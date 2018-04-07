function obj = calc_greeks(option,valuation_date,value_type,underlying,discount_curve,tmp_vola_surf_obj,path_static)
    obj = option;
    if ( nargin < 4)
        error('Error: No  discount curve, vola surface or underlying set. Aborting.');
    end
    if ( nargin < 5)
        valuation_date = today;
    end
    if (ischar(valuation_date))
        valuation_date = datenum(valuation_date);
    end
    if ( nargin < 6)
        path_static = pwd;
    end
    % Get discount curve nodes and rate
        tmp_nodes        = discount_curve.nodes;
        tmp_rates_base   = discount_curve.getValue('base');
        comp_type_curve = discount_curve.compounding_type;
        comp_freq_curve = discount_curve.compounding_freq;
        basis_curve     = discount_curve.basis;
        tmp_type = obj.sub_type;
        option_type = obj.option_type;
        call_flag = obj.call_flag;
    if ( call_flag == 1 )
        moneyness_exponent = 1;
    else
        moneyness_exponent = -1;
    end
    
    
    % Get input variables
    tmp_dtm                  = (datenum(obj.maturity_date,1) - valuation_date); 
    tmp_rf_rate              = interpolate_curve(tmp_nodes,tmp_rates_base,tmp_dtm ) + obj.spread;
    tmp_impl_vola_spread     = obj.vola_spread;
    % Get underlying absolute scenario value 
    tmp_underlying_value     = underlying.getValue('base');
   
    if ( tmp_dtm < 0 )
        theo_value  = 0.0;
        theo_delta  = 0.0;
        theo_gamma  = 0.0;
        theo_vega   = 0.0;
        theo_theta  = 0.0;
        theo_rho    = 0.0;
        theo_omega  = 0.0; 
        tmp_multiplier = 0.0;
    else
        tmp_strike         = obj.strike;
        tmp_value          = obj.value_base;
        tmp_multiplier     = obj.multiplier;
        tmp_moneyness      = ( tmp_underlying_value ./ tmp_strike).^moneyness_exponent;
                
        % get implied volatility spread (choose offset to vola, that tmp_value == option_bs with input of appropriate vol):
        tmp_imp_vola_shock  = tmp_vola_surf_obj.getValue(value_type, ...
                                tmp_dtm,tmp_moneyness) + tmp_impl_vola_spread;
         % sigma needs to be positive
        tmp_imp_vola_shock(tmp_imp_vola_shock<=0) = sqrt(eps);
       % Convert timefactor from Instrument basis to pricing basis (act/365)
        tmp_dtm_pricing  = timefactor (valuation_date, ...
                                valuation_date + tmp_dtm, obj.basis) .* 365;
       
       % Convert divyield and interest rates into act/365 continuous (used by pricing)        
        tmp_rf_rate_conv = convert_curve_rates(valuation_date,tmp_dtm,tmp_rf_rate, ...
                        comp_type_curve,comp_freq_curve,basis_curve, ...
                        'cont','annual',3);
        divyield = obj.get('div_yield');
        
      % set up sensi scenario vector with shocks to all input parameter
        underlying_value_vec    = [tmp_underlying_value.*ones(1,1); ...
                                        tmp_underlying_value - 1; ...
                                        tmp_underlying_value + 1; ...
                                        tmp_underlying_value.*ones(6,1)];
        rf_rate_conv_vec        = [tmp_rf_rate_conv.*ones(3,1); ...
                                        tmp_rf_rate_conv - 0.01; ...
                                        tmp_rf_rate_conv + 0.01; ...
                                        tmp_rf_rate_conv.*ones(4,1)];
        imp_vola_shock_vec      = [tmp_imp_vola_shock.*ones(5,1); ...
                                        tmp_imp_vola_shock - 0.01; ...
                                        tmp_imp_vola_shock + 0.01; ...
                                        tmp_imp_vola_shock.*ones(2,1)];
        dtm_pricing_vec         = [tmp_dtm_pricing.*ones(7,1); ...
                                        tmp_dtm_pricing - 1; ...
                                        tmp_dtm_pricing + 1];
        sensi_vec               = ones(9,1);      
      % Valuation for all Option types:          
        if ( strcmpi(option_type,'American') )   
            % calculating effective greeks -> imply from derivatives
            if ( strcmpi(obj.pricing_function_american,'BjSten') ) 
                sensi_vec   = option_bjsten(call_flag, underlying_value_vec, ...
                                tmp_strike, dtm_pricing_vec, rf_rate_conv_vec, ...
                                imp_vola_shock_vec, divyield);              
            else %  call CRR for both Willowtree and CRR model (less overhead)
                sensi_vec   = pricing_option_cpp(2,logical(call_flag),underlying_value_vec, ...
                                    tmp_strike,dtm_pricing_vec,rf_rate_conv_vec, ...
                                    imp_vola_shock_vec,divyield,800);
            end
        elseif ( strcmpi(option_type,'Barrier') ) 
            % calculating effective greeks -> imply from derivatives
            sensi_vec   = option_barrier(call_flag,obj.upordown,obj.outorin, ...
                                underlying_value_vec, tmp_strike, ...
                                obj.barrierlevel, dtm_pricing_vec, rf_rate_conv_vec, ...
                                imp_vola_shock_vec, divyield, obj.rebate);
        elseif ( strcmpi(option_type,'Asian') ) 
            % calculating effective greeks -> imply from derivatives
            avg_rule = option.averaging_rule;
            avg_monitoring = option.averaging_monitoring;
            % distinguish Asian options:
            if ( strcmpi(avg_rule,'geometric') && strcmpi(avg_monitoring,'continuous') )
              sensi_vec = option_asian_vorst90(call_flag, underlying_value_vec, ...
                                    tmp_strike, dtm_pricing_vec, rf_rate_conv_vec, ...
                                    imp_vola_shock_vec, divyield);
            elseif ( strcmpi(avg_rule,'arithmetic') && strcmpi(avg_monitoring,'continuous') )
              % Call Levy pricing model
              sensi_vec = option_asian_levy(call_flag, underlying_value_vec, ...
                                    tmp_strike, dtm_pricing_vec, rf_rate_conv_vec, ...
                                    imp_vola_shock_vec, divyield);
            else
                error('Unknown Asian averaging rule >>%s<< or monitoring >>%s<<',avg_rule,avg_monitoring);
            end
            
        elseif ( strcmpi(option_type,'Binary'))   % calling Binary option pricing model
            sensi_vec   = option_binary(call_flag, obj.binary_type, underlying_value_vec, ...
                            tmp_strike, obj.payoff_strike, dtm_pricing_vec, rf_rate_conv_vec, ...
                            imp_vola_shock_vec, divyield) .* tmp_multiplier;
                            
        elseif ( strcmpi(option_type,'Lookback'))   % calling lookback option pricing model
            sensi_vec   = option_lookback(call_flag, obj.lookback_type, underlying_value_vec, ...
                            tmp_strike, obj.payoff_strike, dtm_pricing_vec, rf_rate_conv_vec, ...
                            imp_vola_shock_vec, divyield) .* tmp_multiplier;
                            
        end
        % calculate numeric derivatives
        %sensi_vec = [theo_value_base;undvalue_down;undvalue_up;rfrate_down;rfrate_up;vola_down;vola_up;time_down;time_up]
        theo_delta  = (sensi_vec(3) - sensi_vec(2)) / 2;
        theo_gamma  = (sensi_vec(3) + sensi_vec(2) - 2 * sensi_vec(1));
        theo_vega   = (sensi_vec(7) - sensi_vec(6)) / 2;
        theo_theta  = -(sensi_vec(9) - sensi_vec(8)) / 2;
        theo_rho    = (sensi_vec(5) - sensi_vec(4)) / 2;
        theo_omega  = theo_delta .* tmp_underlying_value ./ sensi_vec(1);
        
        % special case European Options: take BS Sensitivities
        if ( strcmpi(option_type,'European')  )     % calling Black-Scholes option pricing model
            [theo_value theo_delta theo_gamma theo_vega theo_theta theo_rho ...
                            theo_omega] = option_bs(call_flag, ...
                            tmp_underlying_value, tmp_strike, tmp_dtm_pricing, ...
                            tmp_rf_rate_conv, tmp_imp_vola_shock, divyield);
        end
    end   % close loop if tmp_dtm < 0
    
    
      
    % store theo_value vector in appropriate class property   
    if ( strcmpi(value_type,'stress'))
        %obj = obj.set('value_stress',theo_value);  
    elseif ( strcmpi(value_type,'base'))
        obj = obj.set('theo_delta',theo_delta .* tmp_multiplier);
        obj = obj.set('theo_gamma',theo_gamma .* tmp_multiplier);
        obj = obj.set('theo_vega',theo_vega .* tmp_multiplier);
        obj = obj.set('theo_theta',theo_theta .* tmp_multiplier);
        obj = obj.set('theo_rho',theo_rho .* tmp_multiplier);
        obj = obj.set('theo_omega',theo_omega .* tmp_multiplier);       
    end
   
end



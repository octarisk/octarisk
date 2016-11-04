function obj = calc_value(option,valuation_date,value_type,underlying,vola_riskfactor,discount_curve,tmp_vola_surf_obj,path_static)
    obj = option;
    if ( nargin < 6)
        error('Error: No  discount curve, vola surface or underlying set. Aborting.');
    end
    if ( nargin < 7)
        valuation_date = today;
    end
    if (ischar(valuation_date))
        valuation_date = datenum(valuation_date);
    end
    if ( nargin < 8)
        path_static = pwd;
    end
    % Get discount curve nodes and rate
        tmp_nodes        = discount_curve.get('nodes');
        tmp_rates        = discount_curve.getValue(value_type);
        tmp_rates_base   = discount_curve.getValue('base');
        comp_type_curve = discount_curve.get('compounding_type');
        comp_freq_curve = discount_curve.get('compounding_freq');
        basis_curve     = discount_curve.get('basis');
        
    % get further option attributes
    tmp_type = obj.sub_type;
    option_type = obj.option_type;
    call_flag = obj.call_flag;
    if ( call_flag == 1 )
        moneyness_exponent = 1;
    else
        moneyness_exponent = -1;
    end
     
    % Get input variables
    tmp_dtm                  = (datenum(obj.maturity_date) - valuation_date); 
    tmp_rf_rate              = interpolate_curve(tmp_nodes,tmp_rates,tmp_dtm ) + obj.spread;
    %tmp_rf_rate_base         = interpolate_curve(tmp_nodes,tmp_rates_base,tmp_dtm ) + obj.spread;
    tmp_impl_vola_spread     = obj.vola_spread;
    % Get underlying absolute scenario value 
    if ( strfind(underlying.get('id'),'RF_') )   % underlying instrument is a risk factor
        tmp_underlying_value_delta      = underlying.getValue(value_type); 
        tmp_underlying_value            = Riskfactor.get_abs_values('GBM', ...
                                        tmp_underlying_value_delta, obj.spot);
        tmp_underlying_value_base       = underlying.getValue('base'); 
    else    % underlying is a Index
        tmp_underlying_value            = underlying.getValue(value_type); 
        tmp_underlying_value_base       = underlying.getValue('base');
    end
    mc = length(tmp_underlying_value);

    if ( tmp_dtm < 0 )
        theo_value_base         = 0;
        theo_value              = zeros(mc,1);
    else
        tmp_strike              = obj.strike;
        tmp_value               = obj.value_base;
        tmp_multiplier          = obj.multiplier;
        tmp_moneyness_base      = ( tmp_underlying_value_base ./ tmp_strike).^ ...
                                                            moneyness_exponent;
        tmp_moneyness           = (tmp_underlying_value ./ tmp_strike).^ ...
                                                            moneyness_exponent;
        tmp_imp_vola_shock = calcVolaShock(value_type,obj,tmp_vola_surf_obj, ...
                            vola_riskfactor,tmp_dtm,tmp_moneyness);
    
      % Convert interest rates into act/365 continuous (used by pricing)     
        tmp_rf_rate_conv = convert_curve_rates(valuation_date,tmp_dtm,tmp_rf_rate, ...
                        comp_type_curve,comp_freq_curve,basis_curve, ...
                        'cont','annual',3);
        divyield = obj.get('div_yield');
        
      % Convert timefactor from Instrument basis to pricing basis (act/365)
        tmp_dtm_pricing  = timefactor (valuation_date, ...
                                valuation_date + tmp_dtm, obj.basis) .* 365;
      
      % Valuation for: European plain vanilla options
        if ( strcmpi(option_type,'European')  )     % calling Black-Scholes option pricing model
            theo_value	= option_bs(call_flag,tmp_underlying_value, ...
                                tmp_strike,tmp_dtm_pricing,tmp_rf_rate_conv, ...
                                tmp_imp_vola_shock,divyield) .* tmp_multiplier;
                                
      % Valuation for: (European) Asian options
        elseif ( strcmpi(option_type,'Asian')  ) % calling Kemna-Vorst or Levy option pricing model
            avg_rule = option.averaging_rule;
            avg_monitoring = option.averaging_monitoring;
            % distinguish Asian options:
            if ( strcmpi(avg_rule,'geometric') && strcmpi(avg_monitoring,'continuous') )
                % Call Kemna-Vorst90 pricing model
                theo_value	= option_asian_vorst90(call_flag,tmp_underlying_value, ...
                                tmp_strike,tmp_dtm_pricing,tmp_rf_rate_conv, ...
                                tmp_imp_vola_shock,divyield) .* tmp_multiplier;
            elseif ( strcmpi(avg_rule,'arithmetic') && strcmpi(avg_monitoring,'continuous') )
                % Call Levy pricing model
                theo_value	= option_asian_levy(call_flag,tmp_underlying_value, ...
                                tmp_strike,tmp_dtm_pricing,tmp_rf_rate_conv, ...
                                tmp_imp_vola_shock,divyield) .* tmp_multiplier;
            else
                error('Unknown Asian averaging rule >>%s<< or monitoring >>%s<<',avg_rule,avg_monitoring);
            end
                             
      % Valuation for: American plain vanilla options
        elseif ( strcmpi(option_type,'American'))   % calling Willow tree option pricing model
            if ( strcmpi(obj.pricing_function_american,'Willowtree') )
                theo_value	= option_willowtree(call_flag,1,tmp_underlying_value, ...
                                    tmp_strike,tmp_dtm_pricing,tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock,0.0,option.timesteps_size, ...
                                    option.willowtree_nodes,path_static) .* tmp_multiplier;
            else
                theo_value  = option_bjsten(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield) .* tmp_multiplier;
            end
                     
       % Valuation for: European Barrier Options:
        elseif ( strcmpi(option_type,'Barrier'))   % calling Barrier option pricing model
            theo_value	= option_barrier(call_flag,obj.upordown,obj.outorin,...
                                tmp_underlying_value, tmp_strike, ...
                                obj.barrierlevel, tmp_dtm_pricing, ...
                                tmp_rf_rate_conv, tmp_imp_vola_shock, ...
                                divyield, obj.rebate) .* tmp_multiplier;   
    end   % close loop if tmp_dtm < 0
    
      
    % store theo_value vector in appropriate class property   
    if ( strcmpi(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);  
    elseif ( strcmpi(value_type,'base'))
        obj = obj.set('value_base',theo_value);  
    else  
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
    
end



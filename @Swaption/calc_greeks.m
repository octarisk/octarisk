function obj = calc_greeks(swaption,valuation_date,value_type,discount_curve,tmp_vola_surf_obj,leg_fixed_obj,leg_float_obj)
    obj = swaption;
    if ( nargin < 4)
        error('Error: No  discount curve or vola surface set. Aborting.');
    end

    % Get discount curve nodes and rate
        tmp_nodes        = discount_curve.nodes;
        tmp_rates        = discount_curve.getValue(value_type);
    tmp_type = obj.sub_type;
    % Get Call or Putflag
    if ( obj.call_flag == true)
        call_flag = 1;
        moneyness_exponent = 1;
    else
        call_flag = 0;
        moneyness_exponent = -1;
    end

    if ( ischar(valuation_date))
        valuation_date = datenum(valuation_date,1);
    end
    
    % Get input variables
    % get days in period
    matdatenum = datenum(obj.maturity_date,1);
    [tmp_tf tmp_effdate dib]  = timefactor (valuation_date, ...
                                matdatenum, obj.basis);
    tmp_effdate =  matdatenum - valuation_date;
    annuity_dates = [];
    % calculating swaption maturity date: effdate + tenor
    if (strcmpi(obj.term_unit,'days'))
        tmp_dtm          = tmp_effdate + obj.term * obj.tenor;
        annuity_dates    = [tmp_effdate:obj.term:tmp_dtm];
    elseif (strcmpi(obj.term_unit,'months'))
        tmp_dtm          = tmp_effdate + obj.term * 30 * obj.tenor;
        annuity_dates    = [tmp_effdate:obj.term * 30:tmp_dtm];
    else % years
        tmp_dtm          = tmp_effdate + obj.term * 365 * obj.tenor;
        annuity_dates    = [tmp_effdate:obj.term * 365:tmp_dtm];
    end
    tmp_effdate = max(tmp_effdate,1);
    
    % interpolating rates
    tmp_rf_rate              = interpolate_curve(tmp_nodes,tmp_rates, ...
                                                tmp_effdate ) + obj.spread;
    tmp_impl_vola_spread     = obj.vola_spread;    
    mc = length(tmp_rf_rate);
    
    if ( tmp_dtm < 0 )
        theo_value  = 0.0;
        theo_delta  = 0.0;
        theo_gamma  = 0.0;
        theo_vega   = 0.0;
        theo_theta  = 0.0;
        theo_rho    = 0.0;
        theo_omega  = 0.0; 
        tmp_multiplier = 0.0;
        theo_value_base = obj.value_base;
    else
        % Valuation:
        tmp_spot            = obj.spot;
        tmp_strike          = obj.strike;
        tmp_value           = obj.value_base;
        theo_value_base     = tmp_value;
        tmp_multiplier      = obj.multiplier;
        tmp_swap_tenor      = obj.tenor;
        tmp_swap_no_pmt     = obj.no_payments;
        tmp_model           = obj.model;
        
        comp_type           = obj.compounding_type;   
        interp_method       = discount_curve.method_interpolation;
        comp_freq           = obj.compounding_freq;
        basis               = obj.basis;
        comp_type_curve     = discount_curve.compounding_type;  
        basis_curve         = discount_curve.basis;
        comp_freq_curve     = discount_curve.compounding_freq;
        
        % apply floor at 0.00001 for forward rates
        if ( regexpi(tmp_model,'black'))
            floor_flag          = true;
        else
            floor_flag          = false;
        end
        % Get underlying yield rates:        
        tmp_forward_shock       = get_forward_rate(tmp_nodes,tmp_rates, ...
                                    tmp_effdate,tmp_dtm-tmp_effdate, comp_type, ...
                                    interp_method, comp_freq, basis, valuation_date, ...
                                    comp_type_curve, basis_curve, ...
                                    comp_freq_curve, floor_flag);
        
        % alternative calculation: Annuity = Sum(DF_OptionTerm_SwaptionMaturity)
        % (DF(SwaptionMaturity) - DF(OptionTerm))/Annuity
        Annuity = zeros(rows(tmp_forward_shock),1);
        for ii=2:1:length(annuity_dates)
            tmp_date = annuity_dates(ii);
            tmp_rate = interpolate_curve(tmp_nodes,tmp_rates,tmp_date,interp_method);
            Annuity = Annuity + discount_factor(valuation_date, ...
                                        valuation_date+tmp_date, ...
                                        tmp_rate,comp_type, basis, comp_freq);
        end
        DF_effdate_rate = interpolate_curve(tmp_nodes,tmp_rates,annuity_dates(1),interp_method);
        DF_matdate_rate = interpolate_curve(tmp_nodes,tmp_rates,annuity_dates(end),interp_method);
        DF_effdate = discount_factor(valuation_date, valuation_date+tmp_effdate, ...
                                        DF_effdate_rate,comp_type, basis, comp_freq);
        DF_matdate = discount_factor(valuation_date, valuation_date+tmp_dtm, ...
                                        DF_matdate_rate,comp_type, basis, comp_freq);
        tmp_forward_shock = (DF_effdate - DF_matdate)./Annuity;
        
        % determining volatility cube axis
        if ( regexpi(tmp_vola_surf_obj.axis_x_name,'TENOR')) % standard case
            % x-axis: effective date of swaption -> option term
            % y-axis: underlying swap tenor -> underlying term
            xx = matdatenum - valuation_date;
            yy = tmp_swap_tenor*365;
        elseif ( regexpi(tmp_vola_surf_obj.axis_x_name,'TERM'))
            % x-axis: underlying swap tenor -> underlying term 
            % y-axis: effective date of swaption -> option term
            xx = tmp_swap_tenor*365;
            yy = matdatenum - valuation_date;
        else
            fprintf('Swaption.calc_value: WARNING: Volatility surface has neither TENOR nor TERM axis. Taking value at (0,0). \n');
            xx = 0;
            yy = 0;
        end
                
      % Convert interest rates into act/365 continuous (used by pricing)
        tmp_rf_rate_conv = convert_curve_rates(valuation_date,tmp_dtm,tmp_rf_rate, ...
                        comp_type_curve,comp_freq_curve,basis_curve, ...
                        'cont','annual',3);
                        
      % Valuation for: Black76 or Bachelier model according to type
       
        if (obj.use_underlyings == false)   % pricing with forward rates
            % get volatility according to moneyness and term
            if ( regexpi(tmp_vola_surf_obj.moneyness_type,'-')) % surface with absolute moneyness
                tmp_moneyness = (tmp_strike - tmp_forward_shock);
            else % surface with relative moneyness
                tmp_moneyness = (tmp_forward_shock ./tmp_strike).^moneyness_exponent; 
            end 
            tmp_imp_vola_shock = tmp_vola_surf_obj.getValue(value_type, ...
                 xx,yy,tmp_moneyness) + tmp_impl_vola_spread;
            
            % calculate shock to Y_u:
            dY_u = 0.01 * tmp_forward_shock;  
            dVola = tmp_imp_vola_shock * 0.01;
            
            % set up sensi scenario vector with shocks to all input parameter
            tmp_forward_shock_vec   = [tmp_forward_shock.*ones(1,1); ...
                                            tmp_forward_shock * 0.99; ...
                                            tmp_forward_shock * 1.01; ...
                                            tmp_forward_shock.*ones(6,1)];
            rf_rate_conv_vec        = [tmp_rf_rate_conv.*ones(3,1); ...
                                            tmp_rf_rate_conv - 0.01; ...
                                            tmp_rf_rate_conv + 0.01; ...
                                            tmp_rf_rate_conv.*ones(4,1)];
            imp_vola_shock_vec      = [tmp_imp_vola_shock.*ones(5,1); ...
                                            tmp_imp_vola_shock * 0.99; ...
                                            tmp_imp_vola_shock * 1.01; ...
                                            tmp_imp_vola_shock.*ones(2,1)];
            tmp_effdate_vec         = [tmp_effdate.*ones(7,1); ...
                                            tmp_effdate - 1; ...
                                            tmp_effdate + 1];
            sensi_vec               = ones(9,1);
        
            if ( regexpi(tmp_model,'black'))
                % calculating effective greeks -> imply from derivatives
                sensi_vec = swaption_black76(call_flag,tmp_forward_shock_vec, ...
                                        tmp_strike,tmp_effdate_vec,rf_rate_conv_vec, ...
                                        imp_vola_shock_vec,tmp_swap_no_pmt, ...
                                        tmp_swap_tenor);    
                                                        
            else % Bachelier formula
                % normal volatilities
                dVola = 0.01;
                imp_vola_shock_vec      = [tmp_imp_vola_shock.*ones(5,1); ...
                                            tmp_imp_vola_shock - dVola; ...
                                            tmp_imp_vola_shock + dVola; ...
                                            tmp_imp_vola_shock.*ones(2,1)];

                sensi_vec = swaption_bachelier(call_flag,tmp_forward_shock_vec, ...
                                        tmp_strike,tmp_effdate_vec,rf_rate_conv_vec, ...
                                        imp_vola_shock_vec,tmp_swap_no_pmt, ...
                                        tmp_swap_tenor);

            end
            
        else    % pricing with underlying float and fixed leg
            % make sure underlying objects are existing
            if ( nargin < 7)
                error('Error: No underlying fixed and floating leg set. Aborting.');
            end
            % fixed leg:
            V_fix = leg_fixed_obj.getValue(value_type);
            % floating leg:
            V_float = leg_float_obj.getValue(value_type);
            if ( regexp(value_type,'base'))
                obj = obj.set('und_fixed_value',V_fix);
                obj = obj.set('und_float_value',V_float);
            end
            % update implied volatility
            if ~(V_fix == 0.0)
                Y = tmp_strike .* V_float ./ V_fix;
            else
                Y = 0.0;
            end
            
            % set multiplier to 1 (value derived from underlyings only)
            tmp_multiplier = 1.0;
            
            % get volatility according to moneyness and term
            % surface with absolute moneyness K - S
            if ( regexpi(tmp_vola_surf_obj.moneyness_type,'-')) 
                tmp_moneyness = (tmp_strike - Y);
            else % surface with relative moneyness
                tmp_moneyness = (Y ./tmp_strike).^moneyness_exponent; 
            end    

            % interpolation of volatility
            % calculate yy: time between maturity and issue date of underlying
            yy = datenum(leg_fixed_obj.maturity_date,1) - datenum(leg_fixed_obj.issue_date,1);
            tmp_imp_vola_shock = tmp_vola_surf_obj.getValue(value_type, ...
                xx,yy,tmp_moneyness) + tmp_impl_vola_spread;
                
            % calculate shock to Y_u:
            dY_u = 0.01 * tmp_strike .* V_float ./ V_fix;
            
            % set up sensi scenario vector with shocks to all input parameter
            V_float_vec     = [V_float.*ones(1,1); ...
                                            V_float * 0.99; ...
                                            V_float * 1.01; ...
                                            V_float.*ones(6,1)];
            dVola = 0.01;
            imp_vola_shock_vec      = [tmp_imp_vola_shock.*ones(5,1); ...
                                            tmp_imp_vola_shock - dVola; ...
                                            tmp_imp_vola_shock + dVola; ...
                                            tmp_imp_vola_shock.*ones(2,1)];
            tmp_effdate_vec         = [tmp_effdate.*ones(7,1); ...
                                            tmp_effdate - 1; ...
                                            tmp_effdate + 1];
            
            % calculating effective greeks -> imply from derivatives
            sensi_vec = swaption_underlyings(call_flag,tmp_strike,V_fix, ...
                               V_float_vec,tmp_effdate_vec,imp_vola_shock_vec, ...
                               tmp_model);
        end
        
        % calculate numeric derivatives
        %sensi_vec = [theo_value_base;undvalue_down;undvalue_up;rfrate_down;rfrate_up;vola_down;vola_up;time_down;time_up]
        theo_delta  = (sensi_vec(3) - sensi_vec(2)) / (2 * dY_u);
        theo_gamma  = (sensi_vec(3) + sensi_vec(2) - 2 * sensi_vec(1))  / (dY_u).^2;
        theo_vega   = (sensi_vec(7) - sensi_vec(6))/ (200 * dVola);
        theo_theta  = -(sensi_vec(9) - sensi_vec(8)) / 2;
        theo_rho    = (sensi_vec(5) - sensi_vec(4)) / 2;
        
            
    end   % close loop if tmp_dtm < 0
            
 
    % store theo_sensitivities in object attributes 
    if ( strcmpi(value_type,'base'))
        obj = obj.set('theo_delta',theo_delta .* tmp_multiplier);
        obj = obj.set('theo_gamma',theo_gamma .* tmp_multiplier);
        obj = obj.set('theo_vega',theo_vega .* tmp_multiplier);
        obj = obj.set('theo_theta',theo_theta .* tmp_multiplier);
        obj = obj.set('theo_rho',theo_rho .* tmp_multiplier);   
    end
   
end



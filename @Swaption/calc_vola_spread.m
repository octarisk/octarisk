function obj = calc_vola_spread(swaption,valuation_date,discount_curve,tmp_vola_surf_obj,vola_riskfactor,leg_fixed_obj,leg_float_obj)
    obj = swaption;
    if ( nargin < 3)
        error('Error: No discount curve or vola surface set. Aborting.');
    end
    if ( nargin < 5)
        vola_riskfactor = Riskfactor();
    end
    % Get discount curve nodes and rate
        tmp_nodes        = discount_curve.get('nodes');
        tmp_rates_base   = discount_curve.getValue('base');
    tmp_type = obj.sub_type;
    % Get Call or Putflag
    %fprintf('==============================\n');
    if ( strcmp(tmp_type,'SWAPT_EUR_PAY') == 1 )
        call_flag = 1;
        moneyness_exponent = 1;
    else
        call_flag = 0;
        moneyness_exponent = -1;
    end
     
    % Get input variables
    
    % Convert tmp_effdate timefactor from Instrument basis to pricing basis (act/365)
    tmp_effdate  = timefactor (valuation_date, ...
                                datenum(obj.maturity_date), obj.basis) .* 365;
    % calculating swaption maturity date: effdate + tenor
    tmp_dtm          = tmp_effdate + 365 * obj.tenor; % unit years is assumed
    tmp_effdate = max(tmp_effdate,1);
    
    tmp_rf_rate_base         = interpolate_curve(tmp_nodes,tmp_rates_base, ...
                                                tmp_effdate ) + obj.spread;
    
    
    if ( tmp_dtm < 0 )
        tmp_impl_vola_spread    = 0;
        theo_value_base         = 0;
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
        tmp_forward_base    = get_forward_rate(tmp_nodes,tmp_rates_base, ...
                                tmp_effdate,tmp_dtm-tmp_effdate, comp_type, ...
                                interp_method, comp_freq, basis, valuation_date, ...
                                comp_type_curve, basis_curve, ...
                                comp_freq_curve, floor_flag);

        tmp_moneyness_base      = (tmp_forward_base ./tmp_strike).^moneyness_exponent;
                
        % get implied volatility spread 
        % (choose offset to vola, that tmp_value == option_bs with input of appropriate vol):
        tmp_indexvol_base           = tmp_vola_surf_obj.interpolate(tmp_swap_tenor, ...
                                        tmp_dtm,tmp_moneyness_base);

        % Convert interest rates into act/365 continuous (used by pricing)
        tmp_rf_rate_base = convert_curve_rates(valuation_date,tmp_dtm,tmp_rf_rate_base, ...
                        comp_type_curve,comp_freq_curve,basis_curve, ...
                        'cont','annual',3);
                        
        % Calculate Swaption base value and implied spread
        if (obj.use_underlyings == false)   % pricing with forward rates
            if ( regexpi(tmp_model,'black'))
                tmp_swaptionvalue_base  = swaption_black76(call_flag,tmp_forward_base, ...
                                            tmp_strike,tmp_effdate,tmp_rf_rate_base, ...
                                            tmp_indexvol_base,tmp_swap_no_pmt, ...
                                            tmp_swap_tenor) .* tmp_multiplier;
            else
                tmp_swaptionvalue_base  = swaption_bachelier(call_flag,tmp_forward_base, ...
                                            tmp_strike,tmp_effdate,tmp_rf_rate_base, ...
                                            tmp_indexvol_base,tmp_swap_no_pmt, ...
                                            tmp_swap_tenor) .* tmp_multiplier;
            end
            tmp_impl_vola_spread = calibrate_swaption(call_flag,tmp_forward_base, ...
                                        tmp_strike,tmp_effdate,tmp_rf_rate_base, ...
                                        tmp_indexvol_base,tmp_swap_no_pmt, ...
                                        tmp_swap_tenor,tmp_multiplier,tmp_value, ...
                                        tmp_model);
        else    % pricing with underlying float and fixed leg
            % make sure underlying objects are existing
            if ( nargin < 7)
                error('Error: No underlying fixed and floating leg set. Aborting.');
            end
            % evaluate fixed leg and floating leg: discount with swaptions 
            %   discount curve:
            % fixed leg:
            cashflow_dates_fixed = leg_fixed_obj.get('cf_dates');
            cashflow_values_fixed = leg_fixed_obj.getCF('base');
            V_fix = pricing_npv(valuation_date, cashflow_dates_fixed, ...
                                    cashflow_values_fixed, 0.0, ...
                                    tmp_nodes, tmp_rates_base, basis, comp_type, ...
                                    comp_freq, interp_method, ...
                                    comp_type_curve, basis_curve, ...
                                    comp_freq_curve);
            % floating leg:
            cashflow_dates_floating = leg_float_obj.get('cf_dates');
            cashflow_values_floating  = leg_float_obj.getCF('base');
            V_float = pricing_npv(valuation_date, cashflow_dates_floating, ...
                                    cashflow_values_floating, 0.0, ...
                                    tmp_nodes, tmp_rates_base, basis, comp_type, ...
                                    comp_freq, interp_method, ...
                                    comp_type_curve, basis_curve, ...
                                    comp_freq_curve);
            % call pricing function
            tmp_swaptionvalue_base = swaption_underlyings(call_flag,tmp_strike,V_fix, ...
                                    V_float,tmp_effdate,tmp_indexvol_base, ...
                                    tmp_model)  .* tmp_multiplier;
            % calibrate vola spread
            tmp_impl_vola_spread = calibrate_swaption_underlyings(call_flag,tmp_strike,V_fix, ...
                                    V_float,tmp_effdate,tmp_indexvol_base, ...
                                    tmp_model,tmp_multiplier,tmp_value);

        end

        % error handling of calibration:
        if ( tmp_impl_vola_spread < -98 )
            fprintf(' Calibration failed for >>%s<< with Retcode 99. Setting market value to THEO/Value\n',obj.id);
            theo_value_base = tmp_swaptionvalue_base;
            tmp_impl_vola_spread    = 0; 
        else
          %disp('Calibration seems to be successful.. checking');
          if (obj.use_underlyings == false)   % pricing with forward rates
            if ( regexpi(tmp_model,'black'))
                tmp_new_val      = swaption_black76(call_flag,tmp_forward_base, ...
                                        tmp_strike,tmp_effdate,tmp_rf_rate_base, ...
                                        tmp_indexvol_base+ tmp_impl_vola_spread, ...
                                        tmp_swap_no_pmt,tmp_swap_tenor) .* tmp_multiplier;
            else
                tmp_new_val      = swaption_bachelier(call_flag,tmp_forward_base, ...
                                        tmp_strike,tmp_effdate,tmp_rf_rate_base, ...
                                        tmp_indexvol_base+ tmp_impl_vola_spread, ...
                                        tmp_swap_no_pmt,tmp_swap_tenor) .* tmp_multiplier;
            end
          else    % pricing with underlying float and fixed leg
                tmp_new_val = swaption_underlyings(call_flag,tmp_strike,V_fix, ...
                                    V_float,tmp_effdate,tmp_indexvol_base ...
                                    + tmp_impl_vola_spread, ...
                                    tmp_model)  .* tmp_multiplier;
          end
          if ( abs(tmp_value - tmp_new_val) < 0.05 )
                %disp('Calibration successful.');
                theo_value_base = tmp_value;
          else
                fprintf(' Calibration failed for >>%s<<, although it converged.. Setting market value to THEO/Value\n',obj.id);
                theo_value_base = tmp_swaptionvalue_base;
                tmp_impl_vola_spread = 0; 
          end
        end
     
    end   % close loop if tmp_dtm < 0
    
      
    % store theo_value vector in appropriate property
    obj.vola_spread = tmp_impl_vola_spread;
    obj.value_base = theo_value_base;
end





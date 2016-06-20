function obj = calc_vola_spread(option,underlying,vola_riskfactor,discount_curve,tmp_vola_surf_obj,valuation_date,path_static)
    obj = option;
    if ( nargin < 5)
        error('Error: No discount curve, vola surface or underlying set. Aborting.');
    end
    if ( nargin < 6)
        valuation_date = today;
    end
    if (ischar(valuation_date))
        valuation_date = datenum(valuation_date);
    end
    if ( nargin < 7)
        path_static = pwd;
    end
    % Get discount curve nodes and rate
        tmp_nodes        = discount_curve.get('nodes');
        tmp_rates_base   = discount_curve.getValue('base');
    tmp_type = obj.sub_type;
    % Get Call or Putflag
    %fprintf('==============================\n');
    if ( strcmp(tmp_type,'OPT_EUR_C') == 1 || strcmp(tmp_type,'OPT_AM_C') == 1)
        call_flag = 1;
        moneyness_exponent = 1;
    else
        call_flag = 0;
        moneyness_exponent = -1;
    end
     
    % Get input variables
    tmp_dtm           = (datenum(obj.maturity_date) - valuation_date); 
    tmp_rf_rate_base  = interpolate_curve(tmp_nodes,tmp_rates_base,tmp_dtm ) + ...
                                                                    obj.spread;
    
    
    if ( tmp_dtm < 0 )
        tmp_impl_vola_spread    = 0;
        theo_value_base         = 0;
    else
        tmp_strike              = obj.strike;
        tmp_value               = obj.value_base;
        theo_value_base         = tmp_value;
        tmp_multiplier          = obj.multiplier;
        % Get underlying absolute scenario value 
        tmp_underlying_value_base       = underlying.getValue('base');

        tmp_moneyness_base      = ( tmp_underlying_value_base ./ tmp_strike).^ ...
                                                            moneyness_exponent;
                
        % get implied volatility spread (choose offset to vola, 
        % that tmp_value == option_bs with input of appropriate vol):
        tmp_indexvol_base       = tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness_base);

        if ( strfind(tmp_type,'OPT_EUR') > 0 )
            tmp_optionvalue_base        = option_bs(call_flag, ...
                                            tmp_underlying_value_base, ...
                                            tmp_strike,tmp_dtm,tmp_rf_rate_base, ...
                                            tmp_indexvol_base) .* tmp_multiplier;
            tmp_impl_vola_spread        = calibrate_option_bs(call_flag, ...
                                            tmp_underlying_value_base,tmp_strike, ...
                                            tmp_dtm,tmp_rf_rate_base, ...
                                            tmp_indexvol_base,tmp_multiplier, ...
                                            tmp_value);
        elseif ( strfind(tmp_type,'OPT_AM') > 0 )
            if ( strcmpi(obj.pricing_function_american,'Willowtree') )
                tmp_optionvalue_base        = option_willowtree(call_flag,1, ...
                                                tmp_underlying_value_base, ...
                                                tmp_strike,tmp_dtm,tmp_rf_rate_base, ...
                                                tmp_indexvol_base,obj.div_yield, ...
                                                option.timesteps_size, ...
                                                option.willowtree_nodes, ...
                                                path_static) .* tmp_multiplier;
                tmp_impl_vola_spread        = calibrate_option_willowtree(call_flag, ...
                                                1,tmp_underlying_value_base, ...
                                                tmp_strike,tmp_dtm,tmp_rf_rate_base,...
                                                tmp_indexvol_base,obj.div_yield, ...
                                                option.timesteps_size, ...
                                                option.willowtree_nodes, ...
                                                tmp_multiplier,tmp_value,path_static);
            else    % use Bjerksund and Stensland approximation
                tmp_optionvalue_base  = option_bjsten(call_flag, ...
                                        tmp_underlying_value_base, tmp_strike, ...
                                        tmp_dtm, tmp_rf_rate_base, ...
                                        tmp_indexvol_base, obj.div_yield) .* ...
                                        tmp_multiplier;
                tmp_impl_vola_spread  = calibrate_option_bjsten(call_flag, ...
                                        tmp_underlying_value_base, tmp_strike, ...
                                        tmp_dtm, tmp_rf_rate_base, ...
                                        tmp_indexvol_base, obj.div_yield, ...
                                        tmp_multiplier,tmp_value);
            end
        end
        % error handling of calibration:
        if ( tmp_impl_vola_spread < -98 )
            fprintf(' Calibration failed for >>%s<< with Retcode 99. Setting market value to THEO/Value\n',obj.id);
            theo_value_base = tmp_optionvalue_base;
            tmp_impl_vola_spread    = 0; 
        else
            %disp('Calibration seems to be successful.. checking');
            %tmp_value
            if ( strfind(tmp_type,'OPT_EUR') > 0  )
                tmp_new_val     = option_bs(call_flag,tmp_underlying_value_base, ...
                                tmp_strike,tmp_dtm,tmp_rf_rate_base, ...
                                tmp_indexvol_base + tmp_impl_vola_spread) .* ...
                                tmp_multiplier;
            elseif ( strfind(tmp_type,'OPT_AM') > 0 )   
                if ( strcmpi(obj.pricing_function_american,'Willowtree') )
                    tmp_new_val = option_willowtree(call_flag,1, ...
                                tmp_underlying_value_base,tmp_strike,tmp_dtm, ...
                                tmp_rf_rate_base,tmp_indexvol_base + tmp_impl_vola_spread, ...
                                obj.div_yield,option.timesteps_size, ...
                                option.willowtree_nodes,path_static) .* tmp_multiplier;
                else
                    tmp_new_val = option_bjsten(call_flag, ...
                                tmp_underlying_value_base, tmp_strike, tmp_dtm, ...
                                tmp_rf_rate_base, tmp_indexvol_base + tmp_impl_vola_spread, ...
                                obj.div_yield) .* tmp_multiplier;
                end        
            end
            
            if ( abs(tmp_value - tmp_new_val) < 0.05 )
                %disp('Calibration successful.');
                theo_value_base = tmp_value;
            else
                fprintf(' Calibration failed for >>%s<<, although it converged.. Setting market value to THEO/Value\n',obj.id);
                theo_value_base = tmp_optionvalue_base;
                tmp_impl_vola_spread = 0; 
            end
        end
     
    end   % close loop if tmp_dtm < 0
    
      
    % store theo_value vector in appropriate class property
    obj.vola_spread = tmp_impl_vola_spread;
    obj.value_base = theo_value_base;
end





function obj = calc_value(option,value_type,underlying,vola_riskfactor,discount_curve,tmp_vola_surf_obj,valuation_date,path_static)
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
    tmp_dtm                  = (datenum(obj.maturity_date) - valuation_date); 
    tmp_rf_rate              = interpolate_curve(tmp_nodes,tmp_rates,tmp_dtm ) + obj.spread;
    tmp_rf_rate_base         = interpolate_curve(tmp_nodes,tmp_rates_base,tmp_dtm ) + obj.spread;
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
                
        % get implied volatility spread (choose offset to vola, that tmp_value == option_bs with input of appropriate vol):
        tmp_indexvol_base       = tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness_base);
        tmp_impl_vola_atm       = max(vola_riskfactor.getValue(value_type),-tmp_indexvol_base);
        
      % Get Volatility according to volatility smile given by vola surface
        % Calculate Volatility depending on model
        tmp_model = vola_riskfactor.model;
        if ( strcmp(tmp_model,'GBM') == 1 || strcmp(tmp_model,'BKM') ) % Log-normal Motion
            if ( strcmp(value_type,'stress'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + ...
                            tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness)) ...
                            .* exp(vola_riskfactor.getValue(value_type));
            elseif ( strcmp(value_type,'base'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + ...
                            tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness));
            else
                tmp_imp_vola_shock  = tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness)  .* ...
                                    exp(tmp_impl_vola_atm) + tmp_impl_vola_spread;
            end
        else        % Normal Model
            if ( strcmp(value_type,'stress'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + ...
                          tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness)) .* ...
                          (vola_riskfactor.getValue(value_type) + 1);
            elseif ( strcmp(value_type,'base'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + ...
                           tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness));
            else
                tmp_imp_vola_shock  = tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness) + ...
                                    tmp_impl_vola_atm + tmp_impl_vola_spread;  
            end
        end
    
      % Valuation for: Black-Scholes Modell (EU) or Willowtreemodel (AM):
        if ( strfind(tmp_type,'OPT_EUR') > 0  )     % calling Black-Scholes option pricing model
            theo_value	            = option_bs(call_flag,tmp_underlying_value, ...
                                            tmp_strike,tmp_dtm,tmp_rf_rate, ...
                                            tmp_imp_vola_shock) .* tmp_multiplier;
        elseif ( strfind(tmp_type,'OPT_AM') > 0 )   % calling Willow tree option pricing model
            if ( strcmpi(obj.pricing_function_american,'Willowtree') )
                theo_value	= option_willowtree(call_flag,1,tmp_underlying_value, ...
                                    tmp_strike,tmp_dtm,tmp_rf_rate, ...
                                    tmp_imp_vola_shock,0.0,option.timesteps_size, ...
                                    option.willowtree_nodes,path_static) .* tmp_multiplier;
            else
                theo_value  = option_bjsten(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm, tmp_rf_rate, ...
                                    tmp_imp_vola_shock, obj.div_yield) .* tmp_multiplier;
            end
    end   % close loop if tmp_dtm < 0
    
      
    % store theo_value vector in appropriate class property   
    if ( regexp(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);  
    elseif ( regexp(value_type,'base'))
        obj = obj.set('value_base',theo_value);  
    else  
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
   
end



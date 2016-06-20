function obj = calc_greeks(option,value_type,underlying,vola_riskfactor,discount_curve,tmp_vola_surf_obj,valuation_date,path_static)
    obj = option;
    if ( nargin < 5)
        error('Error: No  discount curve, vola surface or underlying set. Aborting.');
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
    tmp_dtm                  = (datenum(obj.maturity_date) - valuation_date); 
    tmp_rf_rate              = interpolate_curve(tmp_nodes,tmp_rates_base,tmp_dtm ) + obj.spread;
    tmp_impl_vola_spread     = obj.vola_spread;
    % Get underlying absolute scenario value 
    tmp_underlying_value       = underlying.getValue('base');
   
    if ( tmp_dtm < 0 )
        theo_value  = 0.0;
        theo_delta  = 0.0;
        theo_gamma  = 0.0;
        theo_vega   = 0.0;
        theo_theta  = 0.0;
        theo_rho    = 0.0;
        theo_omega  = 0.0; 
        
    else
        tmp_strike         = obj.strike;
        tmp_value          = obj.value_base;
        tmp_multiplier     = obj.multiplier;
        tmp_moneyness      = ( tmp_underlying_value ./ tmp_strike).^moneyness_exponent;
                
        % get implied volatility spread (choose offset to vola, that tmp_value == option_bs with input of appropriate vol):
        tmp_indexvol_base       = tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness);
        tmp_impl_vola_atm       = max(vola_riskfactor.getValue(value_type),-tmp_indexvol_base);
        
      % Get Volatility according to volatility smile given by vola surface
        % Calculate Volatility depending on model
        tmp_model = vola_riskfactor.model;
        if ( strcmp(tmp_model,'GBM') == 1 || strcmp(tmp_model,'BKM') ) % Log-normal Motion
            if ( strcmp(value_type,'stress'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness)) .* exp(vola_riskfactor.getValue(value_type));
            elseif ( strcmp(value_type,'base'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + tmp_indexvol_base);
            else
                tmp_imp_vola_shock  = tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness) .* exp(tmp_impl_vola_atm) + tmp_impl_vola_spread;
            end
        else        % Normal Model
            if ( strcmp(value_type,'stress'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness)) .* (vola_riskfactor.getValue(value_type) + 1);
            elseif ( strcmp(value_type,'base'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + tmp_indexvol_base);
            else
                tmp_imp_vola_shock  = tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness) + tmp_impl_vola_atm + tmp_impl_vola_spread;  
            end
        end
    
      % Valuation for: Black-Scholes Modell (EU) or Willowtreemodel (AM):
        if ( strfind(tmp_type,'OPT_EUR') > 0  )     % calling Black-Scholes option pricing model
            [theo_value theo_delta theo_gamma theo_vega theo_theta theo_rho theo_omega] = option_bs(call_flag,tmp_underlying_value,tmp_strike,tmp_dtm,tmp_rf_rate,tmp_imp_vola_shock);
        elseif ( strfind(tmp_type,'OPT_AM') > 0 )   % calling Willow tree option pricing model
            %theo_value	            = option_willowtree(call_flag,1,tmp_underlying_value,tmp_strike,tmp_dtm,tmp_rf_rate,tmp_imp_vola_shock,0.0,option.timesteps_size,option.willowtree_nodes,path_static);
            theo_delta  = 0.0;
            theo_gamma  = 0.0;
            theo_vega   = 0.0;
            theo_theta  = 0.0;
            theo_rho    = 0.0;
            theo_omega  = 0.0; 
        end
    end   % close loop if tmp_dtm < 0
    
      
    % store theo_value vector in appropriate class property   
    if ( regexp(value_type,'stress'))
        %obj = obj.set('value_stress',theo_value);  
    elseif ( regexp(value_type,'base'))
        obj = obj.set('theo_delta',theo_delta .* tmp_multiplier);
        obj = obj.set('theo_gamma',theo_gamma .* tmp_multiplier);
        obj = obj.set('theo_vega',theo_vega .* tmp_multiplier);
        obj = obj.set('theo_theta',theo_theta .* tmp_multiplier);
        obj = obj.set('theo_rho',theo_rho .* tmp_multiplier);
        obj = obj.set('theo_omega',theo_omega .* tmp_multiplier);       
    end
   
end



function obj = calc_value(swaption,value_type,vola_riskfactor,discount_curve,tmp_vola_surf_obj,valuation_date)
    obj = swaption;
    if ( nargin < 5)
        error("Error: No  discount curve or vola surface set. Aborting.");
    endif
    if ( nargin < 6)
        valuation_date = today;
    endif
    if (ischar(valuation_date))
        valuation_date = datenum(valuation_date);
    endif
    % Get discount curve nodes and rate
        tmp_nodes        = discount_curve.get('nodes');
        tmp_rates        = discount_curve.getValue(value_type);
        tmp_rates_base   = discount_curve.getValue('base');
    tmp_type = obj.sub_type;
    % Get Call or Putflag
    %fprintf("==============================\n");
    if ( strcmp(tmp_type,'SWAPT_EUR_PAY') == 1 )
        call_flag = 1;
        moneyness_exponent = 1;
    else
        call_flag = 0;
        moneyness_exponent = -1;
    end
    
    
    % Get input variables
    tmp_dtm                  = (datenum(obj.maturity_date) - valuation_date - 1); 
    tmp_rf_rate              = interpolate_curve(tmp_nodes,tmp_rates,tmp_dtm ) .+ obj.spread;
    tmp_rf_rate_base         = interpolate_curve(tmp_nodes,tmp_rates_base,tmp_dtm ) .+ obj.spread;
    tmp_impl_vola_spread     = obj.vola_spread;    
    mc = length(tmp_rf_rate);
    
    if ( tmp_dtm < 0 )
        theo_value_base         = 0;
        theo_value              = zeros(mc,1);
    else
        % Valuation: Black-76 Modell:
        tmp_spot            = obj.spot;
        tmp_strike          = obj.strike;
        tmp_value           = obj.value_base;
        theo_value_base     = tmp_value;
        tmp_multiplier      = obj.multiplier;
        tmp_swap_tenor      = obj.tenor;
        tmp_swap_no_pmt     = obj.no_payments;
        tmp_model           = obj.model;
        
        % Get underlying yield rates:
        tmp_forward_base        = get_forward_rate(tmp_nodes,tmp_rates_base,tmp_dtm,tmp_swap_tenor);
        tmp_moneyness_base      = (tmp_forward_base ./tmp_strike).^moneyness_exponent;
        
        tmp_forward_shock       = get_forward_rate(tmp_nodes,tmp_rates,tmp_dtm,tmp_swap_tenor);
        tmp_moneyness           = (tmp_forward_shock ./tmp_strike).^moneyness_exponent; 
                    
        % get implied volatility spread (choose offset to vola, that tmp_value == option_bs with input of appropriate vol):
        tmp_indexvol_base       = tmp_vola_surf_obj.getValue(tmp_swap_tenor,tmp_dtm,tmp_moneyness_base);
        tmp_impl_vola_atm       = max(vola_riskfactor.getValue(value_type),-tmp_indexvol_base);
        
      % Get Volatility according to volatility smile given by vola surface
        % Calculate Volatility depending on model
        tmp_model_vola = vola_riskfactor.model;
        if ( strcmp(tmp_model_vola,'GBM') == 1 || strcmp(tmp_model_vola,'BKM') ) % Log-normal Motion
            if ( strcmp(value_date,'stress'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread .+ tmp_vola_surf_obj.getValue(tmp_swap_tenor,tmp_dtm,tmp_moneyness)) .* exp(vola_riskfactor.getValue(value_type));
            else
                tmp_imp_vola_shock  = tmp_vola_surf_obj.getValue(tmp_swap_tenor,tmp_dtm,tmp_moneyness)  .* exp(tmp_impl_vola_atm) .+ tmp_impl_vola_spread;
            endif
        else        % Normal Model
            if ( strcmp(value_type,'stress'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread .+ tmp_vola_surf_obj.getValue(tmp_swap_tenor,tmp_dtm,tmp_moneyness)) .* (vola_riskfactor.getValue(value_type) .+ 1);
            else
                tmp_imp_vola_shock  = tmp_vola_surf_obj.getValue(tmp_swap_tenor,tmp_dtm,tmp_moneyness) .+ tmp_impl_vola_atm .+ tmp_impl_vola_spread;  
            endif
        end

      % Valuation for: Black76 or Bachelier model
        if ( strcmp(tmp_model,'BLACK76'))
            theo_value      = max(swaption_black76(call_flag,tmp_forward_base,tmp_strike,tmp_dtm,tmp_rf_rate,tmp_imp_vola_shock,tmp_swap_no_pmt,tmp_swap_tenor) .* tmp_multiplier,0.001);
        else
            theo_value      = max(swaption_bachelier(call_flag,tmp_forward_base,tmp_strike,tmp_dtm,tmp_rf_rate,tmp_imp_vola_shock,tmp_swap_no_pmt,tmp_swap_tenor) .* tmp_multiplier,0.001);
        end
        
    endif   % close loop if tmp_dtm < 0
    
      
    % store theo_value vector in appropriate class property   
    if ( regexp(value_type,'stress'))
        obj = obj.set("value_stress",theo_value);  
    else  
        obj = obj.set("timestep_mc",value_type);
        obj = obj.set("value_mc",theo_value);
    endif
   
endfunction



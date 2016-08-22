function obj = calc_value(swaption,value_type,vola_riskfactor,discount_curve,tmp_vola_surf_obj,valuation_date)
    obj = swaption;
    if ( nargin < 5)
        error('Error: No  discount curve or vola surface set. Aborting.');
    end
    if ( nargin < 6)
        valuation_date = today;
    end
    if (ischar(valuation_date))
        valuation_date = datenum(valuation_date);
    end
    % Get discount curve nodes and rate
        tmp_nodes        = discount_curve.get('nodes');
        tmp_rates        = discount_curve.getValue(value_type);
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
    
    % interpolating rates
    tmp_rf_rate              = interpolate_curve(tmp_nodes,tmp_rates, ...
                                                tmp_effdate ) + obj.spread;
    tmp_rf_rate_base         = interpolate_curve(tmp_nodes,tmp_rates_base, ...
                                                tmp_effdate ) + obj.spread;
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
        
        comp_type           = obj.compounding_type;   
        interp_method       = discount_curve.method_interpolation;
        comp_freq           = obj.compounding_freq;
        basis               = obj.basis;
        comp_type_curve     = discount_curve.compounding_type;  
        basis_curve         = discount_curve.basis;
        comp_freq_curve     = discount_curve.compounding_freq;
        
        % Get underlying yield rates:
        tmp_forward_base    = get_forward_rate(tmp_nodes,tmp_rates_base, ...
                                tmp_effdate,tmp_dtm, comp_type, ...
                                interp_method, comp_freq, basis, valuation_date, ...
                                comp_type_curve, basis_curve, comp_freq_curve);

        tmp_moneyness_base      = (tmp_forward_base ./tmp_strike).^moneyness_exponent;
        
        tmp_forward_shock       = get_forward_rate(tmp_nodes,tmp_rates, ...
                                                    tmp_effdate,tmp_dtm);
        tmp_moneyness           = (tmp_forward_shock ./tmp_strike).^moneyness_exponent; 
                    
        tmp_imp_vola_shock = calcVolaShock(value_type,obj,tmp_vola_surf_obj, ...
                            vola_riskfactor,tmp_swap_tenor,tmp_dtm,tmp_moneyness);

      % Convert interest rates into act/365 continuous (used by pricing)
        tmp_rf_rate_conv = convert_curve_rates(valuation_date,tmp_dtm,tmp_rf_rate, ...
                        comp_type_curve,comp_freq_curve,basis_curve, ...
                        'cont','annual',3);
                        
      % Valuation for: Black76 or Bachelier model
        if ( strcmp(tmp_model,'BLACK76'))
            theo_value      = max(swaption_black76(call_flag,tmp_forward_base, ...
                                    tmp_strike,tmp_effdate,tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock,tmp_swap_no_pmt, ...
                                    tmp_swap_tenor) .* tmp_multiplier,0.001);
        else
            theo_value      = max(swaption_bachelier(call_flag,tmp_forward_base, ...
                                    tmp_strike,tmp_effdate,tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock,tmp_swap_no_pmt, ...
                                    tmp_swap_tenor) .* tmp_multiplier,0.001);
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



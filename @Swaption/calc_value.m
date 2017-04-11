function obj = calc_value(swaption,valuation_date,value_type,discount_curve,tmp_vola_surf_obj,leg_fixed_obj,leg_float_obj)
    obj = swaption;
    if ( nargin < 4)
        error('Error: No  discount curve or vola surface set. Aborting.');
    end

    % Get discount curve nodes and rate
        tmp_nodes        = discount_curve.get('nodes');
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
        valuation_date = datenum(valuation_date);
    end
    
    % Get input variables
    
    % ??Convert tmp_effdate timefactor from Instrument basis to pricing basis (act/365)??
    % get days in period
    [tmp_tf tmp_effdate dib]  = timefactor (valuation_date, ...
                                datenum(obj.maturity_date), obj.basis);
    % calculating swaption maturity date: effdate + tenor
    tmp_dtm          = tmp_effdate + 365 * obj.tenor; % unit years is assumed
    tmp_effdate = max(tmp_effdate,1);
    
    % interpolating rates
    tmp_rf_rate              = interpolate_curve(tmp_nodes,tmp_rates, ...
                                                tmp_effdate ) + obj.spread;
    tmp_impl_vola_spread     = obj.vola_spread;    
    mc = length(tmp_rf_rate);
    
    if ( tmp_dtm < 0 )
        theo_value_base         = 0;
        theo_value              = zeros(mc,1);
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
                      
        % determining volatility cube axis
        if ( regexpi(tmp_vola_surf_obj.axis_x_name,'TENOR')) % standard case
            % x-axis: effective date of swaption -> option term
            % y-axis: underlying swap tenor -> underlying term
            xx = datenum(obj.maturity_date) - valuation_date;
            yy = tmp_swap_tenor*365;
        elseif ( regexpi(tmp_vola_surf_obj.axis_x_name,'TERM'))
            % x-axis: underlying swap tenor -> underlying term 
            % y-axis: effective date of swaption -> option term
            xx = tmp_swap_tenor*365;
            yy = datenum(obj.maturity_date) - valuation_date;
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
                 
            if ( regexpi(tmp_model,'black'))
                theo_value      = swaption_black76(call_flag,tmp_forward_shock, ...
                                        tmp_strike,tmp_effdate,tmp_rf_rate_conv, ...
                                        tmp_imp_vola_shock,tmp_swap_no_pmt, ...
                                        tmp_swap_tenor) .* tmp_multiplier;
            else
                
                theo_value      = swaption_bachelier(call_flag,tmp_forward_shock, ...
                                        tmp_strike,tmp_effdate,tmp_rf_rate_conv, ...
                                        tmp_imp_vola_shock,tmp_swap_no_pmt, ...
                                        tmp_swap_tenor) .* tmp_multiplier;
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
            
            % get volatility according to moneyness and term
            % surface with absolute moneyness K - S
            if ( regexpi(tmp_vola_surf_obj.moneyness_type,'-')) 
                tmp_moneyness = (tmp_strike - Y);
            else % surface with relative moneyness
                tmp_moneyness = (Y ./tmp_strike).^moneyness_exponent; 
            end    

            % interpolation of volatility
            % calculate yy: time between maturity and issue date of underlying
            yy = datenum(leg_fixed_obj.maturity_date) - datenum(leg_fixed_obj.issue_date);
            tmp_imp_vola_shock = tmp_vola_surf_obj.getValue(value_type, ...
                xx,yy,tmp_moneyness) + tmp_impl_vola_spread;
            % call pricing function
            theo_value = swaption_underlyings(call_flag,tmp_strike,V_fix, ...
                               V_float,tmp_effdate,tmp_imp_vola_shock, ...
                               tmp_model);
        end
    end   % close loop if tmp_dtm < 0
    
    % store theo_value vector in appropriate class property   
    if ( regexp(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);  
    elseif ( regexp(value_type,'base'))
        obj = obj.set('value_base',theo_value);    
        obj = obj.set('implied_volatility',tmp_imp_vola_shock);
    else  
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
   
end



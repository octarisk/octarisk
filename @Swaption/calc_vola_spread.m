function obj = calc_vola_spread(swaption,valuation_date,discount_curve,tmp_vola_surf_obj,leg_fixed_obj,leg_float_obj)
    obj = swaption;
    if ( nargin < 3)
        error('Error: No discount curve or vola surface set. Aborting.');
    end
    % Get discount curve nodes and rate
        tmp_nodes        = discount_curve.get('nodes');
        tmp_rates_base   = discount_curve.getValue('base');
    tmp_type = obj.sub_type;
    % Get Call or Putflag
    if ( obj.call_flag == true)
        call_flag = 1;
        moneyness_exponent = 1;
    else
        call_flag = 0;
        moneyness_exponent = -1;
    end
    if ischar(valuation_date)
	   valuation_date = datenum(valuation_date,1);
    end 
    % Get input variables
    
    % Convert tmp_effdate timefactor from Instrument basis to pricing basis (act/365)
    tmp_effdate  = timefactor (valuation_date, ...
                                datenum(obj.maturity_date,1), obj.basis) .* 365;
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
        
        % determining volatility cube axis
        if ( regexpi(tmp_vola_surf_obj.axis_x_name,'TENOR'))
            % x-axis: effective date of swaption -> swaption tenor
            % y-axis: underlying swap tenor -> underlying term
            xx = tmp_effdate;
            yy = tmp_swap_tenor*365;
        elseif ( regexpi(tmp_vola_surf_obj.axis_x_name,'TERM'))
            % x-axis: underlying swap tenor -> underlying term 
            % y-axis: effective date of swaption -> swaption tenor
            xx = tmp_swap_tenor*365;
            yy = tmp_effdate;
        else
            fprintf('Swaption.calc_value: WARNING: Volatility surface has neither TENOR nor TERM axis. Taking value at (0,0). \n');
            xx = 0;
            yy = 0;
        end
        
        % Convert interest rates into act/365 continuous (used by pricing)
        tmp_rf_rate_base = convert_curve_rates(valuation_date,tmp_dtm,tmp_rf_rate_base, ...
                        comp_type_curve,comp_freq_curve,basis_curve, ...
                        'cont','annual',3);
                        
        % Calculate Swaption base value and implied spread
        if (obj.use_underlyings == false)   % pricing with forward rates
            % get volatility according to moneyness and term
            if ( regexpi(tmp_vola_surf_obj.moneyness_type,'-')) % surface with absolute moneyness
                tmp_moneyness_base = (tmp_strike - tmp_forward_base);
            else % surface with relative moneyness
                tmp_moneyness_base = (tmp_forward_base ./tmp_strike).^moneyness_exponent; 
            end 
            tmp_indexvol_base = tmp_vola_surf_obj.getValue('base', ...
                 xx,yy,tmp_moneyness_base);
                 
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
			% Start parameter
			x0 = 0.0001;
			% set lower and upper boundary for volatility
			lb = -tmp_indexvol_base + 0.0001;
			ub = [];
			
			% set up objective function
			objfunc = @ (x) phi_swaption(x,call_flag,tmp_forward_base, ...
                                        tmp_strike,tmp_effdate,tmp_rf_rate_base, ...
                                        tmp_indexvol_base,tmp_swap_no_pmt, ...
                                        tmp_swap_tenor,tmp_multiplier,tmp_value, ...
                                        tmp_model);
			
        else    % pricing with underlying float and fixed leg
            % make sure underlying objects are existing
            if ( nargin < 6)
                error('Error: No underlying fixed and floating leg set. Aborting.');
            end
            V_fix = leg_fixed_obj.getValue('base');
            V_float = leg_float_obj.getValue('base');

            % update implied volatility
            if ~(V_fix == 0.0)
                Y = tmp_strike .* V_float ./ V_fix;
            else
                Y = 0.0;
            end
            % get volatility according to moneyness and term
            % surface with absolute moneyness K - S
            if ( regexpi(tmp_vola_surf_obj.moneyness_type,'-')) 
                tmp_moneyness_base = (tmp_strike - Y);
            else % surface with relative moneyness
                tmp_moneyness_base = (Y ./tmp_strike).^moneyness_exponent; 
            end    

            % interpolation of volatility
            tmp_indexvol_base = tmp_vola_surf_obj.getValue('base', ...
                xx,yy,tmp_moneyness_base);
            
            % call pricing function
            tmp_swaptionvalue_base = swaption_underlyings(call_flag,tmp_strike,V_fix, ...
                                    V_float,tmp_effdate,tmp_indexvol_base, ...
                                    tmp_model)  .* tmp_multiplier;
            % calibrate vola spread
			% Start parameter
			x0 = 0.0001;
			% set lower and upper boundary for volatility
			lb = -tmp_indexvol_base + 0.0001;
			ub = [];
			
			% set up objective function
			objfunc = @ (x) phi_swaption_underlyings(x,call_flag,tmp_strike,V_fix, ...
                                    V_float,tmp_effdate,tmp_indexvol_base, ...
                                    tmp_model,tmp_multiplier,tmp_value);
		
        end

		% calculate spread over yield 	
		[tmp_impl_vola_spread retcode] = calibrate_generic(objfunc,x0,lb,ub);
			
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


%-----------------------------------------------------------------
%------------------- Begin Subfunction ---------------------------
 
% Definition Swaption Objective Function:	    
function obj = phi_swaption (x,PayerReceiverFlag,F,X,T,r,sigma,m,tau,multiplicator,market_value,model)
        if ( strcmp(upper(model),'BLACK76') )
			tmp_swaption_value = swaption_black76(PayerReceiverFlag,F,X,T,r,sigma+x,m,tau) .* multiplicator;
        else
            tmp_swaption_value = swaption_bachelier(PayerReceiverFlag,F,X,T,r,sigma+x,m,tau) .* multiplicator;
        end
        obj = abs( tmp_swaption_value  - market_value)^2;
end
 
% Definition Swaption with Underlyings Objective Function:	    
function obj = phi_swaption_underlyings (x,call_flag,strike,V_fix, V_float,effdate,sigma,model, ...
                        multiplier,market_value)
	    tmp_swaption_value = swaption_underlyings(call_flag,strike,V_fix, ...
                                    V_float,effdate,sigma+x, ...
                                    model)  .* multiplier;
        obj = abs( tmp_swaption_value  - market_value)^2;
end

function obj = calc_value(retail,valuation_date,value_type,discount_curve)
    obj = retail;
    if ( nargin < 3)
        error('No value_type set. [stress,1d,10d,...]');
    end
    if ( nargin < 4)
        error('Error: No  discount curve set. Aborting.');
    end
    if ischar(valuation_date)
		valuation_date = datenum(valuation_date);
    end
    % Get discount curve nodes and rate
        tmp_nodes    = discount_curve.nodes;
        tmp_rates    = discount_curve.getValue(value_type);
    % set start parameter and bounds
		x0 = 0.01;
		lb = -1;
		ub = 1;
    % Get interpolation method and other curve related attributes
        tmp_interp_discount = discount_curve.method_interpolation;
        tmp_curve_basis     = discount_curve.basis;
        tmp_curve_comp_type = discount_curve.compounding_type;
        tmp_curve_comp_freq = discount_curve.compounding_freq;
        
    % Get cf values and dates
		tmp_cashflow_dates  = obj.cf_dates;
		tmp_cashflow_values = obj.getCF(value_type);
    
    % Get bond related basis and conventions
		basis       = obj.basis;
		comp_type   = obj.compounding_type;
		comp_freq   = obj.compounding_freq;
    
    if ( columns(tmp_cashflow_values) == 0 || rows(tmp_cashflow_values) == 0 )
        error('No cash flow values set. CF rollout done?');    
    end

    if (strcmpi(obj.sub_type,'SAVPLAN') || strcmpi(obj.sub_type,'DCP'))
		if ( obj.notice_period > 0 && length(tmp_cashflow_values) > 1)
			% first column: cash flow under first put date, sec column: cf at maturity
			theo_value_putable = pricing_npv(valuation_date, tmp_cashflow_dates(1), ...
										tmp_cashflow_values(:,1), obj.soy, ...
										tmp_nodes, tmp_rates, basis, comp_type, ...
										comp_freq, tmp_interp_discount, ...
										tmp_curve_comp_type, tmp_curve_basis, ...
										tmp_curve_comp_freq);
			theo_value_mat = pricing_npv(valuation_date, tmp_cashflow_dates(2), ...
										tmp_cashflow_values(:,2), obj.soy, ...
										tmp_nodes, tmp_rates, basis, comp_type, ...
										comp_freq, tmp_interp_discount, ...
										tmp_curve_comp_type, tmp_curve_basis, ...
										tmp_curve_comp_freq);
			theo_value = max(theo_value_putable,theo_value_mat) ; 
			if strcmpi(value_type,'base') 
				% calculate embedded option value
				obj = obj.set('embedded_option_value',max(0,theo_value_putable-theo_value_mat));
				% calculate break even interest rate
				objfunc = @ (x) phi_irr(x, valuation_date, ...
											tmp_cashflow_dates(2), ...
											tmp_cashflow_values(:,2), ...
											theo_value_putable,basis, comp_type, ...
											comp_freq);
				xirr = calibrate_generic(objfunc,x0,lb,ub);
				obj = obj.set('ytm',xirr);
			end
		else % no redemption possible
			theo_value = pricing_npv(valuation_date, tmp_cashflow_dates, ...
										tmp_cashflow_values, obj.soy, ...
										tmp_nodes, tmp_rates, basis, comp_type, ...
										comp_freq, tmp_interp_discount, ...
										tmp_curve_comp_type, tmp_curve_basis, ...
										tmp_curve_comp_freq);
		end 
	end
                                    
										
    % store theo_value vector
    if ( regexp(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(value_type,'base'))
        obj = obj.set('value_base',theo_value(1));   
    else
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
   
end

%-------------------------------------------------------------------------------
%--------------------------- Begin Subfunction ---------------------------------

% Definition Objective Function for yield to maturity:         
function obj = phi_irr (x,valuation_date,cashflow_dates, ...
                        cashflow_values,act_value,basis, comp_type, comp_freq)
            tmp_yield = [x];
            % get discount factors for all cash flow dates and ytm rate
            tmp_df  = discount_factor (valuation_date, valuation_date + cashflow_dates', ...
                                                   tmp_yield,comp_type,basis,comp_freq); 
            % Calculate actual NPV of cash flows    
            tmp_npv = cashflow_values * tmp_df;
        
            obj = (act_value - tmp_npv).^2;
end
%-------------------------------------------------------------------------------

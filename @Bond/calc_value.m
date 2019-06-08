function obj = calc_value(bond,valuation_date,value_type,discount_curve,call_schedule,put_schedule)
  obj = bond;
   if ( nargin < 3)
        error('No value_type set. [stress,1d,10d,...]');
   end
   if ( nargin < 4)
        error('Error: No  discount curve set. Aborting.');
   end

    % Get discount curve nodes and rate
        tmp_nodes    = discount_curve.nodes;
        tmp_rates    = discount_curve.getValue(value_type);
    
    % Get interpolation method and other curve related attributes
        tmp_interp_discount = discount_curve.method_interpolation;
        tmp_curve_basis     = discount_curve.basis;
        tmp_curve_comp_type = discount_curve.compounding_type;
        tmp_curve_comp_freq = discount_curve.compounding_freq;
        
    % Get cf values and dates
    tmp_cashflow_dates  = obj.cf_dates;
    tmp_cashflow_values = obj.getCF(value_type);
    
    % Get bond related basis and conventions
    basis       = bond.basis;
    comp_type   = bond.compounding_type;
    comp_freq   = bond.compounding_freq;
    
    if ( columns(tmp_cashflow_values) == 0 || rows(tmp_cashflow_values) == 0 )
        error('No cash flow values set. CF rollout done?');    
    end
    % calculate value according to pricing formula
    [theo_value ] = pricing_npv(valuation_date, tmp_cashflow_dates, ...
                                    tmp_cashflow_values, bond.soy, ...
                                    tmp_nodes, tmp_rates, basis, comp_type, ...
                                    comp_freq, tmp_interp_discount, ...
                                    tmp_curve_comp_type, tmp_curve_basis, ...
                                    tmp_curve_comp_freq);
                                
    % calculate embedded option value
    if ( bond.embedded_option_flag == true)
        if ( nargin < 6)
            error('Error: No call or put schedule set. Aborting.');
        end
        % check whether call or put schedule have been set
        if isobject(call_schedule)
            if ~(strcmpi(call_schedule.type,'Call Schedule'))
                error('Error: Not a call schedule: >>%s<<. Aborting.',any2str(call_schedule.id));
            end
        else    
            call_schedule = [];
        end
        if isobject(put_schedule)
            if ~(strcmpi(put_schedule.type,'Put Schedule'))
                error('Error: Not a put schedule: >>%s<<. Aborting.',any2str(put_schedule.id));
            end
        else    
            put_schedule = [];
        end
        if (length(put_schedule) == 0 && length(call_schedule) == 0)
            error('Error: At least a call or put schedule have to be set.');
        end
        % call option pricing function
        OptionValue = option_bond_hw(value_type,bond,discount_curve, ...
                                                    call_schedule,put_schedule);
        % add embedded Option value
        theo_value = theo_value + OptionValue;
        if ( strcmp(value_type,'base'))
            obj = obj.set('embedded_option_value',OptionValue(1));
        end
    end
	% theo value always dirty
	obj = obj.set('clean_value_base',false);   
										
    % store theo_value vector in appropriate class property
    if ( regexp(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);
    % calculate durations and convexities in base case only
    elseif ( strcmp(value_type,'base'))
        obj = obj.set('value_base',theo_value(1));   
    else
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
   
end



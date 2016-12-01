function s = calc_spread_over_yield (bond,valuation_date,discount_curve,call_schedule,put_schedule)
   s = bond;
   if ( nargin == 2)
        valuation_date = datestr(today);
   elseif ( nargin == 3)
        valuation_date = datestr(valuation_date);

   elseif ( nargin < 2)
        error('Error: No  discount curve set. Aborting.');
   end
   % Get reference curve nodes and rate
        tmp_nodes    = discount_curve.get('nodes');
        tmp_rates    = discount_curve.getValue('base');

    % Get interpolation method
        tmp_interp_discount = discount_curve.get('method_interpolation');
        tmp_curve_dcc       = discount_curve.get('day_count_convention');
        tmp_curve_basis     = discount_curve.get('basis');
        tmp_curve_comp_type = discount_curve.get('compounding_type');
        tmp_curve_comp_freq = discount_curve.get('compounding_freq');
    
    % Get bond related basis and conventions
    basis       = s.basis;
    comp_type   = s.compounding_type;
    comp_freq   = s.compounding_freq;    
  % Check, whether cash flow have already been roll out    
  if ( length(s.cf_values) < 1)
        disp('Warning: No cash flows defined for bond. setting SoY = 0.0')
        s.soy = 0.0;
  else
    % get dirty value
    if s.clean_value_base == 1
        value_dirty = s.value_base + s.accrued_interest;
    else
        value_dirty = s.value_base;
    end

    % calculate embedded option value
    if ( bond.embedded_option_flag == true)
        if ( nargin < 5)
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
        OptionValue = option_bond_hw('base',bond,discount_curve, ...
                                                    call_schedule,put_schedule);
        % adjust value_dirty by embedded option value:
        value_dirty = value_dirty - OptionValue;
    end
    
    % calculate spread over yield (with fixed embedded option value)
    [spread_over_yield retcode] = calibrate_soy_sqp(valuation_date, s.cf_dates, ...
                            s.cf_values(1,:), value_dirty , ...
                            tmp_nodes, tmp_rates, basis, comp_type, comp_freq, ...
                            tmp_interp_discount, tmp_curve_comp_type, ...
                            tmp_curve_basis, tmp_curve_comp_freq);
            
     if ( retcode > 0 ) %failed calibration
        fprintf('Calibration failed for %s. Setting value_base to theo_value.\n',s.id); 
        % calculating theo_value in base case     
        theo_value = pricing_npv(valuation_date,s.cf_dates,s.cf_values(1,:), ...
                0.0,tmp_nodes,tmp_rates, basis, comp_type, ...
                comp_freq, tmp_interp_discount, tmp_curve_comp_type, ...
                tmp_curve_basis, tmp_curve_comp_freq);
        % setting value base to theo value with soy = 0
        s = s.set('value_base',theo_value(1));
        % setting calibration flag to 1 anyhow, since we do not want a failed 
        % calibration a second time...
        s.calibration_flag = 1; 
     else
        s.soy = spread_over_yield;
        s.calibration_flag = 1;
     end
  end
   
end



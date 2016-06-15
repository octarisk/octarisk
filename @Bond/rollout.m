function s = rollout (bond, value_type, arg1, arg2)
  s = bond;

  if ( strcmp(s.sub_type,'FRN'))
    if ( nargin < 3 )
        error ('rollout for sub_type FRN: expecting reference curve object');
    elseif ( nargin == 3)
        tmp_curve_object = arg1;
        valuation_date = datestr(today);
    elseif ( nargin == 4)
        tmp_curve_object = arg1;
        valuation_date = datestr(arg2);
    end
    
    if ischar(valuation_date)
        valuation_date = datenum(valuation_date);
    end

    % call function for rolling out cashflows
    
    % Get reference curve nodes and rate
        reference_nodes    = tmp_curve_object.get('nodes');
        reference_rates    = tmp_curve_object.getValue(value_type);
    % Get interpolation method
        tmp_interp_ref = tmp_curve_object.get('method_interpolation');
    % Get Curve conventions
        tmp_cmp_type = tmp_curve_object.compounding_type;
        tmp_cmp_freq = tmp_curve_object.compounding_freq;               
        tmp_dcc = tmp_curve_object.day_count_convention; 
    % call function for generating CF dates and values
    [ret_dates ret_values ] = rollout_cashflows_oop(s,reference_nodes, ...
                        reference_rates,valuation_date,tmp_interp_ref,...
                        tmp_cmp_type,tmp_dcc,tmp_cmp_freq);

  % type CASHFLOW -> duplicate all base cashflows
  elseif ( strcmpi(s.sub_type,'CASHFLOW') )
    ret_dates  = s.get('cf_dates');
    ret_values = s.get('cf_values');
    
  % all other bond types (like FRB etc.)
  else  
    if ( nargin < 3)
        valuation_date = datestr(today);
    elseif ( nargin == 3)
        valuation_date = datestr(arg1);
    end
    % call function for rolling out cashflows
    [ret_dates ret_values ] = rollout_cashflows_oop(s,[],[],valuation_date);
  end
  
    % set property value pairs to object
    s = s.set('cf_dates',ret_dates);
    if ( strcmp(value_type,'stress'))
        s = s.set('cf_values_stress',ret_values);
    elseif ( strcmp(value_type,'base')) 
        s = s.set('cf_values',ret_values);
    else
        s = s.set('cf_values_mc',ret_values,'timestep_mc_cf',value_type);
    end
   
end



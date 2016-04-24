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
    endif
    % call function for rolling out cashflows
    
    % Get reference curve nodes and rate
        reference_nodes    = tmp_curve_object.get('nodes');
        reference_rates    = tmp_curve_object.getValue(value_type);
    % Get interpolation method
        tmp_interp_ref = tmp_curve_object.get('method_interpolation');
        
    [ret_dates ret_values ] = rollout_cashflows_oop(s,reference_nodes,reference_rates,valuation_date,tmp_interp_ref);
  
  % type CASHFLOW -> duplicate all base cashflows
  elseif ( strcmp(s.sub_type,'CASHFLOW') )
    ret_dates  = s.get('cf_dates');
    ret_values = s.get('cf_values');
    
  % all other bond types (like FRB etc.)
  else  
    if ( nargin < 3)
        valuation_date = datestr(today);
    elseif ( nargin == 3)
        valuation_date = datestr(arg1);
    endif
    % call function for rolling out cashflows
    [ret_dates ret_values ] = rollout_cashflows_oop(s,[],[],valuation_date);
  endif
  
    % set property value pairs to object
    s = s.set('cf_dates',ret_dates);
    if ( strcmp(value_type,'stress'))
        s = s.set('cf_values_stress',ret_values);
    elseif ( strcmp(value_type,'base')) 
        s = s.set('cf_values',ret_values);
    else
        s = s.set('cf_values_mc',ret_values,'timestep_mc_cf',value_type);
    end
   
endfunction



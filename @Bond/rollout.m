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

    % call function for generating CF dates and values and accrued_interest
    [ret_dates ret_values accr_int last_coupon_date ] = rollout_structured_cashflows( ...
                                valuation_date,value_type,s,tmp_curve_object);

  % type CASHFLOW -> duplicate all base cashflows
  elseif ( strcmpi(s.sub_type,'CASHFLOW') )
    ret_dates  = s.get('cf_dates');
    ret_values = s.get('cf_values');
    accr_int = 0.0;
    last_coupon_date = 0.0;
  % all other bond types (like FRB etc.)
  else  
    if ( nargin < 3)
        valuation_date = datestr(today);
    elseif ( nargin == 3)
        valuation_date = datestr(arg1);
    end
    % call function for rolling out cashflows
    [ret_dates ret_values accr_int last_coupon_date] = ...
                    rollout_structured_cashflows(valuation_date,value_type,s);
  end
  
  % set property value pairs to object
  s = s.set('cf_dates',ret_dates);
  s = s.set('accrued_interest',accr_int);
  s = s.set('last_coupon_date',last_coupon_date);
  if ( strcmp(value_type,'stress'))
      s = s.set('cf_values_stress',ret_values);
  elseif ( strcmp(value_type,'base')) 
      s = s.set('cf_values',ret_values);
  else
      s = s.set('cf_values_mc',ret_values,'timestep_mc_cf',value_type);
  end
   
end



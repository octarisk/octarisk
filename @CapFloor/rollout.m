function s = rollout (capfloor, valuation_date, value_type, curve_object, vola_surface)
  s = capfloor;
    
  if ischar(valuation_date)
      valuation_date = datenum(valuation_date);
  end

  % call function for generating CF dates and values and accrued_interest
  [ret_dates ret_values ] = rollout_structured_cashflows(valuation_date, ...
                            value_type, s, curve_object, vola_surface);
  
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



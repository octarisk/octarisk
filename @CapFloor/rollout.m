function s = rollout (capfloor, valuation_date, value_type, arg1, arg2, arg3)
  s = capfloor;
    
  if ischar(valuation_date)
      valuation_date = datenum(valuation_date);
  end

  if ( regexpi(s.sub_type,'INFL'))
        if ( nargin < 6 )
            error ('rollout for sub_type CAP/FLOOR_INFL: expecting valuation_date, value_type,inflation expectation curve, historical curve, cpi index objects');
        end
        
        iec_obj     = arg1;
        hist_obj    = arg2;
        cpi_obj     = arg3;
        % todo: add strike rate curve
        
        % call function for generating CF dates and values
        [ret_dates ret_values ] = rollout_structured_cashflows(valuation_date, ...
                                value_type,  s, iec_obj, hist_obj, cpi_obj);
                                
  else  % all other caps/floors on interest rates   
        if ( nargin < 5 )
            error ('rollout for sub_type CAP/FLOOR: expecting valuation_date, value_type, curve_object, vola_surface');
        end
        % call function for generating CF dates and values
        curve_object  = arg1;
        vola_surface  = arg2;
        [ret_dates ret_values ] = rollout_structured_cashflows(valuation_date, ...
                                value_type, s, curve_object, vola_surface);
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



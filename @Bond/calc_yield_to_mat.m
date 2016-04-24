function s = calc_yield_to_mat (bond, valuation_date)
  s = bond;
 
  if ( nargin < 2)
        valuation_date = datestr(today);
  elseif ( nargin == 2)
        valuation_date = datestr(valuation_date);
  end
  % Check, whether cash flow have already been roll out  
  if ( length(s.cf_values) < 1)
        disp('Warning: No cash flows defined for bond. setting YtM = 0.0')
        s.ytm = 0.0;
  else
        s.ytm = calibrate_yield_to_maturity(valuation_date,s.cf_dates,s.cf_values,s.value_base);       
  end
   
end

function s = calc_spread_over_yield (bond,discount_curve,spread_curve,valuation_date)
   s = bond;
   if ( nargin == 3)
        valuation_date = datestr(today);
   elseif ( nargin == 4)
        valuation_date = datestr(valuation_date);

   elseif ( nargin < 3)
        error("Error: No  discount curve or spread curve set. Aborting.");
   endif
   % Get reference curve nodes and rate
        tmp_nodes    = discount_curve.get('nodes');
        tmp_rates    = discount_curve.getValue('base');
        spread_nodes = spread_curve.get('nodes');
        spread_rates = spread_curve.getValue('base');
  % Check, whether cash flow have already been roll out    
  if ( length(s.cf_values) < 1)
        disp("Warning: No cash flows defined for bond. setting SoY = 0.0")
        s.ytm = 0.0;
  else
    s.soy = calibrate_soy_sqp(valuation_date,s.cf_dates, s.cf_values(1,:),s.value_base, ... 
                tmp_nodes,tmp_rates,spread_nodes,spread_rates,s.basis,s.compounding_type,s.compounding_freq);     
  endif
   
endfunction



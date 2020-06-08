function bond = calc_ilb_break_even (bond,valuation_date,discount_curve,iec,hist,cpi)
   
   if ( nargin < 6)
        error('Error: too few arguments. valuation date, discount curve, iec, hist and cpi required. Aborting.');
   end
   
   if ischar(valuation_date)
       valuation_date = datenum(valuation_date,1);
   end
 % requirement: discount curve contains interest rates of reference fixed rate 
 % bond with equal credit spread risk of identical underlying issuers
 % 0) copy bond object
	ilb = bond;
 % 1) set IEC rates to zero 
	iec = iec.set('nodes',[365],'rates_base',[0.0],'method_interpolation','linear');

 % 2) rollout cashflows --> rollout of cashflows with zero inflation rate assumptions
    ilb = ilb.rollout ('base', valuation_date, iec, hist, cpi);

 % 3) perform spread over yield calculation: calculated soy matches implicit 
 % expected inflation rate assumptions to hit market value
	ilb = ilb.calc_spread_over_yield (valuation_date,discount_curve);
	
 % 4) negative soy == break even inflation rate
	bond.set('break_even_inflation',-ilb.soy);
 
end

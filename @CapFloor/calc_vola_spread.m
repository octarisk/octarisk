function obj = calc_vola_spread (capfloor,valuation_date,discount_curve,vola_surface)
   obj = capfloor;
    if ( nargin < 4)
        error('Error: No discount curve set. Aborting.');
    end
	
	if ( regexpi(obj.sub_type,'INFL'))
		error ('No vola spread calibration possible for sub_type CAP/FLOOR_INFL');
	end

	% get market value
	market_value = obj.getValue('base');
	
	% Start parameter
	x0 = -0.0001;

	% Setting lower bound to minimum of volatility value
	sigma = min(min(min((vola_surface.values_base))));
	lb = -sigma + 0.00001;
	ub = [];
	
	% set up objective function
	objfunc = @ (x) phi(x,obj,valuation_date,discount_curve,vola_surface,market_value);
	
	% calibrate with generic script	
    [vola_spread retcode] = calibrate_generic(objfunc,x0,lb,ub);

	
	% - get return code and set base value / volaspread accordingly    
    if ( retcode > 0 ) %failed calibration
        fprintf('Calibration failed for %s. Setting value_base to uncalibrated value.\n',obj.id); 
		
        % calculating theo_value in base case   
		obj = obj.rollout(valuation_date,'base',discount_curve,vola_surface);
		obj = obj.calc_value(valuation_date,'base',discount_curve);		
        theo_value = obj.getValue('base');
		
        % setting value base to theo value with soy = 0
        obj = obj.set('value_base',theo_value(1));
		
        % setting calibration flag to 1 anyhow, since we do not want a failed 
        % calibration a second time...
        s.calibration_flag = 1;
		
    else % successful calibration ? check for match of base value with market value
		obj.vola_spread = vola_spread;
		
		% new cashflow rollout with calibrated vola_spread
		obj = obj.rollout(valuation_date,'base',discount_curve,vola_surface);
		obj = obj.calc_value(valuation_date,'base',discount_curve);		
        theo_value = obj.getValue('base');
		
		% make check of absolute values, since optimization also calculated absolute deviation
		if ( abs(market_value - theo_value) > 0.00001 ) % calibration failed obviously
			fprintf('Calibration failed for %s (values differ by more than 0.00001). Setting value_base to uncalibrated value.\n',obj.id); 
			obj.vola_spread = 0.0;
			
			% calculating theo_value in base case   
			obj = obj.rollout(valuation_date,'base',discount_curve,vola_surface);
			obj = obj.calc_value(valuation_date,'base',discount_curve);		
			theo_value = obj.getValue('base');
			
			% setting value base to theo value with soy = 0
			obj = obj.set('value_base',theo_value(1));
		end
		
		obj.calibration_flag = 1;
    end
   
end


%-------------------------------------------------------------------------------
%------------------- Begin Subfunction -----------------------------------------
 
% Definition Objective Function:	    
function obj = phi (x,capfloor,valuation_date,discount_curve,vola_surface, market_value)
        obj = capfloor;
		obj.vola_spread = x;
		% cash flow rollout
		obj = obj.rollout(valuation_date,'base',discount_curve,vola_surface);
		% instrument prices
		obj = obj.calc_value(valuation_date,'base',discount_curve);
		% objective function
        obj = abs( obj.getValue('base')  - market_value)^2;
end
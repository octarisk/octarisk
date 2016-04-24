function obj = calc_value (debt,discount_curve_object,spread_object,value_type)
  obj = debt;
   if ( nargin < 3)
        error('Error: No  discount or spread curve set. Aborting.');
   endif
   if ( nargin == 3)
        error('No value_type set. [stress,1d,10d,...]');
   endif
    value_type = tolower(value_type);
    % Get duration and convexity
        tmp_dur         = debt.get('duration');
        tmp_convex      = debt.get('convexity');
        tmp_value_base  = debt.get('value_base');
    % Get Discount Curve nodes and rate
        discount_nodes          = discount_curve_object.get('nodes');
        discount_rates_orig     = discount_curve_object.getValue('base');
        discount_rates_shifted  = discount_curve_object.getValue(value_type);
    % Get Spread Curve nodes and rate        
        spread_nodes 		    = spread_object.get('nodes');
        spread_rates_orig 	    = spread_object.getValue('base');
        spread_rates_shifted 	= spread_object.getValue(value_type);

    % Get Yields and spreads at instrument duration 
        yield_original  = interpolate_curve(discount_nodes,discount_rates_orig,tmp_dur*365,discount_curve_object.get('method_interpolation'));
        yield_shifted   = interpolate_curve(discount_nodes,discount_rates_shifted,tmp_dur*365,discount_curve_object.get('method_interpolation'));       
        spread_original	= interpolate_curve(spread_nodes,spread_rates_orig,tmp_dur*365,spread_object.get('method_interpolation'));
        spread_shifted  = interpolate_curve(spread_nodes,spread_rates_shifted,tmp_dur*365,spread_object.get('method_interpolation'));
        

    % Calculate Shiftvalue
        tmp_ir_abs_diff = ( yield_shifted - yield_original + spread_shifted - spread_original);
        tmp_diff_rel    = -tmp_dur .* ( tmp_ir_abs_diff) + tmp_convex .* (tmp_ir_abs_diff).^2;
        theo_value      = tmp_value_base .* ( tmp_diff_rel + 1);    
        
    % store theo_value vector in appropriate class property
    if ( regexp(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(value_type,'base'))
        obj = obj.set('value_base',tmp_value_base);
    else,
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    endif
   
endfunction



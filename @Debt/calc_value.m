function obj = calc_value (debt,discount_curve_object,value_type)
  obj = debt;
   if ( nargin < 2)
        error('Error: No  discount or spread curve set. Aborting.');
   end
   if ( nargin == 2)
        error('No value_type set. [stress,1d,10d,...]');
   end
    value_type = lower(value_type);
    % Get duration and convexity
        tmp_dur         = debt.get('duration');
        tmp_convex      = debt.get('convexity');
        tmp_value_base  = debt.get('value_base');
    % Get Discount Curve nodes and rate
        discount_nodes          = discount_curve_object.get('nodes');
        discount_rates_orig     = discount_curve_object.getValue('base');
        discount_rates_shifted  = discount_curve_object.getValue(value_type);
    % Get Yields and spreads at instrument duration 
        yield_original  = interpolate_curve(discount_nodes,discount_rates_orig, ...
                tmp_dur*365,discount_curve_object.get('method_interpolation'));
        yield_shifted   = interpolate_curve(discount_nodes,discount_rates_shifted, ...
                tmp_dur*365,discount_curve_object.get('method_interpolation'));       

    % Calculate Shiftvalue
        tmp_ir_abs_diff = yield_shifted - yield_original;
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
    end
   
end



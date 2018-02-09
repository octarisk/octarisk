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
        tmp_dur         = debt.duration;
		tmp_term        = debt.term;
        tmp_convex      = debt.convexity;
        tmp_value_base  = debt.value_base;
    % Get Yields and spreads at instrument duration 
        yield_original  = discount_curve_object.getRate('base',tmp_term * 365);
        yield_shifted   = discount_curve_object.getRate(value_type,tmp_term * 365);      

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



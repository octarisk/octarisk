function obj = calc_value (debt,discount_nodes,discount_rates_orig,discount_rates,spread_nodes,spread_rates_orig,spread_rates,value_type)
  obj = debt;
   if ( nargin < 7)
        error("Error: No  discount or spread curve set. Aborting.");
   endif
   if ( nargin == 7)
        error("No value_type set. [stress,1d,10d,...]");
   endif
    value_type = tolower(value_type);
    % Get duration and convexity
        tmp_dur         = debt.get("duration");
        tmp_convex      = debt.get("convexity");
        tmp_value_base  = debt.get("value_base");
    % Get Yields and spreads at instrument duration 
        yield_original  = interpolate_curve(discount_nodes,discount_rates_orig,tmp_dur*365);
        yield_shifted   = interpolate_curve(discount_nodes,discount_rates,tmp_dur*365);
        spread_original	= interpolate_curve(spread_nodes,spread_rates_orig,tmp_dur*365);
        spread_shifted  = interpolate_curve(spread_nodes,spread_rates,tmp_dur*365);

    % Calculate Shiftvalue
        tmp_ir_abs_diff = ( yield_shifted .- yield_original .+ spread_shifted .- spread_original);
        tmp_diff_rel    = -tmp_dur .* ( tmp_ir_abs_diff) .+ tmp_convex .* (tmp_ir_abs_diff).^2;
        theo_value      = tmp_value_base .* ( tmp_diff_rel .+ 1);    
        
    % store theo_value vector in appropriate class property
    if ( regexp(value_type,'stress'))
        obj = obj.set("value_stress",theo_value);
    elseif ( strcmp(value_type,'base'))
        obj = obj.set("value_base",tmp_value_base);
    else
        obj = obj.set("timestep_mc",value_type);
        obj = obj.set("value_mc",theo_value);
    endif
   
endfunction



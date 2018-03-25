% method of class @Curve
function rate = getRate (curve, value_type, node)
  
% input checks
    if ( nargin < 3 )
        error ('Curve.getRate method requires value_type and node.');
    end
    
% Curve variables
    nodes       = curve.nodes;
    rates       = curve.getValue(value_type);
    interp_method = curve.method_interpolation;

% interpolate
	% vector or linear interpolation -> fall fast cpp method
	if ( length(node) > 1 && strcmpi(interp_method,'linear'))
		if ( length(node) == 1 && strcmpi(interp_method,'linear'))
			% interpolation of single node: call fast and simple version
			rate = interpolate_curve_vectorized_mc(nodes,rates,node);
		else
			% if more than one node should be interpolated, call generic version
			rate = interpolate_curve_vectorized(nodes,rates,node);
		end
	else
		% for all other cases of if different interpolation methods are required
		rate = interpolate_curve(nodes,rates,node,interp_method, ...
			curve.get('ufr'),curve.get('alpha'),curve.get('method_extrapolation'));
	end
end

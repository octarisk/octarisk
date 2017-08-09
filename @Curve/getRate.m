% method of class @Curve
function rate = getRate (curve, value_type, node)
  
% input checks
    if ( nargin < 3 )
        error ('Curve.getRate method requires value_type and node.');
    end
    
% Curve variables
    nodes       = curve.get('nodes');
    rates       = curve.getValue(value_type);
    interp_method = curve.get('method_interpolation');
	extrap_method = curve.get('method_extrapolation');
    ufr         = curve.get('ufr');
    alpha       = curve.get('alpha');

% interpolate
	% vector or linear interpolation -> fall fast cpp method
	if ( length(node) > 1 || strcmpi(interp_method,'linear'))
		rate = interpolate_curve_vectorized(nodes,rates,node);
	else
		rate = interpolate_curve(nodes,rates,node,interp_method,ufr,alpha,extrap_method);
	end
end
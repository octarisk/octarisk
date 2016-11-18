% method of class @Curve
function rate = getRate (curve, value_type, node)
  
% input checks
    if ( nargin < 3 )
        error ('Curve interpolation requires value_type and node.');
    end
    
% Curve variables
    nodes       = curve.get('nodes');
    rates       = curve.getValue(value_type);
    interp_method = curve.get('method_interpolation');
    ufr         = curve.get('ufr');
    alpha       = curve.get('alpha');

% interpolate
    rate = interpolate_curve(nodes,rates,node,interp_method,ufr,alpha);
  
end
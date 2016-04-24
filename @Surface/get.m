% method of class @Surface
function s = get (obj, property)
  if (nargin == 1)
    s = obj.name;
  elseif (nargin == 2)
    if (ischar (property))
      switch (property)
        case 'name'
          s = obj.name;
        case 'id'
          s = obj.id;
        case 'description'
          s = obj.description; 
        case 'type'
          s = obj.type; 
        case 'values_base'
          s = obj.values_base;    
        case 'axis_x'
          s = obj.axis_x;
        case 'axis_y'
          s = obj.axis_y;
        case 'axis_z'
          s = obj.axis_z;
        case 'axis_x_name'
          s = obj.axis_x_name;
        case 'axis_y_name'
          s = obj.axis_y_name;
        case 'axis_z_name'
          s = obj.axis_z_name;
        case 'moneyness_type'
          s = obj.moneyness_type; 
        case 'method_interpolation'
          s = obj.method_interpolation;
        otherwise
          error ('get: invalid property %s', property);
      endswitch
    else
      error ('get: expecting the property to be a string');
    endif
  else
    print_usage ();
  endif
endfunction
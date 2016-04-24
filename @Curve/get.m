% method of class @Curve
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
        case 'rates_mc'
          s = obj.rates_mc;    
        case 'rates_stress'
          s = obj.rates_stress;
        case 'timestep_mc'
          s = obj.timestep_mc; 
        case 'nodes'
          s = obj.nodes; 
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
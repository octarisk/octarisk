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
        case 'rates_base'
          s = obj.rates_base;   
        case 'rates_stress'
          s = obj.rates_stress;
        case 'timestep_mc'
          s = obj.timestep_mc; 
        case 'nodes'
          s = obj.nodes; 
        case 'shocktype_mc'
          s = obj.shocktype_mc; 
        case 'increments'
          s = obj.increments;
        case 'day_count_convention'
          s = obj.day_count_convention;
        case 'compounding_type'
          s = obj.compounding_type;
        case 'compounding_freq'
          s = obj.compounding_freq;
        case 'method_interpolation'
          s = obj.method_interpolation;
        otherwise
          error ('get: invalid property %s', property);
      end
    else
      error ('get: expecting the property to be a string');
    end
  else
    print_usage ();
  end
end
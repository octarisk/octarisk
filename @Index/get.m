% @Index/get.m
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
        case 'currency'
          s = obj.currency; 
        case 'scenario_mc'
          s = obj.scenario_mc;    
        case 'scenario_stress'
          s = obj.scenario_stress;
        case 'timestep_mc'
          s = obj.timestep_mc; 
        case 'value_base'
          s = obj.value_base;
        case 'start_value'
          s = obj.value_base;
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
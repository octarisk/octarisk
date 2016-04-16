% @Riskfactor/get.m
function s = get (obj, property)
  if (nargin == 1)
    s = obj.name;
  elseif (nargin == 2)
    if (ischar (property))
      switch (property)
        case "name"
          s = obj.name;
        case "id"
          s = obj.id;
        case "description"
          s = obj.description; 
        case "type"
          s = obj.type; 
        case "model"
          s = obj.model;   
        case "scenario_mc"
          s = obj.scenario_mc;    
        case "scenario_stress"
          s = obj.scenario_stress;
        case "timestep_mc"
          s = obj.timestep_mc; 
        case "mean"
          s = obj.mean; 
        case "std"
          s = obj.std;   
        case "skew"
          s = obj.skew; 
        case "kurt"
          s = obj.kurt; 
        case "value_base"
          s = obj.value_base;
        case "start_value"
          s = obj.value_base;
        case "mr_level"
          s = obj.mr_level;
        case "mr_rate"
          s = obj.mr_rate;
        case "node"
          s = obj.node;
        case "rate"
          s = obj.value_base; 
        otherwise
          error ("get: invalid property %s", property);
      endswitch
    else
      error ("get: expecting the property to be a string");
    endif
  else
    print_usage ();
  endif
endfunction
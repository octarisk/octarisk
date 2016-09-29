function s = get (bond, property)
  obj = bond;
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
        case 'model'
          s = obj.model;        
        case 'asset_class'
          s = obj.asset_class;   
        case 'currency'
          s = obj.currency;
        case 'value_mc'
          s = obj.value_mc; 
        case 'value_base'
          s = obj.value_base;   
        case 'value_stress'
          s = obj.value_stress;
        case 'sub_type'
          s = obj.sub_type;  
        case 'vola_spread'
          s = obj.vola_spread;  
        case 'timestep_mc'
          s = obj.timestep_mc; 
        case 'vola_surface'
          s = obj.vola_surface;
        case 'vola_spread'
          s = obj.vola_spread;
        case 'discount_curve'
          s = obj.discount_curve; 
        case 'cf_dates'
          s = obj.cf_dates; 
        case 'cf_values'
          s = obj.cf_values; 
        case 'und_fixed_leg'
          s = obj.und_fixed_leg; 
        case 'und_floating_leg'
          s = obj.und_floating_leg; 
        case 'use_underlyings'
          s = obj.use_underlyings;
        case 'effective_date'
          s = obj.effective_date;
        case 'und_fixed_value'
          s = obj.und_fixed_value;
        case 'und_float_value'
          s = obj.und_float_value;
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
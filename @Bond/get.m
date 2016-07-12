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
        case 'asset_class'
          s = obj.asset_class;   
        case 'currency'
          s = obj.currency;
        case 'valuation_date'
          s = obj.valuation_date;
        case 'value_mc'
          s = obj.value_mc; 
        case 'value_base'
          s = obj.value_base;   
        case 'value_stress'
          s = obj.value_stress;
        case 'sub_type'
          s = obj.sub_type;  
        case 'convexity'
          s = obj.convexity;  
        case 'timestep_mc'
          s = obj.timestep_mc; 
        case 'timestep_mc_cf'
          s = obj.timestep_mc_cf;
        case 'discount_curve'
          s = obj.discount_curve; 
        case 'spread_curve'
          s = obj.spread_curve;
        case 'reference_curve'
          s = obj.reference_curve;  
        case 'cf_dates'
          s = obj.cf_dates; 
        case 'cf_values'
          s = obj.cf_values;
        case 'cf_values_stress'
          s = obj.cf_values_stress;
        case 'cf_values_mc'
          s = obj.cf_values_mc;
        case 'soy'
          s = obj.soy;
        case 'basis'
          s = obj.basis;
        case 'compounding_type'
          s = obj.compounding_type; 
        case 'compounding_freq'
          s = obj.compounding_freq;   
        case 'mac_duration'
          s = obj.mac_duration;  
        case 'mod_duration'
          s = obj.mod_duration; 
        case 'calibration_flag'
          s = obj.calibration_flag; 
        case 'accrued_interest'
          s = obj.accrued_interest;
        case 'clean_value_base'
          s = obj.clean_value_base;
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
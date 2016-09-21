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
        case 'maturity_date'
          s = obj.maturity_date; 
        case 'issue_date'
          s = obj.issue_date; 
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
        case 'adj_duration'
          s = obj.mod_duration; 
        case 'eff_duration'
          s = obj.eff_duration; 
        case 'ir_shock'
          s = obj.ir_shock;
        case 'eff_convexity'
          s = obj.eff_convexity; 
        case 'mon_convexity'
          s = obj.dollar_convexity; 
        case 'dollar_convexity'
          s = obj.dollar_convexity; 
        case 'dv01'
          s = obj.dv01; 
        case 'pv01'
          s = obj.pv01;   
        case 'dollar_duration'
          s = obj.dollar_duration; 
        case 'spread_duration'
          s = obj.spread_duration;  
        case 'calibration_flag'
          s = obj.calibration_flag; 
        case 'accrued_interest'
          s = obj.accrued_interest;
        case 'last_coupon_date'
          s = obj.last_coupon_date;
        case 'coupon_rate'
          s = obj.coupon_rate;
        case 'notional'
          s = obj.notional;
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
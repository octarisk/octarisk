% method of class @Curve
function s = getValue (curve, property)
  obj = curve;
  if (nargin == 1)
    s = obj.name;
  elseif (nargin == 2)
    if (ischar (property))
      property = lower(property);
      if ( strcmp(property,'stress'))
        s = obj.rates_stress;
      elseif ( strcmp(property,'base'))
        s = obj.rates_base;  
      else
        tmp_timestep_mc = obj.timestep_mc;
        tmp_vec = strcmp(property,tmp_timestep_mc);
        if ( sum(tmp_vec) > 0)                  
            tmp_col = tmp_vec * (1:length(tmp_vec))';
            s = obj.rates_mc(:,:,tmp_col);    
        else
            printf ('get: invalid property %s. Neither stress nor MC timestep found.\n', property);
            printf ('get: Allowed mc time steps:\n')
            obj.timestep_mc
            s = [];
        end
      end 
    else
      error ('get: expecting the property to be a string');
    end
  else
    print_usage ();
  end
end
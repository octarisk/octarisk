% Instrument Class @Instrument
function s = getValue (instrument, property)
  obj = instrument;
  if (nargin == 1)
    s = obj.name;
  elseif (nargin == 2)
    if (ischar (property))
      property = lower(property);
      if ( strcmp(property,'stress'))
        s = obj.value_stress;
        if ( isempty(s) )
            %printf ('get: No stress values found. Returning base value.\n')
            s = obj.value_base; 
        end
      elseif ( strcmp(property,'base'))
        s = obj.value_base;
      else
        tmp_timestep_mc = obj.timestep_mc;
        tmp_vec = strcmp(property,tmp_timestep_mc);
        if ( sum(tmp_vec) > 0)                  
            tmp_col = tmp_vec * (1:length(tmp_vec))';
            s = obj.value_mc(:,tmp_col);    
        else
            %printf ('get: invalid property %s. No MC timestep found. Returning base value.\n', property);
            s = obj.value_base; 
        end
      end 
    else
      error ('get: expecting the property to be a string');
    end
  else
    print_usage ();
  end
end
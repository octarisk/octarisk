% method of class @option
function s = getVola (option, property)
  obj = option;
  if (nargin == 1)
    s = obj.name;
  elseif (nargin == 2)
    if (ischar (property))
      property = tolower(property);
      if ( strcmp(property,'stress'))
        s = obj.cf_values_stress;
      elseif ( strcmp(property,'base'))
        s = obj.cf_values;  
      else
        tmp_timestep_mc = obj.timestep_mc_cf;
        tmp_vec = strcmp(property,tmp_timestep_mc);
        if ( sum(tmp_vec) > 0)                  
            tmp_col = tmp_vec * (1:length(tmp_vec))';
            s = obj.cf_values_mc(:,:,tmp_col);    
        else
            printf ("get: invalid property %s. Neither stress nor MC timestep found.\n", property);
            printf ("get: Allowed mc time steps:\n")
            obj.timestep_mc
            s = [];
        endif
      endif 
    else
      error ("get: expecting the property to be a string");
    endif
  else
    print_usage ();
  endif
endfunction
%# -*- texinfo -*-
%# @deftypefn  {Function File} {} Riskfactor ()
%# @deftypefnx {Function File} {} Riskfactor (@var{a})
%# Riskfactor Method getValue 
%# This method returns the value for a risk factor object. Specify the desired return values with a property parameter.
%# If the second argument abs is set, the absolut scenario value is calculated from scenario shocks and the risk factor start value.
%# @*
%# Timestep properties:
%# @itemize @bullet
%# @item base: return base value
%# @item stress: return stress values
%# @item 1d: return MC timestep
%# @end itemize
%# @seealso{Instrument}
%# @end deftypefn

function s = getValue (riskfactor, property, abs_flag, sensitivity) % method getValue for riskfactors
  obj = riskfactor;
  if (nargin == 1)
    s = obj.name;
  elseif (nargin > 1)
    if (ischar (property))
      property = tolower(property);
      if ( strcmp(property,'stress'))
        s = obj.scenario_stress;
      elseif ( strcmp(property,'base'))
        s = obj.value_base;  
      else
        tmp_timestep_mc = obj.timestep_mc;
        tmp_vec = strcmp(property,tmp_timestep_mc);
        if ( sum(tmp_vec) > 0)                  
            tmp_col = tmp_vec * (1:length(tmp_vec))';
            s = obj.scenario_mc(:,tmp_col);    
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
  
  % in case of abs_flag == 'abs' -> calculate and return absolute scenario value
  % take sensitivity into account
  if nargin == 4
      sensi = sensitivity;
  else
      sensi = 1;
  end
  if nargin >= 3
    if ( strcmp(abs_flag,'abs') )
        s = Riskfactor.get_abs_values(obj.model, s, obj.value_base, sensi);
    else
        s = s;
    end  
  end
end

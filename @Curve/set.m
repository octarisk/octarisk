% setting Curve base, MC scenario and stress values
function s = set (obj, varargin)
  s = obj;
  if (length (varargin) < 2 || rem (length (varargin), 2) ~= 0)
    error ('set: expecting property/value pairs');
  end
  while (length (varargin) > 1)
    prop = varargin{1};
    prop = lower(prop);
    val = varargin{2};
    varargin(1:2) = [];
    % ====================== set rates_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    if (ischar (prop) && strcmp (prop, 'rates_mc'))   
      if (isreal (val))
        [mc_rows mc_cols mc_stack] = size(s.rates_mc);
        if ( mc_cols > 0 || mc_rows > 0) % appending vector to existing vector
            if ( length(val) == length(s.rates_mc(:,:,mc_stack)))
                s.rates_mc(:,:,mc_stack + 1) = val;
            else
                error('set: expecting length of new input vector to equal length of already existing rate vector');
            end
        else    % setting vector
            [val_rows val_cols val_stack] = size(val);
            if val_stack == 1   % is matrix
                s.rates_mc(:,:,1) = val;
            else
                s.rates_mc = val;
            end
        end  
        
      else
        error ('set: expecting the mc values to be real ');
      end
    % ====================== set timestep_mc: appending or setting timestep vector ======================
    elseif (ischar (prop) && strcmp (prop, 'timestep_mc')) 
      if (iscell(val) && length(val) == 1)
        tmp_cell = s.timestep_mc;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            s.timestep_mc{length(tmp_cell) + 1} = char(val);
        else    % setting vector
            s.timestep_mc = val;
        end      
      elseif (iscell(val) && length(val) > 1) % replacing timestep_mc cell vector with new vector
        s.timestep_mc = val;
      elseif ( ischar(val) )
        tmp_cell = s.timestep_mc;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            s.timestep_mc{length(tmp_cell) + 1} = char(val);
        else    % setting vector
            s.timestep_mc = cellstr(val);
        end 
      else
        error ('set: expecting the cell value to be a cell vector');
      end  
    % ====================== set rates_stress ======================
    elseif (ischar (prop) && strcmp (prop, 'rates_stress'))   
      if (isreal (val))
        s.rates_stress = val;
      else
        error ('set: expecting the stress value to be real ');
      end
    % ====================== set rates_base ======================
    elseif (ischar (prop) && strcmp (prop, 'rates_base'))   
      if (ismatrix (val) && isreal (val))
        s.rates_base = val;
      else
        error ('set: expecting the base values to be a real vector');
      end
    % ====================== set nodes ======================
    elseif (ischar (prop) && strcmp (prop, 'nodes'))   
      if (isnumeric (val) && isreal (val))
        s.nodes = val;
      else
        error ('set: expecting the value to be a real scalar');
      end
    % ====================== set increments   ======================
    elseif (ischar (prop) && strcmp (prop, 'increments'))   
      if (iscell (val))
        s.increments = strtrim(val);
      else
        error ('set: expecting the value to be a cell');
      end 
    % ====================== set method_interpolation ======================
    elseif (ischar (prop) && strcmp (prop, 'method_interpolation'))   
      if (ischar (val))
        s.method_interpolation = strtrim(val);
      else
        error ('set: expecting the value to be of type character');
      end
    % ====================== set compounding_freq ======================
    elseif (ischar (prop) && strcmp (prop, 'compounding_freq'))   
      if (ischar (val))
        s.compounding_freq = strtrim(val);
      else
        error ('set: expecting the value to be of type character');
      end
    % ====================== set day_count_convention ======================
    elseif (ischar (prop) && strcmp (prop, 'day_count_convention'))   
      if (ischar (val))
        s.day_count_convention = strtrim(val);
      else
        error ('set: expecting the value to be of type character');
      end 
    % ====================== set compounding_type ======================
    elseif (ischar (prop) && strcmp (prop, 'compounding_type'))   
      if (ischar (val))
        s.compounding_type = strtrim(val);
      else
        error ('set: expecting the value to be of type character');
      end      
    % ====================== set name ======================
    elseif (ischar (prop) && strcmp (prop, 'name'))   
      if (ischar (val) )
        s.name = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set id ======================
    elseif (ischar (prop) && strcmp (prop, 'id'))   
      if (ischar(val))
        s.id = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set description ======================
    elseif (ischar (prop) && strcmp (prop, 'description'))   
      if (ischar (val))
        s.description = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set shocktype_mc ======================
    elseif (ischar (prop) && strcmp (prop, 'shocktype_mc'))   
      if (ischar (val))
        s.shocktype_mc = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set type ======================
    elseif (ischar (prop) && strcmp (prop, 'type'))   
      if (ischar (val))
        s.type = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end   
    % case else
    else
      error ('set: invalid property of curve class: %s \n',prop);
    end
  end
end
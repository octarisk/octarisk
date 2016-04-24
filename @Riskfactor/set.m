% setting Riskfactor MC scenario and stress values
function s = set (obj, varargin)
  s = obj;
  if (length (varargin) < 2 || rem (length (varargin), 2) != 0)
    error ('set: expecting property/value pairs');
  end
  while (length (varargin) > 1)
    prop = varargin{1};
    val = varargin{2};
    varargin(1:2) = [];
    % ====================== set scenario_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    if (ischar (prop) && strcmp (prop, 'scenario_mc'))   
      if (isvector (val) && isreal (val))
        tmp_vector = [s.scenario_mc];
        if ( rows(tmp_vector) > 0 ) % appending vector to existing vector
            if ( rows(tmp_vector) == rows(val) )
                s.scenario_mc = [tmp_vector, val];
            else
                error ('set: expecting equal number of rows')
            end
        else    % setting vector
            s.scenario_mc = val;
        end      
      elseif (ismatrix(val) && isreal(val)) % replacing scenario_mc matrix with new matrix
        s.scenario_mc = val;
      else
        error ('set: expecting the value to be a real vector');
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
    % ====================== set scenario_stress ======================
    elseif (ischar (prop) && strcmp (prop, 'scenario_stress'))   
      
      if (isvector (val) && isreal (val))
        s.scenario_stress = [s.scenario_stress; val];
      else
        if ( isempty(val))
            s.scenario_stress = [];
        else
            error ('set: expecting the value to be a real vector');
        end
      end
    % ====================== set shift_type ======================
    elseif (ischar (prop) && strcmp (prop, 'shift_type'))   
      if (isvector (val) && isreal (val))
        s.shift_type = [s.shift_type; val];
      else
        error ('set: expecting the value to be a real vector');
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
    % ====================== set description  ======================
    elseif (ischar (prop) && strcmp (prop, 'description'))   
      if (ischar (val))
        s.description = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end 
    % ====================== set model  ======================
    elseif (ischar (prop) && strcmp (prop, 'model'))   
      if (ischar (val))
        s.model = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set type  ======================
    elseif (ischar (prop) && strcmp (prop, 'type'))   
      if (ischar (val))
        s.type = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end   
    % ====================== set mean ======================
    elseif (ischar (prop) && strcmp (prop, 'mean'))   
      if (isnumeric (val) && isreal (val))
        s.mean = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set std ======================
    elseif (ischar (prop) && strcmp (prop, 'std'))   
      if (isnumeric (val) && isreal (val))
        s.std = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set skew ======================
    elseif (ischar (prop) && strcmp (prop, 'skew'))   
      if (isnumeric (val) && isreal (val))
        s.skew = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set kurt ======================
    elseif (ischar (prop) && strcmp (prop, 'kurt'))   
      if (isnumeric (val) && isreal (val))
        s.kurt = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set mr_level ======================
    elseif (ischar (prop) && strcmp (prop, 'mr_level'))   
      if (isnumeric (val) && isreal (val))
        s.mr_level = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set mr_rate ======================
    elseif (ischar (prop) && strcmp (prop, 'mr_rate'))   
      if (isnumeric (val) && isreal (val))
        s.mr_rate = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set node ======================
    elseif (ischar (prop) && strcmp (prop, 'node'))   
      if (isnumeric (val) && isreal (val))
        s.node = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set value_base ======================
    elseif (ischar (prop) && strcmp (prop, 'value_base'))   
      if (isnumeric (val) && isreal (val))
        s.value_base = val;
      else
        error ('set: expecting the value to be a real number');
      end    
    else
      error ('set: invalid property of risk factor class');
    end
  endwhile
end   
% setting Riskfactor MC scenario and stress values
function s = set (obj, varargin)
  s = obj;
  if (length (varargin) < 2 || rem (length (varargin), 2) != 0)
    error ("set: expecting property/value pairs");
  endif
  while (length (varargin) > 1)
    prop = varargin{1};
    val = varargin{2};
    varargin(1:2) = [];
    % ====================== set scenario_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    if (ischar (prop) && strcmp (prop, "scenario_mc"))   
      if (isvector (val) && isreal (val))
        tmp_vector = [s.scenario_mc];
        if ( rows(tmp_vector) > 0 ) % appending vector to existing vector
            if ( rows(tmp_vector) == rows(val) )
                s.scenario_mc = [tmp_vector, val];
            else
                error ("set: expecting equal number of rows")
            endif
        else    % setting vector
            s.scenario_mc = val;
        endif      
      elseif (ismatrix(val) && isreal(val)) % replacing scenario_mc matrix with new matrix
        s.scenario_mc = val;
      else
        error ("set: expecting the value to be a real vector");
      endif
    % ====================== set timestep_mc: appending or setting timestep vector ======================
    elseif (ischar (prop) && strcmp (prop, "timestep_mc"))   
      if (iscell(val) && length(val) == 1)
        tmp_cell = s.timestep_mc;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            s.timestep_mc{length(tmp_cell) + 1} = char(val);
        else    % setting vector
            s.timestep_mc = val;
        endif      
      elseif (iscell(val) && length(val) > 1) % replacing timestep_mc cell vector with new vector
        s.timestep_mc = val;
      elseif ( ischar(val) )
        tmp_cell = s.timestep_mc;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            s.timestep_mc{length(tmp_cell) + 1} = char(val);
        else    % setting vector
            s.timestep_mc = cellstr(val);
        endif 
      else
        error ("set: expecting the cell value to be a cell vector");
      endif  
    % ====================== set scenario_stress ======================
    elseif (ischar (prop) && strcmp (prop, "scenario_stress"))   
      
      if (isvector (val) && isreal (val))
        s.scenario_stress = [s.scenario_stress; val];
      else
        if ( isempty(val))
            s.scenario_stress = [];
        else
            error ("set: expecting the value to be a real vector");
        endif
      endif
    % ====================== set shift_type ======================
    elseif (ischar (prop) && strcmp (prop, "shift_type"))   
      if (isvector (val) && isreal (val))
        s.shift_type = [s.shift_type; val];
      else
        error ("set: expecting the value to be a real vector");
      endif   
    else
      error ("set: invalid property of risk factor class");
    endif
  endwhile
endfunction   
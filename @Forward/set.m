function s = set (forward, varargin)
  s = forward;
  if (length (varargin) < 2 || rem (length (varargin), 2) != 0)
    error ("set: expecting property/value pairs");
  endif
  while (length (varargin) > 1)
    prop = varargin{1};
    val = varargin{2};
    varargin(1:2) = [];
    % ====================== set value_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    if (ischar (prop) && strcmp (prop, "value_mc"))   
      if (isvector (val) && isreal (val))
        tmp_vector = [s.value_mc];
        if ( rows(tmp_vector) > 0 ) % appending vector to existing vector
            if ( rows(tmp_vector) == rows(val) )
                s.value_mc = [tmp_vector, val];
            else
                error ("set: expecting equal number of rows")
            endif
        else    % setting vector
            s.value_mc = val;
        endif      
      elseif (ismatrix(val) && isreal(val)) % replacing value_mc matrix with new matrix
        s.value_mc = val;
      else
        if ( isempty(val))
            s.value_mc = [];
        else
            error ("set: expecting the value to be a real vector");
        endif
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
        else   % setting vector
            s.timestep_mc = cellstr(val);
        endif 
      else
        error ("set: expecting the prop value to be a cell or a string");
      endif  
    % ====================== set value_stress ======================
    elseif (ischar (prop) && strcmp (prop, "value_stress"))   
      if (isvector (val) && isreal (val))
        s.value_stress = val;
      else
        if ( isempty(val))
            s.value_stress = [];
        else
            error ("set: expecting the value to be a real vector");
        endif
      endif
    % ====================== set value_spot ======================
    elseif (ischar (prop) && strcmp (prop, "value_base"))   
      if (isvector (val) && isreal (val))
        s.value_base = val;
      else
        error ("set: expecting the value to be a real vector");
      endif 
    % ====================== set underlying price base ======================
    elseif (ischar (prop) && strcmp (prop, "underlying_price_base"))   
      if (isvector (val) && isreal (val))
        s.underlying_price_base = val;
      else
        error ("set: expecting the value to be a real vector");
      endif 
    else
      error ("set: invalid property of forward class");
    endif
  endwhile
endfunction
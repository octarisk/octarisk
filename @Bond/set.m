function s = set (bond, varargin)
  s = bond;
  if (length (varargin) < 2 || rem (length (varargin), 2) != 0)
    error ("set: expecting property/value pairs");
  endif
  while (length (varargin) > 1)
    prop = varargin{1};
    val = varargin{2};
    varargin(1:2) = [];
    if (ischar (prop) && strcmp (prop, "soy"))
      if (isvector (val) && isreal (val))
        s.soy = val;
      else
        error ("set: expecting the value to be a real vector");
      endif
    elseif (ischar (prop) && strcmp (prop, "convexity"))   
      if (isreal (val))
        s.convexity = val;
      else
        error ("set: expecting the value to be a real number");
      endif
    % ====================== set rates_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmp (prop, "cf_values_mc"))   
      if (isreal (val))
        [mc_rows mc_cols mc_stack] = size(s.cf_values_mc);
        if ( mc_cols > 0 || mc_rows > 0) % appending vector to existing vector
            if ( length(val) == length(s.cf_values_mc(:,:,mc_stack)))
                s.cf_values_mc(:,:,mc_stack + 1) = val;
            else
                error("set: expecting length of new input vector to equal length of already existing rate vector");
            endif
        else    % setting vector
            s.cf_values_mc(:,:,1) = val;
        endif  
        
      else
        error ("set: expecting the mc cf values to be real ");
      endif 
    % ====================== set cf_values_stress ======================
    elseif (ischar (prop) && strcmp (prop, "cf_values_stress"))   
      if (isreal (val))
        s.cf_values_stress = val;
      else
        error ("set: expecting the cf stress value to be real ");
      endif
    % ====================== set cf_values ======================
    elseif (ischar (prop) && strcmp (prop, "cf_values"))   
      if (isvector (val) && isreal (val))
        s.cf_values = val;
      else
        error ("set: expecting the base values to be a real vector");
      endif
    % ====================== set cf_dates ======================
    elseif (ischar (prop) && strcmp (prop, "cf_dates"))   
      if (isvector (val) && isreal (val))
        s.cf_dates = val;
      else
        error ("set: expecting the value to be a real vector");
      endif 
    % ====================== set timestep_mc_cf: appending or setting timestep vector ======================
    elseif (ischar (prop) && strcmp (prop, "timestep_mc_cf"))   
      if (iscell(val) && length(val) == 1)
        tmp_cell = s.timestep_mc_cf;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            s.timestep_mc_cf{length(tmp_cell) + 1} = char(val);
        else    % setting vector
            s.timestep_mc_cf = val;
        endif      
      elseif (iscell(val) && length(val) > 1) % replacing timestep_mc_cf cell vector with new vector
        s.timestep_mc_cf = val;
      elseif ( ischar(val) )
        tmp_cell = s.timestep_mc_cf;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            s.timestep_mc_cf{length(tmp_cell) + 1} = char(val);
        else    % setting vector
            s.timestep_mc_cf = cellstr(val);
        endif 
      else
        error ("set: expecting the cell value to be a cell vector");
      endif   
    % ====================== set value_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmp (prop, "value_mc"))   
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
        else    % setting vector
            s.timestep_mc = cellstr(val);
        endif 
      else
        error ("set: expecting the cell value to be a cell vector");
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
    % ====================== set value_base ======================
    elseif (ischar (prop) && strcmp (prop, "value_base"))   
      if (isvector (val) && isreal (val))
        s.value_base = val;
      else
        error ("set: expecting the value to be a real vector");
      endif  
    else
      error ("set: invalid property of bond class");
    endif
  endwhile
endfunction
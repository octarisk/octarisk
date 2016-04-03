% setting Curve base, MC scenario and stress values
function s = set (obj, varargin)
  s = obj;
  if (length (varargin) < 2 || rem (length (varargin), 2) != 0)
    error ("set: expecting property/value pairs");
  endif
  while (length (varargin) > 1)
    prop = varargin{1};
    val = varargin{2};
    varargin(1:2) = [];
    % ====================== set rates_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    if (ischar (prop) && strcmp (prop, "rates_mc"))   
      if (isreal (val))
        [mc_rows mc_cols mc_stack] = size(s.rates_mc);
        if ( mc_cols > 0 || mc_rows > 0) % appending vector to existing vector
            if ( length(val) == length(s.rates_mc(:,:,mc_stack)))
                s.rates_mc(:,:,mc_stack + 1) = val;
            else
                error("set: expecting length of new input vector to equal length of already existing rate vector");
            endif
        else    % setting vector
            s.rates_mc(:,:,1) = val;
        endif  
        
      else
        error ("set: expecting the mc values to be real ");
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
    % ====================== set rates_stress ======================
    elseif (ischar (prop) && strcmp (prop, "rates_stress"))   
      if (isreal (val))
        s.rates_stress = val;
      else
        error ("set: expecting the stress value to be real ");
      endif
    % ====================== set rates_base ======================
    elseif (ischar (prop) && strcmp (prop, "rates_base"))   
      if (isvector (val) && isreal (val))
        s.rates_base = val;
      else
        error ("set: expecting the base values to be a real vector");
      endif
    % ====================== set nodes ======================
    elseif (ischar (prop) && strcmp (prop, "nodes"))   
      if (isvector (val) && isreal (val))
        s.nodes = val;
      else
        error ("set: expecting the value to be a real vector");
      endif
    % ====================== set method_interpolation ======================
    elseif (ischar (prop) && strcmp (prop, "method_interpolation"))   
      if (ischar (val))
        s.method_interpolation = method_interpolation;
      else
        error ("set: expecting the value to be of type character");
      endif 
    % case else
    else
      error ("set: invalid property of curve class");
    endif
  endwhile
endfunction
function s = set (debt, varargin)
  s = debt;
  if (length (varargin) < 2 || rem (length (varargin), 2) != 0)
    error ('set: expecting property/value pairs');
  endif
  while (length (varargin) > 1)
    prop = varargin{1};
    val = varargin{2};
    varargin(1:2) = [];
    if (ischar (prop) && strcmp (prop, 'duration'))
      if (isvector (val) && isreal (val))
        s.duration = val;
      else
        error ('set: expecting the value to be a real vector');
      endif
    elseif (ischar (prop) && strcmp (prop, 'convexity'))   
      if (isreal (val))
        s.convexity = val;
      else
        error ('set: expecting the value to be a real number');
      endif
    % ====================== set value_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'value_mc'))   
      if (isvector (val) && isreal (val))
        tmp_vector = [s.value_mc];
        if ( rows(tmp_vector) > 0 ) % appending vector to existing vector
            if ( rows(tmp_vector) == rows(val) )
                s.value_mc = [tmp_vector, val];
            else
                error ('set: expecting equal number of rows')
            endif
        else    % setting vector
            s.value_mc = val;
        endif      
      elseif (ismatrix(val) && isreal(val)) % replacing value_mc matrix with new matrix
        s.value_mc = val;
      else
        error ('set: expecting the value to be a real vector');
      endif
    % ====================== set timestep_mc: appending or setting timestep vector ======================
    elseif (ischar (prop) && strcmp (prop, 'timestep_mc'))   
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
        if ( isempty(val))
            s.value_mc = [];
        else
            error ('set: expecting the value to be a real vector');
        endif
      endif  
    % ====================== set value_stress ======================
    elseif (ischar (prop) && strcmp (prop, 'value_stress'))   
      if (isvector (val) && isreal (val))
        s.value_stress = val;
      else
        if ( isempty(val))
            s.value_stress = [];
        else
            error ('set: expecting the value to be a real vector');
        endif
      endif
    % ====================== set value_base ======================
    elseif (ischar (prop) && strcmp (prop, 'value_base'))   
      if (isvector (val) && isreal (val))
        s.value_base = val;
      else
        error ('set: expecting the value to be a real vector');
      endif
    % ====================== set name ======================
    elseif (ischar (prop) && strcmp (prop, 'name'))   
      if (ischar (val) )
        s.name = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      endif
    % ====================== set id ======================
    elseif (ischar (prop) && strcmp (prop, 'id'))   
      if (ischar(val))
        s.id = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      endif
    % ====================== set sub_type ======================
    elseif (ischar (prop) && strcmp (prop, 'sub_type'))   
      if (ischar (val))
        s.sub_type = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      endif   
    % ====================== set valuation_date ======================
    elseif (ischar (prop) && strcmp (prop, 'valuation_date'))   
      if (ischar (val))
        s.valuation_date = datestr(strtrim(val),1);
      else
        error ('set: expecting the value to be a char');
      endif 
    % ====================== set asset_class ======================
    elseif (ischar (prop) && strcmp (prop, 'asset_class'))   
      if (ischar (val))
        s.asset_class = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      endif 
    % ====================== set currency ======================
    elseif (ischar (prop) && strcmp (prop, 'currency'))   
      if (ischar (val))
        s.currency = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      endif 
    % ====================== set description ======================
    elseif (ischar (prop) && strcmp (prop, 'description'))   
      if (ischar (val))
        s.description = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      endif 
    % ====================== set discount_curve  ======================
    elseif (ischar (prop) && strcmp (prop, 'discount_curve'))   
      if (ischar (val))
        s.discount_curve = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      endif  
     % ====================== set spread_curve  ======================
    elseif (ischar (prop) && strcmp (prop, 'spread_curve'))   
      if (ischar (val))
        s.spread_curve = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      endif 
    % ====================== set duration ======================
    elseif (ischar (prop) && strcmp (prop, 'duration'))   
      if (isreal (val))
        s.duration = val;
      else
        error ('set: expecting the value to be a real number');
      endif
    % ====================== set convexity ======================
    elseif (ischar (prop) && strcmp (prop, 'convexity'))   
      if (isreal (val))
        s.convexity = val;
      else
        error ('set: expecting the value to be a real number');
      endif    
    else
      error ('set: invalid property of bond class');
    endif
  endwhile
endfunction
function s = set (forward, varargin)
  s = forward;
  if (length (varargin) < 2 || rem (length (varargin), 2) != 0)
    error ('set: expecting property/value pairs');
  endif
  while (length (varargin) > 1)
    prop = varargin{1};
    val = varargin{2};
    varargin(1:2) = [];
    % ====================== set value_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    if (ischar (prop) && strcmp (prop, 'value_mc'))   
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
        if ( isempty(val))
            s.value_mc = [];
        else
            error ('set: expecting the value to be a real vector');
        endif
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
        else   % setting vector
            s.timestep_mc = cellstr(val);
        endif 
      else
        error ('set: expecting the prop value to be a cell or a string');
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
    % ====================== set value_spot ======================
    elseif (ischar (prop) && strcmp (prop, 'value_base'))   
      if (isvector (val) && isreal (val))
        s.value_base = val;
      else
        error ('set: expecting the value to be a real vector');
      endif 
    % ====================== set underlying price base ======================
    elseif (ischar (prop) && strcmp (prop, 'underlying_price_base'))   
      if (isvector (val) && isreal (val))
        s.underlying_price_base = val;
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
     % ====================== set cf_values ======================
    elseif (ischar (prop) && strcmp (prop, 'cf_values'))   
      if (isvector (val) && isreal (val))
        s.cf_values = val;
      else
        error ('set: expecting the base values to be a real vector');
      endif
    % ====================== set cf_dates ======================
    elseif (ischar (prop) && strcmp (prop, 'cf_dates'))   
      if (isvector (val) && isreal (val))
        s.cf_dates = val;
      else
        error ('set: expecting the value to be a real vector');
      endif
    % ====================== set spread ======================
    elseif (ischar (prop) && strcmp (prop, 'spread'))   
      if (isreal (val))
        s.spread = val;
      else
        error ('set: expecting the value to be a real number');
      endif 
    % ====================== set compounding_freq  ======================
    elseif (ischar (prop) && strcmp (prop, 'compounding_freq'))   
      if (isnumeric (val) && isreal(val))
        s.compounding_freq  = val;
      elseif (ischar(val))
        s.compounding_freq  = val;
      else
        error ('set: expecting the value to be a real number or char');
      endif         
    % ====================== set day_count_convention ======================
    elseif (ischar (prop) && strcmp (prop, 'day_count_convention'))   
      if (ischar (val))
        s.day_count_convention = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      endif 
    % ====================== set compounding_type ======================
    elseif (ischar (prop) && strcmp (prop, 'compounding_type'))   
      if (ischar (val))
        s.compounding_type = strtrim(val);
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
    % ====================== set maturity_date ======================
    elseif (ischar (prop) && strcmp (prop, 'maturity_date'))   
      if (ischar (val))
        s.maturity_date = datestr(strtrim(val),1);
      else
        error ('set: expecting the value to be a char');
      endif
    % ====================== set issue_date ======================
    elseif (ischar (prop) && strcmp (prop, 'issue_date'))   
      if (ischar (val))
        s.issue_date = datestr(strtrim(val),1);
      else
        error ('set: expecting the value to be a char');
      endif
    % ====================== set underlying_id   ======================
    elseif (ischar (prop) && strcmp (prop, 'underlying_id'))   
      if (ischar (val))
        s.underlying_id = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      endif 
    % ====================== set strike_price  ======================
    elseif (ischar (prop) && strcmp (prop, 'strike_price'))   
      if (isreal (val))
        s.strike_price = val;
      else
        error ('set: expecting the value to be a real number');
      endif
    % ====================== set underlying_sensitivity  ======================
    elseif (ischar (prop) && strcmp (prop, 'underlying_sensitivity'))   
      if (isreal (val))
        s.underlying_sensitivity = val;
      else
        error ('set: expecting the value to be a real number');
      endif
    % ====================== set multiplier  ======================
    elseif (ischar (prop) && strcmp (prop, 'multiplier'))   
      if (isreal (val))
        s.multiplier = val;
      else
        error ('set: expecting the value to be a real number');
      endif
    % ====================== set dividend_yield  ======================
    elseif (ischar (prop) && strcmp (prop, 'dividend_yield'))   
      if (isreal (val))
        s.dividend_yield = val;
      else
        error ('set: expecting the value to be a real number');
      endif
    % ====================== set convenience_yield  ======================
    elseif (ischar (prop) && strcmp (prop, 'convenience_yield'))   
      if (isreal (val))
        s.convenience_yield = val;
      else
        error ('set: expecting the value to be a real number');
      endif
    % ====================== set storage_cost ======================
    elseif (ischar (prop) && strcmp (prop, 'storage_cost'))   
      if (isreal (val))
        s.storage_cost = val;
      else
        error ('set: expecting the value to be a real number');
      endif  
    else
      error ('set: invalid property of forward class');
    endif
  endwhile
endfunction
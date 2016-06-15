function s = set (option, varargin)
  s = option;
  if (length (varargin) < 2 || rem (length (varargin), 2) ~= 0)
    error ('set: expecting property/value pairs');
  end
  while (length (varargin) > 1)
    prop = varargin{1};
    prop = lower(prop);
    val = varargin{2};
    varargin(1:2) = [];
    if (ischar (prop) && strcmp (prop, 'vola_spread'))
      if (isvector (val) && isreal (val))
        s.vola_spread = val;
      else
        error ('set: expecting the value to be a real vector');
      end
    % ====================== set value_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'value_mc'))   
      if (isvector (val) && isreal (val))
        tmp_vector = [s.value_mc];
        if ( rows(tmp_vector) > 0 ) % appending vector to existing vector
            if ( rows(tmp_vector) == rows(val) )
                s.value_mc = [tmp_vector, val];
            else
                error ('set: expecting equal number of rows')
            end
        else    % setting vector
            s.value_mc = val;
        end      
      elseif (ismatrix(val) && isreal(val)) % replacing value_mc matrix with new matrix
        s.value_mc = val;
      else
        if ( isempty(val))
            s.value_mc = [];
        else
            error ('set: expecting the value to be a real vector');
        end
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
    % ====================== set value_stress ======================
    elseif (ischar (prop) && strcmp (prop, 'value_stress'))   
      if (isvector (val) && isreal (val))
        s.value_stress = val;
      else
        if ( isempty(val))
            s.value_stress = [];
        else
            error ('set: expecting the value to be a real vector');
        end
      end
    % ====================== set value_base ======================
    elseif (ischar (prop) && strcmp (prop, 'value_base'))   
      if (isvector (val) && isreal (val))
        s.value_base = val;
      else
        error ('set: expecting the value to be a real vector');
      end 
    % ====================== set id ======================
    elseif (ischar (prop) && strcmp (prop, 'id'))   
      if (ischar(val))
        s.id = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set name ======================
    elseif (ischar (prop) && strcmp (prop, 'name'))   
      if (ischar(val))
        s.name = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set currency ======================
    elseif (ischar (prop) && strcmp (prop, 'currency'))   
      if (ischar (val))
        s.currency = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end  
    % ====================== set valuation_date ======================
    elseif (ischar (prop) && strcmp (prop, 'valuation_date'))   
      if (ischar (val))
        s.valuation_date = datestr(strtrim(val),1);
      else
        error ('set: expecting the value to be a char');
      end  
    % ====================== set maturity_date ======================
    elseif (ischar (prop) && strcmp (prop, 'maturity_date'))   
      if (ischar (val))
        s.maturity_date = datestr(strtrim(val),1);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set discount_curve  ======================
    elseif (ischar (prop) && strcmp (prop, 'discount_curve'))   
      if (ischar (val))
        s.discount_curve = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end 
    % ====================== set sub_type ======================
    elseif (ischar (prop) && strcmp (prop, 'sub_type'))   
      if (ischar (val))
        s.sub_type = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end 
    % ====================== set underlying ======================
    elseif (ischar (prop) && strcmp (prop, 'underlying'))   
      if (ischar (val))
        s.underlying = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set vola_surface ======================
    elseif (ischar (prop) && strcmp (prop, 'vola_surface'))   
      if (ischar (val))
        s.vola_surface = strtrim(val);
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
    % ====================== set asset_class ======================
    elseif (ischar (prop) && strcmp (prop, 'asset_class'))   
      if (ischar (val))
        s.asset_class = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end   
    % ====================== set multiplier ======================
    elseif (ischar (prop) && strcmp (prop, 'multiplier'))   
      if (isnumeric (val) && isreal (val))
        s.multiplier = val;
      else
        error ('set: expecting the value to be a real number');
      end  
    % ====================== set spread ======================
    elseif (ischar (prop) && strcmp (prop, 'spread'))   
      if (isnumeric (val) && isreal (val))
        s.spread = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set strike ======================
    elseif (ischar (prop) && strcmp (prop, 'strike'))   
      if (isnumeric (val) && isreal (val))
        s.strike = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set spot ======================
    elseif (ischar (prop) && strcmp (prop, 'spot'))   
      if (isnumeric (val) && isreal (val))
        s.spot = val;
      else
        error ('set: expecting the value to be a real number');
      end 
    % ====================== set theo_delta ======================
    elseif (ischar (prop) && strcmp (prop, 'theo_delta'))   
      if (isnumeric (val) && isreal (val))
        s.theo_delta = val;
      else
        error ('set: expecting the value to be a real number');
      end 
    % ====================== set theo_delta ======================
    elseif (ischar (prop) && strcmp (prop, 'theo_delta'))   
      if (isnumeric (val) && isreal (val))
        s.theo_delta = val;
      else
        error ('set: expecting the value to be a real number');
      end  
    % ====================== set theo_gamma ======================
    elseif (ischar (prop) && strcmp (prop, 'theo_gamma'))   
      if (isnumeric (val) && isreal (val))
        s.theo_gamma = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set theo_vega ======================
    elseif (ischar (prop) && strcmp (prop, 'theo_vega'))   
      if (isnumeric (val) && isreal (val))
        s.theo_vega = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set theo_theta ======================
    elseif (ischar (prop) && strcmp (prop, 'theo_theta'))   
      if (isnumeric (val) && isreal (val))
        s.theo_theta = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set theo_rho ======================
    elseif (ischar (prop) && strcmp (prop, 'theo_rho'))   
      if (isnumeric (val) && isreal (val))
        s.theo_rho = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set theo_omega ======================
    elseif (ischar (prop) && strcmp (prop, 'theo_omega'))   
      if (isnumeric (val) && isreal (val))
        s.theo_omega = val;
      else
        error ('set: expecting the value to be a real number');
      end     
    % ====================== set timesteps_size ======================
    elseif (ischar (prop) && strcmp (prop, 'timesteps_size'))   
      if (isnumeric (val) && isreal (val))
        s.timesteps_size = val;
      else
        error ('set: expecting the value to be a real number');
      end
     % ====================== set willowtree_nodes ======================
    elseif (ischar (prop) && strcmp (prop, 'willowtree_nodes'))   
      if (isnumeric (val) && isreal (val))
        s.willowtree_nodes = val;
      else
        error ('set: expecting the value to be a real number');
      end  
    % ====================== set vola_sensi ======================
    elseif (ischar (prop) && strcmp (prop, 'vola_sensi'))   
      if (isnumeric (val) && isreal (val))
        s.vola_sensi = val;
      else
        error ('set: expecting the value to be a real number');
      end  
    else
      error ('set: >>%s<< invalid property of option class',prop);
    end
  end
end
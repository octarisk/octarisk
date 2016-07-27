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
    if (ischar (prop) && strcmpi (prop, 'vola_spread'))
      if (isvector (val) && isreal (val))
        s.vola_spread = val;
      else
        error ('set: expecting the value to be a real vector');
      end
    % ====================== set value_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmpi (prop, 'value_mc'))   
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
    elseif (ischar (prop) && strcmpi (prop, 'timestep_mc'))   
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
    elseif (ischar (prop) && strcmpi (prop, 'value_stress'))   
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
    elseif (ischar (prop) && strcmpi (prop, 'value_base'))   
      if (isvector (val) && isreal (val))
        s.value_base = val;
      else
        error ('set: expecting the value to be a real vector');
      end 
    % ====================== set id ======================
    elseif (ischar (prop) && strcmpi (prop, 'id'))   
      if (ischar(val))
        s.id = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set name ======================
    elseif (ischar (prop) && strcmpi (prop, 'name'))   
      if (ischar(val))
        s.name = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set currency ======================
    elseif (ischar (prop) && strcmpi (prop, 'currency'))   
      if (ischar (val))
        s.currency = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end  
    % ====================== set valuation_date ======================
    elseif (ischar (prop) && strcmpi (prop, 'valuation_date'))   
      if (ischar (val))
        s.valuation_date = datestr(strtrim(val),1);
      else
        error ('set: expecting the value to be a char');
      end  
    % ====================== set maturity_date ======================
    elseif (ischar (prop) && strcmpi (prop, 'maturity_date'))   
      if (ischar (val))
        s.maturity_date = datestr(strtrim(val),1);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set discount_curve  ======================
    elseif (ischar (prop) && strcmpi (prop, 'discount_curve'))   
      if (ischar (val))
        s.discount_curve = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end 
    % ====================== set sub_type ======================
    elseif (ischar (prop) && strcmpi (prop, 'sub_type'))   
      if (ischar (val))
        s.sub_type = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end 
    % ====================== set underlying ======================
    elseif (ischar (prop) && strcmpi (prop, 'underlying'))   
      if (ischar (val))
        s.underlying = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set vola_surface ======================
    elseif (ischar (prop) && strcmpi (prop, 'vola_surface'))   
      if (ischar (val))
        s.vola_surface = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set description ======================
    elseif (ischar (prop) && strcmpi (prop, 'description'))   
      if (ischar (val))
        s.description = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end   
    % ====================== set asset_class ======================
    elseif (ischar (prop) && strcmpi (prop, 'asset_class'))   
      if (ischar (val))
        s.asset_class = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end 
    % ====================== set pricing_function_american =========
    elseif (ischar (prop) && strcmpi (prop, 'pricing_function_american'))   
      if (ischar (val))
        s.pricing_function_american = strtrim(val);
      else
        error ('set: expecting the value to be a char');
      end 
    % ====================== set UporDown =========
    elseif (ischar (prop) && strcmpi (prop, 'upordown'))   
      if (ischar (val))
        s.upordown = strtrim(val);
      else
        error ('set: expecting upordown to be a char');
      end  
    % ====================== set OutorIn =========
    elseif (ischar (prop) && strcmpi (prop, 'outorin'))   
      if (ischar (val))
        s.outorin = strtrim(val);
      else
        error ('set: expecting outorin to be a char');
      end        
    % ====================== set multiplier ======================
    elseif (ischar (prop) && strcmpi (prop, 'multiplier'))   
      if (isnumeric (val) && isreal (val))
        s.multiplier = val;
      else
        error ('set: expecting the value to be a real number');
      end  
    % ====================== set spread ======================
    elseif (ischar (prop) && strcmpi (prop, 'spread'))   
      if (isnumeric (val) && isreal (val))
        s.spread = val;
      else
        error ('set: expecting the value to be a real number');
      end
     % ====================== set div_yield ======================
    elseif (ischar (prop) && strcmpi (prop, 'div_yield'))   
      if (isnumeric (val) && isreal (val))
        s.div_yield = val;
      else
        error ('set: expecting div_yield to be a real number');
      end
    % ====================== set strike ======================
    elseif (ischar (prop) && strcmpi (prop, 'strike'))   
      if (isnumeric (val) && isreal (val))
        s.strike = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set spot ======================
    elseif (ischar (prop) && strcmpi (prop, 'spot'))   
      if (isnumeric (val) && isreal (val))
        s.spot = val;
      else
        error ('set: expecting the value to be a real number');
      end 
    % ====================== set theo_delta ======================
    elseif (ischar (prop) && strcmpi (prop, 'theo_delta'))   
      if (isnumeric (val) && isreal (val))
        s.theo_delta = val;
      else
        error ('set: expecting the value to be a real number');
      end 
    % ====================== set theo_delta ======================
    elseif (ischar (prop) && strcmpi (prop, 'theo_delta'))   
      if (isnumeric (val) && isreal (val))
        s.theo_delta = val;
      else
        error ('set: expecting the value to be a real number');
      end  
    % ====================== set theo_gamma ======================
    elseif (ischar (prop) && strcmpi (prop, 'theo_gamma'))   
      if (isnumeric (val) && isreal (val))
        s.theo_gamma = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set theo_vega ======================
    elseif (ischar (prop) && strcmpi (prop, 'theo_vega'))   
      if (isnumeric (val) && isreal (val))
        s.theo_vega = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set theo_theta ======================
    elseif (ischar (prop) && strcmpi (prop, 'theo_theta'))   
      if (isnumeric (val) && isreal (val))
        s.theo_theta = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set theo_rho ======================
    elseif (ischar (prop) && strcmpi (prop, 'theo_rho'))   
      if (isnumeric (val) && isreal (val))
        s.theo_rho = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set theo_omega ======================
    elseif (ischar (prop) && strcmpi (prop, 'theo_omega'))   
      if (isnumeric (val) && isreal (val))
        s.theo_omega = val;
      else
        error ('set: expecting the value to be a real number');
      end     
    % ====================== set timesteps_size ======================
    elseif (ischar (prop) && strcmpi (prop, 'timesteps_size'))   
      if (isnumeric (val) && isreal (val))
        s.timesteps_size = val;
      else
        error ('set: expecting the value to be a real number');
      end
     % ====================== set willowtree_nodes ======================
    elseif (ischar (prop) && strcmpi (prop, 'willowtree_nodes'))   
      if (isnumeric (val) && isreal (val))
        s.willowtree_nodes = val;
      else
        error ('set: expecting the value to be a real number');
      end
    % ====================== set Rebate ======================
    elseif (ischar (prop) && strcmpi (prop, 'rebate'))   
      if (isnumeric (val) && isreal (val))
        s.rebate = val;
      else
        error ('set: expecting rebate to be a real number');
      end
    % ====================== set BarrierLevel ======================
    elseif (ischar (prop) && strcmpi (prop, 'barrierlevel'))   
      if (isnumeric (val) && isreal (val))
        s.barrierlevel = val;
      else
        error ('set: expecting barrierlevel to be a real number');
      end     
    % ====================== set vola_sensi ======================
    elseif (ischar (prop) && strcmpi (prop, 'vola_sensi'))   
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
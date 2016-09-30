% setting Surface base: special treatment for Surface class (no consolidation 
% with return_checked_input function
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
    % ====================== set values_base: if issurface -> append to existing surface, if iscube -> replace existing value
    if (ischar (prop) && strcmp (prop, 'values_base'))   
      if (isreal (val))
        [aa bb cc] = size(val);
        if (cc > 1 )        % is cube
            s.values_base = val;
        else                % is surface
        % TODO: Rework. values_base are subsequently added to existing values -> 
        %       no information about about x and y positions -> as workaround
        %       use vola cubes, which overwrite existing values
            %if ( strcmpi(s.type,'INDEX'))   % INDEX type -> term/moneyness/value cube
            %    [mc_rows mc_cols mc_stack] = size(s.values_base);
            %    s.values_base = horzcat(s.values_base,val);  
            %else
                [mc_rows mc_cols mc_stack] = size(s.values_base);
                if ( mc_cols > 0 || mc_rows > 0) % appending vector to existing vector
                    if ( columns(val) == columns(s.values_base(:,:,mc_stack)))
                        s.values_base(:,:,mc_stack + 1) = val;
                    else
                        error('set: expecting length of new input vector to equal length of already existing matrix');
                    end
                else    % setting vector
                    s.values_base(:,:,1) = val;
                end 
            %end
        end
      else
        error ('set: expecting the values to be real ');
      end
    % ====================== set axis_x: if isscalar -> append to existing vector , if isvector -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'axis_x'))   
      if (isvector (val) && isreal (val))
        len = length(val);
        if (len > 1 )        % is vector
            s.axis_x = val;
        else                 % is scalar
            s.axis_x = [s.axis_x, val];
        end 
      else
        error ('set: expecting the value to be a real vector');
      end
    % ====================== set axis_y: if isscalar -> append to existing vector , if isvector -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'axis_y'))   
      if (isvector (val) && isreal (val))
        len = length(val);
        if (len > 1 )        % is vector
            s.axis_y = val;
        else                 % is scalar
            s.axis_y = [s.axis_y, val];
        end 
      else
        error ('set: expecting the value to be a real vector');
      end
    % ====================== set axis_z: if isscalar -> append to existing vector , if isvector -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'axis_z'))   
      if (isreal (val))
        len = length(val);
        if (len > 1 )        % is vector
            s.axis_z = val;
        else                 % is scalar
            s.axis_z = [s.axis_z, val];
        end          
      else
        error ('set: expecting the axis z values to be real ');
      end  
    % ====================== set axis x name ======================
    elseif (ischar (prop) && strcmp (prop, 'axis_x_name'))   
      if (ischar (val) )
        s.axis_x_name = val;
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set axis y name ======================
    elseif (ischar (prop) && strcmp (prop, 'axis_y_name'))   
      if (ischar (val) )
        s.axis_y_name = val;
      else
        error ('set: expecting the value to be a char');
      end
    % ====================== set axis z name ======================
    elseif (ischar (prop) && strcmp (prop, 'axis_z_name'))   
      if (ischar (val) )
        s.axis_z_name = val;
      else
        error ('set: expecting the value to be a char');
      end  
    % ====================== set moneyness_type ======================
    elseif (ischar (prop) && strcmp (prop, 'moneyness_type'))   
      if (ischar (val))
        s.moneyness_type = val;
      else
        error ('set: expecting the value to be of type character');
      end   
    % ====================== set method_interpolation ======================
    elseif (ischar (prop) && strcmp (prop, 'method_interpolation'))   
      if (ischar (val))
        s.method_interpolation = val;
      else
        error ('set: expecting the value to be of type character');
      end 
    % ====================== set type ======================
    elseif (ischar (prop) && strcmp (prop, 'type'))   
      if (ischar (val))
        s.type = val;
      else
        error ('set: expecting the value to be of type character');
      end 
    % ====================== set description ======================
    elseif (ischar (prop) && strcmp (prop, 'description'))   
      if (ischar (val))
        s.description = val;
      else
        error ('set: expecting the value to be of type character');
      end
    % case else
    else
      error ('set: invalid property of surface class: >>%s<<',prop);
    end
  end
end
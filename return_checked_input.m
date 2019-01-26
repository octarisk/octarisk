%# Copyright (C) 2016 Schinzilord <schinzilord@octarisk.com>
%#
%# This program is free software; you can redistribute it and/or modify it under
%# the terms of the GNU General Public License as published by the Free Software
%# Foundation; either version 3 of the License, or (at your option) any later
%# version.
%#
%# This program is distributed in the hope that it will be useful, but WITHOUT
%# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
%# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
%# details.

%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{retval}] =} return_checked_input (@var{obj}, @var{val}, @var{prop}, @var{type})
%#
%# Return value with validated input values according to value type date, char, 
%# numeric, and boolean or special treatment for scenario values. 
%# Used for storing correct field values for classes or structs.
%# The function itself is divided into two parts: special attributes with
%# taylor made validation checks are used for type 'special', while a 
%# generic approach according to different types are performed in the second
%# part.
%# @end deftypefn

function retval = return_checked_input(obj,val,prop,type)

if ( nargin ~= 4)
    print_usage;
end
% ######################     Special Attributes     ############################
if ( strcmpi(type,'special'))
% Special treatment for scenario_mc, timestep_mc and scenario_stress required
    % ====================== set scenario_mc: if isvector -> append to 
    %           existing vector / matrix, if ismatrix -> replace existing value
    if (ischar (prop) && strcmp (prop, 'scenario_mc'))   
      if (isvector (val) && isreal (val))
        tmp_vector = [obj.scenario_mc];
        if ( rows(tmp_vector) > 0 ) % appending vector to existing vector
            if ( rows(tmp_vector) == rows(val) )
                retval = [tmp_vector, val];
            else
                error ('set: expecting equal number of rows')
            end
        else    % setting vector
            retval = val;
        end      
      % replacing scenario_mc matrix with new matrix
      elseif (ismatrix(val) && isreal(val)) 
        retval = val;
      else
        error ('set: expecting scenario_mc to be a real vector');
      end
     % ====================== set rates_mc: if isvector -> append to existing 
     %              vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'rates_mc'))   
      if (isreal (val))
        % applying cap and floor rates before setting values
        if ( isnumeric(obj.floor) )
            val = max(val,obj.floor);
        end
        if ( isnumeric(obj.cap) )
            val = min(val,obj.cap);
        end
        [mc_rows mc_cols mc_stack] = size(obj.rates_mc);
        tmp_cell = obj.rates_mc;
        if ( mc_cols > 0 || mc_rows > 0) % appending vector to existing vector
            if ( length(val) == length(obj.rates_mc(:,:,mc_stack)))
                tmp_cell(:,:,mc_stack + 1) = val;
                retval = tmp_cell;
            else
                error('set: expecting length of new input vector to equal length of already existing rate vector');
            end
        else    % setting vector
            [val_rows val_cols val_stack] = size(val);
            if val_stack == 1   % is matrix
                tmp_cell(:,:,1) = val;
                retval = tmp_cell;
            else
                retval = val;
            end
        end      
      else
        error ('set: expecting the mc values to be real ');
      end
     % ====================== set rates_stress ======================
    elseif (ischar (prop) && strcmp (prop, 'rates_stress'))   
      if (isreal (val))
        % applying cap and floor rates before setting values
        if ( isnumeric(obj.floor) )
            val = max(val,obj.floor);
        end
        if ( isnumeric(obj.cap) )
            val = min(val,obj.cap);
        end
        retval = val;
      else
        error ('set: expecting the stress value to be real ');
      end
    % ====================== set rates_base ======================
    elseif (ischar (prop) && strcmp (prop, 'rates_base'))   
      if (ismatrix (val) && isreal (val))
        % applying cap and floor rates before setting values
        if ( isnumeric(obj.floor) )
            val = max(val,obj.floor);
        end
        if ( isnumeric(obj.cap) )
            val = min(val,obj.cap);
        end
        retval = val;
      else
        error ('set: expecting the base values to be a real vector');
      end
    % =========== set timestep_mc: appending or setting timestep vector ========
    elseif (ischar (prop) && strcmp (prop, 'timestep_mc'))   
      if (iscell(val) && length(val) == 1)
        tmp_cell = obj.timestep_mc;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            tmp_cell{length(tmp_cell) + 1} = char(val);
            retval = tmp_cell;
        else    % setting vector
            retval = val;
        end      
      % replacing timestep_mc cell vector with new vector
      elseif (iscell(val) && length(val) > 1) 
        retval = val;
      elseif ( ischar(val) )
        tmp_cell = obj.timestep_mc;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            tmp_cell{length(tmp_cell) + 1} = char(val);
            retval = tmp_cell;
        else    % setting vector
            retval = cellstr(val);
        end 
      else
        if (iscell(val) && length(val) == 0)
            retval = {};
        else
            error ('set: expecting timestep_mc to be a cell vector');
        end
      end
    % =========== set timestep_mc_cf: appending or setting timestep vector =====
    elseif (ischar (prop) && strcmp (prop, 'timestep_mc_cf'))   
      if (iscell(val) && length(val) == 1)
        tmp_cell = obj.timestep_mc_cf;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            tmp_cell{length(tmp_cell) + 1} = char(val);
            retval = tmp_cell;
        else    % setting vector
            retval = val;
        end    
      % replacing timestep_mc_cf cell vector with new vector
      elseif (iscell(val) && length(val) > 1) 
        retval = val;
      elseif ( ischar(val) )
        tmp_cell = obj.timestep_mc_cf;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            tmp_cell{length(tmp_cell) + 1} = char(val);
            retval = tmp_cell;
        else    % setting vector
            retval = cellstr(val);
        end 
      else
        if (iscell(val) && length(val) == 0)
            retval = {};
        else
            error ('set: expecting the cell value to be a cell vector');
        end
     end
    % ====================== set scenario_stress ======================
    elseif (ischar (prop) && strcmp (prop, 'scenario_stress'))   
      
      if (isvector (val) && isreal (val))   % append to existing stress vector
        retval = [obj.scenario_stress; val];
      else
        if ( isempty(val))
            retval = [];
        else
            error ('set: expecting scenario_stress to be a real vector');
        end
      end 
    % ====================== set cf_values_mc: if isvector -> append 
    % to existing vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'cf_values_mc'))   
      if (isreal (val))
        [mc_rows mc_cols mc_stack] = size(obj.cf_values_mc);
        tmp_cell = obj.cf_values_mc;
        if ( mc_cols > 0 || mc_rows > 0) % appending vector to existing vector
            if ( length(val) == length(obj.cf_values_mc(:,:,mc_stack)))
                tmp_cell(:,:,mc_stack + 1) = val;
                retval = tmp_cell;
            else
                if isempty(val)
                    retval = [];
                else
                    error('set: expecting length of new input vector for cf_values_mc to equal length of already existing rate vector');
                end
            end
        else    % setting vector
            tmp_cell(:,:,1) = val;
            retval = tmp_cell;
        end  
      else
        error ('set: expecting cf_values_mc to be real ');
      end
    % ====================== set value_mc: if isvector -> append to 
    %       existing vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'value_mc'))   
      if (isvector (val) && isreal (val))
        tmp_vector = [obj.value_mc];
        if ( rows(tmp_vector) > 0 ) % appending vector to existing vector
            if ( rows(tmp_vector) == rows(val) )
                retval = [tmp_vector, val];
            else
                error ('set: expecting equal number of rows of value_mc')
            end
        else    % setting vector
            retval = val;
        end    
      % replacing value_mc matrix with new matrix
      elseif (ismatrix(val) && isreal(val)) 
        retval = val;
      else
        if ( isempty(val))
            retval = [];
        else
            error ('set: expecting value_mc to be a real vector');
        end
      end
    % ====================== set value_stress ======================
    elseif (ischar (prop) && strcmp (prop, 'value_stress'))   
      if (isvector (val) && isreal (val))
        retval = val;
      else
        if ( isempty(val))
            retval = [];
        else
            error ('set: expecting value_stress to be a real vector');
        end
      end
    % ====================== set exposure_mc: if isvector -> append to 
    %       existing vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'exposure_mc'))   
      if (isvector (val) && isreal (val))
        tmp_vector = [obj.exposure_mc];
        if ( rows(tmp_vector) > 0 ) % appending vector to existing vector
            if ( rows(tmp_vector) == rows(val) )
                retval = [tmp_vector, val];
            else
                error ('set: expecting equal number of rows of exposure_mc')
            end
        else    % setting vector
            retval = val;
        end    
      % replacing exposure_mc matrix with new matrix
      elseif (ismatrix(val) && isreal(val)) 
        retval = val;
      else
        if ( isempty(val))
            retval = [];
        else
            error ('set: expecting exposure_mc to be a real vector');
        end
      end
    % ====================== set exposure_stress ======================
    elseif (ischar (prop) && strcmp (prop, 'exposure_stress'))   
      if (isvector (val) && isreal (val))
        retval = val;
      else
        if ( isempty(val))
            retval = [];
        else
            error ('set: expecting exposure_stress to be a real vector');
        end
      end
    % ====================== set floor ======================
    elseif (ischar (prop) && strcmp (prop, 'floor'))  
      % set floor rate only if it is numeric and a scalar
      if (isnumeric (val) && isscalar(val))
        retval = val;
      else
        retval = '';
      end
    % ====================== set cap ======================
    elseif (ischar (prop) && strcmp (prop, 'cap')) 
      % set cap rate only if it is numeric and a scalar  
      if (isnumeric (val) && isscalar(val))
        retval = val;
      else
        retval = '';
      end
    else
        error ('return_checked_input: unknown input type >>%s<< and prop >>%s<< not a special input.',type,prop);
    end 
% ############    Standard types [char,date,numeric,boolean]    ################
else
    % check input value according to provided type:
    % ============================     Case 1: char    =========================
    if ( strcmpi(type,'char'))
        if (ischar (val))
            retval = strtrim(val);
        else
            error ('set: expecting %s input value >>%s<< to be a char',prop,any2str(val));
        end 
    % ============================     Case 2: numeric    ======================    
    elseif ( strcmpi(type,'numeric')) 
        if (isnumeric (val) && isreal (val))
            retval = val;
        else
            error ('set: expecting %s input value >>%s<< to be a real number',prop,any2str(val));
        end
    % ============================     Case 3: charvnumber ======================  
    elseif ( strcmpi(type,'charvnumber'))  
      if (isnumeric (val) && isreal(val))
        retval  = val;
      elseif (ischar(val))
        retval  = val;
      else
        error ('set: expecting %s input value >>%s<< to be a number or char',prop,any2str(val));
      end
    % ============================     Case 4: boolean    ======================      
    elseif ( strcmpi(type,'boolean'))    
        if (isnumeric (val) && isreal (val))
            retval = logical(val);
        elseif ( ischar(val))
          if ( strcmp('false',lower(val)))
                retval = logical(0);
          elseif ( strcmp('true',lower(val)))
                retval = logical(1);
          else
                printf('WARNING: Unknown value: >>%s<< for property %s. Setting value to false.',val,prop);
                retval = logical(0);
          end
        elseif ( islogical(val))
            retval = val;    
        else
            error ('set: expecting %s input value >>%s<< to be a real number or logical',prop,any2str(val));
        end  
    % ============================     Case 5: date    ========================= 
    elseif ( strcmpi(type,'date'))
        if (ischar (val))
            retval = datestr(strtrim(val),1);
        elseif ( isnumeric(val))
            retval = datestr(val);
        elseif ( isvector(val) && length(val) == 6 )
            retval = datestr(val);
        else
            error ('set: expecting %s input value >>%s<< to be a char or integer',any2str(val));
        end 
    % ============================     Case 6: cell    ========================= 
    elseif ( strcmpi(type,'cell')) 
      if (iscell(val) )
        retval = strtrim(val);
      else
        error ('set: expecting %s input value >>%s<< to be a cell',any2str(val));
      end
    % ============================     Case 7: numericscalar    ========================= 
    elseif ( strcmpi(type,'numericscalar')) 
      if (isnumeric (val) && isscalar(val))
        retval = val;
      else
        error ('set: expecting %s input value >>%s<< to be a numericscalar',any2str(val));
      end
    else
        error ('return_checked_input: unknown input type >>%s<< not in [char,numeric,boolean,date,cell,charvnumber,numericscalar]',type);
    end
end

end
%!test
%! obj = struct();
%! obj.scenario_stress = [];
%! obj.scenario_mc = [1;2;3;4];
%! obj.timestep_mc = {'10d'};
%! obj.cf_values_mc(:,:,1) = [1;2;3;4];
%! retval = return_checked_input(obj,'aaa ','name','char');
%! assert(retval,'aaa')
%! retval = return_checked_input(obj,234324.2135,'value','numeric');
%! assert(retval,234324.2135)
%! retval = return_checked_input(obj,1,'value','numeric');
%! assert(retval,1)
%! retval = return_checked_input(obj,1.11E-32,'value','numeric');
%! assert(retval,1.11E-32)
% error(return_checked_input(obj,2+3i,'value','numeric'))
% error(return_checked_input(obj,234324.234234,'name','char'))
% error(return_checked_input(obj,'aaa','value','numeric'))
%! retval = return_checked_input(obj,736603,'maturity_date','date');
%! assert(retval,'30-Sep-2016')
%! retval = return_checked_input(obj,[2016,9,30,0,0,0],'maturity_date','date');
%! assert(retval,'30-Sep-2016');
%! retval = return_checked_input(obj,'30-Sep-2016','maturity_date','date');
%! assert(retval,'30-Sep-2016')
%! retval = return_checked_input(obj,[1;2;3;4],'scenario_mc','special');
%! assert(retval,[1,1;2,2;3,3;4,4])
%! retval = return_checked_input(obj,[5;6;7;8],'cf_values_mc','special');
%! assert(retval(:,:,1),[1;2;3;4])
%! assert(retval(:,:,2),[5;6;7;8])
%! retval = return_checked_input(obj,[12;23;145;15],'scenario_stress','special');
%! assert(retval,[12;23;145;15])
%! retval = return_checked_input(obj,'250d','timestep_mc','special');
%! assert(retval,{'10d','250d'})
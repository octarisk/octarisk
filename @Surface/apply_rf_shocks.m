% method of class @Surface
function [surface] = apply_rf_shocks (surface, riskfactor_struct)
    % store risk factor shock values for all underlying risk factors given in
    % riskfactor_struct
    if (nargin < 2)
        error('Surface.apply_rf_shocks: no risk factor struct given.');
    end
  
% check for empty risk factor definition
if (length(surface.riskfactors) == 0)
    break
elseif (length(surface.riskfactors) == 1)
    if (isempty(surface.riskfactors{1}))
        break
    end
end
% what is done here:
% - get all underlying risk factors
% - get all shock values of each risk factor (for stress and MC scenarios)
% - combine these shocks and store them in separate stress and MC sub-structs
% - combine both sub-structs into one shock_struct
% - store these structs in the surface attribute "shock_struct" and return object

% get risk factors of surface
    tmp_riskfactors = surface.riskfactors;
    shock_struct = surface.shock_struct;
    tmp_coordinates = [];
    tmp_shock_values = [];
    tmp_model = '';
    tmp_shift_type = [];
    tmp_timestep_mc = {};
% update stress values
    for ii = 1:1:length(tmp_riskfactors)
        tmp_rf = tmp_riskfactors{ii};
        [tmp_rf_obj  object_ret_code] = get_sub_object(riskfactor_struct,tmp_rf);
        if ( object_ret_code == 0 )
            error('Surface.apply_rf_shocks: risk factor >>%s<< not found for surface >>%s<<',tmp_rf,surface.id);  
        end
        % loop through all value types and set struct
        % loop through stress values
        % append coordinates of risk factor
        tmp_xyz = [tmp_rf_obj.node;tmp_rf_obj.node2;tmp_rf_obj.node3];
        tmp_coordinates = cat(2,tmp_coordinates,tmp_xyz);
        tmp_shock = tmp_rf_obj.getValue('stress');  
		if ( columns(tmp_shock) > rows(tmp_shock) )
			fprintf('Surface.apply_rf_shocks: Shock needs to be column vector. Transposing shock vector.\n');
			tmp_shock = tmp_shock';	% shock needs to be column vector
		end
        % check models are equal for all risk factors
        if ( ii > 1)
            if ~( strcmpi(tmp_model, tmp_rf_obj.model))
                error('Surface.apply_rf_shocks: Model >>%s<< of risk factor >>%s<< not equal to already stored model >>%s<< for surface >>%s<<',tmp_rf_obj.model,tmp_rf,tmp_model,surface.id);  
            end
        else
            tmp_model = tmp_rf_obj.model; 
        end
        % append shock values
        tmp_shock_values = cat(2,tmp_shock_values,tmp_shock); 
        tmp_shift_type = tmp_rf_obj.shift_type;
       % store MC timesteps for later use
        tmp_timestep_mc = tmp_rf_obj.get('timestep_mc');
    end
    if (length(tmp_riskfactors)>0)
         % generate temporary struct with stress values
        tmp_s               = struct();
        tmp_s.model         = tmp_model;
        tmp_s.coordinates   = tmp_coordinates;
        tmp_s.values        = tmp_shock_values;
        tmp_s.shift_type    = tmp_shift_type;
        % store stress struct
        shock_struct = setfield(shock_struct,'stress',tmp_s);
    end
        
% loop through all MC timesteps (with inner loop via all Riskfactors)
    for kk = 1 : 1 : length(tmp_timestep_mc)
        tmp_shock_values = [];
        tmp_value_type = tmp_timestep_mc{kk};
        for ii = 1:1:length(tmp_riskfactors)
            tmp_rf = tmp_riskfactors{ii};
            [tmp_rf_obj  object_ret_code] = get_sub_object(riskfactor_struct,tmp_rf);
            if ( object_ret_code == 0 )
                error('Surface.apply_rf_shocks: risk factor >>%s<< not found for surface >>%s<<',tmp_rf,tmp_id);  
            end
            % loop through all value types and set struct
            tmp_shock = tmp_rf_obj.getValue(tmp_value_type);
            % append shock values
            tmp_shock_values = cat(2,tmp_shock_values,tmp_shock); 
        end 
         % generate temporary struct
        tmp_s               = struct();
        tmp_s.model         = tmp_model;
        tmp_s.coordinates   = tmp_coordinates;
        tmp_s.values        = tmp_shock_values;
        % store stress struct
        shock_struct = setfield(shock_struct,tmp_value_type,tmp_s);
    end
    % store final struct and return object
    surface.shock_struct = shock_struct;
end

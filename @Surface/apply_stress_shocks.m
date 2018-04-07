% method of class @Surface
function [surface] = apply_stress_shocks (surface, stress_struct)
    % store risk factor shock values for all underlying risk factors given in
    % riskfactor_struct
    if (nargin < 2)
        error('Surface.apply_rf_shocks: no risk factor struct given.');
    end
  
% what is done here:
% - loop through all provided stress scenarios and get stress shocks / values
% - combine these shocks and store them in stress sub-structs 
% - store these struct in the surface attribute "shock_struct" and return object

surface_stress_struct = struct();

% iterate via all stress definitions
for ii = 1:1:length(stress_struct)
    % get struct with all market object shocks
    subst = stress_struct(ii).objects;
    % get appropriate market object
    [mktstruct retcode] = get_sub_struct(subst,surface.id);
    if ( retcode == 1)  % market data is contained in stress
        type        = mktstruct.type;
        shock_type  = mktstruct.shock_type;
        shock_value = mktstruct.shock_value;

        % get base rates and nodes of curve
        surface_stress_struct(ii).id   = stress_struct(ii).id;
        surface_stress_struct(ii).axis_x = surface.axis_x;
        surface_stress_struct(ii).axis_y = surface.axis_y;
        if ( strcmpi(surface.type,'IRVol'))
            surface_stress_struct(ii).axis_z = surface.axis_z;
        end
        values_base = surface.values_base;
    
        if (strcmpi(shock_type,'relative'))
            values_stress  = values_base .* shock_value;
        elseif (strcmpi(shock_type,'absolute'))
            values_stress  = values_base + shock_value;
        elseif (strcmpi(shock_type,'value'))
            values_stress  = values_base;
            % overwrite base scenario axis values with stress axis values
            surface_stress_struct(ii).axis_x = mktstruct.axis_x
            surface_stress_struct(ii).axis_y = mktstruct.axis_y;
            if ( strcmpi(surface.type,'IRVol')) 
                surface_stress_struct(ii).axis_z = mktstruct.axis_z;
            end
        else
            error('return_stress_shocks: unknown stress shock type: >>%s<<\n',any2str(shock_type));
        end
        % set stress scenario cube values
        surface_stress_struct(ii).cube = values_stress;
    else
        % apply base value
        surface_stress_struct(ii).cube = surface.values_base;
        surface_stress_struct(ii).id   = stress_struct(ii).id;
        surface_stress_struct(ii).axis_x = surface.axis_x;
        surface_stress_struct(ii).axis_y = surface.axis_y;
        if ( strcmpi(surface.type,'IRVol')) 
            surface_stress_struct(ii).axis_z = surface.axis_z;
        end
    end
end


shock_struct = setfield(surface.shock_struct,'stress',surface_stress_struct);

% store final struct and return object
surface.shock_struct = shock_struct;

end

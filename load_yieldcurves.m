%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{rf_ir_cur_cell} @var{curve_struct}] =} 
%# load_volacubes(@var{curve_struct}, @var{riskfactor_struct}, 
%# @var{mc_timesteps}, @var{path_output}, @var{saving})
%# Generate curve objects from risk factor objects. Store all curves in provided 
%# struct and return the final struct and a cell containing all interest rate 
%# risk factor currency / ratings.
%# @end deftypefn

function [rf_ir_cur_cell curve_struct curve_failed_cell] = load_yieldcurves( ...
                curve_struct,riskfactor_struct,mc_timesteps,path_output,saving)

curve_failed_cell = {};
% 1) Processing Yield Curve: Getting Cell with IDs of IR nodes

% load dynamically cellarray with all RF curves (IR and SPREAD) as defined in 
% riskfactor_struct:
rf_ir_cur_cell = {};
number_riskfactors = 0;
for ii = 1 : 1 : length(riskfactor_struct)
    tmp_rf_struct_obj = riskfactor_struct( ii ).object;
    tmp_rf_id = tmp_rf_struct_obj.id;
    tmp_rf_type = tmp_rf_struct_obj.type;
    if ( strcmp(tmp_rf_type,'RF_IR') || strcmp(tmp_rf_type,'RF_SPREAD') )  
        number_riskfactors = number_riskfactors + 1;
        tmp_rf_parts = strsplit(tmp_rf_id, '_');
        tmp_rf_curve = 'RF';
        % concatenate the whole string except the last '_xY'
        for jj = 2 : 1 : length(tmp_rf_parts) -1    
            tmp_rf_curve = strcat(tmp_rf_curve,'_',tmp_rf_parts{jj});
        end
        rf_ir_cur_cell = cat(2,rf_ir_cur_cell,tmp_rf_curve);
    end
    rf_ir_cur_cell = unique(rf_ir_cur_cell);
end

% 2) generate RF_IR and RF_SPREAD objects from all nodes defined 
%     in riskfactor_struct
% Loop via all entries in currency cell
for ii = 1 : 1 : length(rf_ir_cur_cell)
    tmp_curve_id         = rf_ir_cur_cell{ii};
    try
        if ( regexp(tmp_curve_id,'IR'))
            tmp_curve_type = 'Discount Curve';
        elseif ( regexp(tmp_curve_id,'SPREAD'))
            tmp_curve_type = 'Spread Curve';
        else
            tmp_curve_type = 'Dummy Curve';
        end
        curve_struct( ii ).name     = tmp_curve_id;
        curve_struct( ii ).id       = tmp_curve_id;
        curve_object = Curve(tmp_curve_id,tmp_curve_id,tmp_curve_type,'');

        % loop via all base and stress scenarios:
        tmp_nodes = [];
        tmp_rates_original = [];
        tmp_rates_stress = [];
        for jj = 1 : 1 : length( riskfactor_struct )
            tmp_rf_struct_obj = riskfactor_struct( jj ).object;
            tmp_rf_id = tmp_rf_struct_obj.id;
            if ( regexp(tmp_rf_id,tmp_curve_id) == 1 ) 
                tmp_node            = tmp_rf_struct_obj.get('node');
                tmp_nodes 		    = cat(2,tmp_nodes,tmp_node); 
                tmp_delta_stress    = tmp_rf_struct_obj.getValue('stress') ;
                % distinguish between absolute shocks (in bp) and relative shocks
                tmp_shift_type      = tmp_rf_struct_obj.get('shift_type');  
                %tmp_shift_type_inv  = 1 - tmp_shift_type;
                % set rate original according to shifttype: 
                %             0 absolute shift, 1 relative shift 
                tmp_rate_original   = tmp_shift_type;   
                tmp_rates_original  = cat(2,tmp_rates_original,tmp_rate_original);
                tmp_rates_stress 	= cat(2,tmp_rates_stress,tmp_delta_stress);
            end 
        end 
        % sort nodes and accordingly original and stress rates:
            [tmp_nodes tmp_indizes] = sort(tmp_nodes);
            tmp_rates_original = tmp_rates_original(:,tmp_indizes);
            tmp_rates_stress = tmp_rates_stress(:,tmp_indizes);
        % store values in struct
        curve_object = curve_object.set('nodes',tmp_nodes);
        % contains matrix: rows     = stress shift type values (0 or 1), 
        %                  columns  = nodes of curve
        curve_object = curve_object.set('rates_base',tmp_rates_original);          
        % contains matrix with delta of stress:
        curve_object = curve_object.set('rates_stress',tmp_rates_stress);   
        % loop via all mc timesteps
        for kk = 1:1:length(mc_timesteps)
            tmp_ts = mc_timesteps{kk};
            % get original yield curve
            tmp_rates_shock = [];  
            tmp_nodes = [];
            tmp_model_cell = {};
            for jj = 1 : 1 : length( riskfactor_struct )
                tmp_rf_struct_obj = riskfactor_struct( jj ).object;
                tmp_rf_id = tmp_rf_struct_obj.id;
                if ( regexp(tmp_rf_id,tmp_curve_id) == 1 )           
                    tmp_delta_shock     = tmp_rf_struct_obj.getValue(tmp_ts);
                    % just needed for sorting final results:
                    tmp_node            = tmp_rf_struct_obj.get('node'); 
                    tmp_nodes 		    = cat(2,tmp_nodes,tmp_node);
                    % Calculate new absolute values from Riskfactor PnL 
                    % depending on riskfactor model:
                    tmp_model           = tmp_rf_struct_obj.get('model');
                    tmp_model_cell{end + 1 } = tmp_model;
                    if ( strcmp(tmp_model,{'GBM','BKM'}))
                        tmp_shocktype_mc = 'relative';
                        tmp_delta_shock = exp(tmp_delta_shock);
                    else
                        tmp_shocktype_mc = 'absolute';
                    end          
                    tmp_rates_shock = cat(2,tmp_rates_shock,tmp_delta_shock);
                end
            end  
            % sort nodes and accordingly original and stress rates:
                [tmp_nodes tmp_indizes] = sort(tmp_nodes);
                tmp_rates_shock = tmp_rates_shock(:,tmp_indizes);
            % check, whether all risk factors of one curve have the same model
            if ( length(unique(tmp_model_cell)) > 1 )
                fprintf('WARNING: octarisk::load_yieldcurves: ', ...
                        'one curve has different stochastic models ', ...
                        'for their nodes: %s\n',tmp_model_cell);
            end
            % Save curves into struct
            curve_object = curve_object.set('rates_mc',tmp_rates_shock, ...
                                            'timestep_mc',tmp_ts); 
        end  % close loop via scenario_sets (mc,stress)
        % store shocktype_mc
        curve_object = curve_object.set('shocktype_mc',tmp_shocktype_mc);
        % store curve object in final struct
        curve_struct( ii ).object = curve_object;
        
    catch   % catch errors in generating curves from risk factor nodes
        fprintf('WARNING: octarisk::load_yieldcurves: ');
        fprintf('There has been an error for curve: >>%s<<. ',tmp_curve_id);
        fprintf('Message: >>%s<< Line: >>%d<<\n',lasterr,lasterror.stack.line);
        curve_failed_cell{ length(curve_failed_cell) + 1 } =  tmp_curve_id;
    end % end try catch
end    % close loop via all curves

% append Dummy Spread Curve (used for all instruments without 
% defined spread curve): 
curve_struct( length(rf_ir_cur_cell) + 1  ).id = 'RF_SPREAD_DUMMY';    
curve_object = Curve('RF_SPREAD_DUMMY','RF_SPREAD_DUMMY','Spread Curve', ...
                    'Dummy Spread curve with zero rates');
curve_object = curve_object.set('nodes',[365]);
curve_object = curve_object.set('rates_base',[0]);
curve_object = curve_object.set('rates_stress',[0]);
for kk = 1:1:length(mc_timesteps)    % append dummy curves for all mc_timesteps
    curve_object = curve_object.set('rates_mc',[0], ...
                                    'timestep_mc',mc_timesteps{kk});
end    
curve_struct( length(rf_ir_cur_cell) + 1  ).object = curve_object;   

% end filling curve_struct

% saving struct
if saving == 1
    % Saving curve_struct: loop via all objects in structs and convert
    tmp_curve_struct = curve_struct;
    for ii = 1 : 1 : length( tmp_curve_struct )
        tmp_curve_struct(ii).object = struct(tmp_curve_struct(ii).object);
    end 
    savename = 'tmp_curve_struct';
	fullpath = [path_output, savename, endung];
	save ('-text', fullpath, savename);
end
 
% returning statistics
fprintf('SUCCESS: generated >>%d<< curves from >>%d<< IR and SPREAD risk factors. \n', ...
        length(rf_ir_cur_cell),number_riskfactors);
if (length(curve_failed_cell) > 0 )
    fprintf('WARNING: octarisk::load_yieldcurves: >>%d<< curve generations failed: \n', ...
            length(curve_failed_cell));
    curve_failed_cell
end 

end
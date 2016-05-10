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
%# @deftypefn {Function File} {[@var{index_struct} @var{curve_struct} @var{id_failed_cell}] =} update_mktdata_objects(@var{mktdata_struct},@var{index_struct},@var{riskfactor_struct},@var{curve_struct})
%# Update all market data objects with scenario dependent risk factor and curve shocks. 
%# Return index struct and curve struct with scenario dependent absolute values. @*
%# Calculate reciprocal FX conversion factors for all market objects (e.g. FX_USDEUR = 1 ./ FX_USDEUR)
%# @end deftypefn

function [index_struct curve_struct id_failed_cell] = update_mktdata_objects(mktdata_struct,index_struct,riskfactor_struct,curve_struct)

id_failed_cell = {};
index_curve_objects = 0;
% loop through all mktdata objects
for ii = 1 : 1 : length(mktdata_struct)
    % get class -> switch between curve, index
    tmp_object = mktdata_struct(ii).object;
    tmp_class = lower(class(tmp_object));
    if ( strcmp(tmp_class,'index'))
      tmp_id = tmp_object.id;
      try
        tmp_rf_id = strcat('RF_',tmp_id);
        tmp_rf_object = get_sub_object(riskfactor_struct, tmp_rf_id);
        % get risk factor object values
        tmp_scenario_mc_shock   = tmp_rf_object.get('scenario_mc');
        tmp_stress_shock        = tmp_rf_object.get('scenario_stress');
        tmp_model               = tmp_rf_object.get('model');
        if ( sum(strcmp(tmp_model,{'GBM','BKM'})) > 0 ) % Log-normal Motion
            tmp_scenario_values     =  exp(tmp_scenario_mc_shock) .*  tmp_object.value_base;
        else        % Normal Model
            tmp_scenario_values     = tmp_scenario_mc_shock + tmp_object.value_base;
        end
        tmp_stress_value    = (1+tmp_stress_shock) .* tmp_object.value_base;
        tmp_timesteps_mc    = tmp_rf_object.get('timestep_mc');
        % set object values:
        tmp_object = tmp_object.set('scenario_mc', tmp_scenario_values );
        tmp_object = tmp_object.set('scenario_stress', tmp_stress_value );
        tmp_object = tmp_object.set('timestep_mc', tmp_timesteps_mc );  

        tmp_store_struct = length(index_struct) + 1;        
        index_struct( tmp_store_struct ).id      = tmp_object.id;
        index_struct( tmp_store_struct ).name    = tmp_object.name;
        index_struct( tmp_store_struct ).object  = tmp_object;
        index_curve_objects = index_curve_objects + 1;
      catch
        fprintf('ERROR: There has been an error for new Index object: %s \n',tmp_id);
        id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_id;
      end
    elseif ( strcmp(tmp_class,'curve'))
        tmp_id = tmp_object.id;
      try
        tmp_rf_id = strcat('RF_',tmp_id);
        tmp_rf_object = get_sub_object(curve_struct, tmp_rf_id);
        interp_method = tmp_rf_object.get('method_interpolation');
        % get base values of mktdata curve
        curve_nodes      = tmp_object.get('nodes');
        curve_rates_base = tmp_object.get('rates_base');
        tmp_ir_shock_matrix = [];
        
        % get stress values of risk factor curve
        rf_shock_nodes    = tmp_rf_object.get('nodes');
        rf_shock_rates    = tmp_rf_object.getValue('stress') ;
        rf_shifttype      = tmp_rf_object.get('rates_base');
        rf_shifttype      = rf_shifttype(:,1);   % get just first column of shifttype matrix ->  per stresstest one shifttype for all nodes (columns)
        % loop through all IR Curve nodes and get interpolated shock value from risk factor
        
        for ii = 1 : 1 : length(curve_nodes)
            tmp_node = curve_nodes(ii);
            % get interpolated shock vector at node
            tmp_shock = interpolate_curve(rf_shock_nodes,rf_shock_rates,tmp_node,interp_method);
            % generate total shock matrix
            tmp_ir_shock_matrix = horzcat(tmp_ir_shock_matrix,tmp_shock);
        end
        rf_shifttype_inv  = 1 - rf_shifttype;
        curve_rates_stress = rf_shifttype_inv .* (curve_rates_base + (tmp_ir_shock_matrix ./ 10000)) + (rf_shifttype .* curve_rates_base .* (1 + tmp_ir_shock_matrix)); %calculate abs and rel shocks and sum up (mutually exclusive)
        clear tmp_ir_shock_matrix;
        tmp_object = tmp_object.set('rates_stress',curve_rates_stress);
        
        % loop through all timestep_mc 
        tmp_timestep_mc = tmp_rf_object.get('timestep_mc');
        
        tmp_shocktype_mc = tmp_rf_object.get('shocktype_mc');
        for kk = 1 : 1 : length(tmp_timestep_mc)
            tmp_value_type = tmp_timestep_mc{kk};
            rf_shock_nodes    = tmp_rf_object.get('nodes');
            rf_shock_rates    = tmp_rf_object.getValue(tmp_value_type);
            % loop through all IR Curve nodes and get interpolated shock value from risk factor
            tmp_ir_shock_matrix = [];
            for ii = 1 : 1 : length(curve_nodes)
                tmp_node = curve_nodes(ii);
                % get interpolated shock vector at node
                tmp_shock = interpolate_curve(rf_shock_nodes,rf_shock_rates,tmp_node,interp_method);
                % generate total shock matrix
                tmp_ir_shock_matrix = horzcat(tmp_ir_shock_matrix,tmp_shock);
            end
            if ( strcmp(tmp_shocktype_mc,'relative'))
                curve_rates_mc = curve_rates_base .* tmp_ir_shock_matrix;
            elseif ( strcmp(tmp_shocktype_mc,'absolute'))
                curve_rates_mc = curve_rates_base + tmp_ir_shock_matrix;
            else
                fprintf('No valid shock type defined [relative,absolute]: >>%s<< \n',tmp_shocktype_mc);
            end
            clear tmp_ir_shock_matrix;
            tmp_object = tmp_object.set('timestep_mc',tmp_value_type);
            tmp_object = tmp_object.set('rates_mc',curve_rates_mc);
        end

        % store everything in curve struct
        tmp_store_struct = length(curve_struct) + 1;
        curve_struct( tmp_store_struct ).id      = tmp_object.id;
        curve_struct( tmp_store_struct ).name    = tmp_object.name;
        curve_struct( tmp_store_struct ).object  = tmp_object;
        index_curve_objects = index_curve_objects + 1;
      catch
        fprintf('ERROR: There has been an error for new Curve object: %s \n',tmp_id);
        id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_id;
      end
    end % end class select
end % end for loop through all mktdata objects

fprintf('SUCCESS: generated >>%d<< index and curve objects from marketdata. \n',index_curve_objects);


% Caculate reciprocal FX conversion factors
new_fx_reciprocal_objects = 0;
for ii = 1 : 1 : length(index_struct)
    tmp_object = index_struct(ii).object;
    tmp_class = lower(class(tmp_object));
    if ( strcmp(tmp_class,'index')) % get class -> FX conversion factors are of class index
        if ( strcmp(tmp_object.type,'Exchange Rate') )    % FX have type 'Exchange Rate'  
            tmp_id = tmp_object.id;
            tmp_base_cur = tmp_id(4:6);
            tmp_foreign_cur = tmp_id(7:9);
            tmp_reciproc_id = strcat('FX_',tmp_foreign_cur,tmp_base_cur);
          try
            % deriving new Exchange rate parameters
                tmp_base_cur = tmp_id(4:6);
                tmp_foreign_cur = tmp_id(7:9);
                tmp_reciproc_id = strcat('FX_',tmp_foreign_cur,tmp_base_cur);
                tmp_reciproc_name = strcat(tmp_foreign_cur,'_',tmp_base_cur);
                tmp_description = strcat(tmp_foreign_cur,' ',tmp_base_cur,' Exchange Rate');
                tmp_value_base = 1 ./ tmp_object.get('value_base');
                tmp_scenario_stress = 1 ./ tmp_object.get('scenario_stress');
                tmp_scenario_mc = 1 ./ tmp_object.get('scenario_mc');
                tmp_timestep_mc = tmp_object.get('timestep_mc');
            % invoke new object of class indes:
            tmp_new_fx_object = Index();
            tmp_new_fx_object = tmp_new_fx_object.set('name',tmp_object.name,'id',tmp_reciproc_id,'description',tmp_description, ...
                                'type',tmp_object.type,'currency',tmp_foreign_cur,'value_base',tmp_value_base, ...
                                'timestep_mc',tmp_timestep_mc,'scenario_mc',tmp_scenario_mc,'scenario_stress',tmp_scenario_stress);
            tmp_len_indexstruct = length(index_struct) + 1;
            index_struct( tmp_len_indexstruct ).id = tmp_reciproc_id;
            index_struct( tmp_len_indexstruct ).object = tmp_new_fx_object;
            new_fx_reciprocal_objects = new_fx_reciprocal_objects + 1;
          catch
            fprintf('ERROR: There has been an error for new FX object: %s \n',tmp_reciproc_id);
            id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_reciproc_id;
          end
        end
    end

end % end for loop for FX conversion factors

fprintf('SUCCESS: generated >>%d<< reciprocal FX index objects. \n',new_fx_reciprocal_objects);
if (length(id_failed_cell) > 0 )
    fprintf('WARNING: >>%d<< mktdata objects failed: \n',length(id_failed_cell));
    id_failed_cell
end

end % end function

% ########         HELPER FUNCTIONS              ########
% function for extracting sub-structure object from struct object according to id
function  match_obj = get_sub_object(input_struct, input_id)
 	matches = 0;	
	a = {input_struct.id};
	b = 1:1:length(a);
	c = strcmp(a, input_id);	
    % correct for multiple matches:
    if ( sum(c) > 1 )
        summe = 0;
        for ii=1:1:length(c)
            if ( c(ii) == 1)
                match_struct = input_struct(ii);
                ii;
                return;
            end            
            summe = summe + 1;
        end       
    end
    matches = b * c';
	if (matches > 0)
	    	match_obj = input_struct(matches).object;
		return;
	else
	    	error(' No matches found for input_id: >>%s<<',input_id);
		return;
	end
end

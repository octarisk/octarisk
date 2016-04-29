function [index_struct curve_struct id_failed_cell] = update_mktdata_objects(mktdata_struct,index_struct,riskfactor_struct,curve_struct)

id_failed_cell = {};
% loop through all mktdata objects
for ii = 1 : 1 : length(mktdata_struct)
    % get class -> switch between curve, index
    tmp_object = mktdata_struct(ii).object;
    tmp_class = lower(class(tmp_object));
    if ( strcmp(tmp_class,'index'))
        tmp_id = tmp_object.id;
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
    elseif ( strcmp(tmp_class,'curve'))
        tmp_id = tmp_object.id;
        tmp_rf_id = strcat('RF_',tmp_id);
        tmp_rf_object = get_sub_object(curve_struct, tmp_rf_id);
        interp_method = tmp_rf_object.get('method_interpolation');
        % get base values of mktdata curve
        curve_nodes      = tmp_object.get('nodes');
        curve_rates_base = tmp_object.get('rates_base');
        tmp_ir_shock_matrix = [];
        % get stress values of risk factor curve
        rf_shock_nodes    = tmp_rf_object.get('nodes');
        rf_shock_rates    = tmp_rf_object.getValue('stress') ./ 10000;
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
        curve_rates_stress = rf_shifttype_inv .* (curve_rates_base + (tmp_ir_shock_matrix )) + (rf_shifttype .* curve_rates_base .* tmp_ir_shock_matrix); %calculate abs and rel shocks and sum up (mutually exclusive)
        clear tmp_ir_shock_matrix;
        tmp_object = tmp_object.set('rates_stress',curve_rates_stress);
        % loop through all timestep_mc and stress values
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
    end % end class select
end % end for loop through all mktdata objects

end % end function

% III) %#%#%%#         HELPER FUNCTIONS              %#%#
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
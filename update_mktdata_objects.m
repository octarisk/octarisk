%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
%# Copyright (C) 2016 IRRer-Zins <IRRer-Zins@t-online.de>
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
%# @deftypefn {Function File} {[@var{index_struct} @var{curve_struct} @var{id_failed_cell}] =} update_mktdata_objects(@var{mktdata_struct}, @var{index_struct}, @var{riskfactor_struct}, @var{curve_struct})
%# Update all market data objects with scenario dependent risk factor and curve shocks.
%# Return index struct and curve struct with scenario dependent absolute values. @*
%# Calculate reciprocal FX conversion factors for all exchange rate market objects (e.g. FX_USDEUR = 1 ./ FX_USDEUR).
%# During aggregation and instrument currency conversion the appropriate FX exchange rate is always chosen by FX_BasecurrencyForeigncurrency)
%# Volatility surfaces and cube MC and stress shocks are generated in script load_volacubes.m
%# @end deftypefn

function [index_struct curve_struct surface_struct id_failed_cell] = update_mktdata_objects(valuation_date,instrument_struct,mktdata_struct,index_struct,riskfactor_struct,curve_struct,surface_struct,timesteps_mc,mc,no_stresstests,run_mc,stress_struct)

id_failed_cell = {};
index_curve_objects = 0;
% loop through all Index and Curve mktdata objects (except Aggregated Curves -> stacked in next step)
for ii = 1 : 1 : length(mktdata_struct)
    % get class -> switch between curve, index, surface
    tmp_object = mktdata_struct(ii).object;
    tmp_class = lower(class(tmp_object));
    if ( strcmp(tmp_class,'index') && ~strcmpi(tmp_object.type,'aggregated index'))
        tmp_id = tmp_object.id;
        try
            % a) apply Stress scenario shocks
                % reserve stress_values matrix
                stress_values = zeros(length(stress_struct),columns(tmp_object.getValue('base'))) ;

                % iterate via all stress definitions
                for ii = 1:1:length(stress_struct)
                    % get struct with all market object shocks
                    subst = stress_struct(ii).objects;
                    % get appropriate market object
                    [mktstruct retcode] = get_sub_struct(subst,tmp_object.id);
                    if ( retcode == 1)  % market data is contained in stress
                        stress_values(ii,:) = return_stress_shocks(tmp_object,mktstruct);
                    else
                        % apply base value
                        stress_values(ii,:) = tmp_object.getValue('base');
                    end
                end
                % set instrument stress vector
                tmp_object = tmp_object.set('scenario_stress',stress_values);

            % b) apply MC scenario shocks
            if ( run_mc == true)
                tmp_rf_id = strcat('RF_',tmp_id);
                [tmp_rf_object ret_code] = get_sub_object(riskfactor_struct, tmp_rf_id);
                if (ret_code == 1)  % match found -> market object has attached risk factor
                    % get risk factor object values
                    tmp_model               = tmp_rf_object.get('model');
                    % set mc object values:
                    tmp_scenario_mc_shock   = tmp_rf_object.get('scenario_mc');
                    if ( sum(strcmp(tmp_model,{'GBM','BKM'})) > 0 ) % Log-normal Motion
                        tmp_scenario_values     =  exp(tmp_scenario_mc_shock) .*  tmp_object.value_base;
                    else        % Normal Model
                        tmp_scenario_values     = tmp_scenario_mc_shock + tmp_object.value_base;
                    end
                    tmp_timesteps_mc    = tmp_rf_object.get('timestep_mc');
                    tmp_object = tmp_object.set('scenario_mc', tmp_scenario_values );
                    tmp_object = tmp_object.set('timestep_mc', tmp_timesteps_mc );
                end     % no match found, market object has no attached risk factor
            end
            tmp_store_struct = length(index_struct) + 1;
            index_struct( tmp_store_struct ).id      = tmp_object.id;
            index_struct( tmp_store_struct ).name    = tmp_object.name;
            index_struct( tmp_store_struct ).object  = tmp_object;
            index_curve_objects = index_curve_objects + 1;
        catch
            fprintf('ERROR: There has been an error for new Index object:  >>%s<<. Message: >>%s<< \n',tmp_id,lasterr);
            id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_id;
        end
    % Surfaces  --> Surface scenario values are loaded in script "load_volacubes.m"
    elseif ( strcmpi(tmp_class,'surface'))
        tmp_id = tmp_object.id;
        try  
            % % a) apply Stress scenario shocks
            % tmp_object = tmp_object.apply_stress_shocks(stress_struct);
            % % b) apply MC scenario shocks
            % if ( run_mc == true)
                % % Update MC risk factor shock values
                % tmp_object = tmp_object.apply_rf_shocks(riskfactor_struct);
            % end

            % store surface object in struct
            tmp_store_struct = length(surface_struct) + 1;
            surface_struct( tmp_store_struct ).id      = tmp_id;
            surface_struct( tmp_store_struct ).object  = tmp_object;
            index_curve_objects = index_curve_objects + 1;
        catch
            fprintf('ERROR: There has been an error for new Surface object:  >>%s<<. Message: >>%s<< \n',tmp_id,lasterr);
            id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_id;
        end
    % Curves    
    elseif ( strcmpi(tmp_class,'curve') && ~strcmpi(tmp_object.type,'aggregated curve'))
        tmp_id = tmp_object.id;
        try
            % a) get base values of mktdata curve and sort them
                % get base values of mktdata curve
                curve_nodes      = tmp_object.get('nodes');
                curve_rates_base = tmp_object.get('rates_base');
                % sort nodes and accordingly base rates:
                if (curve_nodes >= 0 )
                    [curve_nodes tmp_indizes] = sort(curve_nodes);
                    curve_rates_base = curve_rates_base(:,tmp_indizes);
                elseif (curve_nodes <= 0 )
                    [curve_nodes tmp_indizes] = sort(curve_nodes,'descend');
                    curve_rates_base = curve_rates_base(:,tmp_indizes);
                end
                tmp_object = tmp_object.set('rates_base',curve_rates_base); % restore rates base. Maybe they were unsorted.
                tmp_object = tmp_object.set('nodes',curve_nodes); % restore nodes. Maybe they were unsorted.
            
            % b) apply stress scenario shocks to market data curve

                % set stressed_values
                stress_values = zeros(length(stress_struct),columns(tmp_object.getValue('base'))) ;
                % iterate via all stress definitions
                for ii = 1:1:length(stress_struct)
                    % get struct with all market object shocks
                    subst = stress_struct(ii).objects;
                    % get approriate market object
                    [mktstruct retcode] = get_sub_struct(subst,tmp_object.id);
                    if ( retcode == 1)  % market data is contained in stress
                        stress_values(ii,:) = return_stress_shocks(tmp_object,mktstruct);
                    else
                        % apply base value
                        stress_values(ii,:) = tmp_object.getValue('base');
                    end
                    
                end
                % set instrument stress vector
                tmp_object = tmp_object.set('rates_stress',stress_values);

            
            % c) apply MC scenario shocks to market data curve
            if ( run_mc == true)
                tmp_rf_id = strcat('RF_',tmp_id);
                [tmp_rf_object ret_code] = get_sub_object(curve_struct, tmp_rf_id);
                if (ret_code == 1)  % match found -> market object has attached risk factor -> calculate appropriate scenario values
                
                    tmp_timestep_mc = tmp_rf_object.get('timestep_mc');
                    tmp_shocktype_mc = tmp_rf_object.get('shocktype_mc');
                    % loop through all timestep_mc
                    for kk = 1 : 1 : length(tmp_timestep_mc)
                        tmp_value_type = tmp_timestep_mc{kk};
                        rf_shock_nodes    = tmp_rf_object.get('nodes');
                        rf_shock_rates    = tmp_rf_object.getValue(tmp_value_type);
                        % 1. loop through all risk factor shock values and calculate
                        % sln values
                        if  ( strcmpi(tmp_rf_object.get('shocktype_mc'),'sln_relative'))
                            shock_vec = [];
                            for jj = 1 : 1 : length(rf_shock_nodes)
                                tmp_node = rf_shock_nodes(jj);
                                tmp_shock = tmp_rf_object.getRate(tmp_value_type,tmp_node);
                                % in case of shifted log-normal: adjust shock and calculate absolute shock
                                    tmp_shocktype_mc = 'absolute';
                                    sln_level_vector = tmp_rf_object.get('sln_level');
                                    % interpolate sln level:
                                    sln_level = interpolate_curve(rf_shock_nodes,sln_level_vector,tmp_node,tmp_rf_object.method_interpolation);
                                    tmp_rate_base = tmp_object.getRate('base',tmp_node);
                                    tmp_shock = (( tmp_rate_base + sln_level ) .* tmp_shock - sln_level) - tmp_rate_base;
                                
                                shock_vec = horzcat(shock_vec,tmp_shock);
                            end
                            rf_shock_rates = shock_vec;
                        end
                        % 2. loop through all IR Curve nodes and get interpolated shock value from risk factor
                        tmp_ir_shock_matrix = zeros(rows(rf_shock_rates),length(curve_nodes));
                        
                        for ii = 1 : 1 : length(curve_nodes)
                            tmp_node = curve_nodes(ii);
                            % get interpolated shock vector at node and generate total shock matrix
                            tmp_ir_shock_matrix(:,ii) = interpolate_curve(rf_shock_nodes, ...
                                rf_shock_rates,tmp_node,tmp_rf_object.method_interpolation);
                        end
                        if ( strcmp(tmp_shocktype_mc,'relative'))
                            curve_rates_mc = curve_rates_base .* tmp_ir_shock_matrix;
                        elseif ( strcmp(tmp_shocktype_mc,'absolute'))
                            % Matlab Adaption
                            %curve_rates_base_temp=repmat(curve_rates_base,size(tmp_ir_shock_matrix,1),1);
                            %curve_rates_mc = curve_rates_base_temp + tmp_ir_shock_matrix;
                            
                            curve_rates_mc = curve_rates_base + tmp_ir_shock_matrix;
                        else
                            fprintf('No valid shock type defined [relative,absolute,sln_relative]: >>%s<< \n',tmp_shocktype_mc);
                        end
                        tmp_object = tmp_object.set('timestep_mc',tmp_value_type);
                        tmp_object = tmp_object.set('rates_mc',curve_rates_mc);
                        
                    end
                end
            end % no match found, market object has no attached risk factor -> just store in curve struct
            % store everything in curve struct
            tmp_store_struct = length(curve_struct) + 1;
            curve_struct( tmp_store_struct ).id      = tmp_object.id;
            curve_struct( tmp_store_struct ).name    = tmp_object.name;
            curve_struct( tmp_store_struct ).object  = tmp_object;
            index_curve_objects = index_curve_objects + 1;
        catch
            fprintf('ERROR: update_mktdata_objects: There has been an error for new Curve object:  >>%s<<. Message: >>%s<< in line >>%d<< \n',tmp_id,lasterr,lasterror.stack.line);
            id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_id;
        end
    end % end class select
end % end for loop through all mktdata objects

fprintf('SUCCESS: generated >>%d<< index and curve objects from marketdata. \n',index_curve_objects);

% ##################              Curve Stacking         #######################
% get all curves from instrument_struct and stack these curves only (reduce memory consumption)
used_curved_list = get_used_curves_from_instruments(instrument_struct);
aggr_curve_objects = 0;
for ii = 1 : 1 : length(mktdata_struct)
    % get class -> switch between curve, index
    tmp_object = mktdata_struct(ii).object;
    tmp_class = lower(class(tmp_object));
    if ( strcmpi(tmp_class,'curve') && strcmpi(tmp_object.type,'aggregated curve'))
        tmp_id = tmp_object.id;
        if ( sum(strcmpi(tmp_id,used_curved_list))>0)   % curve used for instruments
          try
            % check whether aggregated index was not already generated
            [tmp_obj ret_code] = get_sub_object(curve_struct,tmp_id);
            if (ret_code == 1)
                fprintf('octarisk::update_mktdata_objects: Curve >>%s<< already aggregated. Skipping.\n',any2str(tmp_id));
            else
                % call helper function for aggregating curve objects
                [tmp_object curve_struct] = aggregate_curve_ojects(tmp_object,valuation_date, ...
                                mktdata_struct,index_struct,riskfactor_struct, ...
                                curve_struct,surface_struct,timesteps_mc,mc,no_stresstests,run_mc);

                aggr_curve_objects = aggr_curve_objects + 1;
                % store everything in curve struct
                tmp_store_struct = length(curve_struct) + 1;
                curve_struct( tmp_store_struct ).id      = tmp_object.id;
                curve_struct( tmp_store_struct ).name    = tmp_object.name;
                curve_struct( tmp_store_struct ).object  = tmp_object;
            end
          catch
                fprintf('WARNING: octarisk::update_mktdata_objects: There has been an error for new Curve object:  >>%s<<. Message: >>%s<< in line >>%d<< \n',any2str(tmp_id),lasterr,lasterror.stack.line);
                id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_id;
          end
        end % else unused curve -> do nothing, no stacking at all
    end
end
fprintf('SUCCESS: generated >>%d<< aggregated curve objects from marketdata. \n',aggr_curve_objects);


% Calculate reciprocal FX conversion factors (it is only required to define one conversion factor for each currency.
% regardless, whether there is an attached risk factor, the reciprocal base (and scenario) values are taken
% for the corresponding FX exchange rate
new_fx_reciprocal_objects = 0;
for ii = 1 : 1 : length(index_struct)
    tmp_object = index_struct(ii).object;
    tmp_class = lower(class(tmp_object));
    if ( strcmpi(tmp_class,'index')) % get class -> FX conversion factors are of class index
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
                
                % invoke new object of class indes:
                tmp_new_fx_object = Index();
                tmp_new_fx_object = tmp_new_fx_object.set('name',tmp_reciproc_name,'id',tmp_reciproc_id,'description',tmp_description, ...
                    'type',tmp_object.type,'currency',tmp_foreign_cur,'value_base',tmp_value_base, ...
                    'scenario_stress',tmp_scenario_stress);
                % store scenario_mc only, if scenario_mc vector contains values (if base Exchange rate has attached risk factor):
                if ( run_mc == true)
                    tmp_scenario_mc = 1 ./ tmp_object.get('scenario_mc');
                    tmp_timestep_mc = tmp_object.get('timestep_mc');
                    if ~(isempty(tmp_scenario_mc))
                        tmp_new_fx_object = tmp_new_fx_object.set('timestep_mc',tmp_timestep_mc,'scenario_mc',tmp_scenario_mc);
                    end
                end
                tmp_len_indexstruct = length(index_struct) + 1;
                index_struct( tmp_len_indexstruct ).id = tmp_reciproc_id;
                index_struct( tmp_len_indexstruct ).object = tmp_new_fx_object;
                new_fx_reciprocal_objects = new_fx_reciprocal_objects + 1;
            catch
                fprintf('ERROR: There has been an error for new FX object: >>%s<<. Message: >>%s<< \n',tmp_reciproc_id,lasterr);
                id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_reciproc_id;
            end
        end
    end
    
end % end for loop for FX conversion factors

fprintf('SUCCESS: generated >>%d<< reciprocal FX index objects. \n',new_fx_reciprocal_objects);

% ##################              Index Stacking         #######################
aggr_index_objects = 0;
for ii = 1 : 1 : length(mktdata_struct)
    % get class -> switch between curve, index
    tmp_object = mktdata_struct(ii).object;
    tmp_class = lower(class(tmp_object));
    if ( strcmpi(tmp_class,'index') && strcmpi(tmp_object.type,'aggregated index'))
        tmp_id = tmp_object.id;
        try
            % call helper function for aggregating curve objects
            % check whether aggregated index was not already generated
            [tmp_obj ret_code] = get_sub_object(index_struct,tmp_id);
            if (ret_code == 1)
                fprintf('octarisk::update_mktdata_objects: Index >>%s<< already aggregated. Skipping.\n',any2str(tmp_id));
            else
                [tmp_object index_struct] = aggregate_index_ojects(tmp_object,valuation_date, ...
                                       mktdata_struct,index_struct,riskfactor_struct, ...
                                       index_struct,surface_struct,timesteps_mc,mc,no_stresstests,run_mc);

                aggr_index_objects = aggr_index_objects + 1;
                % store everything in curve struct
                tmp_store_struct = length(index_struct) + 1;
                index_struct( tmp_store_struct ).id      = tmp_object.id;
                index_struct( tmp_store_struct ).name    = tmp_object.name;
                index_struct( tmp_store_struct ).object  = tmp_object;
            end
        catch
            fprintf('WARNING: octarisk::update_mktdata_objects: There has been an error for new Curve object:  >>%s<<. Message: >>%s<< in line >>%d<< \n',any2str(tmp_id),lasterr,lasterror.stack.line);
            id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_id;
        end
    end
end
fprintf('SUCCESS: generated >>%d<< aggregated index objects from marketdata. \n',aggr_index_objects);


if (length(id_failed_cell) > 0 )
    fprintf('WARNING: >>%d<< mktdata objects failed: \n',length(id_failed_cell));
    id_failed_cell
end

end % end function


% ##############################################################################
% Helper Function for getting used curves
function used_curved_list = get_used_curves_from_instruments(instrument_struct)

used_curved_list = {};
attribute_list = {'discount_curve','reference_curve','prepayment_curve','spread_curve'};
for ii = 1:1:length(instrument_struct)
    obj = instrument_struct(ii).object;
    % look for attributes
    try
        for kk = 1:1:length(attribute_list)
            if obj.isProp(attribute_list{kk})
                curve_id = obj.get(attribute_list{kk});
                % store curve id
                if ( sum(strcmpi(curve_id,used_curved_list))==0)
                    used_curved_list{ length(used_curved_list) + 1 } = curve_id;
                end
            end
        end   
    end
end
% return list
end

% Helper Function for applying market data stresses
function retval = return_stress_shocks(obj,mktstruct)
    retval = 0.0;
    type        = mktstruct.type;
    shock_type  = mktstruct.shock_type;
    shock_value = mktstruct.shock_value;
    minshock    = mktstruct.minshock;
    maxshock    = mktstruct.maxshock;
    % type index
    if (strcmpi(type,'index'))
        base_value = obj.getValue('base');
        if (strcmpi(shock_type,'relative'))
            appliedshock = base_value .* (shock_value - 1);
            if ( ~isempty(minshock))
                appliedshock(abs(appliedshock)<minshock) = sign(appliedshock).*minshock;
            end
            if ( ~isempty(maxshock))
                appliedshock(abs(appliedshock)>maxshock) = sign(appliedshock).*maxshock;
            end
            retval = base_value + appliedshock;
        elseif (strcmpi(shock_type,'absolute'))
            retval = base_value + shock_value;
        elseif (strcmpi(shock_type,'value'))
            retval = shock_value;
        else
            error('return_stress_shocks: unknown stress shock type: >>%s<<\n',any2str(shock_type));
        end
        
    % type curve
    elseif (strcmpi(type,'curve'))
        % get base rates and nodes of curve
        rates_base = obj.get('rates_base');
        nodes = obj.get('nodes');
        rates_stress = zeros(1,length(nodes));
        
        % apply interpolated shocks to all base rates
        for kk = 1:1:length(nodes)
            tmp_node = nodes(kk);
            shock_value = interpolate_curve (mktstruct.term, ...
                                mktstruct.shock_value, tmp_node, ...
                                mktstruct.method_interpolation);
            if (strcmpi(shock_type,'relative'))
                appliedshock = rates_base(kk) .* (shock_value - 1);
                if ( ~isempty(minshock))
                    appliedshock(abs(appliedshock)<minshock) = sign(appliedshock).*minshock;
                end
                if ( ~isempty(maxshock))
                    appliedshock(abs(appliedshock)>maxshock) = sign(appliedshock).*maxshock;
                end
                rates_stress(kk)  = rates_base(kk) + appliedshock;
            elseif (strcmpi(shock_type,'absolute'))
                rates_stress(kk)  = rates_base(kk) + shock_value;
            elseif (strcmpi(shock_type,'value'))
                rates_stress(kk)  = shock_value;
            else
                error('return_stress_shocks: unknown stress shock type: >>%s<<\n',any2str(shock_type));
            end
        end
        % return stressed rates
        retval = rates_stress;
    % other types
    else
        error('return_stress_shocks: unknown stress type: >>%s<<\n',any2str(type));
    end
end

% ==============================================================================
% Helper Function for stacking curves
function [tmp_object curve_struct] = aggregate_curve_ojects(tmp_object, ...
                valuation_date,mktdata_struct,index_struct,riskfactor_struct, ...
                curve_struct,surface_struct,timesteps_mc,mc,no_stresstests,run_mc)

%fprintf('New type aggregated object: %s \n',tmp_id);
% get nodes of aggr curve and set rates
%disp("make empty containers")
nestedaggregation = false;
aggr_curve_nodes      = tmp_object.get('nodes');
aggr_curve_function   = tmp_object.get('curve_function');
aggr_curve_parameter  = tmp_object.get('curve_parameter');
aggr_curve_rates_base = zeros(1,length(aggr_curve_nodes));                      % make base rate curve
aggr_curve_rates_stress = zeros(no_stresstests,length(aggr_curve_nodes));       % make two dimensional rates surface for stess rates
aggr_curve_rates_mc = zeros(mc,length(aggr_curve_nodes),length(timesteps_mc));   % make three dimensional cube with zero mc rates
% sort nodes and accordingly base rates:
[aggr_curve_nodes tmp_indizes] = sort(aggr_curve_nodes);

% get dcc, comp type and freq of aggregated curve (target values)
comp_type_target = tmp_object.get('compounding_type');
comp_freq_target = tmp_object.get('compounding_freq');
dcc_basis_target = tmp_object.get('basis');

% get increments of aggr curve
aggr_curve_increments = tmp_object.get('increments');
% loop through all increments
for kk = 1 : 1 : length(aggr_curve_increments)
    tmp_incr_id = aggr_curve_increments{kk};
    % searching for curve increment in curve_struct
    [tmp_incr_object ret_code] = get_sub_object(curve_struct, tmp_incr_id);
    if (ret_code == 1)  % match found -> market object has underlying increment curve -> calculate appropriate scenario values
        interp_method = tmp_incr_object.get('method_interpolation');
        
        % get dcc, comp type and freq of increment curve (original values)
        comp_type_origin = tmp_incr_object.get('compounding_type');
        comp_freq_origin = tmp_incr_object.get('compounding_freq');
        dcc_basis_origin = tmp_incr_object.get('basis');
        
        %fprintf('Actual increment:%s\n',tmp_incr_id);
        % loop through all IR Curve nodes and get interpolated shock value from risk factor
        tmp_incr_stress_rate = [];  %zeros(no_stresstests,length(aggr_curve_nodes));
        tmp_incr_base_rate = [];
        for ii = 1 : 1 : length(aggr_curve_nodes)
            tmp_node = aggr_curve_nodes(ii);
            % get interpolated shock vector at node
            rate_stress_origin  = tmp_incr_object.getRate('stress',tmp_node);
            rate_base_origin    = tmp_incr_object.getRate('base',tmp_node);
            % convert from comp type / dcc of increment curve to comp type / dcc of aggregated curve
            tmp_base_rate   = convert_curve_rates(valuation_date,tmp_node,rate_base_origin,comp_type_origin,comp_freq_origin, ...
                dcc_basis_origin, comp_type_target,comp_freq_target,dcc_basis_target);
            tmp_stress_rate = convert_curve_rates(valuation_date,tmp_node,rate_stress_origin,comp_type_origin,comp_freq_origin, ...
                dcc_basis_origin, comp_type_target,comp_freq_target,dcc_basis_target);
            % generate total shock matrix
            tmp_incr_stress_rate = horzcat(tmp_incr_stress_rate,tmp_stress_rate);
            tmp_incr_base_rate = horzcat(tmp_incr_base_rate,tmp_base_rate);
        end
        % add increment to aggr curve stress rates
        % Matlab Adaption
        %if size(aggr_curve_rates_stress,1) ~= size(tmp_incr_stress_rate,1)
        %tmp_incr_stress_rate=repmat(tmp_incr_stress_rate,size(aggr_curve_rates_stress,1),1);
        %end Matlab adaption
        
        % combine all increment rates depending on function
        if ( strcmpi(aggr_curve_function,'sum'))
            aggr_curve_rates_stress = aggr_curve_rates_stress + tmp_incr_stress_rate;
            aggr_curve_rates_base = aggr_curve_rates_base + tmp_incr_base_rate;
        elseif ( strcmpi(aggr_curve_function,'factor'))
            if (length(aggr_curve_increments) > 1)
                error('ERROR: update_mktdata_objects: curve function factor only allows one increment.');
            end
            aggr_curve_rates_stress = aggr_curve_parameter .* tmp_incr_stress_rate;
            aggr_curve_rates_base   = aggr_curve_parameter .* tmp_incr_base_rate;
        elseif ( strcmpi(aggr_curve_function,'product'))
            aggr_curve_rates_stress = aggr_curve_rates_stress .* tmp_incr_stress_rate;
            aggr_curve_rates_base   = aggr_curve_rates_base .* tmp_incr_base_rate;
        elseif ( strcmpi(aggr_curve_function,'divide'))
            aggr_curve_rates_stress = aggr_curve_rates_stress ./ tmp_incr_stress_rate;
            aggr_curve_rates_base   = aggr_curve_rates_base ./ tmp_incr_base_rate;
        end
        % loop through all timesteps_mc
        if ( run_mc == true)
            tmp_aggr_curve_rates_mc = [];
            
            for kk = 1 : 1 : length(timesteps_mc)
                tmp_value_type = timesteps_mc{kk};
                %incr_shock_rates    = tmp_incr_object.getValue(tmp_value_type);
                % loop through all IR Curve nodes and get interpolated shock value from risk factor
                tmp_ir_shock_matrix = [];
                for ii = 1 : 1 : length(aggr_curve_nodes)
                    tmp_node = aggr_curve_nodes(ii);
                    % get interpolated shock vector at node
                    rate_shock_origin    = tmp_incr_object.getRate(tmp_value_type,tmp_node);
                    % convert from comp type / dcc of increment curve to comp type / dcc of aggregated curve
                    tmp_shock_rate = convert_curve_rates(valuation_date,tmp_node,rate_shock_origin,comp_type_origin,comp_freq_origin, ...
                        dcc_basis_origin, comp_type_target,comp_freq_target,dcc_basis_target);
                    % generate total shock matrix
                    tmp_ir_shock_matrix = horzcat(tmp_ir_shock_matrix,tmp_shock_rate);
                end
                %disp("add mc rates to tmp aggre")
                %tmp_value_type
                %tmp_ir_shock_matrix(1:min(5,rows(tmp_ir_shock_matrix)),:)
                tmp_aggr_curve_rates_mc = cat(3,tmp_aggr_curve_rates_mc,tmp_ir_shock_matrix);
                %tmp_aggr_curve_rates_mc(1:min(5,rows(tmp_aggr_curve_rates_mc)),:,:)
            end
            %disp("calc mc rates")
            %aggr_curve_rates_mc(1:min(5,rows(aggr_curve_rates_mc)),:,:)
            % Matlab Adaption
            %if size(aggr_curve_rates_mc,1) ~= size(tmp_aggr_curve_rates_mc,1)
            %tmp_aggr_curve_rates_mc=repmat(tmp_aggr_curve_rates_mc,size(aggr_curve_rates_mc,1),1);
            %end Matlab adaption
            
            % combine all increment rates depending on function
            if ( strcmpi(aggr_curve_function,'sum'))
                aggr_curve_rates_mc =  aggr_curve_rates_mc + tmp_aggr_curve_rates_mc;
            elseif ( strcmpi(aggr_curve_function,'factor'))
                if (length(aggr_curve_increments) > 1)
                    error('ERROR: update_mktdata_objects: curve function factor only allows one increment.');
                end
                aggr_curve_rates_mc =  aggr_curve_parameter .*  tmp_aggr_curve_rates_mc;
            elseif ( strcmpi(aggr_curve_function,'product'))
                aggr_curve_rates_mc = aggr_curve_rates_mc .* tmp_aggr_curve_rates_mc;
            elseif ( strcmpi(aggr_curve_function,'divide'))
                aggr_curve_rates_mc = aggr_curve_rates_mc ./ tmp_aggr_curve_rates_mc;
            else
                error('ERROR: update_mktdata_objects: unknown curve function >>%s<<',any2str(aggr_curve_function));
            end
        end
    else
        fprintf('WARNING: Curve increment not yet found: >>%s<<. Updating marketdata for this id.',tmp_incr_id);
        % call helper function for aggregating increment curve object
        [tmp_incr_object ret_code] = get_sub_object(mktdata_struct, tmp_incr_id);
        if (ret_code == 1)
            fprintf('Updating increment >>%s<<.\n',any2str(tmp_incr_id) );
            tmp_incr_object = aggregate_curve_ojects(tmp_incr_object,valuation_date, ...
                            mktdata_struct,index_struct,riskfactor_struct, ...
                            curve_struct,surface_struct,timesteps_mc,mc,no_stresstests,run_mc);
            % store everything in curve struct
            tmp_store_struct = length(curve_struct) + 1;
            curve_struct( tmp_store_struct ).id      = tmp_incr_object.id;
            curve_struct( tmp_store_struct ).name    = tmp_incr_object.name;
            curve_struct( tmp_store_struct ).object  = tmp_incr_object;

            nestedaggregation = true;
            % and now try to aggregate the initial index again with aggregated subindex...
            [tmp_object curve_struct] = aggregate_curve_ojects(tmp_object,valuation_date, ...
                            mktdata_struct,index_struct,riskfactor_struct, ...
                            curve_struct,surface_struct,timesteps_mc,mc,no_stresstests,run_mc);
        else
            error('WARNING: Curve increment not found in mktdata: >>%s<<.',tmp_incr_id);
        end
    end % retcode 1
    % loop throug all mc timesteps

end

if (nestedaggregation == false)
  % store rates in object
  if ( run_mc == true)
    tmp_object = tmp_object.set('timestep_mc',timesteps_mc);
    tmp_object = tmp_object.set('rates_mc',aggr_curve_rates_mc);
  end
  tmp_object = tmp_object.set('rates_stress',aggr_curve_rates_stress);
  tmp_object = tmp_object.set('rates_base',aggr_curve_rates_base); % restore rates base. Maybe they were unsorted.
  tmp_object = tmp_object.set('nodes',aggr_curve_nodes); % restore nodes. Maybe they were unsorted.
end

end % end function

% ==============================================================================
% Helper function for aggregation of index curves
function [tmp_object index_struct] = aggregate_index_ojects(tmp_object, ...
                                        valuation_date,mktdata_struct,index_struct,riskfactor_struct, ...
                                        curve_struct,surface_struct,timesteps_mc,mc,no_stresstests,run_mc)

nestedaggregation = false;
aggr_index_function   = tmp_object.get('index_function');
aggr_index_parameter  = tmp_object.get('index_parameter');
aggr_index_base    = 1.0;
aggr_index_stress = ones(no_stresstests,1);
aggr_index_mc = ones(mc,1);

% get increments of aggr index
aggr_index_increments = tmp_object.get('increments');
% loop through all increments
for kk = 1 : 1 : length(aggr_index_increments)
    tmp_incr_id = aggr_index_increments{kk};
    % searching for index increment in index_struct
    [tmp_incr_object ret_code] = get_sub_object(index_struct, tmp_incr_id);
        if (ret_code == 0) % search for underlying risk factor
                [tmp_incr_object ret_code] = get_sub_object(riskfactor_struct, tmp_incr_id);
        end
    if (ret_code == 1)  % match found -> market object has underlying index increment -> calculate appropriate scenario values
        tmp_incr_stress_rate     = tmp_incr_object.getValue('stress');
        tmp_incr_base_rate       = tmp_incr_object.getValue('base');

        % combine all increment rates depending on function
        if ( strcmpi(aggr_index_function,'sum'))
            if ( kk == 1)   % first increment: aggr_index_mc = zeros(mc,1);
                aggr_index_stress = zeros(no_stresstests,1);
                aggr_index_base = 0.0;
            end
            aggr_index_stress = aggr_index_stress + tmp_incr_stress_rate;
            aggr_index_base = aggr_index_base + tmp_incr_base_rate;
        elseif ( strcmpi(aggr_index_function,'factor'))
            if (length(aggr_index_increments) > 1)
                error('ERROR: update_mktdata_objects: curve function factor only allows one increment.\n');
            end
            aggr_index_stress = aggr_index_parameter .* tmp_incr_stress_rate;
            aggr_index_base   = aggr_index_parameter .* tmp_incr_base_rate;
        elseif ( strcmpi(aggr_index_function,'product'))
            aggr_index_stress = aggr_index_stress .* tmp_incr_stress_rate;
            aggr_index_base   = aggr_index_base .* tmp_incr_base_rate;
        elseif ( strcmpi(aggr_index_function,'divide'))
            aggr_index_stress = aggr_index_stress ./ tmp_incr_stress_rate;
            aggr_index_base   = aggr_index_base ./ tmp_incr_base_rate;
        else
            error('ERROR: update_mktdata_objects: unknown index function >>%s<<\n',any2str(aggr_index_function));
        end

        % loop through all timesteps_mc
        if ( run_mc == true)
            tmp_aggr_index_rates_mc = [];
            % get increment scenario shock values
            for jj = 1 : 1 : length(timesteps_mc)
                tmp_value_type = timesteps_mc{jj};
                tmp_aggr_index_col = tmp_incr_object.getValue(tmp_value_type);
                tmp_aggr_index_rates_mc = cat(2,tmp_aggr_index_rates_mc,tmp_aggr_index_col);
            end
            % combine all increment rates depending on function
            if ( strcmpi(aggr_index_function,'sum'))
                if ( kk == 1)   % first increment: aggr_index_mc = zeros(mc,1);
                    aggr_index_mc = zeros(mc,1);
                end
                aggr_index_mc =  aggr_index_mc + tmp_aggr_index_rates_mc;
            elseif ( strcmpi(aggr_index_function,'factor'))
                if (length(aggr_index_increments) > 1)
                    error('ERROR: update_mktdata_objects: index function factor only allows one increment.\n');
                end
                aggr_index_mc =  aggr_index_parameter .*  tmp_aggr_index_rates_mc;
            elseif ( strcmpi(aggr_index_function,'product'))
                aggr_index_mc = aggr_index_mc .* tmp_aggr_index_rates_mc;
            elseif ( strcmpi(aggr_index_function,'divide'))
                aggr_index_mc = aggr_index_mc ./ tmp_aggr_index_rates_mc;
            else
                error('ERROR: update_mktdata_objects: unknown index function >>%s<<\n',any2str(aggr_index_function));
            end

        end
    else
        fprintf('WARNING: Index increment not yet found: >>%s<<. Updating index data for this id.\n',tmp_incr_id);
        % call helper function for aggregating increment curve object
        [tmp_incr_object ret_code] = get_sub_object(mktdata_struct, tmp_incr_id);
        if (ret_code == 1)
            fprintf('Updating increment >>%s<<.\n',any2str(tmp_incr_id) );
            tmp_incr_object = aggregate_index_ojects(tmp_incr_object,valuation_date, ...
                            mktdata_struct,index_struct,riskfactor_struct, ...
                            curve_struct,surface_struct,timesteps_mc,mc,no_stresstests,run_mc);
            % store everything in curve struct
            tmp_store_struct = length(index_struct) + 1;
            index_struct( tmp_store_struct ).id      = tmp_incr_object.id;
            index_struct( tmp_store_struct ).name    = tmp_incr_object.name;
            index_struct( tmp_store_struct ).object  = tmp_incr_object;

            % and now try to aggregate the initial index again with aggregated subindex...
            [tmp_object index_struct] = aggregate_index_ojects(tmp_object,valuation_date, ...
                                       mktdata_struct,index_struct,riskfactor_struct, ...
                                       index_struct,surface_struct,timesteps_mc,mc,no_stresstests,run_mc);
            nestedaggregation = true;
        else
            error('WARNING: Index increment not found in mktdata struct: >>%s<<.\n',tmp_incr_id);
        end
    end % retcode 1

end

if (nestedaggregation == false)
    % store base and stress values
    tmp_object = tmp_object.set('scenario_stress',aggr_index_stress);
    tmp_object = tmp_object.set('value_base',aggr_index_base);
    tmp_object = tmp_object.set('timestep_mc',timesteps_mc);
    tmp_object = tmp_object.set('scenario_mc',aggr_index_mc);
end
end
% ##############################################################################
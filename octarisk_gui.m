%# Copyright (C) 2017 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Script File} {} octarisk_gui
%#
%# Octarisk's graphical user interface.
%# Thanks to Andreas Weber <andy@josoansi.de> for his excellent GUI example.
%# 
%# See www.octarisk.com for further information.
%#
%# @end deftypefn

% ##############################################################################

% Specify path to parameter.csv (Recommendation for first try: /path/to/octarisk/ and parameter.csv)
if (isunix)
    input_path = '/Users/schinzilord/Documents/Programmierung/octarisk/testing_folder';
    parameter_file = 'parameter.csv';
else
    input_path = '/Users/schinzilord/Documents/Programmierung/octarisk/testing_folder';
    parameter_file = 'parameter.csv';
end


% All valuation specific input parameters are set in function file octarisk.m.

% ##############################################################################

close all
clear h

graphics_toolkit qt

% ##############################################################################
% set up main window
f = figure();
set (gcf, "color", get(0, "defaultuicontrolbackgroundcolor"))
set (gcf, "numbertitle", "off", "name", "Octarisk GUI")
set (gcf, "menubar","none", "position",[100,200,1400,800],"units","pixels")
h.ax_instrument = axes ("position", [0.04 0.05 0.35 0.30],"units", "normalized","title","PnL Distribution");
h.ax_portfolio = axes ("position", [0.53 0.05 0.35 0.30],"units", "normalized","title","PnL Distribution");

% print loading screen
h.calculation_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Waiting for session generation...",
                                "horizontalalignment", "left",
                                "position", [0.38 0.75 0.40 0.05]);
                                
clear instrument_struct;
clear curve_struct;
clear index_struct;
clear surface_struct;
clear para_object;
clear riskfactor_struct;
clear portfolio_struct;
warning('off','Octave:classdef-to-struct');

% Declare global object data
global instrument_struct = struct();
global curve_struct = struct();
global index_struct = struct();
global surface_struct = struct();
global para_object = struct();
global matrix_struct = struct();
global riskfactor_struct = struct();
global portfolio_struct = struct();
global stresstest_struct = struct();

global valuation_date;

% ##############################################################################
function nochange(obj)
    h = guidata (obj);
    switch (gcbo)
        case {h.curve_attribute_value}
            set (h.curve_attribute_value, "string", "Change rates in mktdata.csv");
        case {h.curve_attribute_nodes}
            set (h.curve_attribute_nodes, "string", "Change nodes in mktdata.csv");
    end
end

% functions for updating window objects
function update_window (obj, init = false)

  ## gcbo holds the handle of the control
  
  h = guidata (obj);
  global instrument_struct;
  global portfolio_struct;
  global stresstest_struct;
  global curve_struct;

  switch (gcbo)
    case {h.object_attributes_popup}
        property = get (gcbo, "string"){get (h.object_attributes_popup, "value")};
        tmp_instr_id = get (h.instrument_struct_popup, "string"){get (h.instrument_struct_popup, "value")};
        tmp_obj = get_sub_object(instrument_struct,tmp_instr_id);
        v = any2str(tmp_obj.get(property));
        set (h.object_attributes_value, "string", v);
    case {h.instrument_struct_popup}
        calculate_value(obj);
        tmp_instr_id = get (gcbo, "string"){get (h.instrument_struct_popup, "value")};
        tmp_obj = get_sub_object(instrument_struct,tmp_instr_id);
        tmp_key = any2str(tmp_obj.get(fieldnames(tmp_obj){1}));
        set (h.object_attributes_popup, "string", fieldnames(tmp_obj));
        set (h.object_attributes_value, "string", tmp_key);
        % update instrument value
        set (h.instrument_value_value, "string", sprintf ("%.8f", tmp_obj.getValue('base')));
    case {h.portfolio_struct_popup}
        % update position ids and quantities
        tmp_port_id = get (gcbo, "string"){get (h.portfolio_struct_popup, "value")};
        tmp_port_struct = get_sub_struct(portfolio_struct,tmp_port_id);
        set (h.position_attributes_popup, "string", {tmp_port_struct.position.id});
        tmp_quantity = any2str(tmp_port_struct.position(1).quantity);
        set (h.position_attributes_value, "string", tmp_quantity);
        aggregate_portfolio(obj);
    case {h.position_attributes_popup}
        tmp_port_id = get (h.portfolio_struct_popup, "string"){get (h.portfolio_struct_popup, "value")};
        tmp_port_struct = get_sub_struct(portfolio_struct,tmp_port_id);
        tmp_pos_id = get (h.position_attributes_popup, "string"){get (h.position_attributes_popup, "value")};
        tmp_quantity = any2str(get_sub_struct(tmp_port_struct.position,tmp_pos_id).quantity);
        set (h.position_attributes_value, "string", tmp_quantity);
        aggregate_portfolio(obj);
    case {h.instrument_stresstest_popup}
        tmp_instr_id = get (h.instrument_struct_popup, "string"){get (h.instrument_struct_popup, "value")};
        tmp_obj = get_sub_object(instrument_struct,tmp_instr_id);
        stress_name = get (h.instrument_stresstest_popup, "string"){get (h.instrument_stresstest_popup, "value")};
        a = {stresstest_struct.name};
        b = 1:1:length(a);
        c = strcmpi(a, stress_name);
        idx_stress = b * c';
        instr_stress_values = tmp_obj.getValue('stress');
        if ( length(instr_stress_values) > 1)
            tmp_instr_stress_value = instr_stress_values(idx_stress) - tmp_obj.getValue('base');
        else
            tmp_instr_stress_value = instr_stress_values(1) - tmp_obj.getValue('base');
        end
        set (h.instrument_stressvalue_value, "string", sprintf ("%.8f", tmp_instr_stress_value));
    case {h.curve_id_menu}  % update curve attribute value
        tmp_curve_id = get (h.curve_id_menu, "string"){get (h.curve_id_menu, "value")};
        tmp_curve_prop = get (h.curve_property_menu, "string"){get (h.curve_property_menu, "value")};
        tmp_obj = get_sub_object(curve_struct,tmp_curve_id);
        nodes = any2str(tmp_obj.get('nodes'));
        rates = tmp_obj.get(tmp_curve_prop);
        if ( strcmpi(tmp_curve_prop,'rates_mc'))
            port_scen_number = str2num(get (h.portfolio_mc_number_value, "string"));
            rates = rates(port_scen_number,:);
        elseif ( strcmpi(tmp_curve_prop,'rates_stress'))
            % get stress value
            stress_name = get (h.portfolio_stresstest_popup, "string"){get (h.portfolio_stresstest_popup, "value")};
            a = {stresstest_struct.name};
            b = 1:1:length(a);
            c = strcmpi(a, stress_name);
            idx_stress = b * c';
            rates = rates(idx_stress,:);
        end
        % print curves
        set (h.curve_attribute_nodes, "string", nodes);
        set (h.curve_attribute_value, "string", any2str(rates));
    case {h.curve_property_menu}    % update curve attribute value
        tmp_curve_id = get (h.curve_id_menu, "string"){get (h.curve_id_menu, "value")};
        tmp_curve_prop = get (h.curve_property_menu, "string"){get (h.curve_property_menu, "value")};
        tmp_obj = get_sub_object(curve_struct,tmp_curve_id);
        nodes = any2str(tmp_obj.get('nodes'));
        rates = tmp_obj.get(tmp_curve_prop);
        if ( strcmpi(tmp_curve_prop,'rates_mc'))
            port_scen_number = str2num(get (h.portfolio_mc_number_value, "string"));
            rates = rates(port_scen_number,:);
        elseif ( strcmpi(tmp_curve_prop,'rates_stress'))
            % get stress value
            stress_name = get (h.portfolio_stresstest_popup, "string"){get (h.portfolio_stresstest_popup, "value")};
            a = {stresstest_struct.name};
            b = 1:1:length(a);
            c = strcmpi(a, stress_name);
            idx_stress = b * c';
            rates = rates(idx_stress,:);
        end
        % print curves
        set (h.curve_attribute_nodes, "string", nodes);
        set (h.curve_attribute_value, "string", any2str(rates));
  end

end

function obj = plot_curve(obj)
    h = guidata (obj);
    global curve_struct;
    global stresstest_struct;

  switch (gcbo)
    case {h.plot_curve_pushbutton}  % update curve attribute value
        tmp_curve_id = get (h.curve_id_menu, "string"){get (h.curve_id_menu, "value")};
        tmp_curve_prop = get (h.curve_property_menu, "string"){get (h.curve_property_menu, "value")};
        tmp_obj = get_sub_object(curve_struct,tmp_curve_id);
        nodes = any2str(tmp_obj.get('nodes'));
        rates_base = tmp_obj.get('rates_base');
        rates = tmp_obj.get(tmp_curve_prop);
        port_scen_number = 1;
        idx_stress = 1;
        if ( strcmpi(tmp_curve_prop,'rates_mc'))
            rates_mc = tmp_obj.get('rates_mc');
            port_scen_number = str2num(get (h.portfolio_mc_number_value, "string"));
            rates = rates(port_scen_number,:);
        elseif ( strcmpi(tmp_curve_prop,'rates_stress'))
            % get stress value
            stress_name = get (h.portfolio_stresstest_popup, "string"){get (h.portfolio_stresstest_popup, "value")};
            a = {stresstest_struct.name};
            b = 1:1:length(a);
            c = strcmpi(a, stress_name);
            idx_stress = b * c';
            rates = rates(idx_stress,:);
        else
            rates = rates_base;
        end
        % plot curves
        f2 = figure();
        set (gcf, "numbertitle", "off", "name", "Octarisk Curve Structure")
        %h.ax_curve_rates = axes ("title",any2str(tmp_obj.id));
        gca();
        h.plot = plot (tmp_obj.get('nodes'),rates_base,'color','blue',"linewidth",1,'marker','x');
        hold on;
        h.plot = plot (tmp_obj.get('nodes'),rates,'color','red',"linewidth",1,'marker','x');
        hold off;
        grid on;
        title(sprintf ("Curve ID %s", strrep(tmp_obj.id,'_','\_')), "fontsize",12);
        xlabel('Nodes (in days)', "fontsize",11);
        ylabel('Rates', "fontsize",11);
        if ( strcmpi(tmp_curve_prop,'rates_mc'))
            legend('Base Scenario Rates',strcat('VaR Scenario(', any2str(port_scen_number) ,') Rates'));
        elseif ( strcmpi(tmp_curve_prop,'rates_stress'))
            legend('Base Scenario Rates',strcat('Stress Scenario(', any2str(idx_stress) ,') Rates'));
        else
            legend('Base Scenario Rates');
        end
        guidata (obj, h);
  end

end

% ################### Update Plot ##############################################
function obj = update_plot(obj,inst_id,var)
    h = guidata (obj);
    clear xx;
    clear yy;
    clear yy_sorted;
    global instrument_struct;
    global curve_struct;
    global index_struct;
    global surface_struct;
    global para_object;
    global matrix_struct;
    global riskfactor_struct;
    global valuation_date;
    % get instrument data
    tmp_obj = get_sub_object(instrument_struct,inst_id);
    yy = tmp_obj.getValue(para_object.mc_timestep) - tmp_obj.getValue('base');
    yy_sorted = sort(yy);
    xx = 1:1:length(yy);
    %ax_instrument = gca (h.ax_instrument);
    axes(h.ax_instrument);
    %set (h.ax_instrument, "position", [0.03 0.15 0.35 0.35]);
    gca();
    h.plot = plot (xx, yy_sorted, "b", "linewidth",2);
    hold on;
    h.plot = plot ([1,para_object.mc],[var,var], "r", "linewidth",1);
    hold on;
    h.plot = plot ([1,1],[var,var], "b", "linewidth",1);
    hold off;
    grid on;
    var_string = sprintf ("VaR: %.2f %s", var,tmp_obj.currency);
    text(0.025*para_object.mc,(0.8*var),var_string); 
    text(0.025*para_object.mc,(1.2*var),strcat(num2str(round((var*1000+eps)/(tmp_obj.getValue('base')+eps))/10),' %'));
    axis ([0 length(xx) min(yy_sorted)-eps -var+eps]);
    title("Instrument PnL Distribution", "fontsize",12);
    xlabel('MonteCarlo Scenario', "fontsize",11);
    ylabel(strcat('Profit and Loss (',tmp_obj.currency,')'), "fontsize",11);
    set (h.plot, "ydata", yy_sorted);
    guidata (obj, h);
    
    

end

function obj = update_plot_aggregation(obj,scenario_values,var,fund_currency,base_value)
    h = guidata (obj);
    clear xx;
    clear yy;
    clear yy_sorted;
    global instrument_struct;
    global curve_struct;
    global index_struct;
    global surface_struct;
    global para_object;
    global matrix_struct;
    global riskfactor_struct;
    global valuation_date;
    global portfolio_struct;
    % get instrument data
    xx = 1:1:length(scenario_values);
    axes(h.ax_portfolio);
    gca();
    h.plot = plot (xx, scenario_values, "b", "linewidth",2);
    hold on;
    h.plot = plot ([1,para_object.mc],[var,var], "r", "linewidth",1);
    hold on;
    h.plot = plot ([1,1],[var,var], "b", "linewidth",1);
    hold off;
    grid on;
    var_string = sprintf ("VaR: %d %s", round(var),fund_currency);
    text(0.025*para_object.mc,(0.8*var),var_string);
    text(0.025*para_object.mc,(1.2*var),strcat(num2str(round(var*1000/base_value)/10),' %')); 
    title("Portfolio PnL Distribution", "fontsize",12);
    axis ([0 length(xx) min(scenario_values) -var]);
    xlabel('MonteCarlo Scenario', "fontsize",11);
    ylabel(strcat('Profit and Loss (',fund_currency,')'), "fontsize",11);
    set (h.plot, "ydata", scenario_values);
    guidata (obj, h);

end

% ################### Aggregate Positions ######################################
function aggregate_portfolio(obj)
    global instrument_struct;
    global portfolio_struct;
    global index_struct;
    global para_object;
    global stresstest_struct;
    h = guidata (obj);
    tmp_port_id = get (h.portfolio_struct_popup, "string"){get (h.portfolio_struct_popup, "value")};
    tmp_port_struct = get_sub_struct(portfolio_struct,tmp_port_id);
    tmp_pos_id = get (h.position_attributes_popup, "string"){get (h.position_attributes_popup, "value")};
    
    
    tmp_quantity = any2str(get_sub_struct(tmp_port_struct.position,tmp_pos_id).quantity);
    
    % update position attributes
    switch (gcbo)
        case {h.position_attributes_value}
            try
                pos_quantity = str2num(get (gcbo, "string"));
            catch
                fprintf('Quantity not numeric!\n');
            end
            % update position quantity in struct
            % get portfolio struct index
            a = {portfolio_struct.id};
            b = 1:1:length(a);
            c = strcmpi(a, tmp_port_id);
            idx_port = b * c';
            % get position struct index
            a = {portfolio_struct(idx_port).position.id};
            b = 1:1:length(a);
            c = strcmpi(a, tmp_pos_id);
            idx_pos = b * c';
            portfolio_struct(idx_port).position(idx_pos).quantity = pos_quantity;
        case {h.add_position_pushbutton}
            % add instrument to selected portfolio (with quantity = 0.0)
            tmp_instr_id = get (h.instrument_struct_popup, "string"){get (h.instrument_struct_popup, "value")};
            if ( sum( strcmpi({tmp_port_struct.position.id},tmp_instr_id)) == 0)
                % get portfolio struct index
                a = {portfolio_struct.id};
                b = 1:1:length(a);
                c = strcmpi(a, tmp_port_id);
                idx_port = b * c';
                new_idx = length( {portfolio_struct(idx_port).position.id}) + 1;
                portfolio_struct(idx_port).position( new_idx ).id = tmp_instr_id;
                portfolio_struct(idx_port).position( new_idx ).quantity = 0;
                set (h.position_attributes_popup,"string", {portfolio_struct(idx_port).position.id});
                set (h.position_attributes_popup, "value",new_idx);
                set (h.position_attributes_value, "string", "0");
                tmp_pos_id = tmp_instr_id;
                tmp_quantity = 0.0;
            end
    end
    % get new port and pos struct values
    tmp_port_struct = get_sub_struct(portfolio_struct,tmp_port_id);
    tmp_pos_struct = tmp_port_struct.position; %get_sub_struct(tmp_port_struct.position,tmp_port_id);
    fund_currency = tmp_port_struct.currency;
    
    % aggregate positions in base scenario
    position_failed_cell = {};
    confi_scenario = max(round((1 - para_object.quantile) * para_object.mc),1);
    [tmp_pos_struct position_failed_cell base_value] = aggregate_positions(tmp_pos_struct, ...
            position_failed_cell,instrument_struct,index_struct, ...
            para_object.mc,'base',fund_currency,tmp_port_id,false);
    tmp_pos_struct_selected = get_sub_struct(tmp_pos_struct,tmp_pos_id);
    tmp_pos_selected_base = tmp_pos_struct_selected.basevalue;  
    [tmp_pos_struct position_failed_cell scenario_values] = aggregate_positions(tmp_pos_struct, ...
            position_failed_cell,instrument_struct,index_struct, ...
            para_object.mc,para_object.mc_timestep,fund_currency,tmp_port_id,false);
    [yy_sorted idx] = sort(scenario_values - base_value);
    var = yy_sorted(confi_scenario);
    
    % get stress results
    [tmp_pos_struct position_failed_cell stress_values] = aggregate_positions(tmp_pos_struct, ...
            position_failed_cell,instrument_struct,index_struct, ...
            para_object.no_stresstests,'stress',fund_currency,tmp_port_id,false);
            
    % set var and base value
    set (h.position_var_value, "string", sprintf ("%.4f", var));
    set (h.position_value_value, "string", sprintf ("%.4f", base_value));
    set (h.position_var_value_pct, "string", sprintf ("%.4f", 100 * ((var ./ base_value))));
    % set portfolio base and var currency
    set (h.position_currency_var_label, "string", fund_currency);
    set (h.position_currency_base_label, "string", fund_currency);
    set (h.position_currency_decomp_label, "string", fund_currency);
    set (h.portfolio_stressvalue_currency, "string", fund_currency);
    
    % calculate selected position decomp var:
    tmp_pos_struct_selected = get_sub_struct(tmp_pos_struct,tmp_pos_id);
    tmp_pos_scen_values = tmp_pos_struct_selected.mc_scenarios.octamat(:,1);
    scen_number_decomp = idx(confi_scenario);
    tmp_quantity = tmp_pos_struct_selected.quantity;
    tmp_pos_decomp_var     = -(tmp_pos_scen_values(scen_number_decomp) * tmp_quantity * sign(tmp_quantity) - tmp_pos_selected_base);
    set (h.position_decomp_value, "string", sprintf ("%.4f", -tmp_pos_decomp_var));
    % set MC VaR scenario number
    set (h.portfolio_mc_number_value, "string", sprintf ("%d", scen_number_decomp));
    
    % get portfolio stress value
    stress_name = get (h.portfolio_stresstest_popup, "string"){get (h.portfolio_stresstest_popup, "value")};
    a = {stresstest_struct.name};
    b = 1:1:length(a);
    c = strcmpi(a, stress_name);
    idx_stress = b * c';
    tmp_port_stress_value = stress_values(idx_stress) - base_value;
    set (h.portfolio_stressvalue_value, "string", sprintf ("%.4f", tmp_port_stress_value));
    
    % update plot
    obj = update_plot_aggregation(obj,yy_sorted,var,fund_currency,base_value);
    
    
end

% ################### Calculate Instrument Value ###############################
function calculate_value(obj)
    ## gcbo holds the handle of the control
    h = guidata (obj);
    global instrument_struct;
    global curve_struct;
    global index_struct;
    global surface_struct;
    global para_object;
    global matrix_struct;
    global riskfactor_struct;
    global valuation_date;
    global stresstest_struct;
      
    tmp_instr_id = get (h.instrument_struct_popup, "string"){get (h.instrument_struct_popup, "value")};
    tmp_obj = get_sub_object(instrument_struct,tmp_instr_id);
    
    % update instrument attributes
    switch (gcbo)
        case {h.object_attributes_value}
            property = get (h.object_attributes_popup, "string"){get (h.object_attributes_popup, "value")};
            value = get (gcbo, "string");
            % get class of property and convert string if necessary
            if strcmpi(class(tmp_obj.get(property)),'double')
                value = str2num(value);
            end
            tmp_obj = tmp_obj.set(property,value);  
    end 
    % delete MC scenarios
    tmp_obj = tmp_obj.del_scen_data;
    
    % recalculate instrument
    para_object.scen_number = 1;
    tmp_obj = tmp_obj.valuate(valuation_date, 'base', ...
                            instrument_struct, surface_struct, ...
                            matrix_struct, curve_struct, index_struct, ...
                            riskfactor_struct, para_object);
    
    % recalc in MC
    para_object.scen_number = para_object.mc;
    tmp_obj = tmp_obj.valuate(valuation_date, para_object.mc_timestep, ...
                            instrument_struct, surface_struct, ...
                            matrix_struct, curve_struct, index_struct, ...
                            riskfactor_struct, para_object);
    para_object.scen_number = para_object.no_stresstests;
    % recalculate instrument
    tmp_obj = tmp_obj.valuate(valuation_date, 'stress', ...
                            instrument_struct, surface_struct, ...
                            matrix_struct, curve_struct, index_struct, ...
                            riskfactor_struct, para_object);
                            
    % print instrument value
    v = sprintf ("%.8f", tmp_obj.getValue('base'));
    set (h.instrument_value_value, "string", v);
    yy = tmp_obj.getValue(para_object.mc_timestep) - tmp_obj.getValue('base');
    yy_sorted = sort(yy);
    var = yy_sorted(max(round((1 - para_object.quantile) * para_object.mc),1));
    set (h.instrument_var_value, "string", sprintf ("%.8f", var));
    set (h.instrument_var_value_pct, "string", sprintf ("%.4f", 100 * (var + 1E-16) ./ (tmp_obj.getValue('base') + 1E-16)));

    set (h.instrument_value_currency, "string", tmp_obj.currency);
    set (h.instrument_var_currency, "string", tmp_obj.currency);
    set (h.instrument_stressvalue_currency, "string", tmp_obj.currency);
    
    % get stress value
    stress_name = get (h.instrument_stresstest_popup, "string"){get (h.instrument_stresstest_popup, "value")};
    a = {stresstest_struct.name};
    b = 1:1:length(a);
    c = strcmpi(a, stress_name);
    idx_stress = b * c';
    instr_stress_values = tmp_obj.getValue('stress');
    if ( length(instr_stress_values) > 1)
        tmp_instr_stress_value = instr_stress_values(idx_stress) - tmp_obj.getValue('base');
    else
        tmp_instr_stress_value = instr_stress_values(1) - tmp_obj.getValue('base');
    end
    set (h.instrument_stressvalue_value, "string", sprintf ("%.8f", tmp_instr_stress_value));
    
    % overwrite object in instrument_struct
    a = {instrument_struct.id};
    b = 1:1:length(a);
    c = strcmpi(a, tmp_instr_id);
    idx = b * c';
    instrument_struct(idx).id = tmp_obj.id;
    instrument_struct(idx).object = tmp_obj;
    
    % update plot
    obj = update_plot(obj,tmp_instr_id,var);
    
    % aggregate portfolio
    aggregate_portfolio(obj);
end

% ##############################################################################

% call octarisk in batch mode to retrieve valuated instruments
[instrument_struct, curve_struct, index_struct, surface_struct, para_object, ...
matrix_struct, riskfactor_struct, portfolio_struct, stresstest_struct] = octarisk(input_path,parameter_file);
valuation_date = para_object.valuation_date;


% ##############################################################################

set (h.calculation_label, "string", "");

                                
% ###################  Portfolio Section  #####################################
h.portfolio_section_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Portfolio Section",
                                "FontSize", 13,
                                %"horizontalalignment", "left",
                                "position", [0.51 0.95 0.40 0.05]);
h.portfolio_struct_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Available Portfolios:",
                                "horizontalalignment", "left",
                                "position", [0.51 0.90 0.18 0.03]);
                                
h.portfolio_struct_popup = uicontrol ("style", "popupmenu",
                               "units", "normalized",
                               "string", {portfolio_struct.id},
                               "backgroundcolor", [1 1 1],
                               "callback", @update_window,
                               "position", [0.68 0.90 0.20 0.03]);

h.position_attributes_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Position ID:",
                                "horizontalalignment", "left",
                                "position", [0.51 0.85 0.16 0.03]);
h.position_attributes_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Position Size:",
                                %"horizontalalignment", "left",
                                "position", [0.68 0.85 0.18 0.03]);
h.position_attributes_popup = uicontrol ("style", "popupmenu",
                               "units", "normalized",
                               "backgroundcolor", [1 1 1],
                               "string", {portfolio_struct(1).position.id},
                               "callback", @update_window,
                               "position", [0.51 0.815 0.16 0.03]);

h.position_attributes_value = uicontrol ("style", "edit",
                               "units", "normalized",
                               "string", any2str(portfolio_struct(1).position(1).quantity),
                               "callback", @aggregate_portfolio,
                               "backgroundcolor", [1 1 1],
                               "position", [0.68 0.815 0.20 0.03]);

h.position_value_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Portfolio Base Value:",
                                "horizontalalignment", "left",
                                "position", [0.51 0.76 0.18 0.03]);
                                
h.position_value_value = uicontrol ("style", "edit",
                                "units", "normalized",
                                "backgroundcolor", [1 1 1],
                                "string", "Press Aggregate...",
                                %"horizontalalignment", "left",
                                "position", [0.68 0.76 0.20 0.03]);

h.position_currency_var_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", portfolio_struct(1).currency,
                                "horizontalalignment", "left",
                                "position", [0.89 0.76 0.04 0.03]);
                                
h.position_var_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", strcat("Value at Risk (", para_object.mc_timestep ,",", any2str(para_object.quantile),"):"),
                                "horizontalalignment", "left",
                                "position", [0.51 0.71 0.18 0.03]);
h.position_var_value = uicontrol ("style", "edit",
                                "units", "normalized",
                                "backgroundcolor", [1 1 1],
                                "string", "Press Aggregate...",
                                %"horizontalalignment", "left",
                                "position", [0.68 0.71 0.20 0.03]);
                                
h.position_currency_base_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", portfolio_struct(1).currency,
                                "horizontalalignment", "left",
                                "position", [0.89 0.71 0.04 0.03]);
%%
%   Portfolio var results
h.position_var_label_pct = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", strcat("Value at Risk (", para_object.mc_timestep ,",", any2str(para_object.quantile),"):"),
                                "horizontalalignment", "left",
                                "position", [0.51 0.66 0.18 0.03]);
h.position_var_value_pct = uicontrol ("style", "edit",
                                "units", "normalized",
                                "backgroundcolor", [1 1 1],
                                "string", "Press Aggregate...",
                                %"horizontalalignment", "left",
                                "position", [0.68 0.66 0.20 0.03]);

h.position_var_label_pct_unit = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "%",
                                "horizontalalignment", "left",
                                "position", [0.89 0.66 0.04 0.03]);
%   Portfolio decomp var results                                
h.position_decomp_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Position Decomp VaR:",
                                "horizontalalignment", "left",
                                "position", [0.51 0.61 0.18 0.03]);
                                
h.position_decomp_value = uicontrol ("style", "edit",
                                "units", "normalized",
                                "backgroundcolor", [1 1 1],
                                "string", "Press Aggregate...",
                                %"horizontalalignment", "left",
                                "position", [0.68 0.61 0.20 0.03]);

h.position_currency_decomp_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", portfolio_struct(1).currency,
                                "horizontalalignment", "left",
                                "position", [0.89 0.61 0.04 0.03]);
% MC scenario number
h.portfolio_mc_number_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "MC VaR portfolio scenario:",
                                "horizontalalignment", "left",
                                "position", [0.51 0.56 0.18 0.03]);
                                
h.portfolio_mc_number_value = uicontrol ("style", "text",
                                "units", "normalized",
                                %"backgroundcolor", [1 1 1],
                                "string", "Press Aggregate...",
                                %"horizontalalignment", "left",
                                "position", [0.68 0.56 0.20 0.03]);                             
                                
                                %   Portfolio stress test results                           
h.portfolio_stresstest_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Stresstest Name:",
                                "horizontalalignment", "left",
                                "position", [0.51 0.51 0.16 0.03]);
h.portfolio_stressvalue_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Stress Profit or Loss:",
                                %"horizontalalignment", "left",
                                "position", [0.68 0.51 0.18 0.03]);
h.portfolio_stresstest_popup = uicontrol ("style", "popupmenu",
                               "units", "normalized",
                               "backgroundcolor", [1 1 1],
                               "string", {stresstest_struct.name},
                               "callback", @aggregate_portfolio,
                               "position", [0.51 0.475 0.16 0.03]);

h.portfolio_stressvalue_value = uicontrol ("style", "edit",
                               "units", "normalized",
                               "string", "Press Aggregate...",
                               "callback", @aggregate_portfolio,
                               "backgroundcolor", [1 1 1],
                               "position", [0.68 0.475 0.20 0.03]);
                               
h.portfolio_stressvalue_currency = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", portfolio_struct(1).currency,
                                "horizontalalignment", "left",
                                "position", [0.89 0.475 0.04 0.03]);
                                
% ###################  Instrument Section  #####################################
h.instrument_section_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Instrument Section",
                                "FontSize", 13,
                                %"horizontalalignment", "left",
                                "position", [0.01 0.95 0.40 0.05]);
h.instrument_struct_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Available Instruments:",
                                "horizontalalignment", "left",
                                "position", [0.01 0.90 0.18 0.03]);
                                
h.instrument_struct_popup = uicontrol ("style", "popupmenu",
                               "units", "normalized",
                               "string", {instrument_struct.id},
                               "backgroundcolor", [1 1 1],
                               "callback", @update_window,
                               "position", [0.18 0.90 0.20 0.03]);
                               
%% Instrument Properties:
            
h.object_attributes_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Instrument Attribute:",
                                "horizontalalignment", "left",
                                "position", [0.01 0.85 0.16 0.03]);
h.object_attributes_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Attribute Value:",
                                %"horizontalalignment", "left",
                                "position", [0.18 0.85 0.18 0.03]);
h.object_attributes_popup = uicontrol ("style", "popupmenu",
                               "units", "normalized",
                               "backgroundcolor", [1 1 1],
                               "string", fieldnames(instrument_struct(1).object),
                               "callback", @update_window,
                               "position", [0.01 0.815 0.16 0.03]);

h.object_attributes_value = uicontrol ("style", "edit",
                               "units", "normalized",
                               "string", any2str(getfield(instrument_struct(1).object,fieldnames(instrument_struct(1).object){1})),
                               "callback", @calculate_value,
                               "backgroundcolor", [1 1 1],
                               "position", [0.18 0.815 0.20 0.03]);

                               
h.instrument_value_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Base Value:",
                                "horizontalalignment", "left",
                                "position", [0.01 0.76 0.18 0.03]);
                                
h.instrument_value_value = uicontrol ("style", "edit",
                                "units", "normalized",
                                "backgroundcolor", [1 1 1],
                                "string", "Press Recalc...",
                                %"horizontalalignment", "left",
                                "position", [0.18 0.76 0.20 0.03]);

h.instrument_value_currency = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", instrument_struct(1).object.currency,
                                "horizontalalignment", "left",
                                "position", [0.39 0.76 0.04 0.03]);
                                
h.instrument_var_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", strcat("Value at Risk (", para_object.mc_timestep ,",", any2str(para_object.quantile),"):"),
                                "horizontalalignment", "left",
                                "position", [0.01 0.71 0.18 0.03]);
                                
h.instrument_var_value = uicontrol ("style", "edit",
                                "units", "normalized",
                                "backgroundcolor", [1 1 1],
                                "string", "Press Recalc...",
                                %"horizontalalignment", "left",
                                "position", [0.18 0.71 0.20 0.03]);

h.instrument_var_currency = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", instrument_struct(1).object.currency,
                                "horizontalalignment", "left",
                                "position", [0.39 0.71 0.04 0.03]);

h.instrument_var_label_pct = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", strcat("Value at Risk (", para_object.mc_timestep ,",", any2str(para_object.quantile),"):"),
                                "horizontalalignment", "left",
                                "position", [0.01 0.66 0.18 0.03]);
                                
h.instrument_var_value_pct = uicontrol ("style", "edit",
                                "units", "normalized",
                                "backgroundcolor", [1 1 1],
                                "string", "Press Recalc...",
                                %"horizontalalignment", "left",
                                "position", [0.18 0.66 0.20 0.03]);

h.instrument_var_unit_pct = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "%",
                                "horizontalalignment", "left",
                                "position", [0.39 0.66 0.04 0.03]);                            
%   Instrument stress test results                          
h.instrument_stresstest_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Stresstest Name:",
                                "horizontalalignment", "left",
                                "position", [0.01 0.61 0.16 0.03]);
h.instrument_stressvalue_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Stress Profit or Loss:",
                                %"horizontalalignment", "left",
                                "position", [0.18 0.61 0.18 0.03]);
h.instrument_stresstest_popup = uicontrol ("style", "popupmenu",
                               "units", "normalized",
                               "backgroundcolor", [1 1 1],
                               "string", {stresstest_struct.name},
                               "callback", @update_window,
                               "position", [0.01 0.575 0.16 0.03]);

h.instrument_stressvalue_value = uicontrol ("style", "edit",
                               "units", "normalized",
                               "string", "Press Recalc...",
                               "callback", @calculate_value,
                               "backgroundcolor", [1 1 1],
                               "position", [0.18 0.575 0.20 0.03]);
                               
h.instrument_stressvalue_currency = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", instrument_struct(1).object.currency,
                                "horizontalalignment", "left",
                                "position", [0.39 0.575 0.04 0.03]);

% ##############################################################################
%   Curve section
h.curve_section_line = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "_________________________________________________________",
                                "FontSize", 10,
                                "horizontalalignment", "left",
                                "position", [0.01 0.555 0.49 0.02]);
h.curve_section_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Curve Section",
                                "FontSize", 13,
                                %"horizontalalignment", "left",
                                "position", [0.01 0.50 0.40 0.05]);
                                
h.curve_id_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Curve ID:",
                                "horizontalalignment", "left",
                                "position", [0.01 0.47 0.16 0.03]);
h.curve_attribute_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", "Attribute Value:",
                                %"horizontalalignment", "left",
                                "position", [0.18 0.47 0.18 0.03]);
h.curve_id_menu = uicontrol ("style", "popupmenu",
                               "units", "normalized",
                               "backgroundcolor", [1 1 1],
                               "string", {curve_struct.id},
                               "callback", @update_window,
                               "position", [0.01 0.435 0.16 0.03]);

h.curve_property_menu = uicontrol ("style", "popupmenu",
                               "units", "normalized",
                               "backgroundcolor", [1 1 1],
                               "string", {'rates_base','rates_stress','rates_mc'},
                               "callback", @update_window,
                               "position", [0.18 0.435 0.20 0.03]);

h.curve_attribute_nodes = uicontrol ("style", "edit",
                               "units", "normalized",
                               "string", any2str(curve_struct(1).object.get('nodes')),
                               "callback", @nochange,
                               "backgroundcolor", [1 1 1],
                               "position", [0.01 0.395 0.16 0.03]);
                               
h.curve_attribute_value = uicontrol ("style", "edit",
                               "units", "normalized",
                               "string", any2str(curve_struct(1).object.get('rates_base')),
                               "callback", @nochange,
                               "backgroundcolor", [1 1 1],
                               "position", [0.18 0.395 0.20 0.03]);
                               
% ##############################################################################                                
% Buttons:                              
% close application
h.exit_pushbutton = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Exit",
                                "callback","delete(gcf)",
                                "position", [0.41 0.01 0.07 0.04]);

% Calculate value
h.calc_value_pushbutton = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Recalc",
                                "callback",@calculate_value,
                                "position", [0.39 0.81 0.09 0.04]);

% Aggregate portfolio
h.aggregate_portfolio_pushbutton = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Aggregate",
                                "callback",@aggregate_portfolio,
                                "position", [0.89 0.89 0.09 0.04]);

% Plot curve
h.plot_curve_pushbutton = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Plot Curve",
                                "callback",@plot_curve,
                                "position", [0.39 0.44 0.09 0.04]);
                                
% Add position
h.add_position_pushbutton = uicontrol ("style", "pushbutton",
                                "units", "normalized",
                                "string", "Add Position ->",
                                "callback",@aggregate_portfolio,
                                "position", [0.39 0.89 0.09 0.04]);

% Add copyright
h.copyright_label = uicontrol ("style", "edit",
                                "units", "normalized",
                                "string", "(c) 2017 schinzilord@octarisk.com",
                                "FontSize", 8,
                                "horizontalalignment", "right",
                                "position", [0.84 0.01 0.15 0.023]);    

% Add valuation date
h.valuation_date_label = uicontrol ("style", "text",
                                "units", "normalized",
                                "string", sprintf ("Valuation Date: %s", datestr(valuation_date)),
                                "FontSize", 10,
                                %"horizontalalignment", "right",
                                "position", [0.35 0.955 0.20 0.04]);    
    
    
% refresh all objects and graphs
guidata (gcf, h);
update_window (gcf, true);
calculate_value(gcf);

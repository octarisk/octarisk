%# Copyright (C) 2015,2016,2017 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {} octarisk (@var{path_working_folder})
%#
%# Full valuation Monte-Carlo risk calculation framework.
%#
%# See www.octarisk.com for further information.
%#
%# @end deftypefn

function [instrument_struct, curve_struct, index_struct, surface_struct, para_object, matrix_struct, riskfactor_struct, portfolio_struct, stresstest_struct, mc_var_shock_pct, port_obj_struct] = octarisk(path_parameter,filename_parameter)



% ##############################################################################################
% Content:
% 0) ###########            DEFINITION OF VARIABLES    ###########
% 1. general variables
% 2. VAR specific variables

% I) ###########            INPUT                      ###########
%   1. Processing Instruments data
%   2. Processing Riskfactor data
%   3. Processing Positions data
%   4. Processing Stresstest data

% II) ###########           CALCULATION                ###########
%   1. Model Riskfactor Scenario Generation
%       a) Load input correlation matrix
%       b) Get distribution parameters from riskfactors
%       c) call MC scenario generations
%   2. Monte Carlo Riskfactor Simulation
%   3. Setup Stress test definitions
%   4. Process yield curves and volatility surfaces, apply shocks to market data objects
%   5. Full Valuation of all Instruments for all MC Scenarios determined by Riskfactors
%       a) Total Loop over all Instruments: call external pricing function
%   6. Portfolio Aggregation
%       a) loop over all portfolios / positions
%       b) VaR Calculation
%           i.) sort arrays
%           ii.) Get Value of confidence scenario
%           iii.) make vector with Harrel-Davis Weights
%       d) Calculate Expected Shortfall 
%   7. Print Report including position VaRs
%   8. Plotting 

% III) ###########         HELPER FUNCTIONS              ###########

% ##############################################################################################
% **********************************************************************************************
% ##############################################################################################
fprintf('\n');
fprintf('=======================================================\n');
fprintf('=== Starting octarisk market risk measurement tool  ===\n');
fprintf('=======================================================\n');
fprintf('\n');

% 0) ###########            DEFINITION OF VARIABLES    ###########

if nargin == 0
    error('octarisk: Please provide path and name of parameter file');
end

para_failed_cell = {};
if isstr(path_parameter)
    % load parameter file
    if (nargin == 1)    % assume parameter file called "parameter.csv"
        fprintf('Assuming default parameter file name >>%s\\parameter.csv<<.\n',path_parameter);
        filename_parameter = 'parameter.csv';
    end
    [para_object para_failed_cell] = load_parameter(path_parameter,filename_parameter);
elseif isobject(path_parameter)
    para_object = path_parameter;
end

% 1. general variables -> path dependent on operating system
path = para_object.path_working_folder;   % general load and save path for all input and output files
if ( strcmpi(path,''))
    path = path_parameter
end
path_output = strcat(path,'/',para_object.folder_output);
path_output_instruments = strcat(path_output,'/',para_object.folder_output_instruments);
path_output_riskfactors = strcat(path_output,'/',para_object.folder_output_riskfactors);
path_output_stresstests = strcat(path_output,'/',para_object.folder_output_stresstests);
path_output_positions   = strcat(path_output,'/',para_object.folder_output_positions);
path_output_mktdata     = strcat(path_output,'/',para_object.folder_output_mktdata);
path_reports = strcat(path,'/',para_object.folder_output,'/',para_object.folder_output_reports);
path_archive = strcat(path,'/',para_object.folder_archive);
path_input = strcat(path,'/',para_object.folder_input);
path_static = strcat(path,'/',para_object.folder_static);
path_mktdata = strcat(path,'/',para_object.folder_mktdata);

path

mkdir(path_output);
mkdir(path_output_instruments);
mkdir(path_output_riskfactors);
mkdir(path_output_stresstests);
mkdir(path_output_positions);
mkdir(path_output_mktdata);
mkdir(path_archive);
mkdir(path_input);
mkdir(path_mktdata);
mkdir(path_reports);
mkdir(path_static);
% Set current working directory to path
chdir(path);
act_pwd = strrep(pwd,'\','/');
if ~( strcmp(path,act_pwd) )
    error('Path could not be set to working folder');
end

% Clean up reporting directory
% A.1) delete all old files in path_output
if ( para_object.reporting )
  oldfiles = dir(path_reports);
  try
    for ii = 1 : 1 : length(oldfiles)
            tmp_file = oldfiles(ii).name;
            if ( length(tmp_file) > 3 )
                delete(strcat(path_reports,'/',tmp_file));
            end
    end
  end    
end

% set filenames for input:
input_filename_instruments  = para_object.input_filename_instruments;
input_filename_corr_matrix  = para_object.input_filename_corr_matrix;
input_filename_stresstests  = para_object.input_filename_stresstests;
input_filename_riskfactors  = para_object.input_filename_riskfactors;
input_filename_positions    = para_object.input_filename_positions;
input_filename_mktdata      = para_object.input_filename_mktdata;
input_filename_seed         = para_object.input_filename_seed;

% set filenames for vola surfaces
input_filename_vola_index = para_object.input_filename_vola_index;
input_filename_vola_ir = para_object.input_filename_vola_ir;
input_filename_surf_stoch = para_object.input_filename_surf_stoch;
input_filename_matrix = para_object.input_filename_matrix;

% set general variables
plotting = para_object.plotting;
saving = para_object.saving;
archive_flag = para_object.archive_flag;
mc_scen_analysis = para_object.mc_scen_analysis;
stable_seed = para_object.stable_seed;
aggregation_flag = para_object.aggregation_flag;
% valuation parameters
mc = para_object.mc; 
quantile = para_object.quantile; 
quantile_estimator = para_object.quantile_estimator;    
quantile_bandwidth = para_object.quantile_bandwidth; 
copulatype = para_object.copulatype;    
nu = para_object.nu; 
rnd_number_gen = para_object.rnd_number_gen;
valuation_date = para_object.valuation_date;
% Aggregation parameters
base_currency  = para_object.base_currency;
aggregation_key = para_object.aggregation_key;
mc_timestep    = para_object.mc_timestep;
scenario_set    = para_object.scenario_set;
mc_var_shock_pct = [];
% specify unique runcode and timestamp:
runcode = para_object.runcode;
if ( strcmpi(runcode,''))
    runcode = substr(hash('MD5',num2str(time())),-6);   % assign random runcode
end

timestamp = para_object.timestamp;
if ( strcmpi(timestamp,''))
    timestamp = strftime ('%Y%m%d_%H%M%S', localtime (time ())); % assign act date
end
first_eval      = para_object.first_eval;

% load packages
pkg load financial;     % load financial packages (needed throughout all scripts)
pkg load statistics;    % load statistics packages (needed throughout all scripts)
#bug_parallel_fixed = 0; % parallel package bug exists with Octave 7.1.0
#if (isunix && para_object.use_parallel_pkg == true && bug_parallel_fixed)
if (isunix && para_object.use_parallel_pkg == true)
	global use_parallel_pkg = false;
	global number_parallel_cores = para_object.number_parallel_cores;
	pkg load parallel; 	% load parallel packages (required for some cpp pricing functions
	pkg load ndpar; 	% only load if use_parallel_pkg parameter was set
else
	global use_parallel_pkg = false;
	global number_parallel_cores = nproc-1;
end

plottime = 0;   % initializing plottime
aggr = 0;       % initializing aggregation time
if isempty(mc_timestep)
    run_mc = false;
else
    run_mc = true;
end
% set seed of random number generator
if ( stable_seed == 1)
    % Read binary file and convert it to integers used as seed:
    %    Octave / Matlab uses Mersenne-Twister
    %    for pseudo random number generation. The seed vector is an arbitrary vector of length of 624.
    %    A 2496 bit binary file can be initialized from /dev/urandom (head --byte=2496 /dev/urandom > random_seed.dat)
    %    This file will be converted to a 32bit unsigned integer vector and used as seed.
    %    This high entropy seed is required to avoid low entropy random numbers used during scenario generation.
    %fid = fopen(strcat(path_static,'/',input_filename_seed)); % open file
    %random_seed = fread(fid,Inf,'uint32');     % convert binary file into integers
    %fclose(fid);                               % close file 
    random_seed = load(strcat(path_static,'/',input_filename_seed));
    if ~(strcmpi(rnd_number_gen,'Mersenne-Twister'))
        rand('seed',random_seed);               % set seed for MLCG
        randn('seed',random_seed);
    else    % Mersenne-Twister
        rand('state',random_seed);              % set seed for Mersenne-Twister
        randn('state',random_seed);
    end
else % use random seed
    if ~(strcmpi(rnd_number_gen,'Mersenne-Twister'))
        rand('seed','reset');                   % reset seed for MLCG
        randn('seed','reset');
        % query seed
        seed_rand = rand ('seed');
        seed_randn = randn ('seed');
    else    % Mersenne-Twister
        rand ('state', 'reset');                % reset seed for Mersenne-Twister   
        randn ('state', 'reset');
        % query seed
        seed_rand = rand ('state');
        seed_randn = rand ('state');
    end
    % store used seed_rand
    savename = 'seed_rand';
    endung   = '.dat';
    path     = strcat(path_static,'/');
    fullpath = [path, savename, endung];
    save ('-ascii', fullpath, savename);
    % store used seed_randn
    savename = 'seed_randn';
    endung   = '.dat';
    fullpath = [path, savename, endung];
    save ('-ascii', fullpath, savename);
end

fprintf('Valuation date: %s\n',any2str(datestr(valuation_date)));

% I) #########            INPUT                 #########
tic;
% 0. Processing timestep values
if (iscell(mc_timestep))
	error('octarisk: only one mc_timestep can be specified');
end

if ( strcmpi(mc_timestep(end),'d') )
	mc_timestep_days = str2num(mc_timestep(1:end-1));  % get timestep days
	para_object.mc_timestep_days = mc_timestep_days;
elseif ( strcmp(to_lower(mc_timestep(end)),'y'))
	mc_timestep_days = 365 * str2num(mc_timestep(1:end-1));  % get timestep days
	para_object.mc_timestep_days = mc_timestep_days;
else
	error('Unknown number of days in timestep: %s\n',mc_timestep);
end

if (run_mc == true)
    scenario_ts_days = [mc_timestep_days; 0];
else
    scenario_ts_days = zeros(length(scenario_set),1);
end
% 1. Processing Instruments data
instrument_struct=struct();
[instrument_struct id_failed_cell] = load_instruments(instrument_struct, ...
                    valuation_date,path_input,input_filename_instruments, ...
                    path_output_instruments,path_archive,timestamp,archive_flag,para_object);
              

% 2. Processing Riskfactor data
riskfactor_struct=struct();
[riskfactor_struct id_failed_cell] = load_riskfactors(riskfactor_struct, ...
            path_input,input_filename_riskfactors,path_output_riskfactors, ...
            path_archive,timestamp,archive_flag);

% 3. Processing Positions data
portfolio_struct=struct();
[portfolio_struct id_failed_cell positions_cell port_obj_struct] = load_positions(portfolio_struct, ...
            path_input,input_filename_positions,path_output_positions, ...
            path_archive,timestamp,archive_flag);

% 4. Processing Stresstest data
stresstest_struct=struct();
[stresstest_struct id_failed_cell] = load_stresstests(stresstest_struct, ...
            path_input,input_filename_stresstests,path_output_stresstests, ...
            path_archive,timestamp,archive_flag);
no_stresstests = length(stresstest_struct);
para_object.no_stresstests = no_stresstests;

% 5. Processing Market Data objects (Indizes and Marketcurves)
mktdata_struct=struct();
[mktdata_struct id_failed_cell] = load_mktdata_objects(mktdata_struct, ...
            path_mktdata,input_filename_mktdata,path_output_mktdata, ...
            path_archive,timestamp,archive_flag,para_object);


parseinput = toc;



% II) ##################            CALCULATION                ##################

 
% 1.) Model Riskfactor Scenario Generation
tic;
%-----------------------------------------------------------------
if (run_mc == true)
    % % special adjustment needed for HD vec if testing is performed with small MC numbers
    % if ( mc < 1000 ) 
        % hd_limit = mc - 1;
    % end

    % a.) Load input correlation matrix

    %corr_matrix = load(input_filename_corr_matrix); % path to correlation matrix

    [corr_matrix riskfactor_cell] = load_correlation_matrix(path_mktdata,input_filename_corr_matrix,path_archive,timestamp,archive_flag);
    	
    %corr_matrix = eye(length(riskfactor_struct));  % for test cases

    % b) Get distribution parameters: all four moments and return for marginal distributions are taken directly from riskfactors
    %   in order of their appearance in correlation matrix
    for ii = 1 : 1 : length(riskfactor_cell)
        rf_id = riskfactor_cell{ii};
        [rf_object retcode] = get_sub_object(riskfactor_struct, rf_id);
        if (retcode > 0)
            rf_para_distributions(1,ii)   = rf_object.mean;  % mu
            rf_para_distributions(2,ii)   = rf_object.std;   % sigma
            rf_para_distributions(3,ii)   = rf_object.skew;  % skew
            rf_para_distributions(4,ii)   = rf_object.kurt;  % kurt  
        else
            error('Unknown risk factor defined in correlation matrix: >>%s<<',rf_id);
        end
    end
    % c) call MC scenario generation (Copula approach, Pearson distribution types 1-7 according four moments of distribution parameters)
    %    returns matrix R with a mc_scenarios x 1 vector with correlated random variables fulfilling skewness and kurtosis
    [R_250 distr_type] = scenario_generation_MC(corr_matrix,rf_para_distributions,mc,copulatype,nu,256,path_static,para_object);
    %[R_1 distr_type] = scenario_generation_MC(corr_matrix,rf_para_distributions,mc,copulatype,nu,1); % only needed if independent random numbers are desired

    % variable for switching statistical analysis on and off
    if ( mc_scen_analysis == 1 )
        retcode = perform_rf_stat_tests(riskfactor_cell,riskfactor_struct,R_250,distr_type);
    end
    % Generate Structure with Risk factor scenario values: scale values according to timestep
    M_struct = struct();
    M_struct( 1 ).matrix = R_250 ./ sqrt(250/mc_timestep_days);
    % --------------------------------------------------------------------------------------------------------------------
    % 2.) Monte Carlo Riskfactor Simulation for all timesteps
    [riskfactor_struct rf_failed_cell ] = load_riskfactor_scenarios(riskfactor_struct,M_struct,riskfactor_cell,mc_timestep,mc_timestep_days,para_object);
    
    % map risk factors 
    % Processing MC Mapping file
	[riskfactor_struct riskfactor_cell mapping_failed_cell] = ...
				load_riskfactor_mapping(riskfactor_struct, riskfactor_cell, ...
				path_input,para_object.input_filename_mc_mapping);
end

% update riskfactor with stresses
[riskfactor_struct rf_failed_cell ] = load_riskfactor_stresses(riskfactor_struct,stresstest_struct);

scengen = toc;

%~ tmp_obj_high = get_sub_object(riskfactor_struct, 'RF_ALT_HIGH')
%~ tmp_obj_btc = get_sub_object(riskfactor_struct, 'RF_ALT_BTC')

tic;
if ( saving == 1 )
    [save_cell] = save_objects(path_output,riskfactor_struct,instrument_struct,portfolio_struct,stresstest_struct);
end
saving_time = toc;


    
% --------------------------------------------------------------------------------------------------------------------

% 4.) Process yield curves and vola surfaces: Generate object with riskfactor yield curves and surfaces 
tic;

% a) Processing yield curves

curve_struct=struct();
[rf_ir_cur_cell curve_struct curve_failed_cell] = load_yieldcurves(curve_struct,riskfactor_struct,mc_timestep,path_output,saving,run_mc);

        
% b) Updating Marketdata Curves and Indizes with scenario dependent risk factor values
index_struct=struct();
surface_struct=struct();
[index_struct curve_struct surface_struct id_failed_cell] = update_mktdata_objects(valuation_date,instrument_struct,mktdata_struct,index_struct,riskfactor_struct,curve_struct,surface_struct,mc_timestep,mc,no_stresstests,run_mc,stresstest_struct);   
%~ c = get_sub_object(index_struct,'FX_EURCAD')
%~ c = get_sub_object(index_struct,'FX_EURCHF')
%~ c = get_sub_object(riskfactor_struct,'RF_IR_EUR_1Y')
%~ c = get_sub_object(curve_struct,'IR_EUR')
%~ c = get_sub_object(curve_struct,'RF_IR_EUR')
% c) Processing Vola surfaces: Load in all vola marketdata and fill Surface object with values
[surface_struct vola_failed_cell] = load_volacubes(surface_struct,path_mktdata,input_filename_vola_index,input_filename_vola_ir,input_filename_surf_stoch,stresstest_struct,riskfactor_struct,run_mc);


% e) Loading matrix objects
matrix_struct=struct();
[matrix_struct matrix_failed_cell] = load_matrix_objects(matrix_struct,path_mktdata,input_filename_matrix);


curve_gen_time = toc;

% ------------------------------------------------------------------------------
% 5. Full Valuation of all Instruments for all MC Scenarios
%   Total Loop over all Instruments and type dependent valuation
fulvia = 0.0;
fulvia_performance = {};
instrument_valuation_failed_cell = {}; 
number_instruments =  length( instrument_struct );
for kk = 1 : 1 : length( scenario_set )      % loop via all MC time steps and other scenarios
  tmp_scenario  = scenario_set{ kk };    % get scenario from scenario_set
  tmp_ts        = scenario_ts_days(kk);  % get timestep days
  if ( strcmpi(tmp_scenario,'stress'))
      scen_number = no_stresstests;
  elseif ( strcmpi(tmp_scenario,'base'))
      scen_number = 1;
  else
      scen_number = mc;
  end
  % store current scenario number in object
  para_object.scen_number = scen_number;
        
  fprintf('== Full valuation | scenario set %s | number of scenarios %d | timestep in days %d ==\n',tmp_scenario, scen_number,tmp_ts);
  for ii = 1 : 1 : length( instrument_struct )
    try
    % TODO: loop via positions_cell -> get id from instrument struct -> valuate these instruments only
    % store in special valuated_instruments struct -> aggregate from these struct only
    tmp_id = instrument_struct( ii ).id;
    tic;
        % =================    Full valuation    ===============================
        
        tmp_instr_obj = get_sub_object(instrument_struct, tmp_id); 
        % Call instrument object method valuate
        tmp_instr_obj = tmp_instr_obj.valuate(valuation_date, tmp_scenario, ...
                                instrument_struct, surface_struct, ...
                                matrix_struct, curve_struct, index_struct, ...
                                riskfactor_struct, para_object);
        % store valuated instrument in struct
        instrument_struct( ii ).object = tmp_instr_obj;
        % print status message:
        if ( mod(ii,round(number_instruments/10)) == 0 )
            %fprintf('%s Pct. processed. Continuing...\n',any2str(round((ii/number_instruments)*100)));
            fprintf('|%s %s|\n',any2str(char(repmat(61,1,round((ii/number_instruments)*10)))),any2str(char(repmat(95,1,10-round((ii/number_instruments)*10)))));
        end
        % =================  End Full valuation  ===============================
        
     % store performance data into cell array
     fulvia_performance{end + 1} = strcat(tmp_instr_obj.get('type'),'|',tmp_instr_obj.get('sub_type'),'|',tmp_id,'|',num2str(scen_number),'|',num2str(toc),'|s');
     fulvia = fulvia + toc ;  
    catch   % catch error in instrument valuation
        fprintf('octarisk:Instrument valuation for %s failed. There was an error: >>%s<< File: >>%s<< Line: >>%d<<\n',tmp_id,lasterr,lasterror.stack.file,lasterror.stack.line);
        instrument_valuation_failed_cell{ length(instrument_valuation_failed_cell) + 1 } =  tmp_id;
        % FALLBACK: store instrument as Cash instrument with fixed value_base for all scenarios (use different variable for scen_number to avoid collisions)
        cc = Cash();
        cc = cc.set('id',tmp_instr_obj.get('id'),'name',tmp_instr_obj.get('name'),'asset_class',tmp_instr_obj.get('asset_class'),'currency',tmp_instr_obj.get('currency'),'value_base',tmp_instr_obj.get('value_base'));
        for pp = 1 : 1 : length(scenario_set);
            if ( strcmp(scenario_set{pp},'stress'))
                scen_number_catch = no_stresstests;
            else
                scen_number_catch = mc;
            end
            cc = cc.calc_value(scenario_set{pp},scen_number_catch);   % repeat base value in all MC timesteps and stress scenarios -> riskfree
        end
        instrument_struct( ii ).object = cc;
    end
  end 
  para_object.first_eval = 0;
  
end      % end eval mc timesteps and stress loops

tic;

if ( saving == 1 )
    % loop via all objects in structs and convert
    tmp_instrument_struct_fv = instrument_struct;
    for ii = 1 : 1 : length( tmp_instrument_struct )
        tmp_instrument_struct(ii).object = struct(tmp_instrument_struct(ii).object);
    end 
    savename = 'tmp_instrument_struct_fv';
    fullpath = [path_output, savename, endung];
    save ('-v7', fullpath, savename);
end
saving_time = saving_time + toc;  

instrument_valuation_failed_cell = unique(instrument_valuation_failed_cell);
if ( length(instrument_valuation_failed_cell) >= 1 )
    fprintf('WARNING: Failed instrument valuation for %d instruments: \n',length(instrument_valuation_failed_cell));
    instrument_valuation_failed_cell
else
    fprintf('SUCCESS: All instruments valuated.\n');
end

% print all base values
fprintf('Instrument Base and stress Values: \n');
fprintf('ID,Base,StressBase,%s,%s,%s,Currency\n',stresstest_struct(2).name,stresstest_struct(3).name,stresstest_struct(11).name);
for kk = 1:1:length(instrument_struct)
    obj = instrument_struct(kk).object;
    stressvec = obj.getValue('stress');
    if (length(stressvec) > 4)
        fprintf('%s,%9.8f,%9.8f,%9.8f,%9.8f,%9.8f,%s\n',obj.id,obj.getValue('base'),stressvec(1),stressvec(2),stressvec(3),stressvec(11),any2str(obj.currency));
    else
        fprintf('%s,%9.8f,%9.8f,%9.8f,%9.8f,%9.8f,%s\n',obj.id,obj.getValue('base'),stressvec(1),stressvec(1),stressvec(1),stressvec(1),any2str(obj.currency));
    end
end

% print all IR sensitivities
fprintf('Instrument IR Sensitivities: \n');
fprintf('ID,EffDuration,EffConvexity\n');
for kk = 1:1:length(instrument_struct)
    obj = instrument_struct(kk).object;
    if (isProp(obj,'eff_convexity') && isProp(obj,'eff_duration'))
		fprintf('%s,%3.1f,%3.1f \n',obj.id,obj.eff_duration,obj.eff_convexity);
    end
end

%~ tmp_obj = get_sub_object(instrument_struct, '103057'); 
%~ tmp_obj
%~ tmp_obj = get_sub_object(instrument_struct, 'A188AL'); 
%~ tmp_obj
%~ tmp_obj = get_sub_object(curve_struct, 'IR_INFL_EUR'); 
%~ tmp_obj.get('rates_base')'
%~ tmp_obj_infl = get_sub_object(riskfactor_struct, 'RF_INFL_EXP_CURVE')
%~ distritmp = tmp_obj_infl.getValue('10d');
%~ tmp_obj = get_sub_object(curve_struct, 'IR_EUR'); 
%~ tmp_obj
%~ tmp_obj = get_sub_object(curve_struct, 'SPREAD_EUR_IG'); 
%~ tmp_obj
%~ tmp_obj = get_sub_object(curve_struct, 'EUR_CORP_IG'); 
%~ tmp_obj
%~ tmp_obj.get('rates_stress')'

% ----------------------------------------------------------------------
% 6. Portfolio Aggregation
aggr = 0;
position_failed_cell = {};

if (aggregation_flag == true) % aggregation and reporting batch
	tic;

	% aggregate and calc_risk for all portfolios
	for ii = 1:1:length(port_obj_struct)
		port_obj = port_obj_struct(ii).object;
		% Base aggregation and risk calculation
		port_obj = port_obj.aggregate('base', instrument_struct, ...
												index_struct, para_object);
		port_obj = port_obj.calc_risk('base', instrument_struct, ...
												index_struct, para_object);
		% aggregation and risk calculation for all scenario sets
		for kk = 1 : 1 : length( scenario_set )      % loop via all MC time steps
			tmp_scen_set  = scenario_set{ kk };    % get timestep string
			port_obj = port_obj.aggregate(tmp_scen_set, instrument_struct, ...
												index_struct, para_object);
			port_obj = port_obj.calc_risk(tmp_scen_set, instrument_struct, ...
												index_struct, para_object);									
		end

		position_failed_cell = port_obj.get('position_failed_cell');
		port_obj_struct(ii).object = port_obj;
	end

	aggr = toc;

	% error handling
	position_failed_cell = unique(position_failed_cell);
	if ( length(position_failed_cell) >= 1 )
		fprintf('\nWARNING: Failed aggregation for %d positions: \n',length(position_failed_cell));
		position_failed_cell
	else
		fprintf('\nSUCCESS: All positions aggregated.\n');
	end
end % close aggregation_flag condition

% ----------------------------------------------------------------------
% 7. Portfolio Reporting
reporting_time = 0;
tic;
if ( para_object.reporting )
  for ii = 1:1:length(port_obj_struct)
	port_obj = port_obj_struct(ii).object;
    port_obj = port_obj.print_report(para_object,'LaTeX','base');	
    
    % aggregation and risk calculation for all scenario sets
	for kk = 1 : 1 : length( scenario_set )      % {stress, MCscenset}
		tmp_scen_set  = scenario_set{ kk };    % get timestep string
        % standard reporting: Total shred
        if strcmpi(para_object.shred_type,'TOTAL')
            port_obj = port_obj.print_report(para_object,'LaTeX',tmp_scen_set,stresstest_struct,instrument_struct);	
            port_obj = port_obj.print_report(para_object,'decomp',tmp_scen_set);
        else % special shred reporting
            port_obj = port_obj.print_report(para_object,'shred',tmp_scen_set,stresstest_struct,instrument_struct);	
        end
	end
    port_obj
    port_obj_struct(ii).object = port_obj;
  end	
end
reporting_time = toc;

% ----------------------------------------------------------------------
% 8. Portfolio Plotting
tic;
if ( para_object.plotting )
  for ii = 1:1:length(port_obj_struct)
	port_obj = port_obj_struct(ii).object;
	
    % standard reporting: Total shred
    if strcmpi(para_object.shred_type,'TOTAL')
        port_obj = port_obj.plot(para_object,'stress','stress', ...
                                                stresstest_struct);
        port_obj = port_obj.plot(para_object,'liquidity','base');										
        port_obj = port_obj.plot(para_object,'concentration','base');										
        port_obj = port_obj.plot(para_object,'asset_allocation','base');										
        port_obj = port_obj.plot(para_object,'ir_sensitivity','base');										
        port_obj = port_obj.plot(para_object,'equitystylebox','base');										
        port_obj = port_obj.plot(para_object,'mvbs_plotting','base');										
        % aggregation and risk calculation for all scenario sets
        for kk = 1 : 1 : length( scenario_set )      % {stress, MCscenset}
            tmp_scen_set  = scenario_set{ kk };    % get timestep string
            port_obj = port_obj.plot(para_object,'srri',tmp_scen_set, ...
                                                stresstest_struct);
            port_obj = port_obj.plot(para_object,'marketdata',tmp_scen_set, ...
                                                stresstest_struct,curve_struct);
            port_obj = port_obj.plot(para_object,'var',tmp_scen_set);		
            port_obj = port_obj.plot(para_object,'history',tmp_scen_set);	
            port_obj = port_obj.plot(para_object,'liquidity',tmp_scen_set);								
            % port_obj = port_obj.plot(para_object,'lorentz',tmp_scen_set);	 % I do not what to do with Gini coefficient and Lorentz curve							
            port_obj = port_obj.plot(para_object,'riskfactor',tmp_scen_set, ...
                                stresstest_struct,curve_struct,riskfactor_struct);								
        end
    else % special shred plotting
        % currently no shred plot implemented
    end
    port_obj_struct(ii).object = port_obj;	
    									
  end	
end
plottime = toc;


% ----------------------------------------------------------------------
% 9. Statistics
totaltime = round((parseinput + scengen + curve_gen_time + fulvia + aggr + plottime + saving_time + reporting_time)*10)/10;
fprintf('\n');
fprintf('=== Total Time for Calculation ===\n');
fprintf('Total time for parsing input files:  %6.2f s\n', parseinput);
fprintf('Total time for MC scenario generation:  %6.2f s\n', scengen)
fprintf('Total time for Curve generation:  %6.2f s\n', curve_gen_time)
fprintf('Total time for full valuation:  %6.2f s\n', fulvia);
fprintf('Total time for aggregation:  %6.2f s\n', aggr);
fprintf('Total time for plotting:  %6.2f s\n', plottime);
fprintf('Total time for reporting:  %6.2f s\n', reporting_time);
fprintf('Total time for saving data:  %6.2f s\n', saving_time);
totaltime = round((parseinput + scengen + curve_gen_time + fulvia + saving_time + plottime + aggr + reporting_time)*10)/10;
fprintf('Total Runtime:  %6.2f s\n',totaltime);

fprintf('\n');
fprintf('=======================================================\n');
fprintf('===   Ended octarisk market risk measurement tool   ===\n');
fprintf('=======================================================\n');
fprintf('\n');

% ----------------------------------------------------------------------
% 10. Final clean up

    %  move all reports files to an TAR in folder archive
    try
        tarfiles = tar( strcat(path_reports,'/archive_reports_',tmp_timestamp,'.tar'),strcat(path,'/*'));
    end

end     % ending MAIN function octarisk


%# Copyright (C) 2015 Stefan Schloegl <schinzilord@octarisk.com>
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
%# Version: 0.0.0, 2015/11/24, Stefan Schloegl:   initial version @* 
%#          0.0.1, 2015/12/16, Stefan Schloegl:   added Willow Tree model for pricing american equity options, @*
%#                                              added volatility surface model for term / moneyness structure of volatility for index vol @*
%#          0.0.2, 2016/01/19, Stefan Schloegl:   added new instrument types FRB, FRN, FAB, ZCB @*
%#                                              added synthetic instruments (linear combinations of other instruments) @*
%#                                              added equity forwards and Black-Karasinski stochastic process @*
%#			0.0.3, 2016/02/05, Stefan Schloegl:	  added spread risk factors, general cash flow pricing  @*
%#			0.0.4, 2016/03/28, Stefan Schloegl:   changed the implementation to object oriented approach (introduced instrument, risk factor classes) @*
%#          0.1.0, 2016/04/02, Stefan Schloegl:   added volatility cube model (Surface class) for tenor / term / moneyness structure of volatility for ir vol @*
%#          0.2.0, 2016/04/19, Stefan Schloegl:   improved the file interface and format for input files (market data, risk factors, instruments, positions, stresstests)  @*
%# @*
%# @*
%# Calculate Monte-Carlo Value-at-Risk (VAR) and Expected Shortfall (ES) for instruments, positions and portfolios at a given confidence level on 
%# 1D and 250D time horizon with a full valuation approach.
%#
%# See octarisk documentation for further information.
%#
%# @*
%# Input files in csv format:
%# @itemize @bullet
%# @item Instruments data: specification of instrument universe (name, id, market value, underlying risk factor, cash flows etc.)
%# @item Riskfactors data: specification of risk factors (name, id, stochastic model, statistic parameters)
%# @item Positions data: specification of portfolio and position data (portfolio id, instrument id, position size)
%# @item Stresstest data: specification of stresstest risk factor shocks (stresstest name, risk factor shock values and types)
%# @item Covariance matrix: covariance matrix of all risk factors
%# @item Volatility surfaces (index volatility: term vs. moneyness, call moneyness spot / strike, linear interpolation and constant extrapolation)
%# @end itemize
%# @*
%# Output data:
%# @itemize @bullet
%# @item portfolio report: instruments and position VAR and ES, diversification effects
%# @item profit and loss distributions: plot of profit and loss histogramm and distribution, most important positions and instruments
%# @end itemize
%# @*
%# Supported instrument types:
%# @itemize @bullet
%# @item equity (stocks and funds priced via multi-factor model and idiosyncratic risk)
%# @item commodity (physical and funds priced via multi-factor model and idiosyncratic risk)
%# @item real estate (stocks and funds priced via multi-factor model and idiosyncratic risk)
%# @item custom cash flow instruments (NPV of all custom CFs) 
%# @item bond funds priced via duration-based sensitivity approach
%# @item fixed rate bonds (NPV of all CFs)
%# @item floating rate notes (scenario dependent cash flow values, NPV of all CFs)
%# @item fixed amortizing bonds (either annuity bonds or amortizable bonds, NPV of all CFs)
%# @item zero coupon bonds (NPV of notional)
%# @item European equity options (Black-Scholes model)
%# @item American equity options (Willow Tree model)
%# @item European swaptions (Black76 and Bachelier model)
%# @item Equity forward
%# @item Synthetic instruments (linear combinations of other valuated instruments)
%# @end itemize
%# @*
%# Supported stochastic processes for risk factors:
%# @itemize @bullet
%# @item Geometric Brownian Motion 
%# @item Black-Karasinski process
%# @item Brownian Motion 
%# @item Ornstein-Uhlenbeck process
%# @item Square-root diffusion process 
%# @end itemize
%# @*
%# Supported copulas for MC scenario generation:
%# @itemize @bullet
%# @item Gaussian copula
%# @item t-copula with one parameter specification for common degrees of freedom
%# @end itemize
%# @*
%# Further functionality will be implemented in the future (e.g. inflation linked instruments)
%# @seealso{option_willowtree, option_bs, harrell_davis_weight, swaption_black76, pricing_forward, rollout_cashflows, scenario_generation_MC}
%# @end deftypefn

function octarisk(path_working_folder)

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
%       a) Total Loop over all Instruments and type dependent valuation
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
% 1. general variables -> path dependent on operating system
path = path_working_folder;   % general load and save path for all input and output files

path_output = strcat(path,'/output');
path_output_instruments = strcat(path_output,'/instruments');
path_output_riskfactors = strcat(path_output,'/riskfactors');
path_output_stresstests = strcat(path_output,'/stresstests');
path_output_positions   = strcat(path_output,'/positions');
path_output_mktdata     = strcat(path_output,'/mktdata');
path_reports = strcat(path,'/output/reports');
path_archive = strcat(path,'/archive');
path_input = strcat(path,'/input');
path_static = strcat(path,'/static');
path_mktdata = strcat(path,'/mktdata');
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
oldfiles = dir(path_reports);
try
    for ii = 1 : 1 : length(oldfiles)
            tmp_file = oldfiles(ii).name;
            if ( length(tmp_file) > 3 )
                delete(strcat(path_reports,'/',tmp_file));
            end
    end
end    


% set filenames for input:
input_filename_instruments  = 'instruments.csv';
input_filename_corr_matrix  = 'corr.csv';
input_filename_stresstests  = 'stresstests.csv';
input_filename_riskfactors  = 'riskfactors.csv';
input_filename_positions    = 'positions.csv';
input_filename_mktdata      = 'mktdata.csv';
input_filename_seed			= 'random_seed.dat';

% set filenames for vola surfaces
input_filename_vola_index = 'vol_index_';
input_filename_vola_ir = 'vol_ir_';

% set general variables
plotting = 1;           % switch for plotting data (0/1)
saving = 0;             % switch for saving *.mat files (WARNING: that takes a long time for 50k scenarios and multiple instruments!)
archive_flag = 0;       % switch for archiving input files to the archive folder (as .tar). This takes some seconds.
stable_seed = 1;        % switch for using stored random numbers (1) or drawing new random numbers (0)
mc_scen_analysis = 0;   % switch for applying statistical tests on risk factor MC scenario values 
                        %   (compare target statistic parameters with actual values)
% load packages
pkg load statistics;	% load statistics package (needed in scenario_generation_MC)
pkg load financial;		% load financial packages (needed throughout all scripts)

% 2. VAR specific variables
mc = 50000              % number of MonteCarlo scenarios
hd_limit = 50001;       % below this MC limit Harrel-Davis estimator will be used
confidence = 0.999      % level of confidence vor MC VAR calculation
copulatype = 't'        % Gaussian  or t-Copula  ( copulatype in ['Gaussian','t'])
nu = 10                 % single parameter nu for t-Copula 
valuation_date = datenum('31-Dec-2015'); % valuation date
base_currency  = 'EUR'  % base reporting currency
aggregation_key = {'asset_class','currency','id'}    % aggregation key
mc_timesteps    = {'10d'}                % MC timesteps
scenario_set    = [mc_timesteps,'stress'];          % append stress scenarios
gpd_confidence_levels = [0.9;0.95;0.975;0.99;0.995;0.999;0.9999];   % vector with confidence levels used in reporting of EVT VAR and ES

% specify unique runcode and timestamp:
runcode = '2015Q4'; %substr(md5sum(num2str(time()),true),-6)
timestamp = '20160424_175042'; %strftime ('%Y%m%d_%H%M%S', localtime (time ()))

first_eval      = 0;

% set seed of random number generator
if ( stable_seed == 1)
    % Read binary file and convert it to integers used as seed:
    %    Octave / Matlab uses Mersenne-Twister
    %    for pseudo random number generation. The seed vector is an arbitrary vector of length of 624.
    %    A 2496 bit binary file can be initialized from /dev/urandom (head --byte=2496 /dev/urandom > random_seed.dat)
    %    This file will be converted to a 32bit unsigned integer vector and used as seed.
    %    This high entropy seed is required to avoid low entropy random numbers used during scenario generation.
    fid = fopen(strcat(path_static,'/',input_filename_seed)); % open file
    random_seed = fread(fid,Inf,'uint32');		% convert binary file into integers
    fclose(fid);								% close file 
    rand('state',random_seed);					% set seed
    randn('state',random_seed);
end
% I) #########            INPUT                 #########
tic;
% 0. Processing timestep values
mc_timestep_days = zeros(length(mc_timesteps),1);
for kk = 1:1:length(mc_timesteps)
    tmp_ts = mc_timesteps{kk};
    if ( strcmp(lower(tmp_ts(end)),'d') )
        mc_timestep_days(kk) = str2num(tmp_ts(1:end-1));  % get timestep days
    elseif ( strcmp(to_lower(tmp_ts(end)),'y'))
        mc_timestep_days(kk) = 365 * str2num(tmp_ts(1:end-1));  % get timestep days
    else
        error('Unknown number of days in timestep: %s\n',tmp_ts);
    end
end
scenario_ts_days = [mc_timestep_days; 0];
% 1. Processing Instruments data
persistent instrument_struct;
instrument_struct=struct();
[instrument_struct id_failed_cell] = load_instruments(instrument_struct,valuation_date,path_input,input_filename_instruments,path_output_instruments,path_archive,timestamp,archive_flag);

% 2. Processing Riskfactor data
persistent riskfactor_struct;
riskfactor_struct=struct();
[riskfactor_struct id_failed_cell] = load_riskfactors(riskfactor_struct,path_input,input_filename_riskfactors,path_output_riskfactors,path_archive,timestamp,archive_flag);

% 3. Processing Positions data
persistent portfolio_struct;
portfolio_struct=struct();
[portfolio_struct id_failed_cell] = load_positions(portfolio_struct, path_input,input_filename_positions,path_output_positions,path_archive,timestamp,archive_flag);

% 4. Processing Stresstest data
persistent stresstest_struct;
stresstest_struct=struct();
[stresstest_struct id_failed_cell] = load_stresstests(stresstest_struct, path_input,input_filename_stresstests,path_output_stresstests,path_archive,timestamp,archive_flag);
no_stresstests = length(stresstest_struct);

% 5. Processing Market Data objects (Indizes and Marketcurves)
persistent mktdata_struct;
mktdata_struct=struct();
[mktdata_struct id_failed_cell] = load_mktdata_objects(mktdata_struct,path_mktdata,input_filename_mktdata,path_output_mktdata,path_archive,timestamp,archive_flag);
% for kk = 1 : 1 : length(mktdata_struct)
    % printf('>>%s<<\n',mktdata_struct(kk).id)
    % tmpobject = mktdata_struct(kk).object;
    % tmpobject
% end
parseinput = toc;


% II) ##################            CALCULATION                ##################

 
% 1.) Model Riskfactor Scenario Generation
tic;
%-----------------------------------------------------------------

% special adjustment needed for HD vec if testing is performed with small MC numbers
if ( mc < 1000 ) 
    hd_limit = mc - 1;
end

% a.) Load input correlation matrix

%corr_matrix = load(input_filename_corr_matrix); % path to correlation matrix

[corr_matrix riskfactor_cell] = load_correlation_matrix(path_mktdata,input_filename_corr_matrix,path_archive,timestamp,archive_flag);
%corr_matrix = eye(length(riskfactor_struct));  % for test cases

% b) Get distribution parameters: all four moments and return for marginal distributions are taken directly from riskfactors
%   in order of their appearance in correlation matrix
for ii = 1 : 1 : length(riskfactor_cell)
    rf_id = riskfactor_cell{ii};
    rf_object = get_sub_object(riskfactor_struct, rf_id);
    rf_para_distributions(1,ii)   = rf_object.mean;  % mu
    rf_para_distributions(2,ii)   = rf_object.std;   % sigma
    rf_para_distributions(3,ii)   = rf_object.skew;  % skew
    rf_para_distributions(4,ii)   = rf_object.kurt;  % kurt    
end
% c) call MC scenario generation (Copula approach, Pearson distribution types 1-7 according four moments of distribution parameters)
%    returns matrix R with a mc_scenarios x 1 vector with correlated random variables fulfilling skewness and kurtosis
[R_250 distr_type] = scenario_generation_MC(corr_matrix,rf_para_distributions,mc,copulatype,nu,256,path_static,stable_seed);
%[R_1 distr_type] = scenario_generation_MC(corr_matrix,rf_para_distributions,mc,copulatype,nu,1); % only needed if independent random numbers are desired

% variable for switching statistical analysis on and off
if ( mc_scen_analysis == 1 )
    % Perform statistical tests on MC risk factor distributions:
    for ii = 1 : 1 : length(riskfactor_cell)  
        rf_id = riskfactor_cell{ii};
        rf_object = get_sub_object(riskfactor_struct, rf_id);    
        fprintf('=== Distribution function for riskfactor %s ===\n',rf_object.id);
        fprintf('Pearson_type: >>%d<<\n',distr_type(ii));  
        mean_target = rf_object.mean;   % mean
        mean_act = mean(R_250(:,ii));
        sigma_target = rf_object.std;   % sigma
        sigma_act = std(R_250(:,ii));
        skew_target = rf_object.skew;   % skew
        skew_act = skewness(R_250(:,ii));
        kurt_target = rf_object.kurt;   % kurt    
        kurt_act = kurtosis(R_250(:,ii));
        fprintf('Stat. parameter:  \t| Target | Actual \n');
        fprintf('Mean comparision: \t| %0.4f |  %0.4f \n',mean_target,mean_act);
        fprintf('Vola comparision: \t| %0.4f |  %0.4f \n',sigma_target,sigma_act);
        fprintf('Skewness comparision: \t| %0.4f |  %0.4f \n',skew_target,skew_act);
        fprintf('Kurtosis comparision: \t| %0.4f |  %0.4f \n',kurt_target,kurt_act);
        % test for bimodality -> fit polynomial and calculate parabola opening parameter sign
        [xx yy] = hist(R_250(:,ii),80);
        p = polyfit(yy,xx,2);
        if ( p(1) > 0 )
            fprintf('Warning: octarisk: Distribution type >>%d<< for riskfactor >>%s<< might be bimodal.\n',distr_type(ii),rf_id);
        end
    end
end
% Generate Structure with Risk factor scenario values: scale values according to timestep
M_struct = struct();
for kk = 1:1:length(mc_timestep_days)       % workaround: take only one random matrix and derive all other timesteps from them
        % [R_250 distr_type] = scenario_generation_MC(corr_matrix,rf_para_distributions,mc,copulatype,nu,mc_timestep_days(kk)); % uncomment, if new random numbers needed for each timestep
        M_struct( kk ).matrix = R_250 ./ sqrt(250/mc_timestep_days(kk));
end
% --------------------------------------------------------------------------------------------------------------------
% 2.) Monte Carlo Riskfactor Simulation for all timesteps
[riskfactor_struct rf_failed_cell ] = load_riskfactor_scenarios(riskfactor_struct,M_struct,riskfactor_cell,mc_timesteps,mc_timestep_days);
% for kk = 1  : 1 : length(riskfactor_struct)
   % riskfactor_struct(kk).id
   % riskfactor_struct(kk).object
% end

% 3.) Take Riskfactor Shiftvalues from Stressdefinition
[riskfactor_struct rf_failed_cell ] = load_riskfactor_stresses(riskfactor_struct,stresstest_struct);

scengen = toc;

tic;
if ( saving == 1 )
    [save_cell] = save_objects(path_output,riskfactor_struct,instrument_struct,portfolio_struct,stresstest_struct);
end
saving_time = toc;

    
% --------------------------------------------------------------------------------------------------------------------

% 4.) Process yield curves and vola surfaces: Generate object with riskfactor yield curves and surfaces 
tic;

% a) Processing yield curves

persistent curve_struct;
curve_struct=struct();
[rf_ir_cur_cell curve_struct curve_failed_cell] = load_yieldcurves(curve_struct,riskfactor_struct,mc_timesteps,path_output,saving);
% for kk = 1  : 1 : length(curve_struct)
   % curve_struct(kk).id
   % curve_struct(kk).object
% end
% b) Processing Vola surfaces: Load in all vola marketdata and fill Surface object with values
persistent surface_struct;
surface_struct=struct();
[surface_struct vola_failed_cell] = load_volacubes(surface_struct,path_mktdata,input_filename_vola_index,input_filename_vola_ir);



% c) Updating Marketdata Curves and Indizes with scenario dependent risk factor values
persistent index_struct;
index_struct=struct();
[index_struct curve_struct id_failed_cell] = update_mktdata_objects(valuation_date,mktdata_struct,index_struct,riskfactor_struct,curve_struct,mc_timesteps,mc,no_stresstests);   
% for kk = 1  : 1 : length(index_struct)
   % index_struct(kk).id
   % index_struct(kk).object
% end
 % for kk = 1  : 1 : length(curve_struct)
    % curve_struct(kk).id
    % curve_struct(kk).object
 % end

% for kk = 1  : 1 : length(riskfactor_struct)
   % riskfactor_struct(kk).object
   % %riskfactor_struct(kk).object.getValue('250d')
   % %riskfactor_struct(kk).object.getValue('base')
% end
curve_gen_time = toc;

% --------------------------------------------------------------------------------------------------------------------
% 5. Full Valuation of all Instruments for all MC Scenarios determined by Riskfactors
%   Total Loop over all Instruments and type dependent valuation
fulvia = 0.0;
fulvia_performance = {};
instrument_valuation_failed_cell = {};  
for kk = 1 : 1 : length( scenario_set )      % loop via all MC time steps and other scenarios
  tmp_scenario  = scenario_set{ kk };    % get scenario from scenario_set
  tmp_ts        = scenario_ts_days(kk);  % get timestep days
  if ( strcmp(tmp_scenario,'stress'))
      scen_number = no_stresstests;
  else
      scen_number = mc;
  end
  fprintf('== Full evaluation | scenario set %s | number of scenarios %d | timestep in days %d ==\n',tmp_scenario, scen_number,tmp_ts);
  for ii = 1 : 1 : length( instrument_struct )
    try
    tmp_id = instrument_struct( ii ).id;
    tic;
    tmp_instr_obj = get_sub_object(instrument_struct, tmp_id); 
    tmp_type = tmp_instr_obj.type;
    tmp_sub_type = tmp_instr_obj.sub_type;
	% Full Valuation depending on Type:
            % ETF Debt Valuation:
            if ( strcmp(tmp_type,'debt') == 1 )
				% Using debt class
                debt = tmp_instr_obj;
				% get discount curve
                tmp_discount_curve  = debt.get('discount_curve');
                tmp_discount_object = get_sub_object(curve_struct, tmp_discount_curve);

				% Get spread curve
                tmp_spread_curve    = debt.get('spread_curve');
                tmp_spread_object 	= get_sub_object(curve_struct, tmp_spread_curve);

				% Calc value
				debt = debt.calc_value(tmp_discount_object,tmp_spread_object,tmp_scenario);

                % store debt object in struct:
                instrument_struct( ii ).object = debt;

            % European Option Valuation according to Back-Scholes Model 
            elseif ( strfind(tmp_type,'option') > 0 )    
                % Using Option class
                option = tmp_instr_obj;
                
                % Get relevant objects
                tmp_rf_vola_obj          = get_sub_object(riskfactor_struct, option.get('vola_surface'));
                tmp_underlying_obj   = get_sub_object(index_struct, option.get('underlying'));

                tmp_rf_curve_obj         = get_sub_object(curve_struct, option.get('discount_curve'));
                tmp_vola_surf_obj        = get_sub_object(surface_struct, option.get('vola_surface'));
                % Calibration of Option vola spread 
                if ( option.get('vola_spread') == 0 )
                    option = option.calc_vola_spread(tmp_underlying_obj,tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,valuation_date,path_static);
                end
                % calculate value
                option = option.calc_value(tmp_scenario,tmp_underlying_obj,tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,valuation_date,path_static);

                % store option object in struct:
                    instrument_struct( ii ).object = option;
                % Debug Mode:
                if ( regexp(option.name,'DEBUG') )
                    fprintf('DEBUG for Instrument name %s of type %s \n',option.name,tmp_type);
                    fprintf('\t Underyling Instrument %s \n',tmp_underlying_obj.id);
                    tmp_underlying_obj
                    fprintf('\t Underyling Vola Surface %s \n',tmp_vola_surf_obj.id);
                    tmp_vola_surf_obj
                    fprintf('\t Discount Curve %s \n',tmp_rf_curve_obj.id);
                    tmp_rf_curve_obj
                    fprintf('\t Underyling Vola Risk factor %s \n',tmp_rf_vola_obj.id);
                    tmp_rf_vola_obj
                    fprintf('\t Option %s \n',option.id);
                    option
                end
            % European Swaption Valuation according to Back76 or Bachelier Model 
            elseif ( strfind(tmp_type,'swaption') > 0 )    
                % Using Swaption class
                swaption = tmp_instr_obj;
                % Get relevant objects
                tmp_rf_vola_obj          = get_sub_object(riskfactor_struct, 'RF_VOLA_EQ_DE'); %swaption.get('vola_surface'));
                tmp_rf_curve_obj         = get_sub_object(curve_struct, swaption.get('discount_curve'));
                tmp_vola_surf_obj        = get_sub_object(surface_struct, swaption.get('vola_surface'));
                % Calibration of swaption vola spread            
                if ( swaption.get('vola_spread') == 0 )
                    swaption = swaption.calc_vola_spread(tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,valuation_date);
                end
                % calculate value
                swaption = swaption.calc_value(tmp_scenario,tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,valuation_date);
                % store swaption object in struct:
                    instrument_struct( ii ).object = swaption;
                    
            %Equity Forward valuation
            elseif (strcmp(tmp_type,'forward') )
                % Using forward class
                    forward = tmp_instr_obj;
                 % Get underlying Index / instrument    
                    tmp_underlying = forward.get('underlying_id');
                    [tmp_underlying_object object_ret_code]  = get_sub_object(index_struct, tmp_underlying);
                    if ( object_ret_code == 0 )
                        fprintf('octarisk: WARNING: No index_struct object found for id >>%s<<\n',tmp_underlying_object);
                    end
                % Get discount curve
                    tmp_discount_curve          = forward.get('discount_curve');            
                    tmp_curve_object            = get_sub_object(curve_struct, tmp_discount_curve);	

                %Calculate values of equity forward
                if ( first_eval == 0)
                % Base value
                    forward = forward.calc_value(tmp_curve_object,'base',tmp_underlying_object);
                end
                % calculation of value for scenario               
                    forward = forward.calc_value(tmp_curve_object,tmp_scenario,tmp_underlying_object);

                % store bond object in struct:
                    instrument_struct( ii ).object = forward;
                % Debug Mode:
                if ( regexp(forward.name,'DEBUG') )
                    fprintf('DEBUG for Instrument name %s of type %s \n',forward.name,tmp_type);
                    fprintf('\t Underyling Instrument %s \n',tmp_underlying_object.id);
                    tmp_underlying_object
                    fprintf('\t Discount Curve %s \n',tmp_curve_object.id);
                    tmp_curve_object
                    fprintf('\t Forward %s \n',forward.id);
                    forward
                end    
            % Equity Valuation: Sensitivity based Approach       
            elseif ( strcmp(tmp_type,'sensitivity') == 1 )
            tmp_delta = 0;
            tmp_shift = 0;
            % Using sensitivity class
                sensi               = tmp_instr_obj;
                tmp_sensitivities   = sensi.get('sensitivities');
                tmp_riskfactors     = sensi.get('riskfactors');
                for jj = 1 : 1 : length(tmp_sensitivities)
                    % get riskfactor:
                    tmp_riskfactor = tmp_riskfactors{jj};
                    % get idiosyncratic risk: normal distributed random variable with stddev speficied in special_num
                    if ( strcmp(tmp_riskfactor,'IDIO') == 1 )
                        if ( strcmp(tmp_scenario,'stress'))
                            tmp_shift;
                        else    % append idiosyncratic term only if not a stress risk factor
                            tmp_idio_vola_p_a = sensi.get('idio_vola');
                            tmp_idio_vec = ones(scen_number,1) .* tmp_idio_vola_p_a;
                            tmp_shift = tmp_shift + tmp_sensitivities(jj) .* normrnd(0,tmp_idio_vec ./ sqrt(250/tmp_ts));
                        end
                    % get sensitivity approach shift from underlying riskfactors
                    else
                        tmp_rf_struct_obj    = get_sub_object(riskfactor_struct, tmp_riskfactor);
                        tmp_delta   = tmp_rf_struct_obj.getValue(tmp_scenario);
                        tmp_shift   = tmp_shift + ( tmp_sensitivities(jj) .* tmp_delta );
                    end
                end

                % Calculate new absolute scenario values from Riskfactor PnL depending on riskfactor model
                theo_value   = Riskfactor.get_abs_values('GBM', tmp_shift, sensi.getValue('base'));

                % store values in sensitivity object:
                if ( strcmp(tmp_scenario,'stress'))
                    sensi = sensi.set('value_stress',theo_value);
                else            
                    sensi = sensi.set('value_mc',theo_value,'timestep_mc',tmp_scenario);           
                end
                % store bond object in struct:
                    instrument_struct( ii ).object = sensi;
                    
            
            % Synthetic Instrument Valuation: synthetic value is linear combination of underlying instrument values      
            elseif ( strcmp(tmp_type,'synthetic') == 1 )
                % get values of underlying instrument and weigh them by their sensitivity
                tmp_value_base      = 0;
                tmp_value           = 0;
                % Using sensitivity class
                synth               = tmp_instr_obj;
                tmp_weights         = synth.get('weights');
                tmp_instruments     = synth.get('instruments');
                tmp_currency        = synth.get('currency');
                % summing values over all underlying instruments
                for jj = 1 : 1 : length(tmp_weights)
                    % get underlying instrument:
                    tmp_underlying              = tmp_instruments{jj};
                    [und_obj  object_ret_code]  = get_sub_object(instrument_struct, tmp_underlying);
                    if ( object_ret_code == 0 )
                        fprintf('octarisk: WARNING: No instrument_struct object found for id >>%s<<\n',tmp_underlying);
                    end
                    % Get instrument Value from full valuation instrument_struct:
                    % absolute values from full valuation
                    underlying_value_base       = und_obj.getValue('base');                 
                    underlying_value_vec        = und_obj.getValue(tmp_scenario);  
                    % Get FX rate:
                    tmp_underlying_currency = und_obj.get('currency'); 
                    if ( strcmp(tmp_underlying_currency,tmp_currency) == 1 )
                        tmp_fx_rate_base    = 1;
                        tmp_fx_value        = 1; %ones(scen_number,1);
                    else
                        %Conversion of currency:;
                        tmp_fx_index = strcat('FX_', tmp_currency, tmp_underlying_currency);
                        tmp_fx_struct_obj = get_sub_object(index_struct, tmp_fx_index);
                        tmp_fx_rate_base  = tmp_fx_struct_obj.getValue('base');
                        tmp_fx_value      = tmp_fx_struct_obj.getValue(tmp_scenario);
                    end
                    tmp_value_base      = tmp_value_base    + tmp_weights(jj) .* underlying_value_base ./ tmp_fx_rate_base;
                    tmp_value           = tmp_value      + tmp_weights(jj) .* underlying_value_vec ./ tmp_fx_value;
                end

                % store values in sensitivity object:
                if ( first_eval == 0)
                    synth = synth.set('value_base',tmp_value_base);
                end
                if ( strcmp(tmp_scenario,'stress'))
                    synth = synth.set('value_stress',tmp_value);
                else                    
                    synth = synth.set('value_mc',tmp_value,'timestep_mc',tmp_scenario);
                end
                % store bond object in struct:
                    instrument_struct( ii ).object = synth;
                    
            % Cashflow Valuation: summing net present value of all cashflows according to cashflowdates
            elseif ( sum(strcmp(tmp_type,'bond')) > 0 ) 
                % Using Bond class
                    bond = tmp_instr_obj;
                % a) Get curve parameters    
                  % get discount curve
                    tmp_discount_curve  = bond.get('discount_curve');
                    [tmp_curve_object object_ret_code]    = get_sub_object(curve_struct, tmp_discount_curve); 
                    if ( object_ret_code == 0 )
                        fprintf('octarisk: WARNING: No curve_struct object found for id >>%s<<\n',tmp_discount_curve);
                    end
                  % Get spread curve
                    tmp_spread_curve    = bond.get('spread_curve');
                    [tmp_spread_object object_ret_code] 	= get_sub_object(curve_struct, tmp_spread_curve);
                    if ( object_ret_code == 0 )
                        fprintf('octarisk: WARNING: No curve_struct object found for id >>%s<<\n',tmp_spread_curve);
                    end                    
                % b) Get Cashflow dates and values of instrument depending on type (cash settlement):
                    if( sum(strcmp(tmp_sub_type,{'FRB','SWAP_FIXED','ZCB','CASHFLOW'})) > 0 )       % Fixed Rate Bond instruments (incl. swap fixed leg)
                        % rollout cash flows for all scenarios
                        if ( first_eval == 0)
                            bond = bond.rollout('base',valuation_date);
                        end
                        bond = bond.rollout(tmp_scenario,valuation_date);
                    elseif( strcmp(tmp_sub_type,'FRN') == 1 || strcmp(tmp_sub_type,'SWAP_FLOAT') == 1)       % Floating Rate Notes (incl. swap floating leg)
                         %get reference curve object used for calculating floating rates:
                            tmp_ref_curve   = bond.get('reference_curve');
                            tmp_ref_object 	= get_sub_object(curve_struct, tmp_ref_curve);
                        % rollout cash flows for all scenarios
                            if ( first_eval == 0)
                                bond = bond.rollout('base',tmp_ref_object,valuation_date);
                            end
                            bond = bond.rollout(tmp_scenario,tmp_ref_object,valuation_date);         
                    end 
                    
                % c) Calculate spread over yield (if not already run...)
                    if ( bond.get('calibration_flag') == 0 )
                        bond = bond.calc_spread_over_yield(tmp_curve_object,tmp_spread_object,valuation_date);
                    end
                    
                % d) get net present value of all Cashflows (discounting of all cash flows)
					if ( first_eval == 0)
                        bond = bond.calc_value (valuation_date,tmp_curve_object,tmp_spread_object,'base');
                    end
                    bond = bond.calc_value (valuation_date,tmp_curve_object,tmp_spread_object,tmp_scenario);                                                                                  

                    % store bond object in struct:
                    instrument_struct( ii ).object = bond;
            % Cash  Valuation: Cash is riskless
            elseif ( strcmp(tmp_type,'cash') == 1 ) 
                % Using cash class
                cash = tmp_instr_obj;
                cash = cash.calc_value(tmp_scenario,scen_number);
                % store cash object in struct:
                    instrument_struct( ii ).object = cash;
            end
     % store performance data into cell array
     fulvia_performance{end + 1} = strcat(tmp_id,'_',num2str(scen_number),'_',num2str(toc),' s');
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
  first_eval = 1;
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


% --------------------------------------------------------------------------------------------------------------------
% 6. Portfolio Aggregation
tic;
Total_Portfolios = length( portfolio_struct );
base_value = 0;
idx_figure = 0;
confi = 1 - confidence;
confi_scenario = max(round(confi * mc),1);
persistent aggr_key_struct;
position_failed_cell = {};
% before looping via all portfolio make one time Harrel Davis Vector:
% HD VaR only if number of scenarios < hd_limit
if ( mc < hd_limit )
    % take values from file in static folder, if already calculated
    tmp_filename = strcat(path_static,'/hd_vec_',num2str(mc),'.mat');
    if ( exist(tmp_filename,'file'))
        fprintf('Taking file >>%s<< with HD vector in static folder\n',tmp_filename);
        tmp_load_struct = load(tmp_filename);
        hd_vec= tmp_load_struct.hd_vec;
    else % otherwise calculate HD vector and save it to static folder
        fprintf('New HD vector is calculated for %d MC scenarios and saved in static foler\n',mc);
        minhd           = min(2*confi_scenario+1,mc);
        hd_vec_min      = zeros(max(confi_scenario-500,0)-1,1);
        hd_vec_max      = zeros(mc-min(confi_scenario+500,mc)-1,1);
        tt              = max(confi_scenario-500,0):1:min(confi_scenario+500,mc);
        hd_vec_func     = harrell_davis_weight(mc,tt,confi)';
        hd_vec          = [hd_vec_min ; hd_vec_func ; hd_vec_max ];
        save ('-v7',tmp_filename,'hd_vec');
    end
    %size_hdvec = size(hd_vec);
end
% a) loop over all portfolios (outer loop) and via all positions (inner loop)
for mm = 1 : 1 : length( portfolio_struct )
    %disp('Aggregation for Portfolio ');
    %mm
    tmp_port_id = portfolio_struct( mm ).id;
    tmp_port_name = portfolio_struct( mm ).name;
    tmp_port_description = portfolio_struct( mm ).description;
    fund_currency = portfolio_struct( mm ).currency;    
    clear position_struct;
    position_struct = struct();
    position_struct = portfolio_struct( mm ).position;
    portfolio_value = 0;
    PositionStructlength = length( position_struct  );
    for ii = 1 : 1 : length( position_struct  )
        tmp_id = position_struct( ii ).id;
        tmp_quantity = position_struct( ii ).quantity;
        try	% trying to find position in valuated instruments
			tmp_instr_object = get_sub_object(instrument_struct, tmp_id);		
			tmp_value = tmp_instr_object.getValue('base');
			tmp_currency = tmp_instr_object.get('currency'); 

			% conversion of position to fund_currency
			if ( strcmp(tmp_currency,fund_currency) == 1 )
					tmp_fx_rate = 1;
			else
					tmp_fx_index = strcat('FX_',fund_currency, tmp_currency);
					tmp_fx_struct_obj = get_sub_object(index_struct, tmp_fx_index);
					tmp_fx_rate = tmp_fx_struct_obj.getValue('base');
			end        
			position_struct( ii ).basevalue = tmp_value .* tmp_quantity ./ tmp_fx_rate;
			portfolio_value = portfolio_value + tmp_value .* tmp_quantity  ./ tmp_fx_rate;
		catch	% if instrument not found raise warning and populate cell
			fprintf('Instrument ID %s not found for position. There was an error: %s\n',tmp_id,lasterr);
			position_failed_cell{ length(position_failed_cell) + 1 } =  tmp_id;
		end
    end
    
    base_value = portfolio_value

    % Fileoutput:
    filename = strcat(path_reports,'/VaR_report_',runcode,'_',tmp_port_id,'.txt');
    fid = fopen (filename, 'w');

    fprintf('==================================================================== \n');
    fprintf('=== Risk measures report for Portfolio %s ===\n',tmp_port_id);
    fprintf('Portfolio currency: %s \n',fund_currency);
    
    fprintf(fid, '==================================================================== \n');
    fprintf(fid, '=== Risk measures report for Portfolio %s ===\n',tmp_port_id);
    fprintf(fid, 'Portfolio name: %s \n',tmp_port_name);
    fprintf(fid, 'Portfolio description: %s \n',tmp_port_description);
    fprintf(fid, 'VaR calculated at %2.1f%% confidence intervall: \n',confidence.*100);
    fprintf(fid, 'Number of Monte Carlo Scenarios: %i \n', mc);
    fprintf(fid, 'Valuation Date: %s \n',datestr(valuation_date));
    fprintf(fid, 'Portfolio currency: %s \n',fund_currency);
    fprintf(fid, 'Portfolio base value: %9.2f %s \n',base_value,fund_currency);   
    fprintf(fid, '\n');
    fprintf(fid, '=====    MC RESULTS    ===== \n');
%   ========================================   Loop via all MC scenarios    ================================= 
for kk = 1 : 1 : length( scenario_set )      % loop via all MC time steps
    tmp_scen_set  = scenario_set{ kk };    % get timestep string
 
  % ##############################    BEGIN  MC REPORTS    ##############################
  if ~( strcmp(tmp_scen_set,'stress') )     % MC scenario
    tmp_ts      = scenario_ts_days(kk);  % get timestep days 
    fprintf('Aggregation for time step: %d \n',tmp_ts);
    fprintf('Aggregation for scenario set: %s \n',tmp_scen_set);     
    fprintf(fid, 'for time step: %s \n',tmp_scen_set);
    fprintf(fid, '\n');    
    portfolio_shock      = zeros(mc,1);
    %  Loop via all positions
        for ii = 1 : 1 : length( position_struct )
            tmp_id = position_struct( ii ).id;
            tmp_quantity = position_struct( ii ).quantity;
			try
				% get instrument data: get Position's Riskfactors and Sensitivities
				tmp_instr_object = get_sub_object(instrument_struct, tmp_id);
				tmp_value = tmp_instr_object.getValue('base');
				tmp_currency = tmp_instr_object.get('currency');
				% Get instrument Value from full valuation instrument_struct:
				% absolute values from full valuation
				new_value_vec_shock      = tmp_instr_object.getValue(tmp_scen_set);              
			   
                
				% Get FX rate:
				if ( strcmp(fund_currency,tmp_currency) == 1 )
					tmp_fx_value_shock   = 1;
				else
					%disp( ' Conversion of currency: ');
					tmp_fx_index   		= strcat('FX_', fund_currency, tmp_currency);
					tmp_fx_struct_obj   = get_sub_object(index_struct, tmp_fx_index);
					tmp_fx_rate_base    = tmp_fx_struct_obj.getValue('base');
					tmp_fx_value_shock  = tmp_fx_struct_obj.getValue(tmp_scen_set);   
				end
				  
				% Store new Values in Position's struct
				pos_vec_shock 	= new_value_vec_shock .* sign(tmp_quantity) ./ tmp_fx_value_shock; % convert position PnL into fund currency
				octamat = [  pos_vec_shock ] ;
				position_struct( ii ).mc_scenarios.octamat = octamat; 
				portfolio_shock = portfolio_shock +  tmp_quantity .* new_value_vec_shock ./ tmp_fx_value_shock;
            catch	% if instrument not found raise warning and populate cell
				fprintf('Instrument ID %s not found for position. There was an error: %s\n',tmp_id,lasterr);
				position_failed_cell{ length(position_failed_cell) + 1 } =  tmp_id;
			end
        end


  % b.) VaR Calculation
  %  i.) sort arrays
  endstaende_reldiff_shock = portfolio_shock ./ base_value;
  endstaende_sort_shock    = sort(endstaende_reldiff_shock);
  [portfolio_shock_sort scen_order_shock] = sort(portfolio_shock');
  p_l_absolut_shock        = portfolio_shock_sort - base_value;
  % Preparing vector for extreme value theory VAR and ES
  
  % only apply EVT if there is some risk in MC data
  if ( abs(std(p_l_absolut_shock)) > 0)
    confi_scenario_evt_95   = round(0.025 * mc);
    evt_tail_shock          = p_l_absolut_shock(1:confi_scenario_evt_95)'
    % Calculate VAR and ES from GPD:
    u = min(-evt_tail_shock);
    [aa bb cc] = size(evt_tail_shock);
    [chi sigma] = calibrate_evt_gpd(-evt_tail_shock);
    nu = length(evt_tail_shock);   
    [VAR_EVT_shock ES_EVT_shock]        = get_gpd_var(chi, sigma, u, gpd_confidence_levels, mc, nu);        
   else % apply dummy values
    [VAR_EVT_shock ES_EVT_shock]    = horzcat(zeros(length(gpd_confidence_levels),1), zeros(length(gpd_confidence_levels),1));
   end


  % Preparing direct VAR measures:
    VAR50_shock      = p_l_absolut_shock(round(0.5*mc));
    VAR70_shock      = p_l_absolut_shock(round(0.3*mc));
    VAR90_shock      = p_l_absolut_shock(round(0.10*mc));
    VAR95_shock      = p_l_absolut_shock(round(0.05*mc));
    VAR975_shock     = p_l_absolut_shock(round(0.025*mc));
    VAR99_shock      = p_l_absolut_shock(ceil(0.01*mc));
    VAR999_shock     = p_l_absolut_shock(ceil(0.001*mc));
    VAR9999_shock    = p_l_absolut_shock(ceil(0.0001*mc));


  % ii.) Get Value of confidence scenario

  confi_scenarionumber_shock = scen_order_shock(confi_scenario);
  skewness_shock           = skewness(endstaende_reldiff_shock);
  kurtosis_shock           = kurtosis(endstaende_reldiff_shock);
  fprintf('Scenarionumber according to confidence intervall: %d\n',confi_scenarionumber_shock);
  fprintf('MC scenarios portfolio skewness: %2.2f\n',skewness_shock);
  fprintf('MC scenarios portfolio kurtosis: %2.2f\n',kurtosis_shock);

  % iii.) Extract confidence scenarionumbers around quantile scenario
  confi_scenarionumber_shock_p1 = scen_order_shock(confi_scenario + 1);
  confi_scenarionumber_shock_p2 = scen_order_shock(confi_scenario + 2);
  confi_scenarionumber_shock_m1 = scen_order_shock(confi_scenario - 1);
  confi_scenarionumber_shock_m2 = scen_order_shock(confi_scenario - 2);

  % iv.) make vector with Harrel-Davis Weights
  % HD VaR only if number of scenarios < hd_limit
  if ( mc < hd_limit )
  size_hdvec = size(portfolio_shock_sort);
    mc_var_shock_value_abs    = dot(hd_vec,portfolio_shock_sort);
    mc_var_shock_value_rel    = dot(hd_vec,endstaende_sort_shock);
    mc_var_shock_diff_hd      = abs(portfolio_shock_sort(confi_scenario) - mc_var_shock_value_abs)
  else
    mc_var_shock_value_abs    = portfolio_shock_sort(confi_scenario);
    mc_var_shock_value_rel    = endstaende_sort_shock(confi_scenario);
  end

  mc_var_shock_pct  = -(1 - mc_var_shock_value_rel);
  mc_var_shock      = base_value - mc_var_shock_value_abs;


  % d) Calculate Expected Shortfall as average of losses in sorted profit and loss vector from [1:confi_scenario-1]:
  mc_es_shock			= base_value - mean(portfolio_shock_sort(1:confi_scenario-1));
  mc_es_shock_pct		= -(1 - mean(endstaende_sort_shock(1:confi_scenario-1)));

  % e) Print Report including position VaRs

  % Printing P&L test statistics
  fprintf(fid, 'Test statistics on portfolio level:\n');
  fprintf(fid, '|MC %s Tail scenario number\t |%i| \n',tmp_scen_set,confi_scenarionumber_shock);
  fprintf(fid, '|MC %s P&L skewness  \t\t\t |%2.1f| \n',tmp_scen_set,skewness_shock);
  fprintf(fid, '|MC %s P&L kurtosis  \t\t\t |%2.1f| \n',tmp_scen_set,kurtosis_shock);
  % -------------------------------------------------------------------------------------------------------------------- 

  % 7.0) Print Report for all Risk factor scenario values around confidence scenario
  fprintf(fid, 'Risk factor scenario values: \n');
  fprintf(fid, '|VaR %s scenario delta |RF_ID|Scen-2|Scen-1|Base|Scen+1|Scen+2|\n',tmp_scen_set);
  for ii = 1 : 1 : length( riskfactor_cell) % loop through all MC risk factors only
    tmp_object      = get_sub_object(riskfactor_struct, riskfactor_cell{ii});
    tmp_delta_shock   = tmp_object.getValue(tmp_scen_set);
    fprintf(fid, '|VaR %s scenario delta |%s|%1.3f|%1.3f|%1.3f|%1.3f|%1.3f|\n',tmp_scen_set,tmp_id,tmp_delta_shock(confi_scenarionumber_shock_m2),tmp_delta_shock(confi_scenarionumber_shock_m1),tmp_delta_shock(confi_scenarionumber_shock),tmp_delta_shock(confi_scenarionumber_shock_p1),tmp_delta_shock(confi_scenarionumber_shock_p2));
  end
  % 7.1) Print Report for all Positions:
  total_var_undiversified = 0;


  aggr_key_struct=struct();

  % reset vectors for charts of riskiest instruments and positions
  pie_chart_values_instr_shock = [];
  pie_chart_desc_instr_shock = {};
  pie_chart_values_pos_shock = [];
  pie_chart_desc_pos_shock = {};
    
  fprintf(fid, '\n');
  fprintf(fid, 'Sensitivities on Positional Level: \n');
  for ii = 1 : 1 : length( position_struct )
    tmp_id = position_struct( ii ).id;
    try
        tmp_instr_object = get_sub_object(instrument_struct, tmp_id);		
		octamat = position_struct( ii ).mc_scenarios.octamat;
        tmp_values_shock = sort(octamat);
		tmp_value = tmp_instr_object.getValue('base');
		tmp_name = tmp_instr_object.get('name');
		tmp_type = tmp_instr_object.get('type'); 
		tmp_currency = tmp_instr_object.get('currency'); 
		   
		tmp_quantity            = position_struct( ii ).quantity;
		tmp_basevalue           = position_struct( ii ).basevalue;
		tmp_decomp_var_shock     = -(octamat(confi_scenarionumber_shock) * tmp_quantity .* sign(tmp_quantity) - tmp_basevalue); 
		% Get pos var
		tmp_pos_var = (tmp_basevalue ) - (tmp_values_shock(confi_scenario) * tmp_quantity  * sign(tmp_quantity));
		
		% Aggregate positional data according to aggregation keys:
		for jj = 1 : 1 : length(aggregation_key)
			if ( ii == 1)   % first use of struct
				tmp_aggr_cell = {};
				aggregation_mat = [];
				aggregation_decomp_shock = 0;
			else            % reading from struct from previous instrument
				tmp_aggr_cell           = aggr_key_struct( jj ).key_values;
				aggregation_mat         = [aggr_key_struct( jj ).aggregation_mat];
				aggregation_decomp_shock  = [aggr_key_struct( jj ).aggregation_decomp_shock];
			end
			if (isProp(tmp_instr_object,aggregation_key{jj}) == 1)
				tmp_aggr_key_value = getfield(tmp_instr_object,aggregation_key{jj});
				if (ischar(tmp_aggr_key_value))
					if ( strcmp(tmp_aggr_key_value,'') == 1 )
						tmp_aggr_key_value = 'Unknown';
					end
					% Assign P&L to aggregation key
					% check, wether aggr key already exist in cell array
					if (sum(strcmp(tmp_aggr_cell,tmp_aggr_key_value)) > 0)   % aggregation key found
						tmp_vec_xx = 1:1:length(tmp_aggr_cell);
						tmp_aggr_key_index = strcmp(tmp_aggr_cell,tmp_aggr_key_value)*tmp_vec_xx';
						aggregation_mat(:,tmp_aggr_key_index) = aggregation_mat(:,tmp_aggr_key_index) + (octamat .* tmp_quantity .* sign(tmp_quantity) - tmp_basevalue);
						aggregation_decomp_shock(tmp_aggr_key_index) = aggregation_decomp_shock(tmp_aggr_key_index) + tmp_decomp_var_shock;
					else    % aggregation key not found -> set value for first time
						tmp_aggr_cell{end+1} = tmp_aggr_key_value;
						tmp_aggr_key_index = length(tmp_aggr_cell);
						aggregation_mat(:,tmp_aggr_key_index)       = (octamat .* tmp_quantity .* sign(tmp_quantity)  - tmp_basevalue);
						aggregation_decomp_shock(tmp_aggr_key_index)  = tmp_decomp_var_shock;
					end
				else
					disp('Aggregation key not valid');
				end
			else
				disp('Aggregation key not found in instrument definition');
			end
			% storing updated values in struct
			aggr_key_struct( jj ).key_name = aggregation_key{jj};
			aggr_key_struct( jj ).key_values = tmp_aggr_cell;
			aggr_key_struct( jj ).aggregation_mat = aggregation_mat;
			aggr_key_struct( jj ).aggregation_decomp_shock = aggregation_decomp_shock;
		end
		
	   
		total_var_undiversified = total_var_undiversified + tmp_pos_var;
		% Store Values for piechart (Except CASH):
		pie_chart_values_instr_shock(ii) = round((tmp_pos_var) / abs(tmp_quantity));
		pie_chart_desc_instr_shock(ii) = cellstr( strcat(tmp_instr_object.id));
		pie_chart_values_pos_shock(ii) = round((tmp_decomp_var_shock) );
		pie_chart_desc_pos_shock(ii) = cellstr( strcat(tmp_instr_object.id));
    catch	% if instrument not found raise warning and populate cell
		fprintf('Instrument ID %s not found for position. There was an error: %s\n',tmp_id,lasterr);
		position_failed_cell{ length(position_failed_cell) + 1 } =  tmp_id;
	end
  end  % end loop for all positions
  % prepare vector for piechart:
  [pie_chart_values_sorted_instr_shock sorted_numbers_instr_shock ] = sort(pie_chart_values_instr_shock);
  [pie_chart_values_sorted_pos_shock sorted_numbers_pos_shock ] = sort(pie_chart_values_pos_shock);
  idx = 1;

  % plot only maximum 6 highest values
  %for ii = length(pie_chart_values_instr_shock):-1:max(0,length(pie_chart_values_instr_shock)-5)
  for ii = 1:1:min(length(pie_chart_values_instr_shock),6)
    pie_chart_values_plot_instr_shock(idx)   = pie_chart_values_sorted_instr_shock(ii) ;
    pie_chart_desc_plot_instr_shock(idx)     = pie_chart_desc_instr_shock(sorted_numbers_instr_shock(ii));
    pie_chart_values_plot_pos_shock(idx)     = pie_chart_values_sorted_pos_shock(ii) ;
    pie_chart_desc_plot_pos_shock(idx)       = pie_chart_desc_pos_shock(sorted_numbers_pos_shock(ii));
    idx = idx + 1;
  end
  plot_vec_pie = zeros(1,length(pie_chart_values_plot_instr_shock));
  plot_vec_pie(1) = 1;



  fprintf(fid, '\n');
  % Print aggregation key report:  
  fprintf(fid, '=== Aggregation Key VAR === \n');  
  fprintf('=== Aggregation Key VAR === \n');  
  for jj = 1:1:length(aggr_key_struct)
    % load values from aggr_key_struct:
    tmp_aggr_cell               = aggr_key_struct( jj ).key_values;
    tmp_aggr_key_name           = aggr_key_struct( jj ).key_name;
    tmp_aggregation_mat         = [aggr_key_struct( jj ).aggregation_mat];
    tmp_aggregation_decomp_shock  = [aggr_key_struct( jj ).aggregation_decomp_shock];
    fprintf(' Risk aggregation for key: %s \n', tmp_aggr_key_name);
    fprintf('|VaR %s | Key value   | Standalone VAR \t | Decomp VAR|\n',tmp_scen_set);
    fprintf(fid, ' Risk aggregation for key: %s \n', tmp_aggr_key_name);
    fprintf(fid, '|VaR %s | Key value   | Standalone VAR \t | Decomp VAR|\n',tmp_scen_set);
    for ii = 1 : 1 : length(tmp_aggr_cell)
        tmp_aggr_key_value          = tmp_aggr_cell{ii};
        tmp_sorted_aggr_mat			= sort(tmp_aggregation_mat(:,ii));
        tmp_standalone_aggr_key_var = abs(tmp_sorted_aggr_mat(confi_scenario));
        tmp_decomp_aggr_key_var     = tmp_aggregation_decomp_shock(ii);
        fprintf('|VaR %s | %s \t |%9.2f %s \t |%9.2f %s|\n',tmp_scen_set,tmp_aggr_key_value,tmp_standalone_aggr_key_var,fund_currency,tmp_decomp_aggr_key_var,fund_currency);
        fprintf(fid, '|VaR %s | %s \t |%9.2f %s \t |%9.2f %s|\n',tmp_scen_set,tmp_aggr_key_value,tmp_standalone_aggr_key_var,fund_currency,tmp_decomp_aggr_key_var,fund_currency);
    end
  end

  % Print Portfolio reports
  fprintf(fid, '\n');
  fprintf(fid, 'Total VaR undiversified: \n');
  fprintf(fid, '|VaR %s undiversified| |%9.2f %s|\n',tmp_scen_set,total_var_undiversified,fund_currency);
  fprintf(fid, '\n');
  if ( mc < hd_limit )
    fprintf(fid, '=== Total Portfolio HD-VaR === \n');
    fprintf('=== Total Portfolio HD-VaR === \n');
  else
    fprintf(fid, '=== Total Portfolio VaR === \n');
    fprintf('=== Total Portfolio VaR === \n')
  end
  % Output to file: 
  fprintf(fid, '|Portfolio VaR %s@%2.1f%%| \t |%9.2f%%|\n',tmp_scen_set,confidence.*100,mc_var_shock_pct*100);
  fprintf(fid, '|Portfolio VaR %s@%2.1f%%| \t |%9.2f %s|\n',tmp_scen_set,confidence.*100,mc_var_shock,fund_currency);
  fprintf(fid, '|Portfolio ES  %s@%2.1f%%| \t |%9.2f%%|\n',tmp_scen_set,confidence.*100,mc_es_shock_pct*100);
  fprintf(fid, '|Portfolio ES  %s@%2.1f%%| \t |%9.2f %s|\n\n',tmp_scen_set,confidence.*100,mc_es_shock,fund_currency);
  
  % print EVT VAR and ES to file
  fprintf(fid, '= GPD extreme value VAR and ES: \n');
  for jj = 1 : 1 : length( gpd_confidence_levels )
    fprintf(fid, '|Port EVT VAR  %s@%2.2f%%| \t |%9.2f %s|\n',tmp_scen_set,gpd_confidence_levels(jj).*100,VAR_EVT_shock(jj),fund_currency);
  end
  for jj = 1 : 1 : length( gpd_confidence_levels )
    fprintf(fid, '|Port EVT ES  %s@%2.2f%%| \t |%9.2f %s|\n',tmp_scen_set,gpd_confidence_levels(jj).*100,ES_EVT_shock(jj),fund_currency);
  end
  
  % Output to stdout:
  fprintf('VaR %s@%2.1f%%: \t %9.2f%%\n',tmp_scen_set,confidence.*100,mc_var_shock_pct*100);
  fprintf('VaR %s@%2.1f%%: \t %9.2f %s\n',tmp_scen_set,confidence.*100,mc_var_shock,fund_currency);
  fprintf('ES  %s@%2.1f%%: \t %9.2f%%\n',tmp_scen_set,confidence.*100,mc_es_shock_pct*100);
  fprintf('ES  %s@%2.1f%%: \t %9.2f %s\n\n',tmp_scen_set,confidence.*100,mc_es_shock,fund_currency);
  fprintf('GPD extreme value VAR and ES: \n');
  fprintf('VaR EVT %s@%2.2f%%: \t %9.2f %s\n\n',tmp_scen_set,gpd_confidence_levels(end).*100,VAR_EVT_shock(end),fund_currency);
  fprintf('ES  EVT %s@%2.2f%%: \t %9.2f %s\n\n',tmp_scen_set,gpd_confidence_levels(end).*100,ES_EVT_shock(end),fund_currency);
  fprintf('Low tail VAR: \n');
  fprintf('VaR %s@%2.1f%%: \t %9.2f %s\n',tmp_scen_set,50.0,-VAR50_shock,fund_currency);
  fprintf('VaR %s@%2.1f%%: \t %9.2f %s\n',tmp_scen_set,70.0,-VAR70_shock,fund_currency);
  fprintf('VaR %s@%2.1f%%: \t %9.2f %s\n',tmp_scen_set,90.0,-VAR90_shock,fund_currency);
  fprintf('VaR %s@%2.1f%%: \t %9.2f %s\n',tmp_scen_set,95.0,-VAR95_shock,fund_currency);

  if ( mc < hd_limit )
    fprintf(fid, '\n');
    fprintf(fid, 'Difference to HD-VaR %s:  %9.2f %s\n',tmp_scen_set,mc_var_shock_diff_hd,fund_currency);    
  end
  fprintf(fid, '\n');

  fprintf(fid, 'Total Reduction in VaR via Diversification: \n');
  fprintf(fid, '|Portfolio VaR %s Diversification Effect| |%9.2f%%|\n',tmp_scen_set,(1 - mc_var_shock / total_var_undiversified)*100)

  fprintf(fid, '====================================================================');
  fprintf(fid, '\n');
  aggr = toc;

  % --------------------------------------------------------------------------------------------------------------------
  % 8.  Plotting 
  tic
  if ( plotting == 1 )
	  plot_vec = 1:1:mc;
	  %graphics_toolkit gnuplot;
	  idx_figure = idx_figure + 1;
	  figure(idx_figure);
	  clf;

	  subplot (2, 2, 1)
		hist(endstaende_reldiff_shock,40)
		title_string = {tmp_port_name; tmp_port_description; strcat('Portfolio PnL ',tmp_scen_set);};
		title (title_string,'fontsize',12);
		xlabel('Relative Portfoliovalue');
	  subplot (2, 2, 2)
		plot ( plot_vec, p_l_absolut_shock,'linewidth',2);
		%area ( plot_vec, p_l_absolut_shock,'Facecolor','blue');
		hold on;
		plot ( [1, mc], [-mc_var_shock, -mc_var_shock], '-','linewidth',1);
		hold on;
		plot ( [1, mc], [0, 0], 'r','linewidth',1);
		h=get (gcf, 'currentaxes');
		xlabel('MonteCarlo Scenario');
		set(h,'xtick',[1 mc])
		set(h,'ytick',[min(p_l_absolut_shock) -20000 0 20000 max(p_l_absolut_shock)])
		h=text(0.025*mc,(-1.45*mc_var_shock),num2str(round(-mc_var_shock)));   %add MC Value
		h=text(0.025*mc,(-2.1*mc_var_shock),strcat(num2str(round(mc_var_shock_pct*1000)/10),' %'));   %add MC Value
		%set(h,'fontweight','bold'); %,'rotation',90)
		ylabel(strcat('Absolute PnL (in ',fund_currency,')'));
		title_string = strcat('Portfolio PnL ',tmp_scen_set);
		title (title_string,'fontsize',12);
	  subplot (2, 2, 3)
		pie(pie_chart_values_plot_pos_shock, pie_chart_desc_plot_pos_shock, plot_vec_pie);
		title_string = strcat('Position contribution to VaR',tmp_scen_set);
		title(title_string,'fontsize',12);
		axis ('tic', 'off');    
	  subplot (2, 2, 4)
		pie(pie_chart_values_plot_instr_shock, pie_chart_desc_plot_instr_shock, plot_vec_pie);
		title_string = strcat('Pie Chart of Riskiest Instruments (VaR',tmp_scen_set,')');
		title(title_string,'fontsize',12);
		axis ('tic', 'off');
  end     % end plotting
  plottime = toc; % end plotting
% %#%#%#%#%#%#%#%#%#%#%#%#%#%#%#    END  MC REPORTS    %#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%# 


% %#%#%#%#%#%#%#%#%#%#%#%#%#%#%#    BEGIN  STRESS REPORTS    %#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%# 
elseif ( strcmp(tmp_scen_set,'stress') )     % Stress scenario
    % prepare stresstest plotting and report output
    stresstest_plot_desc = {stresstest_struct.id};
    portfolio_stress    = zeros(no_stresstests,1);
    %  Loop via all positions
    for ii = 1 : 1 : length( position_struct )
        tmp_id = position_struct( ii ).id;
        tmp_quantity = position_struct( ii ).quantity;
        try
			% get instrument data: get Position's Riskfactors and Sensitivities
			tmp_instr_object = get_sub_object(instrument_struct, tmp_id);
			tmp_value = tmp_instr_object.getValue('base');
			tmp_currency = tmp_instr_object.get('currency');
			tmp_name = tmp_instr_object.get('name');
			% Get instrument Value from full valuation instrument_struct:
			% absolute values from full valuation
			new_value_vec_stress    = tmp_instr_object.getValue('stress');

			% Get FX rate:
			if ( strcmp(tmp_currency,fund_currency) == 1 )
				tmp_fx_value_stress = 1;
			else
				%disp( ' Conversion of currency: ');
				tmp_fx_index   = strcat('FX_', fund_currency, tmp_currency);
				tmp_fx_struct_obj   = get_sub_object(index_struct, tmp_fx_index);
				tmp_fx_rate_base    = tmp_fx_struct_obj.getValue('base');
				tmp_fx_value_stress = tmp_fx_struct_obj.getValue('stress');                       
			end
			  
			% Store new Values in Position's struct
			pos_vec_stress  = new_value_vec_stress .*  sign(tmp_quantity) ./ tmp_fx_value_stress;
			octamat = [  pos_vec_shock ] ;
			position_struct( ii ).stresstests = pos_vec_stress;
			portfolio_stress = portfolio_stress + new_value_vec_stress .*  tmp_quantity ./ tmp_fx_value_stress;
		catch	% if instrument not found raise warning and populate cell
			fprintf('Instrument ID %s not found for position. There was an error: %s\n',tmp_id,lasterr);
			position_failed_cell{ length(position_failed_cell) + 1 } =  tmp_id;
		end	
    end
    % Calc absolute and relative stress values
    p_l_absolut_stress      = portfolio_stress - base_value;
    p_l_relativ_stress      = (portfolio_stress - base_value )./ base_value;

    fprintf(fid, '\n');
    fprintf(fid, '=====    STRESS RESULTS    ===== \n');
    fprintf(fid, '\n');
    fprintf(fid, 'Sensitivities on Positional Level: \n');
    for ii = 1 : 1 : length( position_struct )  
        tmp_id = position_struct( ii ).id;
        try
			% get instrument data: get Position's Riskfactors and Sensitivities
			tmp_instr_object = get_sub_object(instrument_struct, tmp_id);
			tmp_values_stress = [position_struct( ii ).stresstests];
			% tmp_value = tmp_instr_object.getValue('base');
			% tmp_currency = tmp_instr_object.get('currency');
			tmp_name = tmp_instr_object.get('name');

			% Get instrument IR and Spread sensitivity from stresstests 1-4:
			if ~( tmp_values_stress(end) == 0 ) % test for base values 0 (e.g. matured option )
				tmp_values_stress_rel = 100.*(tmp_values_stress - tmp_values_stress(end)) ./ tmp_values_stress(end);
			else
				tmp_values_stress_rel = zeros(length(tmp_values_stress),1);
			end
			tmp_ir_sensitivity = (abs(tmp_values_stress_rel(1)) + abs(tmp_values_stress_rel(2)))/2;
			tmp_spread_sensitivity = (abs(tmp_values_stress_rel(3)) + abs(tmp_values_stress_rel(4)))/2;
			fprintf(fid, '|Sensi ModDuration \t\t |%s|%s| = \t |%3.2f%%|\n',tmp_name,tmp_id,tmp_ir_sensitivity);
			fprintf(fid, '|Sensi ModSpreadDur \t |%s|%s| = \t |%3.2f%%|\n',tmp_name,tmp_id,tmp_spread_sensitivity);
        catch	% if instrument not found raise warning and populate cell
			fprintf('Instrument ID %s not found for position. There was an error: %s\n',tmp_id,lasterr);
			position_failed_cell{ length(position_failed_cell) + 1 } =  tmp_id;
		end	
    end 
 
    fprintf(fid, 'Stress test results:\n');
    for xx=1:1:no_stresstests
        fprintf(fid, 'Relative PnL in Stresstest: |%s| \t |%3.2f%%|\n',stresstest_plot_desc{xx},p_l_relativ_stress(xx).*100);
    end
    fprintf(fid, '\n');

    if ( plotting == 1 )
        tic;   
        xx = 1:1:(no_stresstests-1);
        % Plot Stresstestdata
        idx_figure = idx_figure + 1;
        figure(idx_figure);
        clf;
        barh(p_l_relativ_stress(1:end-1), 'facecolor', 'blue');
        h=get (gcf, 'currentaxes');
        set(h,'ytick',xx);
        set(h,'yticklabel',stresstest_plot_desc(1:end-1));
        xlabel('Relative PnL');
        %ylabel('Value');
        title('Relative Stresstest Scenario Results','fontsize',12);
        plottime = plottime + toc;
    end     % end plotting
end     % close if loop MC / Stress scenarioset

% #####################################    END  STRESS REPORTS    #####################################

end % close kk loop: 
position_failed_cell = unique(position_failed_cell);
if ( length(position_failed_cell) >= 1 )
    fprintf('\nWARNING: Failed aggregation for %d positions: \n',length(position_failed_cell));
    position_failed_cell
else
    fprintf('\nSUCCESS: All positions aggregated.\n');
end

% Output to stdout:
fprintf('\n');
fprintf('=== Total Time for Calculation ===\n');
fprintf('Total time for parsing input files:  %6.2f s\n', parseinput);
fprintf('Total time for MC scenario generation:  %6.2f s\n', scengen)
fprintf('Total time for Curve generation:  %6.2f s\n', curve_gen_time)
fprintf('Total time for full valuation:  %6.2f s\n', fulvia);
fprintf('Total time for aggregation:  %6.2f s\n', aggr);
fprintf('Total time for plotting:  %6.2f s\n', plottime);
fprintf('Total time for saving data:  %6.2f s\n', saving_time);
totaltime = round((parseinput + scengen + curve_gen_time + fulvia + aggr + plottime + saving_time)*10)/10;
fprintf(fid, 'Total Runtime:  %6.2f s\n',totaltime);
fprintf('Total Runtime:  %6.2f s\n',totaltime);
% Close file
fclose (fid);
end % closing main portfolioloop mm

% Plot correlation mismatches:
if ( plotting == 1 && mc_scen_analysis == 1 )
    M_diff = corr_matrix .- corr(R_250);
    M_rs = reshape(M_diff,1,columns(M_diff)^2);
    idx_figure = idx_figure + 1;
    figure(idx_figure);
    clf;
    hist(M_rs,80);
    xlabel('Correlation mismatch');
    ylabel('Occurence');
    title('Absolute correlation settings mismatches overview','fontsize',12);

    idx_figure = idx_figure + 1;
        figure(idx_figure);
    clf;
    x_values = [1 : 1 : columns(M_diff)];
    y_values = [1 : 1 : columns(M_diff)];
    contourf(x_values, y_values, rot90(M_diff));
    xlabel('Risk factor');
    ylabel('Risk factor');
    title('Absolute correlation settings mismatches per risk factor','fontsize',12);
    axis square;
    colorbar;
    xlim([1 columns(M_diff)]);
    ylim([1 columns(M_diff)]);
end

fprintf('\n');
fprintf('=======================================================\n');
fprintf('===   Ended octarisk market risk measurement tool   ===\n');
fprintf('=======================================================\n');
fprintf('\n');

% Final clean up 

    %  move all reports files to an TAR in folder archive
    try
        tarfiles = tar( strcat(path_reports,'/archive_reports_',tmp_timestamp,'.tar'),strcat(path,'/*'));
    end

end     % ending MAIN function octarisk

% III) %#%#%%#         HELPER FUNCTIONS              %#%#
% function for extracting sub-structure from struct object according to id
function  match_struct = get_sub_struct(input_struct, input_id)
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
	    	match_struct = input_struct(matches);
		return;
	else
	    	error(' No matches found for input_id: >>%s<<',input_id);
		return;
	end
end

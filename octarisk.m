## Copyright (C) 2015 Stefan Schloegl <schinzilord@octarisk.com>
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.

## -*- texinfo -*-
## @deftypefn {Function File} {} octarisk (@var{path_working_folder})
##
## Version: 0.0.0, 2015/11/24, Stefan Schloegl:   initial version @* 
##          0.0.1, 2015/12/16, Stefan Schloegl:   added Willow Tree model for pricing american equity options, 
##                                              added volatility surface model for term / moneyness structure of volatility for index vol
##          0.0.2, 2016/01/19, Stefan Schloegl:   added new instrument types FRB, FRN, FAB, ZCB
##                                              added synthetic instruments (linear combinations of other instruments)
##                                              added equity forwards and Black-Karasinski stochastic process
##			0.0.3, 2016/02/05, Stefan Schloegl:	  added spread risk factors, general cash flow pricing 
##			0.0.4, 2016/03/28, Stefan Schloegl:   changed the implementation to object oriented approach (introduced instrument, risk factor classes)
##          0.1.0, 2016/04/02, Stefan Schloegl:   added volatility cube model (Surface class) for tenor / term / moneyness structure of volatility for ir vol
##          0.2.0, 2016/04/19, Stefan Schloegl:   improved the file interface and format for input files (market data, risk factors, instruments, positions, stresstests) 
## @*
## @*
## Calculate Monte-Carlo Value-at-Risk (VAR) and Expected Shortfall (ES) for instruments, positions and portfolios at a given confidence level on 
## 1D and 250D time horizon with a full valuation approach.
##
## See octarisk documentation for further information.
##
## @*
## Input files in csv format:
## @itemize @bullet
## @item Instruments data: specification of instrument universe (name, id, market value, underlying risk factor, cash flows etc.)
## @item Riskfactors data: specification of risk factors (name, id, stochastic model, statistic parameters)
## @item Positions data: specification of portfolio and position data (portfolio id, instrument id, position size)
## @item Stresstest data: specification of stresstest risk factor shocks (stresstest name, risk factor shock values and types)
## @item Covariance matrix: covariance matrix of all risk factors
## @item Volatility surfaces (index volatility: term vs. moneyness, call moneyness spot / strike, linear interpolation and constant extrapolation)
## @end itemize
## @*
## Output data:
## @itemize @bullet
## @item portfolio report: instruments and position VAR and ES, diversification effects
## @item profit and loss distributions: plot of profit and loss histogramm and distribution, most important positions and instruments
## @end itemize
## @*
## Supported instrument types:
## @itemize @bullet
## @item equity (stocks and funds priced via multi-factor model and idiosyncratic risk)
## @item commodity (physical and funds priced via multi-factor model and idiosyncratic risk)
## @item real estate (stocks and funds priced via multi-factor model and idiosyncratic risk)
## @item custom cash flow instruments (NPV of all custom CFs) 
## @item bond funds priced via duration-based sensitivity approach
## @item fixed rate bonds (NPV of all CFs)
## @item floating rate notes (scenario dependent cash flow values, NPV of all CFs)
## @item fixed amortizing bonds (either annuity bonds or amortizable bonds, NPV of all CFs)
## @item zero coupon bonds (NPV of notional)
## @item European equity options (Black-Scholes model)
## @item American equity options (Willow Tree model)
## @item European swaptions (Black76 and Bachelier model)
## @item Equity forward
## @item Synthetic instruments (linear combinations of other valuated instruments)
## @end itemize
## @*
## Supported stochastic processes for risk factors:
## @itemize @bullet
## @item Geometric Brownian Motion 
## @item Black-Karasinski process
## @item Brownian Motion 
## @item Ornstein-Uhlenbeck process
## @item Square-root diffusion process 
## @end itemize
## @*
## Supported copulas for MC scenario generation:
## @itemize @bullet
## @item Gaussian copula
## @item t-copula with one parameter specification for common degrees of freedom
## @end itemize
## @*
## Further functionality will be implemented in the future (e.g. inflation linked instruments)
## @seealso{option_willowtree, option_bs, harrell_davis_weight, swaption_black76, pricing_forward, rollout_cashflows, scenario_generation_MC}
## @end deftypefn

function octarisk(path_working_folder)

% ###########################################################################################################
% Content:
% 0) #######            DEFINITION OF VARIABLES    ####
% 1. general variables
% 2. VAR specific variables

% I) #######            INPUT                      ####
%   1. Processing Instruments data
%   2. Processing Riskfactor data
%   3. Processing Positions data
%   4. Processing Stresstest data

% II) #######           CALCULATION                ####
%   1. Model Riskfactor Scenario Generation
%       a) Load input correlation matrix
%       b) Get distribution parameters from riskfactors
%       c) call MC scenario generations
%   2. Monte Carlo Riskfactor Simulation
%   3. Setup Stress test definitions
%   4. Process yield curves: Generate struct with riskfactor yield curves 
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

% III) #######         HELPER FUNCTIONS              ####

% ###########################################################################################################
% ***********************************************************************************************************
% ###########################################################################################################
fprintf('\n');
fprintf('=======================================================\n');
fprintf('=== Starting octarisk market risk measurement tool  ===\n');
fprintf('=======================================================\n');
fprintf('\n');

% 0) #######            DEFINITION OF VARIABLES    ####
% 1. general variables -> path dependent on operating system
path = path_working_folder;   % general load and save path for all input and output files

path_output = strcat(path,'/output');
path_output_instruments = strcat(path_output,'/instruments');
path_output_riskfactors = strcat(path_output,'/riskfactors');
path_output_stresstests = strcat(path_output,'/stresstests');
path_output_positions = strcat(path_output,'/positions');
path_reports = strcat(path,'/output/reports');
path_archive = strcat(path,'/archive');
path_input = strcat(path,'/input');
path_mktdata = strcat(path,'/mktdata');
mkdir(path_output);
mkdir(path_output_instruments);
mkdir(path_output_riskfactors);
mkdir(path_output_stresstests);
mkdir(path_output_positions);
mkdir(path_archive);
mkdir(path_input);
mkdir(path_mktdata);
mkdir(path_reports);
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
            endif
    end
end    


% set filenames for input:
input_filename_instruments = 'instruments.csv';
input_filename_corr_matrix = strcat(path_mktdata,'/corr24.dat');
input_filename_stresstests = 'stresstests.csv';
input_filename_riskfactors = 'riskfactors.csv';
input_filename_positions = 'positions.csv';

% set filenames for vola surfaces
input_filename_vola_index = 'vol_index_';
input_filename_vola_ir = 'vol_ir_';

% set general variables
plotting = 1;           % switch for plotting data (0/1)
saving = 0;             % switch for saving *.mat files (WARNING: that takes a long time for 50k scenarios and multiple instruments!)
archive_flag = 0;       % switch for archiving input files to the archive folder (as .tar). This takes some seconds.

% load packages
pkg load statistics;	% load statistics package (needed in scenario_generation_MC)
pkg load financial;		% load financial packages (needed throughout all scripts)

% 2. VAR specific variables
mc = 50000              % number of MonteCarlo scenarios
hd_limit = 50001;       % below this MC limit Harrel-Davis estimator will be used
confidence = 0.999      % level of confidence vor MC VAR calculation
copulatype = 't'        % Gaussian  or t-Copula  ( copulatype in ['Gaussian','t'])
nu = 10                 % single parameter nu for t-Copula 
valuation_date = today; % valuation date
base_currency  = 'EUR'  % base reporting currency
aggregation_key = {'asset_class','currency','id'}    % aggregation key
mc_timesteps    = {'10d'}                % MC timesteps
scenario_set    = [mc_timesteps,'stress'];          % append stress scenarios

% specify unique runcode and timestamp:
runcode = '2015Q4'; %substr(md5sum(num2str(time()),true),-6)
timestamp = strftime ('%Y%m%d_%H%M%S', localtime (time ()))

first_eval      = 0;
% I) #######            INPUT                 ####
tic;
% 0. Processing timestep values
mc_timestep_days = zeros(length(mc_timesteps),1);
for kk = 1:1:length(mc_timesteps)
    tmp_ts = mc_timesteps{kk};
    if ( strcmp(tolower(tmp_ts(end)),'d') )
        mc_timestep_days(kk) = str2num(tmp_ts(1:end-1));  % get timestep days
    elseif ( strcmp(to_lower(tmp_ts(end)),'y'))
        mc_timestep_days(kk) = 365 * str2num(tmp_ts(1:end-1));  % get timestep days
    else
        error('Unknown number of days in timestep: %s\n',tmp_ts);
    endif
endfor
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

parseinput = toc;


% II) #######            CALCULATION                ####

 
% 1.) Model Riskfactor Scenario Generation
tic;
%-----------------------------------------------------------------

if ( mc < 1000 ) 
    hd_limit = mc - 1;
endif

% a.) Load input correlation matrix
%corr_matrix = load('rf_corr_2011_2015.dat'); 

%cov_matrix = load('covmat_24.dat'); % path to covariance matrix
%[std_vector corr_matrix] = cov2corr(cov_matrix);
corr_matrix = load(input_filename_corr_matrix); % path to correlation matrix
%corr_matrix = eye(length(riskfactor_struct));
%std_vector'
% b) Get distribution parameters: all four moments and return are taken directly from riskfactors, NOT from covariance matrix!
rf_vola_vector = zeros(length(riskfactor_struct),1);
for ii = 1 : 1 : length(riskfactor_struct)
    rf_object = riskfactor_struct( ii ).object;
    rf_vola_vector(ii)            = rf_object.std;
    rf_para_distributions(1,ii)   = rf_object.mean;  % mu
    rf_para_distributions(2,ii)   = rf_object.std;   % sigma
    rf_para_distributions(3,ii)   = rf_object.skew;  % skew
    rf_para_distributions(4,ii)   = rf_object.kurt;  % kurt    
endfor
% c) call MC scenario generation (Copula approach, Pearson distribution types 1-7 according four moments of distribution parameters)
%    returns matrix R with a mc_scenarios x 1 vector with correlated random variables fulfilling skewness and kurtosis
[R_250 distr_type] = scenario_generation_MC(corr_matrix,rf_para_distributions,mc,copulatype,nu,256);
%[R_1 distr_type] = scenario_generation_MC(corr_matrix,rf_para_distributions,mc,copulatype,nu,1); % only needed if independent random numbers are desired
% for ii = 1 : 1 : length(riskfactor_struct)
    % disp('=== Distribution function for riskfactor ===')
    % riskfactor_struct( ii ).name
    % distr_type(ii)
    % sigma_soll = rf_para_distributions(2,ii)   % sigma
    % sigma_act = std(R(:,ii))
    % skew_soll = rf_para_distributions(3,ii)   % skew
    % skew_act = skewness(R(:,ii))
    % kurt_soll = rf_para_distributions(4,ii)   % kurt    
    % kurt_act = kurtosis(R(:,ii))
% endfor

% Correlation breach analysis: calculating norm of target and actual correlation matrix of all risk factors
norm_corr_250 = norm( corr(R_250) .- corr_matrix)
%norm_corr_1 = norm( corr(R_1) .- corr_matrix)
std_vector = rf_vola_vector;

M_struct = struct();
for kk = 1:1:length(mc_timestep_days)       % workaround: take only one random matrix and derive all other timesteps from them
        % [R_250 distr_type] = scenario_generation_MC(corr_matrix,rf_para_distributions,mc,copulatype,nu,mc_timestep_days(kk)); % uncomment, if new random numbers needed for each timestep
        M_struct( kk ).matrix = R_250 ./ sqrt(250/mc_timestep_days(kk));
endfor
% --------------------------------------------------------------------------------------------------------------------
% 2.) Monte Carlo Riskfactor Simulation for all timesteps

for kk = 1 : 1 : length( mc_timesteps )      % loop via all MC time steps
    tmp_ts  = mc_timesteps{ kk };    % get timestep string
    ts      = mc_timestep_days(kk);  % get timestep days
    Y_tmp   = M_struct( kk ).matrix; % get matrix with correlated random numbers for all risk factors
    for ii = 1 : 1 : length( riskfactor_struct )    % loop via all risk factors: calculate risk factor deltas in each MC scenario
        rf_object = riskfactor_struct( ii ).object;
        tmp_model = rf_object.model;
        tmp_drift = rf_object.mean / 250;
        tmp_sigma = rf_object.std;
        % correlated random variables vector from corr. random matrix M:
        Y       = Y_tmp(:,ii);
        % Case Dependency:
            % Geometric Brownian Motion Riskfactor Modeling
                if ( strcmp(tmp_model,'GBM') )
                    tmp_delta 	    = Y .+ ((tmp_drift - 0.5 .* (tmp_sigma./ sqrt(256)).^2) .* ts);
            % Brownian Motion Riskfactor Modeling
                elseif ( strcmp(tmp_model,'BM') )
                    tmp_delta 	    = Y .+ (tmp_drift * ts);
            % Black-Karasinski (log-normal mean reversion) Riskfactor Modeling
                elseif ( strcmp(tmp_model,'BKM') )
                    % startlevel, sigma_p_a, mr_level, mr_rate
                    tmp_start       = rf_object.value_base;
                    tmp_mr_level    = rf_object.mr_level;
                    tmp_mr_rate     = rf_object.mr_rate;    
                    tmp_delta       = Y .+ (tmp_mr_rate * ( tmp_mr_level - tmp_start ) * ts);
            % Ornstein-Uhlenbeck process 
                elseif ( strcmp(tmp_model,'OU') )    
                    % startlevel, sigma_p_a, mr_level, mr_rate
                    tmp_start       = rf_object.value_base;
                    tmp_mr_level    = rf_object.mr_level;
                    tmp_mr_rate     = rf_object.mr_rate;     
                    tmp_delta       = Y .+ (tmp_mr_rate * ( tmp_mr_level - tmp_start ) * ts);
            % Square-root diffusion process
                elseif ( strcmp(tmp_model,'SRD') )    
                    % startlevel, sigma_p_a, mr_level, mr_rate
                    tmp_start       = rf_object.value_base;
                    tmp_mr_level    = rf_object.mr_level;
                    tmp_mr_rate     = rf_object.mr_rate;     
                    tmp_delta       = sqrt(tmp_start) .* Y .+ (tmp_mr_rate * ( tmp_mr_level - tmp_start ) * ts);
                end     
        % store increment for actual riskfactor and scenario number
        rf_object = rf_object.set('scenario_mc',tmp_delta,'timestep_mc',tmp_ts);
        % store risk factor object back into struct:
        riskfactor_struct( ii ).object = rf_object;    
    endfor  % close loop via all risk factors  
endfor      % close loop via all mc_timesteps


% 3.) Take Riskfactor Shiftvalues from Stressdefinition
% loop via all riskfactors, take IDs from struct und apply delta
for ii = 1 : 1 : length( stresstest_struct )
    tmp_shiftvalue  = [stresstest_struct( ii ).shiftvalue];
    tmp_shifttypes  = [stresstest_struct( ii ).shifttype];
    tmp_risktype    = stresstest_struct( ii ).risktype;
        for kk = 1 : 1 : length( riskfactor_struct )
            % get parameters of risk factor object
            rf_object   = riskfactor_struct( kk ).object;
            tmp_rf_type = rf_object.type;
            tmp_rf_id   = rf_object.id;
            c = regexp(tmp_rf_id, tmp_risktype);     % string comparison on whole cell -> multiply for shiftvalue
            k = cellfun(@isempty,c) == 0;
            tmp_shift = tmp_shiftvalue * k';
            tmp_shift_type = tmp_shifttypes * k';

            if ( sum(k) == 1 )
                tmp_stress = [tmp_shift];
            else
                tmp_stress = [0.0];
            end
            rf_object = rf_object.set('scenario_stress',tmp_stress);
            rf_object = rf_object.set('shift_type',tmp_shift_type);
            % store risk factor object back into struct:
            riskfactor_struct( kk ).object = rf_object; 
        endfor    
endfor

scengen = toc;
tic;
if ( saving == 1 )
% Save structs to file
endung = '.mat';

    % Saving riskfactors: loop via all objects in structs and convert
    tmp_riskfactor_struct = riskfactor_struct;
    for ii = 1 : 1 : length( tmp_riskfactor_struct )
        tmp_riskfactor_struct(ii).object = struct(tmp_riskfactor_struct(ii).object);
    endfor
    savename = 'tmp_riskfactor_struct';
	fullpath = [path_output, savename, endung];
	save ('-text', fullpath, savename);
 
    % Saving instruments: loop via all objects in structs and convert
    tmp_instrument_struct = instrument_struct;
    for ii = 1 : 1 : length( tmp_instrument_struct )
        tmp_instrument_struct(ii).object = struct(tmp_instrument_struct(ii).object);
    endfor 
    savename = 'tmp_instrument_struct';
	fullpath = [path_output, savename, endung];
	save ('-text', fullpath, savename);

savename = 'portfolio_struct';
	fullpath = [path_output, savename, endung];
	save ('-text', fullpath, savename);

savename = 'stresstest_struct';
	fullpath = [path_output, savename, endung];
	save ('-text', fullpath, savename);
end
saving_time = toc;    


% 4.) Process yield curves and vola surfaces: Generate object with riskfactor yield curves and surfaces 
% a) Processing Yield Curve: Getting Cell with IDs of IR nodes
% load dynamically cellarray with all RF curves (IR and SPREAD) as defined in riskfactor_struct
rf_ir_cur_cell = {};
for ii = 1 : 1 : length(riskfactor_struct)
    tmp_rf_struct_obj = riskfactor_struct( ii ).object;
    tmp_rf_id = tmp_rf_struct_obj.id;
    tmp_rf_type = tmp_rf_struct_obj.type;
    if ( strcmp(tmp_rf_type,'RF_IR') || strcmp(tmp_rf_type,'RF_SPREAD') )   % store riskfactor id in cell
        tmp_rf_parts = strsplit(tmp_rf_id, '_');
        tmp_rf_curve = 'RF';
        for jj = 2 : 1 : length(tmp_rf_parts) -1    % concatenate the whole string except the last '_xY'
            tmp_rf_curve = strcat(tmp_rf_curve,'_',tmp_rf_parts{jj});
        endfor
        rf_ir_cur_cell = cat(2,rf_ir_cur_cell,tmp_rf_curve);
    end
    rf_ir_cur_cell = unique(rf_ir_cur_cell);
endfor

% generate RF_IR and RF_SPREAD objects from all nodes defined in riskfactor_struct
tic;
persistent curve_struct;
curve_struct=struct();
% Loop via all entries in currency cell
for ii = 1 : 1 : length(rf_ir_cur_cell)
    tmp_curve_id         = rf_ir_cur_cell{ii};
    if ( regexp(tmp_curve_id,'IR'))
        tmp_curve_type = 'Discount Curve';
    elseif ( regexp(tmp_curve_id,'SPREAD'))
        tmp_curve_type = 'Spread Curve';
    else
        tmp_curve_type = 'Dummy Curve';
    endif
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
            %tmp_rf_id
            tmp_node            = tmp_rf_struct_obj.get('node');
            tmp_rate_original   = tmp_rf_struct_obj.get('rate');
            tmp_nodes 		    = cat(2,tmp_nodes,tmp_node); % final vectors with nodes in days
            tmp_rates_original  = cat(2,tmp_rates_original,tmp_rate_original); % final vector with rates in decimals
            tmp_delta_stress    = tmp_rf_struct_obj.getValue('stress') ./ 10000;
            tmp_rf_rates_stress	= tmp_rate_original .+ tmp_delta_stress;
            tmp_rates_stress 	= cat(2,tmp_rates_stress,tmp_rf_rates_stress);
        end
    endfor 
    curve_object = curve_object.set('nodes',tmp_nodes);
    curve_object = curve_object.set('rates_base',tmp_rates_original);
    curve_object = curve_object.set('rates_stress',tmp_rates_stress);
    
    % loop via all mc timesteps
    for kk = 1:1:length(mc_timesteps)
        tmp_ts = mc_timesteps{kk};
        % get original yield curve
        tmp_rates_shock = [];            
        for jj = 1 : 1 : length( riskfactor_struct )
            tmp_rf_struct_obj = riskfactor_struct( jj ).object;
            tmp_rf_id = tmp_rf_struct_obj.id;
            if ( regexp(tmp_rf_id,tmp_curve_id) == 1 )           
                tmp_delta_shock     = tmp_rf_struct_obj.getValue(tmp_ts);
                % Calculate new absolute values from Riskfactor PnL depending on riskfactor model
                tmp_model           = tmp_rf_struct_obj.get('model');
                tmp_rf_rates_shock  = Riskfactor.get_abs_values(tmp_model, tmp_delta_shock, tmp_rf_struct_obj.get('rate')); 
                tmp_rates_shock 	= cat(2,tmp_rates_shock,tmp_rf_rates_shock);
            endif
        endfor    
        % Save curves into struct
        curve_object = curve_object.set('rates_mc',tmp_rates_shock,'timestep_mc',tmp_ts);           
    endfor  % close loop via scenario_sets (mc,stress)
    
    curve_struct( ii ).object = curve_object;
endfor    % close loop via all curves

% append Dummy Spread Curve (used for all instruments without defined spread curve): 
    curve_struct( length(rf_ir_cur_cell) + 1  ).id = 'RF_SPREAD_DUMMY';    
    curve_object = Curve('RF_SPREAD_DUMMY','RF_SPREAD_DUMMY','Spread Curve','Dummy Spread curve with zero rates');
    curve_object = curve_object.set('nodes',[365]);
    curve_object = curve_object.set('rates_base',[0]);
    curve_object = curve_object.set('rates_stress',[0]);
    for kk = 1:1:length(mc_timesteps)       % append dummy curves for all mc_timesteps
        curve_object = curve_object.set('rates_mc',[0],'timestep_mc',mc_timesteps{ kk });
    endfor    
    curve_struct( length(rf_ir_cur_cell) + 1  ).object = curve_object;   
curve_gen_time = toc;
% end filling curve_struct
% tmp_rates_mc_250d
       % Save interest rates data:	
       % endung = strcat('_',tmp_curve_id,'.dat');
       % savename = 'tmp_rates_mc_250d';
       % fullpath = [path, savename, endung];
       % save ('-ascii', fullpath, savename);
       
% b) BEGIN: Processing Vola surfaces: Load in all vola marketdata and fill Surface object with values
% i) Get list of all vol files
tmp_list_files = dir(path_mktdata);
persistent surface_struct;
surface_struct=struct();
% Apply dummy surface for VOLA_INDEX
tmp_surface_object = Surface('RF_VOLA_INDEX_DUMMY','RF_VOLA_INDEX_DUMMY','INDEX','Dummy Vola Surface');
tmp_surface_object = tmp_surface_object.set('axis_x_name','TERM','axis_y_name','MONEYNESS','axis_x',[365],'axis_y',[1],'values_base',[0.0]);
surface_struct(1).id = 'RF_VOLA_INDEX_DUMMY';
surface_struct(1).object = tmp_surface_object;
% Apply dummy surface for VOLA_IR
tmp_surface_object = Surface('RF_VOLA_IR_DUMMY','RF_VOLA_IR_DUMMY','IR','Dummy Vola Surface');
tmp_surface_object = tmp_surface_object.set('axis_x_name','TENOR','axis_y_name','TERM','axis_z_name','MONEYNESS','axis_x',[365],'axis_y',[365],'axis_z',[1],'values_base',[0.0]);
surface_struct(2).id = 'RF_VOLA_IR_DUMMY';
surface_struct(2).object = tmp_surface_object;

% Store marketdata
for ii = 1 : 1 : length(tmp_list_files)
    tmp_filename = tmp_list_files( ii ).name;
    if ( regexp(tmp_filename,input_filename_vola_index) == 1)       % vola for index found  
        tmp_len_struct = length(surface_struct);
        M = load(strcat(path_mktdata,'/',tmp_filename));
        % Get axis values and matrix: 
        % Format: 3 columns: xx yy value [moneyness term impl_vola]
        xx_structure = unique(M(:,1))';
        yy_structure = unique(M(:,2))';
        vola_matrix = zeros(length(yy_structure),length(xx_structure));   % dimensionality of matrix has to be swapped XX <-> YY
        % loop through all rows and store values in vola_matrix
        for ii = 1 : 1 : rows(M)
            index_xx = find(xx_structure==M(ii,1));
            index_yy = find(yy_structure==M(ii,2));
            vola_matrix(index_yy,index_xx) = M(ii,3);
        endfor
        % Generate object and store data
        tmp_id = strrep(tmp_filename,input_filename_vola_index,''); % remove first string identifying file
        tmp_id = strrep(tmp_id,'.dat',''); % remove file ending
        tmp_surface_object =  Surface(tmp_id,tmp_id,'INDEX','INDEX Vola Surface');
        tmp_surface_object = tmp_surface_object.set('axis_x_name','TERM','axis_y_name','MONEYNESS','axis_x',xx_structure,'axis_y',yy_structure,'values_base',vola_matrix);
        surface_struct( tmp_len_struct + 1).id = tmp_id;
        surface_struct( tmp_len_struct + 1).object = tmp_surface_object;
        % %tmp_surface_object
    elseif ( regexp(tmp_filename,input_filename_vola_ir) == 1)       % vola for ir found  
        tmp_len_struct = length(surface_struct);
        M = load(strcat(path_mktdata,'/',tmp_filename));
        % Get axis values and matrix: 
        % Format: 4 columns: xx yy zz value [underlying_tenor  swaption_term  moneyness  impl_cola]
        xx_structure = unique(M(:,1))';
        yy_structure = unique(M(:,2))';
        zz_structure = unique(M(:,3))';
        vola_cube = zeros(length(xx_structure),length(yy_structure),length(zz_structure));    % dimensionality of matrix has to be swapped XX <-> YY
        % loop through all rows and store values in vola_cube
        for ii = 1 : 1 : rows(M)
            index_xx = find(xx_structure==M(ii,1));
            index_yy = find(yy_structure==M(ii,2));
            index_zz = find(zz_structure==M(ii,3));
            vola_cube(index_xx,index_yy,index_zz) = M(ii,4);
        endfor
        % Generate object and store data
        tmp_id = strrep(tmp_filename,input_filename_vola_ir,''); % remove first string identifying file
        tmp_id = strrep(tmp_id,'.dat',''); % remove file ending
        tmp_surface_object =  Surface(tmp_id,tmp_id,'IR','IR Vola Surface');
        tmp_surface_object = tmp_surface_object.set('axis_x_name','TENOR','axis_y_name','TERM','axis_z_name','MONEYNESS','axis_x',xx_structure,'axis_y',yy_structure,'axis_z',zz_structure,'values_base',vola_cube);
        surface_struct( tmp_len_struct + 1).id = tmp_id;
        surface_struct( tmp_len_struct + 1).object = tmp_surface_object;
         % tmp_surface_object
         % zz_vec = ones(10,1) .* (1 + rand(10,1)/10)
         % retvec = tmp_surface_object.getValue(380,700,zz_vec)'
         % retvec(1:10)
    end    
endfor
%  END: Processing Vola surfaces

      
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
  endif
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
                tmp_underlying_obj       = get_sub_object(riskfactor_struct, option.get('underlying'));
                tmp_rf_curve_obj         = get_sub_object(curve_struct, option.get('discount_curve'));
                tmp_vola_surf_obj        = get_sub_object(surface_struct, option.get('vola_surface'));
                % Calibration of Option vola spread 
                if ( option.get('vola_spread') == 0 )
                    option = option.calc_vola_spread(tmp_underlying_obj,tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,valuation_date);
                endif
                % calculate value
                option = option.calc_value(tmp_scenario,tmp_underlying_obj,tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,valuation_date);

                % store option object in struct:
                    instrument_struct( ii ).object = option;
            
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
                endif
                % calculate value
                swaption = swaption.calc_value(tmp_scenario,tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,valuation_date);
                % store swaption object in struct:
                    instrument_struct( ii ).object = swaption;
                    
            %Equity Forward valuation
            elseif (strcmp(tmp_type,'forward') )
                % Using forward class
                    forward = tmp_instr_obj;
                 % Get underlying risk factor / instrument    
                    tmp_underlying = forward.get('underlying_id');
                if ( strfind(tmp_underlying,'RF_') )   % underlying instrument is a risk factor
                    tmp_underlying_object       = get_sub_object(riskfactor_struct, tmp_underlying);
                endif
                % Get discount curve
                    tmp_discount_curve          = forward.get('discount_curve');            
                    tmp_curve_object            = get_sub_object(curve_struct, tmp_discount_curve);	

                %Calculate values of equity forward: assume geometric brownian motion for underlying price movement
                if ( first_eval == 0)
                % Base value
                    forward = forward.calc_value(tmp_curve_object,'base',tmp_underlying_object);
                endif
                % calculation of value for scenario               
                    forward = forward.calc_value(tmp_curve_object,tmp_scenario,tmp_underlying_object);

                % store bond object in struct:
                    instrument_struct( ii ).object = forward;
                    
            % Equity Valuation: Sensitivity based Approach: dR_pos = Sum(Sensitivity_i * dR_i) via Geometric Brownian Motion      
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
                            tmp_shift = tmp_shift .+ tmp_sensitivities(jj) .* normrnd(0,tmp_idio_vec ./ sqrt(250/tmp_ts));
                        endif
                    % get sensitivity approach shift from underlying riskfactors
                    else
                        tmp_rf_struct_obj    = get_sub_object(riskfactor_struct, tmp_riskfactor);
                        tmp_delta   = tmp_rf_struct_obj.getValue(tmp_scenario);
                        tmp_shift   = tmp_shift + ( tmp_sensitivities(jj) .* tmp_delta );
                    end
                endfor

                % Calculate new absolute scenario values from Riskfactor PnL depending on riskfactor model
                theo_value   = Riskfactor.get_abs_values('GBM', tmp_shift, sensi.getValue('base'));

                % store values in sensitivity object:
                if ( strcmp(tmp_scenario,'stress'))
                    sensi = sensi.set('value_stress',theo_value);
                else            
                    sensi = sensi.set('value_mc',theo_value,'timestep_mc',tmp_scenario);           
                endif
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
                    tmp_underlying      = tmp_instruments{jj};
                    und_obj             = get_sub_object(instrument_struct, tmp_underlying);
                    % Get instrument Value from full valuation instrument_struct:
                    % absolute values from full valuation
                    underlying_value_base       = und_obj.getValue('base');                 
                    underlying_value_vec        = und_obj.getValue(tmp_scenario);  
                    % Get FX rate:
                    tmp_underlying_currency = und_obj.get('currency'); 
                    if ( strcmp(tmp_underlying_currency,tmp_currency) == 1 )
                        tmp_fx_rate_base    = 1;
                        tmp_fx_value        = ones(scen_number,1);
                    else
                        %disp( ' Conversion of currency: ');
                        tmp_fx_riskfactor = strcat('RF_FX_', tmp_currency, tmp_underlying_currency);
                        tmp_fx_struct_obj = get_sub_object(riskfactor_struct, tmp_fx_riskfactor);
                        tmp_fx_rate_base  = tmp_fx_struct_obj.value_base;
                        tmp_fx_value      = tmp_fx_struct_obj.getValue(tmp_scenario,'abs');
                    end
                    tmp_value_base      = tmp_value_base    .+ tmp_weights(jj) .* underlying_value_base ./ tmp_fx_rate_base;
                    tmp_value           = tmp_value      .+ tmp_weights(jj) .* underlying_value_vec ./ tmp_fx_value;
                endfor

                % store values in sensitivity object:
                if ( first_eval == 0)
                    synth = synth.set('value_base',tmp_value_base);
                endif
                if ( strcmp(tmp_scenario,'stress'))
                    synth = synth.set('value_stress',tmp_value);
                else                    
                    synth = synth.set('value_mc',tmp_value,'timestep_mc',tmp_scenario);
                endif
                % store bond object in struct:
                    instrument_struct( ii ).object = synth;
                    
            % Cashflow Valuation: summing net present value of all cashflows according to cashflowdates
            elseif ( sum(strcmp(tmp_type,'bond')) > 0 ) 
                % Using Bond class
                    bond = tmp_instr_obj;
                % a) Get curve parameters    
                  % get discount curve
                    tmp_discount_curve  = bond.get('discount_curve');
                    tmp_curve_object    = get_sub_object(curve_struct, tmp_discount_curve); 
                  % Get spread curve
                    tmp_spread_curve    = bond.get('spread_curve');
                    tmp_spread_object 	= get_sub_object(curve_struct, tmp_spread_curve);  
                % b) Get Cashflow dates and values of instrument depending on type (cash settlement):
                    if( sum(strcmp(tmp_sub_type,{'FRB','SWAP_FIXED','ZCB','CASHFLOW'})) > 0 )       % Fixed Rate Bond instruments (incl. swap fixed leg)
                        % rollout cash flows for all scenarios
                        if ( first_eval == 0)
                            bond = bond.rollout('base',valuation_date);
                        endif
                        bond = bond.rollout(tmp_scenario,valuation_date);
                    elseif( strcmp(tmp_sub_type,'FRN') == 1 || strcmp(tmp_sub_type,'SWAP_FLOAT') == 1)       % Floating Rate Notes (incl. swap floating leg)
                         %get reference curve object used for calculating floating rates:
                            tmp_ref_curve   = bond.get('reference_curve');
                            tmp_ref_object 	= get_sub_object(curve_struct, tmp_ref_curve);
                        % rollout cash flows for all scenarios
                            if ( first_eval == 0)
                                bond = bond.rollout('base',tmp_ref_object,valuation_date);
                            endif
                            bond = bond.rollout(tmp_scenario,tmp_ref_object,valuation_date);         
                    endif 
                    
                % c) Get Spread over yield: 
                    if ~( bond.get('soy') == 0 )
                        bond = bond.calc_spread_over_yield(tmp_curve_object,tmp_spread_object,valuation_date);
                    endif
                    
                % d) get net present value of all Cashflows (discounting of all cash flows)
					if ( first_eval == 0)
                        bond = bond.calc_value (valuation_date,tmp_curve_object,tmp_spread_object,'base');
                    endif
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
        fprintf('Instrument valuation for %s failed. There was an error: %s\n',tmp_id,lasterr);
        instrument_valuation_failed_cell{ length(instrument_valuation_failed_cell) + 1 } =  tmp_id;
        % store instrument as Cash instrument with fixed value_base for all scenarios
        cc = Cash();
        cc = cc.set('id',tmp_instr_obj.get('id'),'name',tmp_instr_obj.get('name'),'asset_class',tmp_instr_obj.get('asset_class'),'currency',tmp_instr_obj.get('currency'),'value_base',tmp_instr_obj.get('value_base'));
        cc = cc.calc_value(tmp_scenario,scen_number);
        instrument_struct( ii ).object = cc;
    end
  endfor 
  first_eval = 1;
endfor      % endfor eval mc timesteps and stress loops
 
 tic;
if ( saving == 1 )
    % loop via all objects in structs and convert
    tmp_instrument_struct_fv = instrument_struct;
    for ii = 1 : 1 : length( tmp_instrument_struct )
        tmp_instrument_struct(ii).object = struct(tmp_instrument_struct(ii).object);
    endfor 
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
endif


% --------------------------------------------------------------------------------------------------------------------
% 6. Portfolio Aggregation
tic;
Total_Portfolios = length( portfolio_struct );
base_value = 0;
idx_figure = 0;
confi = 1 - confidence;
confi_scenario = max(round(confi * mc),1);

% before looping via all portfolio make one time Harrel Davis Vector:
% HD VaR only if number of scenarios < hd_limit
if ( mc < hd_limit )
    minhd           = min(2*confi_scenario+1,mc);
    hd_vec_min      = zeros(max(confi_scenario-500,0)-1,1);
    hd_vec_max      = zeros(mc-min(confi_scenario+500,mc)-1,1);
    hd_plot_x       = max(confi_scenario-500,0):1:min(confi_scenario+500,mc);
    tt              = max(confi_scenario-500,0):1:min(confi_scenario+500,mc);
    hd_vec_func     = harrell_davis_weight(mc,tt,confi)';
    hd_vec          = [hd_vec_min ; hd_vec_func ; hd_vec_max ];
    size_hdvec = size(hd_vec);
end
% a) loop over all portfolios (outer loop) and via all positions (inner loop)
for mm = 1 : 1 : length( portfolio_struct )
    %disp('Aggregation for Portfolio ');
    %mm
    tmp_port_id = portfolio_struct( mm ).id;
    clear position_struct;
    position_struct = struct();
    position_struct = portfolio_struct( mm ).position;
    portfolio_value = 0;
    PositionStructlength = length( position_struct  );
    for ii = 1 : 1 : length( position_struct  )
        tmp_id = position_struct( ii ).id;
        tmp_quantity = position_struct( ii ).quantity;
        tmp_instr_object = get_sub_object(instrument_struct, tmp_id);
        tmp_value = tmp_instr_object.getValue('base');
        tmp_currency = tmp_instr_object.get('currency'); 

        % conversion of position to EUR
        if ( strcmp(tmp_currency,'EUR') == 1 )
                tmp_fx_rate = 1;
        else
                tmp_fx_riskfactor = strcat('RF_FX_EUR', tmp_currency);
                tmp_fx_struct_obj = get_sub_object(riskfactor_struct, tmp_fx_riskfactor);
                tmp_fx_rate = tmp_fx_struct_obj.value_base;
        end        
        position_struct( ii ).basevalue = tmp_value .* tmp_quantity ./ tmp_fx_rate;
        portfolio_value = portfolio_value + tmp_value .* tmp_quantity  ./ tmp_fx_rate;

    endfor
    
    base_value = portfolio_value

    % Fileoutput:
    filename = strcat(path_reports,'/VaR_report_',runcode,'_',tmp_port_id,'.txt');
    fid = fopen (filename, 'w');

    fprintf('==================================================================== \n');
    fprintf('=== Risk measures report for Portfolio %s ===\n',tmp_port_id);

    fprintf(fid, '==================================================================== \n');
    fprintf(fid, '=== Risk measures report for Portfolio %s ===\n',tmp_port_id);
    fprintf(fid, 'VaR calculated at %2.1f%% confidence intervall: \n',confidence.*100);
    fprintf(fid, 'Number of Monte Carlo Scenarios: %i \n', mc);
    fprintf(fid, 'Valuation Date: %s \n',datestr(valuation_date));
    fprintf(fid, 'Portfolio base value: %9.2f EUR \n',base_value);
    fprintf(fid, '\n');
    fprintf(fid, '=====    MC RESULTS    ===== \n');
%   ========================================   Loop via all MC scenarios    ================================= 
for kk = 1 : 1 : length( scenario_set )      % loop via all MC time steps
    tmp_scen_set  = scenario_set{ kk };    % get timestep string
 
  % ##############################    BEGIN  MC REPORTS    ########################################## 
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

            % get instrument data: get Position's Riskfactors and Sensitivities
            tmp_instr_object = get_sub_object(instrument_struct, tmp_id);
            tmp_value = tmp_instr_object.getValue('base');
            tmp_currency = tmp_instr_object.get('currency');
            % Get instrument Value from full valuation instrument_struct:
            % absolute values from full valuation
            new_value_vec_shock      = tmp_instr_object.getValue(tmp_scen_set);              
 
            % Get FX rate:
            if ( strcmp(tmp_currency,'EUR') == 1 )
                tmp_fx_value_shock   = ones(mc,1);
            else
                %disp( ' Conversion of currency: ');
                tmp_fx_riskfactor   = strcat('RF_FX_', base_currency, tmp_currency);
                tmp_fx_struct_obj   = get_sub_object(riskfactor_struct, tmp_fx_riskfactor);
                tmp_fx_rate_base    = tmp_fx_struct_obj.getValue('base');
                tmp_fx_value_shock   = tmp_fx_struct_obj.getValue(tmp_scen_set,'abs');
                        
            end
              
            % Store new Values in Position's struct
	        pos_vec_shock 	= new_value_vec_shock .* sign(tmp_quantity) ./ tmp_fx_value_shock;
	        octamat = [  pos_vec_shock ] ;
            position_struct( ii ).mc_scenarios.octamat = octamat;
            portfolio_shock = portfolio_shock .+  tmp_quantity .* new_value_vec_shock ./ tmp_fx_value_shock;
        endfor


% b.) VaR Calculation
%  i.) sort arrays
endstaende_reldiff_shock = portfolio_shock ./ base_value;
endstaende_sort_shock    = sort(endstaende_reldiff_shock);
[portfolio_shock_sort scen_order_shock] = sort(portfolio_shock');
p_l_absolut_shock        = portfolio_shock_sort .- base_value;
% Preparing vector for extreme value theory VAR and ES
    confi_scenario_evt_95   = round(0.025 * mc);
    evt_tail_shock           = p_l_absolut_shock(1:confi_scenario_evt_95)';
    % Calculate VAR and ES from GPD:
    u = min(-evt_tail_shock);
    [chi sigma] = calibrate_evt_gpd(-evt_tail_shock);
    nu = length(evt_tail_shock);
    [VAR90_EVT_shock ES90_EVT_shock]    = get_gpd_var(chi, sigma, u, 0.90, mc, nu);
    [VAR95_EVT_shock ES95_EVT_shock]  = get_gpd_var(chi, sigma, u, 0.95, mc, nu);
    [VAR975_EVT_shock ES975_EVT_shock]    = get_gpd_var(chi, sigma, u, 0.975, mc, nu);
    [VAR99_EVT_shock ES99_EVT_shock]  = get_gpd_var(chi, sigma, u, 0.99, mc, nu);
    [VAR9999_EVT_shock ES9999_EVT_shock]  = get_gpd_var(chi, sigma, u, 0.9999, mc, nu);
    [VAR995_EVT_shock ES995_EVT_shock]    = get_gpd_var(chi, sigma, u, confidence, mc, nu);
    [VAR999_EVT_shock ES999_EVT_shock]    = get_gpd_var(chi, sigma, u, 0.999, mc, nu);
    [VAR9999_EVT_shock ES9999_EVT_shock]  = get_gpd_var(chi, sigma, u, 0.9999, mc, nu);

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

confi_scenarionumber_shock = scen_order_shock(confi_scenario)
skewness_shock           = skewness(endstaende_reldiff_shock)
kurtosis_shock           = kurtosis(endstaende_reldiff_shock)

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
for ii = 1 : 1 : length( riskfactor_struct)
    tmp_id           = riskfactor_struct( ii ).object.id;
    tmp_delta_shock   = riskfactor_struct( ii ).object.getValue(tmp_scen_set);
    fprintf(fid, '|VaR %s scenario delta |%s|%1.3f|%1.3f|%1.3f|%1.3f|%1.3f|\n',tmp_scen_set,tmp_id,tmp_delta_shock(confi_scenarionumber_shock_m2),tmp_delta_shock(confi_scenarionumber_shock_m1),tmp_delta_shock(confi_scenarionumber_shock),tmp_delta_shock(confi_scenarionumber_shock_p1),tmp_delta_shock(confi_scenarionumber_shock_p2));
endfor
% 7.1) Print Report for all Positions:
total_var_undiversified = 0;

persistent aggr_key_struct;
aggr_key_struct=struct();

% reset vectors for charts of riskiest instruments and positions
pie_chart_values_instr_shock = [];
pie_chart_desc_instr_shock = {};
pie_chart_values_pos_shock = [];
pie_chart_desc_pos_shock = {};
    
fprintf(fid, '\n');
fprintf(fid, 'Sensitivities on Positional Level: \n');
for ii = 1 : 1 : length( position_struct )
    octamat = position_struct( ii ).mc_scenarios.octamat;
    tmp_values_shock = sort(octamat);
    tmp_id = position_struct( ii ).id;
    tmp_instr_object = get_sub_object(instrument_struct, tmp_id);
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
        endif
        if (isProp(tmp_instr_object,aggregation_key{jj}) == 1)
            tmp_aggr_key_value = getfield(tmp_instr_object,aggregation_key{jj});
            if (ischar(tmp_aggr_key_value))
                if ( strcmp(tmp_aggr_key_value,'') == 1 )
                    tmp_aggr_key_value = 'Unknown';
                endif
                % Assign P&L to aggregation key
                % check, wether aggr key already exist in cell array
                if (sum(strcmp(tmp_aggr_cell,tmp_aggr_key_value)) > 0)   % aggregation key found
                    tmp_vec_xx = 1:1:length(tmp_aggr_cell);
                    tmp_aggr_key_index = strcmp(tmp_aggr_cell,tmp_aggr_key_value)*tmp_vec_xx';
                    aggregation_mat(:,tmp_aggr_key_index) = aggregation_mat(:,tmp_aggr_key_index) .+ (octamat .* tmp_quantity .* sign(tmp_quantity) .- tmp_basevalue);
                    aggregation_decomp_shock(tmp_aggr_key_index) = aggregation_decomp_shock(tmp_aggr_key_index) + tmp_decomp_var_shock;
                else    % aggregation key not found -> set value for first time
                    tmp_aggr_cell{end+1} = tmp_aggr_key_value;
                    tmp_aggr_key_index = length(tmp_aggr_cell);
                    aggregation_mat(:,tmp_aggr_key_index)       = (octamat .* tmp_quantity .* sign(tmp_quantity)  .- tmp_basevalue);
                    aggregation_decomp_shock(tmp_aggr_key_index)  = tmp_decomp_var_shock;
                endif
            else
                disp('Aggregation key not valid');
            endif
        else
            disp('Aggregation key not found in instrument definition');
        endif
        % storing updated values in struct
        aggr_key_struct( jj ).key_name = aggregation_key{jj};
        aggr_key_struct( jj ).key_values = tmp_aggr_cell;
        aggr_key_struct( jj ).aggregation_mat = aggregation_mat;
        aggr_key_struct( jj ).aggregation_decomp_shock = aggregation_decomp_shock;
    endfor
    
   
    total_var_undiversified = total_var_undiversified + tmp_pos_var;
    % Store Values for piechart (Except CASH):
    pie_chart_values_instr_shock(ii) = round((tmp_pos_var) / abs(tmp_quantity));
    pie_chart_desc_instr_shock(ii) = cellstr( strcat(tmp_instr_object.id));
    pie_chart_values_pos_shock(ii) = round((tmp_decomp_var_shock) );
    pie_chart_desc_pos_shock(ii) = cellstr( strcat(tmp_instr_object.id));
endfor  % end loop for all positions
% prepare vector for piechart:
[pie_chart_values_sorted_instr_shock sorted_numbers_instr_shock ] = sort(pie_chart_values_instr_shock);
[pie_chart_values_sorted_pos_shock sorted_numbers_pos_shock ] = sort(pie_chart_values_pos_shock);
idx = 1;

% plot only 6 highest values
for ii = length(pie_chart_values_instr_shock):-1:max(0,length(pie_chart_values_instr_shock)-5)
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
    tmp_aggr_key_name           =  aggr_key_struct( jj ).key_name;
    tmp_aggregation_mat         = [aggr_key_struct( jj ).aggregation_mat];
    tmp_aggregation_decomp_shock  = [aggr_key_struct( jj ).aggregation_decomp_shock];
    fprintf(' Risk aggregation for key: %s \n', tmp_aggr_key_name);
    fprintf('|VaR %s | Key value   | Standalone VAR \t | Decomp VAR|\n',tmp_scen_set);
    fprintf(fid, ' Risk aggregation for key: %s \n', tmp_aggr_key_name);
    fprintf(fid, '|VaR %s | Key value   | Standalone VAR \t | Decomp VAR|\n',tmp_scen_set);
    for ii = 1 : 1 : length(tmp_aggr_cell)
        tmp_aggr_key_value          = tmp_aggr_cell{ii};
        tmp_standalone_aggr_key_var = abs(sort(tmp_aggregation_mat(:,ii))(confi_scenario));
        tmp_decomp_aggr_key_var     = tmp_aggregation_decomp_shock(ii);
        fprintf('|VaR %s | %s \t |%9.2f EUR \t |%9.2f EUR|\n',tmp_scen_set,tmp_aggr_key_value,tmp_standalone_aggr_key_var,tmp_decomp_aggr_key_var);
        fprintf(fid, '|VaR %s | %s \t |%9.2f EUR \t |%9.2f EUR|\n',tmp_scen_set,tmp_aggr_key_value,tmp_standalone_aggr_key_var,tmp_decomp_aggr_key_var);
    endfor
endfor

% Print Portfolio reports
fprintf(fid, '\n');
fprintf(fid, 'Total VaR undiversified: \n');
fprintf(fid, '|VaR %s undiversified| |%9.2f EUR|\n',tmp_scen_set,total_var_undiversified);
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
fprintf(fid, '|Portfolio VaR %s@%2.1f%%| \t |%9.2f EUR|\n',tmp_scen_set,confidence.*100,mc_var_shock);
fprintf(fid, '|Portfolio ES  %s@%2.1f%%| \t |%9.2f%%|\n',tmp_scen_set,confidence.*100,mc_es_shock_pct*100);
fprintf(fid, '|Portfolio ES  %s@%2.1f%%| \t |%9.2f EUR|\n\n',tmp_scen_set,confidence.*100,mc_es_shock);
fprintf(fid, '|Port EVT VAR  %s@%2.1f%%| \t |%9.2f EUR|\n',tmp_scen_set,confidence.*100,VAR995_EVT_shock);
fprintf(fid, '|Port EVT VAR  %s@%2.1f%%| \t |%9.2f EUR|\n',tmp_scen_set,99.9,VAR999_EVT_shock);
fprintf(fid, '|Port EVT VAR  %s@%2.2f%%| \t |%9.2f EUR|\n\n',tmp_scen_set,99.99,VAR9999_EVT_shock);
fprintf(fid, '|Port EVT  ES  %s@%2.1f%%| \t |%9.2f EUR|\n',tmp_scen_set,confidence.*100,ES995_EVT_shock);
fprintf(fid, '|Port EVT  ES  %s@%2.1f%%| \t |%9.2f EUR|\n',tmp_scen_set,99.9,ES999_EVT_shock);
fprintf(fid, '|Port EVT  ES  %s@%2.2f%%| \t |%9.2f EUR|\n',tmp_scen_set,99.99,ES9999_EVT_shock);

% Output to stdout:
fprintf('VaR %s@%2.1f%%: \t %9.2f%%\n',tmp_scen_set,confidence.*100,mc_var_shock_pct*100);
fprintf('VaR %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,confidence.*100,mc_var_shock);
fprintf('ES  %s@%2.1f%%: \t %9.2f%%\n',tmp_scen_set,confidence.*100,mc_es_shock_pct*100);
fprintf('ES  %s@%2.1f%%: \t %9.2f EUR\n\n',tmp_scen_set,confidence.*100,mc_es_shock);
% Output of GPD calibrated VaR and ES:
fprintf('GPD extreme value VAR and ES: \n');
fprintf('VaR EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,90.0,VAR90_EVT_shock);
fprintf('VaR EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,95.0,VAR95_EVT_shock);
fprintf('VaR EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,97.5,VAR975_EVT_shock);
fprintf('VaR EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,99.0,VAR99_EVT_shock);
fprintf('VaR EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,confidence.*100,VAR995_EVT_shock);
fprintf('VaR EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,99.9,VAR999_EVT_shock);
fprintf('VaR EVT %s@%2.2f%%: \t %9.2f EUR\n\n',tmp_scen_set,99.99,VAR9999_EVT_shock);

fprintf('ES  EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,90.0,ES90_EVT_shock);
fprintf('ES  EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,95.0,ES95_EVT_shock);
fprintf('ES  EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,97.5,ES975_EVT_shock);
fprintf('ES  EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,99.0,ES99_EVT_shock);
fprintf('ES  EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,confidence.*100,ES995_EVT_shock);
fprintf('ES  EVT %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,99.9,ES999_EVT_shock);
fprintf('ES  EVT %s@%2.2f%%: \t %9.2f EUR\n\n',tmp_scen_set,99.99,ES9999_EVT_shock);
fprintf('Low tail VAR: \n');
fprintf('VaR %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,50.0,-VAR50_shock);
fprintf('VaR %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,70.0,-VAR70_shock);
fprintf('VaR %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,90.0,-VAR90_shock);
fprintf('VaR %s@%2.1f%%: \t %9.2f EUR\n',tmp_scen_set,95.0,-VAR95_shock);

if ( mc < hd_limit )
    fprintf(fid, '\n');
    fprintf(fid, 'Difference to HD-VaR %s:  %9.2f EUR\n',tmp_scen_set,mc_var_shock_diff_hd);    
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
    title_string = strcat('Portfolio PnL ',tmp_scen_set);
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
    ylabel('Absolute PnL (in EUR)');
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
plottime = toc;
end     % end plotting
% ##############################    END  MC REPORTS    ########################################## 


% ##############################    BEGIN  STRESS REPORTS    ########################################## 
elseif ( strcmp(tmp_scen_set,'stress') )     % Stress scenario
    % prepare stresstest plotting and report output
    stresstest_plot_desc = {stresstest_struct.id};
    portfolio_stress    = zeros(no_stresstests,1);
    %  Loop via all positions
    for ii = 1 : 1 : length( position_struct )

        tmp_id = position_struct( ii ).id;
        tmp_quantity = position_struct( ii ).quantity;
        
        % get instrument data: get Position's Riskfactors and Sensitivities
        tmp_instr_object = get_sub_object(instrument_struct, tmp_id);
        tmp_value = tmp_instr_object.getValue('base');
        tmp_currency = tmp_instr_object.get('currency');
        tmp_name = tmp_instr_object.get('name');
        % Get instrument Value from full valuation instrument_struct:
        % absolute values from full valuation
        new_value_vec_stress    = tmp_instr_object.getValue('stress');

        % Get FX rate:
        if ( strcmp(tmp_currency,'EUR') == 1 )
            tmp_fx_value_stress = ones(no_stresstests,1);
        else
            %disp( ' Conversion of currency: ');
            tmp_fx_riskfactor   = strcat('RF_FX_', base_currency, tmp_currency);
            tmp_fx_struct_obj   = get_sub_object(riskfactor_struct, tmp_fx_riskfactor);
            tmp_fx_rate_base    = tmp_fx_struct_obj.getValue('base');
            tmp_fx_value_stress = tmp_fx_struct_obj.getValue('stress','abs');                       
        end
          
        % Store new Values in Position's struct
        pos_vec_stress  = new_value_vec_stress .*  sign(tmp_quantity) ./ tmp_fx_value_stress;
        octamat = [  pos_vec_shock ] ;
        position_struct( ii ).stresstests = pos_vec_stress;
        portfolio_stress = portfolio_stress .+ new_value_vec_stress .*  tmp_quantity ./ tmp_fx_value_stress;
    endfor
    % Calc absolute and relative stress values
    p_l_absolut_stress      = portfolio_stress .- base_value;
    p_l_relativ_stress      = (portfolio_stress .- base_value )./ base_value;

    fprintf(fid, '\n');
    fprintf(fid, '=====    STRESS RESULTS    ===== \n');
    fprintf(fid, '\n');
    fprintf(fid, 'Sensitivities on Positional Level: \n');
    for ii = 1 : 1 : length( position_struct )
        tmp_values_stress = [position_struct( ii ).stresstests];
        tmp_id = position_struct( ii ).id;
        
        % get instrument data: get Position's Riskfactors and Sensitivities
        tmp_instr_object = get_sub_object(instrument_struct, tmp_id);
        % tmp_value = tmp_instr_object.getValue('base');
        % tmp_currency = tmp_instr_object.get('currency');
        tmp_name = tmp_instr_object.get('name');

        % Get instrument IR and Spread sensitivity from stresstests 1-4:
        if ~( tmp_values_stress(end) == 0 ) % test for base values 0 (e.g. matured option )
            tmp_values_stress_rel = 100.*(tmp_values_stress .- tmp_values_stress(end)) ./ tmp_values_stress(end);
        else
            tmp_values_stress_rel = zeros(length(tmp_values_stress),1);
        endif
        tmp_ir_sensitivity = (abs(tmp_values_stress_rel(1)) + abs(tmp_values_stress_rel(2)))/2;
        tmp_spread_sensitivity = (abs(tmp_values_stress_rel(3)) + abs(tmp_values_stress_rel(4)))/2;
        fprintf(fid, '|Sensi ModDuration \t\t |%s|%s| = \t |%3.2f%%|\n',tmp_name,tmp_id,tmp_ir_sensitivity);
        fprintf(fid, '|Sensi ModSpreadDur \t |%s|%s| = \t |%3.2f%%|\n',tmp_name,tmp_id,tmp_spread_sensitivity);
    endfor 
 
    fprintf(fid, 'Stress test results:\n');
    for xx=1:1:no_stresstests
        fprintf(fid, 'Relative PnL in Stresstest: |%s| \t |%3.2f%%|\n',stresstest_plot_desc{xx},p_l_relativ_stress(xx).*100);
    endfor
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

% ##############################    END  STRESS REPORTS    ########################################## 

end % close kk loop: 


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
endfor % closing main portfolioloop mm

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

% III) #######         HELPER FUNCTIONS              ####
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
        endfor       
    end
    matches = b * c';
	if (matches > 0)
	    	match_struct = input_struct(matches);
		return;
	else
	    	error(' No matches found')
		return;
	end
end
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
        endfor       
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
% function for calculating VAR and ES from GPD calibrated parameters
% chi and sigma are GPD shape parameters, u is offset level, q is quantile, n is number of total scenarios, nu is number of tail scenarios
function [VAR ES] = get_gpd_var(chi, sigma, u, q, n, nu) 
    VAR = u .+ sigma/chi*(( n/nu *( 1- q ) )^(-chi) -1);
    ES = (VAR + sigma - chi * u) / ( 1 - chi );
end
% plot ( hd_plot_x, hd_vec_func, 'linewidth',1 );
%    %axis( [ 0 min(2 * confi_scenario, mc) ] ); 
%    xlabel('MC Scenario','fontsize',12);
%    ylabel('H-D','fontsize',12); 
%    title ('Harrell-Davis Estimator','fontsize',12);

%plot (pp,cdf_var250, 'linewidth',1);
%    set(gca,'xtick',[-1 -0.5 0 0.5 1]);
%    xlabel('x','fontsize',12);
%    ylabel('CDF(x)','fontsize',12);
%    title ('CDF for VaR250 Portfolio Value Distribution','fontsize',12);

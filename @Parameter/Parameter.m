classdef Parameter
   % file: @Parameter/Parameter.m
    properties
      name = '';
      id = '';
      description = '';
      type = ''; 
      path
      path_output
      path_output_instruments
      path_output_riskfactors
      path_output_stresstests
      path_output_positions
      path_output_mktdata
      path_reports
      path_archive
      path_input
      path_static
      path_mktdata
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
      input_filename_matrix = 'matrix_';
      % set general variables
      plotting = 1;           % switch for plotting data (0/1)
      saving = 0;             % switch for saving *.mat files (WARNING: that takes a long time for 50k scenarios and multiple instruments!)
      archive_flag = 0;       % switch for archiving input files to the archive folder (as .tar). This takes some seconds.
      stable_seed = 1;        % switch for using stored random numbers (1) or drawing new random numbers (0)
      mc_scen_analysis = 0;   % switch for applying statistical tests on risk factor MC scenario values 
      % VAR specific variables
      mc = 50000              % number of MonteCarlo scenarios
      hd_limit = 50001;       % below this MC limit Harrel-Davis estimator will be used
      confidence = 0.999      % level of confidence vor MC VAR calculation
      copulatype = 't'        % Gaussian  or t-Copula  ( copulatype in ['Gaussian','t'])
      nu = 10                 % single parameter nu for t-Copula 
      valuation_date = datenum('31-Dec-2015'); % valuation date
      fprintf('Valuation date: %s\n',any2str(datestr(valuation_date)));
      base_currency  = 'EUR'  % base reporting currency
      aggregation_key = {'asset_class','currency','id'}    % aggregation key
      mc_timesteps    = {'10d'}                % MC timesteps
      scenario_set    = [mc_timesteps,'stress'];          % append stress scenarios
      gpd_confidence_levels = [0.9;0.95;0.975;0.99;0.995;0.999;0.9999];   % vector with confidence levels used in reporting of EVT VAR and ES
      % specify unique runcode and timestamp:
      runcode = '2015Q4'; %substr(md5sum(num2str(time()),true),-6)
      timestamp = '20160424_175042'; %strftime ('%Y%m%d_%H%M%S', localtime (time ()))
      first_eval      = 0;
    end
   
 
   % Class methods
   methods
      function a = Parameter(tmp_name)
       % Matrix Constructor method
        if nargin < 1
            name        = 'Octarisk Parameter Object';
            tmp_id      = 'para_object';
        else
            name        = tmp_name;
            tmp_id      = tmp_name;
        end
        tmp_description = 'Octarisk Parameter Object';
        tmp_type        = 'Parameter';
        a.name          = name;
        a.id            = tmp_id;
        a.description   = tmp_description;
        a.type          = lower(tmp_type);                             
      end % Matrix
      
      function disp(a)
         % Display a Matrix object
         % Get length of Value vector:
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\n', ... 
            a.name,a.id,a.description,a.type);
         
      end % disp
      
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'Parameter')  )
            error('Type must be Parameter')
         end
         obj.type = type;
      end % Set.type
      
      
   end
   
end % classdef

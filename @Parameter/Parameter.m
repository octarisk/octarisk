classdef Parameter
   % file: @Parameter/Parameter.m
    properties
        name = 'Parameter';
        id = 'para_object';
        description = 'Parameter Object';
        type = 'Parameter'; 
        % input folder properties
        path_working_folder = '';
        folder_archive = 'archive';
        folder_input = 'input';
        folder_static = 'static';
        folder_mktdata = 'mktdata';

        % output folder
        folder_output = 'output';
        folder_output_instruments = 'instruments';
        folder_output_riskfactors = 'riskfactors';
        folder_output_stresstests = 'stresstests';
        folder_output_positions = 'positions';
        folder_output_mktdata = 'mktdata';
        folder_output_reports = 'reports';

        % full path to folder
        path_reports = '';
        path_archive = '';
        path_input = '';
        path_static = '';
        path_mktdata = '';

        % input filenames
        input_filename_instruments = 'instruments.csv';
        input_filename_corr_matrix = 'corr.csv';
        input_filename_stresstests = 'stresstests.csv';
        input_filename_riskfactors = 'riskfactors.csv';
        input_filename_positions = 'positions.csv';
        input_filename_mktdata = 'mktdata.csv';
        input_filename_seed = 'random_seed.dat';

        % set filenames for vola surfaces
        input_filename_vola_index = 'vol_index_';
        input_filename_vola_ir = 'vol_ir_';
        input_filename_surf_stoch = 'surf_stochastic_';
        input_filename_matrix = 'matrix_';

        % Boolean variables
        plotting = 1;
        saving = 0;
        archive_flag = 0;
        stable_seed = 1;
        mc_scen_analysis = 0;
        aggregation_flag = 0;
        first_eval = 1;
        frob_norm_limit = 0.05;   % Frobenius Norm: threshold of rlzd corrmat and 
                            % input corrmat, where to draw new random numbers
            
        % VAR specific variables
        mc = 50000;
        scen_number = 1;
        quantile_estimator = 'hd'; %{'hd', 'ep', 'ew', 'singular'}
        quantile_bandwidth = 50;
        quantile = 0.995;
        copulatype = 'Gaussian';
        nu = 10;
        rnd_number_gen = 'Mersenne-Twister';
        valuation_date = today;
        no_stresstests = 1;
        use_sobol = false;
        sobol_seed = 1;
        filename_sobol_direction_number = 'new-joe-kuo-6.21201'; % Reference: http://web.maths.unsw.edu.au/~fkuo/sobol/
        path_sobol_direction_number = 'static';

        % Aggregation specific variables
        base_currency = 'EUR';
        aggregation_key = {'asset_class','currency','id'};
        mc_timesteps = {'250d'};
        scenario_set = {'250d','stress'};

        % specify unique runcode and timestamp:
        runcode = '';
        timestamp = '';
    end
 
 
   % Class methods
   methods
      function a = Parameter(tmp_name)
       % Parameter Constructor method
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
      end % Parameter
      
      function disp(a)
         % Display a Parameter object
         % Get length of Value vector:
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\n', ... 
            a.name,a.id,a.description,a.type);
         props = fieldnames(a);
         for (ii=1:1:length(props))
            fprintf('%s: %s\n',props{ii},any2str(a.(props{ii})));
         end
         
      end % disp
      
      function obj = set.quantile_estimator(obj,quantile_estimator)
         quantile_estimator = lower(quantile_estimator);
         quantile_estimator_cell = {'hd', 'ep', 'ew', 'singular'};
         if ( sum(strcmpi(quantile_estimator_cell,quantile_estimator)) == 0)
                fprintf('Need valid quantile_estimator state:  >>%s<< not in {hd, ep, ew, singular} for id >>%s<<. Setting to default value hd. See help get_quantile_estimator for more information.\n',quantile_estimator,obj.id);
                quantile_estimator = 'hd';
            end
          obj.quantile_estimator = quantile_estimator;
      end % set.quantile_estimator
      
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'Parameter')  )
            error('Type must be Parameter')
         end
         obj.type = type;
      end % Set.type
      
      
      function obj = set.valuation_date(obj,valuation_date) % convert to datenum
         if ischar(valuation_date)
            valuation_date = datenum(valuation_date);
         elseif ( isvector(valuation_date) )
            if ( length(valuation_date) > 1)
                valuation_date = datenum(valuation_date);
            end
         end
         obj.valuation_date = valuation_date;
      end % Set.valuation_date
      
      
   end
   
end % classdef

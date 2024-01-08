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
        input_filename_mc_mapping = 'mc-mapping.csv';

        % set filenames for vola surfaces
        input_filename_vola_index = 'vol_index_';
        input_filename_vola_ir = 'vol_ir_';
        input_filename_surf_stoch = 'surf_stochastic_';
        input_filename_matrix = 'matrix_';
        
        % redis database parameter
        redis_ip = '127.0.0.1'
        redis_dbnr = 1
        redis_port = 6379
        

        % Boolean variables
        plotting = 1;
        reporting = 1;
        idx_figure = 1;
        calc_marg_incr_var = 0;
        saving = 0;
        archive_flag = 0;
        stable_seed = 1;
        mc_scen_analysis = 0;
        aggregation_flag = 0;
        export_to_redis_db = 0;
        cvar_flag = 0;
        no_stresstest_plot = 1;
        first_eval = 1;
        use_parallel_pkg = 0;
        number_parallel_cores = 4;
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
        reporting_date = today;
        no_stresstests = 1;
        use_sobol = false;
        sobol_seed = 1;
        filename_sobol_direction_number = 'new-joe-kuo-6.21201'; % Reference: http://web.maths.unsw.edu.au/~fkuo/sobol/
        path_sobol_direction_number = 'static';
        shred_type =  'TOTAL'; %{'IR','EQ'}; %
        cvar_type = 'base'; %

        % WRT amd SII standard model specific variables
        calc_sm_scr = false;
        type_of_undertaking 	= 'Retail';		% S.01.02.01 General QRT
        country_authorization 	= 'Germany';	% S.01.02.01 General QRT
        language_reporting 		= 'English';	% S.01.02.01 General QRT
        financial_year_end 		= '12/31';		% S.01.02.01 General QRT
        submission_type 		= 'Regular';	% S.01.02.01 General QRT
        accounting_standards 	= 'Custom';		% S.01.02.01 General QRT
        scr_calculation_method 	= 'MC Full Valuation';	% S.01.02.01 General QRT
        
        % Aggregation specific variables
        base_currency = 'EUR';
        aggregation_key = {'asset_class','currency','id'};
        mc_timestep = '';
        mc_timestep_days = 0;
        scenario_set = {'stress'};
        tax_rate = 0.0;

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
      
       function obj = set.shred_type(obj,shred_type)
		 if ~(sum(strcmpi(shred_type,{'TOTAL','IR','SPREAD','COM','EQ','VOLA','ALT','RE','FX','INFL'}))>0  )
			error('Shred type must be either TOTAL, IR, SPREAD, COM, RE, EQ, VOLA, ALT, INFL or FX')
		 end
         obj.shred_type = shred_type;
      end % Set.shred_type
      
      function obj = set.cvar_type(obj,cvar_type)
         if ~(sum(strcmpi(cvar_type,{'base','IR+100bp','EQ-30pct','Crisis'}))>0  )
            error('CVaR type must be (either) BASE, EQ-30pct, Crisis or IR+100bp')
         end
         obj.cvar_type = cvar_type;
         if ~(strcmpi(cvar_type,'base'))
            obj.cvar_flag = 1;
         end
      end % Set.cvar_type
      
      
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

% Risk Factor Superclass, for documentation see dummy function doc_riskfactor.m
classdef Riskfactor
   % file: @Riskfactor/Riskfactor.m
   properties
      name = '';
      id = '';
      description = '';
      model = '';      
      mean
      std
      skew
      kurt
      value_base = 0.0;
      mr_level
      mr_rate
      node = 0;
      node2 = 0;
      node3 = 0;
      type = '';
	  sln_level = 0.0;
   end
   
    properties (SetAccess = protected )
      scenario_stress = [];
      scenario_mc = [];
      shift_type = [];
	  shocktype_mc = '';	% either relative or absolute
      timestep_mc = {};
    end
 
   % Class methods
   methods
        
      function a = Riskfactor(tmp_name)
      % Riskfactor Constructor method
        if nargin < 1
            tmp_name            = 'Test Risk Factor';
            tmp_id              = 'RF_EUR-INDEX-TEST';
        else 
            tmp_id = tmp_name;
        end
        a.name          = tmp_name;
        a.id            = tmp_id;
        a.description   = 'Test risk factor for multi purpose use';
        a.type          = 'RF_EQ';
        a.model         = 'GBM';
        a.mean          = 0.0;
        a.std           = 0.25;
        a.skew          = 0.0;
        a.kurt          = 3.0;
      end % Riskfactor constructor
      
      function disp(a)
         % Display a Riskfactor object
         % Get length of Value vector:
         scenario_stress_rows = min(rows(a.scenario_stress),5);
         scenario_mc_rows = min(rows(a.scenario_mc),5);
         scenario_mc_cols = min(length(a.scenario_mc),2);
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\nmodel: %s\n', ... 
            a.name,a.id,a.description,a.type,a.model);
         fprintf('mean: %f\nstandard deviation: %f\nskewness: %f\nkurtosis: %f\n', ... 
            a.mean,a.std,a.skew,a.kurt);
         if ( sum(strcmp(a.model,{'OU','BKM','SRD'})) > 0) 
            fprintf('mr_level: %f\n',a.mr_level); 
            fprintf('mr_rate: %f\n',a.mr_rate); 
         end
         if ( regexp('RF_IR',a.type) || regexp('RF_SPREAD',a.type) )
            fprintf('node: %d\n',a.node); 
            fprintf('rate: %f\n',a.value_base); 
         end
         if ( length(a.scenario_stress) > 0 ) 
            fprintf('Scenario stress: %8.5f \n',a.scenario_stress(1:scenario_stress_rows));
            fprintf('\n');
         end
         % looping via first 5 MC scenario values
         for ( ii = 1 : 1 : scenario_mc_cols)
            if ( length(a.timestep_mc) >= ii )
                fprintf('MC timestep: %s\n',a.timestep_mc{ii});
                fprintf('Scenariovalue: %8.5f \n',a.scenario_mc(1:scenario_mc_rows,ii));
            end
            
            fprintf('\n');
         end
      end % disp
      
      function obj = set.model(obj,model)
         if ~(strcmpi(model,'GBM') || strcmpi(model,'BM') || strcmpi(model,'BKM') || strcmpi(model,'OU') || strcmpi(model,'SRD') || strcmpi(model,'SLN') )
            error('Model must be either GBM, BM, BKM, SLN, OU or SRD')
         end
         obj.model = model;
      end % Set.model
      
      function obj = set.type(obj,type)
         if ~(sum(strcmpi(type,{'RF_IR','RF_SPREAD','RF_COM','RF_EQ','RF_VOLA','RF_ALT','RF_RE','RF_FX'}))>0  )
            error('Risk factor type must be either RF_IR, RF_SPREAD, RF_COM, RF_RE, RF_EQ, RF_VOLA, RF_ALT or RF_FX')
         end
         obj.type = type;
      end % Set.type
	  
	  % function obj = set.shift_type(obj,shift_type)
	    % if ( rows(obj.scenario_stress) > 1)
			% shift_type
			% obj.scenario_stress
			% if ( rows(shift_type) ~= rows(obj.scenario_stress))
				% error('Riskfactor: ID >>%s<< Length of shift_types (%d) and stress scenarios (%d) does not match.',any2str(obj.id),rows(shift_type),rows(obj.scenario_stress))
			% end
		% end
         % obj.shift_type = shift_type;
      % end % Set.shift_type
	  
	  % function obj = set.scenario_stress(obj,scenario_stress)
		% scenario_stress
		% obj.shift_type
	    % if ( rows(obj.shift_type) > 1)
			% if ( rows(obj.shift_type) ~= rows(scenario_stress))
				% error('Riskfactor: ID >>%s<< Length of shift_types (%d) and stress scenarios (%d) does not match.',any2str(obj.id),rows(obj.shift_type),rows(scenario_stress))
			% end
		% end
        % obj.scenario_stress = scenario_stress;
      % end % Set.scenario_stress

    end
    methods (Static = true)
    
      function basis = get_basis(dcc_string)
            % provide static method for converting dcc string into basis value
            basis = get_basis(dcc_string);
      end %get_basis
      
      % The following function returns a vector with absolut scenario values depending on the start value and the scenario delta vector
      function ret_vec = get_abs_values(model, scen_deltavec, value_base, sensitivity)
        if nargin < 3
            error('Not enough arguments. Please provide model, scenario deltas and value_base and sensitivity (optional)');
        end
        if nargin < 4
            sensitivity = 1;
        end
        if ( sum(strcmp(model,{'GBM','BKM'})) > 0 ) % Log-normal Motion
            ret_vec     =  exp(scen_deltavec .* sensitivity) .* value_base;
        else        % Normal Model
            ret_vec     = (scen_deltavec .* sensitivity) + value_base;
        end
      end % get_abs_values
      
      function retval = get_doc(format,path)
        if nargin < 1
            format = 'plain text';
        end
        if nargin < 2
            printflag = 0;
        elseif nargin == 2
            if (ischar(path) && length(path) > 1)
                printflag = 1;
            else
                error('Insufficient path: %s \n',path);
            end
        end
        % printing documentation for Class Riskfactor (outsourced to dummy function to use documentation behaviour)
        scripts = ['doc_riskfactor'];
        c = cellstr(scripts);
        for ii = 1:length(c)
            [retval status] = __makeinfo__(get_help_text(c{ii}),format);
        end
        if ( status == 0 )
            if ( printflag == 1) % print to file
                if (strcmp(format,'html'))
                    ending = '.html';
                    %replace html title
                    repstring = strcat('<title>', c{ii} ,'</title>');
                    retval = strrep( retval, '<title>Untitled</title>', repstring);
                elseif (strcmp(format,'texinfo'))
                    ending = '.texi';
                else
                    ending = '.txt';
                end
                filename = strcat(path,c{ii},ending);
                fid = fopen (filename, 'w');
                fprintf(fid, retval);
                fprintf(fid, '\n');
                fclose (fid); 
            else    
                fprintf('Documentation for Class %s: \n',c{ii}(4:end));
                fprintf(retval);
                fprintf('\n');
            end
                     
        else
            disp('There was a problem')
        end
        retval = status;
      end
            
   end
   
end % classdef

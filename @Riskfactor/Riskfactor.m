% Risk Factor Superflass, for documentation see dummy function doc_riskfactor.m
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
      value_base = 1;
      mr_level
      mr_rate
      node
      type = ''; 
   end
   
    properties (Access = protected )
      scenario_stress = [];
      scenario_mc = [];
      shift_type = [];
    end
    properties (SetAccess = protected )
      timestep_mc = {};
    end
 
% model	mean	standard_deviation	skewness	kurtosis	
% GBM	    x	    x	                x	        x	    IR node	        IR value			
% BM	    x	    x	                x	        x	    IR node	        IR value			
% SRD	    x	    x	                x	        x	    start value	    mr level	mr rate	    IR node	  IR value
% OU	    x	    x	                x	        x	    start value	    mr level	mr rate	    IR node	  IR value

 
   % Class methods
   methods
        
      function a = Riskfactor(tmp_name,tmp_id,tmp_type,tmp_description,tmp_model,tmp_parameters)
         % Riskfactor Constructor method
        if nargin < 6
            tmp_name            = 'Test Risk Factor';
            tmp_id              = 'RF_IR_TEST';
            tmp_description     = 'Test risk factor for multi purpose use';
            tmp_type            = 'RF_IR';
            tmp_model           = 'SRD';
            tmp_parameters      = [0.0,0.16,-0.5,4.0,0.034,0.05,0.00001,365,0.024567];
        end 
        if ( strcmp(tmp_id,''))
            error('Error: Risk factor requires a valid ID')
        end
        if ( length(tmp_parameters) < 4)
            error('Error: Risk factor requires a at least mean,std,skew,kurt')
        end
        a.name          = tmp_name;
        a.id            = tmp_id;
        a.description   = tmp_description;
        a.type          = upper(tmp_type);
        a.model         = tmp_model;
        a.mean          = tmp_parameters(1);
        a.std           = tmp_parameters(2);
        a.skew          = tmp_parameters(3);
        a.kurt          = tmp_parameters(4);
        % Get model dependent parameters
        if ( sum(strcmp(a.model,{'GBM','BM'})) > 0) 
            if ( strcmp('RF_IR',a.type(1:5)) || strcmp('RF_SP',a.type(1:5)) )
                if ( length(tmp_parameters) > 4 )
                    a.node  = tmp_parameters(5);          
                    a.value_base  = tmp_parameters(6);
                else
                    error('Error: Risk factor type RF_IR has no defined IR node or value')
                end
            else
                if ( length(tmp_parameters) > 4 )
                    a.value_base  = tmp_parameters(5);
                end    
            end
        else    % Mean reversion models (OE,SRD,BKM)
            a.value_base  = tmp_parameters(5);
            a.mr_level  = tmp_parameters(6);
            a.mr_rate  = tmp_parameters(7);
            if ( strcmp('RF_IR',a.type(1:5)) || strcmp('RF_SP',a.type(1:5)) )
                if ( length(tmp_parameters) > 7 )
                    a.node  = tmp_parameters(8);         
                    a.value_base  = tmp_parameters(9);
                else
                    error('Error: Risk factor type RF_IR has no defined IR node or value')    
                end   
            end
        end
               
      end % Riskfactor
      
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
            fprintf('value_base: %f\n',a.value_base); 
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
         if ~(strcmpi(model,'GBM') || strcmpi(model,'BM') || strcmpi(model,'BKM') || strcmpi(model,'OU') || strcmpi(model,'SRD') )
            error('Model must be either GBM, BM, BKM, OU or SRD')
         end
         obj.model = model;
      end % Set.model
      
      function obj = set.type(obj,type)
         if ~(sum(strcmpi(type,{'RF_IR','RF_SPREAD','RF_COM','RF_EQ','RF_VOLA','RF_ALT','RF_RE','RF_FX'}))>0  )
            error('Risk factor type must be either RF_IR, RF_SPREAD, RF_COM, RF_RE, RF_EQ, RF_VOLA, RF_ALT or RF_FX')
         end
         obj.type = type;
      end % Set.type
      
    end
    methods (Static = true)
    
      function basis = get_basis(dcc_string)
            dcc_cell =  {'act/act' '30/360 SIA' 'act/360' 'act/365' '30/360 PSA' '30/360 ISDA' '30/360 European' 'act/365 Japanese' 'act/act ISMA' 'act/360 ISMA' 'act/365 ISMA' '30/360E' };
            findvec = strcmp(dcc_string,dcc_cell);
            tt = 1:1:length(dcc_cell);
            tt = (tt - 1)';
            basis = dot(single(findvec),tt);
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
        % printing documentation for Class Riskfactor (ousourced to dummy function to use documentation behaviour)
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

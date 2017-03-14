classdef Index		% Superclass
   % file: @Index/Index.m
   properties
      name = '';
      id = '';
      description = '';
      currency = 'EUR';
      value_base = 1;
      type = ''; 
   end
   
    properties (SetAccess = protected )
      scenario_stress = [];
      scenario_mc = [];
      shift_type = [];
      timestep_mc = {};
    end
 
   % Class methods
   methods
        
      function a = Index(tmp_name)
         % Index Constructor method
        if nargin < 1
            tmp_name            = 'Test Index';
            tmp_id              = 'EUR-INDEX-TEST';
        else 
            tmp_id = tmp_name;
        end 
        tmp_currency    = 'EUR';
        tmp_description = 'Test index for multi purpose use';
        tmp_type        = 'Equity Index';
        tmp_value_base  = 10321.45;

        a.name          = tmp_name;
        a.id            = tmp_id;
        a.description   = tmp_description;
        a.type          = upper(tmp_type);
        a.currency      = tmp_currency;
        a.value_base    = tmp_value_base;           
      end % Index
      
      function disp(a)
         % Display a Index object
         % Get length of Value vector:
         scenario_stress_rows = min(rows(a.scenario_stress),5);
         scenario_mc_rows = min(rows(a.scenario_mc),5);
         scenario_mc_cols = min(length(a.scenario_mc),2);
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s \ncurrency: %s\n', ... 
            a.name,a.id,a.description,a.type,a.currency);
         fprintf('value_base: %8.5f\n',a.value_base);
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
           
      function obj = set.type(obj,type)
         if ~(sum(strcmpi(upper(type),{'EQUITY INDEX','BOND INDEX','VOLATILITY INDEX','COMMODITY INDEX','REAL ESTATE INDEX','EXCHANGE RATE','CPI'}))>0  )
            error('Risk factor type must be either EQUITY INDEX, BOND INDEX, VOLATILITY INDEX, COMMODITY INDEX, REAL ESTATE INDEX,EXCHANGE RATE,CPI')
         end
         obj.type = type;
      end % Set.type
      
    end
    
    methods (Static = true)
    
      function basis = get_basis(dcc_string)
            % provide static method for converting dcc string into basis value
            basis = get_basis(dcc_string);
      end %get_basis
      
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
        % printing documentation for Class Index (ousourced to dummy function to use documentation behaviour)
        scripts = ['doc_index'];
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

      % print Help text
	  function retval = help (format,retflag)
		formatcell = {'plain text','html','texinfo'};
		% input checks
		if ( nargin == 0 )
			format = 'plain text';	
		end
		if ( nargin < 2 )
			retflag = 0;	
		end

		% format check
		if ~( strcmpi(format,formatcell))
			fprintf('WARNING: Index.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
			format = 'plain text';
		end	

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Index(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Index()\n\
\n\
Class for setting up Index objects.\n\
\n\
Index class is used for specifying asset indizes, exchange rates and consumer price\n\
indizes. Indizes serve as underlyings for e.g. Options or Forwards, are used\n\
to set up forex rates or CPI indizes for inflation linked products.\n\
Indizes can be shocked with risk factors (e.g. risk factor types RF_EQ or RF_FX)\n\
or in MC scenarios.\n\
\n\
This class contains all attributes and methods related to the following Index types:\n\
\n\
@itemize @bullet\n\
@item EQUITY INDEX\n\
@item BOND INDEX\n\
@item VOLATILITY INDEX\n\
@item COMMODITY INDEX\n\
@item REAL ESTATE INDEX\n\
@item EXCHANGE RATE\n\
@item CPI (Consumer Price index)\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Index object @var{obj}:\n\
@itemize @bullet\n\
@item Index(@var{id}) or Index(): Constructor of a Index object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.getValue(@var{scenario}): Return Index value according to scenario type.\n\
\n\
@item Index.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
\n\
@item Index.get_basis(@var{dcc_string}): Return basis integer value for \n\
given day count convention string. [static method]\n\
@end itemize\n\
\n\
Attributes of Index objects:\n\
@itemize @bullet\n\
@item @var{id}: Index id. Has to be unique identifier. Default: empty string.\n\
@item @var{name}: Index name. Default: empty string.\n\
@item @var{description}: Index description. Default: empty string.\n\
@item @var{type}: Index type. Can be [EQUITY INDEX, BOND INDEX, VOLATILITY INDEX,\n\
COMMODITY INDEX, REAL ESTATE INDEX, EXCHANGE RATE, CPI]. Default: empty string.\n\
@item @var{value_base}:  Base value of index. Default: 1.0\n\
@item @var{currency}: Index currency. Default: \'EUR\'\n\
\n\
@item @var{scenario_mc}: Vector with Monte Carlo index values. \n\\n\
@item @var{scenario_stress}: Vector with Stress index values. \n\
@item @var{timestep_mc}: String Cell array with MC timesteps. Automatically appended if values for new timesteps are set.\n\
@item @var{shift_type}: (unused) Specify a vector specifying stress index shift type .\n\
Can be either 0 (absolute) or 1 (relative) shift.\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
@example\n\
@group\n\
\n\
disp('Setting up an equity index and Exchange Rate')\n\
i = Index();\n\
i = i.set('id','MSCIWORLD','value_base',1000, ...\n\
	'scenario_stress',[2000;1333;800],'currency','USD');\n\
fx = Index();\n\
fx = fx.set('id','FX_EURUSD','value_base',1.1,  ...\n\
	'scenario_stress',[1.2;1.18;1.23]);\n\
@end group\n\
@end example\n\
\n\
@end deftypefn";

		% format help text
		[retval status] = __makeinfo__(textstring,format);
		% status
		if (status == 0)
			% depending on retflag, return textstring
			if (retflag == 0)
				% print formatted textstring
				fprintf("\'Index\' is a class definition from the file /octarisk/@Index/Index.m\n");
				fprintf("\n%s\n",retval);
				retval = [];
			end
		end

	  end % end of static method help
	
   end	% end of static methods
            
   
end % classdef

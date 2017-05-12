classdef Surface
   % file: @Surface/Surface.m
    properties
      name = '';
      id = '';
      description = '';
      type = ''; 
      moneyness_type = 'K/S'; % in list {'K/S','K-S'}
      compounding_type = 'cont';
      compounding_freq = 'annual';               
      day_count_convention = 'act/365';
      method_interpolation = 'linear';    % 3D: [linear,nearest]
      shock_struct = struct();      % structure containing risk factor shocks
      riskfactors = {};             % cell containing all risk factors
    end
   
    properties (SetAccess = protected )
      axis_x = [];
      axis_y = [];
      axis_z = [];
      values_base = [];
      axis_x_name = '';
      axis_y_name = '';
      axis_z_name = ''; 
      basis = 3;      
    end
 
   % Class methods
   methods
      function a = Surface(tmp_name)
       % Surface Constructor method
        if nargin < 1
            name        = 'Index Test Vola Surface';
            tmp_id      = 'VOLA_INDEX_EUR';
        else
            name        = tmp_name;
            tmp_id      = tmp_name;
        end
        tmp_description = 'Test Dummy Surface';
        tmp_type        = 'INDEX';
        a.name          = name;
        a.id            = tmp_id;
        a.description   = tmp_description;
        a.type          = upper(tmp_type);  
      end % Surface
      
      function disp(a)
         % Display a Surface object
         % Get length of Value vector:
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\n', ... 
            a.name,a.id,a.description,a.type);
         fprintf('moneyness_type: %s\n',a.moneyness_type);
         fprintf('method_interpolation: %s\n',a.method_interpolation);
         fprintf('riskfactors: %s\n',any2str(a.riskfactors));
         % looping via all x axis values if defined
         if ( length(a.axis_x) > 0 )
            fprintf('Axis x %s : Values :\n[ ',a.axis_x_name);
            for (ii = 1 : 1 : length(a.axis_x))
                fprintf('%d,',a.axis_x(ii));
            end
            fprintf(' ]\n');
         end
         % looping via all y axis values if defined
         if ( length(a.axis_y) > 0 )
            fprintf('Axis y %s : Values :\n[ ',a.axis_y_name);
            for (ii = 1 : 1 : length(a.axis_y))
                fprintf('%d,',a.axis_y(ii));
            end
            fprintf(' ]\n');
         end
         % looping via all z axis values if defined
         if ( length(a.axis_z) > 0 )
            fprintf('Axis z %s : Values :\n[ ',a.axis_z_name);
            for (ii = 1 : 1 : length(a.axis_z))
                fprintf('%d,',a.axis_z(ii));
            end
            fprintf(' ]\n');
         end
         
         % looping via all values if defined
         if ( length(a.values_base) > 0 )
            fprintf('Surface base values:\n[ ');
            [aa bb cc ] = size(a.values_base);
            for ( kk = 1 : 1 : cc)
                if ( length(a.axis_z) == cc );fprintf('%s : %d\n',a.axis_z_name, a.axis_z(kk));end;
                for ( jj = 1 : 1 : aa)
                    fprintf('%f,',a.values_base(jj,:,kk));
                    fprintf('\n');
                end
            end
            fprintf(' ]\n');
         end   
      end % disp
      
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'Index') || strcmpi(type,'IR')  ...
                || strcmpi(type,'Dummy')  || strcmpi(type,'Prepayment') ...
                || strcmpi(type,'Stochastic')                 )
            error('Type must be either Index, IR, Stochastic, Prepayment or Dummy Surface')
         end
         obj.type = type;
      end % Set.type
      
      function obj = set.day_count_convention(obj,day_count_convention)
        obj.day_count_convention = day_count_convention;
        % Call superclass method to set basis
        obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
      
      function obj = set.moneyness_type(obj,moneyness_type)
        moneyness_type = upper(moneyness_type);
        moneyness_type = strrep (moneyness_type,' ', '');
        if ~(sum(strcmpi(moneyness_type,{'K/S','K-S'}))>0  )
            fprintf('Curve:set: for curve >>%s<<: moneyness_type >>%s<< must be K/S or K-S. Setting to >>K/S<<\n',obj.id,moneyness_type);
            moneyness_type = 'K/S';
        end
         obj.moneyness_type = moneyness_type;
      end % set.moneyness_type
      
      function obj = set.compounding_freq(obj,compounding_freq)
        compounding_freq = lower(compounding_freq);
        if ~(sum(strcmpi(compounding_freq,{'day','daily','week','weekly','month','monthly','quarter','quarterly','semi-annual','annual'}))>0  )
            fprintf('Curve:set: for curve >>%s<<: compounding_freq >>%s<< must be either day,daily,week,weekly,month,monthly,quarter,quarterly,semi-annual,annual. Setting to >>annual<<\n',obj.id,compounding_freq);
            compounding_freq = 'annual';
        end
         obj.compounding_freq = compounding_freq;
      end % set.compounding_freq
      
      
      function obj = set.compounding_type(obj,compounding_type)
        compounding_type = lower(compounding_type);
        if ~(sum(strcmpi(compounding_type,{'simple','continuous','discrete'}))>0  )
            fprintf('Curve:set: for curve >>%s<<: Compounding type >>%s<< must be either >>simple<<, >>continuous<<, or >>discrete<<. Setting to >>continuous<<\n',obj.id,compounding_type);
            compounding_type = 'continuous';
        end
         obj.compounding_type = compounding_type;
      end % set.compounding_type
      
      function obj = set.method_interpolation(obj,method_interpolation)
         if ~(sum(strcmpi(method_interpolation,{'linear','nearest'}))>0  )
            error('Interpolation method >>%s<< must be linear or nearest.',any2str(method_interpolation))
         end
         obj.method_interpolation = method_interpolation;
      end % Set.method_interpolation
      
   end
   
   methods (Static = true)
         
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
			fprintf('WARNING: Surface.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
			format = 'plain text';
		end	

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Surface(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Surface()\n\
\n\
Class for setting up Surface objects.\n\
\n\
Surface class is used for specifying Index, IR, Stochastic, Prepayment or Dummy Surfaces.\n\
A Surface (or Cube) stores two- or three-dimensional values (e.g. term, tenor and/or\n\
moneyness dependent volatility values.\n\
Surfaces can be shocked with risk factors (e.g. risk factor types RF_VOLA_EQ or RF_VOLA_IR)\n\
at any coordinates of the multi-dimensional space in MC or stress scenarios.\n\
\n\
This class contains all attributes and methods related to the following Surface types:\n\
\n\
@itemize @bullet\n\
@item @var{Index} two-dimensional surface (term vs. moneyness) for setting up Equity volatility values.\n\
@item @var{IR} two- or three-dimensional surface (term vs. moneyness) / cube (term vs. tenor vs. moneyness)\n\
for setting up Interest rate volatility values.\n\
@item @var{Stochastic} one- or two-dimensional curve / surface to store scenario dependent values\n\
(e.g. stochastic cash flow surface with values dependent on date and quantile)\n\
@item @var{Prepayment} two-dimensional prepayment surface with prepayment factors dependent\n\
on e.g. interest rate shock and coupon rates.\n\
@item @var{Dummy} Dummy curve for various purposes.\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Surface object @var{obj}:\n\
@itemize @bullet\n\
@item Surface(@var{id}) or Surface(): Constructor of a Surface object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.getValue(@var{scenario}, @var{x}, @var{y}, @var{z}): Return Surface value at given coordinates according to scenario type.\n\
Interpolate surface base value and risk factor shock (only possible after call of method @var{apply_rf_shocks} )\n\
\n\
@item Surface.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
\n\
@item obj.apply_rf_shocks(@var{riskfactor_struct}): Apply risk factor shocks to Surface base values and store\n\
the shocks for later use in attribute @var{shock_struct}. These shocks are then applied to the surface base value with method getValue.\n\
The risk factors are taken from the provided structure according to the surface risk factor IDs given by the attribute @var{riskfactors}.\n\
\n\
@item Surface.interpolate(@var{x}, @var{y}, @var{z}): Return Surface base value at given coordinates.\n\
@end itemize\n\
\n\
Attributes of Surface objects:\n\
@itemize @bullet\n\
@item @var{id}: Surface id. Has to be unique identifier. Default: empty string.\n\
@item @var{name}: Surface name. Default: empty string.\n\
@item @var{description}: Surface description. Default: empty string.\n\
@item @var{type}: Surface type. Can be [Index, IR, Stochastic, Prepayment, Dummy Surfaces]. Default: Index.\n\
@item @var{day_count_convention}: Day count convention of curve. See \'help get_basis\' \n\
for details (Default: \'act/365\')\n\
@item @var{compounding_type}: Compounding type. Can be continuous, discrete or simple. \n\
(Default: \'cont\')\n\
@item @var{compounding_freq}: Compounding frequency used for discrete compounding.\n\
Can be [daily, weekly, monthly, quarterly, semi-annual, annual]. (Default: \'annual\')\n\
@item @var{values_base}:  Base values of Surface.\n\
@item @var{moneyness_type}:  Moneyness type. Can be K/S for relative moneyness\n\
or K-S for absolute moneyness. (Default: \'K/S'\).\n\
@item @var{shock_struct}: Structure containing all risk factor shock specifications\n\
(e.g. model, risk factor coordinates, shock values and shift type)\n\
@item @var{riskfactors}: Cell specifying all risk factor IDs\n\
@item @var{axis_x}: x-axis coordinates\n\
@item @var{axis_y}: y-axis coordinates\n\
@item @var{axis_z}: z-axis coordinates\n\
@item @var{axis_x_name}: x-axis name\n\
@item @var{axis_y_name}: y-axis name\n\
@item @var{axis_z_name}: z-axis name\n\
\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
@example\n\
@group\n\
\n\
disp('Setting up an Index Surface and Risk factor, apply shocks and retrieve values:')\n\
r1 = Riskfactor();\n\
r1 = r1.set('id','V1','scenario_stress',[1.0;-0.5], ...\n\
'model','GBM','shift_type',[1;1], ...\n\
'node',730,'node2',1);\n\
riskfactor_struct(1).id = r1.id;\n\
riskfactor_struct(1).object = r1;\n\
v = Surface();\n\
v = v.set('id','V1','axis_x',[365,3650], ...\n\
'axis_x_name','TERM','axis_y',[0.9,1.0,1.1], ...\n\
'axis_y_name','MONEYNESS');\n\
v = v.set('values_base',[0.25,0.36;0.22,0.32;0.26,0.34]);\n\
riskfactor_cell = cell;\n\
riskfactor_cell(1) = 'V1';\n\
v = v.set('type','INDEX','riskfactors',riskfactor_cell);\n\
v = v.apply_rf_shocks(riskfactor_struct);\n\
base_value = v.interpolate(365,0.9)\n\
base_value = v.getValue('base',365,0.9)\n\
stress_value = v.getValue('stress',365,0.9)\n\
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
				fprintf("\'Surface\' is a class definition from the file /octarisk/@Surface/Surface.m\n");
				fprintf("\n%s\n",retval);
				retval = [];
			end
		end

	  end % end of static method help
	
   end	% end of static methods
   
end % classdef

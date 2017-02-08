%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
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

classdef Curve
   % file: @Curve/Curve.m
    properties
      name = '';
      id = '';
      description = '';
      type = '';  
      method_interpolation = 'linear'; %'monotone-convex'; 
	  method_extrapolation = 'constant'; %'linear'
      compounding_type = 'cont';
      compounding_freq = 'annual';               
      day_count_convention = 'act/365'; 
      shocktype_mc = 'absolute';
	  shocktype_stress = 'absolute';
      increments = '';
      alpha = 0.19; % alpha parameter for Smith-Wilson interpolation method
      ufr = 0.042; % ultimate forward rate for Smith-Wilson interpolation method
      american_flag = 0; % specifying option type if used as call or put schedule
      curve_function = 'sum';   % required for aggregated curves
      curve_parameter = 1;      % required for aggregated curves
	  sln_level = [];			% required for shifted log-normal model of risk factors
    end
   
    properties (SetAccess = protected )
      timestep_mc = {};
      nodes = [];
      rates_base = [];
      rates_mc  = [];
      rates_stress = [];
      basis = 3;
      floor = '';
      cap = '';
    end
 
   % Class methods
   methods
      function a = Curve(tmp_name)
         % Riskfactor Constructor method
        if nargin < 1
            name        = 'Test Curve';
            tmp_id      = 'IR_EUR_TEST';
        else
            name        = tmp_name;
            tmp_id      = tmp_name;
        end
        tmp_description = 'Test Dummy Curve';
        tmp_type        = 'Discount Curve';
        a.name          = name;
        a.id            = tmp_id;
        a.description   = tmp_description;
        a.type          = upper(tmp_type);
                     
      end % Curve
      
      function disp(a)
         % Display a Curve object
         % Get length of Value vector:
         rates_stress_rows = min(rows(a.rates_stress),5);
         [mc_rows mc_cols mc_stack] = size(a.rates_mc);
         rates_stress_cols = min(length(a.rates_stress),2);
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\n', ... 
            a.name,a.id,a.description,a.type);
         fprintf('method_interpolation: %s\n',a.method_interpolation);
         fprintf('compounding_type: %s\n',a.compounding_type);
         fprintf('compounding_freq: %s\n',a.compounding_freq);
         fprintf('day_count_convention: %s\n',a.day_count_convention);
         fprintf('dcc_basis: %d\n',a.basis);
         fprintf('shocktype_mc: %s\n',a.shocktype_mc);
         if ( regexpi(a.type,'Schedule'))
            fprintf('american_flag: %s\n',any2str(a.american_flag));
         end
         if ( isnumeric(a.floor))
			fprintf('floor rate: %f\n',a.floor);
         end
         if ( isnumeric(a.cap))
			fprintf('cap rate: %f\n',a.cap);
         end
         % looping via all riskfactors / sensitivities
         if ( length(a.increments) > 0 )
             for ( ii = 1 : 1 : length(a.increments))
                fprintf('Increments: %s \n',a.increments{ii});            
             end
         end
         % looping via all nodes if defined
         if ( length(a.nodes) > 0 )
            fprintf('Nodes:\n[ ');
            for (ii = 1 : 1 : min(length(a.nodes),10) )
                fprintf('%d,',a.nodes(ii));
            end
            fprintf(' ]\n');
         end
         % looping via all base values if defined
         if ( length(a.rates_base) > 0 )
            fprintf('Base rates:\n[ ');
            for ( kk = 1 : 1 : min(columns(a.rates_base),10))
                    fprintf('%f,',a.rates_base(kk));
            end
            fprintf(' ]\n');
         end   
          % looping via all stress rates if defined
         if ( rows(a.rates_stress) > 0 )
            tmp_rates = a.getValue('stress');
            fprintf('Stress rates:\n[ ');
            for ( jj = 1 : 1 : min(rows(tmp_rates),5))
                for ( kk = 1 : 1 : min(columns(tmp_rates),10))
                    fprintf('%f,',tmp_rates(jj,kk));
                end
                fprintf(' ]\n');
            end
            fprintf('\n');
         end    
         % looping via first 3 MC scenario values
         for ( ii = 1 : 1 : mc_stack)
            if ( length(a.timestep_mc) >= ii )
                fprintf('MC timestep: %s\n',a.timestep_mc{ii});
                tmp_rates = a.getValue(a.timestep_mc{ii});
                fprintf('Scenariovalue:\n[ ')
                for ( jj = 1 : 1 : min(rows(tmp_rates),5))
                    for ( kk = 1 : 1 : min(columns(tmp_rates),10))
                        fprintf('%f,',tmp_rates(jj,kk));
                    end
                    fprintf(' ]\n');
                end
                fprintf('\n');
            else
                fprintf('MC timestep not defined\n');
            end
         end
      end % disp
      
      function obj = set.type(obj,type)
		 typecell = { 'Discount Curve', 'Spread Curve', 'Dummy Curve', ...
						'Aggregated Curve', 'Prepayment Curve', ...
						'Call Schedule', 'Put Schedule', ...
						'Historical Curve', 'Inflation Expectation Curve', 'Shock Curve'};
         if ~(strcmpi(type,typecell))
            error('Type must be either Discount Curve, Spread Curve, Aggregated Curve, Dummy Curve, Call or Put Schedule, Inflation Expectation Curve, Historical Curve or Prepayment Curve')
         end
         obj.type = type;
      end % Set.type
      
      function obj = set.method_interpolation(obj,method_interpolation)
         method_interpolation = lower(method_interpolation);
         if ~(sum(strcmpi(method_interpolation,{'smith-wilson','spline','linear','mm','exponential','loglinear','monotone-convex','constant','next','previous'}))>0  )
            error('Interpolation method must be either smith-wilson,spline,linear,mm,exponential,monotone-convex,loglinear,constant,next or previous')
         end
         obj.method_interpolation = method_interpolation;
      end % Set.method_interpolation
      
	  function obj = set.method_extrapolation(obj,method_extrapolation)
         method_extrapolation = lower(method_extrapolation);
         if ~(sum(strcmpi(method_extrapolation,{'linear','constant','monotone-convex','smith-wilson'}))>0  )
            error('Extrapolation method must be either linear or constant. Smith-Wilson and Monotone Convex automatically have extrapolation embedded.')
         end
         obj.method_extrapolation = method_extrapolation;
      end % Set.method_extrapolation
	  

      function obj = set.day_count_convention(obj,day_count_convention)
        obj.day_count_convention = day_count_convention;
        % Call superclass method to set basis
        obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
      
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
      
      function obj = set.floor(obj,floor)
         obj.floor = floor;
		 % applying floor rates to rates_base, rates_stress and rates_mc
		 if ( isnumeric(floor))
             obj.rates_base = max(obj.rates_base,floor);
             obj.rates_stress = max(obj.rates_stress,floor);
             obj.rates_mc = max(obj.rates_mc,floor);
         end
      end % set.floor
      
      function obj = set.cap(obj,cap)
         obj.cap = cap;
		 % applying cap rates to rates_base, rates_stress and rates_mc
		 if ( isnumeric(cap))
             obj.rates_base = min(obj.rates_base,cap);
             obj.rates_stress = min(obj.rates_stress,cap);
             obj.rates_mc = min(obj.rates_mc,cap);
         end
      end % set.cap
      
      function obj = set.curve_function(obj,curve_function)
         if ~(strcmpi(curve_function,'sum') || strcmpi(curve_function,'factor') ...
                || strcmpi(curve_function,'product') || strcmpi(curve_function,'divide'))
            error('Bond curve_function must be either sum, factor, product or divide : %s for id >>%s<<.\n',curve_function,obj.id);
         end
         obj.curve_function = tolower(curve_function);
      end % set.curve_function
      
   end
   
   % static methods: 
   methods (Static = true)
   
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
			fprintf('WARNING: Curve.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
			format = 'plain text';
		end	

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Curve(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Curve()\n\
\n\
Class for setting up Curve objects.\n\
\n\
This class contains all attributes and methods related to the following Curve types:\n\
\n\
Discount Curve, Spread Curve, Dummy Curve,\n\
Aggregated Curve, Prepayment Curve,\n\
Call Schedule, Put Schedule,\n\
Historical Curve, Inflation Expectation Curve, Shock Curve.\n\
\n\
In the following, all methods and attributes are explained and code example is given.\n\
\n\
Methods for Curve object @var{obj}:\n\
@itemize @bullet\n\
@item Curve(@var{id}) or Curve(): Constructor of a Curve object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.getRate(@var{scenario},@var{node}): Return scenario curve values at given node (in days).\n\
Interpolation or Extrapolation is performed according to specified methods.\n\
@var{scenario} can be \'base\', \'stress\' or a certain MC timestep like \'250d\'\.\n\
\n\
@item obj.getValue(@var{scenario}): Return all scenario curve values. @var{scenario}\n\
can be \'base\', \'stress\' or a certain MC timestep like \'250d\'\.\n\
\n\
@item obj.apply_rf_shocks(@var{scenario},@var{riskfactor_object}): Set shock curve values for @var{scenario}\n\
Scenario shocks from provided @var{riskfactor_object} are used\n\
\n\
@item obj.isProp(@var{attribute}): Return true, if attribute is a property of Curve class. Return false otherwise.\n\
\n\
@item Curve.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean. True returns \n\
documentation string, false (default) return empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Curves:\n\
@itemize @bullet\n\
@item @var{id}: Curve id. Has to be unique identifier. Default: empty string.\n\
@item @var{name}: Curve name. Default: empty string.\n\
@item @var{description}: Curve description. Default: empty string.\n\
@item @var{type}: Curve type. Can be [Discount Curve (default), Spread Curve, Dummy Curve,\n\
Aggregated Curve, Prepayment Curve,\n\
Call Schedule, Put Schedule,\n\
Historical Curve, Inflation Expectation Curve, Shock Curve]\n\
\n\
@item @var{day_count_convention}: Day count convention of curve. See \'help get_basis\' \n\
for details. Default: \'act/365'\\n\
@item @var{basis}: Basis belonging to day count convention. Value is set automatically.\n\
@item @var{compounding_type}: Compounding type. Can be continuous, discrete or simple. \n\
Default: \'cont\'\n\
@item @var{compounding_freq}: Compounding frequency used for discrete compounding.\n\
Can be [daily, weekly, monthly, quarterly, semi-annual, annual]. Default: \'annual\'\n\
\n\
@item @var{curve_function}: Type Aggregated Curve only: Specifies how \n\
to aggregated curves, which are specified in attribute increments.\n\
Can be [sum, product, divide, factor]. [sum, product, divide] specifies\n\
mathematical operation applied on all curve increments.\n\
[factor] allows only one increment and uses @var{curve_parameter} for multiplication. Default: \'sum\'\n\
@item @var{curve_parameter}: Type Aggregated Curve only: used as multiplication\n\
parameter for factor @var{curve_function}.\n\
@item @var{increments}: Type Aggregated Curve only: List of IDs of all\n\
underlying curves. Use @var{curve_function} to specify how to aggregated curves.\n\
\n\
@item @var{method_extrapolation}: Extrapolation method. Can be \'constant\' (default) or \'linear\'.\n\
@item @var{method_interpolation}: Interpolation method. See \'help interpolate_curve\' for details. Default: \'linear\'.\n\
@item @var{ufr}: Smith-Wilson Ultimate Forward Rate. Used for Smith-Wilson interpolation and extrapolation. Defaults to 0.042.\n\
@item @var{alpha}: Smith-Wilson Reversion parameter. Used for Smith-Wilson interpolation and extrapolation. Defaults to 0.19.\n\
\n\
@item @var{cap}: Cap rate. Cap rate is enforced on all set rates. Set to empty string for no cap rate. Default: empty string.\n\
@item @var{floor}: Floor rate. Floor rate is enforced on all existing and future rates. Set to empty string for no floor rate. Default: empty string.\n\
\n\
@item @var{nodes}: Vector with curve nodes.\n\
@item @var{rates_base}: Vector with curve rates. Has to be of same column size as @var{nodes}.\n\
@item @var{rates_mc}: Matrix with curve rates. Has to be of same column size as @var{nodes}.\n\
Columns: nodes, Lines: scenarios. MC rates for several MC timesteps are stored in layers.\n\
@item @var{rates_stress}: Matrix with curve rates. Has to be of same  as @var{nodes}.\n\
Columns correspond to nodes, lines correspond to scenarios.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. Automatically appended if values for new timesteps are set.\n\
\n\
@item @var{shocktype_mc}: Specify how to apply risk factor shocks in Monte Carlo\n\
scenarios and for method apply_rf_shocks. Can be [absolute, relative, sln_relative].\n\
Automatically set by scripts. Default: absolute\n\
@item @var{shocktype_stress}: Specify Stress risk factor shocks for method apply_rf_shocks.\n\
Can be [absolute, relative]\n\
by stree scenario configuration.\n\
@item @var{sln_level}: Vector with term specific shift level for risk factors modelled with shifted log-normal model.\n\
Automatically set by script during curve setup.\n\
@item @var{american_flag}: Flag for American (true) or European (false) call feature on bonds. Valid only if Curve type is  call or put schedule. Default: false.\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
A discount curve c is specified. A shock curve s provides absolute shocks for stress\n\
and relative shocks for MC scenarios, which are linearly interpolated and\n\
subsequently applied to the discount curve c. In the end, stress and MC\n\
discount rates are interpolated for given nodes with method getRate, while all curve rates are extracted\n\
with getValue.\n\
@example\n\
@group\n\
\n\
c = Curve();\n\
c = c.set('id','Discount_Curve','type','Discount Curve', ...\n\
'nodes',[365,3650,7300],'rates_base',[0.01,0.02,0.04], ...\n\
'method_interpolation','linear','compounding_type','continuous', ...\n\
'day_count_convention','act/365');\n\
s = Curve();\n\
s = s.set('id','IR Shock','type','Shock Curve','nodes',[365,7300], ...\n\
'rates_base',[],'rates_stress',[0.01,0.01;0.02,0.02;-0.01,-0.01;-0.01,0.01], ...\n\
'rates_mc',[1.1,1.1;0.9,0.9;1.2,0.8;0.8,1.2],'timestep_mc','250d', ...\n\
'method_interpolation','linear','shocktype_stress','absolute', ...\n\
'shocktype_mc','relative');\n\
c = c.apply_rf_shock('stress',s);\n\
c = c.apply_rf_shock('250d',s);\n\
c_base = c.getRate('base',1825)\n\
c_rate_stress = c.getRate('stress',1825)\n\
c_rate_250d = c.getRate('250d',1825)\n\
c_rates_250d = c.getValue('250d')\n\
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
				fprintf("\'Matrix\' is a class definition from the file /octarisk/@Matrix/Matrix.m\n");
				fprintf("\n%s\n",retval);
				retval = [];
			end
		end
		
	end % end of static method help
	
   end	% end of static methods
   
end % classdef

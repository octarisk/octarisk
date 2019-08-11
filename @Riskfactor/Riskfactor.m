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
      shocktype_mc = '';    % either relative or absolute
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
         scenario_mc_cols = min(columns(a.scenario_mc),2);

         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\nmodel: %s\n', ... 
            a.name,a.id,a.description,a.type,a.model);
         fprintf('mean: %f\nstandard deviation: %f\nskewness: %f\nkurtosis: %f\n', ... 
            a.mean,a.std,a.skew,a.kurt);
         if (strcmpi(a.model,'SLN'))
            fprintf('sln_level: %f\n',a.sln_level);     
         end
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
            fprintf('Shifttype stress: %d \n',a.shift_type(1:min(rows(a.shift_type),5)));
            fprintf('\n');
         end
         % looping via first 5 MC scenario values
         for ( ii = 1 : 1 : scenario_mc_cols)
			fprintf('MC timestep: %s\n',a.timestep_mc{ii});
			fprintf('Scenariovalues:\n[ ')
                for ( jj = 1 : 1 : scenario_mc_rows)
                    fprintf('%8.6f,\n',a.scenario_mc(jj,ii));
                end
            fprintf(' ]\n');
         end
      end % disp
      
      function obj = set.model(obj,model)
         if ~(strcmpi(model,'GBM') || strcmpi(model,'BM') || strcmpi(model,'BKM') ...
                        || strcmpi(model,'OU') || strcmpi(model,'SRD') ...
                        || strcmpi(model,'SLN') || strcmpi(model,'REL') )
            error('Model must be either GBM, BM, BKM, SLN, REL, OU or SRD')
         end
         obj.model = model;
      end % Set.model
      
      function obj = set.type(obj,type)
         if ~(sum(strcmpi(type,{'RF_IR','RF_SPREAD','RF_COM','RF_EQ','RF_VOLA','RF_ALT','RF_RE','RF_FX','RF_INFL'}))>0  )
            error('Risk factor type must be either RF_IR, RF_SPREAD, RF_COM, RF_RE, RF_EQ, RF_VOLA, RF_ALT, RF_INFL or RF_FX')
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
    
    % static methods:
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
        if ~(isempty(scen_deltavec))
            if ( sum(strcmpi(model,{'GBM','BKM'})) > 0 ) % Log-normal Motion
                ret_vec     =  exp(scen_deltavec .* sensitivity) .* value_base;
            elseif (strcmpi(model,'REL')) % relative shock 
                ret_vec     = (1 + scen_deltavec .* sensitivity) .* value_base;
            else   % Normal Model     
                ret_vec     = (scen_deltavec .* sensitivity) + value_base;
            end
        else
            ret_vec = 0.0;
        end
      end % get_abs_values
      
       

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
            fprintf('WARNING: Riskfactor.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
            format = 'plain text';
        end 

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Riskfactor(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Riskfactor()\n\
\n\
Class for setting up Riskfactor objects.\n\
\n\
The mapping between e.g. curve or index objects and their corresponding risk factors\n\
is automatically done by using regular expressions to match the names.\n\
Riskfactors always have to begin with \'RF_\' followed by the object name.\n\
If certain nodes of curves or surfaces are shocked, the name is followed by an additional node identifier,\n\
e.g. \'RF_IR_EUR_SWAP_1Y\' for shocking an interest rate curve or \'RF_VOLA_IR_EUR_1825_3650\'\n\
for shocking a certain point on the volatility tenor / term surface.\n\
\n\
Riskfactors can be either shocked during stresses, where custom absolute or relative shocks can be defined.\n\
During Monte-Carlo scenario generation risk factor shocks are calculated by applying statistical processes\n\
according to specified stochastic model. The random numbers follow a match of given\n\
mean, standard deviation, skewness and kurtosis according to distributions selected by\n\
the Pearson Type I-VII distribution system.\n\
\n\
This class contains all attributes and methods related to the following Riskfactor types:\n\
\n\
@itemize @bullet\n\
@item RF_IR: Interest rate risk factor.\n\
@item RF_SPREAD: Spread risk factor.\n\
@item RF_COM: Commodity risk factor.\n\
@item RF_RE: Real estate risk factor.\n\
@item RF_EQ: Equity risk factor.\n\
@item RF_VOLA: Volatility risk factor.\n\
@item RF_ALT: Alternative investment risk factor.\n\
@item RF_INFL: Inflation risk factor.\n\
@item RF_FX: Forex risk factor.\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Riskfactor object @var{obj}:\n\
@itemize @bullet\n\
@item Riskfactor(@var{id}) or Riskfactor(): Constructor of a Riskfactor object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.getValue(@var{scenario}, @var{abs_flag}, @var{sensitivity}): Return Riskfactor value\n\
according to scenario type. If optional parameter abs_flag is true returns Riskfactor scenario values.\n\
Therefore static method Riskfactor.get_abs_values will be called.\n\
\n\
@item Riskfactor.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@item Riskfactor.get_abs_values(@var{model}, @var{scen_deltavec}, @var{value_base}, @var{sensitivity}): Calculate absolute\n\
scenario value for given base value, sensitivity, model and shock.  [static method]\n\
@item Riskfactor.get_basis(@var{dcc_string}): Return basis integer value for given day count convention string.\n\
@end itemize\n\
\n\
Attributes of Riskfactor objects:\n\
@itemize @bullet\n\
@item @var{id}: Riskfactor id. Has to be unique identifier. Default: empty string.\n\
@item @var{name}: Riskfactor name. Default: empty string.\n\
@item @var{description}: Riskfactor description. Default: empty string.\n\
@item @var{type}: Riskfactor type. Can be [RF_IR, RF_SPREAD, RF_COM, RF_RE, RF_EQ, RF_VOLA, RF_ALT, RF_INFL or RF_FX]\n\
\n\
@item @var{model}: Stochastic risk factor model. Can be [Geometric Brownian Motion (GBM), Brownian Motioan (BM),\n\
Black-Karasinsky Model (BKM), Shifted LogNormal (SLN), Ornstein-Uhlenbeck (OU), Square-Root Diffusion (SRD)]. Default: empty string.\n\
@item @var{mean}: Annualized targeted marginal mean (drift) of risk factor. Default: 0.0\n\
@item @var{std}: Annualized targeted marginal standard deviation of risk factor. Default: 0.0\n\
@item @var{skew}: Targeted marginal skewness of risk factor. Default: 0.0\n\
@item @var{kurt}: Targeted marginal kurtosis of risk factor. Default: 0.0\n\
@item @var{value_base}:  Base value of risk factor (required for mean reverting stochastic models). Default: 0.0\n\
@item @var{mr_level}: Mean reversion level. Default: 0.0\n\
@item @var{mr_rate}: Mean reversion parameter. Default: 0.0\n\
@item @var{node}:  Risk factor term value in first dimension (in days). For curves equals term in days at x-axis (term). Default: 0.0\n\
@item @var{node2}:  Risk factor term value in second dimension. For interest rate surfaces equals term in days at y-axis (tenor or term).\n\
For index surfaces equals moneyness. Default: 0.0\n\
@item @var{node3}:  Risk factor term value in third dimension. For volatility cubes equals moneyness at z-axis. Default: 0.0\n\
@item @var{sln_level}: Shift parameter (shift level) of shifted log-normal distribution. Default: 0.0\n\
\n\
@item @var{scenario_mc}: Vector with risk factor shock values. \n\
MC rates for several MC timesteps are stored in layers.\n\
@item @var{scenario_stress}: Vector with risk factor shock values. \n\
@item @var{timestep_mc}: String Cell array with MC timesteps. Automatically appended if values for new timesteps are set.\n\
\n\
@item @var{shocktype_mc}: Specify how to apply risk factor shocks in Monte Carlo\n\
scenarios. Can be [absolute, relative, sln_relative].\n\
Automatically set by scripts. Default: absolute\n\
@item @var{shift_type}: Specify a vector specifying stress risk factor shift type .\n\
Can be either 0 (absolute) or 1 (relative) shift.\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
A swap risk factor modelled by a shifted log-normal model at the three year node\n\
is set up and shifted in three stress scenarios (absolute up- and downshift, relative downshift):\n\
@example\n\
@group\n\
\n\
disp('Setting up Swap(3650) risk factor')\n\
r = Riskfactor();\n\
r = r.set('id','RF_EUR-SWAP_3Y','name','RF_EUR-SWAP_3Y', ...\n\
    'scenario_stress',[0.02;-0.01;0.8], ...\n\
    'type','RF_IR','model','SLN','shift_type',[0;0;1], ...\n\
    'mean',0.0,'std',0.117,'skew',0.0,'kurt',3, ...\n\
    'node',1095,'sln_level',0.03)\n\
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
                fprintf("\'Riskfactor\' is a class definition from the file /octarisk/@Riskfactor/Riskfactor.m\n");
                fprintf("\n%s\n",retval);
                retval = [];
            end
        end

      end % end of static method help
    
    end % end of static methods
   
end % classdef

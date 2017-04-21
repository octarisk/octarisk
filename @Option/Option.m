classdef Option < Instrument
   
    properties   % All properties of Class Option with default values
        maturity_date = '';
        compounding_type = 'disc';
        compounding_freq = 1;               
        day_count_convention = 'act/365';
        spread = 0.0;             
        discount_curve = 'EUR_IR';
        underlying = 'DAX30';
        vola_surface = 'vol_index_DAX30';
        vola_sensi = 1;
        strike = 100;
        spot = 100;
        multiplier = 5;
        timesteps_size = 5;      % size of one timestep in path dependent valuations
        willowtree_nodes = 20;   % number of willowtree nodes per timestep
        pricing_function_american = 'BjSten'; % [Willowtree,BjSten] 
        div_yield = 0.0;         % dividend yield (continuous, act/365)
        % special attributes required for barrier option only:
        upordown = 'U';          % Up or Down Barrier Option {'U','D'}
        outorin  = 'out';        % out or in Barrier Option {'out','in'}
        barrierlevel = 0.0;      % barrier level triggers barrier event 
        rebate   = 0.0;          % Rebate: payoff in case of a barrier event
        averaging_type = 'rate';   % Asian averaging type {'rate','strike'}
        averaging_rule = 'geometric'; % underlying distribution of average
                                      % either {'geometric','arithmetic'}
        averaging_monitoring = 'continuous'; % continuous or discrete averaging
		calibration_flag = 1;       % BOOL: if true, no calibration will be done
    end
 
    properties (SetAccess = private)
        basis = 3;
        call_flag = 1;           % set by sub type -> 1: call, 0: put
        cf_dates = [];
        cf_values = [];
        vola_spread = 0.0;
        sub_type = 'OPT_EUR_C';
        option_type = 'European'; % set by sub_type [European, American, Barrier]
        theo_delta = 0.0;
        theo_gamma = 0.0;
        theo_vega = 0.0;
        theo_theta = 0.0;
        theo_rho = 0.0;
        theo_omega = 0.0;
    end

   methods
      function b = Option(tmp_name)
        if nargin < 1
            name  = 'OPTION_TEST';
            id    = 'OPTION_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Option test instrument';
        value_base = 1.00;      
        currency = 'EUR';
        asset_class = 'Derivative';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'option',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type); 
         fprintf('option_type: %s\n',b.option_type); 
         fprintf('call_flag: %d\n',b.call_flag);
         if ( strcmpi(b.option_type,'Barrier') )
            fprintf('Barrier Level: %f\n',b.barrierlevel);
            fprintf('Rebate: %f\n',b.rebate);
            fprintf('UporDown: %s\n',b.upordown);
            fprintf('OutorIn: %s\n',b.outorin);
         end
         if ( strcmpi(b.option_type,'Asian') )
            fprintf('averaging_type: %s\n',b.averaging_type);
            fprintf('averaging_rule: %s\n',b.averaging_rule);
            fprintf('averaging_monitoring: %s\n',b.averaging_monitoring);
         end
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('strike: %f \n',b.strike);
         fprintf('multiplier: %f \n',b.multiplier);         
         fprintf('underlying: %s\n',b.underlying);  
         fprintf('vola_surface: %s\n',b.vola_surface ); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('spread: %f\n',b.spread); 
         fprintf('div_yield (cont, act/365): %f \n',b.div_yield);
         fprintf('vola_sensi: %f\n',b.vola_sensi); 
         fprintf('compounding_type: %s\n',b.compounding_type);  
         fprintf('compounding_freq: %d\n',b.compounding_freq);    
         fprintf('day_count_convention: %s\n',b.day_count_convention);
         if ( (b.theo_delta + b.theo_gamma + b.theo_vega + b.theo_theta ...
										+ b.theo_rho + b.theo_omega) ~= 0 )
            fprintf('theo_delta:\t%8.8f\n',b.theo_delta);  
            fprintf('theo_gamma:\t%8.8f\n',b.theo_gamma);  
            fprintf('theo_vega:\t%8.8f\n',b.theo_vega);  
            fprintf('theo_theta:\t%8.8f\n',b.theo_theta);  
            fprintf('theo_rho:\t%8.8f\n',b.theo_rho);  
            fprintf('theo_omega:\t%8.8f\n',b.theo_omega);  
         end    
      end
      % converting object <-> struct for saving / loading purposes
      % function b = saveobj (a)
          % disp('Converting object to struct');
          % b = struct(a);       
      % end
      function b = loadobj (t,a)
          disp('Converting stuct to object');
          b = Option();
          b.id          = a.id;
          b.name        = a.name; 
          b.description = a.description;  
          b = b.set('timestep_mc',a.timestep_mc);
          b = b.set('value_mc',a.value_mc);
          b.spot            = a.spot;
          b.strike          = a.strike;
          b.maturity_date   = a.maturity_date;
          b.discount_curve  = a.discount_curve;
          b.compounding_type = a.compounding_type;
          b.compounding_freq = a.compounding_freq;               
          b.day_count_convention = a.day_count_convention;
          b.spread          = a.spread;             
          b.underlying      = a.underlying;
          b.vola_surface    = a.vola_surface;
          b.vola_sensi      = a.vola_sensi;
          b.multiplier      = a.multiplier;
          b.basis           = a.basis;
          b.cf_dates        = a.cf_dates;
          b.cf_values       = a.cf_values;
          b.vola_surf       = a.vola_surf;
          b.vola_surf_mc    = a.vola_surf_mc;
          b.vola_surf_stress = a.vola_surf_stress;
          b.vola_spread     = a.vola_spread;
          b.sub_type        = a.sub_type;
      end  
      function obj = set.sub_type(obj,sub_type)
         if ~(any(strcmpi(sub_type,{'OPT_EUR_C','OPT_EUR_P','OPT_AM_C', ...
                  'OPT_AM_P','OPT_BAR_P','OPT_BAR_C','OPT_ASN_P','OPT_ASN_C'})))
            error('Option sub_type must be either OPT_EUR_C, OPT_EUR_P, OPT_AM_C, OPT_AM_P, OPT_BAR_P or OPT_BAR_C','OPT_ASN_P','OPT_ASN_C')
         end
         obj.sub_type = sub_type;
         % set call_flag
         if ( regexpi(sub_type,'_P$'))  % put option
            obj.call_flag = 0;
         else                           % call option
            obj.call_flag = 1;
         end
         % set option type
         if ( regexpi(sub_type,'_EUR_'))        % European (plain vanilla) option
            obj.option_type = 'European';
         elseif ( regexpi(sub_type,'_AM_'))     % American (plain vanilla) option
            obj.option_type = 'American';
         elseif ( regexpi(sub_type,'_BAR_'))    % (European) Barrier option
            obj.option_type = 'Barrier';
         elseif ( regexpi(sub_type,'_ASN_'))    % (European) Asian option
            obj.option_type = 'Asian';
         end
      end % set.sub_type
      
      % restrictions for Asian Options
      function obj = set.averaging_type(obj,averaging_type)
         if ~(any(strcmpi(averaging_type,{'rate'})))
            fprintf('Asian Option averaging type must be rate. Setting to rate.\n')
            averaging_type = 'rate';
         end
         obj.averaging_type = lower(averaging_type);
      end % set.averaging_type
      function obj = set.averaging_rule(obj,averaging_rule)
         if ~(any(strcmpi(averaging_rule,{'geometric','arithmetic'})))
            error('Asian Option averaging rule must be geometric or arithmetic')
         end
         obj.averaging_rule = lower(averaging_rule);
      end % set.averaging_rule
      function obj = set.averaging_monitoring(obj,averaging_monitoring)
         if ~(any(strcmpi(averaging_monitoring,{'continuous'})))
            fprintf('Asian Option averaging monitoring must be continuous. Setting to continuous.\n')
            averaging_monitoring = 'continuous';
         end
         obj.averaging_monitoring = lower(averaging_monitoring);
      end % set.averaging_monitoring
  
      % restrictions for Barrier Options
      function obj = set.upordown(obj,upordown)
         if ~(any(strcmpi(upordown,{'U','D'})))
            error('Option upordown must be either U or D')
         end
         obj.upordown = upper(upordown);
      end % set.upordown
      function obj = set.outorin(obj,outorin)
         if ~(any(strcmpi(outorin,{'out','in'})))
            error('Option outorin must be either out or in')
         end
         obj.outorin = lower(outorin);
      end % set.outorin
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
   end 

  %static methods: 
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
			fprintf('WARNING: Option.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
			format = 'plain text';
		end	

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Option(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Option()\n\
\n\
Class for setting up Option objects.\n\
Possible underlyings are financial instruments or indizes. Therefore the following Option types\n\
are introduced:\n\
\n\
@itemize @bullet\n\
@item OPT_EUR_C: European Call option priced by Black-Scholes model\n\
@item OPT_EUR_P: European Put option priced by Black-Scholes model\n\
@item OPT_AM_C: American Call option priced by Willow tree model or Bjerksund-Stensland approximation\n\
@item OPT_AM_P: European Put option priced by Willow tree model or Bjerksund-Stensland approximation\n\
@item OPT_BAR_C: European Barrier Call option. Can have all combinations of out or in and up or down barrier types. Priced with Merton, Reiner, Rubinstein model.\n\
@item OPT_BAR_P: European Barrier Put option. Same restrictions as Barrier Call options.\n\
@item OPT_ASN_C: European Asian Call option. Average rate only. The following compounding types can be used:\n\
geometric continuous (Kemna-Vorst90 pricing model) or arithmetic continuous (Levy pricing model)\n\
@item OPT_ASN_P: European Asian Put option. Same restrictions as Asian Call options.\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Option object @var{obj}:\n\
@itemize @bullet\n\
@item Option(@var{id}) or Option(): Constructor of a Option object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{valuation_date},@var{scenario}, @var{underlying}, @var{discount_curve}, @var{volatility_surface}, @var{path_static})\n\
Calculate the value of Options based on valuation date, scenario type, discount curve, underlying instrument and volatility surface.\n\
The pricing model is chosen based on Option type and instrument model attributes.\n\
A path to precalculated Willow trees for pricing American options by Willowtree model can be provided.\n\
\n\
@item obj.calc_greeks(@var{valuation_date},@var{scenario}, @var{underlying}, @var{discount_curve}, @var{volatility_surface}, @var{path_static})\n\
Calculate sensitivities (the Greeks) for the given Option instrument.\n\
For plain-vanilla European Options the Greeks are calculated by Black-Scholes pricing.\n\
The Greeks of all other Option types will be calculated by numeric approximation.\n\
\n\
@item obj.calc_vola_spread(@var{valuation_date}, @var{underlying}, @var{discount_curve}, @var{volatility_surface}, @var{path_static})\n\
Calibrate volatility spread in order to match the Option price with the market price. The volatility spread will be used for further pricing.\n\
\n\
@item obj.getValue(@var{scenario}): Return Option value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item Option.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Option objects:\n\
@itemize @bullet\n\
@item @var{id}: Instrument id. Has to be unique identifier. (Default: empty string)\n\
@item @var{name}: Instrument name. (Default: empty string)\n\
@item @var{description}: Instrument description. (Default: empty string)\n\
@item @var{value_base}: Base value of instrument of type real numeric. (Default: 0.0)\n\
@item @var{currency}: Currency of instrument of type string. (Default: 'EUR')\n\
During instrument valuation and aggregation, FX conversion takes place if corresponding FX rate is available.\n\
@item @var{asset_class}: Asset class of instrument. (Default: 'derivative')\n\
@item @var{type}: Type of instrument, specific for class. Set to 'Option'.\n\
@item @var{value_stress}: Line vector with instrument stress scenario values.\n\
@item @var{value_mc}: Line vector with instrument scenario values.\n\
MC values for several @var{timestep_mc} are stored in columns.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. If new timesteps are set, values are automatically appended.\n\
\n\
@item @var{maturity_date}:  Maturity date of Option (date in format DD-MMM-YYYY)\n\
@item @var{day_count_convention}: Day count convention of curve. See \'help get_basis\' \n\
for details (Default: \'act/365\')\n\
@item @var{compounding_type}: Compounding type. Can be continuous, discrete or simple. \n\
(Default: \'cont\')\n\
@item @var{compounding_freq}: Compounding frequency used for discrete compounding.\n\
Can be [daily, weekly, monthly, quarterly, semi-annual, annual]. (Default: \'annual\')\n\
@item @var{spread}: Interest rate spread used in calculating risk free interest rate. Default: 0.0;\n\
@item @var{discount_curve}: ID of discount curve. Default: empty string\n\
@item @var{underlying}: ID of underlying object (instrument or risk factor). Default: empty string\n\
@item @var{vola_surface}: ID of volatility surface. Default: empty string\n\
@item @var{vola_sensi}: Sensitivity scaling factor for volatility. Default: 1\n\
@item @var{strike}: Strike value of Option. Default: 100\n\
@item @var{spot}: Spot value of underlying instrment. Only used, if underlying is risk factor.\n\
@item @var{multiplier}: Multiplier of Option. Resulting Option price is scales by this multiplier. Default: 5\n\
@item @var{div_yield}: Continuous dividend yield of underlying (act/365 day count convention assumed). Default: 0.0\n\
\n\
@item @var{timesteps_size}: American Willow Tree timestep size (in days). Default: 5\n\
@item @var{willowtree_nodes}: American Willow Tree nodes per timestep. Default: 20\n\
@item @var{pricing_function_american}: American pricing model [Willowtree,BjSten]. Default: \'BjSten\'\n\
\n\
@item @var{upordown}: Barrier Up or Down description. Default: \'U\'\n\
@item @var{outorin}: Barrier In or Out description. Default: \'out\'\n\
@item @var{barrierlevel}: Barrier level. Default: 0.0\n\
@item @var{rebate}: Barrier rebate (payoff in case of a barrier event). Default: 0.0\n\
\n\
@item @var{averaging_type} Asian option averaging type [\'rate\',\'strike\']. Defaults to \'rate\'.\n\
@item @var{averaging_rule} = Asian option underlying distribution of average type [\'geometric\',\'arithmetic\']. Defaults to \'geometric\'\n\
@item @var{averaging_monitoring} Asian option average monitoring. Can only be \'continuous\'\n\
\n\
@item @var{theo_delta}: Sensitivity to changes in underlying's price. Calculate by method @var{calc_greeks}.\n\
@item @var{theo_gamma}: Sensitivity to changes in changes of underlying's price. Calculate by method @var{calc_greeks}.\n\
@item @var{theo_vega}: Sensitivity to changes in volatility. Calculate by method @var{calc_greeks}.\n\
@item @var{theo_theta}: Sensitivity to changes in remaining days to maturity. Calculate by method @var{calc_greeks}.\n\
@item @var{theo_rho}: Sensitivity to changes in risk free rate. Calculate by method @var{calc_greeks}.\n\
@item @var{theo_omega}: Specified as @var{theo_delta} scaled by underlying value over option base value. Calculate by method @var{calc_greeks}.\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
An American equity Option with 10 years to maturity, an underlying index, a volatility surface and a discount curve are set up\n\
and the Option value (123.043), volatility spread and the Greeks are calculated by the Willowtree model and retrieved:\n\
@example\n\
@group\n\
\n\
disp('Pricing American Option Object (Willowtree)')\n\
c = Curve();\n\
c = c.set('id','IR_EUR','nodes',[730,3650,4380], ...\n\
'rates_base',[0.0001001034,0.0045624391,0.0062559362], ...\n\
'method_interpolation','linear');\n\
v = Surface();\n\
v = v.set('axis_x',3650,'axis_x_name','TERM','axis_y',1.1, ...\n\
'axis_y_name','MONEYNESS');\n\
v = v.set('values_base',0.210360082233);\n\
v = v.set('type','INDEX');\n\
i = Index();\n\
i = i.set('value_base',286.867623322,'currency','USD');\n\
o = Option();\n\
o = o.set('maturity_date','29-Mar-2026','currency','USD', ...\n\
'timesteps_size',5,'willowtree_nodes',30);\n\
o = o.set('strike',368.7362,'multiplier',1,'sub_Type','OPT_AM_P');\n\
o = o.set('pricing_function_american','Willowtree');\n\
o = o.calc_value('31-Mar-2016','base',i,c,v);\n\
o = o.calc_greeks('31-Mar-2016','base',i,c,v);\n\
value_base = o.getValue('base')\n\
theo_omega = o.get('theo_omega')\n\
disp('Calibrating volatility spread over yield:')\n\
o = o.set('value_base',100);\n\
o = o.calc_vola_spread('31-Mar-2016',i,c,v);\n\
o.getValue('base')\n\
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
				fprintf("\'Option\' is a class definition from the file /octarisk/@Option/Option.m\n");
				fprintf("\n%s\n",retval);
				retval = [];
			end
		end

		
	end % end of static method help
	
   end	% end of static methods
end 

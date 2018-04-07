classdef Swaption < Instrument
   
    properties   % All properties of Class Swaption with default values
        maturity_date = '';
        effective_date = '';
        compounding_type = 'disc';
        compounding_freq = 1;               
        day_count_convention = 'act/365';
        spread = 0.0;             
        discount_curve = 'RF_IF_EUR';
        underlying = 'RF_IF_EUR';
        vola_surface = 'RF_VOLA_IR_EUR';
        vola_sensi = 1;
        strike = 0.025;
        spot = 0.025;
        multiplier = 100;           % only used if valued without underlyings
        tenor = 10;                 % Tenor of underlying swap in years
        no_payments = 1;
        und_fixed_leg = '';         % String: underlying fixed leg
        und_floating_leg = '';      % String: underlying floating leg
        use_underlyings = false;    % BOOL: use underlying legs for valuation
        calibration_flag = 1;       % BOOL: if true, no calibration will be done
    end
   
    properties (SetAccess = private)
        basis = 3;
        cf_dates = [];
        cf_values = [];
        vola_spread = 0.0;
        sub_type = 'SWAPT_PAY';
        model = 'black';
        und_fixed_value = 0.0;
        und_float_value = 0.0;
        call_flag = false;
        implied_volatility = 0.0;
        theo_delta = 0.0;
        theo_gamma = 0.0;
        theo_vega = 0.0;
        theo_theta = 0.0;
        theo_rho = 0.0;
    end

   methods
      function b = Swaption(tmp_name)
        if nargin < 1
            name  = 'SWAPTION_TEST';
            id    = 'SWAPTION_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Swaption test instrument';
        value_base = 1.00;      
        currency = 'EUR';
        asset_class = 'Derivative';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'swaption',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);                   
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('strike: %f \n',b.strike);
         fprintf('multiplier: %f \n',b.multiplier);          
         fprintf('vola_surface: %s\n',b.vola_surface ); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('spread: %f\n',b.spread); 
         fprintf('tenor (years): %f\n',b.tenor); 
         fprintf('no_payments (per year): %f\n',b.no_payments); 
         fprintf('vola_sensi: %f\n',b.vola_sensi); 
         fprintf('compounding_type: %s\n',b.compounding_type);  
         fprintf('compounding_freq: %d\n',b.compounding_freq);    
         fprintf('day_count_convention: %s\n',b.day_count_convention); 
         fprintf('model: %s\n',b.model); 
         fprintf('und_fixed_leg: %s\n',b.und_fixed_leg); 
         fprintf('und_floating_leg: %s\n',b.und_floating_leg); 
         fprintf('use_underlyings: %s\n',any2str(b.use_underlyings)); 
         if ~(b.und_float_value == 0.0)
            fprintf('und_float_value: %f \n',b.und_float_value);
         end
         if ~(b.und_fixed_value == 0.0)
            fprintf('und_fixed_value: %f \n',b.und_fixed_value);
         end
         if ~(b.implied_volatility == 0.0)
            fprintf('implied_volatility: %f \n',b.implied_volatility);
         end
         if ~(b.vola_spread == 0.0)
            fprintf('vola_spread: %f \n',b.vola_spread);
         end
         if ( (b.theo_delta + b.theo_gamma + b.theo_vega + b.theo_theta ...
                + b.theo_rho ) ~= 0 )
            fprintf('theo_delta:\t%8.8f\n',b.theo_delta);  
            fprintf('theo_gamma:\t%8.8f\n',b.theo_gamma);  
            fprintf('theo_vega:\t%8.8f\n',b.theo_vega);  
            fprintf('theo_theta:\t%8.8f\n',b.theo_theta);  
            fprintf('theo_rho:\t%8.8f\n',b.theo_rho);   
         end 
      end
      % converting object <-> struct for saving / loading purposes
      % function b = saveobj (a)
          % disp('Converting object to struct');
          % b = struct(a);       
      % end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'SWAPT_REC') || strcmpi(sub_type,'SWAPT_PAY') )
            error('Swaption sub_type must be either SWAPT_REC, SWAPT_PAY')
         end
         if (strcmpi(sub_type,'SWAPT_PAY') )
            obj.call_flag = true; % Receive fixed, pay float -> put option on fixed
         else
            obj.call_flag = false;
         end
         obj.sub_type = sub_type;
      end % set.sub_type
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
      
      function obj = set.model(obj,model)
        model = lower(model);
        if ~(strcmpi(model,'normal') || strcmpi(model,'black') || strcmpi(model,'black76') )
            error('Swaption model must be either normal or black')
        end
        obj.model = model;
      end % set.model
      
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
            fprintf('WARNING: Swaption.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
            format = 'plain text';
        end 

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Swaption(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Swaption()\n\
\n\
Class for setting up Swaption objects.\n\
Possible underlyings are fixed and floating swap legs. Therefore the following Swaption types\n\
are introduced:\n\
\n\
@itemize @bullet\n\
@item SWAPT_REC: European Receiver Swaption priced by Black-Scholes or Bachelier normal model.\n\
@item SWAPT_PAY: European Payer Swaption priced by Black-Scholes or Bachelier normal model.\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Swaption object @var{obj}:\n\
@itemize @bullet\n\
@item Swaption(@var{id}) or Swaption(): Constructor of a Swaption object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{valuation_date},@var{scenario}, @var{discount_curve}, @var{volatility_surface}, @var{underlying_fixed_leg}, @var{underlying_floating_leg})\n\
Calculate the value of Swaptions based on valuation date, scenario type, discount curve, underlying instruments and volatility surface.\n\
The pricing model is chosen based on Swaption type and instrument model attributes.\n\
\n\
@item obj.calc_greeks(@var{valuation_date},@var{scenario}, @var{discount_curve}, @var{volatility_surface}, @var{underlying_fixed_leg}, @var{underlying_floating_leg})\n\
Calculate numerical sensitivities (the Greeks) for the given Swaption instrument.\n\
\n\
@item obj.calc_vola_spread(@var{valuation_date},@var{scenario}, @var{discount_curve}, @var{volatility_surface}, @var{underlying_fixed_leg}, @var{underlying_floating_leg})\n\
Calibrate volatility spread in order to match the Swaption price with the market price. The volatility spread will be used for further pricing.\n\
\n\
@item obj.getValue(@var{scenario}): Return Swaption value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item Swaption.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Swaption objects:\n\
@itemize @bullet\n\
@item @var{id}: Instrument id. Has to be unique identifier. (Default: empty string)\n\
@item @var{name}: Instrument name. (Default: empty string)\n\
@item @var{description}: Instrument description. (Default: empty string)\n\
@item @var{value_base}: Base value of instrument of type real numeric. (Default: 0.0)\n\
@item @var{currency}: Currency of instrument of type string. (Default: 'EUR')\n\
During instrument valuation and aggregation, FX conversion takes place if corresponding FX rate is available.\n\
@item @var{asset_class}: Asset class of instrument. (Default: 'derivative')\n\
@item @var{type}: Type of instrument, specific for class. Set to 'Swaption'.\n\
@item @var{value_stress}: Line vector with instrument stress scenario values.\n\
@item @var{value_mc}: Line vector with instrument scenario values.\n\
MC values for several @var{timestep_mc} are stored in columns.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. If new timesteps are set, values are automatically appended.\n\
\n\
@item @var{maturity_date}:  Maturity date of Swaption (date in format DD-MMM-YYYY)\n\
@item @var{effective_date}:  Effective date of Swaption (date in format DD-MMM-YYYY)\n\
@item @var{day_count_convention}: Day count convention of curve. See \'help get_basis\'\n\
for details (Default: \'act/365\')\n\
@item @var{compounding_type}: Compounding type. Can be continuous, discrete or simple. \n\
(Default: \'cont\')\n\
@item @var{compounding_freq}: Compounding frequency used for discrete compounding.\n\
Can be [daily, weekly, monthly, quarterly, semi-annual, annual]. (Default: \'annual\')\n\
@item @var{spread}: Interest rate spread used in calculating risk free interest rate. Default: 0.0;\n\
@item @var{discount_curve}: ID of discount curve. Default: empty string\n\
@item @var{underlying}: ID of underlying curve object for extracting forward rates. Default: empty string\n\
@item @var{vola_surface}: ID of volatility surface. Default: empty string\n\
@item @var{vola_sensi}: Sensitivity scaling factor for volatility. Default: 1\n\
@item @var{strike}: Strike rate of Swaption. Default: 100\n\
@item @var{spot}: Spot rate of underlying reference curve. Only used, if underlying is risk factor.\n\
@item @var{multiplier}: Multiplier of Swaption. Resulting Swaption price is scales by this multiplier. Default: 100\n\
@item @var{model}: Pricing model for Swaptions. Can be [\'black\',\'normal\']. Default: \'black\'\n\
\n\
@item @var{tenor}: Tenor of swaption contract.\n\
@item @var{no_payments}: Number of payments of swaption contract.\n\
@item @var{use_underlyings}: Boolean flag: if true, underlying swap values of\n\
fixed and floating legs are used for calculation of swaption spot price spot price (Default: \'false\')\n\
@item @var{und_fixed_leg}: ID of underlying fixed swap leg. Object has to be a Bond(). Default: empty string\n\
@item @var{und_floating_leg}: ID of underlying floating swap leg. Object has to be a Bond(). Default: empty string\n\
\n\
@item @var{theo_delta}: Sensitivity to changes in underlying's price. Calculate by method @var{calc_greeks}.\n\
@item @var{theo_gamma}: Sensitivity to changes in changes of underlying's price. Calculate by method @var{calc_greeks}.\n\
@item @var{theo_vega}: Sensitivity to changes in volatility. Calculate by method @var{calc_greeks}.\n\
@item @var{theo_theta}: Sensitivity to changes in remaining days to maturity. Calculate by method @var{calc_greeks}.\n\
@item @var{theo_rho}: Sensitivity to changes in risk free rate. Calculate by method @var{calc_greeks}.\n\
@item @var{theo_omega}: Specified as @var{theo_delta} scaled by underlying value over Swaption base value. Calculate by method @var{calc_greeks}.\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
A normal payer swaption with maturity in 20 years with underlying swaps starting\n\
in 20 years for 10 years, a volatility surface and a discount curve are priced.\n\
The resulting Swaption value (642.6867193851) is retrieved:\n\
@example\n\
@group\n\
\n\
disp('Pricing Payer Swaption with underlyings (Normal Model)')\n\
r = Curve();\n\
r = r.set('id','EUR-SWAP-NOFLOOR','nodes', ...\n\
[7300,7665,8030,8395,8760,9125,9490,9855,10220,10585,10900], ...\n\
'rates_base',[0.02,0.01,0.0075,0.005,0.0025,-0.001, ...\n\
-0.002,-0.003,-0.005,-0.0075,-0.01], ...\n\
'method_interpolation','linear');\n\
fix = Bond();\n\
fix = fix.set('Name','SWAP_FIXED','coupon_rate',0.045, ...\n\
'value_base',100,'coupon_generation_method','forward', ...\n\
'sub_type','SWAP_FIXED');\n\
fix = fix.set('maturity_date','24-Mar-2046','notional',100, ...\n\
'compounding_type','simple','issue_date','26-Mar-2036', ...\n\
'term',365,'notional_at_end',0);\n\
fix = fix.rollout('base','31-Mar-2016');\n\
fix = fix.rollout('stress','31-Mar-2016');\n\
fix = fix.calc_value('31-Mar-2016','base',r); \n\
fix = fix.calc_value('31-Mar-2016','stress',r);\n\
float = Bond();\n\
float = float.set('Name','SWAP_FLOAT','coupon_rate',0.00,'value_base',100, ...\n\
'coupon_generation_method','forward','last_reset_rate',-0.000, ...\n\
'sub_type','SWAP_FLOATING','spread',0.00);\n\
float = float.set('maturity_date','24-Mar-2046','notional',100, ...\n\
'compounding_type','simple','issue_date','26-Mar-2036', ...\n\
'term',365,'notional_at_end',0);\n\
float = float.rollout('base',r,'31-Mar-2016');\n\
float = float.rollout('stress',r,'31-Mar-2016');\n\
float = float.calc_value('30-Sep-2016','base',r);\n\
float = float.calc_value('30-Sep-2016','stress',r);\n\
v = Surface();\n\
v = v.set('axis_x',30,'axis_x_name','TENOR', ...\n\
'axis_y',45,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');\n\
v = v.set('values_base',0.376563388);\n\
v = v.set('type','IRVol');\n\
s = Swaption();\n\
s = s.set('maturity_date','26-Mar-2036','effective_date','31-Mar-2016');\n\
s = s.set('strike',0.045,'multiplier',1,'sub_type', 'SWAPT_PAY', ...\n\
'model','normal','tenor',10);\n\
s = s.set('und_fixed_leg','SWAP_FIXED','und_floating_leg','SWAP_FLOAT', ...\n\
'use_underlyings',true);\n\
s = s.calc_value('31-Mar-2016','base',r,v,fix,float);\n\
s.getValue('base')\n\
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
                fprintf("\'Swaption\' is a class definition from the file /octarisk/@Swaption/Swaption.m\n");
                fprintf("\n%s\n",retval);
                retval = [];
            end
        end

        
    end % end of static method help
    
   end  % end of static method
   
end 
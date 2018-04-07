classdef Forward < Instrument
    % Forward class incorporates Futures
    properties   % All properties of Class Forward with default values
        issue_date = '01-Jan-1900';
        maturity_date = '';
        compounding_type = 'disc';
        compounding_freq = 'annual';  
        strike_price = 0.0;               
        day_count_convention = 'act/365';         
        underlying_price_base = 0.0;
        underlying_id = '';
        underlying_sensitivity = 1;
        discount_curve = 'IR_EUR';
        foreign_curve = 'IR_USD';
        multiplier = 1;
        dividend_yield = 0.0; 
        convenience_yield = 0.0;
        storage_cost = 0.0;
        spread = 0.0;          
        cf_dates = [];
        cf_values = [];
        component_weight = 0.0;
        net_basis = 0.0;
        calc_price_from_netbasis = false;
    end
    properties (SetAccess = private)
        sub_type = 'EQFWD';
        basis = 3;
        theo_delta = 0.0;
        theo_gamma = 0.0;
        theo_vega = 0.0;
        theo_theta = 0.0;
        theo_rho = 0.0;
        theo_domestic_rho = 0.0;
        theo_foreign_rho = 0.0;
        theo_price = 0.0;
    end
    
   methods
      function b = Forward(tmp_name)
         if nargin < 1
            name  = 'FWD_TEST';
            id    = 'FWD_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Forward test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'derivative';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'forward',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);                     
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('compounding_type: %s\n',b.compounding_type);  
         if (ischar(b.compounding_freq))
            fprintf('compounding_freq: %s\n',b.compounding_freq); 
         else
            fprintf('compounding_freq: %d\n',b.compounding_freq);  
         end   
         fprintf('day_count_convention: %s\n',b.day_count_convention); 
         fprintf('strike_price: %f\n',b.strike_price);  
         fprintf('underlying_id: %s\n',b.underlying_id); 
         %fprintf('underlying_price_base: %f\n',b.underlying_price_base); 
         fprintf('underlying_sensitivity: %d\n',b.underlying_sensitivity); 
         fprintf('dividend_yield: %f\n',b.dividend_yield); 
         fprintf('convenience_yield: %f\n',b.convenience_yield);
         fprintf('storage_cost: %f\n',b.storage_cost);         
         fprintf('multiplier: %f\n',b.multiplier); 
         fprintf('component_weight: %f\n',b.component_weight);
         fprintf('net_basis: %f\n',b.net_basis);
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('calc_price_from_netbasis: %d\n',b.calc_price_from_netbasis);
         fprintf('theo_price:\t%8.8f\n',b.theo_price);  
         if ( (b.theo_delta + b.theo_gamma + b.theo_vega + b.theo_theta ...
                + b.theo_rho + b.theo_domestic_rho + b.theo_foreign_rho) ~= 0 )
            fprintf('theo_delta:\t%8.8f\n',b.theo_delta);  
            fprintf('theo_gamma:\t%8.8f\n',b.theo_gamma);  
            fprintf('theo_vega:\t%8.8f\n',b.theo_vega);  
            fprintf('theo_theta:\t%8.8f\n',b.theo_theta);  
            fprintf('theo_rho:\t%8.8f\n',b.theo_rho);  
            fprintf('theo_domestic_rho:\t%8.8f\n',b.theo_domestic_rho);  
            fprintf('theo_foreign_rho:\t%8.8f\n',b.theo_foreign_rho);  
         end 
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'Equity') || strcmpi(sub_type,'Bond') ...
                || strcmpi(sub_type,'EQFWD') || strcmpi(sub_type,'FX') ...
                || strcmpi(sub_type,'BondFuture')  || strcmpi(sub_type,'EquityFuture') ...
                || strcmpi(sub_type,'BONDFWD'))
            error('Forward sub_type must be either EquityFuture, EQFWD, BONDFWD, FX or BondFuture')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
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
            fprintf('WARNING: Forward.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
            format = 'plain text';
        end 

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Forward(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Forward()\n\
\n\
Class for setting up Forward and Future objects.\n\
Possible underlyings are bonds, equities and FX rates. Therefore the following Forward types\n\
are introduced:\n\
\n\
@itemize @bullet\n\
@item Bond: Forward on bond underlyings. Underlying instrument will be priced incl. accrued interest.\n\
@item Equity: Forward on equity underlyings like stocks or equity funds. Only Continuous dividends are possible.\n\
@item FX: Forward on currencies. Price is depending on underlying price and foreign and domestic discount factors.\n\
@item EquityFuture: Standardized contract on equity underlyings. A net basis can be specified.\n\
@item BondFuture: Standardized contract on Bond underlyings. A net basis can be specified.\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Forward object @var{obj}:\n\
@itemize @bullet\n\
@item Forward(@var{id}) or Forward(): Constructor of a Forward object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{valuation_date},@var{scenario}, @var{discount_curve_object}, @var{underlying_object}, @var{und_curve_object})\n\
Calculate the value of Forwards based on valuation date, scenario type, discount curve and underlying instruments.\n\
Underlying discount curve @var{und_curve_object} is used for Forwards on Bond or FX rates only.\n\
\n\
@item obj.getValue(@var{scenario}): Return Forward value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item obj.calc_sensitivities(@var{valuation_date}, @var{discount_curve_object}, @var{underlying_object}, @var{und_curve_object})\n\
Calculate sensitivities (the Greeks) of all Forward and Future by numeric approximation.\n\
\n\
@item Forward.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Forward objects:\n\
@itemize @bullet\n\
@item @var{id}: Instrument id. Has to be unique identifier. (Default: empty string)\n\
@item @var{name}: Instrument name. (Default: empty string)\n\
@item @var{description}: Instrument description. (Default: empty string)\n\
@item @var{value_base}: Base value of instrument of type real numeric. (Default: 0.0)\n\
@item @var{currency}: Currency of instrument of type string. (Default: 'EUR')\n\
During instrument valuation and aggregation, FX conversion takes place if corresponding FX rate is available.\n\
@item @var{asset_class}: Asset class of instrument. (Default: 'derivative')\n\
@item @var{type}: Type of instrument, specific for class. Set to 'Forward'.\n\
@item @var{value_stress}: Line vector with instrument stress scenario values.\n\
@item @var{value_mc}: Line vector with instrument scenario values.\n\
MC values for several @var{timestep_mc} are stored in columns.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. If new timesteps are set, values are automatically appended.\n\
\n\
@item @var{issue_date}:  Issue date of Forward (date in format DD-MMM-YYYY)\n\
@item @var{maturity_date}:  Maturity date of Forward (date in format DD-MMM-YYYY)\n\
@item @var{day_count_convention}: Day count convention of curve. See \'help get_basis\' \n\
for details (Default: \'act/365\')\n\
@item @var{compounding_type}: Compounding type. Can be continuous, discrete or simple. \n\
(Default: \'cont\')\n\
@item @var{compounding_freq}: Compounding frequency used for discrete compounding.\n\
Can be [daily, weekly, monthly, quarterly, semi-annual, annual]. (Default: \'annual\')\n\
@item @var{strike_price}: Strike price (Default: 0.0)\n\
@item @var{underlying_id}:ID of underlying object. (Default: '')\n\
@item @var{underlying_price_base}:  Underlying base price. Used only\n\
if underlying object is a risk factor. Risk factor shocks are applied to underlying base price. (Default: 0.0)\n\
@item @var{underlying_sensitivity}:  Underlying sensitivity used only,\n\
if underlying object is a risk factor. Risk factor shocks are scaled by this sensitivity (Default: 1.0)\n\
@item @var{discount_curve}: Discount curve (Default: \'IR_EUR\')\n\
@item @var{foreign_curve}:  Foreign curve, used for Bond and FX Forwards only (Default: \'IR_USD\')\n\
@item @var{multiplier}: Multiplier. Used to scale price and value of one constract. (Default: 1)\n\
@item @var{dividend_yield}:  Dividend yield is part of total cost of carry. Used for Equity Forwards only. (Default: 0.0)\n\
@item @var{convenience_yield}:  Convenience yield is part of total cost of carry. Used for Equity Forwards only. (Default: 0.0)\n\
@item @var{storage_cost}:  Storage cost (yield) is part of total cost of carry. Used for Equity Forwards only. (Default: 0.0)\n\
@item @var{spread}:  Unsued: Spread of Forward (Default: 0.0) \n\
@item @var{cf_dates}: Unused: Cash flow dates (Default: [])\n\
@item @var{cf_values}: Unused: Cash flow values (Default: [])\n\
@item @var{component_weight}:  Used for Bond futures only. Scale future future price.\n\
@item @var{net_basis}:  Net basis of futures. Used only, if @var{calc_price_from_netbasis} is set to true.\n\
@item @var{calc_price_from_netbasis}: Boolean Flag. True: use @var{net_basis} to calculate future price. (Default: false).\n\
\n\
@item @var{theo_delta}: Sensitivity to changes in underlying's price. Calculated by method @var{calc_sensitivities}.\n\
@item @var{theo_gamma}: Sensitivity to changes in changes of underlying's price. Calculated by method @var{calc_sensitivities}.\n\
@item @var{theo_vega}: Sensitivity to changes in volatility. Calculated by method @var{calc_sensitivities}.\n\
@item @var{theo_theta}: Sensitivity to changes in remaining days to maturity. Calculated by method @var{calc_sensitivities}.\n\
@item @var{theo_rho}: Sensitivity to changes in risk free rate. Calculated by method @var{calc_sensitivities}.\n\
@item @var{theo_domestic_rho}: Sensitivity to changes in domestic interest rate. Calculated by method @var{calc_sensitivities}.\n\
@item @var{theo_foreign_rho}: Sensitivity to changes in foreign interest rate. Calculated by method @var{calc_sensitivities}.\n\
@item @var{theo_price}: Forward price. Calculated by method @var{calc_value}.\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
An equity forward with 10 years to maturity, an underlying index and a discount curve are set up\n\
and the forward value (-27.2118960639903) is calculated and retrieved:\n\
@example\n\
@group\n\
\n\
c = Curve();\n\
c = c.set('id','IR_EUR','nodes',[365,3650,7300]);\n\
c = c.set('rates_base',[0.0001002070,0.0045624391,0.009346842]);\n\
c = c.set('method_interpolation','linear');\n\
i = Index();\n\
i = i.set('value_base',326.900);\n\
f = Forward();\n\
f = f.set('name','EQ_Forward_Index_Test','maturity_date','26-Mar-2036');\n\
f = f.set('strike_price',426.900);\n\
f = f.set('compounding_freq','annual');\n\
f = f.calc_value('31-Mar-2016','base',c,i);\n\
f.getValue('base')\n\
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
                fprintf("\'Forward\' is a class definition from the file /octarisk/@Forward/Forward.m\n");
                fprintf("\n%s\n",retval);
                retval = [];
            end
        end

        
    end % end of static method help
    
   end  % end of static methods
   
end 

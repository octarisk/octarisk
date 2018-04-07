classdef Synthetic < Instrument
   
    properties   % All properties of Class Debt with default values
        instruments  = {'TEST_INSTRUMENT'};
        weights    = [1]; 
        compounding_type = 'cont';
        compounding_freq = 'annual';                
        day_count_convention = 'act/365';         
        instr_vol_surfaces  = {'INSTRUMENT_VOL'};
        discount_curve = '';
        correlation_matrix = '';
        basket_vola_type = 'Levy'; % [Levy, VCV, Beisser] approximation for basket volatility calculation
    end
   
    properties (SetAccess = private)
        sub_type  = 'SYNTH';
        cf_dates  = [];
        cf_values = [];
        basis = 3;
        is_basket = false;
    end
   
   methods
      function b = Synthetic(tmp_name)
        if nargin < 1
            name  = 'SYNTH_TEST';
            id    = 'SYNTH_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Synthetic test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'Synthetic';   
        valuation_date = today; 
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'synthetic',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);              
         % looping via all instruments / weights
         for ( ii = 1 : 1 : length(b.weights))
            fprintf('Instrument: %s | weight: %f\n',b.instruments{ii},b.weights(ii));            
         end
         fprintf('compounding_type: %s\n',b.compounding_type); 
         fprintf('compounding_freq: %s\n',b.compounding_freq); 
         fprintf('day_count_convention: %s\n',b.day_count_convention); 
         fprintf('basis: %s\n',any2str(b.basis)); 
         fprintf('correlation_matrix: %s\n',b.correlation_matrix); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('Instrument Volatility Surface(s): %s \n',any2str(b.instr_vol_surfaces));    
         fprintf('basket_vola_type: %s\n',b.basket_vola_type);  
      end
      
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,{'SYNTH'}) || strcmpi(sub_type,{'Basket'}) )
            error('Synthetic Instrument sub_type must be SYNTH or Basket')
         end
         obj.sub_type = sub_type;
         if ( strcmpi(sub_type,{'Basket'}) )
            obj.is_basket = true;
         end
      end % set.sub_type
      
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
      
      function obj = set.basket_vola_type(obj,basket_vola_type)
         if ~(strcmpi(basket_vola_type,{'Levy','VCV','Beisser'}) )
            error('Synthetic Instrument basket_vola_type must be Levy, VCV or Beisser')
         end
         obj.basket_vola_type = basket_vola_type;
      end % set.basket_vola_type
     
   end % end of methods
   
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
            fprintf('WARNING: Synthetic.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
            format = 'plain text';
        end 

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Synthetic(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Synthetic()\n\
\n\
Class for setting up Synthetic objects.\n\
A Synthetic instrument is a linear combination of underlying instruments. The following Synthetic types\n\
are introduced:\n\
\n\
@itemize @bullet\n\
@item SYNTH: Synthetic instrument with underlyings. The Synthetic price\n\
is based on the linear combination of underlying instrument's prices.\n\
@item Basket: The same as type SYNTH, but additional attributes for specifying\n\
underlying volatility surface and volatility types are introduced to enable basket option valuation.\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Synthetic object @var{obj}:\n\
@itemize @bullet\n\
@item Synthetic(@var{id}) or Synthetic(): Constructor of a Synthetic object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{valuation_date},@var{scenario}, @var{instrument_struct}, @var{index_struct})\n\
Calculate the value of Synthetic instruments based on valuation date, scenario type, underlying instruments and FX rates.\n\
The provided structures have to contain the referenced underlying instrument objects and FX rates.\n\
\n\
@item obj.getValue(@var{scenario}): Return Synthetic value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item Synthetic.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Synthetic objects:\n\
@itemize @bullet\n\
@item @var{id}: Instrument id. Has to be unique identifier. (Default: empty string)\n\
@item @var{name}: Instrument name. (Default: empty string)\n\
@item @var{description}: Instrument description. (Default: empty string)\n\
@item @var{value_base}: Base value of instrument of type real numeric. (Default: 0.0)\n\
@item @var{currency}: Currency of instrument of type string. (Default: 'EUR')\n\
During instrument valuation and aggregation, FX conversion takes place if corresponding FX rate is available.\n\
@item @var{asset_class}: Asset class of instrument. (Default: 'derivative')\n\
@item @var{type}: Type of instrument, specific for class. Set to 'Synthetic'.\n\
@item @var{value_stress}: Line vector with instrument stress scenario values.\n\
@item @var{value_mc}: Line vector with instrument scenario values.\n\
MC values for several @var{timestep_mc} are stored in columns.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. If new timesteps are set, values are automatically appended.\n\
\n\
@item @var{day_count_convention}: Day count convention of curve. See \'help get_basis\' \n\
for details (Default: \'act/365\')\n\
@item @var{compounding_type}: Compounding type. Can be continuous, discrete or simple. \n\
(Default: \'cont\')\n\
@item @var{compounding_freq}: Compounding frequency used for discrete compounding.\n\
Can be [daily, weekly, monthly, quarterly, semi-annual, annual]. (Default: \'annual\')\n\
@item @var{instruments}: Underlying instrument identifiers (Cellstring )\n\
@item @var{weights}: Underlying instruments weights (Numeric vector)\n\
@item @var{discount_curve}: Discount curve (Default: empty string)\n\
@item @var{instr_vol_surfaces}: Required for Options on Baskets only:\n\
Underlying instruments volatility surface identifiers (Cellstring )\n\
@item @var{correlation_matrix}: Required for Options on Baskets only:\n\
Correlation matrix object of Basket underlyings (Default: empty string)\n\
@item @var{basket_vola_type}: Required for Options on Baskets only:\n\
Approximation method for basket volatility calculation  [Levy, VCV, Beisser] (Default: \'Levy\')\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
A fund modelled as synthetic instrument with two underlying indizes (MSCI World and Euro Stoxx 50) is set up\n\
and the synthetic value (1909.090909) is calculated and retrieved:\n\
@example\n\
@group\n\
\n\
fprintf('Pricing Synthetic Instrument');\n\
s = Synthetic();\n\
instrument_cell = cell;\n\
instrument_cell(1) = 'EURO_STOXX_50';\n\
instrument_cell(2) = 'MSCIWORLD';\n\
s = s.set('id','TestSynthetic','instruments',instrument_cell);\n\
s = s.set('weights',[1,1],'currency','EUR');\n\
i1 = Index();\n\
i1 = i1.set('id','EURO_STOXX_50','value_base',1000,'scenario_stress',2000);\n\
i2 = Index();\n\
i2 = i2.set('id','MSCIWORLD','value_base',1000);\n\
i2 = i2.set('scenario_stress',2000,'currency','USD');\n\
fx = Index();\n\
fx = fx.set('id','FX_EURUSD','value_base',1.1,'scenario_stress',1.2);\n\
instrument_struct = struct();\n\
instrument_struct(1).id = i1.id;\n\
instrument_struct(1).object = i1;\n\
instrument_struct(2).id = i2.id;\n\
instrument_struct(2).object = i2;\n\
index_struct = struct();\n\
index_struct(1).id = fx.id;\n\
index_struct(1).object = fx;\n\
valuation_date = datenum('31-Mar-2016');\n\
s = s.calc_value(valuation_date,'base',instrument_struct,index_struct);\n\
s.getValue('base')\n\
@end group\n\
@end example\n\
@end deftypefn";

        % format help text
        [retval status] = __makeinfo__(textstring,format);
        % status
        if (status == 0)
            % depending on retflag, return textstring
            if (retflag == 0)
                % print formatted textstring
                fprintf("\'Synthetic\' is a class definition from the file /octarisk/@Synthetic/Synthetic.m\n");
                fprintf("\n%s\n",retval);
                retval = [];
            end
        end

        
    end % end of static method help
    
   end  % end of static methods
end 
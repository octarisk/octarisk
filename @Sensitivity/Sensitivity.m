classdef Sensitivity < Instrument
   
    properties
        % attributes for linear combinations of risk factor shocks
        riskfactors  = {''};
        sensitivities    = []; 
        idio_vola = 0.0;
        model = 'GBM';
        % attributes for sensi instruments (linear and quadratic combination of underlyings)
        underlyings = {''}; % cell array of underlying indizes, curves, surfaces, instruments, risk factors
        x_coord = 0.0;      % x coordinate of underlying (curves, surfaces, cubes only)
        y_coord = 0.0;      % y coordinate of underlying (surfaces, cubes only)
        z_coord = 0.0;      % z coordinate of underlying (cubes only)
        shock_type = {''};  % cell array of shock types for each underlying [value, relative, absolute]
        sensi_prefactor = [];   % vector with prefactors (a in a*x^b)
        sensi_exponent = []; % vector with exponents (b in a*x^b)
        sensi_cross = [];   % vector with cross terms [0 = single; 1,2,3, ... link cross terms]
        use_value_base = false; % boolean flag: use value_base for base valuation. Scenario shocks are added to base value
        use_taylor_exp = false; % boolean flag: if true, treat polynomial value 
            % as taylor expansion: f(x) = a*x^1 + 1/2*b*x^2 + ..., otherwise just f(x) = a*x^1 + b*x^2
        sii_equity_type = 0;
        payout_yield = 0;	% used for fund modelling (forecast dividend yield)
        div_month = 12; % used for fund modelling (dividend payment month)
    end
   
    properties (SetAccess = private)
        sub_type  = 'STK';
        cf_dates  = [];
        cf_values = [];
    end
   
   methods
      function b = Sensitivity(tmp_name)
        if nargin < 1
            name  = 'SENSI_TEST';
            id    = 'SENSI_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Sensitivity test instrument';
        value_base  = 100.00;      
        currency    = 'EUR';
        asset_class = 'Equity';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'sensitivity',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('model: %s\n',b.model);   
         fprintf('sub_type: %s\n',b.sub_type);              
         if (strcmpi(b.sub_type,'SENSI'))
            
            fprintf('underlyings: \n\t');
            for ( ii = 1 : 1 : length(b.underlyings))
                fprintf('%s | ',b.underlyings{ii});            
            end
            fprintf('\nshock_type: \n\t');
            for ( ii = 1 : 1 : length(b.shock_type))
                fprintf('%s | ',b.shock_type{ii});            
            end
            fprintf('\nsensi_prefactor: \n\t');
            for ( ii = 1 : 1 : length(b.sensi_prefactor))
                fprintf('%f | ',b.sensi_prefactor(ii));            
            end
            fprintf('\nsensi_exponent: \n\t');
            for ( ii = 1 : 1 : length(b.sensi_exponent))
                fprintf('%f | ',b.sensi_exponent(ii));            
            end
            fprintf('\nsensi_cross: \n\t');
            for ( ii = 1 : 1 : length(b.sensi_cross))
                fprintf('%d | ',b.sensi_cross(ii));            
            end
            fprintf('\nx_coord: \n\t');
            for ( ii = 1 : 1 : length(b.x_coord))
                fprintf('%d | ',b.x_coord(ii));            
            end
            fprintf('\ny_coord: \n\t');
            for ( ii = 1 : 1 : length(b.y_coord))
                fprintf('%d | ',b.y_coord(ii));            
            end
            fprintf('\nz_coord: \n\t');
            for ( ii = 1 : 1 : length(b.z_coord))
                fprintf('%d | ',b.z_coord(ii));            
            end
            fprintf('\n');
            fprintf('use_value_base: %s\n',any2str(b.use_value_base)); 
            fprintf('use_taylor_exp: %s\n',any2str(b.use_taylor_exp)); 
         else
             % looping via all riskfactors / sensitivities
             for ( ii = 1 : 1 : length(b.sensitivities))
                fprintf('Riskfactor: %s | Sensitivity: %f\n',b.riskfactors{ii},b.sensitivities(ii));            
             end
             fprintf('idio_vola: %f\n',b.idio_vola); 
             fprintf('payout yield: %s\n',any2str(b.payout_yield)); 
             fprintf('dividend payment month: %s\n',any2str(b.div_month)); 
         end
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,{'EQU','RET','COM','STK','ALT','SENSI'}) )
            error('Sensitivity Instruments sub_type must be EQU,RET,COM,STK,ALT or SENSI')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
      
      function obj = set.model(obj,model)
         if ~(strcmpi(model,'GBM') || strcmpi(model,'BM') || strcmpi(model,'REL') )
            error('Model must be either REL, GBM or BM')
         end
         obj.model = model;
      end % Set.model
      
      function obj = set.sii_equity_type(obj,sii_equity_type)
         if ~(sii_equity_type == 1 || sii_equity_type == 2 || sii_equity_type == 0)
            error('Index SII equity type must be either 0, 1 or 2.')
         end
         obj.sii_equity_type = sii_equity_type;
      end % Set.sii_equity_type
      
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
            fprintf('WARNING: Sensitivity.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
            format = 'plain text';
        end 

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Sensitivity(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Sensitivity()\n\
\n\
Class for setting up Sensitivity objects. This class contains two different\n\
instrument setups. The first idea of this class is to model an instrument\n\
whose shocks are derived from underlying risk factor shocks or idiosyncratic risk (for MC only).\n\
The shocks from these risk factors are then applied to the instrument base value under the\n\
assumption of a Geometric Brownian Motion or Brownian Motion.\n\
Basically, all real assets like Equity or Commodity can be modelled with this class.\n\
The combined shock is a linear combination of all underlying risk factor shocks:\n\
@example\n\
@group\n\
V_shock = V_base * exp(Sum_i=1...n [dRF_i * w_i]) (Model: GBM)\n\
V_shock = V_base + (Sum_i=1...n [dRF_i * w_i]) (Model: BM)\n\
@end group\n\
@end example\n\
with the new shock Value V_shock, base V_base, risk factor shock dRF_i and risk factor weight w_i.\n\
\n\
The second idea is to use this class to specify a polynomial function or taylor series\n\
of underlying instruments, risk factors, curves, surfaces or indizes and derive\n\
the sensitivity value with the following formulas. If Taylor expansion shall be used:\n\
@example\n\
@group\n\
V_shock = V_base + a1/b1 * x1^b1 + a2/b2 * x2^b2 + .. + an/bn * xn^bn * am/bm * xm^bm\n\
@end group\n\
@end example\n\
The base value is used only if appropriate flag is set.\n\
Otherwise, a polynomial function can be set up:\n\
@example\n\
@group\n\
V_shock = V_base + a1 * x1^b1 + a2 * x2^b2 + .. + an * xn^bn * am * xm^bm\n\
@end group\n\
@end example\n\
with the new shock Value V_shock, base V_base, and prefactors a, exponents b and\n\
a multiplicative combination of cross terms (term with equal cross terms are\n\
multiplied with each other, term with cross terms equal zero are added to the total value)\n\
All combined cross terms and all single terms are finally summed up.\n\
\n\
This class contains all attributes and methods related to the following Sensitivity types:\n\
\n\
@itemize @bullet\n\
@item EQU: Equity sensitivity type\n\
@item RET: Real Estate sensitivity type\n\
@item COM: Commodity sensitivity type\n\
@item STK: Stock sensitivity type\n\
@item ALT: Alternative investments sensitivity type\n\
@item SENSI: Taylor series or polynomial equation of underlying objects\n\
@end itemize\n\
\n\
which stands for Equity, Real Estate, Commodity, Stock and Alternative Investments.\n\
All sensitivity types assume a geometric brownian motion or brownian motion as underlying stochastic process.\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Sensitivity object @var{obj}:\n\
@itemize @bullet\n\
@item Sensitivity(@var{id}) or Sensitivity(): Constructor of a Sensitivity object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{valuation_date}, @var{scenario}, @var{riskfactor_struct}, @var{instrument_struct}, @var{index_struct}, @var{curve_struct}, @var{surface_struct}, [@var{scen_number}]):\n\
Method for calculation of sensitivity value. Only structures with used objects need to be set.\n\
\n\
@item obj.valuate(@var{valuation_date}, @var{scenario}, @var{instrument_struct}, @var{surface_struct}, @var{matrix_struct},\n\
@var{curve_struct}, @var{index_struct}, @var{riskfactor_struct}, [ @var{para_struct} ])\n\
Generic instrument valuation method. All objects required for valuation of the instrument\n\
are taken from provided structures (e.g. curves, riskfactors, underlying indizes).\n\
Method inherited from Superclass @var{Instrument}.\n\
\n\
@item obj.getValue(@var{scenario}): Return Sensitivity value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item Sensitivity.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Sensitivity objects:\n\
@itemize @bullet\n\
@item @var{id}: Instrument id. Has to be unique identifier. Default: empty string.\n\
@item @var{name}: Instrument name. Default: empty string.\n\
@item @var{description}: Instrument description. Default: empty string.\n\
@item @var{value_base}: Base value of instrument of type real numeric. Default: 0.0.\n\
@item @var{currency}: Currency of instrument of type string. Default: 'EUR'\n\
During instrument valuation and aggregation, FX conversion takes place if corresponding FX rate is available.\n\
@item @var{asset_class}: Asset class of instrument. Default: empty string\n\
@item @var{type}: Type of instrument, specific for class. Set to 'sensitivity'.\n\
@item @var{value_stress}: Line vector with instrument stress scenario values.\n\
@item @var{value_mc}: Line vector with instrument scenario values.\n\
MC values for several @var{timestep_mc} are stored in columns.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. If new timesteps are set, values are automatically appended.\n\
\n\
@item @var{riskfactors}: Cell with IDs of all underlying risk factors. Default: empy cell.\n\
@item @var{sensitivities}: Vector with weights of riskfactors of same length and order as riskfactors cell. Default: empty vector\n\
@item @var{idio_vola}: Idiosyncratic volatility of sensitivity instrument. Used only if one riskfactor is set to \'IDIO\'.\n\
Applies a shock given by a normal distributed random variable with standard deviation taken from the value of attribute @var{idio_vola}\n\
and a mean of zero.\n\
@item @var{model}: Model specifies the stochastic process. Can be a Geometric Brownian\n\
Notion (GBM) or Brownian Notion (BM). (Default: 'GBM')\n\
\n\
@item @var{underlyings}: cell array of underlying indizes, curves, surfaces, instruments, risk factors\n\
@item @var{x_coord}: vector with x coordinates of underlying (curves, surfaces, cubes only)\n\
@item @var{y_coord}: vector y coordinate of underlying (surfaces, cubes only)\n\
@item @var{z_coord}: vector z coordinate of underlying (cubes only)\n\
@item @var{shock_type}: cell array of shock types for each underlying [value, relative, absolute]\n\
@item @var{sensi_prefactor}: vector with prefactors (a in a*x^b)\n\
@item @var{sensi_exponent}: vector with exponents (b in a*x^b)\n\
@item @var{div_yield}: forecast dividend yield\n\
@item @var{div_month}: dividend paymend month\n\
@item @var{sensi_cross}: vector with cross terms [0 = single; 1,2,3, ... link cross terms]\n\
@item @var{use_value_base}: boolean flag: use value_base for base valuation. Scenario shocks are added to base value (default: false)\n\
@item @var{use_taylor_exp}: boolean flag: if true, treat polynomial value as Taylor expansion(default: false)\n\
\n\
@item @var{cf_dates}: Unused: Cash flow dates (Default: [])\n\
@item @var{cf_values}: Unused: Cash flow values (Default: [])\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
An All Country World Index (ACWI) fund with base value of 100 USD shall be modelled\n\
with both instrument setups (Linear combination of risk factor shocks\n\
and a polynomial (linear) function with two single terms.\n\
Underlying risk factors are the MSCI Emerging Market and MSCI World Index.\n\
The sensitivities to both risk factors\n\
are equal to the weights of the subindices in the ACWI index. Both risk factors\n\
are shocked during a stress scenario and the total shock values for the fund are calculated:\n\
\n\
@example\n\
@group\n\
 fprintf('\tdoc_instrument:\tPricing Sensitivity Instrument (Polynomial Function)');\n\
 r1 = Riskfactor();\n\
  r1 = r1.set('id','MSCI_WORLD','scenario_stress',[20;-10], ...\n\
        'model','GBM','shift_type',[1;1]);\n\
  r2 = Riskfactor();\n\
  r2 = r2.set('id','MSCI_EM','scenario_stress',[10;-20], ...\n\
        'model','GBM','shift_type',[1;1] );\n\
  riskfactor_struct = struct();\n\
  riskfactor_struct(1).id = r1.id;\n\
  riskfactor_struct(1).object = r1;\n\
  riskfactor_struct(2).id = r2.id;\n\
  riskfactor_struct(2).object = r2;\n\
  s = Sensitivity();\n\
  s = s.set('id','MSCI_ACWI_ETF','sub_type','SENSI', 'currency', 'USD' , ...\n\
        'asset_class','Equity',  'value_base', 100, ...\n\
        'underlyings',cellstr(['MSCI_WORLD';'MSCI_EM']), ...\n\
        'x_coord',[0,0], ...\n\
        'y_coord',[0,0.0], ...\n\
        'z_coord',[0,0], ...\n\
        'shock_type', cellstr(['absolute';'absolute']), ...\n\
        'sensi_prefactor', [0.8,0.2], 'sensi_exponent', [1,1], ...\n\
        'sensi_cross', [0,0], 'use_value_base',true,'use_taylor_exp',false);\n\
  instrument_struct = struct();\n\
  instrument_struct(1).id = s.id;\n\
  instrument_struct(1).object = s;\n\
s = s.calc_value('31-Dec-2016', 'base',riskfactor_struct,instrument_struct,[],[],[],2);\n\
s.getValue('base')\n\
s = s.calc_value('31-Dec-2016', 'stress',riskfactor_struct,instrument_struct,[],[],[],2);\n\
s.getValue('stress')\n\
\n\
 fprintf('\tdoc_instrument:\tPricing Sensitivity Instrument (Riskfactor linear combination)');\n\
 r1 = Riskfactor();\n\
  r1 = r1.set('id','MSCI_WORLD','scenario_stress',[20;-10], ...\n\
        'model','BM','shift_type',[1;1]);\n\
  r2 = Riskfactor();\n\
  r2 = r2.set('id','MSCI_EM','scenario_stress',[10;-20], ...\n\
        'model','BM','shift_type',[1;1] );\n\
  riskfactor_struct = struct();\n\
  riskfactor_struct(1).id = r1.id;\n\
  riskfactor_struct(1).object = r1;\n\
  riskfactor_struct(2).id = r2.id;\n\
  riskfactor_struct(2).object = r2;\n\
  s = Sensitivity();\n\
  s = s.set('id','MSCI_ACWI_ETF','sub_type','EQU', 'currency', 'USD', ...\n\
        'asset_class','Equity', 'model', 'BM', ...\n\
        'riskfactors',cellstr(['MSCI_WORLD';'MSCI_EM']), ...\n\
        'sensitivities',[0.8,0.2],'value_base',100.00);\n\
  instrument_struct = struct();\n\
  instrument_struct(1).id = s.id;\n\
  instrument_struct(1).object = s;\n\
  s = s.valuate('31-Dec-2016', 'stress', ...\n\
        instrument_struct, [], [], ...\n\
        [], [], riskfactor_struct);\n\
  s.getValue('stress')\n\
@end group\n\
@end example\n\
\n\
Stress results are [118;88].\n\
\n\
@end deftypefn";

        % format help text
        [retval status] = __makeinfo__(textstring,format);
        % status
        if (status == 0)
            % depending on retflag, return textstring
            if (retflag == 0)
                % print formatted textstring
                fprintf("\'Sensitivity\' is a class definition from the file /octarisk/@Sensitivity/Sensitivity.m\n");
                fprintf("\n%s\n",retval);
                retval = [];
            end
        end

        
    end % end of static method help
    
   end  % end of static methods

end 

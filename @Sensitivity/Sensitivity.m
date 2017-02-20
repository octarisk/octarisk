classdef Sensitivity < Instrument
   
    properties
        riskfactors  = {''};
        sensitivities    = []; 
        idio_vola = 0.0;
		model = 'GBM';
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
         fprintf('sub_type: %s\n',b.sub_type);              
         % looping via all riskfactors / sensitivities
         for ( ii = 1 : 1 : length(b.sensitivities))
            fprintf('Riskfactor: %s | Sensitivity: %f\n',b.riskfactors{ii},b.sensitivities(ii));            
         end
         fprintf('idio_vola: %f\n',b.idio_vola); 
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,{'EQU','RET','COM','STK','ALT'}) )
            error('Sensitivity Instruments sub_type must be EQU,RET,COM,STK,ALT')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
	  
	  function obj = set.model(obj,model)
         if ~(strcmpi(model,'GBM') || strcmpi(model,'BM') )
            error('Model must be either GBM or BM')
         end
         obj.model = model;
      end % Set.model
	  
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
Class for setting up Sensitivity objects. The idea of this class is to model an instrument\n\
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
This class contains all attributes and methods related to the following Sensitivity types:\n\
\n\
@itemize @bullet\n\
@item EQU: Equity sensitivity type\n\
@item RET: Real Estate sensitivity type\n\
@item COM: Commodity sensitivity type\n\
@item STK: Stock sensitivity type\n\
@item ALT: Alternative investments sensitivity type\n\
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
@item @var{cf_dates}: Unused: Cash flow dates (Default: [])\n\
@item @var{cf_values}: Unused: Cash flow values (Default: [])\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
An All Country World Index (ACWI) fund with base value of 100 USD shall be modelled.\n\
Underlying risk factors are the MSCI Emerging Market and MSCI World Index.\n\
The sensitivities to both risk factors\n\
are equal to the weights of the subindices in the ACWI index. Both risk factors\n\
are shocked during a stress scenario and the total shock values for the fund are calculated:\n\
\n\
@example\n\
@group\n\
r1 = Riskfactor();\n\
r1 = r1.set('id','MSCI_WORLD','scenario_stress',[0.2;-0.1], ...\n\
	'model','GBM','shift_type',[1;1]);\n\
r2 = Riskfactor();\n\
r2 = r2.set('id','MSCI_EM','scenario_stress',[0.1;-0.2], ...\n\
	'model','GBM','shift_type',[1;1] );\n\
riskfactor_struct = struct();\n\
riskfactor_struct(1).id = r1.id;\n\
riskfactor_struct(1).object = r1;\n\
riskfactor_struct(2).id = r2.id;\n\
riskfactor_struct(2).object = r2;\n\
s = Sensitivity();\n\
s = s.set('id','MSCI_ACWI_ETF','sub_type','EQU', 'currency', 'USD' ...\n\
	'asset_class','Equity', 'model', 'GBM', ...\n\
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
Stress results are [119.7217363121810;88.6920436717158].\n\
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
	
   end	% end of static methods

end 
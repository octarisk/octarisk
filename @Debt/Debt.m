classdef Debt < Instrument
   
    properties   % All properties of Class Debt with default values
        discount_curve  = '';  
        duration    = 0.0;       
        convexity   = 0.0; 
		term        = 0.0;		
    end
   
    properties (SetAccess = private)
        sub_type    = 'DBT';
        cf_dates    = [];
        cf_values   = [];
    end
   
   methods
      function b = Debt(tmp_name)
        if nargin < 1
            name  = 'DEBT_TEST';
            id    = 'DEBT_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Debt test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'debt';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'debt',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);              
         fprintf('duration: %f\n',b.duration); 
         fprintf('convexity: %f\n',b.convexity); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'DBT') )
            error('Debt sub_type must be DBT.')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
   end  % end of methods
   
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
			fprintf('WARNING: Debt.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
			format = 'plain text';
		end	

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Debt(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Debt()\n\
\n\
Class for setting up Debt objects. The idea of this class is to model baskets (funds) of bond instruments.\n\
The shocked value is derived from a sensitivity approach based on Modified duration and\n\
convexity. These sensitivities describe the total basket properties in terms of interest rate sensitivity.\n\
The following formula is applied to calculate the instrument shock:\n\
@example\n\
@group\n\
   dP\n\
  --- = -D dY + 0.5 C dY^2\n\
   P\n\
@end group\n\
@end example\n\
\n\
If you want to model all underlying bonds directly, use Bond class for underlyings and Synthetic class for the basket (fund).\n\
\n\
This class contains all attributes and methods related to the following Debt types:\n\
\n\
@itemize @bullet\n\
@item DBT: Standard debt type\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Debt object @var{obj}:\n\
@itemize @bullet\n\
@item Debt(@var{id}) or Debt(): Constructor of a Debt object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{discount_curve},@var{scenario}): Calculate instrument shocked value based on interest rate sensitivity.\n\
Modified Duration and Convexity are used to predict change in value based on absolute shock discount curve at given term.\n\
\n\
@item obj.getValue(@var{scenario}): Return Debt value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item Debt.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Debt objects:\n\
@itemize @bullet\n\
@item @var{id}: Instrument id. Has to be unique identifier. Default: empty string.\n\
@item @var{name}: Instrument name. Default: empty string.\n\
@item @var{description}: Instrument description. Default: empty string.\n\
@item @var{value_base}: Base value of instrument of type real numeric. Default: 0.0.\n\
@item @var{currency}: Currency of instrument of type string. Default: 'EUR'\n\
During instrument valuation and aggregation, FX conversion takes place if corresponding FX rate is available.\n\
@item @var{asset_class}: Asset class of instrument. Default: 'debt'\n\
@item @var{type}: Type of instrument, specific for class. Set to 'debt'.\n\
@item @var{value_stress}: Line vector with instrument stress scenario values.\n\
@item @var{value_mc}: Line vector with instrument scenario values.\n\
MC values for several @var{timestep_mc} are stored in columns.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. If new timesteps are set, values are automatically appended.\n\
\n\
@item @var{discount_curve}: Discount curve is used as sensitivity curve to derive absolute shocks at term given by duration.\n\
@item @var{term}: Term of debt instrument (in years). Equals average maturity of all underlying cash flows.\n\
@item @var{duration}: Modified duration of debt instrument.\n\
@item @var{convexity}: Convexity of debt instrument.\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
Stress values of a debt instrument with average maturity of underlyings of 8.35 years and given duration and convexity\n\
are calculated based on 100bp parallel down- and upshift scenarios of a given discount curve.\n\
Stress results are [108.5300000000000;91.1969278203125]\n\
@example\n\
@group\n\
\n\
c = Curve();\n\
c = c.set('id','IR_EUR','nodes',[730,3650,4380],'rates_base',[0.01,0.02,0.025],'method_interpolation','linear');\n\
c = c.set('rates_stress',[0.00,0.01,0.015;0.02,0.031,0.035],'method_interpolation','linear');\n\
d = Debt();\n\
d = d.set('duration',8.35,'convexity',18,'term',8.35);\n\
d = d.calc_value(c,'stress');\n\
d.getValue('base')\n\
d.getValue('stress')\n\
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
				fprintf("\'Debt\' is a class definition from the file /octarisk/@Debt/Debt.m\n");
				fprintf("\n%s\n",retval);
				retval = [];
			end
		end

		
	end % end of static method help
	
   end	% end of static methods
   
end 

%# -*- texinfo -*-
%# @deftypefn  {Function File} {} Stochastic ()
%# @deftypefnx {Function File} {} Stochastic (@var{id})
%# Stochastic Class, inherited attributes from Instrument Superclass 
%# A Stochastic instrument uses a risk factor with random variables 
%# (either uniform, normal or t-distributed) to draw values from a 1D Surface.
%# The surface has exactly one value per given quantile [0,1].
%# This instrument type can be used to pre-calculate values in another risk 
%# system for a given risk factor distribution.
%#
%# @seealso{Bond, Forward, Option, Swaption, Debt, Sensitivity, Synthetic}
%# @end deftypefn

classdef Stochastic < Instrument
   
    properties   % All properties of Class Bond with default values
        quantile_base = 0.5;
        stochastic_riskfactor   = 'RF_STOCHASTIC';    % used for stochastic cf
        stochastic_curve        = 'STOCHASTIC_CURVE';  % used for stochastic cf
        stochastic_rf_type      = 'normal';       % either normal or univariate
        t_degree_freedom        = 120;  % degrees of freedom for t distribution
    end
   
    properties (SetAccess = private)
        sub_type = 'stochastic';
    end
   
   methods
      function b = Stochastic(tmp_name)
        if nargin < 1
            name  = 'STOCHASTIC_TEST';
            id    = 'STOCHASTIC_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Stochastic test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'Stochastic';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'stochastic',currency,value_base, ...
                        asset_class);      
      end 
      % method display properties
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);
         fprintf('stochastic_riskfactor: %s\n',b.stochastic_riskfactor);
         fprintf('stochastic_curve: %s\n',b.stochastic_curve);
         fprintf('stochastic_rf_type: %s\n',b.stochastic_rf_type);
         if ( strcmpi(b.stochastic_rf_type,'t'))
                fprintf('t_degree_freedom: %d\n',b.t_degree_freedom); 
         end
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'stochastic') )
            error('Stochastic sub_type must be stochastic: %s',sub_type)
         end
         obj.sub_type = sub_type;
      end % set.sub_type
    
   end % end methods
   
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
            fprintf('WARNING: Stochastic.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
            format = 'plain text';
        end 

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Stochastic(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Stochastic()\n\
\n\
Class for setting up Stochastic objects.\n\
A Stochastic instrument uses a risk factor with random variables \n\
(either uniform, normal or t-distributed) to draw values from a 1D Surface.\n\
The surface has exactly one value per given quantile [0,1].\n\
This instrument type can be used to pre-calculate values in another risk \n\
system for a given risk factor distribution.\n\
\n\
@itemize @bullet\n\
@item STOCHASTIC: Stochastic instrument type is the default value.\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Stochastic object @var{obj}:\n\
@itemize @bullet\n\
@item Stochastic(@var{id}) or Stochastic(): Constructor of a Stochastic object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{valuation_date},@var{scenario}, @var{riskfactor}, @var{surface})\n\
Calculate the value of Stochastic instruments. Quantile values from a 1-dimensional surface are drawn\n\
based on (transformed) risk factor shocks.\n\
\n\
@item obj.getValue(@var{scenario}): Return Stochastic value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item Stochastic.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Stochastic objects:\n\
@itemize @bullet\n\
@item @var{id}: Instrument id. Has to be unique identifier. (Default: empty string)\n\
@item @var{name}: Instrument name. (Default: empty string)\n\
@item @var{description}: Instrument description. (Default: empty string)\n\
@item @var{value_base}: Base value of instrument of type real numeric. (Default: 0.0)\n\
@item @var{currency}: Currency of instrument of type string. (Default: 'EUR')\n\
During instrument valuation and aggregation, FX conversion takes place if corresponding FX rate is available.\n\
@item @var{asset_class}: Asset class of instrument. (Default: 'stochastic')\n\
@item @var{type}: Type of instrument, specific for class. Set to 'Stochastic'.\n\
@item @var{value_stress}: Line vector with instrument stress scenario values.\n\
@item @var{value_mc}: Line vector with instrument scenario values.\n\
MC values for several @var{timestep_mc} are stored in columns.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. If new timesteps are set, values are automatically appended.\n\
\n\
@item @var{quantile_base}: Base quantile of stochastic curve. (Default: 0.5)\n\
@item @var{stochastic_riskfactor}: underlying risk factor objects. Shocks are transformed according to @var{stochastic_rf_type}\n\
@item @var{stochastic_curve}: underlying 1-dim surface with values per quantile.\n\
@item @var{stochastic_rf_type}: Risk factor transformation. Type can be [\'normal\',\'t\',\'uniform\'] (Default: 'normal')\n\
@item @var{t_degree_freedom}:  degrees of freedom for t distribution (Default: 120)\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
A stochastic value object is generated. Quantile values are given by\n\
a 1-dim volatility surface.\n\
The resulting Stress value ([95;100;105]) is retrieved:\n\
@example\n\
@group\n\
\n\
disp('Pricing Pricing Stochastic Value Object')\n\
r = Riskfactor();\n\
r = r.set('value_base',0.5,'scenario_stress',[0.3;0.50;0.7],'model','BM');\n\
value_x = 0;\n\
value_quantile = [0.1,0.5,0.9];\n\
value_matrix = [90;100;110];\n\
v = Surface();\n\
v = v.set('axis_x',value_x,'axis_x_name','DATE', ...\n\
'axis_y',value_quantile,'axis_y_name','QUANTILE');\n\
v = v.set('values_base',value_matrix);\n\
v = v.set('type','STOCHASTIC');\n\
s = Stochastic();\n\
s = s.set('sub_type','STOCHASTIC','stochastic_rf_type','uniform', ...\n\
't_degree_freedom',10);\n\
s = s.calc_value('31-Mar-2016','base',r,v);\n\
s = s.calc_value('31-Mar-2016','stress',r,v);\n\
stress_value = s.getValue('stress')\n\
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
                fprintf("\'Stochastic\' is a class definition from the file /octarisk/@Stochastic/Stochastic.m\n");
                fprintf("\n%s\n",retval);
                retval = [];
            end
        end

        
    end % end of static method help
    
   end  % end of static method
   
end 

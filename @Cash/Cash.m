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

classdef Cash < Instrument
	% file: @Cash/Cash.m
   
    properties   % All properties of Class Debt with default values
        discount_curve = ''; % unused
    end
   
    properties (SetAccess = private)
        sub_type    = 'cash';
        cf_dates    = [];
        cf_values   = [];
    end
   
   methods
      function b = Cash(tmp_name)
        if nargin < 1
            name  = 'CASH_TEST';
            id    = 'CASH_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Cash test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'cash';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'cash',currency,value_base, ...
                        asset_class);  
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);               
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'cash') )
            error('Cash sub_type must be cash.')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
	  
   end   % end of methods
  
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
			fprintf('WARNING: Cash.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
			format = 'plain text';
		end	

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Cash(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Cash()\n\
\n\
Class for setting up Cash objects.\n\
\n\
This class contains all attributes and methods related to the following Cash types:\n\
\n\
@itemize @bullet\n\
@item Cash: Specify riskless cash instruments\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Cash object @var{obj}:\n\
@itemize @bullet\n\
@item Cash(@var{id}) or Cash(): Constructor of a Cash object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{scenario},@var{scen_number}): Extends base value to vector of row size @var{scen_number}\n\
and stores vector for given @var{scenario}. Cash instruments are per definition risk free.\n\
\n\
@item obj.getValue(@var{scenario}): Return Cash value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item Cash.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Cash objects:\n\
@itemize @bullet\n\
@item @var{id}: Instrument id. Has to be unique identifier. Default: empty string.\n\
@item @var{name}: Instrument name. Default: empty string.\n\
@item @var{description}: Instrument description. Default: empty string.\n\
@item @var{value_base}: Base value of instrument of type real numeric. Default: 0.0.\n\
@item @var{currency}: Currency of instrument of type string. Default: 'EUR'\n\
During instrument valuation and aggregation, FX conversion takes place if corresponding FX rate is available.\n\
@item @var{asset_class}: Asset class of instrument. Default: 'unknown'\n\
@item @var{type}: Type of instrument, specific for class. Set to 'cash'.\n\
@item @var{value_stress}: Line vector with instrument stress scenario values.\n\
@item @var{value_mc}: Line vector with instrument scenario values.\n\
MC values for several @var{timestep_mc} are stored in columns.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. If new timesteps are set, values are automatically appended.\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
A THB Cash instrument is being generated and during value calculation the stress and MC scenario values\n\
with 20 resp. 1000 scenarios are derived from the base value:\n\
@example\n\
@group\n\
\n\
c = Cash();\n\
c = c.set('id','THB_CASH','name','Cash Position THB');\n\
c = c.set('asset_class','cash','currency','THB');\n\
c = c.set('value_base',346234.1256);\n\
c = c.calc_value('stress',20);\n\
c = c.calc_value('250d',1000);\n\
value_stress = c.getValue('stress');\n\
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
				fprintf("\'Cash\' is a class definition from the file /octarisk/@Cash/Cash.m\n");
				fprintf("\n%s\n",retval);
				retval = [];
			end
		end

		
	end % end of static method help
	
   end	% end of static methods
   

   
end 
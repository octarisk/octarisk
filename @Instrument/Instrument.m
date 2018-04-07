%# -*- texinfo -*-
%# @deftypefn  {Function File} {} Instrument ()
%# @deftypefnx {Function File} {} Instrument (@var{a})
%# Instrument Superclass 
%#
%# @*
%# Inherited superclass properties:
%# @itemize @bullet
%# @item name: Name of object
%# @item id: Id of object
%# @item description: Description of object
%# @item value_spot: Actual spot value of object
%# @item currency
%# @item asset_class 
%# @item type: Type of Instrument class (Bond,Forward,...) 
%# @item value_stress: Vector with values under stress scenarios
%# @item value_mc: Matrix with values under MC scenarios (values per timestep per column)
%# @item timestep_mc: MC timestep per column (cell string)
%# @end itemize
%# @*
%#
%# @seealso{Bond, Forward, Option, Swaption, Debt, Sensitivity, Synthetic}
%# @end deftypefn

classdef Instrument
    % file: @Instrument/Instrument.m
    properties
      name = '';
      id = '';
      description = '';
      value_base = 0;      
      currency = 'EUR';
      asset_class = 'Unknown';   
      type = 'Unknown';      
    end
   
    properties (SetAccess = protected )
      value_stress = [];
      value_mc = [];
      timestep_mc = {};
    end
   
   % Class methods
   methods
      function a = Instrument(tmp_name,tmp_id,tmp_description,tmp_type,tmp_currency,value_base,tmp_asset_class)
         % Instrument Constructor function
         if nargin > 0
            a.name = tmp_name;
            a.id = tmp_id;
            a.description = tmp_description;
            a.type = lower(tmp_type);
            a.value_base = value_base;
            a.currency = tmp_currency;
            a.asset_class = tmp_asset_class;
         end
      end % Instrument
      
      function disp(a)
         % Display a Instrument object
         % Get length of Value vector:
         value_stress_rows = min(rows(a.value_stress),5);
         value_mc_rows = min(rows(a.value_mc),5);
         value_mc_cols = min(length(a.timestep_mc),2);
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\nasset_class: %s\ncurrency: %s\nvalue_base: %8.6f %s\n', ... 
            a.name,a.id,a.description,a.type,a.asset_class,a.currency,a.value_base,a.currency);
         fprintf('value_stress: %8.6f \n',a.value_stress(1:value_stress_rows));
         fprintf('\n');
         % looping via first 5 MC scenario values
         for ( ii = 1 : 1 : value_mc_cols)
            fprintf('MC timestep: %s\n',a.timestep_mc{ii});
            %fprintf('Scenariovalue: %8.2f \n',a.value_mc(1:value_mc_rows,ii));
            fprintf('Scenariovalues:\n[ ')
                for ( jj = 1 : 1 : value_mc_rows)
                    fprintf('%8.6f,\n',a.value_mc(jj,ii));
                end
            fprintf(' ]\n');
         end
        
      end % disp
      
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'cash') || strcmpi(type,'bond') || strcmpi(type,'debt') ...
                    || strcmpi(type,'swaption') ||  strcmpi(type,'option') ...
                    ||  strcmpi(type,'capfloor') || strcmpi(type,'forward') ...
                    || strcmpi(type,'sensitivity') || strcmpi(type,'synthetic') ...
                    || strcmpi(type,'stochastic'))
            error('Type must be either cash, bond, debt, option, swaption, forward, sensitivity, capfloor, stochastic or synthetic')
         end
         obj.type = type;
      end % Set.type
      
    end
    
    methods (Static = true)
      function basis = get_basis(dcc_string)
            % provide static method for converting dcc string into basis value
            basis = get_basis(dcc_string);
      end %get_basis
      
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
            fprintf('WARNING: Instrument.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
            format = 'plain text';
        end 

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} { @var{object} =} Instrument (@var{name}, @var{id}, @var{description}, @var{type}, @var{currency}, @var{base_value}, @var{asset_class})\n\
\n\
Superclass for all instrument objects.\n\
\n\
@itemize @bullet\n\
@item @var{name} (string): name of object\n\
@item @var{id} (string): id of object\n\
@item @var{description} (string): description of object\n\
@item @var{type} (string): instrument type in list [cash, bond, debt, forward,\n\
option, sensitivity, synthetic, capfloor, stochastic, swaption]\n\
@item @var{currency} (string): ISO code of currency\n\
@item @var{base_value} (float): actual base (spot) value of object\n\
@item @var{asset_class} (sring): instrument asset class\n\
@end itemize\n\
@*\n\
The constructor of the instrument class constructs an object with the \n\
following properties and inherits them to all sub classes: @*\n\
@itemize @bullet\n\
@item name: name of object\n\
@item id: id of object\n\
@item description: description of object\n\
@item value_base: actual base (spot) value of object\n\
@item currency: ISO code of currency\n\
@item asset_class: instrument asset class\n\
@item type: type of instrument class (Bond,Forward,...) \n\
@item value_stress: vector with values under stress scenarios\n\
@item value_mc: matrix with values under MC scenarios (values per timestep\n\
per column)\n\
@item timestep_mc: MC timestep per column (cell string)\n\
@end itemize\n\
\n\
@end deftypefn";

        % format help text
        [retval status] = __makeinfo__(textstring,format);
        % status
        if (status == 0)
            % depending on retflag, return textstring
            if (retflag == 0)
                % print formatted textstring
                fprintf("\'Instrument\' is a superclass definition from the file /octarisk/@Instrument/Instrument.m\n");
                fprintf("\n%s\n",retval);
                retval = [];
            end
        end

      end % end of static method help
    end % end of static methods

end % classdef
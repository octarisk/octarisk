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
%# @item valuation_date 
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
      valuation_date = today;     
   end
   
    properties (Access = protected )
      value_stress = [];
      value_mc = [];
    end
    properties (SetAccess = protected )
      timestep_mc = {};
    end
   
   % Class methods
   methods
      function a = Instrument(tmp_name,tmp_id,tmp_description,tmp_type,tmp_currency,tmp_spot_value,tmp_asset_class,tmp_valuation_date)
         % Instrument Constructor function
         if nargin > 0
            a.name = tmp_name;
            a.id = tmp_id;
            a.description = tmp_description;
            a.type = lower(tmp_type);
            a.value_base = tmp_spot_value;
            a.currency = tmp_currency;
            a.asset_class = tmp_asset_class;
            a.valuation_date = tmp_valuation_date;
         end
      end % Instrument
      
      function disp(a)
         % Display a Instrument object
         % Get length of Value vector:
         value_stress_rows = min(rows(a.value_stress),5);
         value_mc_rows = min(rows(a.value_mc),5);
         value_mc_cols = min(length(a.timestep_mc),2);
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\nasset_class: %s\ncurrency: %s\nvalue_base: %f %s\n', ... 
            a.name,a.id,a.description,a.type,a.asset_class,a.currency,a.value_base,a.currency);
         fprintf('value_stress: %8.2f \n',a.value_stress(1:value_stress_rows));
         fprintf('\n');
         % looping via first 5 MC scenario values
         for ( ii = 1 : 1 : value_mc_cols)
            fprintf('MC timestep: %s\n',a.timestep_mc{ii});
            %fprintf('Scenariovalue: %8.2f \n',a.value_mc(1:value_mc_rows,ii));
            fprintf('Scenariovalues:\n[ ')
                for ( jj = 1 : 1 : value_mc_rows)
                    fprintf('%f,\n',a.value_mc(jj,ii));
                end
            fprintf(' ]\n');
         end
        
      end % disp
      
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'cash') || strcmpi(type,'bond') || strcmpi(type,'debt') || strcmpi(type,'swaption') ||  strcmpi(type,'option') || strcmpi(type,'forward') || strcmpi(type,'sensitivity') || strcmpi(type,'synthetic') )
            error('Type must be either cash, bond, debt, option, swaption, forward, sensitivity or synthetic')
         end
         obj.type = type;
      end % Set.type
      
    end
    methods (Static = true)
      function basis = get_basis(dcc_string)
            dcc_cell = cellstr( ['act/act';'30/360 SIA';'act/360';'act/365';'30/360 PSA';'30/360 ISDA';'30/360 European';'act/365 Japanese';'act/act ISMA';'act/360 ISMA';'act/365 ISMA';'30/360E']);
            findvec = strcmp(dcc_string,dcc_cell);
            tt = 1:1:length(dcc_cell);
            tt = (tt - 1)';
            basis = dot(single(findvec),tt);
      end %get_basis
      
      function retval = get_doc(format,path)
        if nargin < 1
            format = 'plain text';
        end
        if nargin < 2
            printflag = 0;
        elseif nargin == 2
            if (ischar(path) && length(path) > 1)
                printflag = 1;
            else
                error('Insufficient path: %s \n',path);
            end
        end
        % printing documentation for Class Instrument (ousourced to dummy function to use documentation behaviour)
        scripts = ['doc_instrument'];
        c = cellstr(scripts);
        for ii = 1:length(c)
            [retval status] = __makeinfo__(get_help_text(c{ii}),format);
        end
        if ( status == 0 )
            if ( printflag == 1) % print to file
                
                if (strcmp(format,'html'))
                    ending = '.html';
                    filename = strcat(path,'functions',ending);
					fid = fopen (filename, 'a');
					retval = strrep( retval, '\', '\\');
                    %replace html title
                    repstring = strcat('<title>', c{ii} ,'</title>');
                    retval = strrep( retval, '<title>Untitled</title>', repstring);
                    % print formatted documentation
					fprintf(fid, retval);
					fprintf(fid, '\n');
					fclose (fid);
                elseif (strcmp(format,'texinfo'))
                    ending = '.texi';
                    filename = strcat(path,'functions',ending);
					fid = fopen (filename, 'a');
					retval = strrep( retval, '\', '\\');
                    % Print texinfo header
					nodestring = strcat('\@node \t', c{ii},'\n')
					fprintf(fid, nodestring);
					sectionstring = strcat('\@section \t', c{ii},'\n')
					fprintf(fid, sectionstring); 
					indexstring = strcat('@cindex \t Function \t', c{ii},'\n');
					fprintf(fid, indexstring);
					% print formatted documentation
					fprintf(fid, retval);
					fprintf(fid, '\n');
					fclose (fid);
                else
                    ending = '.txt';
                end
                 
            else    
                printf('Documentation for Class %s: \n',c{ii}(4:end));
                printf(retval);
                printf('\n');
            end
                     
        else
            disp('There was a problem')
        end
        retval = status;
      end
   end
   
end % classdef

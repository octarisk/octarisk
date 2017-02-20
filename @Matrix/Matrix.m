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

classdef Matrix
   % file: @Matrix/Matrix.m
    properties
      name = '';
      id = '';
      description = '';
      type = ''; 
      components = {};  
    end
   
    properties (SetAccess = protected )
      matrix = []; 
      components_xx = {};   % possibility to specify non symmetric matrix
      components_yy = {};   % possibility to specify non symmetric matrix
    end
 
   % Class methods
   methods
      function a = Matrix(tmp_name)
       % Matrix Constructor method
        if nargin < 1
            name        = 'Correlation Matrix 1';
            tmp_id      = 'MATRIX_CORR_1';
        else
            name        = tmp_name;
            tmp_id      = tmp_name;
        end
        tmp_description = 'Test Correlation Matrix';
        tmp_type        = 'Correlation';
        a.name          = name;
        a.id            = tmp_id;
        a.description   = tmp_description;
        a.type          = lower(tmp_type);                             
      end % Matrix
      
      function disp(a)
         % Display a Matrix object
         % Get length of Value vector:
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\n', ... 
            a.name,a.id,a.description,a.type);
         % looping via all x axis values if defined
         if ( length(a.components) > 0 )
            fprintf('Components :\n{ ');
            for (ii = 1 : 1 : length(a.components))
                fprintf('%s,',a.components{ii});
            end
            fprintf(' }\n');
         end
         
         % looping via all values if defined
         if ( rows(a.matrix) > 0 )
            fprintf('Matrix values:\n[ ');
            [aa bb cc ] = size(a.matrix);
            for ( kk = 1 : 1 : bb)
                for ( jj = 1 : 1 : aa)
                    fprintf('%f,',a.matrix(jj,kk,:));     
                end
                fprintf(';\n');
            end
            fprintf(' ]\n');
         end   
      end % disp
      
	  function obj = set.matrix(obj,matrix)
         if (strcmpi(obj.type,'Correlation') )
            if ~(issymmetric(matrix))
				fprintf('WARNING: Matrix.set: Trying to set non-symmetric matrix for type correlation.\n');
			end
         end
         obj.matrix = matrix;
      end % Set.matrix
	  
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'Correlation')  )
            error('Type must be Correlation')
         end
		 if ~(issymmetric(obj.matrix))
			fprintf('WARNING: Matrix.set: Trying to set Matrix type correlation. Existing matrix is not symmetric.\n');
		 end
         obj.type = type;
      end % Set.type
      
      % simplification: components are symmetric for matrix:
      function obj = set.components(obj,components)
         obj.components = components;
         obj.components_xx = components;
         obj.components_yy = components;
      end % Set.components
      
   end
   
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
			fprintf('WARNING: Curve.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
			format = 'plain text';
		end	

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Matrix(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Matrix()\n\
\n\
Class for setting up Matrix objects.\n\
\n\
This class contains all attributes and methods related to the following Matrix types:\n\
\n\
@itemize @bullet\n\
@item Correlation: specifies a symmetric correlation matrix.\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Matrix object @var{obj}:\n\
@itemize @bullet\n\
@item Matrix(@var{id}) or Matrix(): Constructor of a Matrix object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.getValue(@var{xx},@var{yy}): Return matrix value for component on x-Axis @var{xx}\n\
and component on y-Axis @var{yy}. Component values are recognized as strings.\n\
\n\
@item Matrix.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Matrix objects:\n\
@itemize @bullet\n\
@item @var{id}: Matrix id. Has to be unique identifier. Default: empty string.\n\
@item @var{name}: Matrix name. Default: empty string.\n\
@item @var{description}: Matrix description. Default: empty string.\n\
@item @var{type}: Matrix type. Can be [Correlation]\n\
\n\
@item @var{components}: String cell specifying matrix components. For symmetric\n\
correlation  matrizes x and y-axis components are equal.\n\
@item @var{matrix}: Matrix containing all elements. Has to be of dimension n x n,\n\
while n is length of @var{components} cell.\n\
@item @var{components_xx}: Set automatically while setting @var{components} cell\n\
@item @var{components_yy}: Set automatically while setting @var{components} cell\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
A symmetric 3 x 3 correlation matrix is specified and one specific correlation\n\
for a set of components as well as the whole matrix is retrieved:\n\
@example\n\
@group\n\
\n\
m = Matrix();\n\
component_cell = cell;\n\
component_cell(1) = 'INDEX_A';\n\
component_cell(2) = 'INDEX_B';\n\
component_cell(3) = 'INDEX_C';\n\
m = m.set('id','BASKET_CORR','type','Correlation','components',component_cell);\n\
m = m.set('matrix',[1.0,0.3,-0.2;0.3,1,0.1;-0.2,0.1,1]);\n\
m.get('matrix')\n\
corr_A_C = m.getValue('INDEX_A','INDEX_C')\n\
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
				fprintf("\'Matrix\' is a class definition from the file /octarisk/@Matrix/Matrix.m\n");
				fprintf("\n%s\n",retval);
				retval = [];
			end
		end

		
	end % end of static method help
	
   end	% end of static methods
   
end % classdef

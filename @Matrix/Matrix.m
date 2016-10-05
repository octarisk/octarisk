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
      
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'Correlation')  )
            error('Type must be Correlation')
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
   
end % classdef

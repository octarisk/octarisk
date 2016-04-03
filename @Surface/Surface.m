## -*- texinfo -*-
## @deftypefn  {Function File} {} Surface ()
## @deftypefnx {Function File} {} Surface (@var{a})
## Surface Superclass 
##
## @*
## Superclass properties:
## @itemize @bullet
## @item name: Name of object
## @item id: Id of object
## @item description: Description of object
## @item type: Actual spot value of object
## @item model
## @item mean 
## @item std
## @item skew 
## @item start_value 
## @item mr_level
## @item mr_rate 
## @item node
## @item rate 
## @item scenario_stress: Vector with values of stress scenarios
## @item scenario_mc: Matrix with risk factor scenario values (values per timestep per column)
## @item timestep_mc: MC timestep per column (cell string)
## @end itemize
## @*
##
## @seealso{Instrument}
## @end deftypefn

classdef Surface
   % file: @Surface/Surface.m
    properties
      name = '';
      id = '';
      description = '';
      type = ''; 
      moneyness_type = 'K/S';
      method_interpolation = 'linear';    
    end
   
    properties (SetAccess = protected )
      axis_x = [];
      axis_y = [];
      axis_z = [];
      values_base = [];
      axis_x_name = '';
      axis_y_name = '';
      axis_z_name = '';    
    end
 
   % Class methods
   methods
      function a = Surface(tmp_name,tmp_id,tmp_type,tmp_description)
         % Riskfactor Constructor method
        if nargin < 3
            tmp_name            = 'RF_VOLA_INDEX_DUMMY';
            tmp_id              = 'RF_VOLA_IR_EUR';
            tmp_description     = 'Test Dummy surface';
            tmp_type            = 'Index';
        end 
        if nargin < 4
            tmp_description     = 'Dummy Description';
        end
        if ( strcmp(tmp_id,''))
            error("Error: Surface requires a valid ID")
        endif
        a.name          = tmp_name;
        a.id            = tmp_id;
        a.description   = tmp_description;
        a.type          = toupper(tmp_type);
                     
      end % Surface
      
      function disp(a)
         % Display a Surface object
         % Get length of Value vector:
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\n', ... 
            a.name,a.id,a.description,a.type);
         fprintf('moneyness_type: %s\n',a.moneyness_type);
         fprintf('method_interpolation: %s\n',a.method_interpolation);
         % looping via all x axis values if defined
         if ( length(a.axis_x) > 0 )
            fprintf('Axis x %s : Values :\n[ ',a.axis_x_name);
            for (ii = 1 : 1 : length(a.axis_x))
                fprintf('%d,',a.axis_x(ii));
            endfor
            fprintf(' ]\n');
         endif
         % looping via all y axis values if defined
         if ( length(a.axis_y) > 0 )
            fprintf('Axis y %s : Values :\n[ ',a.axis_y_name);
            for (ii = 1 : 1 : length(a.axis_y))
                fprintf('%d,',a.axis_y(ii));
            endfor
            fprintf(' ]\n');
         endif
         % looping via all z axis values if defined
         if ( length(a.axis_z) > 0 )
            fprintf('Axis z %s : Values :\n[ ',a.axis_z_name);
            for (ii = 1 : 1 : length(a.axis_z))
                fprintf('%d,',a.axis_z(ii));
            endfor
            fprintf(' ]\n');
         endif
         
         % looping via all values if defined
         if ( length(a.values_base) > 0 )
            fprintf('Surface base values:\n[ ');
            [aa bb cc ] = size(a.values_base);
            for ( kk = 1 : 1 : cc)
                if ( length(a.axis_z) == cc );fprintf('%s : %d\n',a.axis_z_name, a.axis_z(kk));endif;
                for ( jj = 1 : 1 : aa)
                    fprintf('%f,',a.values_base(jj,:,kk));
                    fprintf('\n');
                endfor
            endfor
            fprintf(' ]\n');
         endif   
      end % disp
      
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'Index') || strcmpi(type,'IR')  || strcmpi(type,'Dummy')  )
            error('Type must be either Index or IR or Dummy Curve')
         end
         obj.type = type;
      end % Set.type
      
      function obj = set.method_interpolation(obj,method_interpolation)
         if ~(sum(strcmpi(method_interpolation,{'linear','nearest'}))>0  )
            error('Interpolation method must be linear or nearest')
         end
         obj.method_interpolation = method_interpolation;
      end % Set.method_interpolation
      
   end
   
end % classdef

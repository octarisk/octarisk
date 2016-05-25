%# -*- texinfo -*-
%# @deftypefn  {Function File} {} Curve ()
%# @deftypefnx {Function File} {} Curve (@var{a})
%# Curve Superclass 
%#
%# @*
%# Superclass properties:
%# @itemize @bullet
%# @item name: Name of object
%# @item id: Id of object
%# @item description: Description of object
%# @item type: Actual spot value of object
%# @item model
%# @item mean 
%# @item std
%# @item skew 
%# @item start_value 
%# @item mr_level
%# @item mr_rate 
%# @item node
%# @item rate 
%# @item scenario_stress: Vector with values of stress scenarios
%# @item scenario_mc: Matrix with risk factor scenario values (values per timestep per column)
%# @item timestep_mc: MC timestep per column (cell string)
%# @end itemize
%# @*
%#
%# @seealso{Instrument}
%# @end deftypefn

classdef Curve
   % file: @Curve/Curve.m
    properties
      name = '';
      id = '';
      description = '';
      type = '';  
      method_interpolation = 'linear'; %'monotone-convex';  
      compounding_type = 'simple';
      compounding_freq = 'daily';               
      day_count_convention = 'act/365';
      shocktype_mc = 'absolute';  
      increments = '';
    end
   
    properties (SetAccess = protected )
      timestep_mc = {};
      nodes = [];
      rates_base = [];
      rates_mc  = [];
      rates_stress = [];
    end
 
   % Class methods
   methods
      function a = Curve(tmp_name,tmp_id,tmp_type,tmp_description)
         % Riskfactor Constructor method
        if nargin < 3
            tmp_name            = 'Test Curve';
            tmp_id              = 'RF_IR_EUR';
            tmp_description     = 'Test Dummy Curve';
            tmp_type            = 'Discount Curve';
        end 
        if nargin < 4
            tmp_description     = 'Dummy Description';
        end
        if ( strcmp(tmp_id,''))
            error('Error: Curve requires a valid ID')
        end
        a.name          = tmp_name;
        a.id            = tmp_id;
        a.description   = tmp_description;
        a.type          = upper(tmp_type);
                     
      end % Curve
      
      function disp(a)
         % Display a Curve object
         % Get length of Value vector:
         rates_stress_rows = min(rows(a.rates_stress),5);
         [mc_rows mc_cols mc_stack] = size(a.rates_mc);
         rates_stress_cols = min(length(a.rates_stress),2);
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\n', ... 
            a.name,a.id,a.description,a.type);
         fprintf('method_interpolation: %s\n',a.method_interpolation);
         fprintf('shocktype_mc: %s\n',a.shocktype_mc);
         % looping via all riskfactors / sensitivities
         if ( length(a.increments) > 0 )
             for ( ii = 1 : 1 : length(a.increments))
                fprintf('Increments: %s \n',a.increments{ii});            
             end
         end
         % looping via all nodes if defined
         if ( length(a.nodes) > 0 )
            fprintf('Nodes:\n[ ');
            for (ii = 1 : 1 : length(a.nodes))
                fprintf('%d,',a.nodes(ii));
            end
            fprintf(' ]\n');
         end
         % looping via all base values if defined
         if ( length(a.rates_base) > 0 )
            fprintf('Base rates:\n[ ');
            for ( kk = 1 : 1 : min(columns(a.rates_base),10))
                    fprintf('%f,',a.rates_base(kk));
            end
            fprintf(' ]\n');
         end   
          % looping via all stress rates if defined
         if ( rows(a.rates_stress) > 0 )
            tmp_rates = a.getValue('stress');
            fprintf('Stress rates:\n[ ');
            for ( jj = 1 : 1 : min(rows(tmp_rates),5))
                for ( kk = 1 : 1 : min(columns(tmp_rates),10))
                    fprintf('%f,',tmp_rates(jj,kk));
                end
                fprintf(' ]\n');
            end
            fprintf('\n');
         end    
         % looping via first 3 MC scenario values
         for ( ii = 1 : 1 : mc_stack)
            if ( length(a.timestep_mc) >= ii )
                fprintf('MC timestep: %s\n',a.timestep_mc{ii});
                tmp_rates = a.getValue(a.timestep_mc{ii});
                fprintf('Scenariovalue:\n[ ')
                for ( jj = 1 : 1 : min(rows(tmp_rates),5))
                    for ( kk = 1 : 1 : min(columns(tmp_rates),10))
                        fprintf('%f,',tmp_rates(jj,kk));
                    end
                    fprintf(' ]\n');
                end
                fprintf('\n');
            else
                fprintf('MC timestep not defined\n');
            end
         end
      end % disp
      
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'Discount Curve') || strcmpi(type,'Spread Curve')  || strcmpi(type,'Dummy Curve') || strcmpi(type,'Aggregated Curve') )
            error('Type must be either Discount Curve, Spread Curve, Aggregated Curve or Dummy Curve')
         end
         obj.type = type;
      end % Set.type
      
      function obj = set.method_interpolation(obj,method_interpolation)
         if ~(sum(strcmpi(method_interpolation,{'smith-wilson','spline','linear','mm','exponential','loglinear','monotone-convex'}))>0  )
            error('Interpolation method must be either smith-wilson,spline,linear,mm,exponential,monotone-convex or loglinear')
         end
         obj.method_interpolation = method_interpolation;
      end % Set.method_interpolation
      
    end
    methods (Static = true)
      function basis = get_basis(dcc_string)
            dcc_cell = cellstr( ['act/act';'30/360 SIA';'act/360';'act/365';'30/360 PSA';'30/360 ISDA';'30/360 European';'act/365 Japanese';'act/act ISMA';'act/360 ISMA';'act/365 ISMA';'30/360E']);
            findvec = strcmp(dcc_string,dcc_cell);
            tt = 1:1:length(dcc_cell);
            tt = (tt - 1)';
            basis = dot(single(findvec),tt);
      end %get_basis
   end
   
end % classdef

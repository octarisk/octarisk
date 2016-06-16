classdef Curve
   % file: @Curve/Curve.m
    properties
      name = '';
      id = '';
      description = '';
      type = '';  
      method_interpolation = 'linear'; %'monotone-convex';  
      compounding_type = 'cont';
      compounding_freq = 'annual';               
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
      basis = 3;
      floor = '';
      cap = '';
    end
 
   % Class methods
   methods
      function a = Curve(tmp_name)
         % Riskfactor Constructor method
        if nargin < 1
            name        = 'Test Curve';
            tmp_id      = 'IR_EUR_TEST';
        else
            name        = tmp_name;
            tmp_id      = tmp_name;
        end
        tmp_description = 'Test Dummy Curve';
        tmp_type        = 'Discount Curve';
        a.name          = name;
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
         fprintf('compounding_type: %s\n',a.compounding_type);
         fprintf('compounding_freq: %s\n',a.compounding_freq);
         fprintf('day_count_convention: %s\n',a.day_count_convention);
         fprintf('dcc_basis: %d\n',a.basis);
         fprintf('shocktype_mc: %s\n',a.shocktype_mc);
         if ( isnumeric(a.floor))
			fprintf('floor rate: %f\n',a.floor);
         end
         if ( isnumeric(a.cap))
			fprintf('cap rate: %f\n',a.cap);
         end
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
         if ~(strcmpi(type,'Discount Curve') || strcmpi(type,'Spread Curve')  || strcmpi(type,'Dummy Curve') ...
                    || strcmpi(type,'Aggregated Curve') || strcmpi(type,'Prepayment Curve'))
            error('Type must be either Discount Curve, Spread Curve, Aggregated Curve, Dummy Curve or Prepayment Curve')
         end
         obj.type = type;
      end % Set.type
      
      function obj = set.method_interpolation(obj,method_interpolation)
         method_interpolation = lower(method_interpolation);
         if ~(sum(strcmpi(method_interpolation,{'smith-wilson','spline','linear','mm','exponential','loglinear','monotone-convex'}))>0  )
            error('Interpolation method must be either smith-wilson,spline,linear,mm,exponential,monotone-convex or loglinear')
         end
         obj.method_interpolation = method_interpolation;
      end % Set.method_interpolation
      
      function obj = set.day_count_convention(obj,day_count_convention)
        if ~(sum(strcmpi(day_count_convention,{'act/act','30/360 SIA','act/360','act/365','30/360 PSA','30/360 ISDA','30/360 European','act/365 Japanese','act/act ISMA','act/360 ISMA','act/365 ISMA','30/360E'}))>0  )
            fprintf('Curve:set: for curve >>%s<<: day_count_convention >>%s<< must be either act/act,30/360 SIA,act/360,act/365,30/360 PSA,30/360 ISDA,30/360 European,act/365 Japanese,act/act ISMA,act/360 ISMA,act/365 ISMA,30/360E Setting to >>act/365<<\n',obj.id,day_count_convention);
            day_count_convention = 'act/365';
        end
        obj.day_count_convention = day_count_convention;
        % Call superclass method to set basis
        obj.basis = Curve.get_basis(obj.day_count_convention);
      end % set.day_count_convention
      
      function obj = set.compounding_freq(obj,compounding_freq)
        compounding_freq = lower(compounding_freq);
        if ~(sum(strcmpi(compounding_freq,{'day','daily','week','weekly','month','monthly','quarter','quarterly','semi-annual','annual'}))>0  )
            fprintf('Curve:set: for curve >>%s<<: compounding_freq >>%s<< must be either day,daily,week,weekly,month,monthly,quarter,quarterly,semi-annual,annual. Setting to >>annual<<\n',obj.id,compounding_freq);
            compounding_freq = 'annual';
        end
         obj.compounding_freq = compounding_freq;
      end % set.compounding_freq
      
      function obj = set.compounding_type(obj,compounding_type)
        compounding_type = lower(compounding_type);
        if ~(sum(strcmpi(compounding_type,{'simple','continuous','discrete'}))>0  )
            fprintf('Curve:set: for curve >>%s<<: Compounding type >>%s<< must be either >>simple<<, >>continuous<<, or >>discrete<<. Setting to >>continuous<<\n',obj.id,compounding_type);
            compounding_type = 'continuous';
        end
         obj.compounding_type = compounding_type;
      end % set.compounding_type
      
      function obj = set.floor(obj,floor)
         obj.floor = floor;
		 % applying floor rates to rates_base, rates_stress and rates_mc
		 if ( isnumeric(floor))
             obj.rates_base = max(obj.rates_base,floor);
             obj.rates_stress = max(obj.rates_stress,floor);
             obj.rates_mc = max(obj.rates_mc,floor);
         end
      end % set.floor
      
      function obj = set.cap(obj,cap)
         obj.cap = cap;
		 % applying cap rates to rates_base, rates_stress and rates_mc
		 if ( isnumeric(cap))
             obj.rates_base = min(obj.rates_base,cap);
             obj.rates_stress = min(obj.rates_stress,cap);
             obj.rates_mc = min(obj.rates_mc,cap);
         end
      end % set.cap
      
		
		
    end
    methods (Static = true)
      function basis = get_basis(dcc_string)
            dcc_cell = {'act/act' '30/360 SIA' 'act/360' 'act/365' '30/360 PSA' '30/360 ISDA' '30/360 European' 'act/365 Japanese' 'act/act ISMA' 'act/360 ISMA' 'act/365 ISMA' '30/360E'};
            findvec = strcmpi(dcc_string,dcc_cell);
            tt = 1:1:length(dcc_cell);
            tt = (tt - 1)';
            basis = dot(single(findvec),tt);
      end %get_basis
   end
   
end % classdef

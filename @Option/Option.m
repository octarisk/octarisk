classdef Option < Instrument
   
    properties   % All properties of Class Option with default values
        maturity_date = '';
        compounding_type = 'disc';
        compounding_freq = 1;               
        day_count_convention = 'act/365';
        spread = 0.0;             
        discount_curve = 'EUR_IR';
        underlying = 'DAX30';
        vola_surface = 'vol_index_DAX30';
        vola_sensi = 1;
        strike = 100;
        spot = 100;
        multiplier = 5;
        timesteps_size = 5;      % size of one timestep in path dependent valuations
        willowtree_nodes = 20;   % number of willowtree nodes per timestep
        pricing_function_american = 'BjSten'; % [Willowtree,BjSten] 
        div_yield = 0.0;         % dividend yield (continuous, act/365)
        % special attributes required for barrier option only:
        upordown = 'U';          % Up or Down Barrier Option {'U','D'}
        outorin  = 'out';        % out or in Barrier Option {'out','in'}
        barrierlevel = 0.0;      % barrier level triggers barrier event 
        rebate   = 0.0;          % Rebate: payoff in case of a barrier event
    end
 
    properties (SetAccess = private)
        basis = 3;
        call_flag = 1;           % set by sub type -> 1: call, 0: put
        cf_dates = [];
        cf_values = [];
        vola_spread = 0.0;
        sub_type = 'OPT_EUR_C';
        option_type = 'European'; % set by sub_type [European, American, Barrier]
        theo_delta = 0.0;
        theo_gamma = 0.0;
        theo_vega = 0.0;
        theo_theta = 0.0;
        theo_rho = 0.0;
        theo_omega = 0.0;
    end

   methods
      function b = Option(tmp_name)
        if nargin < 1
            name  = 'OPTION_TEST';
            id    = 'OPTION_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Option test instrument';
        value_base = 1.00;      
        currency = 'EUR';
        asset_class = 'Derivative';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'option',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type); 
         fprintf('option_type: %s\n',b.option_type); 
         fprintf('call_flag: %d\n',b.call_flag);
         if ( strcmpi(b.option_type,'Barrier') )
            fprintf('Barrier Level: %f\n',b.barrierlevel);
            fprintf('Rebate: %f\n',b.rebate);
            fprintf('UporDown: %s\n',b.upordown);
            fprintf('OutorIn: %s\n',b.outorin);
         end
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('strike: %f \n',b.strike);
         fprintf('multiplier: %f \n',b.multiplier);         
         fprintf('underlying: %s\n',b.underlying);  
         fprintf('vola_surface: %s\n',b.vola_surface ); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('spread: %f\n',b.spread); 
         fprintf('div_yield (cont, act/365): %f \n',b.div_yield);
         fprintf('vola_sensi: %f\n',b.vola_sensi); 
         fprintf('compounding_type: %s\n',b.compounding_type);  
         fprintf('compounding_freq: %d\n',b.compounding_freq);    
         fprintf('day_count_convention: %s\n',b.day_count_convention);
         if ( b.theo_delta ~= 0 )
            fprintf('theo_delta:\t%8.4f\n',b.theo_delta);  
            fprintf('theo_gamma:\t%8.4f\n',b.theo_gamma);  
            fprintf('theo_vega:\t%8.4f\n',b.theo_vega);  
            fprintf('theo_theta:\t%8.4f\n',b.theo_theta);  
            fprintf('theo_rho:\t%8.4f\n',b.theo_rho);  
            fprintf('theo_omega:\t%8.4f\n',b.theo_omega);  
         end    

      end
      % converting object <-> struct for saving / loading purposes
      % function b = saveobj (a)
          % disp('Converting object to struct');
          % b = struct(a);       
      % end
      function b = loadobj (t,a)
          disp('Converting stuct to object');
          b = Option();
          b.id          = a.id;
          b.name        = a.name; 
          b.description = a.description;  
          b = b.set('timestep_mc',a.timestep_mc);
          b = b.set('value_mc',a.value_mc);
          b.spot            = a.spot;
          b.strike          = a.strike;
          b.maturity_date   = a.maturity_date;
          b.discount_curve  = a.discount_curve;
          b.compounding_type = a.compounding_type;
          b.compounding_freq = a.compounding_freq;               
          b.day_count_convention = a.day_count_convention;
          b.spread          = a.spread;             
          b.underlying      = a.underlying;
          b.vola_surface    = a.vola_surface;
          b.vola_sensi      = a.vola_sensi;
          b.multiplier      = a.multiplier;
          b.basis           = a.basis;
          b.cf_dates        = a.cf_dates;
          b.cf_values       = a.cf_values;
          b.vola_surf       = a.vola_surf;
          b.vola_surf_mc    = a.vola_surf_mc;
          b.vola_surf_stress = a.vola_surf_stress;
          b.vola_spread     = a.vola_spread;
          b.sub_type        = a.sub_type;
      end  
      function obj = set.sub_type(obj,sub_type)
         if ~(any(strcmpi(sub_type,{'OPT_EUR_C','OPT_EUR_P','OPT_AM_C','OPT_AM_P','OPT_BAR_P','OPT_BAR_C'})))
            error('Option sub_type must be either OPT_EUR_C, OPT_EUR_P, OPT_AM_C, OPT_AM_P, OPT_BAR_P or OPT_BAR_C')
         end
         obj.sub_type = sub_type;
         % set call_flag
         if ( regexpi(sub_type,'_P$'))  % put option
            obj.call_flag = 0;
         else                           % call option
            obj.call_flag = 1;
         end
         % set option type
         if ( regexpi(sub_type,'_EUR_'))        % European (plain vanilla) option
            obj.option_type = 'European';
         elseif ( regexpi(sub_type,'_AM_'))     % American (plain vanilla) option
            obj.option_type = 'American';
         elseif ( regexpi(sub_type,'_BAR_'))    % (European) Barrier option
            obj.option_type = 'Barrier';
         end
      end % set.sub_type
      function obj = set.upordown(obj,upordown)
         if ~(any(strcmpi(upordown,{'U','D'})))
            error('Option upordown must be either U or D')
         end
         obj.upordown = upper(upordown);
      end % set.upordown
      function obj = set.outorin(obj,outorin)
         if ~(any(strcmpi(outorin,{'out','in'})))
            error('Option outorin must be either out or in')
         end
         obj.outorin = lower(outorin);
      end % set.outorin
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
   end 

end 
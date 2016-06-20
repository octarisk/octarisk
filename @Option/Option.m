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
        theo_delta = 0.0;
        theo_gamma = 0.0;
        theo_vega = 0.0;
        theo_theta = 0.0;
        theo_rho = 0.0;
        theo_omega = 0.0; 
        pricing_function_american = 'Willowtree'; 
        div_yield = 0.0;         % dividend yield (continuous, act/365)
    end
   
    properties (SetAccess = private)
        basis = 3;
        cf_dates = [];
        cf_values = [];
        vola_surf = [];
        vola_surf_mc  = [];
        vola_surf_stress = [];
        vola_spread = 0.0;
        sub_type = 'OPT_EUR_C';
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
        valuation_date = today; 
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'option',currency,value_base, ...
                        asset_class,valuation_date); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);                   
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('strike: %f \n',b.strike);
         fprintf('multiplier: %f \n',b.multiplier);         
         fprintf('underlying: %s\n',b.underlying);  
         fprintf('vola_surface: %s\n',b.vola_surface ); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('spread: %f\n',b.spread); 
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
         if ~(strcmpi(sub_type,'OPT_EUR_C') || strcmpi(sub_type,'OPT_EUR_P') || strcmpi(sub_type,'OPT_AM_C') || strcmpi(sub_type,'OPT_AM_P') )
            error('Option sub_type must be either OPT_EUR_C, OPT_EUR_P, OPT_AM_C, OPT_AM_P ')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
   end 

end 
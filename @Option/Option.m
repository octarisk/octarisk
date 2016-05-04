classdef Option < Instrument
   
    properties   % All properties of Class Option with default values
        maturity_date = '';
        compounding_type = 'disc';
        compounding_freq = 1;               
        day_count_convention = 'act/365';
        spread = 0.0;             
        discount_curve = 'RF_IF_EUR';
        underlying = 'RF_EQ_DE';
        vola_surface = 'vol_index_RF_EQ_DE';
        vola_sensi = 1;
        strike = 100;
        spot = 100;
        multiplier = 5;
        timesteps_size = 5;      % size of one timestep in path dependent valuations
        willowtree_nodes = 20;   % number of willowtree nodes per timestep
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
      function b = Option(name,id,description,sub_type,currency,base_value,asset_class,valuation_date,riskfactors,sensitivities,special_num,special_str,tmp_cf_dates,tmp_cf_values)
        if nargin < 12
           name = 'ODAXC20160318';
           id = 'ODAXC20160318';
           description = 'Call Option DAX for testing purposes';
           sub_type = 'OPT_EUR_C';
           currency = 'EUR';
           base_value = 125;
           asset_class = 'Derivative';
           riskfactors = {'RF_VOLA_EQ_DE','RF_EQ_DE','STRIKE','RF_IR_EUR'};
           sensitivities = [1,9220,10200,0];
           special_num = [5,1];
           special_str = {'18-Mar-2016','disc','30/360'};
           tmp_cf_dates = [];
           tmp_cf_values = [];
           valuation_date = today;
        elseif( nargin == 12)
           tmp_cf_dates = [];
           tmp_cf_values = [];
        elseif ( nargin == 14)
            if ( length(tmp_cf_dates) > 0 )
                tmp_cf_dates = (tmp_cf_dates)' - today;
            end
        end
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'option',currency,base_value,asset_class,valuation_date);
        % setting property sub_type
        if ( strcmp(sub_type,'') )
            error('Error: No sub_type specified');
        else
            b.sub_type = sub_type;
        end

        % setting property issue_date
        if ( length(special_str) >= 1 )
            if ( ~strcmp(special_str{1},'') )
                b.maturity_date =  datestr(special_str{1});
            end
        end

        % parsing attribute special_str
            % setting property compounding_type
            if ( length(special_str) >= 2  )
                b.compounding_type = lower(special_str{2});
            end

            % setting property day_count_convention
            if ( length(special_str) >= 3  )
                b.day_count_convention = special_str{3};
            end
 
        % parsing attribute special_num
            % setting property multiplier
            if ( length(special_num) >= 1  )
                b.multiplier = special_num(1);  
            end
            % setting property compounding_freq
            if ( length(special_num) >= 2  )
                b.compounding_freq = special_num(2);  
            end 

        % parsing attribute sensitivities
            % setting property vola_sensi
            if ( length(sensitivities) < 1  )
                error('Error: No vola_sensi specified');
            else
                b.vola_sensi = sensitivities(1);
            end        
            % setting property spot
            if ( length(sensitivities) < 2  )
                error('Error: No spot specified');
            else
                b.spot = sensitivities(2);
            end       
            % setting property strike
            if ( length(sensitivities) < 3  )
                error('Error: No strike specified');
            else
                b.strike = sensitivities(3);
            end
            % setting property spread
            if ( length(sensitivities) >= 3  )
                b.spread = sensitivities(4);
            end

        % parsing attribute riskfactors
            % setting property vola surface
            if ( length(riskfactors) < 1  )
                error('Error: No vola_surface specified');
            else
                b.vola_surface = riskfactors{1};
            end
             % setting property underlying
            if ( length(riskfactors) < 2  )
                error('Error: No underlying specified');
            else
                b.underlying = riskfactors{2};
            end
             % setting property discount_curve
            if ( length(riskfactors) < 4  )
                error('Error: No discount_curve specified');
            else
                b.discount_curve = riskfactors{4};
            end
        b.cf_dates = tmp_cf_dates;
        b.cf_values = tmp_cf_values;
        
        % Call static superclass method to set basis
        b.basis = Instrument.get_basis(b.day_count_convention);
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);                   
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('spot: %f \n',b.spot); 
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
   end 
   
   methods (Static = true)
      function market_value = calc_value_tmp(notional,coupon_rate)
            market_value = notional .* coupon_rate;
      end       
   end
end 
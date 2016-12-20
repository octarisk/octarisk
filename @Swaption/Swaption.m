classdef Swaption < Instrument
   
    properties   % All properties of Class Swaption with default values
        maturity_date = '';
        effective_date = '';
        compounding_type = 'disc';
        compounding_freq = 1;               
        day_count_convention = 'act/365';
        spread = 0.0;             
        discount_curve = 'RF_IF_EUR';
        underlying = 'RF_IF_EUR';
        vola_surface = 'RF_VOLA_IR_EUR';
        vola_sensi = 1;
        strike = 0.025;
        spot = 0.025;
        multiplier = 100;
        tenor = 10;                 % Tenor of underlying swap in years
        no_payments = 1;
        und_fixed_leg = '';         % String: underlying fixed leg
        und_floating_leg = '';      % String: underlying floating leg
        use_underlyings = false;    % BOOL: use underlying legs for valuation
        calibration_flag = 1;       % BOOL: if true, no calibration will be done
    end
   
    properties (SetAccess = private)
        basis = 3;
        cf_dates = [];
        cf_values = [];
        vola_spread = 0.0;
        sub_type = 'SWAPT_PAY';
        model = 'black';
        und_fixed_value = 0.0;
        und_float_value = 0.0;
        call_flag = false;
        implied_volatility = 0.0;
    end

   methods
      function b = Swaption(tmp_name)
        if nargin < 1
            name  = 'SWAPTION_TEST';
            id    = 'SWAPTION_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Swaption test instrument';
        value_base = 1.00;      
        currency = 'EUR';
        asset_class = 'Derivative';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'swaption',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);                   
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('strike: %f \n',b.strike);
         fprintf('multiplier: %f \n',b.multiplier);          
         fprintf('vola_surface: %s\n',b.vola_surface ); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('spread: %f\n',b.spread); 
         fprintf('tenor (years): %f\n',b.tenor); 
         fprintf('no_payments (per year): %f\n',b.no_payments); 
         fprintf('vola_sensi: %f\n',b.vola_sensi); 
         fprintf('compounding_type: %s\n',b.compounding_type);  
         fprintf('compounding_freq: %d\n',b.compounding_freq);    
         fprintf('day_count_convention: %s\n',b.day_count_convention); 
         fprintf('model: %s\n',b.model); 
         fprintf('und_fixed_leg: %s\n',b.und_fixed_leg); 
         fprintf('und_floating_leg: %s\n',b.und_floating_leg); 
         fprintf('use_underlyings: %s\n',any2str(b.use_underlyings)); 
         if ~(b.und_float_value == 0.0)
            fprintf('und_float_value: %f \n',b.und_float_value);
         end
         if ~(b.und_fixed_value == 0.0)
            fprintf('und_fixed_value: %f \n',b.und_fixed_value);
         end
         if ~(b.implied_volatility == 0.0)
            fprintf('implied_volatility: %f \n',b.implied_volatility);
         end
         if ~(b.vola_spread == 0.0)
            fprintf('vola_spread: %f \n',b.vola_spread);
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
          b.tenor           = a.tenor;
          b.no_payments     = a.no_payments;
          b.multiplier      = a.multiplier;
          b.basis           = a.basis;
          b.cf_dates        = a.cf_dates;
          b.cf_values       = a.cf_values;
          b.vola_spread     = a.vola_spread;
          b.sub_type        = a.sub_type;
      end  
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'SWAPT_REC') || strcmpi(sub_type,'SWAPT_PAY') )
            error('Swaption sub_type must be either SWAPT_REC, SWAPT_PAY')
         end
         if (strcmpi(sub_type,'SWAPT_PAY') )
            obj.call_flag = true; % Receive fixed, pay float -> put option on fixed
         else
            obj.call_flag = false;
         end
         obj.sub_type = sub_type;
      end % set.sub_type
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
      
      function obj = set.model(obj,model)
        model = lower(model);
        if ~(strcmpi(model,'normal') || strcmpi(model,'black') || strcmpi(model,'black76') )
            error('Swaption model must be either normal or black')
        end
        obj.model = model;
      end % set.model
      
   end 
   
end 
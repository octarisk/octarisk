classdef Forward < Instrument
  
    properties   % All properties of Class Forward with default values
        issue_date = '01-Jan-1900';
        maturity_date = '';
        compounding_type = 'disc';
        compounding_freq = 'annual';  
        strike_price = 0.0;               
        day_count_convention = 'act/365';         
        underlying_price_base = 0.0;
        underlying_id = 'INDEX_EQ_DE';
        underlying_sensitivity = 1;
        discount_curve = 'IR_EUR';
        foreign_curve = 'IR_USD';
        multiplier = 1;
        dividend_yield = 0.0; 
        convenience_yield = 0.0;
        storage_cost = 0.0;
        spread = 0.0;          
        cf_dates = [];
        cf_values = [];
    end
    properties (SetAccess = private)
        sub_type = 'EQFWD';
        basis = 3;
    end
    
   methods
      function b = Forward(tmp_name)
         if nargin < 1
            name  = 'FWD_TEST';
            id    = 'FWD_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Forward test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'derivative';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'forward',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);                     
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('compounding_type: %s\n',b.compounding_type);  
         if (ischar(b.compounding_freq))
            fprintf('compounding_freq: %s\n',b.compounding_freq); 
         else
            fprintf('compounding_freq: %d\n',b.compounding_freq);  
         end   
         fprintf('day_count_convention: %s\n',b.day_count_convention); 
         fprintf('strike_price: %f\n',b.strike_price);  
         fprintf('underlying_id: %s\n',b.underlying_id); 
         %fprintf('underlying_price_base: %f\n',b.underlying_price_base); 
         fprintf('underlying_sensitivity: %d\n',b.underlying_sensitivity); 
         fprintf('dividend_yield: %f\n',b.dividend_yield); 
         fprintf('convenience_yield: %f\n',b.convenience_yield);
         fprintf('storage_cost: %f\n',b.storage_cost);         
         fprintf('multiplier: %f\n',b.multiplier); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'Equity') || strcmpi(sub_type,'Bond') ...
                || strcmpi(sub_type,'EQFWD') || strcmpi(sub_type,'FX') )
            error('Forward sub_type must be either Equity, EQFWD, Bond or FX')
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

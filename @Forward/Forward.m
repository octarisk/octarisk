classdef Forward < Instrument
  
    properties   % All properties of Class Forward with default values
        issue_date = datestr(today);
        maturity_date = '';
        compounding_type = 'disc';
        compounding_freq = 'daily';  
        strike_price = 0.0;               
        day_count_convention = 'act/365';         
        underlying_price_base = 0.0;
        underlying_id = 'RF_EQ_DE';
        underlying_sensitivity = 1;
        discount_curve = 'RF_IR_EUR';
        multiplier = 1;
        dividend_yield = 0; 
        convenience_yield = 1;
        storage_cost = 0;
        spread = 0.0;          
        cf_dates = [];
        cf_values = [];
    end
    properties (SetAccess = private)
        sub_type = 'EQFWD';
        basis = 3;
    end
    
   methods
      function b = Forward(name,id,description,sub_type,currency,base_value,asset_class,valuation_date,riskfactors,sensitivities,special_num,special_str,tmp_cf_dates,tmp_cf_values)
        if nargin < 11
           name = 'Dummy';
           id = 'Dummy';
           description = '';
           sub_type = 'EQFWD';
           currency = 'EUR';
           base_value = 0;
           asset_class = 'Derivative';
           riskfactors = {'RF_EQ_DE','RF_IR_EUR'};
           sensitivities = [1,1];
           special_num = [100,100,1,0.0,0.0,0.0];
           special_str = {'01-Feb-2017','disc',1,'act/365'};
           tmp_cf_dates = [];
           tmp_cf_values = [];
           valuation_date = today;
        elseif( nargin == 11)
           tmp_cf_dates = [];
           tmp_cf_values = [];
        elseif ( nargin == 13)
            if ( length(tmp_cf_dates) > 0 )
                tmp_cf_dates = (tmp_cf_dates)' .- today;
            endif
        end
        
        % Calling constructor
        b = b@Instrument(name,id,description,'forward',currency,base_value,asset_class,valuation_date);
        % === Parsing special_str === 
        % setting property maturity_date
        if ( length(special_str) >= 1 )
            if ( !strcmp(special_str{1},'')  )
                b.maturity_date =  datestr(special_str{1});
            else
                error("Error: No maturity date specified");
            endif
        endif
        % setting property compounding_type
        if ( length(special_str) >= 2  )
            b.compounding_type = tolower(special_str{2});
        endif
        % setting property compounding_freq
        if ( length(special_str) >= 3  )
            b.compounding_freq = special_str{3};
        endif
        % setting property day_count_convention
        if ( length(special_str) >= 4  )
            b.day_count_convention = special_str{4};
        endif
        % setting property sub_type
        if ( strcmp(sub_type,'') )
            error("Error: No sub_type specified");
        else
            b.sub_type = sub_type;
        endif 
        % === Parsing special_num ===        
        % setting property strike price
        if ( length(special_num) < 1  )
            error("Error: No strike_price specified");
        else
            b.strike_price = special_num(1);  
        endif
        % setting property underlying price
        if ( length(special_num) < 2 )
            error("Error: No underlying_price specified");
        else
            b.underlying_price_base = special_num(2);  
        endif  
        % setting property multiplier
        if ( length(special_num) >= 3 )
            b.multiplier = special_num(3);  
        endif 
        % setting property dividend_yield
        if ( length(special_num) >= 4 )
            b.dividend_yield = special_num(4);  
        endif 
        % setting property storage_cost
        if ( length(special_num) >= 5 )
            b.storage_cost = special_num(5);  
        endif 
        % setting property convenience_yield
        if ( length(special_num) >= 6 )
            b.convenience_yield = special_num(6);  
        endif 
        % === Parsing riskfactors ===
        % setting property underlying_id
        if ( length(riskfactors) < 1  )
            error("Error: No underlying_id specified");
        else
            b.underlying_id = riskfactors{1};
        endif
        % setting property discount_curve
        if ( length(riskfactors) < 2 )
            error("Error: No discount_curve specified");
        else
            b.discount_curve = riskfactors{2};
        endif
         % setting property convenience_yield
        if ( length(sensitivities) >= 1 )
            b.underlying_sensitivity = sensitivities(1);  
        endif 
        % === Parsing cash flows ===
        b.cf_dates = tmp_cf_dates;
        b.cf_values = tmp_cf_values;
        
        % Call static methods
        b.basis = Instrument.get_basis(b.day_count_convention);
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
         fprintf('underlying_price_base: %f\n',b.underlying_price_base); 
         fprintf('underlying_sensitivity: %d\n',b.underlying_sensitivity); 
         fprintf('dividend_yield: %f\n',b.dividend_yield); 
         fprintf('convenience_yield: %f\n',b.convenience_yield);
         fprintf('storage_cost: %f\n',b.storage_cost);         
         fprintf('multiplier: %f\n',b.multiplier); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'Equity') || strcmpi(sub_type,'Bond') || strcmpi(sub_type,'EQFWD') )
            error('Forward sub_type must be either Equity, EQFWD or Bond')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
   end 
   
   methods (Static = true)
      function market_value = test_value(notional,coupon_rate)
            market_value = notional .* coupon_rate;
      end 
   end
end 
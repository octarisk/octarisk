classdef Debt < Instrument
   
    properties   % All properties of Class Debt with default values
        discount_curve  = 'RF_IF_EUR';
        spread_curve    = 'RF_SPREAD_DUMMY';           
    end
   
    properties (SetAccess = private)
        sub_type        = 'DBT';
        cf_dates = [];
        cf_values = [];
        duration        = 0.0;       
        convexity       = 0.0; 
    end
   
   methods
      function b = Debt(name,id,description,sub_type,currency,base_value,asset_class,valuation_date,riskfactors,sensitivities,special_num,special_str,tmp_cf_dates,tmp_cf_values)
        if nargin < 12
           name = 'Dummy';
           id = 'Dummy';
           description = 'Test debt instrument for testing purposes';
           sub_type = 'DBT';
           currency = 'EUR';
           base_value = 100;
           asset_class = 'Fixed Income';
           riskfactors = {'RF_IR_DUMMY','RF_SPREAD_DUMMY'};
           sensitivities = [7.8,-15.8];
           special_num = [];
           special_str = {};
           tmp_cf_dates = [];
           tmp_cf_values = [];
           valuation_date = today;
        elseif( nargin == 12)
           tmp_cf_dates = [];
           tmp_cf_values = [];
        elseif ( nargin == 14)
            if ( length(tmp_cf_dates) > 0 )
                tmp_cf_dates = (tmp_cf_dates)' - today;
            endif
        end
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'debt',currency,base_value,asset_class,valuation_date);
        % setting property sub_type
        if ( strcmp(sub_type,'') )
            error('Error: No sub_type specified');
        else
            b.sub_type = sub_type;
        endif     
        % setting property duration
        if ( length(sensitivities) >= 1  )
            b.duration = sensitivities(1);
        endif
        % setting property convexity
        if ( length(sensitivities) >= 2  )
            b.convexity = sensitivities(2);
        endif
        % setting property discount_curve
        if ( length(riskfactors) < 1  )
            error('Error: No discount_curve specified');
        else
            b.discount_curve = riskfactors{1};
        endif
        % setting property spread_curve
        if ( length(riskfactors) >= 2 )
            b.spread_curve = riskfactors{2};
        endif
        b.cf_dates = tmp_cf_dates;
        b.cf_values = tmp_cf_values;
        
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);              
         fprintf('duration: %f\n',b.duration); 
         fprintf('convexity: %f\n',b.convexity); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('spread_curve: %s\n',b.spread_curve); 
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'DBT') )
            error('Bond sub_type must be DBT.')
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

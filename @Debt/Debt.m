classdef Debt < Instrument
   
    properties   % All properties of Class Debt with default values
        discount_curve  = 'IR_EUR';        
    end
   
    properties (SetAccess = private)
        sub_type    = 'DBT';
        cf_dates    = [];
        cf_values   = [];
        duration    = 0.0;       
        convexity   = 0.0; 
    end
   
   methods
      function b = Debt(tmp_name)
        if nargin < 1
            name  = 'DEBT_TEST';
            id    = 'DEBT_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Debt test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'debt';   
        valuation_date = today; 
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'debt',currency,value_base, ...
                        asset_class,valuation_date); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);              
         fprintf('duration: %f\n',b.duration); 
         fprintf('convexity: %f\n',b.convexity); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'DBT') )
            error('Bond sub_type must be DBT.')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
   end 
   
end 

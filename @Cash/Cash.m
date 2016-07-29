classdef Cash < Instrument
   
    properties   % All properties of Class Debt with default values
        discount_curve = '';
    end
   
    properties (SetAccess = private)
        sub_type    = 'cash';
        cf_dates    = [];
        cf_values   = [];
    end
   
   methods
      function b = Cash(tmp_name)
        if nargin < 1
            name  = 'CASH_TEST';
            id    = 'CASH_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Cash test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'cash';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'cash',currency,value_base, ...
                        asset_class);  
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);               
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'cash') )
            error('Cash sub_type must be cash.')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
   end 
   
end 
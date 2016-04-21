classdef Cash < Instrument
   
    properties   % All properties of Class Debt with default values
        discount_curve = '';
    end
   
    properties (SetAccess = private)
        sub_type        = 'cash';
        cf_dates = [];
        cf_values = [];
    end
   
   methods
      function b = Cash(name,id,description,sub_type,currency,base_value,asset_class,valuation_date,riskfactors,sensitivities,special_num,special_str,tmp_cf_dates,tmp_cf_values)
        if nargin < 12
           name = 'Cash Account';
           id = 'CashAccount';
           description = 'Test cash instrument for testing purposes';
           sub_type = 'cash';
           currency = 'EUR';
           base_value = 1;
           asset_class = 'Cash';
           riskfactors = {};
           sensitivities = [];
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
                tmp_cf_dates = (tmp_cf_dates)' .- today;
            endif
        end
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'cash',currency,base_value,asset_class,valuation_date);
        % setting property sub_type
        if ( strcmp(sub_type,'') )
            error("Error: No sub_type specified");
        else
            b.sub_type = sub_type;
        endif     
        b.cf_dates = tmp_cf_dates;
        b.cf_values = tmp_cf_values;
        
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
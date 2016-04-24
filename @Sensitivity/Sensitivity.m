classdef Sensitivity < Instrument
   
    properties   % All properties of Class Debt with default values
        riskfactors  = {'RF_EQ_DE'};
        sensitivities    = [1]; 
        idio_vola = 0.0;    
    end
   
    properties (SetAccess = private)
        sub_type  = 'STK';
        cf_dates  = [];
        cf_values = [];
    end
   
   methods
      function b = Sensitivity(name,id,description,sub_type,currency,base_value,asset_class,valuation_date,riskfactors,sensitivities,special_num,special_str,tmp_cf_dates,tmp_cf_values)
        if nargin < 12
           name = 'DummyStock';
           id = 'DummyStock';
           description = 'Stock instrument for testing purposes';
           sub_type = 'STK';
           currency = 'EUR';
           base_value = 100;
           asset_class = 'Equity';
           riskfactors = {'RF_EQ_DE','RF_EQ_NA','IDIO'};
           sensitivities = [0.6,0.4,0.15];
           special_num = [0.3];
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
        b = b@Instrument(name,id,description,'sensitivity',currency,base_value,asset_class,valuation_date);
        % setting property sub_type
        if ( strcmp(sub_type,'') )
            error('Error: No sub_type specified');
        else
            b.sub_type = sub_type;
        endif     
        % setting property sensitivity
        if ( length(sensitivities) >= 1  )
            b.sensitivities = sensitivities;
        endif
        % setting property riskfactors
        if ( length(riskfactors) >= 1  )
            b.riskfactors = riskfactors;
        endif
        % setting property riskfactors
        if ( length(special_num) >= 1  )
            b.idio_vola = special_num(1);
        endif
        b.cf_dates = tmp_cf_dates;
        b.cf_values = tmp_cf_values;
        
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);              
         % looping via all riskfactors / sensitivities
         for ( ii = 1 : 1 : length(b.sensitivities))
            fprintf('Riskfactor: %s | Sensitivity: %f\n',b.riskfactors{ii},b.sensitivities(ii));            
         endfor
         fprintf('idio_vola: %f\n',b.idio_vola); 
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,{'EQU','RET','COM','STK','ALT'}) )
            error('Sensitivity Instruments sub_type must be EQU,RET,COM,STK,ALT')
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
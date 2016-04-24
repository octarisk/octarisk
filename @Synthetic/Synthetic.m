classdef Synthetic < Instrument
   
    properties   % All properties of Class Debt with default values
        instruments  = {'BASF11'};
        weights    = [1]; 
    end
   
    properties (SetAccess = private)
        sub_type  = 'SYNTH';
        cf_dates  = [];
        cf_values = [];
    end
   
   methods
      function b = Synthetic(name,id,description,sub_type,currency,base_value,asset_class,valuation_date,riskfactors,sensitivities,special_num,special_str,tmp_cf_dates,tmp_cf_values)
        if nargin < 12
           name = 'DummySynthetic';
           id = 'DummySynthetic';
           description = 'Synthetic instrument for testing purposes';
           sub_type = 'SYNTH';
           currency = 'EUR';
           base_value = 100;
           asset_class = 'Diversified';
           riskfactors = {'BASF11','114171'};
           sensitivities = [0.6,0.4];
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
            end
        end
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'synthetic',currency,base_value,asset_class,valuation_date);
        % setting property sub_type
        if ( strcmp(sub_type,'') )
            error('Error: No sub_type specified');
        else
            b.sub_type = sub_type;
        end     
        % setting property weights
        if ( length(sensitivities) >= 1  )
            b.weights = sensitivities;
        end
        % setting property instruments
        if ( length(riskfactors) >= 1  )
            b.instruments = riskfactors;
        end
        b.cf_dates = tmp_cf_dates;
        b.cf_values = tmp_cf_values;
        
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);              
         % looping via all instruments / weights
         for ( ii = 1 : 1 : length(b.weights))
            fprintf('Instrument: %s | weight: %f\n',b.instruments{ii},b.weights(ii));            
         end
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,{'SYNTH'}) )
            error('Synthetic Instrument sub_type must be SYNTH')
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
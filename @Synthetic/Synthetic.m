classdef Synthetic < Instrument
   
    properties   % All properties of Class Debt with default values
        instruments  = {'TEST_INSTRUMENT'};
        weights    = [1]; 
    end
   
    properties (SetAccess = private)
        sub_type  = 'SYNTH';
        cf_dates  = [];
        cf_values = [];
    end
   
   methods
      function b = Synthetic(tmp_name)
        if nargin < 1
            name  = 'SYNTH_TEST';
            id    = 'SYNTH_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Synthetic test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'Synthetic';   
        valuation_date = today; 
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'synthetic',currency,value_base, ...
                        asset_class,valuation_date); 
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
end 
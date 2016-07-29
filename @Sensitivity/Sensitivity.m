classdef Sensitivity < Instrument
   
    properties
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
      function b = Sensitivity(tmp_name)
        if nargin < 1
            name  = 'SENSI_TEST';
            id    = 'SENSI_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Sensitivity test instrument';
        value_base  = 100.00;      
        currency    = 'EUR';
        asset_class = 'Equity';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'sensitivity',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);              
         % looping via all riskfactors / sensitivities
         for ( ii = 1 : 1 : length(b.sensitivities))
            fprintf('Riskfactor: %s | Sensitivity: %f\n',b.riskfactors{ii},b.sensitivities(ii));            
         end
         fprintf('idio_vola: %f\n',b.idio_vola); 
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,{'EQU','RET','COM','STK','ALT'}) )
            error('Sensitivity Instruments sub_type must be EQU,RET,COM,STK,ALT')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
   end 

end 
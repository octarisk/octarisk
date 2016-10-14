classdef Synthetic < Instrument
   
    properties   % All properties of Class Debt with default values
        instruments  = {'TEST_INSTRUMENT'};
        weights    = [1]; 
        compounding_type = 'cont';
        compounding_freq = 'annual';                
        day_count_convention = 'act/365';         
        instr_vol_surfaces  = {'INSTRUMENT_VOL'};
        discount_curve = '';
        correlation_matrix = '';
    end
   
    properties (SetAccess = private)
        sub_type  = 'SYNTH';
        cf_dates  = [];
        cf_values = [];
        basis = 3;
        is_basket = false;
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
         fprintf('compounding_type: %s\n',b.compounding_type); 
         fprintf('compounding_freq: %s\n',b.compounding_freq); 
         fprintf('day_count_convention: %s\n',b.day_count_convention); 
         fprintf('basis: %s\n',any2str(b.basis)); 
         fprintf('correlation_matrix: %s\n',b.correlation_matrix); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('Instrument Volatility Surface(s): %s \n',any2str(b.instr_vol_surfaces));            
      end
      
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,{'SYNTH'}) || strcmpi(sub_type,{'Basket'}) )
            error('Synthetic Instrument sub_type must be SYNTH or Basket')
         end
         obj.sub_type = sub_type;
         if ( strcmpi(sub_type,{'Basket'}) )
            obj.is_basket = true;
         end
      end % set.sub_type
      
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
   end 
end 
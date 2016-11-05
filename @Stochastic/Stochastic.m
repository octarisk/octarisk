%# -*- texinfo -*-
%# @deftypefn  {Function File} {} Stochastic ()
%# @deftypefnx {Function File} {} Stochastic (@var{id})
%# Stochastic Class, inherited attributes from Instrument Superclass 
%# A Stochastic instrument uses a risk factor with random variables 
%# (either uniform, normal or t-distributed) to draw values from a 1D Surface.
%# The surface has exactly one value per given quantile [0,1].
%# This instrument type can be used to pre-calculate values in another risk 
%# system for a given risk factor distribution.
%#
%# @seealso{Bond, Forward, Option, Swaption, Debt, Sensitivity, Synthetic}
%# @end deftypefn

classdef Stochastic < Instrument
   
    properties   % All properties of Class Bond with default values
        quantile_base = 0.5;
        stochastic_riskfactor   = 'RF_STOCHASTIC';    % used for stochastic cf
        stochastic_curve        = 'STOCHASTIC_CURVE';  % used for stochastic cf
        stochastic_rf_type      = 'normal';       % either normal or univariate
        t_degree_freedom        = 120;  % degrees of freedom for t distribution
    end
   
    properties (SetAccess = private)
        sub_type = 'stochastic';
    end
   
   methods
      function b = Stochastic(tmp_name)
        if nargin < 1
            name  = 'STOCHASTIC_TEST';
            id    = 'STOCHASTIC_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Stochastic test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'Stochastic';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'stochastic',currency,value_base, ...
                        asset_class);      
      end 
      % method display properties
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);
         fprintf('stochastic_riskfactor: %s\n',b.stochastic_riskfactor);
         fprintf('stochastic_curve: %s\n',b.stochastic_curve);
         fprintf('stochastic_rf_type: %s\n',b.stochastic_rf_type);
         if ( strcmpi(b.stochastic_rf_type,'t'))
                fprintf('t_degree_freedom: %d\n',b.t_degree_freedom); 
         end
      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'stochastic') )
            error('Stochastic sub_type must be stochastic: %s',sub_type)
         end
         obj.sub_type = sub_type;
      end % set.sub_type
    
   end % end static methods
   
end 

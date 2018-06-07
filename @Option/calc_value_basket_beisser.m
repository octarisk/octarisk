function obj = calc_value_basket_beisser(option,valuation_date,value_type,sigma_bar,basket_dict)
% Calculate Basket volatility assuming Beisser model for European Options (modify strike and volatility)
% according to the Paper "Pricing of arithmetic basket options by conditioning" by
% Deelstra et al., Insurance: Mathematics and Economics 34 (2004) 55–77
% Formulas taken from equation 35 and 36
    
    obj = option;
    if ( nargin < 5)
        error('Error: No  Volatility or basket dictionary set.');
    end
    % check for European Option
    if ~(strcmpi(option.option_type,'European'))
        error('Error: option.calc_value_basket_beisser method only applicable for European Plain Vanilla Options.');
    end
    
    % get input values from dictionary
    Kbar = basket_dict.strike;
    rf = basket_dict.rf_rate;
    TF = basket_dict.timefactor;
    S = basket_dict.underlying_values;
    w = basket_dict.underlying_weights;
    % calculate Beisser basket option price
    theo_value = option_basket_beisser(option.call_flag,S,w,Kbar,sigma_bar,rf,TF);
      
    % store theo_value vector in appropriate class property   
    if ( strcmpi(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);  
    elseif ( strcmpi(value_type,'base'))
        obj = obj.set('value_base',theo_value);  
    else  
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
    
end

%####################################   Helper Function   ######################
function theo_value = option_basket_beisser(call_flag,S,w,K,sigma,rf,TF)
    % calculate Beisser basket option price
    d1 = (log(S ./ K) + ( rf + 0.5 .*sigma .^2) .* TF) ./ ( sigma .* sqrt(TF) );
    d2 = d1 - sigma .* sqrt(TF);
    % calculate call price
    theo_value = sum( w .* ( S .* normcdf(d1) - exp(-rf .* TF) .* K .* normcdf(d2) ),2);
    if ( call_flag == false)
        % Put-Call-Parity
        theo_value = theo_value - sum(w .* S - K .* exp(-rf * TF),2);
    end
    
end

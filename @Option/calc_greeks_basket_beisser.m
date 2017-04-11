function obj = calc_greeks_basket_beisser(option,valuation_date,value_type,sigma_bar,basket_dict)
% Calculate Basket volatility assuming Beisser model for European Options (modify strike and volatility)
% according to the Paper "Pricing of arithmetic basket options by conditioning" b
% Deelstra et al., Insurance: Mathematics and Economics 34 (2004) 55–77

	
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
	basket_value = sum(w.*S,2);
	% calculate Beisser basket option price
	theo_value = option_basket_beisser(option.call_flag,S,w,Kbar,sigma_bar,rf,TF);
	tmp_multiplier = 1.0;
	if ( TF < 0 )
        theo_value  = 0.0;
        theo_delta  = 0.0;
        theo_gamma  = 0.0;
        theo_vega   = 0.0;
        theo_theta  = 0.0;
        theo_rho    = 0.0;
        theo_omega  = 0.0; 
        tmp_multiplier = 0.0;
    else
		% calculating effective greeks -> imply from derivatives
		theo_value_base	= option_basket_beisser(option.call_flag,S,w,Kbar,sigma_bar,rf,TF);
		
		undvalue_down	= option_basket_beisser(option.call_flag,S - 1,w,Kbar,sigma_bar,rf,TF);
		undvalue_up	    = option_basket_beisser(option.call_flag,S + 1,w,Kbar,sigma_bar,rf,TF);
		
		rfrate_down     = option_basket_beisser(option.call_flag,S,w,Kbar,sigma_bar,rf - 0.01,TF);
		rfrate_up	    = option_basket_beisser(option.call_flag,S,w,Kbar,sigma_bar,rf + 0.01,TF);
		
		vola_down	    = option_basket_beisser(option.call_flag,S,w,Kbar,sigma_bar - 0.01,rf,TF);         
		vola_up	        = option_basket_beisser(option.call_flag,S,w,Kbar,sigma_bar + 0.01,rf,TF);
		
		time_down	    = option_basket_beisser(option.call_flag,S,w,Kbar,sigma_bar,rf,TF - 1/365);
		time_up	        = option_basket_beisser(option.call_flag,S,w,Kbar,sigma_bar,rf,TF + 1/365);
		
		theo_delta  = (undvalue_up - undvalue_down) / 2;
		theo_gamma  = (undvalue_up + undvalue_down - 2 * theo_value_base);
		theo_vega   = (vola_up - vola_down) / 2;
		theo_theta  = -(time_up - time_down) / 2;
		theo_rho    = -(rfrate_up - rfrate_down) / 2;
		theo_omega  = theo_delta .* basket_value ./ theo_value_base;
	end
	
    % store theo_value vector in appropriate class property   
    if ( strcmpi(value_type,'stress'))
        %obj = obj.set('value_stress',theo_value);  
    elseif ( strcmpi(value_type,'base'))
        obj = obj.set('theo_delta',theo_delta .* tmp_multiplier);
        obj = obj.set('theo_gamma',theo_gamma .* tmp_multiplier);
        obj = obj.set('theo_vega',theo_vega .* tmp_multiplier);
        obj = obj.set('theo_theta',theo_theta .* tmp_multiplier);
        obj = obj.set('theo_rho',theo_rho .* tmp_multiplier);
        obj = obj.set('theo_omega',theo_omega .* tmp_multiplier);       
    end
   
    
end

%####################################   Helper Function   ######################
function theo_value = option_basket_beisser(call_flag,S,w,K,sigma,rf,TF)
	% Formulas taken from equation 35 and 36
	% calculate Beisser basket option price
	d1 = (log(S ./ K) + ( rf + 0.5 .*sigma .^2) .* TF) ./ ( sigma .* sqrt(TF) );
	d2 = d1 - sigma .* sqrt(TF);

	if ( call_flag)
		theo_value = sum( w .* ( S .* normcdf(d1) - exp(-rf .* TF) .* K .* normcdf(d2) ),2);
	else
		% Put-Call-Parity
		theo_value = Callprice_min - (sum(w.*S,2) - option.strike .* exp(-rf * TF));
    end
	
end



function obj = calc_sensitivities (forward,valuation_date,discount_curve_object,underlying_object,und_curve_object)
% calculate sensitivities of forwards and futures by numerical approximation
  obj = forward;
   if ( nargin < 3)
        error('Error: No  discount curve set. Aborting.');
   end

   % value type is base for all sensitivity calculations
   value_type = 'base';

    if ( nargin < 4 )
        error('No underlying_object set for value_type not being base.');
    end
    if (ischar(valuation_date))
        valuation_date = datenum(valuation_date,1);
    end
    % Get input variables
    tmp_dtm                  = (datenum(obj.maturity_date,1) - valuation_date); 
   
    % default values
    theo_value  		= 0.0;
	theo_delta  		= 0.0;
	theo_gamma  		= 0.0;
	theo_vega   		= 0.0;
	theo_theta  		= 0.0;
	theo_rho    		= 0.0;
	theo_domestic_rho 	= 0.0;
	theo_foreign_rho 	= 0.0;
	tmp_multiplier = obj.multiplier; 
		
    if ( tmp_dtm > 0 )
         % calculate sensitivities according to pricing formula
		% ====================    Bond / EQ Forward and Futures   =========================
		if ( sum(strcmpi(obj.sub_type,{'BondFuture','EquityFuture','Equity','EQFWD'})) > 0 )
			% get base values:
			theo_value_base = pricing_forward(valuation_date,value_type,obj, ...
										discount_curve_object, underlying_object);

			% shock underlying value up and down by 1%:
			underlying_object_tmp = underlying_object.set('value_base', ...
									underlying_object.get('value_base') .* 0.99);
            undvalue_down	= pricing_forward(valuation_date,value_type,obj, ...
					discount_curve_object, underlying_object_tmp);
			
			underlying_object_tmp = underlying_object.set('value_base', ...
									underlying_object.get('value_base') .* 1.01);			
            undvalue_up	    = pricing_forward(valuation_date,value_type,obj, ...
					discount_curve_object, underlying_object_tmp);
			
			% shock domestic curve values up and down by 1bp:
			domestic_curve  = discount_curve_object.set('rates_base', ...
								discount_curve_object.get('rates_base') - 0.0001);	
            rfrate_down     = pricing_forward(valuation_date,value_type,obj, ...
					domestic_curve, underlying_object);
			
			domestic_curve	= discount_curve_object.set('rates_base', ...
								discount_curve_object.get('rates_base') + 0.0001);	
            rfrate_up	    = pricing_forward(valuation_date,value_type,obj, ...
					domestic_curve, underlying_object);

			% shock maturity date forward and back by 1 day:
			obj_tmp = obj.set('maturity_date', ...
								datestr(datenum(obj.get('maturity_date')) - 1));	
            time_down	    = pricing_forward(valuation_date,value_type,obj_tmp, ...
					discount_curve_object, underlying_object);
			
			obj_tmp = obj.set('maturity_date', ...
								datestr(datenum(obj.get('maturity_date')) + 1));
            time_up	        = pricing_forward(valuation_date,value_type,obj_tmp, ...
					discount_curve_object, underlying_object);
					
            % calculate sensitivities
			theo_delta  = (undvalue_up - undvalue_down) ...
							/ (0.02 * underlying_object.get('value_base'));
			theo_gamma  = (undvalue_up + undvalue_down - 2 * theo_value_base) ...
							/ (0.02 * underlying_object.get('value_base')).^2;
			theo_vega   = 0.0;	% Eq/Bond Forwards have to volatility dependence
			theo_theta  = -(time_up - time_down) / 2;
			theo_rho    = (rfrate_up - rfrate_down) / 0.02;
			theo_domestic_rho = 0.0;
			theo_foreign_rho = 0.0;
			
		% ===================    FX and Bond Forward    ========================
		elseif ( sum(strcmpi(obj.sub_type,{'FX','Bond','BONDFWD'})) > 0 )
			if nargin < 4
				error('No foreign discount curve object set for FX forward.');
			end
					
			% get shocked base values:
            theo_value_base	= pricing_forward(valuation_date,value_type,obj, ...
					discount_curve_object, underlying_object, und_curve_object);
			
			% shock underlying value up and down by 1%:
			underlying_object_tmp = underlying_object.set('value_base', ...
									underlying_object.get('value_base') .* 0.99);
            undvalue_down	= pricing_forward(valuation_date,value_type,obj, ...
					discount_curve_object, underlying_object_tmp, und_curve_object);
			
			underlying_object_tmp = underlying_object.set('value_base', ...
									underlying_object.get('value_base') .* 1.01);			
            undvalue_up	    = pricing_forward(valuation_date,value_type,obj, ...
					discount_curve_object, underlying_object_tmp, und_curve_object);
			
			% shock domestic curve values up and down by 1bp:
			domestic_curve  = discount_curve_object.set('rates_base', ...
								discount_curve_object.get('rates_base') - 0.0001);	
            rfrate_down     = pricing_forward(valuation_date,value_type,obj, ...
					domestic_curve, underlying_object, und_curve_object);
			
			domestic_curve	= discount_curve_object.set('rates_base', ...
								discount_curve_object.get('rates_base') + 0.0001);	
            rfrate_up	    = pricing_forward(valuation_date,value_type,obj, ...
					domestic_curve, underlying_object, und_curve_object);
			
			% shock foreign curve values up and down by 1bp:
			foreign_curve  = und_curve_object.set('rates_base', ...
								und_curve_object.get('rates_base') - 0.0001);	
			rfrate_down_for = pricing_forward(valuation_date,value_type,obj, ...
					discount_curve_object, underlying_object, foreign_curve);
			
			foreign_curve  = und_curve_object.set('rates_base', ...
								und_curve_object.get('rates_base') + 0.0001);			
            rfrate_up_for	= pricing_forward(valuation_date,value_type,obj, ...
					discount_curve_object, underlying_object, foreign_curve);
			
			% shock maturity date forward and back by 1 day:
			obj_tmp = obj.set('maturity_date', ...
								datestr(datenum(obj.get('maturity_date')) - 1));	
            time_down	    = pricing_forward(valuation_date,value_type,obj_tmp, ...
					discount_curve_object, underlying_object, und_curve_object);
			
			obj_tmp = obj.set('maturity_date', ...
								datestr(datenum(obj.get('maturity_date')) + 1));
            time_up	        = pricing_forward(valuation_date,value_type,obj_tmp, ...
					discount_curve_object, underlying_object, und_curve_object);
					
            % calculate sensitivities
			theo_delta  = (undvalue_up - undvalue_down) ...
							/ (0.02 * underlying_object.get('value_base'));
			theo_gamma  = (undvalue_up + undvalue_down - 2 * theo_value_base) ...
							/ (0.02 * underlying_object.get('value_base')).^2;
			theo_vega   = 0.0;	% FX Forwards have to volatility dependence
			theo_theta  = -(time_up - time_down) / 2;
			theo_rho    = 0.0;  % FX Forwards have domestic and foreign rho
			theo_domestic_rho = (rfrate_up - rfrate_down) / 0.02;
			theo_foreign_rho = (rfrate_up_for - rfrate_down_for) / 0.02;
			       
		end
        
    end   % close loop if tmp_dtm > 0

    % store sensitivities
	obj = obj.set('theo_delta',theo_delta .* tmp_multiplier);
	obj = obj.set('theo_gamma',theo_gamma .* tmp_multiplier);
	obj = obj.set('theo_vega',theo_vega .* tmp_multiplier);
	obj = obj.set('theo_theta',theo_theta .* tmp_multiplier);
	obj = obj.set('theo_rho',theo_rho .* tmp_multiplier);
	obj = obj.set('theo_domestic_rho',theo_domestic_rho .* tmp_multiplier);
	obj = obj.set('theo_foreign_rho',theo_foreign_rho .* tmp_multiplier);
   
end



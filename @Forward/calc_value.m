function obj = calc_value (forward,valuation_date,value_type,discount_curve_object,underlying_object,und_curve_object,fx)
  obj = forward;
   if ( nargin < 4)
        error('Error: No  discount curve set. Aborting.');
   end
   if ( nargin == 2)
        error('No value_type set. [stress,1d,10d,...]');
   end
   % get underlying price vector according to value_type
   value_type = lower(value_type);

    if ( nargin < 5 )
        error('No underlying_object set for value_type not being base.');
    end
    
    if ( ~strcmpi(forward.currency,underlying_object.currency) && nargin < 7)
        error('Currency of forward and underlying are not equal. FX object required.');
    elseif ( ~strcmpi(forward.currency,underlying_object.currency) && nargin == 7 ) 
        if ( ~isobject(fx) && ~isstruct(fx))
            error('Forward: Provided FX variable is neither object nor struct.\n');
        end
    else
        fx = [];
    end
    
    if (ischar(valuation_date))
        valuation_date = datenum(valuation_date,1);
    end
    % calculate value according to pricing formula
    if ( sum(strcmpi(obj.sub_type,{'BondFuture','EquityFuture'})) > 0 )
        [theo_value theo_price] = pricing_forward(valuation_date,value_type,obj, ...
                                    discount_curve_object, underlying_object,[],fx);
        % if flag for calculation of net basis is true, payoff equals net basis
        % and payoff is zero by definition (only in base case)
        if (obj.calc_price_from_netbasis == 0 && strcmpi(value_type,'base'))
            obj = obj.set('net_basis',theo_value);
            theo_value = zeros(rows(theo_price),1);   % per definition
        end
    elseif ( sum(strcmpi(obj.sub_type,{'Equity','EQFWD'})) > 0 )
        [theo_value theo_price] = pricing_forward(valuation_date,value_type,obj, ...
                                    discount_curve_object, underlying_object,[],fx);
    elseif ( sum(strcmpi(obj.sub_type,{'FX'})) > 0 )
        if nargin < 5
            error('No foreign discount curve object set for FX forward.');
        end
        [theo_value theo_price] = pricing_forward(valuation_date,value_type,obj, ...
                discount_curve_object, underlying_object, und_curve_object,fx);
    elseif ( sum(strcmpi(obj.sub_type,{'Bond','BONDFWD'})) > 0 )
        if nargin < 5
            error('No underlying discount curve object set for Bond forward.');
        end
        [theo_value theo_price] = pricing_forward(valuation_date,value_type,obj, ...
                discount_curve_object, underlying_object, und_curve_object,fx);
    end
    
    theo_value  = theo_value .* obj.multiplier;
    theo_price  = theo_price .* obj.multiplier;
    % store theo_value vector in appropriate class property
    if ( regexp(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(value_type,'base'))
        obj = obj.set('underlying_price_base',underlying_object.getValue('base'));
        obj = obj.set('value_base',theo_value(1));
        obj = obj.set('theo_price',theo_price);
    else
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
    
    % set exposure
    if ( strcmpi(obj.exposure_type,'exposure_from_price'))
        if ( regexp(value_type,'stress'))
            obj = obj.set('exposure_stress',theo_price);
        elseif ( strcmp(value_type,'base'))
            obj = obj.set('exposure_base',theo_price(1));
        else
            obj = obj.set('exposure_mc',theo_price);
        end
        
    elseif ( strcmpi(obj.exposure_type,'exposure_from_value'))
        if ( regexp(value_type,'stress'))
            obj = obj.set('exposure_stress',theo_value);
        elseif ( strcmp(value_type,'base'))
            obj = obj.set('exposure_base',theo_value(1));
        else
            obj = obj.set('exposure_mc',theo_value);
        end
        
    elseif ( strcmpi(obj.exposure_type,'delta_x_underlyingvalue'))
        val = underlying_object.getValue(value_type) .* obj.theo_delta;
        if ( regexp(value_type,'stress'))
            obj = obj.set('exposure_stress',val);
        elseif ( strcmp(value_type,'base'))
            obj = obj.set('exposure_base',val);
        else
            obj = obj.set('exposure_mc',val);
        end    
    end
   
end



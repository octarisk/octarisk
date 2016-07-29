function obj = calc_value (forward,valuation_date,value_type,discount_curve_object,underlying_object,foreign_curve_object)
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
 
    % calculate value according to pricing formula
    if ( sum(strcmpi(obj.sub_type,{'Equity','EQFWD','Bond'})) > 0 )
        [theo_value theo_price] = pricing_forward(valuation_date,value_type,obj, ...
                                    discount_curve_object, underlying_object);
    elseif ( sum(strcmpi(obj.sub_type,{'FX'})) > 0 )
        if nargin < 5
            error('No foreign discount curve object set for FX forward.');
        end
        [theo_value theo_price] = pricing_forward(valuation_date,value_type,obj, ...
                discount_curve_object, underlying_object, foreign_curve_object);
    end
    
    theo_value  = theo_value .* obj.multiplier;
    theo_price  = theo_price .* obj.multiplier;
    % store theo_value vector in appropriate class property
    if ( regexp(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(value_type,'base'))
        obj = obj.set('value_base',theo_value(1));
    else
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
   
end



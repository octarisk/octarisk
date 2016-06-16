function obj = calc_value (forward,value_type,discount_curve_object,underlying_object)
  obj = forward;
   if ( nargin < 3)
        error('Error: No  discount curve set. Aborting.');
   end
   if ( nargin == 1)
        error('No value_type set. [stress,1d,10d,...]');
   end
   % get underlying price vector according to value_type
   value_type = lower(value_type);
  % if ( strcmp(value_type,'base'))
   %    tmp_underlying_price = underlying_object.getValue(value_type);;
  %else
        if ( nargin < 4 )
            error('No underlying_object set for value_type not being base.');
        else
            if ( strfind(underlying_object.get('id'),'RF_') )   % underlying instrument is a risk factor
                tmp_underlying_sensitivity = obj.get('underlying_sensitivity'); 
                tmp_underlying_delta = underlying_object.getValue(value_type);
                tmp_underlying_price = Riskfactor.get_abs_values(underlying_object.model, tmp_underlying_delta, obj.underlying_price_base, tmp_underlying_sensitivity);
            else    % underlying is a index
                tmp_underlying_price = underlying_object.getValue(value_type);
            end
        end
  % end   
    % Get Discount Curve nodes and rate
        discount_nodes  = discount_curve_object.get('nodes');
        discount_rates  = discount_curve_object.getValue(value_type);
        
    % Get interpolation method and other curve related attributes
        interp_discount = discount_curve_object.get('method_interpolation');
        curve_dcc       = discount_curve_object.get('day_count_convention');
        curve_basis     = discount_curve_object.get('basis');
        curve_comp_type = discount_curve_object.get('compounding_type');
        curve_comp_freq = discount_curve_object.get('compounding_freq');
        
    % calculate value according to pricing formula
    [theo_value theo_price] = pricing_forward_oop(obj,discount_nodes,discount_rates, ...
                    tmp_underlying_price,curve_comp_type,curve_basis, ...
                    curve_comp_freq);
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



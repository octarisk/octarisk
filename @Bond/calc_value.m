function obj = calc_value(bond,valuation_date,discount_curve,spread_curve,value_type)
  obj = bond;
   if ( nargin < 3)
        error('Error: No  discount curve set. Aborting.');
   end
   if ( nargin < 5)
        error('No value_type set. [stress,1d,10d,...]');
   end

    % Get reference curve nodes and rate
        tmp_nodes    = discount_curve.get('nodes');
        tmp_rates    = discount_curve.getValue(value_type);
        spread_nodes = spread_curve.get('nodes');
        spread_rates = spread_curve.getValue(value_type);
    
    % Get interpolation method
        tmp_interp_discount = discount_curve.get('method_interpolation');
        tmp_interp_spread = spread_curve.get('method_interpolation');
        
    % Get cf values and dates
    tmp_cashflow_dates  = obj.get('cf_dates');
    tmp_cashflow_values = obj.getCF(value_type);
    if ( columns(tmp_cashflow_values) == 0 || rows(tmp_cashflow_values) == 0 )
        error('No cash flow values set. CF rollout done?');    
    end
    % calculate value according to pricing formula
    [theo_value MacDur] = pricing_npv(valuation_date,tmp_cashflow_dates, tmp_cashflow_values,bond.soy,tmp_nodes,tmp_rates,spread_nodes,spread_rates,bond.basis,bond.compounding_type,bond.compounding_freq,tmp_interp_discount,tmp_interp_spread);
    % store theo_value vector in appropriate class property
    if ~isreal(theo_value)
        obj.id
        theo_value(1:min(length(theo_value),100))     
        error('theo_value of bond is not real ')
    end
    if ( regexp(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(value_type,'base'))
        obj = obj.set('value_base',theo_value(1));
        obj.mac_duration = MacDur(1);
        obj.mod_duration = (MacDur(1) ./ (1 + obj.coupon_rate ./ obj.compounding_freq)) ./100;
    else
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
   
end



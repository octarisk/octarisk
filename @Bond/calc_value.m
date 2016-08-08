function obj = calc_value(bond,valuation_date,discount_curve,value_type)
  obj = bond;
   if ( nargin < 3)
        error('Error: No  discount curve set. Aborting.');
   end
   if ( nargin < 4)
        error('No value_type set. [stress,1d,10d,...]');
   end

    % Get reference curve nodes and rate
        tmp_nodes    = discount_curve.get('nodes');
        tmp_rates    = discount_curve.getValue(value_type);
    
    % Get interpolation method and other curve related attributes
        tmp_interp_discount = discount_curve.get('method_interpolation');
        tmp_curve_dcc       = discount_curve.get('day_count_convention');
        tmp_curve_basis     = discount_curve.get('basis');
        tmp_curve_comp_type = discount_curve.get('compounding_type');
        tmp_curve_comp_freq = discount_curve.get('compounding_freq');
        
    % Get cf values and dates
    tmp_cashflow_dates  = obj.get('cf_dates');
    tmp_cashflow_values = obj.getCF(value_type);
    
    % Get bond related basis and conventions
    basis       = bond.get('basis');
    comp_type   = bond.get('compounding_type');
    comp_freq   = bond.get('compounding_freq');
    
    if ( columns(tmp_cashflow_values) == 0 || rows(tmp_cashflow_values) == 0 )
        error('No cash flow values set. CF rollout done?');    
    end
    % calculate value according to pricing formula
    [theo_value MacDur Convex] = pricing_npv(valuation_date, tmp_cashflow_dates, ...
                                    tmp_cashflow_values, bond.soy, ...
                                    tmp_nodes, tmp_rates, basis, comp_type, ...
                                    comp_freq, tmp_interp_discount, ...
                                    tmp_curve_comp_type, tmp_curve_basis, ...
                                    tmp_curve_comp_freq);
                                    
    % store theo_value vector in appropriate class property
    if ( regexp(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(value_type,'base'))
        obj = obj.set('value_base',theo_value(1));
        obj.mac_duration = MacDur(1);
        obj.dollar_duration = MacDur(1) * theo_value(1);
        % calculating modified (adjusted) duration depending on compounding freq
        if ( strcmpi(comp_type,'disc'))
            obj.coupon_rate
            obj.compounding_freq
            obj.mod_duration = obj.dollar_duration ./ (1 + obj.coupon_rate  ...
                                          ./ obj.compounding_freq) ./ 100;
        else    % in case of simple and cont compounding
            obj.mod_duration = MacDur(1) ./ 100;
        end

        obj.convexity = Convex;
        obj.dollar_convexity = Convex * theo_value;

        % calculate and set effective duration based on 100bp down / upshift:
        theo_value_100bpdown = pricing_npv(valuation_date, tmp_cashflow_dates, ...
                                    tmp_cashflow_values, bond.soy - bond.ir_shock, ...
                                    tmp_nodes, tmp_rates, basis, comp_type, ...
                                    comp_freq, tmp_interp_discount, ...
                                    tmp_curve_comp_type, tmp_curve_basis, ...
                                    tmp_curve_comp_freq);
        theo_value_100bpup = pricing_npv(valuation_date, tmp_cashflow_dates, ...
                                    tmp_cashflow_values, bond.soy + bond.ir_shock, ...
                                    tmp_nodes, tmp_rates, basis, comp_type, ...
                                    comp_freq, tmp_interp_discount, ...
                                    tmp_curve_comp_type, tmp_curve_basis, ...
                                    tmp_curve_comp_freq);
        eff_duration = ( theo_value_100bpdown - theo_value_100bpup ) ...
                        / ( 2 * theo_value * bond.ir_shock );
        obj.eff_duration = eff_duration;  
        
        % calculate and set effective convexity based on 100bp down / upshift:
        eff_convexity = ( theo_value_100bpdown + theo_value_100bpup - 2 * theo_value ) ...
                        / ( theo_value * 0.0001  );
        obj.eff_convexity = eff_convexity;  
        
        % calculate and set DV01 duration based on 1bp down / upshift:
        theo_value_1bpdown = pricing_npv(valuation_date, tmp_cashflow_dates, ...
                                    tmp_cashflow_values, bond.soy - 0.0001, ...
                                    tmp_nodes, tmp_rates, basis, comp_type, ...
                                    comp_freq, tmp_interp_discount, ...
                                    tmp_curve_comp_type, tmp_curve_basis, ...
                                    tmp_curve_comp_freq);
        theo_value_1bpup = pricing_npv(valuation_date, tmp_cashflow_dates, ...
                                    tmp_cashflow_values, bond.soy + 0.0001, ...
                                    tmp_nodes, tmp_rates, basis, comp_type, ...
                                    comp_freq, tmp_interp_discount, ...
                                    tmp_curve_comp_type, tmp_curve_basis, ...
                                    tmp_curve_comp_freq);
        dv01 = 0.5 * abs(theo_value_1bpdown - theo_value_1bpup);
        obj.dv01 = dv01;  
    else
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
   
end



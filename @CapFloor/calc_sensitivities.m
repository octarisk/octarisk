function obj = calc_sensitivities(capfloor,valuation_date,value_type, reference_curve, vola_surface, vola_rf, discount_curve)
obj = capfloor;
if ( nargin < 7)
    error('Error: No reference curve, discount curve, vola surface or vola risk factor set. Aborting.');
end

if ischar(valuation_date)
      valuation_date = datenum(valuation_date);
end
  
% a) get object attributes
    obj = obj.rollout(valuation_date,'base',reference_curve,vola_surface,vola_rf);
    obj = obj.calc_value(valuation_date,'base',reference_curve);
    theo_value      = obj.getValue('base');
    basis_obj       = obj.get('basis');
    comp_type_obj   = obj.get('compounding_type');
    comp_freq_obj   = obj.get('compounding_freq');
    
% b) Get curve specific attributes
    % Get reference curve attributes
    nodes_ref          = reference_curve.get('nodes');
    rates_ref          = reference_curve.getValue('base');
    floor_ref          = reference_curve.get('floor');
    cap_ref            = reference_curve.get('cap');
    % get discount curve attributes
    nodes_discount     = discount_curve.get('nodes');
    rates_discount     = discount_curve.getValue('base');
    interp_discount    = discount_curve.get('method_interpolation');
    basis_discount     = discount_curve.get('basis');
    comp_type_discount = discount_curve.get('compounding_type');
    comp_freq_discount = discount_curve.get('compounding_freq');    
        
% c) Calculate instrument values under shifted input data
    % downshock
        rates_ref_sensi  = rates_ref .- obj.ir_shock;
        if ( isnumeric(floor_ref) )
            rates_ref_sensi = max(rates_ref_sensi,floor_ref);
        end
        if ( isnumeric(cap_ref) )
            rates_ref_sensi = min(rates_ref_sensirates_ref,cap_ref);
        end
        % set adjusted curve rates in reference curve
        reference_curve = reference_curve.set('rates_base',rates_ref_sensi);
        [ret_dates ret_values ] = rollout_structured_cashflows(valuation_date, ...
                             'base', obj, reference_curve, vola_surface, vola_rf);

        theo_value_ir_down = pricing_npv(valuation_date, ret_dates, ...
                                    ret_values, obj.soy - obj.ir_shock, ...
                                    nodes_discount, rates_discount, basis_obj, ...
                                    comp_type_obj, comp_freq_obj, interp_discount, ...
                                    comp_type_discount, basis_discount, ...
                                    comp_freq_discount);
    % upshock
        rates_ref_sensi  = rates_ref .+ obj.ir_shock;
        if ( isnumeric(floor_ref) )
            rates_ref_sensi = max(rates_ref_sensi,floor_ref);
        end
        if ( isnumeric(cap_ref) )
            rates_ref_sensi = min(rates_ref_sensirates_ref,cap_ref);
        end
        % set adjusted curve rates in reference curve
        reference_curve = reference_curve.set('rates_base',rates_ref_sensi);
        [ret_dates ret_values ] = rollout_structured_cashflows(valuation_date, ...
                             'base', obj, reference_curve, vola_surface, vola_rf);

        theo_value_ir_up = pricing_npv(valuation_date, ret_dates, ...
                                    ret_values, obj.soy + obj.ir_shock, ...
                                    nodes_discount, rates_discount, basis_obj, ...
                                    comp_type_obj, comp_freq_obj, interp_discount, ...
                                    comp_type_discount, basis_discount, ...
                                    comp_freq_discount);
% d) calculate and set sensitivities    
    % effective duration
        eff_duration = ( theo_value_ir_down - theo_value_ir_up ) ...
                        / ( 2 * theo_value * obj.ir_shock );
        obj.eff_duration = eff_duration;  
    
    % effective convexity
        eff_convexity = ( theo_value_ir_down + theo_value_ir_up - 2 * theo_value ) ...
                        / ( theo_value * obj.ir_shock^2  );
        obj.eff_convexity = eff_convexity;  
        
        
end



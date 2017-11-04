function obj = calc_sensitivities(capfloor,valuation_date,value_type, reference_curve, vola_surface, discount_curve)
obj = capfloor;
if ( nargin < 6)
    error('Error: No reference curve, discount curve, vola surface or vola risk factor set. Aborting.');
end

if ischar(valuation_date)
      valuation_date = datenum(valuation_date,1);
end
  
% a) get object attributes
    obj = obj.rollout(valuation_date,'base',reference_curve,vola_surface);
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
    % IR shock
        % stack rates_ref curves
		% adjust rates_discount for shocks
		%	1. row: base value
		%	2. row:	-obj.ir_shock
		%	3. row:	+obj.ir_shock
		rates_ref_sensi = [rates_ref; ...
					rates_ref - obj.ir_shock; ...
					rates_ref + obj.ir_shock];
		rates_disc_sensis = [rates_discount; ...
					rates_discount - obj.ir_shock; ...
					rates_discount + obj.ir_shock];
	% set floor and cap
        if ( isnumeric(floor_ref) )
            rates_ref_sensi = max(rates_ref_sensi,floor_ref);
        end
        if ( isnumeric(cap_ref) )
            rates_ref_sensi = min(rates_ref_sensirates_ref,cap_ref);
        end
    % set adjusted curve rates in reference curve
		reference_curve_shock = reference_curve;
        reference_curve_shock = reference_curve_shock.set('rates_base',rates_ref_sensi);
        [ret_dates ret_values ] = rollout_structured_cashflows(valuation_date, ...
                             'base', obj, reference_curve_shock, vola_surface);

        value_vec = pricing_npv(valuation_date, ret_dates, ...
                                    ret_values, obj.soy, ...
                                    nodes_discount, rates_disc_sensis, basis_obj, ...
                                    comp_type_obj, comp_freq_obj, interp_discount, ...
                                    comp_type_discount, basis_discount, ...
                                    comp_freq_discount);
									
		theo_value				= value_vec(1);
		theo_value_ir_down		= value_vec(2);
		theo_value_ir_up		= value_vec(3);
									
	% Vola downshock (applied to spread)
        vola_spread  = obj.vola_spread - obj.vola_shock;

        % set adjusted volatilities 
        obj_shock = obj.set('vola_spread',vola_spread);
        [ret_dates ret_values ] = rollout_structured_cashflows(valuation_date, ...
                             'base', obj_shock, reference_curve, vola_surface);

        theo_value_vola_down = pricing_npv(valuation_date, ret_dates, ...
                                    ret_values, obj_shock.soy, ...
                                    nodes_discount, rates_discount, basis_obj, ...
                                    comp_type_obj, comp_freq_obj, interp_discount, ...
                                    comp_type_discount, basis_discount, ...
                                    comp_freq_discount);
	% Vola upshock (applied to spread)
        vola_spread  = obj.vola_spread + obj.vola_shock;

        % set adjusted volatilities 
        obj_shock = obj.set('vola_spread',vola_spread);
        [ret_dates ret_values ] = rollout_structured_cashflows(valuation_date, ...
                             'base', obj_shock, reference_curve, vola_surface);

        theo_value_vola_up = pricing_npv(valuation_date, ret_dates, ...
                                    ret_values, obj_shock.soy, ...
                                    nodes_discount, rates_discount, basis_obj, ...
                                    comp_type_obj, comp_freq_obj, interp_discount, ...
                                    comp_type_discount, basis_discount, ...
                                    comp_freq_discount);
									
    % Time upshock 
        % set adjusted maturity
        obj_shock = obj.set('maturity_date',datestr(datenum(obj.maturity_date) + 1));
        [ret_dates ret_values ] = rollout_structured_cashflows(valuation_date, ...
                             'base', obj_shock, reference_curve, vola_surface);

        theo_value_time_up = pricing_npv(valuation_date, ret_dates, ...
                                    ret_values, obj_shock.soy, ...
                                    nodes_discount, rates_discount, basis_obj, ...
                                    comp_type_obj, comp_freq_obj, interp_discount, ...
                                    comp_type_discount, basis_discount, ...
                                    comp_freq_discount);									
% d) calculate and set sensitivities    
    % effective duration
        obj.eff_duration = ( theo_value_ir_down - theo_value_ir_up ) ...
                        / ( 2 * theo_value * obj.ir_shock ); 
    
    % effective convexity
        obj.eff_convexity = ( theo_value_ir_down + theo_value_ir_up - 2 * theo_value ) ...
                        / ( theo_value * obj.ir_shock^2  );
		
    % effective vega
        obj.vega = ( theo_value_vola_up - theo_value_vola_down ) ...
                        / ( 2 * theo_value * obj.vola_shock );
						
    % effective theta
	    obj.theta = theo_value_time_up - theo_value;
        
end



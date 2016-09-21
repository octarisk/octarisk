function obj = calc_sensitivities (bond, valuation_date, discount_curve, reference_curve)
obj = bond;

if ischar(valuation_date)
    valuation_date = datenum(valuation_date);
end

% A) get bond related attributes
% Get base cf values and dates
cashflow_dates  = bond.get('cf_dates');
cashflow_values = bond.getCF('base');
if ( columns(cashflow_values) == 0 || rows(cashflow_values) == 0 )
    error('No cash flow values set. CF rollout done?');    
end

% Get bond related basis and conventions
    basis_bond       = bond.get('basis');
    comp_type_bond   = bond.get('compounding_type');
    comp_freq_bond   = bond.get('compounding_freq');

% get discount curve attributes
    nodes_discount    = discount_curve.get('nodes');
    rates_discount    = discount_curve.getValue('base');
    interp_discount = discount_curve.get('method_interpolation');
    basis_discount     = discount_curve.get('basis');
    comp_type_discount = discount_curve.get('compounding_type');
    comp_freq_discount = discount_curve.get('compounding_freq');
 
% B) Calculate analytic sensitivities where no new CF rollout is required     
    [theo_value MacDur Convex MonDur] = pricing_npv(valuation_date, cashflow_dates, ...
                                cashflow_values, bond.soy, ...
                                nodes_discount, rates_discount, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount);
    obj.mac_duration = MacDur(1);
    obj.dollar_duration = MonDur(1);
    % calculating modified (adjusted) duration depending on compounding freq
    if ( regexpi(comp_type_bond,'disc'))
        obj.mod_duration = (MacDur(1) ./ (1 + obj.coupon_rate  ...
                                      ./ obj.compounding_freq));
    elseif ( regexpi(comp_type_bond,'cont')) 
        obj.mod_duration = MacDur(1);
    else    % in case of simple compounding
        obj.mod_duration = MonDur(1) / theo_value;
    end

    obj.convexity = Convex;
    obj.dollar_convexity = Convex * theo_value(1);
    
% C.1) Effective Dur/Convex: CF rollout required special case FRN or SWAP_FLOAT
if ( strcmp(bond.sub_type,'FRN') || strcmp(bond.sub_type,'SWAP_FLOAT'))
    if ( nargin < 4 )
        error ('rollout for sub_type FRN or SWAP_FLOAT: expecting reference curve object');
    end
       
    % C.1.a) Get reference curve specific attributes

    % Get reference curve nodes and rate
        nodes_ref    = reference_curve.get('nodes');
        rates_ref    = reference_curve.getValue('base');
        floor_ref    = reference_curve.get('floor');
        cap_ref      = reference_curve.get('cap');
        
    % C.1.b) Calculate sensitivities
    % calculate and set effective duration based on specified down / upshift:
    % downshock
        rates_ref_sensi  = rates_ref .- bond.ir_shock;
        if ( isnumeric(floor_ref) )
            rates_ref_sensi = max(rates_ref_sensi,floor_ref);
        end
        if ( isnumeric(cap_ref) )
            rates_ref_sensi = min(rates_ref_sensirates_ref,cap_ref);
        end
        % set adjusted curve rates in reference curve
        reference_curve = reference_curve.set('rates_base',rates_ref_sensi);
        [ret_dates ret_values] = rollout_structured_cashflows(valuation_date, ...
                                                    'base',obj,reference_curve);

        theo_value_100bpdown = pricing_npv(valuation_date, ret_dates, ...
                                    ret_values, bond.soy - bond.ir_shock, ...
                                    nodes_discount, rates_discount, basis_bond, ...
                                    comp_type_bond, comp_freq_bond, interp_discount, ...
                                    comp_type_discount, basis_discount, ...
                                    comp_freq_discount);
    % upshock
        rates_ref_sensi  = rates_ref .+ bond.ir_shock;
        if ( isnumeric(floor_ref) )
            rates_ref_sensi = max(rates_ref_sensi,floor_ref);
        end
        if ( isnumeric(cap_ref) )
            rates_ref_sensi = min(rates_ref_sensirates_ref,cap_ref);
        end
        % set adjusted curve rates in reference curve
        reference_curve = reference_curve.set('rates_base',rates_ref_sensi);
        [ret_dates ret_values] = rollout_structured_cashflows(valuation_date, ...
                                                    'base',obj,reference_curve);

        theo_value_100bpup = pricing_npv(valuation_date, ret_dates, ...
                                    ret_values, bond.soy + bond.ir_shock, ...
                                    nodes_discount, rates_discount, basis_bond, ...
                                    comp_type_bond, comp_freq_bond, interp_discount, ...
                                    comp_type_discount, basis_discount, ...
                                    comp_freq_discount);
    % calculate effective duration
        eff_duration = ( theo_value_100bpdown - theo_value_100bpup ) ...
                        / ( 2 * theo_value * bond.ir_shock );
        obj.eff_duration = eff_duration;  
    
    % calculate and set effective convexity based on 100bp down / upshift:
        eff_convexity = ( theo_value_100bpdown + theo_value_100bpup - 2 * theo_value ) ...
                        / ( theo_value * 0.0001  );
        obj.eff_convexity = eff_convexity;  
    
    % calculate and set DV01 duration based on 1bp down / upshift:
    % downshock
        % applying floor and cap to curves
        rates_ref_sensi  = rates_ref .- 0.0001;
        if ( isnumeric(floor_ref) )
            rates_ref_sensi = max(rates_ref_sensi,floor_ref);
        end
        if ( isnumeric(cap_ref) )
            rates_ref_sensi = min(rates_ref_sensirates_ref,cap_ref);
        end
        % set adjusted curve rates in reference curve
        reference_curve = reference_curve.set('rates_base',rates_ref_sensi);
        [ret_dates ret_values] = rollout_structured_cashflows(valuation_date, ...
                                                    'base',obj,reference_curve);
        
        theo_value_1bpdown = pricing_npv(valuation_date, ret_dates, ...
                                    ret_values, bond.soy - 0.0001, ...
                                    nodes_discount, rates_discount, basis_bond, ...
                                    comp_type_bond, comp_freq_bond, interp_discount, ...
                                    comp_type_discount, basis_discount, ...
                                    comp_freq_discount);
    % upshock
        % applying floor and cap to curves
        rates_ref_sensi  = rates_ref .+ 0.0001;
        if ( isnumeric(floor_ref) )
            rates_ref_sensi = max(rates_ref_sensi,floor_ref);
        end
        if ( isnumeric(cap_ref) )
            rates_ref_sensi = min(rates_ref_sensirates_ref,cap_ref);
        end
        % set adjusted curve rates in reference curve
        reference_curve = reference_curve.set('rates_base',rates_ref_sensi);
        [ret_dates ret_values] = rollout_structured_cashflows(valuation_date, ...
                                                    'base',obj,reference_curve);
                                                    
        theo_value_1bpup = pricing_npv(valuation_date, ret_dates, ...
                                    ret_values, bond.soy + 0.0001, ...
                                    nodes_discount, rates_discount, basis_bond, ...
                                    comp_type_bond, comp_freq_bond, interp_discount, ...
                                    comp_type_discount, basis_discount, ...
                                    comp_freq_discount);
    % calculate dv01 and pv01 based on 1bp down/upshock
        dv01 = 0.5 * abs(theo_value_1bpdown - theo_value_1bpup);
        obj.dv01 = dv01;
        % calculating pv01 using upshock only
        pv01 = theo_value_1bpup - theo_value;
        obj.pv01 = pv01;          
    
    % calculate spread duration (without CF rollout): shock discount curve only
    theo_value_100bpdown = pricing_npv(valuation_date, cashflow_dates, ...
                                cashflow_values, bond.soy - bond.ir_shock, ...
                                nodes_discount, rates_discount, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount);
    theo_value_100bpup = pricing_npv(valuation_date, cashflow_dates, ...
                                cashflow_values, bond.soy + bond.ir_shock, ...
                                nodes_discount, rates_discount, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount);
    spread_duration = ( theo_value_100bpdown - theo_value_100bpup ) ...
                    / ( 2 * theo_value * bond.ir_shock );
    obj.spread_duration = spread_duration; 
    
else  % all bonds with fixed cashflows (FRB, SWAP_FIXED, CF Instruments)
  % C.2) calculate effective sensitivities for all fixed CF bonds

    % calculate and set effective duration based on specified down / upshift:
    theo_value_100bpdown = pricing_npv(valuation_date, cashflow_dates, ...
                                cashflow_values, bond.soy - bond.ir_shock, ...
                                nodes_discount, rates_discount, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount);
    theo_value_100bpup = pricing_npv(valuation_date, cashflow_dates, ...
                                cashflow_values, bond.soy + bond.ir_shock, ...
                                nodes_discount, rates_discount, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount);
    eff_duration = ( theo_value_100bpdown - theo_value_100bpup ) ...
                    / ( 2 * theo_value * bond.ir_shock );
    obj.eff_duration = eff_duration;  
    % spread duration for FRB equals effective duration:
    obj.spread_duration = eff_duration;     
    
    % calculate and set effective convexity based on 100bp down / upshift:
    eff_convexity = ( theo_value_100bpdown + theo_value_100bpup - 2 * theo_value ) ...
                    / ( theo_value * 0.0001  );
    obj.eff_convexity = eff_convexity;  
    
    % calculate and set DV01 duration based on 1bp down / upshift:
    theo_value_1bpdown = pricing_npv(valuation_date, cashflow_dates, ...
                                cashflow_values, bond.soy - 0.0001, ...
                                nodes_discount, rates_discount, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount);
    theo_value_1bpup = pricing_npv(valuation_date, cashflow_dates, ...
                                cashflow_values, bond.soy + 0.0001, ...
                                nodes_discount, rates_discount, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount);
    dv01 = 0.5 * abs(theo_value_1bpdown - theo_value_1bpup);
    obj.dv01 = dv01;
    % calculating pv01 using upshock only
    pv01 = theo_value_1bpup - theo_value;
    obj.pv01 = pv01;                            
end
   
end



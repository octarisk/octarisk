function obj = calc_sensitivities (bond, valuation_date, discount_curve, reference_curve)
obj = bond;

if ischar(valuation_date)
    valuation_date = datenum(valuation_date,1);
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
    % TODO: incorporate embedded bond option calculation 
    sensi_flag = true;
    [theo_value MacDur Convex MonDur] = pricing_npv(valuation_date, cashflow_dates, ...
                                cashflow_values, bond.soy, ...
                                nodes_discount, rates_discount, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount, sensi_flag);
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
		% stack rates_ref curves
		% adjust rates_discount for shocks
		%	1. row: base value
		%	2. row:	-bond.ir_shock
		%	3. row:	+bond.ir_shock
		%	4. row:	-0.0001 (DV01)
		%	5. row:	+0.0001 (DV01)
		rates_ref_sensi = [rates_ref; ...
					rates_ref - bond.ir_shock; ...
					rates_ref + bond.ir_shock; ...
					rates_ref - 0.0001; ...
					rates_ref + 0.0001];
		rates_disc_sensis = [rates_discount; ...
					rates_discount - bond.ir_shock; ...
					rates_discount + bond.ir_shock; ...
					rates_discount - 0.0001; ...
					rates_discount + 0.0001];
	% set floor and cap
        if ( isnumeric(floor_ref) )
            rates_ref_sensi = max(rates_ref_sensi,floor_ref);
        end
        if ( isnumeric(cap_ref) )
            rates_ref_sensi = min(rates_ref_sensirates_ref,cap_ref);
        end
    % set adjusted curve rates in reference curve
        reference_curve = reference_curve.set('rates_base',rates_ref_sensi);
    % make cash flow rollout
        [ret_dates ret_values] = rollout_structured_cashflows(valuation_date, ...
                                                    'base',obj,reference_curve);
	% valuate
        value_vec = pricing_npv(valuation_date, ret_dates, ...
                                ret_values, bond.soy, ...
                                nodes_discount, rates_disc_sensis, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount);
									
		theo_value				= value_vec(1);
		theo_value_100bpdown	= value_vec(2);
		theo_value_100bpup		= value_vec(3);
		theo_value_1bpdown		= value_vec(4);
		theo_value_1bpup		= value_vec(5);							

    % calculate effective duration
        obj.eff_duration = ( theo_value_100bpdown - theo_value_100bpup ) ...
                        / ( 2 * theo_value * bond.ir_shock ); 
    
    % calculate and set effective convexity based on 100bp down / upshift:
        obj.eff_convexity  = ( theo_value_100bpdown + theo_value_100bpup - 2 * theo_value ) ...
                        / ( theo_value * obj.ir_shock^2  );  
    
    % calculate and set DV01 duration based on 1bp down / upshift:

        obj.dv01 = 0.5 * abs(theo_value_1bpdown - theo_value_1bpup);

    % calculating pv01 using upshock only
        obj.pv01 = theo_value_1bpup - theo_value;         
    
    % calculate spread duration (without CF rollout): shock discount curve only
	rates_eff_sensis = [rates_discount; ...
					rates_discount - bond.ir_shock; ...
					rates_discount + bond.ir_shock];
    value_vec = pricing_npv(valuation_date, cashflow_dates, ...
                                cashflow_values, bond.soy, ...
                                nodes_discount, rates_eff_sensis, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount);
								
	theo_value				= value_vec(1);
	theo_value_100bpdown	= value_vec(2);
	theo_value_100bpup		= value_vec(3);
	
	% calc spread duration
    obj.spread_duration = ( theo_value_100bpdown - theo_value_100bpup ) ...
                    / ( 2 * theo_value * bond.ir_shock );
    
else  % all bonds with fixed cashflows (FRB, SWAP_FIXED, CF Instruments)
  % C.2) calculate effective sensitivities for all fixed CF bonds
	% adjust rates_discount for shocks
	%	1. row: base value
	%	2. row:	-bond.ir_shock
	%	3. row:	+bond.ir_shock
	%	4. row:	-0.0001 (DV01)
	%	5. row:	+0.0001 (DV01)
	rates_eff_sensis = [rates_discount; ...
					rates_discount - bond.ir_shock; ...
					rates_discount + bond.ir_shock; ...
					rates_discount - 0.0001; ...
					rates_discount + 0.0001];
					
    % calculate values under shock
    value_vec = pricing_npv(valuation_date, cashflow_dates, ...
                                cashflow_values, bond.soy, ...
                                nodes_discount, rates_eff_sensis, basis_bond, ...
                                comp_type_bond, comp_freq_bond, interp_discount, ...
                                comp_type_discount, basis_discount, ...
                                comp_freq_discount);
    theo_value				= value_vec(1);
	theo_value_100bpdown	= value_vec(2);
	theo_value_100bpup		= value_vec(3);
	theo_value_1bpdown		= value_vec(4);
	theo_value_1bpup		= value_vec(5);
	
    obj.eff_duration = ( theo_value_100bpdown - theo_value_100bpup ) ...
                    / ( 2 * theo_value * bond.ir_shock );
    % spread duration for FRB equals effective duration:
    obj.spread_duration = obj.eff_duration;     
    
    % calculate and set effective convexity based on 100bp down / upshift:
    obj.eff_convexity = ( theo_value_100bpdown + theo_value_100bpup - 2 * theo_value ) ...
                    / ( theo_value * bond.ir_shock^2  ); 
    
    % calculate and set DV01 duration based on 1bp down / upshift:
    obj.dv01 = 0.5 * abs(theo_value_1bpdown - theo_value_1bpup);
    % calculating pv01 using upshock only
    obj.pv01 = theo_value_1bpup - theo_value;                           
end
   
end



function obj = calc_key_rates(retail,valuation_date,discount_curve)
  obj = retail;
   if ( nargin < 3)
        error('Error: No  discount curve set. Aborting.');
   end

    if ( ischar(valuation_date))
        valuation_date = datenum(valuation_date,1);
    end
  
    % Get discount curve nodes and rate
        disc_nodes    = discount_curve.nodes;
        disc_rates    = discount_curve.getValue('base');
    
    % Get interpolation method and other curve related attributes
        interp_discount = discount_curve.method_interpolation;
        curve_basis     = discount_curve.basis;
        curve_comp_type = discount_curve.compounding_type;
        curve_comp_freq = discount_curve.compounding_freq;
        
    % Get cf values and dates
    cf_dates  = obj.get('cf_dates');
    cf_values = obj.getCF('base');
    % take future cash flow dates only
    cf_values = cf_values(cf_dates>0);
    cf_dates = cf_dates(cf_dates>0);
    
    % Get bond related basis and conventions
    basis       = obj.basis;
    comp_type   = obj.compounding_type;
    comp_freq   = obj.compounding_freq;
    
    if ( columns(cf_values) == 0 || rows(cf_values) == 0 )
        error('No cash flow values set. CF rollout done?');    
    end
    base_value  = obj.getValue('base');
    
    % get key rate input parameter
    key_terms = obj.key_term;
    key_rate_shock = obj.key_rate_shock;
    key_rate_width = obj.key_rate_width;    
    
    % new discount curve
    curve_keyrate_up = zeros(1,length(cf_dates));
    curve_keyrate_down = zeros(1,length(cf_dates));
    % vectors for key rate durations and convexities
    key_rate_eff_dur = zeros(1,length(key_terms));
    key_rate_mon_dur = zeros(1,length(key_terms));
    key_rate_eff_convex = zeros(1,length(key_terms));
    key_rate_mon_convex = zeros(1,length(key_terms));
    
    % loop through all key rates and set up a new curve for each key rate.
    % calculate up and down values for each key rate with the new curve.
    % the new curve consists of the discount curve and key rate specific shocks.
    for ii = 1:1:length(key_terms)
        key_term = key_terms(ii);
        % generate key rate shock curve
        krs_terms = [key_term - key_rate_width,key_term,key_term + key_rate_width];
        if ( ii == 1)
            krs_rates = [key_rate_shock,key_rate_shock,0];
        elseif ( ii == length(key_terms))
            krs_rates = [0,key_rate_shock,key_rate_shock];
        else
            krs_rates = [0,key_rate_shock,0];
        end
        for jj = 1:1:length(cf_dates)
            cf_date = cf_dates(jj);
            % generate new curve (sum of discount curve and key rate shock curve)
            disc_rate = interpolate_curve(disc_nodes,disc_rates, ...
                                            cf_date,interp_discount);
            krs_rate = interpolate_curve(krs_terms,krs_rates, ...
                                            cf_date,'linear');
            % convert krs_rate convention (cont, act/365) to curve conv
            key_rate_shock_conv = convert_curve_rates(valuation_date,cf_date, ...
                        krs_rate,'continuous','annual',3, ...
                        curve_comp_type,curve_comp_freq,curve_basis);   
            % store rate in new curve
            curve_keyrate_up(jj) = disc_rate + key_rate_shock_conv;
            curve_keyrate_down(jj) = disc_rate - key_rate_shock_conv;
        end
        curve_keyrates = [curve_keyrate_down ; curve_keyrate_up];
        % calc bond values under key rate up and down shocks
        c = discount_curve.set('rates_stress',curve_keyrates,'nodes',cf_dates);                           
		obj_tmp = obj.calc_value(valuation_date,'stress',c);              
		value_krs = obj_tmp.getValue('stress');                        
        value_krs_down  = value_krs(1);
        value_krs_up    = value_krs(2);
        % calc key rate duration and convexity
        key_rate_dur    = (value_krs_down - value_krs_up) ...
                                ./ (2 * key_rate_shock * base_value);
        key_rate_convex = (value_krs_down + value_krs_up - 2*base_value) ...
                                ./ (key_rate_shock^2 * base_value);
        % store in vectors
        key_rate_eff_dur(ii) = key_rate_dur;
        key_rate_mon_dur(ii) = key_rate_dur * base_value;
        key_rate_eff_convex(ii) = key_rate_convex;
        key_rate_mon_convex(ii) = key_rate_convex * base_value;
    end
    
    % store key rates
    obj = obj.set('key_rate_eff_dur',key_rate_eff_dur);   
    obj = obj.set('key_rate_mon_dur',key_rate_mon_dur);
    obj = obj.set('key_rate_eff_convex',key_rate_eff_convex);
    obj = obj.set('key_rate_mon_convex',key_rate_mon_convex);
    
end



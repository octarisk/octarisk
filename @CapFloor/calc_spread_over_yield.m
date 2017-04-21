function s = calc_vola_spread (capfloor,valuation_date,discount_curve,vola_surface)
   obj = capfloor;
    if ( nargin < 4)
        error('Error: No discount curve set. Aborting.');
    end

	
	% todo:
	% - call calibrate_capfloor_volaspread script
	% - get return code and set base value / volaspread accordingly
	
   % % Get discount curve nodes and rate
        % tmp_nodes    = discount_curve.get('nodes');
        % tmp_rates    = discount_curve.getValue('base');
    
    % % Get interpolation method and other curve related attributes
        % tmp_interp_discount = discount_curve.get('method_interpolation');
        % tmp_curve_dcc       = discount_curve.get('day_count_convention');
        % tmp_curve_basis     = discount_curve.get('basis');
        % tmp_curve_comp_type = discount_curve.get('compounding_type');
        % tmp_curve_comp_freq = discount_curve.get('compounding_freq');
        
    % % Get cf values and dates
    % tmp_cashflow_dates  = obj.get('cf_dates');
    % tmp_cashflow_values = obj.getCF('base');
    
    % % Get capfloor related basis and conventions
    % basis       = capfloor.get('basis');
    % comp_type   = capfloor.get('compounding_type');
    % comp_freq   = capfloor.get('compounding_freq');
    
    % if ( columns(tmp_cashflow_values) == 0 || rows(tmp_cashflow_values) == 0 )
        % error('No cash flow values set. CF rollout done?');    
    % end

    % calculate spread over yield (with fixed embedded option value)
    [vola_spread retcode] = calibrate_soy_sqp(valuation_date, s.cf_dates, ...
                            s.cf_values(1,:), value_dirty , ...
                            tmp_nodes, tmp_rates, basis, comp_type, comp_freq, ...
                            tmp_interp_discount, tmp_curve_comp_type, ...
                            tmp_curve_basis, tmp_curve_comp_freq);
            
     if ( retcode > 0 ) %failed calibration
        fprintf('Calibration failed for %s. Setting value_base to theo_value.\n',s.id); 
        % calculating theo_value in base case     
        theo_value = pricing_npv(valuation_date,s.cf_dates,s.cf_values(1,:), ...
                0.0,tmp_nodes,tmp_rates, basis, comp_type, ...
                comp_freq, tmp_interp_discount, tmp_curve_comp_type, ...
                tmp_curve_basis, tmp_curve_comp_freq);
        % setting value base to theo value with soy = 0
        s = s.set('value_base',theo_value(1));
        % setting calibration flag to 1 anyhow, since we do not want a failed 
        % calibration a second time...
        s.calibration_flag = 1; 
     else
        s.vola_spread = vola_spread;
        s.calibration_flag = 1;
     end
  end
   
end



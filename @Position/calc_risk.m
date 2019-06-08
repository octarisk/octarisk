% @Position/calc_risk.m: Calculate risk figures based on pre-aggregated portfolio / position values
function obj = calc_risk (obj, scen_set, instrument_struct, index_struct, para)
    if ~(nargin == 5)
        print_usage ();
    end

    if ( regexp(scen_set,'stress') && para.calc_sm_scr == true) % SII portfolio and position SCR
        % TODO
        sii_SCR = 0.0
        if ( strcmpi(obj.type,'PORTFOLIO'))
			for (ii=1:1:length(obj.positions))
				pos_obj = obj.positions(ii).object;
				pos_id = obj.positions(ii).id;
				if (isobject(pos_obj))
					% Preaggregate position object
					pos_obj_new = pos_obj.calc_risk(scen_set, instrument_struct, index_struct, para);
					
					% sum up position contributions to scr 
					
					% store position object in portfolio object
					obj.positions(ii).object = pos_obj_new;
				end
			end
		% calculate Spread risk for Positions
        elseif ( strcmpi(obj.type,'POSITION'))
			tmp_id = obj.id;
			tmp_quantity = obj.quantity;
			try 
				% calculate SCR
			catch   % if instrument not found raise warning and populate cell
				fprintf('Instrument ID %s not found for position. There was an error: %s\n',tmp_id,lasterr);
			end
		end
    elseif ( regexp(scen_set,'stress') && para.calc_sm_scr == false)
		% do nothing
		sii_SCR = 0.0;
    elseif ( strcmpi(scen_set,'base'))
        %
    else % calculate VaR risk figures
        no_scen = para.mc;
        if ( strcmpi(obj.type,'PORTFOLIO'))
          
          base_value = obj.getValue('base');
          pnl_abs = obj.getValue(scen_set) .- base_value;
          tt = 1:1:no_scen;
          confi = 1 - para.quantile;
          confi_scenario = max(round(confi * no_scen),1);
          hd_vec  = get_quantile_estimator(para.quantile_estimator, no_scen, ...
                                    tt,confi,para.quantile_bandwidth);

          
          %  i.) sort arrays
          pnl_relative = pnl_abs ./ base_value;
          [pnl_abs_sorted scen_order_shock] = sort(pnl_abs);

          % ii.) Get Value of confidence scenario
          confi_scenarionumber_shock = scen_order_shock(confi_scenario);
          mean_shock           	= mean(pnl_abs);
          std_shock           	= std(pnl_abs);
          skewness_shock        = skewness(pnl_abs);
          kurtosis_shock        = kurtosis(pnl_abs);

          % iii.) Extract confidence scenarionumbers around quantile scenario
          confi_scenarionumber_shock_p1 = scen_order_shock(confi_scenario + 1);
          confi_scenarionumber_shock_p2 = scen_order_shock(confi_scenario + 2);
          confi_scenarionumber_shock_m1 = scen_order_shock(confi_scenario - 1);
          confi_scenarionumber_shock_m2 = scen_order_shock(confi_scenario - 2);
          scenario_numbers = [confi_scenarionumber_shock_m2, ...
                            confi_scenarionumber_shock_m1, ...
                            confi_scenarionumber_shock, ...
                            confi_scenarionumber_shock_p1, ...
                            confi_scenarionumber_shock_p2];
          
          % iv.) make vector with Harrel-Davis Weights
          varhd_abs     = - dot(hd_vec,pnl_abs_sorted);
          varhd_rel     = dot(hd_vec,sort(pnl_relative));
          var_abs       = - pnl_abs_sorted(confi_scenario);
          var_diff_hd   = abs(var_abs - varhd_abs);

          % d) Calculate Expected Shortfall as average of losses in sorted profit and loss vector from [1:confi_scenario-1]:
          expshortfall_abs      = - mean(pnl_abs_sorted(1:confi_scenario-1));
          expshortfall_rel      = - expshortfall_abs ./ base_value;
         
          % sum up position standalone VaRs
          var_positionsum = 0.0;
          decomp_varhd_abs = 0.0;
          for (ii=1:1:length(obj.positions))
            pos_obj_new = obj.positions(ii).object;
            pos_id = obj.positions(ii).id;
            if (isobject(pos_obj_new))
                pos_value = pos_obj_new.getValue(scen_set);
                pos_currency = pos_obj_new.get('currency');
                % Get FX rate:
                fx_rate 		= get_FX_rate(index_struct,obj.currency, ...
														pos_currency,scen_set);
				fx_rate_base 	= get_FX_rate(index_struct,obj.currency, ...
														pos_currency,'base');
				pos_value_portcur = pos_value ./ fx_rate;
				base_value 		= pos_obj_new.getValue('base') ./ fx_rate_base;									
				pos_pnl_abs     = pos_value_portcur .- base_value;
				[pnl_abs_sorted_pos scen_order_shock_pos] = sort(pos_pnl_abs);
				pos_decomp_varhd = - dot(hd_vec,pos_pnl_abs(scen_order_shock));
				decomp_varhd_abs = decomp_varhd_abs + pos_decomp_varhd;
				pos_varhd_abs 	= - dot(hd_vec,pnl_abs_sorted_pos);
				var_positionsum = var_positionsum + pos_varhd_abs;	
				% store decomp_varhd_pos
				pos_obj_new = pos_obj_new.set('decomp_varhd',pos_decomp_varhd);
				pos_obj_new = pos_obj_new.set('varhd_abs',pos_varhd_abs);
				pos_obj_new = pos_obj_new.set('var_abs',-pnl_abs_sorted_pos(confi_scenario));
				% store position object in portfolio object
				obj.positions(ii).object = pos_obj_new;						
            end
          end
          diversification_ratio = varhd_abs / var_positionsum;    
          
          % Optional:
            %~ VAR50_shock      = pnl_abs_sorted(ceil(0.5*mc));
			%~ VAR70_shock      = pnl_abs_sorted(ceil(0.3*mc));
			%~ VAR90_shock      = pnl_abs_sorted(ceil(0.10*mc));
			%~ VAR95_shock      = pnl_abs_sorted(ceil(0.05*mc));
			%~ VAR975_shock     = pnl_abs_sorted(ceil(0.025*mc));
			%~ VAR99_shock      = pnl_abs_sorted(ceil(0.01*mc));
			%~ VAR999_shock     = pnl_abs_sorted(ceil(0.001*mc));
			%~ VAR9999_shock    = pnl_abs_sorted(ceil(0.0001*mc));
          
        elseif ( strcmpi(obj.type,'POSITION'))
          tmp_id = obj.id;
          % nothing to do here
          fprintf('Positoin >>%s<< is not a portfolio. use portfolioobject.calc_risk instead to calculate also position risk figures.\n',tmp_id);
      else
        fprintf('Unknown type >>%s<<. Neither position nor portfolio\n',any2str(obj.type));
      end
    end
    
    % store theo_value vector
    if ( regexp(scen_set,'stress'))
        % obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(scen_set,'base'))
        % obj = obj.set('value_base',theo_value(1)); 
        % if ( strcmpi(obj.type,'PORTFOLIO'))
            % obj.tpt_5 = theo_value; 
        % elseif ( strcmpi(obj.type,'POSITION'))
            % obj.tpt_22 = theo_value; 
        % end  
    else
		if ( strcmpi(obj.type,'PORTFOLIO'))
			obj = obj.set('varhd_abs',varhd_abs);
			obj = obj.set('var_confidence',para.quantile);
			obj = obj.set('var_abs',var_abs);
			obj = obj.set('varhd_rel',varhd_rel);
			obj = obj.set('expshortfall_abs',expshortfall_abs);
			obj = obj.set('scenario_numbers',scenario_numbers);
			obj = obj.set('diversification_ratio',diversification_ratio);
			obj = obj.set('var_positionsum',var_positionsum);
			obj = obj.set('scenario_numbers',scenario_numbers);
			obj = obj.set('mean_shock',mean_shock);
			obj = obj.set('std_shock',std_shock);
			obj = obj.set('skewness_shock',skewness_shock);
			obj = obj.set('kurtosis_shock',kurtosis_shock);
			obj = obj.set('expshortfall_abs',expshortfall_abs);
			obj = obj.set('expshortfall_rel',expshortfall_rel);
	    end
    end
    
end

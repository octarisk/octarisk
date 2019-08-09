% @Position/calc_risk.m: Calculate risk figures based on pre-aggregated portfolio / position values
function obj = calc_risk (obj, scen_set, instrument_struct, index_struct, para)
    if ~(nargin == 5)
        print_usage ();
    end
	position_failed_cell = obj.get('position_failed_cell');
    if ( regexp(scen_set,'stress') && para.calc_sm_scr == true) % SII portfolio and position SCR
        % TODO
        sii_SCR = 0.0
        if ( strcmpi(obj.type,'PORTFOLIO'))
			for (ii=1:1:length(obj.positions))
				pos_obj = obj.positions(ii).object;
				pos_id = obj.positions(ii).id;
				if (isobject(pos_obj))
					% Pre calc position object
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
				position_failed_cell{ length(position_failed_cell) + 1 } =  tmp_id;
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
         
          % sum up position standalone VaRs and calculate decomp VaR
          var_positionsum = 0.0;
          decomp_varhd_abs = 0.0;
          for (ii=1:1:length(obj.positions))
            try
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
            catch
				fprintf('There was an error for position id>>%s<<: %s\n',pos_id,lasterr);
				position_failed_cell{ length(position_failed_cell) + 1 } =  pos_id;
            end
          end
          
          % fill aggregation keys
          aggr_key_struct = obj.get('aggr_key_struct');
          aggr_key_struct( 1 ).key_name = {};
		  aggr_key_struct( 1 ).key_values = {};
		  aggr_key_struct( 1 ).aggregation_mat = [];
		  aggr_key_struct( 1 ).aggregation_basevalue = 0;
		  aggr_key_struct( 1 ).aggregation_decomp_shock = 0;
          aggregation_key = para.aggregation_key;
          tmp_flag1 = false;
          tmp_flag2 = false;
          for (ii=1:1:length(obj.positions))
            try
			  pos_obj_new = obj.positions(ii).object;
			  if (isobject(pos_obj_new))
				if (tmp_flag1 == true)
					tmp_flag2 = true;
				end
				tmp_flag1 = true;
				pos_id = obj.positions(ii).id;
				pos_value = pos_obj_new.getValue(scen_set);
				fund_currency = pos_obj_new.getValue('currency');
				tmp_basevalue = pos_obj_new.getValue('base');
				pos_decomp_varhd = pos_obj_new.get('decomp_varhd');
				% retrieve instrument
				tmp_instr_object = get_sub_object(instrument_struct,pos_id);
				
                % Aggregate positional data according to aggregation keys:
				for jj = 1 : 1 : length(aggregation_key)
					if ( tmp_flag1 == true & tmp_flag2 == false)   % first use of struct
						tmp_aggr_cell = {};
						aggregation_mat = [];
						aggregation_basevalue = [];
						aggregation_decomp_shock = 0;
					else            % reading from struct from previous instrument
						tmp_aggr_cell           = aggr_key_struct( jj ).key_values;
						aggregation_mat         = [aggr_key_struct( jj ).aggregation_mat];
						aggregation_basevalue   = [aggr_key_struct( jj ).aggregation_basevalue];
						aggregation_decomp_shock  = [aggr_key_struct( jj ).aggregation_decomp_shock];
					end
					if (isProp(tmp_instr_object,aggregation_key{jj}) == 1)
						tmp_aggr_key_value = getfield(tmp_instr_object,aggregation_key{jj});
						if (ischar(tmp_aggr_key_value))
							if ( strcmp(tmp_aggr_key_value,'') == 1 )
								tmp_aggr_key_value = 'Unknown';
							end
							% Assign P&L to aggregation key
							% check, wether aggr key already exist in cell array
							if (sum(strcmp(tmp_aggr_cell,tmp_aggr_key_value)) > 0)   % aggregation key found
								tmp_vec_xx = 1:1:length(tmp_aggr_cell);
								tmp_aggr_key_index = strcmp(tmp_aggr_cell,tmp_aggr_key_value)*tmp_vec_xx';
								aggregation_basevalue(:,tmp_aggr_key_index) = aggregation_basevalue(:,tmp_aggr_key_index) + tmp_basevalue;
								aggregation_mat(:,tmp_aggr_key_index) = aggregation_mat(:,tmp_aggr_key_index) + (pos_value - tmp_basevalue);
								aggregation_decomp_shock(tmp_aggr_key_index) = aggregation_decomp_shock(tmp_aggr_key_index) + pos_decomp_varhd;
							else    % aggregation key not found -> set value for first time
								tmp_aggr_cell{end+1} = tmp_aggr_key_value;
								tmp_aggr_key_index = length(tmp_aggr_cell);
								aggregation_basevalue(:,tmp_aggr_key_index) = tmp_basevalue;
								aggregation_mat(:,tmp_aggr_key_index)       = (pos_value - tmp_basevalue);
								aggregation_decomp_shock(tmp_aggr_key_index)  = pos_decomp_varhd;
							end
						else
							printf('Aggregation key not valid');
						end
					else
						printf('Aggregation key not found in instrument definition');
					end
					% storing updated values in struct
					aggr_key_struct( jj ).key_name = aggregation_key{jj};
					aggr_key_struct( jj ).key_values = tmp_aggr_cell;
					aggr_key_struct( jj ).aggregation_mat = aggregation_mat;
					aggr_key_struct( jj ).aggregation_basevalue = aggregation_basevalue;
					aggr_key_struct( jj ).aggregation_decomp_shock = aggregation_decomp_shock;
				end          
			  end
            catch
				printf('There was an error for position id>>%s<<: %s\n',pos_id,lasterr);
				position_failed_cell{ length(position_failed_cell) + 1 } =  pos_id;
            end
          end
          % Calculate standalone report:  
		  for jj = 1:1:length(aggr_key_struct)
			% load values from aggr_key_struct:
			tmp_aggr_cell               = aggr_key_struct( jj ).key_values;
			tmp_aggr_key_name           = aggr_key_struct( jj ).key_name;
			tmp_aggregation_mat         = [aggr_key_struct( jj ).aggregation_mat];
			aggregation_standalone_shock = zeros(length(length(tmp_aggr_cell)),1);
			for ii = 1 : 1 : length(tmp_aggr_cell)
				tmp_aggr_key_value          = tmp_aggr_cell{ii};
				tmp_sorted_aggr_mat         = sort(tmp_aggregation_mat(:,ii));  
				tmp_standalone_aggr_key_var = abs(dot(hd_vec,tmp_sorted_aggr_mat));
				aggregation_standalone_shock(ii)  = tmp_standalone_aggr_key_var;
			end
			aggr_key_struct( jj ).aggregation_standalone_shock = aggregation_standalone_shock;
		  end
          % store aggr_key_struct
          obj = obj.set('aggr_key_struct',aggr_key_struct);

          
          % calculate incremental and marginal VaRs
          for (ii=1:1:length(obj.positions))
            try
              pos_obj_new = obj.positions(ii).object;
              pos_id = obj.positions(ii).id;
              if (isobject(pos_obj_new))
				% TODO
              end
            catch
				printf('There was an error for position id>>%s<<: %s\n',pos_id,lasterr);
				position_failed_cell{ length(position_failed_cell) + 1 } =  pos_id;
            end
          end
          diversification_ratio = varhd_abs / var_positionsum;    
          
          % Optional:
            var50_abs      = -pnl_abs_sorted(ceil(0.5*no_scen));
			var70_abs      = -pnl_abs_sorted(ceil(0.3*no_scen));
			var90_abs      = -pnl_abs_sorted(ceil(0.10*no_scen));
			var95_abs      = -pnl_abs_sorted(ceil(0.05*no_scen));
			var975_abs     = -pnl_abs_sorted(ceil(0.025*no_scen));
			var99_abs      = -pnl_abs_sorted(ceil(0.01*no_scen));
			var999_abs     = -pnl_abs_sorted(ceil(0.001*no_scen));
			var9999_abs    = -pnl_abs_sorted(ceil(0.0001*no_scen));
          
        elseif ( strcmpi(obj.type,'POSITION'))
          tmp_id = obj.id;
          % nothing to do here
          fprintf('Position >>%s<< is not a portfolio. use portfolioobject.calc_risk instead to calculate also position risk figures.\n',tmp_id);
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
			obj = obj.set('var50_abs',var50_abs);
			obj = obj.set('var70_abs',var70_abs);
			obj = obj.set('var90_abs',var90_abs);
			obj = obj.set('var95_abs',var95_abs);
			obj = obj.set('var975_abs',var975_abs);
			obj = obj.set('var99_abs',var99_abs);
			obj = obj.set('var999_abs',var999_abs);
			obj = obj.set('var9999_abs',var9999_abs);
			% in any case store failed position cell
			obj = obj.set('position_failed_cell',position_failed_cell);
	    end
    end
    
end

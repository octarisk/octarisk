%  Main Idea: print all relevant information to a YAML format for further processing by GenAI
% This reports covers all aspects from risk run metadata, instruments, market data, portfolio and position risk measures
% movements, thresholds, allocations, rebalancing and investment rules, governance and requested outputs from GenAI.

% @Position/print_schema: Print reports for GenAI framework schema
function obj = print_schema(obj, para_object,type,scen_set,stresstest_struct = [],instrument_struct = [])
if (nargin < 4)   
	print_usage();
end
  
 % determine time step in days
if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	tmp_ts = 0;
else
    if ( strcmpi(scen_set(end),'d') )
		tmp_ts = str2num(scen_set(1:end-1));  % get timestep days
	elseif ( strcmpi(scen_set(end),'y'))
		tmp_ts = 365 * str2num(scen_set(1:end-1));  % get timestep days
	else
		error('Unknown number of days in timestep: %s\n',scen_set);
	end
end

% get report_struct from Portfolio object
repstruct = obj.report_struct;
repstruct.ts = tmp_ts;

% get path
if ( strcmpi(para_object.path_working_folder,''))
  path_main = pwd;
else
  path_main = para_object.path_working_folder;
end
path_reports = strcat(path_main,'/', ...
			para_object.folder_output,'/',para_object.folder_output_reports);

yaml_risk_schema = strcat(path_reports,'/risk_schema_port_',obj.id,'.yaml');
	    
% ---------------------------------    YAML schema    --------------------------------
if (strcmpi(type,'yaml'))  
  fprintf('Scenario set: %s Portfolio: %s Nargin: %s\n',scen_set,obj.id,any2str(nargin));
  if (  strcmpi(scen_set,'base')) % ######################### Base reporting #########################
	  fprintf('print_schema: Printing YAML report for scenario set >>%s<<\n',scen_set);
	  % todo: metadata printing + printing of thresholds and asset allocation targets etc.
	  % get path
	  if ( strcmpi(para_object.path_working_folder,''))
		path_main = pwd;
	  else
		path_main = para_object.path_working_folder;
	  end
	  path_reports = strcat(path_main,'/', ...
					para_object.folder_output,'/',para_object.folder_output_reports);
	  
	  yaml_risk_schema = strcat(path_reports,'/risk_schema_port_',obj.id,'.yaml');
	  yaml = fopen (yaml_risk_schema, 'w');
	  
	  
	  % append static risk schema with strategy and rebalancing recommendations
	  try
		path_schema_static = strcat(path_main,'/',para_object.folder_static,'/risk_schema_static_',obj.id,'.yaml');
		fprintf('static schema filepath: %s ',path_schema_static);
		static_risk_schema_str = fileread(path_schema_static);
		fprintf(yaml,'%s',static_risk_schema_str);
	  catch
	    fprintf('print_schema: risk_schema_static.yaml for portfolio %s not found in static folder: >>%s<<\n',obj.id,path_schema_static);
	  end
	  
	  fprintf(yaml, 'metadata:\n');
	  fprintf(yaml, '  valuation_date: "%s"\n',datestr(para_object.valuation_date,"YYYY-mm-DD"));
	  fprintf(yaml, '  runcode: "%s"\n',para_object.runcode);
	  fprintf(yaml, '  timestamp: "%s"\n',asctime(localtime(time)));
	  fprintf(yaml, '  octarisk_version: "%s"\n',para_object.version);
	  fprintf(yaml, '  description: "Framework for risk measures, market inputs, thresholds, constraints, allocations, and rebalancing rules"\n');
	  fprintf(yaml, '  scr_calculation_method: "%s"\n',para_object.scr_calculation_method);
	  fprintf(yaml, '  number_of_mc_scenarios: %s\n',any2str(para_object.mc));
	  fprintf(yaml, '  portfolio_id: "%s"\n',obj.id);
	  fprintf(yaml, '  portfolio_currency: "%s"\n',obj.currency);
	  fprintf(yaml, '  template_version: "v0.1"\n');
	  
    
      fprintf(yaml, '# =========================================================\n');
	  fprintf(yaml, '# Target allocations, active views, and permitted deviations:\n');
	  fprintf(yaml, '# =========================================================\n');
      fprintf(yaml, 'allocations:\n');
		if ( length(obj.aa_target_values) == length(obj.aa_target_id) && length(obj.aa_target_values) > 0 )
			fprintf(yaml,'  target_asset_allocation:\n');
			for ii=1:1:length(obj.aa_target_values)
				fprintf(yaml, '    - asset_class: "%s"\n',obj.aa_target_id{ii});
				fprintf(yaml, '      target_allocation: %2.2f\n',obj.aa_target_values(ii));
				fprintf(yaml, '      minimum_allocation: %2.2f\n',0.05);
				fprintf(yaml, '      maximum_allocation: %2.2f\n',min(obj.aa_target_values(ii)*2,0.8));
			end
		end
		if ( length(obj.equity_target_region_values) == length(obj.equity_target_region_id) && length(obj.equity_target_region_values) > 0 )
			fprintf(yaml, '  target_equity_region_allocation:\n');
			for ii=1:1:length(obj.equity_target_region_values)
				fprintf(yaml, '    - equity_region: "%s"\n',obj.equity_target_region_id{ii});
				fprintf(yaml, '      target_allocation: %2.2f\n',obj.equity_target_region_values(ii));
				fprintf(yaml, '      minimum_allocation: %2.2f\n',0.0);
				fprintf(yaml, '      maximum_allocation: %2.2f\n',min(obj.equity_target_region_values(ii)*2,0.8));
			end

			fprintf(yaml, '  permitted_deviations: "Within minimum and maximum equity region allocations if justification provided in tactical_views section."\n');
		end
		
	  fclose (yaml)
	
  % ######################### Stresstest reporting #########################	
  elseif ( strcmpi(scen_set,'stress'))
	    fprintf('print_schema: Print YAML report for scenario set >>%s<<\n',scen_set);
		yaml = fopen (yaml_risk_schema, 'a');
		if (length(stresstest_struct)>0)
			% Stress portfolio reporting
			fprintf(yaml, '# =========================================================\n');
			fprintf(yaml, '# Portfolio parametric stresstesting:\n');
			fprintf(yaml, '# =========================================================\n');
			fprintf(yaml, 'portfolio_stresstesting:\n');
			stressnames = {stresstest_struct.name};
			stressvec = obj.getValue('stress');
			for jj=2:1:length(stressnames)
				fprintf(yaml, '    - stresstest_name: "%s"\n',stressnames{jj});
				fprintf(yaml, '      profit_or_loss_%s: %2.0f\n',obj.currency,stressvec(jj) - obj.getValue('base') );
			end
		else
			fprintf('print_report: No stresstest_struct input provided.\n');
		end
		fclose (yaml)

  else % ######################### MC reporting #########################
	    
	    yaml = fopen (yaml_risk_schema, 'a');
	  
	    % get asset and liability base values
	    srri_actual = get_srri_level(abs(obj.varhd_rel),tmp_ts,para_object.quantile);
	    % sri_actual  = get_sri_level(obj.get('value_base'),obj.get('value_mc'),para_object.mc_timestep_days); % unused, gives less conservative classification
	    port_basevalue_assets = 0.0;
	    port_basevalue_liabs = 0.0;
	    port_basevalue_dtl = 0.0;
	    for (ii=1:1:length(obj.positions))
			try
			  pos_obj = obj.positions(ii).object;
			  if (isobject(pos_obj))
				if (strcmpi(pos_obj.balance_sheet_item,'Asset'))
					port_basevalue_assets = port_basevalue_assets + pos_obj.getValue('base');
				else
					port_basevalue_liabs = port_basevalue_liabs + pos_obj.getValue('base');
					if (isempty(regexpi(pos_obj.id,'DTL')) == 0)
						port_basevalue_dtl = port_basevalue_dtl + pos_obj.getValue('base');
					end
				end
			  end
			catch
				printf('Portfolio.print_report: get asset and liability base values: there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
			end
		end
		repstruct.port_basevalue_assets = port_basevalue_assets;
		repstruct.port_basevalue_liabs = port_basevalue_liabs;
		repstruct.port_basevalue_dtl = port_basevalue_dtl;
	  % ####  print portfolio risk metrics report as table
	    fprintf(yaml, '# =========================================================\n');
	    fprintf(yaml, '# Portfolio risk measures and positional risk contributions:\n');
	    fprintf(yaml, '# =========================================================\n');
		fprintf(yaml, 'portfolio_risk_metrics:\n');
		fprintf(yaml, '  portfolio_value: %9.0f\n',obj.getValue('base'));   
		fprintf(yaml, '  portfolio_currency: %s\n',obj.currency);   
		fprintf(yaml, '  time_horizon: %s days\n',any2str(tmp_ts));   
		fprintf(yaml, '  quantile: %1.3f\n',para_object.quantile);   
		fprintf(yaml, '  var_rel: %1.3f\n',-obj.varhd_rel);
		fprintf(yaml, '  var_abs_%s: %2.0f\n',obj.currency,obj.varhd_abs);
		fprintf(yaml, '  expected_shortfall_rel: %1.3f\n',-obj.expshortfall_rel);
		fprintf(yaml, '  expected_shortfall_abs_%s: %2.0f\n',obj.currency,obj.expshortfall_abs);
		vola_pa = obj.var84_abs * sqrt(250/para_object.mc_timestep_days) / obj.getValue('base');
		div_benefit = (1 - obj.diversification_ratio);
		fprintf(yaml, '  volatility_annualized: %1.3f\n',vola_pa);
		fprintf(yaml, '  diversification_benefit: %1.3f\n',div_benefit);


	    % ####  print tax details as table
		fprintf(yaml, '  tax_details:\n');
		fprintf(yaml, '    var_after_tax_%s:  %2.0f\n',obj.currency,obj.varhd_abs_at);
		fprintf(yaml, '    var_before_tax_%s:  %2.0f\n',obj.currency,obj.varhd_abs);
		fprintf(yaml, '    tax_benefit_%s:  %2.0f\n',obj.currency,obj.tax_benefit);
		fprintf(yaml, '    tax_benefit_rel:  %1.3f\n',abs(obj.tax_benefit/obj.varhd_abs));
		fprintf(yaml, '    deferred_tax_liability_%s:  %2.0f\n',obj.currency,abs(obj.dtl));

		 % ####  print utility var
		fprintf(yaml, '  utility_var\n');
		fprintf(yaml, '    explanations: "Utility VaR is calibrated to portfolio owner risk profile."\n');
		fprintf(yaml, '    var_after_tax_%s:  %2.0f\n',obj.currency,obj.varhd_abs_at);
		fprintf(yaml, '    utility_var_%s:  %2.0f\n',obj.currency,obj.utility_var);
		var_util_diff = obj.varhd_abs_at - obj.utility_var;	% difference between actual var and utility var
		fprintf(yaml, '    difference_%s:  %2.0f\n',obj.currency,var_util_diff);
		fprintf(yaml, '    thresholds:\n');
		fprintf(yaml, '      upper_limit_%s:  %2.0f\n',obj.currency,1.05*obj.utility_var);
		fprintf(yaml, '      lower_limit_%s:  %2.0f\n',obj.currency,0.95*obj.utility_var);
		fprintf(yaml, '    action_recommendation: "Actual VaR within thresholds."\n');
		%~ fprintf(yaml, '      If difference between actual VaR and utility VaR exceeds thresholds, propose rebalancing actions based on rebalancing strategy:\n');
		
		%~ if (var_util_diff > 1.05*obj.utility_var) 
			%~ diff_str = ['WARNING: Actual VaR ',any2str(round(var_util_diff)),' ',obj.currency,' larger than utility VaR. Consider de-risking.'];
		%~ elseif (var_util_diff < 0.9*obj.utility_var)
			%~ diff_str = ['Actual VaR ',any2str(round(abs(var_util_diff))),' ',obj.currency,' smaller than utility VaR. Consider re-risking.'];
		%~ else
			%~ diff_str = ['Actual VaR within thresholds.'];
		%~ end
		%~ fprintf(yaml, '        %s\n',diff_str);
		
	     % ####  print comment as table to file
	    comments_cell = obj.get('comments_items_cell');
	    fprintf(yaml, '  portfolio_assumptions:\n');
        if strcmpi(para_object.runcode,'Crisis')
            fprintf(yaml, '    crisis_scenario: EQ-40%%, Alt-70%%, IR+200bps, INFL+500bps, CS+100bps, FX-10%%, RE-50%%, COM+20%%\n');
        end
	    for kk=1:1:length(comments_cell)
			fprintf(yaml, '    assummption %s: "%s"\n',any2str(kk),comments_cell{kk});
	    end

		% ####  position level report
		fprintf(yaml, '  portfolio_positions:\n');
            if ( length(obj.positions) > 0)
                for (ii = 2:1:length(obj.positions))
                    tmp_pos_obj = obj.positions(ii).object;
					fprintf(yaml, '    - instrument_id: "%s"\n',tmp_pos_obj.id);
					fprintf(yaml, '      quantity: %2.2f\n',tmp_pos_obj.quantity);
					fprintf(yaml, '      currency: "%s"\n',obj.currency);
					fprintf(yaml, '      base_value: %2.2f\n',tmp_pos_obj.value_base);
					fprintf(yaml, '      standalone_var: %2.2f\n',tmp_pos_obj.varhd_abs);
					fprintf(yaml, '      decomposition_var: %2.2f\n',tmp_pos_obj.decomp_varhd);
					fprintf(yaml, '      incremental_var: %2.2f\n',tmp_pos_obj.incr_var);
					fprintf(yaml, '      marginal_var: %2.2f\n',tmp_pos_obj.marg_var);
                end
            end
                
            
		% #### Print Aggregation Key Asset Class report
		fprintf(yaml, '  portfolio_risk_contributions:\n');
		aggr_key_struct = obj.get('aggr_key_struct_assets');
		aa_target_id = obj.get('aa_target_id');
		aa_target_values = obj.get('aa_target_values');

		fprintf(yaml, '    - aggregation_key: "Asset Class"\n');
		fprintf(yaml, '      contributions:"\n');
		saa_deviation = 0;
		saa_riskimpact = 0;
		for jj = 1:1:length(aggr_key_struct)
		tmp_aggr_key_name  = aggr_key_struct( jj ).key_name;
		tmp_aggr_cell               = aggr_key_struct( jj ).key_values;
		tmp_aggr_key_name           = aggr_key_struct( jj ).key_name;
		tmp_aggregation_mat         = [aggr_key_struct( jj ).aggregation_mat];
		tmp_aggregation_basevalue   = [aggr_key_struct( jj ).aggregation_basevalue];
		tmp_aggregation_decomp_shock  = [aggr_key_struct( jj ).aggregation_decomp_shock];
		tmp_aggregation_standalone_shock  = [aggr_key_struct( jj ).aggregation_standalone_shock];
		  if strcmpi(tmp_aggr_key_name,'asset_class')
			devation_sum = 0;
			risk_impact_sum = 0;
			aa_cell = {};
			aa_exposure = [];
			aa_sa = [];
			aa_decomp = [];
			for ii = 1 : 1 : min(length(tmp_aggr_cell),25)
				tmp_aggr_key_value          = tmp_aggr_cell{ii};
				tmp_sorted_aggr_mat         = sort(tmp_aggregation_mat(:,ii));  
				tmp_standalone_aggr_key_var = tmp_aggregation_standalone_shock(ii);
				tmp_decomp_aggr_key_var     = tmp_aggregation_decomp_shock(ii);
				tmp_aggregation_basevalue_pos = tmp_aggregation_basevalue(ii);
				tmp_aggr_key_value = strrep(tmp_aggr_key_value,"_","");
				aa_target = 0;
				for kk=1:1:length(aa_target_id)
					if ( strcmpi(aa_target_id{kk},tmp_aggr_key_value))
						aa_target = aa_target_values(kk);
					end
				end
				aa_cell = [aa_cell,tmp_aggr_key_value];
				aa_current = tmp_aggregation_basevalue_pos/port_basevalue_assets;
				aa_exposure =[aa_exposure,aa_current];
				aa_sa =[aa_sa,tmp_standalone_aggr_key_var];
				aa_decomp =[aa_decomp,tmp_decomp_aggr_key_var];
				tmp_deviation = (aa_current - aa_target) * port_basevalue_assets;
				tmp_risk_impact = (tmp_deviation / tmp_aggregation_basevalue_pos) * tmp_decomp_aggr_key_var;
				tmp_risk_impact(isnan(tmp_risk_impact)) = 0;    % replace NaN with 0
				risk_impact_sum = risk_impact_sum + tmp_risk_impact;
				devation_sum = devation_sum + abs(tmp_deviation);
			    fprintf(yaml, '      - asset_class: "%s"\n',tmp_aggr_key_value);
				fprintf(yaml, '        base_value_%s: %2.2f\n',obj.currency,tmp_aggregation_basevalue_pos);
				fprintf(yaml, '        base_value_contribution_rel: %1.2f\n',tmp_aggregation_basevalue_pos/obj.getValue('base'));
				fprintf(yaml, '        standalone_var_%s: %2.2f\n',obj.currency,tmp_standalone_aggr_key_var);
				fprintf(yaml, '        decomposition_var_%s: %2.2f\n',obj.currency,tmp_decomp_aggr_key_var);
				fprintf(yaml, '        decomposition_var_rel: %1.2f\n',tmp_pos_obj.incr_var);
			end
			saa_deviation = devation_sum;
			saa_riskimpact = risk_impact_sum;
			repstruct.saa_deviation = devation_sum;
			repstruct.saa_riskimpact = risk_impact_sum;
			repstruct.aa_exposure = aa_exposure;
			repstruct.aa_cell = aa_cell;
			repstruct.aa_sa = aa_sa;
			repstruct.aa_decomp = aa_decomp;
		  % plot currency decomposition
		  elseif strcmpi(tmp_aggr_key_name,'currency')
			fprintf(yaml, '    - aggregation_key: "Currency"\n');
			fprintf(yaml, '      contributions:"\n');
			%fprintf(fild, '\\\hline Currency \& Basevalue \& Pct. \& Standalone VaR \& Decomp VaR\& Pct.\\\\\\hline\n');
			devation_sum = 0;
			risk_impact_sum = 0;
			for ii = 1 : 1 : min(length(tmp_aggr_cell),25)
				tmp_aggr_key_value          = tmp_aggr_cell{ii};
				tmp_sorted_aggr_mat         = sort(tmp_aggregation_mat(:,ii));  
				tmp_standalone_aggr_key_var = tmp_aggregation_standalone_shock(ii);
				tmp_decomp_aggr_key_var     = tmp_aggregation_decomp_shock(ii);
				tmp_aggregation_basevalue_pos = tmp_aggregation_basevalue(ii);
				tmp_aggr_key_value = strrep(tmp_aggr_key_value,"_","");
				% subtract DTL from EUR position
				if ( strcmpi(tmp_aggr_key_value,'EUR'))
					tmp_aggregation_basevalue_pos = tmp_aggregation_basevalue_pos + port_basevalue_dtl;
				end
				fprintf(yaml, '      - currency: "%s"\n',tmp_aggr_key_value);
				fprintf(yaml, '        base_value_%s: %2.2f\n',obj.currency,tmp_aggregation_basevalue_pos);
				fprintf(yaml, '        base_value_contribution_rel: %1.2f\n',tmp_aggregation_basevalue_pos/obj.getValue('base'));
				fprintf(yaml, '        standalone_var_%s: %2.2f\n',obj.currency,tmp_standalone_aggr_key_var);
				fprintf(yaml, '        decomposition_var_%s: %2.2f\n',obj.currency,tmp_decomp_aggr_key_var);
				fprintf(yaml, '        decomposition_var_rel: %1.2f\n',tmp_pos_obj.incr_var);
			end
			
		  end
		  fprintf('\n');
		end
	
		# historical VaR reporting
		fprintf(yaml, '  portfolio_historical_risk_metrics:\n');
	    if ( iscell(obj.hist_report_dates) && ...
					numel(obj.hist_report_dates) == length(obj.hist_base_values) && ...
					length(obj.hist_base_values) == length(obj.hist_var_abs))
				for(kk=1:1:numel(obj.hist_base_values))
					fprintf(yaml, '    - historical_reporting_date: "%s"\n',datestr(datestr(obj.hist_report_dates{kk}),"YYYY-mm-DD"));
					fprintf(yaml, '      portfolio_base_value_%s: %2.0f\n',obj.currency,obj.hist_base_values(kk));
					fprintf(yaml, '      portfolio_historical_var_%s: %2.0f\n',obj.currency,obj.hist_var_abs(kk));
					fprintf(yaml, '      portfolio_historical_var_rel: %1.3f\n',obj.hist_var_abs(kk)/obj.hist_base_values(kk));
				end
        end
            
            
	    %~ % #### Position ID Decomp LaTeX Table
	    %~ mc_var_shock = obj.varhd_abs;
	    %~ fund_currency = obj.currency; 	
		%~ pie_chart_values_pos_shock = [];
		%~ pie_chart_desc_pos_shock = {};
		%~ % loop through all positions
		%~ for (ii=1:1:length(obj.positions))
			%~ try
			  %~ pos_obj = obj.positions(ii).object;
			  %~ if (isobject(pos_obj))
					%~ pie_chart_values_pos_shock(ii) = (pos_obj.decomp_varhd) ;
					%~ pie_chart_desc_pos_shock(ii) = cellstr( strcat(pos_obj.id));
			  %~ end
			%~ catch
				%~ printf('Portfolio.print_report: decomp there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
			%~ end
		%~ end
		%~ % prepare vector for piechart:
		%~ [pie_chart_values_sorted_pos_shock sorted_numbers_pos_shock ] = sort(pie_chart_values_pos_shock,'descend');
		%~ idx = 1; 
		%~ % plot Top 25 Positions
		%~ max_positions = 28;
		%~ for ii = 1:1:min(length(pie_chart_values_pos_shock),max_positions);
			%~ pie_chart_values_plot_pos_shock(idx)     = pie_chart_values_sorted_pos_shock(ii) ;
			%~ pie_chart_desc_plot_pos_shock(idx)       = pie_chart_desc_pos_shock(sorted_numbers_pos_shock(ii));
			%~ idx = idx + 1;
		%~ end
		%~ % append remaining part
		%~ if (idx == (max_positions + 1))
			%~ pie_chart_values_plot_pos_shock(idx)     = mc_var_shock - sum(pie_chart_values_plot_pos_shock) ;
			%~ pie_chart_desc_plot_pos_shock(idx)       = "Other";
		%~ end
		%~ pie_chart_values_plot_pos_shock = pie_chart_values_plot_pos_shock ./ sum(pie_chart_values_plot_pos_shock);
  
		%~ % Plot LaTeX table Decomp ID
		%~ other_var = obj.varhd_abs;
		%~ other_value = obj.getValue('base');

		%~ fprintf(yaml, 'Decomp ID\n');
		%~ fprintf(yaml, '\\begin{tabular}{l|r|r|r|r|r}\n');
		%~ fprintf(yaml, 'Position ID \& Basevalue \& Standalone VaR \& Decomp VaR \& Pct. \& SRRI \\\\\\hline\\hline\n');
		%~ fprintf(yaml, 'Portfolio \& %9.0f %s \& %9.0f  %s\& %9.0f %s \& %3.1f\\%% \&  %s \\\\\\hline\n',obj.getValue('base'),obj.currency,obj.varhd_abs,obj.currency,obj.varhd_abs,obj.currency,100,any2str(srri_actual));
		%~ for kk=1:1:length(pie_chart_desc_plot_pos_shock)
			%~ pos_id = pie_chart_desc_plot_pos_shock{kk};
			%~ [pos_obj retcode] = get_sub_object(obj.positions,pos_id);
			%~ if ( retcode == 1)
				%~ tmp_id = strrep(pos_obj.id,"_","");
				%~ other_var = other_var - pos_obj.decomp_varhd;
				%~ other_value = other_value - pos_obj.getValue('base');
				%~ fprintf(yaml, '%s \& %9.0f %s \& %9.0f %s \& %9.0f %s\& %3.1f\\%% \& %s\\\\\n',tmp_id,pos_obj.getValue('base'),pos_obj.currency,pos_obj.varhd_abs,obj.currency,pos_obj.decomp_varhd,obj.currency,100*pos_obj.decomp_varhd/obj.varhd_abs,any2str(pos_obj.srri_pos));
			%~ end
		%~ end
		%~ fprintf(yaml, '%s \& %9.0f %s \& %s \& %9.0f %s\& %3.1f\\%% \& -- \\\\\n','Other',other_value,obj.currency,'--',other_var,obj.currency,100*other_var/obj.varhd_abs);
		%~ fprintf(yaml, '\\end{tabular}\n');
		
		%~ % #### print Incremental and Marginal VaR Report
		%~ if (para_object.calc_marg_incr_var = true)
			%~ fprintf(yaml, 'Incremental and Marginal VaR Report\n');
			%~ fprintf(yaml, '\\begin{tabular}{l|r|r|r }\n');
			%~ fprintf(yaml, 'Position ID\& Basevalue \& Incremental VaR \& Marginal VaR\\\\ \\hline\\hline\n');
		%~ for kk=1:1:length(pie_chart_desc_plot_pos_shock)
			%~ pos_id = pie_chart_desc_plot_pos_shock{kk};
			%~ [pos_obj retcode] = get_sub_object(obj.positions,pos_id);
			%~ if ( retcode == 1)
				%~ fprintf(yaml, '%s \& %9.0f %s \& %9.0f %s\& %9.0f %s\\\\\n',strrep(pos_id,"_",""),pos_obj.getValue('base'),obj.currency,pos_obj.incr_var,obj.currency,pos_obj.marg_var,obj.currency);
			  %~ end
		%~ end
			%~ fprintf(yaml, '\\end{tabular}\n');
		%~ end
	  
	   %~ % Equity Style / Region Allocation & Fixed Income Style box
	   %~ % loop through all positions
	    %~ eq_deviation = 0;
	    %~ eq_basevalue = 0;
	    %~ cash_amount = 0;
	    %~ country_cell = obj.country_id;
		%~ country_exposure = zeros(1,numel(country_cell));
		%~ liquidity_class_cell = {};
		%~ liquidity_class_exposure = [];
		%~ issuer_cell = {};
		%~ issuer_exposure = [];		
		%~ category_cell = {};
		%~ category_exposure = [];	
		%~ custodian_bank_cell = {};
		%~ custodian_bank_exposure = [];		
		%~ counterparty_cell = {};
		%~ counterparty_exposure = [];		
		%~ designated_sponsor_cell = {};
		%~ designated_sponsor_exposure = [];		
		%~ market_maker_cell = {};
		%~ market_maker_exposure = [];		
		%~ custodian_bank_underlyings_cell = {};
		%~ custodian_bank_underlyings_exposure = [];		
		%~ country_of_origin_cell = {};
		%~ country_of_origin_exposure = [];		
		%~ fund_replication_cell = {};
		%~ fund_replication_exposure = [];	
		%~ entity_cell = {};
		%~ entity_exposure = [];
		%~ entity_relationship_cell = {};
		%~ issuer = '';
	    %~ country_of_origin = '';
	    %~ custodian_bank_underlyings = '';
	    %~ designated_sponsor = '';
	    %~ custodian_bank = '';
	    %~ counterparty = '';	  
		%~ esg_score = 0;
		%~ esg_basevalue = 0;
		%~ region_sum = 0;
		%~ bond_exposure = 0;
		%~ bond_ytm = 0;
		%~ bond_ytm_duration = 0;
	    %~ if (isstruct(instrument_struct))
			%~ region_cell = obj.equity_target_region_id;
			%~ region_current_values = zeros(1,numel(region_cell));
			%~ region_current_decomp = zeros(1,numel(region_cell));
			%~ style_port_values = zeros(1,9);
			%~ port_rating = zeros(1,length(obj.rating_values));
			%~ port_duration = zeros(1,length(obj.duration_values));
			%~ for (ii=1:1:length(obj.positions))
				%~ try
				  %~ pos_obj = obj.positions(ii).object;
				  %~ if (isobject(pos_obj))
				   %~ pos_id = pos_obj.id;
				   %~ instr_obj = get_sub_object(instrument_struct,pos_id);
				   %~ if (instr_obj.isProp('asset_class'))
					  %~ if (strcmpi(instr_obj.get('asset_class'),'Equity'))
						%~ region_cell_pos  = instr_obj.region_id;
						%~ if (abs(sum(instr_obj.region_values) - 1) > 0.01)
							%~ fprintf('WARNING: Position.print_report: >>%s<< has region allocation not equal to 1\n',instr_obj.id);
						%~ end
						%~ region_values_abs  = instr_obj.region_values .* pos_obj.getValue('base');
						%~ region_decomp_abs  = instr_obj.region_values .* pos_obj.decomp_varhd;
                        
						%~ for kk=1:1:length(region_cell)
							%~ tmp_region = region_cell{kk};
							%~ for jj=1:1:length(region_cell_pos)
								%~ if ( strcmpi(tmp_region,region_cell_pos{jj}))
									%~ region_current_values(kk) = region_current_values(kk) + region_values_abs(jj);
									%~ region_current_decomp(kk) = region_current_decomp(kk) + region_decomp_abs(jj);
								%~ end
							%~ end
						%~ end
					  %~ end
					  %~ % save portfolio equity style box
					  %~ if (strcmpi(instr_obj.get('asset_class'),'Equity'))
						%~ style_cell_pos  = instr_obj.style_id;
						%~ style_pos_values = instr_obj.style_values .* pos_obj.getValue('base');
						%~ style_port_values = style_port_values + style_pos_values;
					  %~ end
					  %~ % save portfolio rating / duration box
					  %~ if (strcmpi(pos_obj.balance_sheet_item,'Asset'))
						  %~ if (strcmpi(instr_obj.type,'Debt'))
								%~ if ( instr_obj.duration < 3 )
									%~ port_duration(1) = port_duration(1) + pos_obj.getValue('base');
								%~ elseif ( instr_obj.duration >= 3 && instr_obj.duration < 7  )
									%~ port_duration(2) = port_duration(2) + pos_obj.getValue('base');
								%~ elseif ( instr_obj.duration >= 7 )
									%~ port_duration(3) = port_duration(3) + pos_obj.getValue('base');
								%~ end
						  %~ else 
							%~ if ( instr_obj.isProp('eff_duration'))
								%~ if ( instr_obj.eff_duration < 3 )
									%~ port_duration(1) = port_duration(1) + pos_obj.getValue('base');
								%~ elseif ( instr_obj.eff_duration >= 3 && instr_obj.eff_duration < 7  )
									%~ port_duration(2) = port_duration(2) + pos_obj.getValue('base');
								%~ elseif ( instr_obj.eff_duration >= 7 )
									%~ port_duration(3) = port_duration(3) + pos_obj.getValue('base');
								%~ end
							%~ end
						  %~ end
						  %~ % get rating
						  %~ if ( sum(instr_obj.rating_values) > 0)
							%~ port_rating = port_rating + instr_obj.rating_values .* pos_obj.getValue('base');
						  %~ end
					  %~ end %end balance_sheet_item Asset Loop
					  
					  %~ % get yield to maturity
					  %~ if (strcmpi(instr_obj.get('type'),'Bond')) 
						%~ if ( instr_obj.isProp('ytm') && strcmpi(pos_obj.balance_sheet_item,'Asset'))
							%~ bond_exposure = bond_exposure + pos_obj.getValue('base');
							%~ bond_ytm = bond_ytm + instr_obj.get('ytm') * pos_obj.getValue('base');
							%~ bond_ytm_duration = bond_ytm_duration  + instr_obj.eff_duration * pos_obj.getValue('base');
							%~ instr_obj.id
							%~ instr_obj.get('ytm') 
							%~ instr_obj.eff_duration
						%~ end
					  %~ end

					  %~ % get rating
					  %~ if ( sum(instr_obj.rating_values) > 0)
						%~ port_rating = port_rating + instr_obj.rating_values .* pos_obj.getValue('base');
					  %~ end
					  
					  
					  %~ % required for KPI reporting
					  %~ if (strcmpi(instr_obj.get('asset_class'),'Cash'))
					      %~ cash_amount = cash_amount + pos_obj.getValue('base');	
					  %~ end
					  %~ % get country
					  %~ if ( sum(instr_obj.country_values) > 0)
					    %~ for kk=1:1:length(instr_obj.country_id)
							%~ tmp_ctry = instr_obj.country_id{kk};
							%~ if (strcmpi(country_cell,tmp_ctry) == false)
								%~ country_cell = [country_cell,tmp_ctry];
								%~ country_exposure = [country_exposure,0];
							%~ end
							%~ idx_vec = linspace(1,numel(country_cell),numel(country_cell))'; % find index of country
							%~ idx = strcmpi(country_cell,tmp_ctry) * idx_vec;
							%~ country_exposure(idx) = country_exposure(idx) + ...
										%~ instr_obj.country_values(kk) * pos_obj.getValue('base');
					    %~ end
					  %~ end
					  %~ % get ESG score
					  %~ if (~isempty(instr_obj.esg_score))
						  %~ if (instr_obj.esg_score > 0)
							  %~ esg_score = esg_score + (instr_obj.esg_score * ...
									%~ abs(pos_obj.getValue('base')));
							  %~ esg_basevalue = esg_basevalue + abs(pos_obj.getValue('base'));
						  %~ end
					  %~ end
					  %~ % get further instrument properties and load into cell exposure vector
					  %~ issuer
					  %~ if ( ~isnull(instr_obj.issuer))
							%~ [issuer_cell, issuer_exposure] = add_to_exposure_cell(...
									%~ issuer_cell, issuer_exposure, ...
									%~ instr_obj.issuer,pos_obj.getValue('base'));
							%~ [entity_cell, entity_exposure] = add_to_exposure_cell(...
									%~ entity_cell, entity_exposure, ...
									%~ instr_obj.issuer,pos_obj.getValue('base'));
					  %~ end
					  
					  %~ category
					  %~ if ( ~isnull(pos_obj.category))
							%~ [category_cell, category_exposure] = add_to_exposure_cell(...
									%~ category_cell, category_exposure, ...
									%~ pos_obj.category,pos_obj.getValue('base'));
					  %~ end

					  %~ %-  liquidity class
					  %~ if (strcmpi(pos_obj.balance_sheet_item,'Asset'))
						  %~ if ( ~isnull(instr_obj.liquidity_class))
								%~ [liquidity_class_cell, liquidity_class_exposure] = add_to_exposure_cell(...
										%~ liquidity_class_cell, liquidity_class_exposure, ...
										%~ instr_obj.liquidity_class,pos_obj.getValue('base'));
						  %~ end
					  %~ end % liquidity classification for assets only
					  %~ custodian_bank
					  %~ if ( ~isnull(pos_obj.custodian_bank))
							%~ [custodian_bank_cell, custodian_bank_exposure] = add_to_exposure_cell(...
									%~ custodian_bank_cell, custodian_bank_exposure, ...
									%~ pos_obj.custodian_bank,pos_obj.getValue('base'));
							%~ [entity_cell, entity_exposure] = add_to_exposure_cell(...
									%~ entity_cell, entity_exposure, ...
									%~ pos_obj.custodian_bank,pos_obj.getValue('base'));
									
							%~ if ( ~isnull(instr_obj.issuer))
								%~ tmpstr = strcat('"',pos_obj.custodian_bank,'"->"',instr_obj.issuer,'" [colorscheme=greys9 color =9]');
								%~ if (strcmpi(entity_relationship_cell,tmpstr) == false || isempty(strcmpi(entity_relationship_cell,tmpstr)))
									%~ entity_relationship_cell = [entity_relationship_cell,tmpstr];
								%~ end
							%~ end
								
					  %~ end
					  %~ counterparty
					  %~ if ( ~isnull(instr_obj.counterparty))
							%~ [counterparty_cell, counterparty_exposure] = add_to_exposure_cell(...
									%~ counterparty_cell, counterparty_exposure, ...
									%~ instr_obj.counterparty,pos_obj.getValue('base'));
							%~ [entity_cell, entity_exposure] = add_to_exposure_cell(...
									%~ entity_cell, entity_exposure, ...
									%~ instr_obj.counterparty,pos_obj.getValue('base'));
									
							%~ if ( ~isnull(instr_obj.issuer))
								%~ tmpstr = strcat('"',instr_obj.issuer,'"->"',instr_obj.counterparty,'" [colorscheme=greys9 color =8]');
								%~ if (strcmpi(entity_relationship_cell,tmpstr) == false  || isempty(strcmpi(entity_relationship_cell,tmpstr)))
									%~ entity_relationship_cell = [entity_relationship_cell,tmpstr];
								%~ end
							%~ end		
					  %~ end
					  %~ designated_sponsor
					  %~ if ( ~isnull(instr_obj.designated_sponsor))
							%~ [designated_sponsor_cell, designated_sponsor_exposure] = add_to_exposure_cell(...
									%~ designated_sponsor_cell, designated_sponsor_exposure, ...
									%~ instr_obj.designated_sponsor,pos_obj.getValue('base'));
							%~ [entity_cell, entity_exposure] = add_to_exposure_cell(...
									%~ entity_cell, entity_exposure, ...
									%~ instr_obj.designated_sponsor,pos_obj.getValue('base'));
									
							%~ if ( ~isnull(instr_obj.issuer))
								%~ tmpstr = strcat('"',instr_obj.issuer,'"->"',instr_obj.designated_sponsor,'" [colorscheme=greys9 color =7]');
								%~ if (strcmpi(entity_relationship_cell,tmpstr) == false  || isempty(strcmpi(entity_relationship_cell,tmpstr)))
									%~ entity_relationship_cell = [entity_relationship_cell,tmpstr];
								%~ end
							%~ end			
					  %~ end
					  %~ market_maker
					  %~ if ( ~isnull(instr_obj.market_maker))
							%~ [market_maker_cell, market_maker_exposure] = add_to_exposure_cell(...
									%~ market_maker_cell, market_maker_exposure, ...
									%~ instr_obj.market_maker,pos_obj.getValue('base'));
					  %~ end
					  %~ custodian_bank_underlyings
					  %~ if ( ~isnull(instr_obj.custodian_bank_underlyings))
							%~ [custodian_bank_underlyings_cell, custodian_bank_underlyings_exposure] = add_to_exposure_cell(...
									%~ custodian_bank_underlyings_cell, custodian_bank_underlyings_exposure, ...
									%~ instr_obj.custodian_bank_underlyings,pos_obj.getValue('base'));
							%~ [entity_cell, entity_exposure] = add_to_exposure_cell(...
									%~ entity_cell, entity_exposure, ...
									%~ instr_obj.custodian_bank_underlyings,pos_obj.getValue('base'));
									
							%~ if ( ~isnull(instr_obj.issuer))
								%~ tmpstr = strcat('"',instr_obj.issuer,'"->"',instr_obj.custodian_bank_underlyings,'"  [colorscheme=greys9 color =6]');
								%~ if (strcmpi(entity_relationship_cell,tmpstr) == false  || isempty(strcmpi(entity_relationship_cell,tmpstr)))
									%~ entity_relationship_cell = [entity_relationship_cell,tmpstr];
								%~ end
							%~ end	
					  %~ end
					  %~ country_of_origin
					  %~ if ( ~isnull(instr_obj.country_of_origin))
							%~ [country_of_origin_cell, country_of_origin_exposure] = add_to_exposure_cell(...
									%~ country_of_origin_cell, country_of_origin_exposure, ...
									%~ instr_obj.country_of_origin,pos_obj.getValue('base'));
							%~ [entity_cell, entity_exposure] = add_to_exposure_cell(...
									%~ entity_cell, entity_exposure, ...
									%~ instr_obj.country_of_origin,pos_obj.getValue('base'));
									
							%~ if ( ~isnull(instr_obj.custodian_bank_underlyings))
								%~ tmpstr = strcat('"',instr_obj.custodian_bank_underlyings,'"->"',instr_obj.country_of_origin,'" [colorscheme=greys9 color =5]');
								%~ if (strcmpi(entity_relationship_cell,tmpstr) == false  || isempty(strcmpi(entity_relationship_cell,tmpstr)))
									%~ entity_relationship_cell = [entity_relationship_cell,tmpstr];
								%~ end
							%~ end	
					  %~ end
					  %~ fund_replication
					  %~ if ( ~isnull(instr_obj.fund_replication))
							%~ [fund_replication_cell, fund_replication_exposure] = add_to_exposure_cell(...
									%~ fund_replication_cell, fund_replication_exposure, ...
									%~ instr_obj.fund_replication,pos_obj.getValue('base'));
					  %~ end					  
					%~ end
				  %~ end
				%~ catch
					%~ printf('Portfolio.print_report: cell and exposure: there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
				%~ end
			%~ end
			%~ entity_cell;
			%~ entity_exposure;
			%~ entity_relationship_cell;
		
			%~ disp('======================================================')
			%~ bond_exposure
			%~ bond_ytm = bond_ytm / bond_exposure
			%~ bond_ytm_duration = bond_ytm_duration / bond_exposure
			%~ disp('======================================================')
					  
			%~ repstruct.bond_exposure = bond_exposure;
			%~ repstruct.bond_ytm = bond_ytm;
			%~ repstruct.bond_ytm_duration = bond_ytm_duration;
			%~ repstruct.issuer_cell = issuer_cell;
			%~ repstruct.issuer_exposure = issuer_exposure;	
			%~ repstruct.category_cell = category_cell;
			%~ repstruct.category_exposure = category_exposure;
			%~ repstruct.entity_cell = entity_cell;
			%~ repstruct.entity_exposure = entity_exposure;
			%~ repstruct.custodian_bank_cell = custodian_bank_cell;
			%~ repstruct.custodian_bank_exposure = custodian_bank_exposure;
			%~ repstruct.counterparty_cell = counterparty_cell;
			%~ repstruct.counterparty_exposure = counterparty_exposure;
			%~ repstruct.designated_sponsor_cell = designated_sponsor_cell;
			%~ repstruct.designated_sponsor_exposure = designated_sponsor_exposure;	
			%~ repstruct.market_maker_cell = market_maker_cell;
			%~ repstruct.market_maker_exposure	 = market_maker_exposure;
			%~ repstruct.custodian_bank_underlyings_cell = custodian_bank_underlyings_cell;
			%~ repstruct.custodian_bank_underlyings_exposure = custodian_bank_underlyings_exposure;
			%~ repstruct.country_of_origin_cell = country_of_origin_cell;
			%~ repstruct.country_of_origin_exposure = country_of_origin_exposure;
			%~ repstruct.fund_replication_cell = fund_replication_cell;
			%~ repstruct.fund_replication_exposure = fund_replication_exposure;
			%~ repstruct.liquidity_class_cell = liquidity_class_cell;
			%~ repstruct.liquidity_class_exposure = liquidity_class_exposure;
			
			% print aggregated issuer, custodian, counterparty into table
			%       Issuer:
			%~ latex_table_issuer_exposure = strcat(path_reports,'/table_pos_',obj.id,'_issuer_exposure.tex');
			%~ fiie = fopen (latex_table_issuer_exposure, 'w');
			%~ fprintf(fiie, '\\center\n');
			%~ fprintf(fiie, '\\begin{tabular}{l|r|r}\n');
			%~ fprintf(fiie, 'Issuer \& Exposure \& Pct. \\\\\\hline\\hline\n');
			%~ [tt idx_sorted] = sort(issuer_exposure,'descend');	
			%~ for (ii=1:1:length(idx_sorted))
				%~ tmp_idx = idx_sorted(ii);
				%~ fprintf(fiie, '%s \& %s %s \& %3.1f\\%% \\\\\n',issuer_cell{tmp_idx},any2str(round(issuer_exposure(tmp_idx))),obj.currency, ( 100 * issuer_exposure(tmp_idx) / port_basevalue_assets) );
			%~ end
			%~ fprintf(fiie, '\\\hline Total \& %9.0f %s \& %3.1f\\%% \\\\\\hline\n',round(sum(issuer_exposure)),obj.currency, round(100* sum(issuer_exposure) / port_basevalue_assets) );
			%~ fprintf(fiie, '\\end{tabular}\n');
			%~ fclose (fiie);
			
			%~ %       Counterparty:
			%~ latex_table_counterparty_exposure = strcat(path_reports,'/table_pos_',obj.id,'_counterparty_exposure.tex');
			%~ fiie = fopen (latex_table_counterparty_exposure, 'w');
			%~ fprintf(fiie, '\\center\n');
			%~ fprintf(fiie, '\\begin{tabular}{l|r|r}\n');
			%~ fprintf(fiie, 'Counterparty \& Net Exposure \& Pct. \\\\\\hline\\hline\n');	
			%~ [tt idx_sorted] = sort(counterparty_exposure,'descend');
			%~ counterparty_exposure_scaled = counterparty_exposure .* 0.05; %scale for derivative exposure (worst case 5%)	
			%~ for (ii=1:1:length(idx_sorted))
				%~ tmp_idx = idx_sorted(ii);
				%~ fprintf(fiie, '%s \& %s %s \& %3.1f\\%% \\\\\n',counterparty_cell{tmp_idx},any2str(round(counterparty_exposure_scaled(tmp_idx))),obj.currency, ( 100 * counterparty_exposure_scaled(tmp_idx) / port_basevalue_assets) );
			%~ end
			%~ fprintf(fiie, '\\\hline Total \& %9.0f %s \& %3.1f\\%% \\\\\\hline\n',round(sum(counterparty_exposure_scaled)),obj.currency, round(100* sum(counterparty_exposure_scaled) / port_basevalue_assets));
			%~ fprintf(fiie, '\\end{tabular}\n');
			%~ fclose (fiie);
			
			%~ %       Custodian:
			%~ latex_table_custodian_exposure = strcat(path_reports,'/table_pos_',obj.id,'_custodian_exposure.tex');
			%~ fiie = fopen (latex_table_custodian_exposure, 'w');
			%~ fprintf(fiie, '\\center\n');
			%~ fprintf(fiie, '\\begin{tabular}{l|r|r}\n');
			%~ fprintf(fiie, 'Custodian \& Exposure \& Pct. \\\\\\hline\\hline\n');
			%~ [tt idx_sorted] = sort(custodian_bank_exposure,'descend');		
			%~ for (ii=1:1:length(idx_sorted))
				%~ tmp_idx = idx_sorted(ii);
				%~ fprintf(fiie, '%s \& %s %s \& %3.1f\\%% \\\\\n',custodian_bank_cell{tmp_idx},any2str(round(custodian_bank_exposure(tmp_idx))),obj.currency, ( 100 * custodian_bank_exposure(tmp_idx) / port_basevalue_assets) );
			%~ end
			%~ fprintf(fiie, '\\\hline Total \& %9.0f %s \& %3.1f\\%% \\\\\\hline\n',round(sum(custodian_bank_exposure)),obj.currency, round(100* sum(custodian_bank_exposure) / port_basevalue_assets));
			%~ fprintf(fiie, '\\end{tabular}\n');
			%~ fclose (fiie);
			
			%~ %       Custodian Bank Underlying:
			%~ latex_table_custodian_undrl_exposure = strcat(path_reports,'/table_pos_',obj.id,'_custodian_bank_underlying_exposure.tex');
			%~ fiie = fopen (latex_table_custodian_undrl_exposure, 'w');
			%~ fprintf(fiie, '\\center\n');
			%~ fprintf(fiie, '\\begin{tabular}{l|r|r}\n');
			%~ fprintf(fiie, 'Custodian Bank Underlying \& Exposure \& Pct. \\\\\\hline\\hline\n');
			%~ [tt idx_sorted] = sort(custodian_bank_underlyings_exposure,'descend');		
			%~ for (ii=1:1:length(idx_sorted))
				%~ tmp_idx = idx_sorted(ii);
				%~ fprintf(fiie, '%s \& %s %s \& %3.1f\\%% \\\\\n',custodian_bank_underlyings_cell{tmp_idx},any2str(round(custodian_bank_underlyings_exposure(tmp_idx))),obj.currency, ( 100 * custodian_bank_underlyings_exposure(tmp_idx) / port_basevalue_assets) );
			%~ end
			%~ fprintf(fiie, '\\\hline Total \& %9.0f %s \& %3.1f\\%% \\\\\\hline\n',round(sum(custodian_bank_underlyings_exposure)),obj.currency, (100* sum(custodian_bank_underlyings_exposure) / port_basevalue_assets));
			%~ fprintf(fiie, '\\end{tabular}\n');
			%~ fclose (fiie);
			
			%       yield to maturity:
			%~ fprintf(yaml, 'yield to maturity\n');
			%~ fprintf(yaml, '\\begin{tabular}{l|r|r}\n');
			%~ fprintf(yaml, 'Bond Exp. \& Yield to Mat. \& Eff.Dur. \\\\\\hline\\hline\n');
			%~ fprintf(yaml, '%9.0f %s \& %2.2f\\%%  \& %1.2f \\\\\\hline\n',round(bond_exposure),obj.currency, 100 * bond_ytm,bond_ytm_duration);
			%~ fprintf(yaml, '\\end{tabular}\n');
			
			%~ % calculate HHI of all cells/exposures
            %~ HHI_total_sum = sum(issuer_exposure) + sum(custodian_bank_exposure) ...
                    %~ + sum(counterparty_exposure) + sum(designated_sponsor_exposure) + ...
                    %~ sum(custodian_bank_underlyings_exposure) + sum(country_of_origin_exposure);
			%~ HHI_issuer = calc_HHI(issuer_exposure);
			%~ HHI_custodian = calc_HHI(custodian_bank_exposure);
			%~ HHI_counterparty = calc_HHI(counterparty_exposure);
			%~ HHI_dessponsor = calc_HHI(designated_sponsor_exposure);
			%~ HHI_custund = calc_HHI(custodian_bank_underlyings_exposure);
			%~ HHI_coo = calc_HHI(country_of_origin_exposure);
			%~ % calculate geomean HHI of all concentration risks
			%~ exp_vec = [HHI_issuer,HHI_custodian, ...
						%~ HHI_counterparty,HHI_dessponsor,HHI_custund,HHI_coo];
			%~ if (sum(isnan(exp_vec))>0)
				%~ HHI_weighted = 0;
                %~ HHI_exp_weighted = 0;
			%~ else			
				%~ [HHI_weighted] = geomean(abs([HHI_issuer,HHI_custodian, ...
						%~ HHI_counterparty,HHI_dessponsor,HHI_custund,HHI_coo]))
                 %~ HHI_exp_weighted =   (HHI_issuer *  sum(issuer_exposure) + ...  
                        %~ HHI_custodian *  sum(custodian_bank_exposure) + ... 
                        %~ HHI_counterparty *  sum(counterparty_exposure) + ... 
                        %~ HHI_dessponsor *  sum(designated_sponsor_exposure) + ... 
                        %~ HHI_custund *  sum(custodian_bank_underlyings_exposure) + ... 
                        %~ HHI_coo *  sum(country_of_origin_exposure)) / HHI_total_sum;
			%~ end
			%~ % get ESG  score for portfolio (weighted sum of position ESG scores)
			%~ if ( abs(esg_basevalue) > 0)
				%~ esg_score = esg_score / esg_basevalue;
				%~ esg_rating = get_esg_rating(esg_score);
			%~ else
				%~ esg_score = 0;
				%~ esg_rating = 'NA';
			%~ end
			%~ repstruct.esg_score = esg_score;
			%~ repstruct.esg_rating = esg_rating;

		%~ % calculate portfolio effective duration / convexity
		    %~ port_eff_duration = 0;          
            %~ port_eff_convexity = 0;          
            %~ port_asset_duration = 0;          
            %~ port_asset_convexity = 0;          
            %~ port_liab_duration = 0;          
            %~ port_liab_convexity = 0;          
            %~ port_liabilities_basevalue = 0;          
            %~ port_assets_basevalue = 0; 
			%~ if (isstruct(stresstest_struct))
				%~ stresstest_names = {stresstest_struct.name};
				%~ idx_vec = linspace(1,length(stresstest_names),length(stresstest_names))';
				%~ idx_IRdown = strcmpi(stresstest_names,'IR-100bp') * idx_vec;
				%~ idx_IRup  = strcmpi(stresstest_names,'IR+100bp') * idx_vec;
				%~ if ( idx_IRdown == 0 || idx_IRup == 0)
					%~ fprintf('print_report: No portfolio duration calculation. Cannot find IR-100bp or IR+100bp.\n');
				%~ else
					%~ [port_eff_duration 	port_eff_convexity] = ...
							%~ calc_eff_sensitivities(obj.getValue('base'), ...
											%~ obj.getValue('stress')(idx_IRup), ...
											%~ obj.getValue('stress')(idx_IRdown));

					%~ % loop through all positions als cumulate asset / liability shock values
					%~ port_assets_basevalue = 0;
					%~ port_assets_IRup = 0;
					%~ port_assets_IRdown = 0;
					%~ port_liabilities_basevalue = 0;
					%~ port_liabilities_IRup = 0;
					%~ port_liabilities_IRdown = 0;
					
					%~ for (ii=1:1:length(obj.positions))
						%~ try
						  %~ pos_obj = obj.positions(ii).object;
						  %~ if (isobject(pos_obj))
							%~ pos_id = pos_obj.id;
							%~ if (strcmpi(pos_obj.balance_sheet_item,'Asset'))
								%~ port_assets_basevalue = port_assets_basevalue + ...
											%~ pos_obj.getValue('base');
								%~ port_assets_IRup = port_assets_IRup + ...
											%~ pos_obj.getValue('stress')(idx_IRup);
								%~ port_assets_IRdown = port_assets_IRdown + ...
											%~ pos_obj.getValue('stress')(idx_IRdown);
							%~ else
								%~ port_liabilities_basevalue = port_liabilities_basevalue + ...
											%~ pos_obj.getValue('base');
								%~ port_liabilities_IRup = port_liabilities_IRup + ...
											%~ pos_obj.getValue('stress')(idx_IRup);
								%~ port_liabilities_IRdown = port_liabilities_IRdown + ...
											%~ pos_obj.getValue('stress')(idx_IRdown);
							%~ end
						  %~ end
						%~ catch
							%~ printf('Portfolio.print_report: there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
						%~ end
					%~ end
					%~ % calculate port_eff_duration_assets and liabs
					%~ [port_asset_duration port_asset_convexity] = ...
							%~ calc_eff_sensitivities(port_assets_basevalue, ...
									%~ port_assets_IRup, port_assets_IRdown);
					
					%~ [port_liab_duration port_liab_convexity] = ...
							%~ calc_eff_sensitivities(port_liabilities_basevalue, ...
									%~ port_liabilities_IRup, port_liabilities_IRdown);
                %~ end
            %~ end   
    
			%~ repstruct.port_eff_duration = port_eff_duration;
			%~ repstruct.port_eff_convexity = port_eff_convexity;			
			%~ repstruct.port_asset_duration = port_asset_duration;
			%~ repstruct.port_asset_convexity = port_asset_convexity;
			%~ repstruct.port_liab_duration = port_liab_duration;
			%~ repstruct.port_liab_convexity = port_liab_convexity;
			%~ repstruct.port_liabilities_basevalue = port_liabilities_basevalue;
			%~ repstruct.port_assets_basevalue = port_assets_basevalue;
			
			%~ % get all risk factors where portfolio is sensitive:
			%~ rf_cell = {'RF_EQ_EU','RF_EQ_NA','RF_EQ_EM','RF_FX_EURUSD', ...
							%~ 'RF_IR_EUR_10Y','RF_INFL_EXP_EUR','RF_COM_GOLD', ...
							%~ 'RF_ALT_BTC','RF_RE_DM','RF_SPREAD_EUR_IG_5Y'};
			%~ ret_cell = get_rf_sensitivities(obj,stresstest_struct);
			%~ repstruct.rf_sensitive_cell = ret_cell;
			
			%~ % print Fixed Income style box to LaTeX Table
		%~ % calculate rating, duration style boxes 
			%~ port_rating = port_rating ./ sum(port_rating);
			%~ port_duration = port_duration ./ sum(port_duration);
			%~ obj.rating_values = port_rating;
			%~ obj.duration_values = port_duration;
			%~ repstruct.country_exposure_abs = country_exposure;
			%~ country_exposure = country_exposure ./ sum(country_exposure);
			%~ repstruct.country_exposure = country_exposure;
			%~ repstruct.country_cell = country_cell;
		%~ % print country exposure to LaTeX table
			%~ dm_string = '';
			%~ em_string = '';
			%~ dm_exp = 0;
			%~ em_exp = 0;
			%~ other_exp = 0;
			%~ max_exp_dm = 0; %max(country_exposure)	% set to 100 for drawing
			%~ max_exp_em = 0;
			%~ dm_exposure_vec = [];
			%~ em_exposure_vec = [];
			%~ dm_exposure_cell = {};
			%~ em_exposure_cell = {};
			%~ % get exposure
			%~ for kk=1:1:numel(country_cell)
				%~ tmp_ctry = country_cell{kk};
				%~ if ( strcmpi(tmp_ctry,'Other'))
					%~ other_exp = country_exposure(kk);
				%~ elseif ( strcmpi(tmp_ctry,'')) 
					%~ % do nothing
				%~ else
					%~ if (isdevelopedmarket(tmp_ctry))
						%~ dm_exp = dm_exp + country_exposure(kk);	
						%~ dm_exposure_vec = cat(2,dm_exposure_vec,country_exposure(kk));
						%~ dm_exposure_cell = [dm_exposure_cell,tmp_ctry];
						%~ if (country_exposure(kk) > max_exp_dm)
							%~ max_exp_dm = country_exposure(kk);
						%~ end					
					%~ else	% emerging market country
						%~ em_exp = em_exp + country_exposure(kk);
						%~ em_exposure_vec = cat(2,em_exposure_vec,country_exposure(kk));
						%~ em_exposure_cell = [em_exposure_cell,tmp_ctry];
						%~ if (country_exposure(kk) > max_exp_em)
							%~ max_exp_em = country_exposure(kk);
						%~ end	
					%~ end
				%~ end
			%~ end
			%~ % get string
			%~ for kk=1:1:numel(country_cell)
				%~ tmp_ctry = country_cell{kk};
				%~ if ( strcmpi(tmp_ctry,'Other')) || (strcmpi(tmp_ctry,''))
					%~ % do nothing
				%~ else
					%~ if (isdevelopedmarket(tmp_ctry))
						%~ colordepth = 25 + (75 * sqrt(country_exposure(kk) / max_exp_dm));
						%~ if isnan(colordepth)
							%~ colordepth = 25;
						%~ end
						%~ %colordepth = 100;
						%~ if ( length(dm_string) == 0)
							%~ dm_string = strcat(tmp_ctry,'/',num2str(colordepth));
						%~ else
							%~ dm_string = strcat(dm_string,',',tmp_ctry,'/',num2str(colordepth));
						%~ end
						
					%~ else	% emerging market country
						%~ colordepth = 25 + (75 * sqrt(country_exposure(kk) / max_exp_em));
						%~ if isnan(colordepth)
							%~ colordepth = 25;
						%~ end
						%~ %colordepth = 100;
						%~ if ( length(em_string) == 0)
							%~ em_string = strcat(tmp_ctry,'/',num2str(colordepth));
						%~ else
							%~ em_string = strcat(em_string,',',tmp_ctry,'/',num2str(colordepth));
						%~ end
					%~ end
				%~ end
			%~ end
			
			%~ % Print MVBS Balance Sheet
			%~ latex_table_mvbs = strcat(path_reports,'/',obj.id,'_mvbs.tex');
			%~ latex_table_reconciliation = strcat(path_reports,'/',obj.id,'_recon.csv');
			%~ [retcode repstruct] = print_table_categories(obj,repstruct, ...
								%~ latex_table_mvbs,latex_table_reconciliation);
			
			
			
			%~ % print rating / duration table
			%~ ratingtable = 100 .* port_rating;
			%~ ratingdesc = obj.rating_id;
			%~ durationdesc = obj.duration_id;
			%~ durationtable = 100 .* port_duration;
			%~ al_ratio = abs(port_basevalue_liabs)/abs(port_basevalue_assets);
			%~ if (abs(port_basevalue_liabs - obj.dtl) > 0.01)	% liability exposure available (ignoring deferred tax liability)
				%~ fprintf(yaml, 'duration table\n');
				%~ fprintf(yaml, '\\begin{tabular}{r | c | c || c}\n');
				%~ fprintf(yaml, 'Sensitivity \& Assets \& Liabilities \& Gap\\\\\\hline\\hline\n');	
				%~ fprintf(yaml, 'Effective Duration \& %3.1f \& %3.1f \& %3.1f\\\\\n',port_asset_duration,port_liab_duration,port_asset_duration-port_liab_duration*al_ratio);	
				%~ fprintf(yaml, 'Effective Convexity \& %3.1f \& %3.1f \& %3.1f\\\\\n',port_asset_convexity,port_liab_convexity,port_asset_convexity-port_liab_convexity*al_ratio);	
				%~ fprintf(yaml, '\\end{tabular}\n');
			%~ else % print only overall portfolio sensitivities (liability exposure zero)
				%~ fprintf(yaml, 'overall portfolio sensitivities (liability exposure zero)\n');
				%~ fprintf(yaml, '\\begin{tabular}{r | c }\n');
				%~ fprintf(yaml, 'Sensitivity \& Overall Portfolio \\\\\\hline\\hline\n');	
				%~ fprintf(yaml, 'Effective Duration \& %3.1f  \\\\\n',port_eff_duration);	
				%~ fprintf(yaml, 'Effective Convexity \& %3.1f \\\\\n',port_eff_convexity);	
				%~ fprintf(yaml, '\\end{tabular}\n');
			%~ end
			
			%~ fprintf(yaml, 'Rating Table\n');
			%~ fprintf(yaml, '\\begin{tabular}{r | c || r | c }\n');
			%~ fprintf(yaml, 'Asset Credit Rating \& Allocation \& Eff. Duration \& Asset Allocation \\\\\\hline\\hline\n');	
			%~ fprintf(yaml, '%s \& %3.1f\\%% \& %s \& %3.1f\\%%  \\\\\n','High (AAA-AA)',ratingtable(1),durationdesc{1},durationtable(1));	
			%~ fprintf(yaml, '%s \& %3.1f\\%% \& %s \& %3.1f\\%%  \\\\\n','Mid (A-BBB)',ratingtable(2),durationdesc{2},durationtable(2))
			%~ fprintf(yaml, '%s \& %3.1f\\%% \& %s \& %3.1f\\%%  \\\\\\hline\n','Low (BB-C)',ratingtable(3),durationdesc{3},durationtable(3))	
			%~ fprintf(yaml, 'Sum \& %3.1f\\%% \& Sum \& %3.1f\\%% \\\\\n',sum(ratingtable),sum(durationtable));	
			%~ fprintf(yaml, '\\end{tabular}\n');

			
			%~ % print Equity region allocation to LaTeX Table
			%~ fprintf(yaml, '\\center\n');
			%~ fprintf(yaml, '\\begin{tabular}{l|r|r|r|r|r}\n');
			%~ fprintf(yaml, 'Region \& Basevalue \& Target AA \& Actual AA \& Deviation \& Risk Impact\\\\\\hline\\hline\n');	
			%~ for kk=1:1:length(region_cell)
				%~ region = region_cell{kk};
				%~ region_val = region_current_values(kk);
				%~ region_decomp = region_current_decomp(kk);
				%~ region_sum = sum(region_current_values);
				%~ aa_target = obj.equity_target_region_values(kk);
				%~ aa_current = region_val ./ region_sum;
				%~ tmp_deviation = (aa_current - aa_target) * region_sum;
                
                %~ if (region_val == 0)
                    %~ tmp_risk_impact = NaN;
                %~ else
                    %~ tmp_risk_impact = (tmp_deviation / region_val) * region_decomp;
                    %~ risk_impact_sum = risk_impact_sum + tmp_risk_impact;
                %~ end
				
				%~ devation_sum = devation_sum + abs(tmp_deviation);
				%~ fprintf(yaml, '%s \& %9.0f %s \& %3.1f\\%% \& %3.1f\\%% \& %9.0f %s\& %9.0f %s\\\\\n',region,region_val,obj.currency,aa_target*100,aa_current*100,tmp_deviation,obj.currency,tmp_risk_impact,obj.currency);
			%~ end
			%~ fprintf(yaml, '\\\hline Equity \& %9.0f %s \& %3.1f\\%% \& %3.1f\\%% \& %9.0f %s\& %9.0f %s\\\\\\hline\n',region_sum,obj.currency,100,100,devation_sum,obj.currency,risk_impact_sum,obj.currency);
			%~ fprintf(yaml, '\\end{tabular}\n');

			%~ eq_deviation = devation_sum;
			%~ eq_basevalue = region_sum;
			%~ repstruct.eq_deviation = devation_sum;
			%~ repstruct.eq_basevalue = region_sum;
			%~ repstruct.eq_riskimpact = risk_impact_sum;
			%~ % print Equity style box to LaTeX Table
			%~ estab = 100 .* style_port_values / sum(region_sum);
			%~ repstruct.estab = 100 .* style_port_values / sum(region_sum);
			%~ fprintf(yaml, '\\center\n');
			%~ fprintf(yaml, '\\begin{tabular}{l|c c c|r}\n');
			%~ fprintf(yaml, 'Size/Style \& Value \& Blend \& Growth \& Sum \\\\\\hline\\hline\n');	
			%~ fprintf(yaml, 'Large Cap \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\n',estab(1),estab(2),estab(3),sum(estab(1:3)));	
			%~ fprintf(yaml, 'Mid Cap \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\n',estab(4),estab(5),estab(6),sum(estab(4:6)));	
			%~ fprintf(yaml, 'Small Cap \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\\hline\n',estab(7),estab(8),estab(9),sum(estab(7:9)));	
			%~ fprintf(yaml, 'Sum \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\n',sum([estab(1),estab(4),estab(7)]),sum([estab(2),estab(5),estab(8)]),sum([estab(3),estab(6),estab(9)]),sum(estab));	
			%~ fprintf(yaml, '\\end{tabular}\n');
		%~ end
		
		%~ % print KPI summary table
		%~ fprintf(yaml, 'KPI summary table\n');
		%~ fprintf(yaml, '\\begin{tabular}{l|c|c|c|c}\n');
		%~ fprintf(yaml, 'Category \& Measure \& Target \& Actual \& Status \\\\\\hline\\hline\n');	
		
		%~ % 1) VaR Risklevel
			%~ % a) SRRI level
			%~ if (abs(port_basevalue_liabs - port_basevalue_dtl) < 0.01)	% asset portfolio only
				%~ % Risk | SRRI level | 4 | 4 | on track v rebalancing
				%~ srri_actual = get_srri_level(abs(obj.varhd_rel),tmp_ts,para_object.quantile);
				%~ repstruct.srri_actual = srri_actual;
				%~ sr_actual = obj.solvency_ratio;
				%~ repstruct.solvency_ratio = sr_actual;
				
				%~ if ( srri_actual == obj.srri_target )
					%~ status_str = '\colorbox{octariskgreen}{on track}';
					%~ var_status = 'on track';
				%~ else
					%~ status_str = '\colorbox{octariskorange}{action required}';
					%~ var_status = 'action required';
				%~ end
				%~ fprintf(yaml, '%s \& %s \& %d \& %d \& %s \\\\\\hline\n','Risk','SRRI class',obj.srri_target,srri_actual,status_str);
				%~ repstruct.srri_target = obj.srri_target;
				%~ repstruct.var_status = var_status;	
			%~ else % asset and liability portfolio
			 %~ % b) Solvency Ratio
				%~ % Risk | Solvency Ratio | >200% | 195% | on track v rebalancing v monitoring
				%~ % get and store srri in any case
				%~ srri_actual = get_srri_level(abs(obj.varhd_rel),tmp_ts,para_object.quantile);
				%~ repstruct.srri_actual = srri_actual;
				
				%~ sr_actual = obj.solvency_ratio;
				%~ sr_limit_lower = 1.0;
				%~ sr_limit_higher = 2.0;
				%~ repstruct.solvency_ratio = sr_actual;
				%~ if ( sr_actual >= sr_limit_lower && sr_actual < sr_limit_higher )
					%~ status_str = '\colorbox{yellow}{monitor}';
				%~ elseif ( sr_actual >= 2.0 )
					%~ status_str = '\colorbox{octariskgreen}{on track}';	
					%~ var_status = 'on track';
				%~ else
					%~ status_str = '\colorbox{octariskorange}{action required}';
					%~ var_status = 'action required';
				%~ end
				%~ fprintf(yaml, '%s \& %s \& >%3.1f\\%% \& %4.1f\\%% \& %s \\\\\\hline\n','Risk','Solvency Ratio',sr_limit_higher*100,sr_actual*100,status_str);	
				%~ repstruct.srri_target = obj.srri_target;
				%~ repstruct.var_status = var_status;
			%~ end
		%~ % 2) VaR trend
			%~ % Risk | VaR trend | -> | up | on track v action required
			%~ hist_var = obj.hist_var_abs;
			%~ hist_bv = obj.hist_base_values;
			%~ hist_dates = obj.hist_report_dates;
			%~ if (length(hist_dates) > 0 && length(hist_var) > 0 && length(hist_bv) > 0)
				%~ % remove all values equal or after valuation date		
				%~ hist_var(datenum(hist_dates)>=datenum(datestr(para_object.valuation_date)))=[];
				%~ hist_bv(datenum(hist_dates)>=datenum(datestr(para_object.valuation_date)))=[];
				%~ % lastly remove from hist_dates
				%~ hist_dates(datenum(hist_dates)>=datenum(datestr(para_object.valuation_date)))=[];

				%~ if ( numel(hist_var) == numel(hist_bv) )
					%~ hist_var_rel = hist_var ./ hist_bv;
				%~ else
					%~ error('print_report: Length of historical base values and VaR does not match.\n');
				%~ end
				%~ var_rel = abs(obj.varhd_rel);
				%~ if (length(hist_var_rel) >= 1)
					%~ arrow_str = '$\rightarrow$'; % default if inside +-2% last VaR (MC error)
					%~ status_str = '\colorbox{octariskgreen}{on track}';
					%~ var_trend = 'on track';
					%~ if ( var_rel >= 1.02*hist_var_rel(end))
						%~ arrow_str = '$\nearrow$';
						%~ status_str = '\colorbox{yellow}{monitor}';
						%~ var_trend = 'monitor';
						%~ if ( var_rel > 1.02*max(hist_var_rel))
							%~ arrow_str = '$\uparrow$';
							%~ status_str = '\colorbox{octariskorange}{action required}';
							%~ var_trend = 'action required';
						%~ end
					%~ elseif ( var_rel <= 0.98*hist_var_rel(end))
						%~ arrow_str = '$\searrow$';
						%~ status_str = '\colorbox{yellow}{monitor}';
						%~ var_trend = 'monitor';
						%~ if ( var_rel < 0.98*min(hist_var_rel))
							%~ arrow_str = '$\downarrow$';
							%~ status_str = '\colorbox{octariskorange}{action required}';
							%~ var_trend = 'action required';
						%~ end
					%~ end
				%~ else
					%~ arrow_str = '$\rightarrow$';
					%~ status_str = '\colorbox{octariskgreen}{no history}';
					%~ var_trend = 'not available';
				%~ end
			%~ else % no historical values set
				%~ arrow_str = '$\rightarrow$';
				%~ status_str = '\colorbox{octariskgreen}{no history}';
				%~ var_trend = 'not available';
			%~ end
			%~ fprintf(yaml, '%s \& %s \& %s \& %s \& %s \\\\\\hline\n','Risk','VaR Trend','$\rightarrow$',arrow_str,status_str);
			%~ if numel(hist_var)>=1
				%~ repstruct.var_last = hist_var(end);
			%~ else
				%~ repstruct.var_last = 0;
			%~ end
			%~ repstruct.var_curr = obj.varhd_abs;
			%~ repstruct.var_trend = var_trend;
		%~ % 3) Strategic Asset Allocation
			%~ % SAA | Deviation  | <10% | 6% | on track v action
			%~ max_deviation = 10;
			%~ saa_deviation_rel = 100 * saa_deviation / port_basevalue_assets;
			%~ if ( saa_deviation_rel <= max_deviation )
				%~ status_str = '\colorbox{octariskgreen}{on track}';
			%~ else
				%~ status_str = '\colorbox{octariskorange}{action required}';
			%~ end
			%~ fprintf(yaml, '%s \& %s \& <%3.0f\\%% \& %3.0f\\%% \& %s \\\\\\hline\n','Allocation','Total Deviation',max_deviation,saa_deviation_rel,status_str);	
			%~ % SAA | Risk Impact | <10% | 5% | on track v action
			%~ risk_impact_abs = abs(saa_riskimpact) ;
			%~ risk_impact_max = 10;
			%~ risk_impact_rel = 100 * risk_impact_abs / obj.varhd_abs;
			%~ if ( risk_impact_rel <= risk_impact_max )
				%~ status_str = '\colorbox{octariskgreen}{on track}';
			%~ else
				%~ status_str = '\colorbox{octariskorange}{action required}';
			%~ end
			%~ fprintf(yaml, '%s \& %s \& <%3.0f\\%% \& %3.0f\\%% \& %s \\\\\\hline\n','Allocation','Risk Impact',risk_impact_max,risk_impact_rel,status_str);
			%~ % SAA | Equity Deviation | <10% | 4% | on track v action
			%~ eq_deviation_max = 10;
			%~ eq_deviation_rel = 100 * eq_deviation / eq_basevalue;
			%~ if ( eq_deviation_rel <= eq_deviation_max )
				%~ status_str = '\colorbox{octariskgreen}{on track}';
			%~ else
				%~ status_str = '\colorbox{octariskorange}{action required}';
			%~ end
			%~ fprintf(yaml, '%s \& %s \& <%3.0f\\%% \& %3.0f\\%% \& %s \\\\\\hline\n','Allocation','Equity Deviation',eq_deviation_max,eq_deviation_rel,status_str);	
		%~ % 4) Other thresholds
			%~ % SAA | Cash | >40000 EUR | XX EUR | on track v action
			%~ if ( cash_amount >= obj.min_req_cash )
				%~ status_str = '\colorbox{octariskgreen}{on track}';
			%~ else
				%~ status_str = '\colorbox{octariskorange}{action required}';
			%~ end
			%~ fprintf(yaml, '%s \& %s \& >%9.0f %s \& %9.0f %s \& %s \\\\\\hline\n','Allocation','Cash',obj.min_req_cash,obj.currency,cash_amount,obj.currency,status_str);
			%~ repstruct.alloc_cash_target = obj.min_req_cash;
			%~ repstruct.alloc_cash_actual = cash_amount;
		
		%~ % 7) Liquidity Risk
			%~ % Allocation | Liquidity | high | >50%  | on track v action HHI_risk
			%~ idx = get_idx_cell(liquidity_class_cell,'high');
			%~ liq_exp_high = liquidity_class_exposure(idx) ./ sum(liquidity_class_exposure);
			%~ liq_exp_limit = 0.5;
			%~ if ( liq_exp_high >=liq_exp_limit )
				%~ status_str = '\colorbox{octariskgreen}{on track}';
			%~ else
				%~ status_str = '\colorbox{octariskorange}{action required}';
			%~ end
			%~ fprintf(yaml, '%s \& %s \& high: >%3.0f\\%%\& high: %3.0f\\%%\& %s \\\\\\hline\n','Allocation','Liquidity',liq_exp_limit*100,liq_exp_high*100,status_str);		
		%~ % end
		%~ fprintf(yaml, '\\end{tabular}\n');
		fclose (yaml);
		
		% Call llm for providing an individual risk analysis and recommendations for further action:
		%[retcode prompt response] = call_llm_risk_analysis(obj, repstruct, path_reports);
		
  end
end

% update report_struct in object
%obj = obj.set('report_struct',repstruct);
end   

% ##############################################################################
% 			Helper Functions
%
% Return true if ISO code contained in developed market cell
function retcode = isdevelopedmarket(code)

	DM_cell = {'GB','FR','CH','DE','NL','ES', ...
	'SE','IT','DK','BE','US','JP','CA','AU', ...
	'HN','SG','NZ','HK','AT','FI','IL','PT'};

	if (sum(strcmpi(DM_cell,code)) > 0)
		retcode = true;
	else
		retcode = false;
	end
end

% append or add to cell
function [id_cell, x_cell] = add_to_exposure_cell(id_cell,x_cell,id,exposure)
	if ( ~isempty(id) && ~isnull(exposure))	
		if (strcmpi(id_cell,id) == false || isempty(strcmpi(id_cell,id)))
			id_cell = [id_cell,id];
			x_cell = [x_cell,0];
		end
		idx_vec = linspace(1,numel(id_cell),numel(id_cell))'; % find index
		idx = strcmpi(id_cell,id) * idx_vec;
		x_cell(idx) = x_cell(idx) + exposure;
	end
end

% print graphviz file for entity relationship network graph
function retval = print_graphviz(tmpfilename,entity_cell,entity_exposure,entity_relationship_cell)
	retval = 1;
	entity_exposure_scaled = entity_exposure.^2;
	entity_exposure_scaled = entity_exposure_scaled ./ sum(entity_exposure_scaled); % make sure normalized vector
	entity_exposure_scaled = entity_exposure_scaled .* 1 + 0.4;


fid = fopen (tmpfilename, 'w');

% define header
    fprintf(fid, 'digraph G {\n');
    fprintf(fid, '\tfontname = "Bitstream Vera Sans"\n');
    fprintf(fid, '\tfontsize = 5\n');
    fprintf(fid, '\tnode [\n');
    fprintf(fid, '\t\tfontname = "Bitstream Vera Sans"\n');
    fprintf(fid, '\t\tfontsize = 5\n');
    fprintf(fid, '\t\tshape = "record"\n');
    fprintf(fid, '\t]\n');
    fprintf(fid, '\tedge [\n');
    fprintf(fid, '\t\tfontname = "Bitstream Vera Sans"\n');
    fprintf(fid, '\t\tfontsize = 4\n');
    fprintf(fid, '\t\tarrowsize=0.25\n');
    %fprintf(fid, '\t\tarrowhead=none\n');
    fprintf(fid, '\t\tcolor="black"\n');
    fprintf(fid, '\t]\n');
    %fprintf(fid, '\tgraph [splines=ortho];\n');
    %fprintf(fid, '\trankdir=UD;\n');
    fprintf(fid, '\t\toverlap=scalexy;\n');
    fprintf(fid, '\t\tsplines=true;\n');
    
    fprintf(fid, '\t\ta[label = "" image="legend_arrows.png" imagescale=true fixedsize=true imagepos=mc shape="rectangle" width=1.5 height=0.5];\n');
    fprintf(fid, '\t\tr[label = "" image="legend_rating.png" imagescale=true fixedsize=true imagepos=mc shape="rectangle" width=0.166 height=1 color=white];\n');
    
% define nodes
	for kk=1:1:length(entity_cell)
		id = entity_cell{kk};
		expo = entity_exposure_scaled(kk);
		rating_color = get_entity_rating(id);
		fprintf(fid, '\t\t"%s" [label="%s" margin=0 fontcolor=black fontsize=5 width=%1.2f shape=circle style=filled fixedsize=shape colorscheme=rdylgn8 fillcolor=%d ];\n',id,id,expo,rating_color);
	end
% relationships
	for kk=1:1:length(entity_relationship_cell)
		rel = entity_relationship_cell{kk};
		fprintf(fid, '\t\t%s;\n',rel);
	end

% end and close file
fprintf(fid,'}\n');
fclose(fid);

end % end YAML schema printing

% ##############################################################################
% get rating score per entity
function rating = get_entity_rating(id)

% get credit rating (AAA-D)
credit_rating = get_credit_rating(id);
% convert to number 1-8 ( NR = 3 )
switch (credit_rating)
  case 'AAA'
    rating = 8;
  case 'AA'
    rating = 7;
  case 'A'
    rating = 6;
  case 'BBB'
    rating = 5;
  case 'BB'
    rating = 4;
  case 'B'
    rating = 3;
  case 'C'
    rating = 2;
  case 'D'
    rating = 1;
  case 'NR'
    rating = 5;              
  otherwise
    rating = 5;   
end

end

% ##############################################################################
% sort cell and vector
function [vec_plot, cell_plot] = sort_cells(vec_unsorted,cell_unsorted,max_elems = 5);

	[vec_sorted sorted_numbers ] = sort(vec_unsorted,'descend');

	% Top 5 Positions Basevalue
	idx = 1; 
	for ii = 1:1:min(numel(vec_sorted),max_elems);
		vec_plot(idx)  = vec_sorted(ii) ;
		cell_plot(idx) = cell_unsorted(sorted_numbers(ii));
		idx = idx + 1;
	end
	%append remaining part
	if (idx == (max_elems + 1))
		vec_plot(idx)    = sum(vec_unsorted) - sum(vec_plot) ;
		cell_plot(idx)   = "Other";
	end
end

% get index of certain item in cell
function idx = get_idx_cell(incell,item)
	idx_vec = [1:1:numel(incell)]';
	idx = strcmpi(incell,item) * idx_vec;
	if  ~isscalar(idx)
		idx = 0;
	end
end

% calculate effective duration and convexity
function [dur convex] = calc_eff_sensitivities(base,IRup,IRdown)
	if (isreal(base) && isreal(IRup) && isreal(IRdown) && abs(base)>0)
		dur = ( IRdown - IRup ) / ( 2 * base * 0.01 );						
		convex =(  IRdown + IRup - 2 * base ) / ( base * 0.0001);
	else
		dur = 0;
		convex = 0;
	end						
end

% get all sensitivity to risk factor categories
function [ret_cell] = get_rf_sensitivities(obj,stresstest_struct,rf_cell = {})
% todo: screen stress test names for types (e.g. EQ,IR,INFL,SPREAD etc.)
% and see whether portfolio obj has non-zero pnl --> count this rf type as
% sensitive for portfolio (to be used then for specific rf plotting)
ret_cell = {};
if isempty(rf_cell)
	rf_cell = {'RF_EQ_EU','RF_EQ_NA','RF_EQ_EM','RF_FX_EURUSD','RF_IR_EUR_10Y','RF_INFL_EXP_EUR','RF_COM_GOLD','RF_ALT_BTC','RF_RE_DM','RF_SPREAD_EUR_IG_5Y'};
end
if (isstruct(stresstest_struct))
	stresstest_names = {stresstest_struct.name};
	obj_pnl = obj.getValue('stress') - obj.getValue('base');
	for kk = 1:1:numel(rf_cell)
		tmp_rf = rf_cell{kk};
		idx_rf = get_idx_cell(stresstest_names,tmp_rf);
	
		if ( idx_rf == 0)
			fprintf('print_report: Stress test struct has no stress test named >>%s<<.\n',tmp_rf);
		else
			if (abs(obj_pnl(idx_rf)) == 0)
				fprintf('print_report: Portfolio not sensitive to risk factor %s.\n',tmp_rf);
			else
				fprintf('print_report: Portfolio sensitive to risk factor %s.\n',tmp_rf);
				ret_cell(length(ret_cell)+1) = tmp_rf;
			end
		end
	end
end
end

% @Position/print_report: Print reports
function obj = print_report(obj, para_object,type,scen_set,stresstest_struct = [],instrument_struct = [])
  if (nargin < 3)
        type = 'TPT';
  elseif (nargin < 4)   
		print_usage();
  end
% --------------    Decomp VaRAggregating Key reporting     ------------
if (strcmpi(type,'decomp'))  
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  fprintf('print_report: No decomp report exists for scenario set >>%s<<\n',scen_set);
  else
	  fund_currency = obj.getValue('currency');
	  aggr_key_struct = obj.get('aggr_key_struct');
	
	  fprintf('=== Aggregation Key Reporting for Portfolio %s === \n',obj.get('id'));  
	  for jj = 1:1:length(aggr_key_struct)
		% load values from aggr_key_struct:
		tmp_aggr_cell               = aggr_key_struct( jj ).key_values;
		tmp_aggr_key_name           = aggr_key_struct( jj ).key_name;
		tmp_aggregation_mat         = [aggr_key_struct( jj ).aggregation_mat];
		tmp_aggregation_basevalue   = [aggr_key_struct( jj ).aggregation_basevalue];
		tmp_aggregation_decomp_shock  = [aggr_key_struct( jj ).aggregation_decomp_shock];
		tmp_aggregation_standalone_shock  = [aggr_key_struct( jj ).aggregation_standalone_shock];
		fprintf(' Risk aggregation for key: %s \n', tmp_aggr_key_name);
		fprintf('|VaR %s | Key value   | Basevalue \t | Standalone HD VAR \t | Decomp %s VAR|\n',scen_set,upper(para_object.get('quantile_estimator')));
		fprintf('|VaR %s | Portfolio \t |%9.2f %s \t|%9.2f %s \t |%9.2f %s|\n',scen_set,obj.get('value_base'),fund_currency,obj.get('varhd_abs'),fund_currency,obj.get('varhd_abs'),fund_currency);
		for ii = 1 : 1 : length(tmp_aggr_cell)
			tmp_aggr_key_value          = tmp_aggr_cell{ii};
			tmp_decomp_aggr_key_var     = tmp_aggregation_decomp_shock(ii);
			tmp_standalone_aggr_key_var = tmp_aggregation_standalone_shock(ii);
			tmp_aggregation_basevalue_pos = tmp_aggregation_basevalue(ii);
			fprintf('|VaR %s | %s \t |%9.2f %s \t|%9.2f %s \t |%9.2f %s|\n',scen_set,tmp_aggr_key_value,tmp_aggregation_basevalue_pos,fund_currency,tmp_standalone_aggr_key_var,fund_currency,tmp_decomp_aggr_key_var,fund_currency);
		end
	  end
  end

% ---------------------------------    LaTeX    --------------------------------
elseif (strcmpi(type,'latex'))  
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  fprintf('print_report: No LaTeX report exists for scenario set >>%s<<\n',scen_set);
  else 
	  % get path
	  if ( strcmpi(para_object.path_working_folder,''))
		path_main = pwd;
	  else
		path_main = para_object.path_working_folder;
	  end
	  path_reports = strcat(path_main,'/', ...
					para_object.folder_output,'/',para_object.folder_output_reports);
	  
	  % ####  print portfolio risk metrics report
	    latex_table_port_var = strcat(path_reports,'/table_port_',obj.id,'_var.tex');
	    filp = fopen (latex_table_port_var, 'w');
		fprintf(filp, '\\center\n');
		fprintf(filp, '\\label{table_port_var}\n');
		fprintf(filp, '\\begin{tabular}{l r}\n');
		fprintf(filp, 'Valuation date \& %s\\\\\n',datestr(para_object.valuation_date));
		fprintf(filp, 'Portfolio value in reporting currency \& %9.0f %s\\\\\n',obj.getValue('base'),obj.currency);   
		fprintf(filp, 'Value at Risk (abs.) %s@%2.1f\\%% \& %9.1f\\%%\\\\\n',scen_set,para_object.quantile.*100,-obj.varhd_rel*100);
		fprintf(filp, 'Value at Risk (rel.) %s@%2.1f\\%% \& %9.0f %s\\\\\n',scen_set,para_object.quantile.*100,obj.varhd_abs,obj.currency);
		fprintf(filp, 'Expected Shortfall %s@%2.1f\\%% \& %9.1f\\%%\\\\\n',scen_set,para_object.quantile.*100,-obj.expshortfall_rel*100);
		fprintf(filp, 'Expected Shortfall %s@%2.1f\\%% \& %9.0f %s\\\\\n',scen_set,para_object.quantile.*100,obj.expshortfall_abs,obj.currency);
		fprintf(filp, 'Volatility (annualized) \& %3.1f\\%%\\\\\n',100 * obj.var84_abs * sqrt(250/para_object.mc_timestep_days) / obj.getValue('base'));
		fprintf(filp, 'Diversification benefit \& %9.1f\\%%\\\\ \n',(1 - obj.diversification_ratio)*100);
		fprintf(filp, '\\end{tabular}\n');
	    fclose (filp);
  
	  
	  
	  % #### Print Aggregation Key Asset Class report
	  aggr_key_struct = obj.get('aggr_key_struct');
	  aa_target_id = obj.get('aa_target_id');
	  aa_target_values = obj.get('aa_target_values');
	  latex_table_decomp = strcat(path_reports,'/table_port_',obj.id,'_decomp.tex');
	  fild = fopen (latex_table_decomp, 'w');
	  fprintf(fild, '\\center\n');
	  fprintf(fild, '\\label{table_port_decomp}\n');
	  fprintf(fild, '\\begin{tabular}{l|r|r|r|r|r}\n');
	  
	  for jj = 1:1:length(aggr_key_struct)
		tmp_aggr_key_name  = aggr_key_struct( jj ).key_name;
		tmp_aggr_cell               = aggr_key_struct( jj ).key_values;
		tmp_aggr_key_name           = aggr_key_struct( jj ).key_name;
		tmp_aggregation_mat         = [aggr_key_struct( jj ).aggregation_mat];
		tmp_aggregation_basevalue   = [aggr_key_struct( jj ).aggregation_basevalue];
		tmp_aggregation_decomp_shock  = [aggr_key_struct( jj ).aggregation_decomp_shock];
		tmp_aggregation_standalone_shock  = [aggr_key_struct( jj ).aggregation_standalone_shock];
		  if strcmpi(tmp_aggr_key_name,'asset_class')
			latex_table_aa = strcat(path_reports,'/table_port_',obj.id,'_aa.tex');
			fiaa = fopen (latex_table_aa, 'w');
			fprintf(fild, 'Asset Class \& Basevalue \& Pct. \& Standalone VaR \& Decomp VaR\& Pct.\\\\\\hline\\hline\n');
			fprintf(fild, 'Portfolio \& %9.0f %s \& %3.1f\\%% \& %9.0f %s\& %9.0f %s\& %3.1f\\%%\\\\\\hline\n',obj.getValue('base'),obj.currency,100,obj.varhd_abs,obj.currency,obj.varhd_abs,obj.currency,100);
			fprintf(fiaa, '\\center\n');
			fprintf(fiaa, '\\label{table_port_aa}\n');
			fprintf(fiaa, '\\begin{tabular}{l|r|r|r|r|r}\n');
			fprintf(fiaa, 'Asset Class \& Basevalue \& Target AA \& Actual AA \& Deviation \& Risk Impact\\\\\\hline\\hline\n');
			devation_sum = 0;
			risk_impact_sum = 0;
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
				aa_current = tmp_aggregation_basevalue_pos/obj.getValue('base');
				tmp_deviation = (aa_current - aa_target) * obj.getValue('base');
				tmp_risk_impact = (tmp_deviation / tmp_aggregation_basevalue_pos) * tmp_decomp_aggr_key_var;
				risk_impact_sum = risk_impact_sum + tmp_risk_impact;
				devation_sum = devation_sum + abs(tmp_deviation);
				fprintf(fild, '%s \& %9.0f %s \& %3.1f\\%% \& %9.0f %s \& %9.0f %s \& %3.1f\\%%\\\\\n',tmp_aggr_key_value,tmp_aggregation_basevalue_pos,obj.currency,100*tmp_aggregation_basevalue_pos/obj.getValue('base'),tmp_standalone_aggr_key_var,obj.currency,tmp_decomp_aggr_key_var,obj.currency,100*tmp_decomp_aggr_key_var/obj.varhd_abs);
				fprintf(fiaa, '%s \& %9.0f %s \& %3.1f\\%% \& %3.1f\\%% \& %9.0f %s \& %9.0f  %s\\\\\n',tmp_aggr_key_value,tmp_aggregation_basevalue_pos,obj.currency,aa_target*100,aa_current*100,tmp_deviation,obj.currency,tmp_risk_impact,obj.currency);
			end
			fprintf(fiaa, '\\\hline Portfolio \& %9.0f %s \& %3.0f\\%% \& %3.0f\\%% \&  %9.0f %s \& %9.0f  %s\\\\\\hline\n',obj.getValue('base'),obj.currency,100,100,devation_sum,obj.currency,risk_impact_sum,obj.currency);
			%fprintf(fild, '\\end{tabular}\n');
			fprintf(fiaa, '\\end{tabular}\n');
			%fclose (fild);
			fclose (fiaa);
		  % plot currency decomposition
		  elseif strcmpi(tmp_aggr_key_name,'currency')
			%latex_table_decomp_cur = strcat(path_reports,'/table_port_',obj.id,'_decomp_cur.tex');
			%fild = fopen (latex_table_decomp_cur, 'w');
			%fprintf(fild, '\\center\n');
			%fprintf(fild, '\\label{table_port_decomp_cur}\n');
			%fprintf(fild, '\\begin{tabular}{l|r|r|r|r|r}\n');
			fprintf(fild, '\\\hline Currency \& Basevalue \& Pct. \& Standalone VaR \& Decomp VaR\& Pct.\\\\\\hline\n');
			%fprintf(fild, 'Portfolio \& %9.0f %s \& %2.1f\\%% \& %9.0f %s\& %9.0f %s\& %2.1f\\%%\\\\\\hline\n',obj.getValue('base'),obj.currency,100,obj.varhd_abs,obj.currency,obj.varhd_abs,obj.currency,100);
			devation_sum = 0;
			risk_impact_sum = 0;
			for ii = 1 : 1 : min(length(tmp_aggr_cell),25)
				tmp_aggr_key_value          = tmp_aggr_cell{ii};
				tmp_sorted_aggr_mat         = sort(tmp_aggregation_mat(:,ii));  
				tmp_standalone_aggr_key_var = tmp_aggregation_standalone_shock(ii);
				tmp_decomp_aggr_key_var     = tmp_aggregation_decomp_shock(ii);
				tmp_aggregation_basevalue_pos = tmp_aggregation_basevalue(ii);
				tmp_aggr_key_value = strrep(tmp_aggr_key_value,"_","");
				fprintf(fild, '%s \& %9.0f %s \& %3.1f\\%%\& %9.0f %s \& %9.0f %s \& %3.1f\\%%\\\\\n',tmp_aggr_key_value,tmp_aggregation_basevalue_pos,obj.currency,100*tmp_aggregation_basevalue_pos/obj.getValue('base'),tmp_standalone_aggr_key_var,obj.currency,tmp_decomp_aggr_key_var,obj.currency,100*tmp_decomp_aggr_key_var/obj.varhd_abs);
			end
			
		  end
		  
	  end
	  fprintf(fild, '\\end{tabular}\n');
	  fclose (fild);
	
	  % #### Position ID Decomp LaTeX Table
	  mc_var_shock = obj.varhd_abs;
	  fund_currency = obj.currency; 	
		pie_chart_values_pos_shock = [];
		pie_chart_desc_pos_shock = {};
		% loop through all positions
		for (ii=1:1:length(obj.positions))
			try
			  pos_obj = obj.positions(ii).object;
			  if (isobject(pos_obj))
					pie_chart_values_pos_shock(ii) = (pos_obj.decomp_varhd) ;
					pie_chart_desc_pos_shock(ii) = cellstr( strcat(pos_obj.id));
			  end
			catch
				printf('Portfolio.print_report: there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
			end
		end
		% prepare vector for piechart:
		[pie_chart_values_sorted_pos_shock sorted_numbers_pos_shock ] = sort(pie_chart_values_pos_shock,'descend');
		idx = 1; 
		% plot Top 10 Positions
		max_positions = 10;
		for ii = 1:1:min(length(pie_chart_values_pos_shock),max_positions);
			pie_chart_values_plot_pos_shock(idx)     = pie_chart_values_sorted_pos_shock(ii) ;
			pie_chart_desc_plot_pos_shock(idx)       = pie_chart_desc_pos_shock(sorted_numbers_pos_shock(ii));
			idx = idx + 1;
		end
		% append remaining part
		if (idx == (max_positions + 1))
			pie_chart_values_plot_pos_shock(idx)     = mc_var_shock - sum(pie_chart_values_plot_pos_shock) ;
			pie_chart_desc_plot_pos_shock(idx)       = "Other";
		end
		pie_chart_values_plot_pos_shock = pie_chart_values_plot_pos_shock ./ sum(pie_chart_values_plot_pos_shock);
  
		% Plot LaTeX table Decomp ID
		other_var = obj.varhd_abs;
		other_value = obj.getValue('base');
		latex_table_decomp = strcat(path_reports,'/table_port_',obj.id,'_decomp_id.tex');
		fiid = fopen (latex_table_decomp, 'w');
		fprintf(fiid, '\\center\n');
		fprintf(fiid, '\\begin{tabular}{l|r|r|r|r}\n');
		fprintf(fiid, 'Position ID \& Basevalue \& Standalone VaR \& Decomp VaR \& Pct.\\\\\\hline\\hline\n');
		fprintf(fiid, 'Portfolio \& %9.0f %s \& %9.0f  %s\& %9.0f %s \& %3.1f\\%%\\\\\\hline\n',obj.getValue('base'),obj.currency,obj.varhd_abs,obj.currency,obj.varhd_abs,obj.currency,100);
		for kk=1:1:length(pie_chart_desc_plot_pos_shock)
			pos_id = pie_chart_desc_plot_pos_shock{kk};
			[pos_obj retcode] = get_sub_object(obj.positions,pos_id);
			if ( retcode == 1)
				tmp_id = strrep(pos_obj.id,"_","");
				other_var = other_var - pos_obj.decomp_varhd;
				other_value = other_value - pos_obj.getValue('base');
				fprintf(fiid, '%s \& %9.0f %s \& %9.0f %s \& %9.0f %s\& %3.1f\\%%\\\\\n',tmp_id,pos_obj.getValue('base'),pos_obj.currency,pos_obj.varhd_abs,obj.currency,pos_obj.decomp_varhd,obj.currency,100*pos_obj.decomp_varhd/obj.varhd_abs);
			end
		end
		fprintf(fiid, '%s \& %9.0f %s \& %s \& %9.0f %s\& %3.1f\\%%\\\\\n','Other',other_value,obj.currency,'--',other_var,obj.currency,100*other_var/obj.varhd_abs);
		fprintf(fiid, '\\end{tabular}\n');
		fclose (fiid);
		
		% #### print Incremental and Marginal VaR Report
		if (para_object.calc_marg_incr_var = true)
			latex_table_incr_var = strcat(path_reports,'/table_pos_',obj.id,'_incr_var.tex');
			fili = fopen (latex_table_incr_var, 'w');
			fprintf(fili, '\\center\n');
			fprintf(fili, '\\begin{tabular}{l|r|r|r }\n');
			fprintf(fili, 'Position ID\& Basevalue \& Incremental VaR \& Marginal VaR\\\\ \\hline\n');
		for kk=1:1:length(pie_chart_desc_plot_pos_shock)
			pos_id = pie_chart_desc_plot_pos_shock{kk};
			[pos_obj retcode] = get_sub_object(obj.positions,pos_id);
			if ( retcode == 1)
				fprintf(fili, '%s \& %9.0f %s \& %9.0f %s\& %9.0f %s\\\\\n',strrep(pos_id,"_",""),pos_obj.getValue('base'),obj.currency,pos_obj.incr_var,obj.currency,pos_obj.marg_var,obj.currency);
			  end
		end
			fprintf(fili, '\\end{tabular}\n');
			fclose (fili);
		end
	  
	    % Equity Region Allocation
	    % loop through all positions
	    if (isstruct(instrument_struct))
			region_cell = obj.equity_target_region_id;
			region_current_values = zeros(1,length(region_cell));
			region_current_decomp = zeros(1,length(region_cell));
			style_port_values = zeros(1,9);
			for (ii=1:1:length(obj.positions))
				try
				  pos_obj = obj.positions(ii).object;
				  if (isobject(pos_obj))
				   pos_id = pos_obj.id;
				   instr_obj = get_sub_object(instrument_struct,pos_id);
				   if (instr_obj.isProp('asset_class'))
					 if (strcmpi(instr_obj.get('asset_class'),'Equity'))
						region_cell_pos  = instr_obj.region_id;
						if (abs(sum(instr_obj.region_values) - 1) > 0.01)
							fprintf('WARNING: Position.print_report: >>5s<< has region allocation not equal to 1\n',instr_obj.id);
						end
						region_values_abs  = instr_obj.region_values .* pos_obj.getValue('base');
						region_decomp_abs  = instr_obj.region_values .* pos_obj.decomp_varhd;
						for kk=1:1:length(region_cell)
							tmp_region = region_cell{kk};
							for jj=1:1:length(region_cell_pos)
								if ( strcmpi(tmp_region,region_cell_pos{jj}))
									region_current_values(kk) = region_current_values(kk) + region_values_abs(jj);
									region_current_decomp(kk) = region_current_decomp(kk) + region_decomp_abs(jj);
								end
							end
						end
					  end
					  % save portfolio equity style box
					  if (strcmpi(instr_obj.get('asset_class'),'Equity'))
						style_cell_pos  = instr_obj.style_id;
						style_pos_values = instr_obj.style_values .* pos_obj.getValue('base');
						style_port_values = style_port_values + style_pos_values;
					  end
					end
				  end
				catch
					printf('Portfolio.print_report: there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
				end
			end
			
			% print Equity region allocation to LaTeX Table
			latex_table_equity_region = strcat(path_reports,'/table_pos_',obj.id,'_equity_region.tex');
			fiaa = fopen (latex_table_equity_region, 'w');
			fprintf(fiaa, '\\center\n');
			fprintf(fiaa, '\\begin{tabular}{l|r|r|r|r|r}\n');
			fprintf(fiaa, 'Region \& Basevalue \& Target AA \& Actual AA \& Deviation \& Risk Impact\\\\\\hline\\hline\n');	
			for kk=1:1:length(region_cell)
				region = region_cell{kk};
				region_val = region_current_values(kk);
				region_decomp = region_current_decomp(kk);
				region_sum = sum(region_current_values);
				aa_target = obj.equity_target_region_values(kk);
				aa_current = region_val ./ region_sum;
				tmp_deviation = (aa_current - aa_target) * region_sum;
				tmp_risk_impact = (tmp_deviation / region_val) * region_decomp;
				risk_impact_sum = risk_impact_sum + tmp_risk_impact;
				devation_sum = devation_sum + abs(tmp_deviation);
				fprintf(fiaa, '%s \& %9.0f %s \& %3.1f\\%% \& %3.1f\\%% \& %9.0f %s\& %9.0f %s\\\\\n',region,region_val,obj.currency,aa_target*100,aa_current*100,tmp_deviation,obj.currency,tmp_risk_impact,obj.currency);
			end
			fprintf(fiaa, '\\\hline Equity \& %9.0f %s \& %3.1f\\%% \& %3.1f\\%% \& %9.0f %s\& %9.0f %s\\\\\\hline\n',region_sum,obj.currency,100,100,devation_sum,obj.currency,risk_impact_sum,obj.currency);
			fprintf(fiaa, '\\end{tabular}\n');
			fclose (fiaa);
			
			% print Equity style box to LaTeX Table
			style_cell_pos
			style_port_values
			estab = 100 .* style_port_values / sum(region_sum);
			latex_table_equity_style = strcat(path_reports,'/table_pos_',obj.id,'_equity_style.tex');
			fies = fopen (latex_table_equity_style, 'w');
			fprintf(fies, '\\center\n');
			fprintf(fies, '\\begin{tabular}{l|c c c|r}\n');
			fprintf(fies, 'Size/Style \& Value \& Blend \& Growth \& Sum \\\\\\hline\n');	
			fprintf(fies, 'Large Cap \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\n',estab(1),estab(2),estab(3),sum(estab(1:3)));	
			fprintf(fies, 'Mid Cap \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\n',estab(4),estab(5),estab(6),sum(estab(4:6)));	
			fprintf(fies, 'Small Cap \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\\hline\n',estab(7),estab(8),estab(9),sum(estab(7:9)));	
			fprintf(fies, 'Sum \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\n',sum([estab(1),estab(4),estab(7)]),sum([estab(2),estab(5),estab(8)]),sum([estab(3),estab(6),estab(9)]),sum(estab));	
			fprintf(fies, '\\end{tabular}\n');
			fclose (fies);
		end
  end
% ------------------------------------------------------------------------------  
elseif (strcmpi(type,'stress'))
  if ~( strcmpi(scen_set,'stress'))
	  fprintf('print_report: No stress report exists for scenario set >>%s<<\n',scen_set);
  else
	if (length(stresstest_struct)>0 && nargin == 5)
		% Stress portfolio reporting
		fprintf('Position Base and stress Values: \n');
		stressnames = {stresstest_struct.name};
		fprintf('\n');
		fprintf('ID,Base,StressBase,');
		for jj=2:1:length(stressnames)
			fprintf('%s,',stressnames{jj});
		end
		fprintf('\n');
		% print portfolio stress values
		stressvec = obj.getValue('stress');
		fprintf('%s,%9.8f,',obj.id,obj.getValue('base'));
		if (length(stressvec) > 0)
			for jj=1:1:length(stressvec)
				fprintf('%9.8f,',stressvec(jj));
			end
		end
		fprintf('%s\n',any2str(obj.currency));
			  
		for (ii=1:1:length(obj.positions))
		  pos_obj = obj.positions(ii).object;
		  if (isobject(pos_obj))
			try
			  pos_id = pos_obj.id;
			  stressvec = pos_obj.getValue('stress');
			  fprintf('%s,%9.8f,',pos_obj.id,pos_obj.getValue('base'));
			  if (length(stressvec) > 0)
				for jj=1:1:length(stressvec)
					fprintf('%9.8f,',stressvec(jj));
				end
			  end
			  fprintf('%s\n',any2str(pos_obj.currency));
			catch
			  printf('There was an error for position id>>%s<<: %s\n',pos_id,lasterr);
			end
		  end
		end
	else
		fprintf('print_report: No stresstest_struct input provided.\n');
	end

  end
elseif (strcmpi(type,'TPT'))
	  % A) Specify fieldnames <-> types key/value pairs
	  tpt_map = struct(...
				'tpt_1', '1_Portfolio_identifying_data', ...
				'tpt_2', '2_Type_of_identification_code_for_the_fund_share_or_portfolio', ...
				'tpt_3', '3_Portfolio_name', ...
				'tpt_4', '4_Portfolio_currency_(B)', ...
				'tpt_5', '5_Net_asset_valuation_of_the_portfolio_or_the_share_class_in_portfolio_currency', ...
				'tpt_6', '6_Valuation_date', ...
				'tpt_7', '7_Reporting_date', ...
				'tpt_8', '8_Share_price', ...
				'tpt_8b', '8b_Total_number_of_shares', ...
				'tpt_9', '9_Cash_ratio', ...
				'tpt_10', '10_Portfolio_modified_duration', ...
				'tpt_11', '11_Complete_SCR_delivery', ...
				'tpt_12', '12_CIC_code_of_the_instrument', ...
				'tpt_13', '13_Economic_zone_of_the_quotation_place', ...
				'tpt_14', '14_Identification_code_of_the_instrument', ...
				'tpt_15', '15_Type_of_identification_code_for_the_instrument', ...
				'tpt_16', '16_Grouping_code_for_multiple_leg_instruments', ...
				'tpt_17', '17_Instrument_name', ...
				'tpt_17b', '17b_Asset_liability', ...
				'tpt_18', '18_Quantity', ...
				'tpt_19', '19_Nominal_amount', ...
				'tpt_20', '20_Contract_size_for_derivatives', ...
				'tpt_21', '21_Quotation_currency_(A)', ...
				'tpt_22', '22_Market_valuation_in_quotation_currency_(A)', ...
				'tpt_23', '23_Clean_market_valuation_in_quotation_currency_(A)', ...
				'tpt_24', '24_Market_valuation_in_portfolio_currency_(B)', ...
				'tpt_25', '25_Clean_market_valuation_in_portfolio_currency_(B)', ...
				'tpt_26', '26_Valuation_weight', ...
				'tpt_27', '27_Market_exposure_amount_in_quotation_currency_(A)', ...
				'tpt_28', '28_Market_exposure_amount_in_portfolio_currency_(B)', ...
				'tpt_29', '29_Market_exposure_amount_for_the_3rd_quotation_currency_(C)', ...
				'tpt_30', '30_Market_exposure_in_weight', ...
				'tpt_31', '31_Market_exposure_for_the_3rd_currency_in_weight_over_NAV', ...
				'tpt_32', '32_Interest_rate_type', ...
				'tpt_33', '33_Coupon_rate', ...
				'tpt_34', '34_Interest_rate_reference_identification', ...
				'tpt_35', '35_Identification_type_for_interest_rate_index', ...
				'tpt_36', '36_Interest_rate_index_name', ...
				'tpt_37', '37_Interest_rate_margin', ...
				'tpt_38', '38_Coupon_payment_frequency', ...
				'tpt_39', '39_Maturity_date', ...
				'tpt_40', '40_Redemption_type', ...
				'tpt_41', '41_Redemption_rate', ...
				'tpt_42', '42_Callable_putable', ...
				'tpt_43', '43_Call_put_date', ...
				'tpt_44', '44_Issuer_bearer_option_exercise', ...
				'tpt_45', '45_Strike_price_for_embedded_(call_put)_options', ...
				'tpt_46', '46_Issuer_name', ...
				'tpt_47', '47_Issuer_identification_code', ...
				'tpt_48', '48_Type_of_identification_code_for_issuer', ...
				'tpt_49', '49_Name_of_the_group_of_the_issuer', ...
				'tpt_50', '50_Identification_of_the_group', ...
				'tpt_51', '51_Type_of_identification_code_for_issuer_group', ...
				'tpt_52', '52_Issuer_country', ...
				'tpt_53', '53_Issuer_economic_area', ...
				'tpt_54', '54_Economic_sector', ...
				'tpt_55', '55_Covered_not_covered', ...
				'tpt_56', '56_Securitisation', ...
				'tpt_57', '57_Explicit_guarantee_by_the_country_of_issue', ...
				'tpt_58', '58_Subordinated_debt', ...
				'tpt_58b', '58b_Nature_of_the_tranche', ...
				'tpt_59', '59_Credit_quality_step', ...
				'tpt_60', '60_Call_Put_Cap_Floor', ...
				'tpt_61', '61_Strike_price', ...
				'tpt_62', '62_Conversion_factor_(convertibles)_concordance_factor_parity_(options)', ...
				'tpt_63', '63_Effective_date_of_instrument', ...
				'tpt_64', '64_Exercise_type', ...
				'tpt_65', '65_Hedging_rolling', ...
				'tpt_67', '67_CIC_of_the_underlying_asset', ...
				'tpt_68', '68_Identification_code_of_the_underlying_asset', ...
				'tpt_69', '69_Type_of_identification_code_for_the_underlying_asset', ...
				'tpt_70', '70_Name_of_the_underlying_asset', ...
				'tpt_71', '71_Quotation_currency_of_the_underlying_asset_(C)', ...
				'tpt_72', '72_Last_valuation_price_of_the_underlying_asset', ...
				'tpt_73', '73_Country_of_quotation_of_the_underlying_asset', ...
				'tpt_74', '74_Economic_area_of_quotation_of_the_underlying_asset', ...
				'tpt_75', '75_Coupon_rate_of_the_underlying_asset', ...
				'tpt_76', '76_Coupon_payment_frequency_of_the_underlying_asset', ...
				'tpt_77', '77_Maturity_date_of_the_underlying_asset', ...
				'tpt_78', '78_Redemption_profile_of_the_underlying_asset', ...
				'tpt_79', '79_Redemption_rate_of_the_underlying_asset', ...
				'tpt_80', '80_Issuer_name_of_the_underlying_asset', ...
				'tpt_81', '81_Issuer_identification_code_of_the_underlying_asset', ...
				'tpt_82', '82_Type_of_issuer_identification_code_of_the_underlying_asset', ...
				'tpt_83', '83_Name_of_the_group_of_the_issuer_of_the_underlying_asset', ...
				'tpt_84', '84_Identification_of_the_group_of_the_underlying_asset', ...
				'tpt_85', '85_Type_of_the_group_identification_code_of_the_underlying_asset', ...
				'tpt_86', '86_Issuer_country_of_the_underlying_asset', ...
				'tpt_87', '87_Issuer_economic_area_of_the_underlying_asset', ...
				'tpt_88', '88_Explicit_guarantee_by_the_country_of_issue_of_the_underlying_asset', ...
				'tpt_89', '89_Credit_quality_step_of_the_underlying_asset', ...
				'tpt_90', '90_Modified_duration_to_maturity_date', ...
				'tpt_91', '91_Modified_duration_to_next_option_exercise_date', ...
				'tpt_92', '92_Credit_sensitivity', ...
				'tpt_93', '93_Sensitivity_to_underlying_asset_price_(delta)', ...
				'tpt_94', '94_Convexity_gamma_for_derivatives', ...
				'tpt_94b', '94b_Vega', ...
				'tpt_95', '95_Identification_of_the_original_portfolio_for_positions_embedded_in_a_fund', ...
				'tpt_97', '97_SCR_mrkt_IR_up_weight_over_NAV', ...
				'tpt_98', '98_SCR_mrkt_IR_down_weight_over_NAV', ...
				'tpt_99', '99_SCR_mrkt_eq_type1_weight_over_NAV', ...
				'tpt_100', '100_SCR_mrkt_eq_type2_weight_over_NAV', ...
				'tpt_101', '101_SCR_mrkt_prop_weight_over_NAV', ...
				'tpt_102', '102_SCR_mrkt_spread_bonds_weight_over_NAV', ...
				'tpt_103', '103_SCR_mrkt_spread_structured_weight_over_NAV', ...
				'tpt_104', '104_SCR_mrkt_spread_derivatives_up_weight_over_NAV', ...
				'tpt_105', '105_SCR_mrkt_spread_derivatives_down_weight_over_NAV', ...
				'tpt_105a', '105a_SCR_mrkt_FX_up_weight_over_NAV', ...
				'tpt_105b', '105b_SCR_mrkt_FX_down_weight_over_NAV', ...
				'tpt_106', '106_Asset_pledged_as_collateral', ...
				'tpt_107', '107_Place_of_deposit', ...
				'tpt_108', '108_Participation', ...
				'tpt_110', '110_Valorisation_method', ...
				'tpt_111', '111_Value_of_acquisition', ...
				'tpt_112', '112_Credit_rating', ...
				'tpt_113', '113_Rating_agency', ...
				'tpt_114', '114_Issuer_economic_area', ...
				'tpt_115', '115_Fund_issuer_code', ...
				'tpt_116', '116_Fund_issuer_code_type', ...
				'tpt_117', '117_Fund_issuer_name', ...
				'tpt_118', '118_Fund_issuer_sector', ...
				'tpt_119', '119_Fund_issuer_group_code', ...
				'tpt_120', '120_Fund_issuer_group_code_type', ...
				'tpt_121', '121_Fund_issuer_group_name', ...
				'tpt_122', '122_Fund_issuer_country', ...
				'tpt_123', '123_Fund_CIC', ...
				'tpt_123a', '123a_Fund_custodian_country', ...
				'tpt_124', '124_Duration', ...
				'tpt_125', '125_Accrued_income_(Security Denominated Currency)', ...
				'tpt_126', '126_Accrued_income_(Portfolio Denominated Currency)', ...
				'tpt_127', '127_Bond_floor_(convertible_instrument_only)', ...
				'tpt_128', '128_Option_premium_(convertible_instrument_only)', ...
				'tpt_129', '129_Valuation_yield', ...
				'tpt_130', '130_Valuation_z_spread', ...
				'tpt_131', '131_Underlying_asset_category', ...
				'tpt_132', '132_Infrastructure_investment', ...
				'tpt_133', '133_custodian_name', ...
				'tpt_1000', '1000_tpt_Version' ...
				   );
	  % print attributes to report
	% 0) open file
	path_reports = strcat(para_object.path_working_folder,'/',para_object.folder_output,'/',para_object.folder_output_reports);
	%TPT Naming Convention:     
	%               YYYYMMDD_TPT_ISIN_YYYYMMDD_XXX = 
	%               valuation date_TPT_identification code_reporting date_free text 
	%               (example: 20170331_TPT_FR0123456789_20170415_XXX)
	filename_TPT = strcat(path_reports,'/',datestr(obj.valuation_date,'yyyymmdd'), ...
						'_TPT_',obj.port_id,'_',datestr(obj.reporting_date,'yyyymmdd'), ...
						'_','octarisk','.csv');
	fid = fopen (filename_TPT, 'w');
	delim = ';';    
	fields = fieldnames(tpt_map);
	% 1) print header
	header_string = '';
	for ii = 1:1:length(fields)
		field = fields{ii};
		attr_name = getfield(tpt_map,field);
		header_string = strcat(header_string,delim,attr_name);
	end
	header_string = header_string(2:end); % remove first delimiter
	fprintf(fid, '%s\n',header_string);  


	% 2) print position data
	for (ii=1:1:length(obj.positions))
		pos_obj = obj.positions(ii).object;
		pos_id = obj.positions(ii).id;
		if (isobject(pos_obj))
			print_string = '';
			for ii = 1:1:length(fields)
				field = fields{ii};
				if (( ii <= 12) || ( ii >= 118 && ii <= 124) || ( ii >= 126 && ii <= 130)) % take attributes from portfolio
					attr_value = any2str(obj.get(field));
					% check for date string and convert to TPT date format YYYY-MM-DD (code 29)
					if (ii == 6 || ii == 7) %valuation and reporting date
						attr_value = datestr(attr_value,29);
					end
				else % take position attributes
					attr_value = any2str(pos_obj.get(field));
					% check for date string and convert to TPT date format YYYY-MM-DD
					if (ii == 41 || ii == 45 || ii == 67 || ii == 78) % more dates...
						try 
							attr_value = datestr(attr_value,29);
						end
					end
				end
				print_string = strcat(print_string,delim,attr_value);
			end
			print_string = print_string(2:end); % remove first delimiter
			fprintf(fid, '%s\n',print_string); 
		end
	end
			
	% Close file
	fclose (fid);
	printf('%s: TPT report printed to file >>%s<<\n',obj.id,filename_TPT);s(ii).object;
    pos_id = obj.positions(ii).id;
    if (isobject(pos_obj))
        print_string = '';
        for ii = 1:1:length(fields)
            field = fields{ii};
            if (( ii <= 12) || ( ii >= 118 && ii <= 124) || ( ii >= 126 && ii <= 130)) % take attributes from portfolio
                attr_value = any2str(obj.get(field));
                % check for date string and convert to TPT date format YYYY-MM-DD (code 29)
                if (ii == 6 || ii == 7) %valuation and reporting date
                    attr_value = datestr(attr_value,29);
                end
            else % take position attributes
                attr_value = any2str(pos_obj.get(field));
                % check for date string and convert to TPT date format YYYY-MM-DD
                if (ii == 41 || ii == 45 || ii == 67 || ii == 78) % more dates...
                    try 
                        attr_value = datestr(attr_value,29);
                    end
                end
            end
            print_string = strcat(print_string,delim,attr_value);
        end
        print_string = print_string(2:end); % remove first delimiter
        fprintf(fid, '%s\n',print_string); 
    end
        
% Close file
fclose (fid);
printf('%s: TPT report printed to file >>%s<<\n',obj.id,filename_TPT);
end

end   

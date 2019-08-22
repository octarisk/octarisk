% @Position/print_report: Print reports
function obj = print_report(obj, para_object,type,scen_set,stresstest_struct = [],instrument_struct = [])
if (nargin < 3)
	type = 'TPT';
elseif (nargin < 4)   
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
			latex_table_aa = strcat(path_reports,'/table_port_',obj.id,'_aa.tex');
			fiaa = fopen (latex_table_aa, 'w');
			fprintf(fild, 'AC / Currency \& Basevalue \& Pct. \& Standalone VaR \& Decomp VaR\& Pct.\\\\\\hline\\hline\n');
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
			fprintf(fiaa, '\\end{tabular}\n');
			fclose (fiaa);
			saa_deviation = devation_sum;
			saa_riskimpact = risk_impact_sum;
			repstruct.saa_deviation = devation_sum;
			repstruct.saa_riskimpact = risk_impact_sum;
		  % plot currency decomposition
		  elseif strcmpi(tmp_aggr_key_name,'currency')
			fprintf(fild,'\\\hline ');
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
			fprintf(fili, 'Position ID\& Basevalue \& Incremental VaR \& Marginal VaR\\\\ \\hline\\hline\n');
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
	  
	   % Equity Style / Region Allocation & Fixed Income Style box
	   % loop through all positions
	    eq_deviation = 0;
	    eq_basevalue = 0;
	    cash_amount = 0;
	    country_cell = obj.country_id;
		country_exposure = zeros(1,numel(country_cell));
		esg_score = 0;
		esg_basevalue = 0;
		region_sum = 0;
	    if (isstruct(instrument_struct))
			region_cell = obj.equity_target_region_id;
			region_current_values = zeros(1,numel(region_cell));
			region_current_decomp = zeros(1,numel(region_cell));
			style_port_values = zeros(1,9);
			port_rating = zeros(1,length(obj.rating_values));
			port_duration = zeros(1,length(obj.duration_values));
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
							fprintf('WARNING: Position.print_report: >>%s<< has region allocation not equal to 1\n',instr_obj.id);
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
					  % save portfolio rating / duration box
					  if (strcmpi(instr_obj.type,'Debt'))
							if ( instr_obj.duration < 3 )
								port_duration(1) = port_duration(1) + pos_obj.getValue('base');
							elseif ( instr_obj.duration >= 3 && instr_obj.duration < 7  )
								port_duration(2) = port_duration(2) + pos_obj.getValue('base');
							elseif ( instr_obj.duration >= 7 )
								port_duration(3) = port_duration(3) + pos_obj.getValue('base');
							end
					  else 
						if ( instr_obj.isProp('eff_duration'))
							if ( instr_obj.eff_duration < 3 )
								port_duration(1) = port_duration(1) + pos_obj.getValue('base');
							elseif ( instr_obj.eff_duration >= 3 && instr_obj.eff_duration < 7  )
								port_duration(2) = port_duration(2) + pos_obj.getValue('base');
							elseif ( instr_obj.eff_duration >= 7 )
								port_duration(3) = port_duration(3) + pos_obj.getValue('base');
							end
						end
					  end
					  % get rating
					  if ( sum(instr_obj.rating_values) > 0)
						port_rating = port_rating + instr_obj.rating_values .* pos_obj.getValue('base');
					  end
					  % required for KPI reporting
					  if (strcmpi(instr_obj.get('asset_class'),'Cash'))
					      cash_amount = cash_amount + pos_obj.getValue('base');	
					  end
					  % get country
					  if ( sum(instr_obj.country_values) > 0)
					    for kk=1:1:length(instr_obj.country_id)
							tmp_ctry = instr_obj.country_id{kk};
							if (strcmpi(country_cell,tmp_ctry) == false)
								country_cell = [country_cell,tmp_ctry];
								country_exposure = [country_exposure,0];
							end
							idx_vec = linspace(1,numel(country_cell),numel(country_cell))'; % find index of country
							idx = strcmpi(country_cell,tmp_ctry) * idx_vec;
							country_exposure(idx) = country_exposure(idx) + ...
										instr_obj.country_values(kk) * pos_obj.getValue('base');
					    end
					  end
					  % get ESG score
					  if (~isempty(instr_obj.esg_score))
						  esg_score = esg_score + (instr_obj.esg_score * ...
								pos_obj.getValue('base'));
						  esg_basevalue = esg_basevalue + pos_obj.getValue('base');
					  end
					end
				  end
				catch
					printf('Portfolio.print_report: there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
				end
			end
			
			if ( abs(esg_basevalue) > 0)
				esg_score = esg_score / esg_basevalue;
				esg_rating = get_esg_rating(esg_score);
			else
				esg_score = 0;
				esg_rating = 'NA';
			end
			repstruct.esg_score = esg_score;
			repstruct.esg_rating = esg_rating;
		% calculate portfolio effective duration / convexity
			if (isstruct(stresstest_struct))
				stresstest_names = {stresstest_struct.name};
				idx_vec = linspace(1,length(stresstest_names),length(stresstest_names))';
				idx_IRdown = strcmpi(stresstest_names,'IR-100bp') * idx_vec;
				idx_IRup  = strcmpi(stresstest_names,'IR+100bp') * idx_vec;
				if ( idx_IRdown == 0 || idx_IRup == 0)
					fprintf('print_report: No portfolio duration calculation. Cannot find IR-100bp or IR+100bp.\n');
				else
					port_eff_duration = ( obj.getValue('stress')(idx_IRdown) - ...
						obj.getValue('stress')(idx_IRup) ) ...
						/ ( 2 * obj.getValue('base') * 0.01 );
							
					port_eff_convexity =(  obj.getValue('stress')(idx_IRdown) + ...
						obj.getValue('stress')(idx_IRup) - 2 * obj.getValue('base') ) ...
						/ ( obj.getValue('base') * 0.0001  );
                end
            end                
			repstruct.port_eff_duration = port_eff_duration;
			repstruct.port_eff_convexity = port_eff_convexity;
			% print Fixed Income style box to LaTeX Table
		% calculate rating, duration style boxes 
			port_rating = port_rating ./ sum(port_rating);
			port_duration = port_duration ./ sum(port_duration);
			obj.rating_values = port_rating;
			obj.duration_values = port_duration;
			
			country_exposure = 100 .* country_exposure ./ sum(country_exposure);
			repstruct.country_exposure = country_exposure;
		% print country exposure to LaTeX table
			dm_string = '';
			em_string = '';
			dm_exp = 0;
			em_exp = 0;
			other_exp = 0;
			max_exp_dm = 0; %max(country_exposure)	% set to 100 for drawing
			max_exp_em = 0;
			dm_exposure_vec = [];
			em_exposure_vec = [];
			dm_exposure_cell = {};
			em_exposure_cell = {};
			% get exposure
			for kk=1:1:numel(country_cell)
				tmp_ctry = country_cell{kk};
				if ( strcmpi(tmp_ctry,'Other'))
					other_exp = country_exposure(kk);
				else
					if (isdevelopedmarket(tmp_ctry))
						dm_exp = dm_exp + country_exposure(kk);	
						dm_exposure_vec = cat(2,dm_exposure_vec,country_exposure(kk));
						dm_exposure_cell = [dm_exposure_cell,tmp_ctry];
						if (country_exposure(kk) > max_exp_dm)
							max_exp_dm = country_exposure(kk);
						end					
					else	% emerging market country
						em_exp = em_exp + country_exposure(kk);
						em_exposure_vec = cat(2,em_exposure_vec,country_exposure(kk));
						em_exposure_cell = [em_exposure_cell,tmp_ctry];
						if (country_exposure(kk) > max_exp_em)
							max_exp_em = country_exposure(kk);
						end	
					end
				end
			end
			% get string
			for kk=1:1:numel(country_cell)
				tmp_ctry = country_cell{kk};
				if ( strcmpi(tmp_ctry,'Other'))
					% do nothing
				else
					if (isdevelopedmarket(tmp_ctry))
						colordepth = 25 + (75 * sqrt(country_exposure(kk) / max_exp_dm));
						%colordepth = 100;
						if ( length(dm_string) == 0)
							dm_string = strcat(tmp_ctry,'/',num2str(colordepth));
						else
							dm_string = strcat(dm_string,',',tmp_ctry,'/',num2str(colordepth));
						end
						
					else	% emerging market country
						colordepth = 25 + (75 * sqrt(country_exposure(kk) / max_exp_em));
						%colordepth = 100;
						if ( length(em_string) == 0)
							em_string = strcat(tmp_ctry,'/',num2str(colordepth));
						else
							em_string = strcat(em_string,',',tmp_ctry,'/',num2str(colordepth));
						end
					end
				end
			end
			
			% Plot overall exposure map
			latex_table_country_exposure = strcat(path_reports,'/',obj.id,'_world_map_exposure.tex');
			fice = fopen (latex_table_country_exposure, 'w');	
			fprintf(fice, '\\tikzset{set state val/.style args={#1/#2}{#1={fill=octariskblue!#2}}};\n');
			fprintf(fice, '\\tikzset{set state val/.list={%s}};\n',dm_string);
			fprintf(fice, '\\tikzset{set state val/.style args={#1/#2}{#1={fill=octariskgreen!#2}}};\n');
			fprintf(fice, '\\tikzset{set state val/.list={%s}};\n',em_string);
			fprintf(fice, '\\definecolor{customgrey}{RGB}{204, 204, 204}\n');
			fprintf(fice, '\\node[draw,align=left] at (13.5,-8.5) {\\textcolor{octariskblue}{$\\blacksquare$} Developed Markets %2.0f\\%%  \\textcolor{octariskgreen}{$\\blacksquare$} Emerging Markets %2.0f\\%%  \\textcolor{customgrey}{$\\blacksquare$} Other %2.0f\\%%};\n',dm_exp,em_exp,other_exp);
			
			% Plot legends for DM and EM
			[dm_exp_sorted sort_numbers] = sort(dm_exposure_vec,'descend');
			dm_exposure_cell = dm_exposure_cell(sort_numbers);
			dm_limit = min(5,numel(dm_exposure_vec));
			dm_exp_sorted = dm_exp_sorted(1:dm_limit);
			dm_exp_sorted_norm = dm_exp_sorted ./ max(dm_exp_sorted);
			dm_exposure_cell = dm_exposure_cell(1:dm_limit);
			orblue = [22, 115, 195];
			orbluediff = 255 - orblue;
			
			for kk=1:1:dm_limit
				orbluecustom = (0.75 - (0.75 * sqrt(dm_exp_sorted(kk) / max(dm_exp_sorted)))) .* orbluediff + orblue;
				fprintf(fice, '\\definecolor{orbluecustom%d}{RGB}{%3.0f, %3.0f, %3.0f}\n',kk,orbluecustom(1),orbluecustom(2),orbluecustom(3));
			end
			fprintf(fice, '\\node[draw,align=left] at (2.0,-7.43) {');
			for kk=1:1:dm_limit
				inform_score = get_informscore(dm_exposure_cell{kk});
				inform_class = get_informclass(inform_score);
				if (kk==1)
					fprintf(fice, 'Exposure \\& Risk \\\\ \\textcolor{orbluecustom%d}{$\\blacksquare$} %s %2.0f\\%% %s',kk,dm_exposure_cell{kk},dm_exp_sorted(kk),inform_class);
				else
					fprintf(fice, '\\\\ \\textcolor{orbluecustom%d}{$\\blacksquare$} %s %2.0f\\%% %s',kk,dm_exposure_cell{kk},dm_exp_sorted(kk),inform_class);
				end
			end
			fprintf(fice, '};\n');
			
			[em_exp_sorted sort_numbers] = sort(em_exposure_vec,'descend');
			em_exposure_cell = em_exposure_cell(sort_numbers);
			em_limit = min(5,numel(em_exposure_vec));
			em_exp_sorted = em_exp_sorted(1:em_limit);
			em_exp_sorted_norm = em_exp_sorted ./ max(em_exp_sorted);
			em_exposure_cell = em_exposure_cell(1:em_limit);
			orgreen = [145, 209, 34];
			orgreendiff = 255 - orgreen;
			for kk=1:1:em_limit
				orgreencustom = (0.75 - (0.75 * sqrt(dm_exp_sorted(kk) / max(dm_exp_sorted)))) .* orgreendiff + orgreen;
				fprintf(fice, '\\definecolor{orgreencustom%d}{RGB}{%3.0f, %3.0f, %3.0f}\n',kk,orgreencustom(1),orgreencustom(2),orgreencustom(3));
			end
			fprintf(fice, '\\node[draw,align=left] at (4.9,-7.43) {');
			for kk=1:1:em_limit
				inform_score = get_informscore(em_exposure_cell{kk});
				inform_class = get_informclass(inform_score);
				if (kk==1)
					fprintf(fice, 'Exposure \\& Risk \\\\ \\textcolor{orgreencustom%d}{$\\blacksquare$} %s %2.0f\\%% %s',kk,em_exposure_cell{kk},em_exp_sorted(kk),inform_class);
				else
					fprintf(fice, '\\\\ \\textcolor{orgreencustom%d}{$\\blacksquare$} %s %2.0f\\%% %s',kk,em_exposure_cell{kk},em_exp_sorted(kk),inform_class);
				end
			end
			fprintf(fice, '};\n');
			fprintf(fice, '\\WORLD[every state={draw=white, thick, fill=black!20}]\n');
			fclose (fice);
			
			% print rating / duration table
			ratingtable = 100 .* port_rating;
			ratingdesc = obj.rating_id;
			durationdesc = obj.duration_id;
			durationtable = 100 .* port_duration;
			latex_table_fi_style = strcat(path_reports,'/table_pos_',obj.id,'_fi_style.tex');
			fifi = fopen (latex_table_fi_style, 'w');
			fprintf(fifi, '\\center\n');
			fprintf(fifi, '\\begin{tabular}{r | c}\n');
			fprintf(fifi, 'Overall Portfolio \& Sensitivity \\\\\\hline\\hline\n');	
			fprintf(fifi, 'Effective Duration \& %3.1f \\\\\n',port_eff_duration);	
			fprintf(fifi, 'Effective Convexity \& %3.1f \\\\\n',port_eff_convexity);	
			fprintf(fifi, '\\end{tabular}\n');
			
			fprintf(fifi, '\\center\n');
			fprintf(fifi, '\\begin{tabular}{r | c || r | c }\n');
			fprintf(fifi, 'Rating \& Allocation \& Eff. Duration \& Allocation \\\\\\hline\\hline\n');	
			fprintf(fifi, '%s \& %3.1f\\%% \& %s \& %3.1f\\%%  \\\\\n','High (AAA-AA)',ratingtable(1),durationdesc{1},durationtable(1));	
			fprintf(fifi, '%s \& %3.1f\\%% \& %s \& %3.1f\\%%  \\\\\n','Mid (A-BBB)',ratingtable(2),durationdesc{2},durationtable(2))
			fprintf(fifi, '%s \& %3.1f\\%% \& %s \& %3.1f\\%%  \\\\\\hline\n','Low (BB-C)',ratingtable(3),durationdesc{3},durationtable(3))	
			fprintf(fifi, 'Sum \& %3.1f\\%% \& Sum \& %3.1f\\%% \\\\\n',sum(ratingtable),sum(durationtable));	
			fprintf(fifi, '\\end{tabular}\n');
			fclose (fifi);
			
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
			eq_deviation = devation_sum;
			eq_basevalue = region_sum;
			repstruct.eq_deviation = devation_sum;
			repstruct.eq_basevalue = region_sum;
			repstruct.eq_riskimpact = risk_impact_sum;
			% print Equity style box to LaTeX Table
			estab = 100 .* style_port_values / sum(region_sum);
			repstruct.estab = 100 .* style_port_values / sum(region_sum);
			latex_table_equity_style = strcat(path_reports,'/table_pos_',obj.id,'_equity_style.tex');
			fies = fopen (latex_table_equity_style, 'w');
			fprintf(fies, '\\center\n');
			fprintf(fies, '\\begin{tabular}{l|c c c|r}\n');
			fprintf(fies, 'Size/Style \& Value \& Blend \& Growth \& Sum \\\\\\hline\\hline\n');	
			fprintf(fies, 'Large Cap \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\n',estab(1),estab(2),estab(3),sum(estab(1:3)));	
			fprintf(fies, 'Mid Cap \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\n',estab(4),estab(5),estab(6),sum(estab(4:6)));	
			fprintf(fies, 'Small Cap \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\\hline\n',estab(7),estab(8),estab(9),sum(estab(7:9)));	
			fprintf(fies, 'Sum \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \& %3.1f\\%% \\\\\n',sum([estab(1),estab(4),estab(7)]),sum([estab(2),estab(5),estab(8)]),sum([estab(3),estab(6),estab(9)]),sum(estab));	
			fprintf(fies, '\\end{tabular}\n');
			fclose (fies);
		end
		% get portfolio INFORM risk score and class
		inform_score = 0;
		for jj=1:1:numel(country_cell)
			ctry = country_cell{jj};
			if ~(strcmpi(ctry,'Other'))
				ctry_inform_risk = get_informscore(ctry);
				exposure = country_exposure(jj) / 100;
				inform_score = inform_score + exposure * ctry_inform_risk;
			else
				exp_other = country_exposure(jj) / 100;
			end
		end
		inform_score = inform_score / (1 - exp_other);
		inform_class = get_informclass(inform_score);
		repstruct.inform_score = inform_score;
		repstruct.inform_class = inform_class;
		% print KPI summary table
		latex_table_kpi = strcat(path_reports,'/table_port_',obj.id,'_kpi.tex');
		fikpi = fopen (latex_table_kpi, 'w');
		fprintf(fikpi, '\\center\n');
		fprintf(fikpi, '\\begin{tabular}{l|c|c|c|c}\n');
		fprintf(fikpi, 'Category \& Measure \& Target \& Actual \& Status \\\\\\hline\\hline\n');	
		
		% 1) VaR SRRI level
			% VaR | SRRI level | 4 | 4 | on track v rebalancing
			srri_actual = get_srri_level(abs(obj.varhd_rel),tmp_ts,para_object.quantile);
			if ( srri_actual == obj.srri_target )
				status_str = '\colorbox{octariskgreen}{on track}';
			else
				status_str = '\colorbox{octariskorange}{action required}';
			end
			fprintf(fikpi, '%s \& %s \& %d \& %d \& %s \\\\\\hline\n','Risk','SRRI class',obj.srri_target,srri_actual,status_str);	
		% 2) VaR trend
			% Risk | VaR trend | -> | up | on track v action required
			hist_var = obj.hist_var_abs;
			hist_bv = obj.hist_base_values;
			hist_var_rel = hist_var ./ hist_bv;
			var_rel = abs(obj.varhd_rel);
			if (length(hist_var_rel) >= 1)
				arrow_str = '$\rightarrow$'; % default if inside +-2% last VaR (MC error)
				status_str = '\colorbox{octariskgreen}{on track}';
				if ( var_rel >= 1.02*hist_var_rel(end))
					arrow_str = '$\nearrow$';
					status_str = '\colorbox{yellow}{monitor}';
					if ( var_rel > 1.02*max(hist_var_rel))
						arrow_str = '$\uparrow$';
						status_str = '\colorbox{octariskorange}{action required}';
					end
				elseif ( var_rel <= 0.98*hist_var_rel(end))
					arrow_str = '$\searrow$';
					status_str = '\colorbox{yellow}{monitor}';
					if ( var_rel < 0.98*min(hist_var_rel))
						arrow_str = '$\downarrow$';
						status_str = '\colorbox{octariskorange}{action required}';
					end
				end
			else
				arrow_str = '$\rightarrow$';
				status_str = '\colorbox{octariskgreen}{no history}';
			end
			fprintf(fikpi, '%s \& %s \& %s \& %s \& %s \\\\\\hline\n','Risk','VaR Trend','$\rightarrow$',arrow_str,status_str);
		% 3) Strategic Asset Allocation
			% SAA | Deviation  | <10% | 6% | on track v action
			max_deviation = 10;
			saa_deviation_rel = 100 * saa_deviation / obj.getValue('base');
			if ( saa_deviation_rel <= max_deviation )
				status_str = '\colorbox{octariskgreen}{on track}';
			else
				status_str = '\colorbox{octariskorange}{action required}';
			end
			fprintf(fikpi, '%s \& %s \& <%3.0f\\%% \& %3.0f\\%% \& %s \\\\\\hline\n','Allocation','Total Deviation',max_deviation,saa_deviation_rel,status_str);	
			% SAA | Risk Impact | <10% | 5% | on track v action
			risk_impact_abs = abs(saa_riskimpact) ;
			risk_impact_max = 10;
			risk_impact_rel = 100 * risk_impact_abs / obj.varhd_abs;
			if ( risk_impact_rel <= risk_impact_max )
				status_str = '\colorbox{octariskgreen}{on track}';
			else
				status_str = '\colorbox{octariskorange}{action required}';
			end
			fprintf(fikpi, '%s \& %s \& <%3.0f\\%% \& %3.0f\\%% \& %s \\\\\\hline\n','Allocation','Risk Impact',risk_impact_max,risk_impact_rel,status_str);
			% SAA | Equity Deviation | <10% | 4% | on track v action
			eq_deviation_max = 10;
			eq_deviation_rel = 100 * eq_deviation / eq_basevalue;
			if ( eq_deviation_rel <= eq_deviation_max )
				status_str = '\colorbox{octariskgreen}{on track}';
			else
				status_str = '\colorbox{octariskorange}{action required}';
			end
			fprintf(fikpi, '%s \& %s \& <%3.0f\\%% \& %3.0f\\%% \& %s \\\\\\hline\n','Allocation','Equity Deviation',eq_deviation_max,eq_deviation_rel,status_str);	
		% 4) Other thresholds
			% SAA | Cash | >40000 EUR | XX EUR | on track v action
			if ( cash_amount >= obj.min_req_cash )
				status_str = '\colorbox{octariskgreen}{on track}';
			else
				status_str = '\colorbox{octariskorange}{action required}';
			end
			fprintf(fikpi, '%s \& %s \& >%9.0f %s \& %9.0f %s \& %s \\\\\\hline\n','Allocation','Cash',obj.min_req_cash,obj.currency,cash_amount,obj.currency,status_str);
		% 5) INFORM risk class
			% Risk | INFORM score | (very) low | low | on track v action
			if ( strcmpi(inform_class,'very low') || strcmpi(inform_class,'low') )
				status_str = '\colorbox{octariskgreen}{on track}';
			else
				status_str = '\colorbox{octariskorange}{action required}';
			end
			fprintf(fikpi, '%s \& %s \& %s \& %s \& %s \\\\\\hline\n','Risk','INFORM score','(very) low',inform_class,status_str);
		% 6) ESG rating
			% Risk | ESG rating | A-AAA | A | on track v action
			if (esg_score > 0)
				if ( strcmpi(esg_rating,'AAA') || strcmpi(esg_rating,'AA') ...
									|| strcmpi(esg_rating,'A'))
					status_str = '\colorbox{octariskgreen}{on track}';
				else
					status_str = '\colorbox{octariskorange}{action required}';
				end
			else
				status_str = '\colorbox{yellow}{not evaluated}';
			end
			fprintf(fikpi, '%s \& %s \& %s \& %s \& %s \\\\\\hline\n','Risk','ESG rating','A-AAA',esg_rating,status_str);	
			
		% end
		fprintf(fikpi, '\\end{tabular}\n');
		fclose (fikpi);
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

% update report_struct in object
obj = obj.set('report_struct',repstruct);
end   

% ##############################################################################
% 			Helper Functions
%
% Return true is ISO code contained in developed market cell
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

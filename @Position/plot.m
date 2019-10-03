% @Position/plot: Plot figures
function obj = plot(obj, para_object,type,scen_set,stresstest_struct = [],curve_struct = [],riskfactor_struct = [])
  if (nargin < 4)   
		print_usage();
  end
  
 % get path
if ( strcmpi(para_object.path_working_folder,''))
	path_main = pwd;
else
	path_main = para_object.path_working_folder;
end
path_reports = strcat(path_main,'/', ...
			para_object.folder_output,'/',para_object.folder_output_reports);

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

% set colors
or_green = [0.56863   0.81961   0.13333]; 
or_blue  = [0.085938   0.449219   0.761719]; 
or_orange =  [0.945312   0.398438   0.035156];

colorbrewer_map = [ ...
		239,243,255;
		198,219,239;
		158,202,225;
		107,174,214;
		49,130,189;
		8,81,156 ...
		] ./255;
		
% --------------    Liquidity Plotting     -----------------------------
if (strcmpi(type,'liquidity'))    
  if ( strcmpi(scen_set,'base'))
		fprintf('plot: Plotting liquidity information for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
		cf_dates = obj.get('cf_dates');
		cf_values = obj.getCF('base');
		xx=1:1:columns(cf_values);
		plot_desc = datestr(datenum(datestr(para_object.valuation_date)) + cf_dates,'mmm');
		hs = figure(1); 
		clf;
		bar(cf_values, 'facecolor', or_blue);
		h=get (gcf, 'currentaxes');
		set(h,'xtick',xx);
		set(h,'xticklabel',plot_desc);
		xlabel('Cash flow date');
		ylabel(strcat('Cash flow amount (in ',obj.currency,')'));
		title('Projected future cash flows','fontsize',12);
		% save plotting
		filename_plot_cf = strcat(path_reports,'/',obj.id,'_cf_plot.png');
		print (hs,filename_plot_cf, "-dpng", "-S600,200");
		filename_plot_cf = strcat(path_reports,'/',obj.id,'_cf_plot.pdf');
		print (hs,filename_plot_cf, "-dpdf", "-S600,200");
		
		% plot exposure to liquidity classes:
		liq_cell = repstruct.liquidity_class_cell;
		liq_exp = repstruct.liquidity_class_exposure;
		colormap (colorbrewer_map);
		hf = figure(1);
		clf; 
		pie(liq_exp,liq_cell);
		%titlestring =  ['Liquidity classes'];
		%title(titlestring,'fontsize',12);
		%legend(desc_cell,'location','west');
		axis(1.2.*[-1,1,-1,1]);
		axis ('tic', 'off'); 	
		% save plotting
		filename_plot_liq = strcat(path_reports,'/',obj.id,'_liquidity_classes.png');
		print (hs,filename_plot_liq, "-dpng", "-S200,200");
		filename_plot_liq = strcat(path_reports,'/',obj.id,'_liquidity_classes.pdf');
		print (hs,filename_plot_liq, "-dpdf", "-S200,200");
		
  elseif ~( strcmpi(scen_set,'base') || strcmpi(scen_set,'stress'))
		fprintf('plot: Plotting liquidity information for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
		cf_dates = obj.get('cf_dates');
		cf_values_base = obj.getCF('base');
		cf_values_mc = obj.getCF(scen_set);
		% take only tail scenarios
		cf_values_mc = mean(cf_values_mc(obj.scenario_numbers,:),1);
		xx=1:1:columns(cf_values_base);
		plot_desc = datestr(datenum(datestr(para_object.valuation_date)) + cf_dates,'mmm');
		hs = figure(1); 
		clf;
		hb = bar([cf_values_base;cf_values_mc]');
		set (hb(1), "facecolor", or_blue);
		set (hb(2), "facecolor", or_orange);
		ha =get (gcf, 'currentaxes');
		set(ha,'xtick',xx);
		set(ha,'xticklabel',plot_desc);
		xlabel('Cash flow date','fontsize',11);
		ylabel(["Cash flow amount (in ",obj.currency,")"],'fontsize',11);
		title('Projected future cash flows','fontsize',12);
		%legend('Base Scenario','Average Tail Scenario');
		% save plotting
		filename_plot_cf = strcat(path_reports,'/',obj.id,'_cf_plot_mc.png');
		print (hs,filename_plot_cf, "-dpng", "-S600,200");
		filename_plot_cf = strcat(path_reports,'/',obj.id,'_cf_plot_mc.pdf');
		print (hs,filename_plot_cf, "-dpdf", "-S600,200");
  else
	  %fprintf('plot: No liquidity plotting possible for scenario set %s === \n',scen_set);  
  end  
% --------------    Risk Factor Shock Plotting   -----------------------------
elseif (strcmpi(type,'riskfactor'))    
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  %fprintf('plot: Risk Factor Shock plots exists for scenario set >>%s<<\n',scen_set);
  else
	  fprintf('plot: Plotting Risk Factor Shock results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
	  if isstruct(riskfactor_struct)
	    [sortPnL sortedscennumbers] = sort(obj.getValue(scen_set) - obj.getValue('base'));
	    % calculate numbers of selected quantiles
	    quantile_9999 = round(max(1,0.0001 * para_object.mc));
	    quantile_9997 = round(max(1,0.0003 * para_object.mc));
		quantile_9995 = round(max(1,0.0005 * para_object.mc));
		quantile_999  = round(max(1,0.001 * para_object.mc));
		quantile_95   = round(max(1,0.05 * para_object.mc));
		quantile_90   = round(max(1,0.1 * para_object.mc));
		quantile_84   = round(para_object.mc - normcdf(1)*para_object.mc);
		quantile_ats  = round(max(1,(1-para_object.quantile)*para_object.mc));
		% prefill risk factor and portfolio shock vectors
	    abs_rf_shocks_mean = [sortPnL(quantile_ats)/obj.getValue('base')];
	    rf_shocks_9999 = [sortPnL(quantile_9999)/obj.getValue('base')];
	    rf_shocks_9997 = [sortPnL(quantile_9997)/obj.getValue('base')];
	    rf_shocks_9995 = [sortPnL(quantile_9995)/obj.getValue('base')];
	    rf_plot_desc = {'Portfolio'};
	    rf_cell = {'RF_EQ_EU','RF_EQ_NA','RF_EQ_EM','RF_FX_EURUSD','RF_IR_EUR_5Y','RF_IR_USD_5Y','RF_COM_GOLD','RF_ALT_BTC','RF_RE_DM'};
		for kk=1:1:length(rf_cell)
			[rf_obj retcode]= get_sub_object(riskfactor_struct,rf_cell{kk});
			if (retcode == 1)
				abs_rf_shocks = rf_obj.getValue(scen_set,'abs') - rf_obj.getValue('base');
				abs_rf_shocks_quantile = abs_rf_shocks(obj.scenario_numbers,:);
				tmp_rf_shocks = abs_rf_shocks(sortedscennumbers,:);
				tmp_rf_shocks_9999 = tmp_rf_shocks(quantile_9999,:);
				tmp_rf_shocks_9997 = tmp_rf_shocks(quantile_9997,:);
				tmp_rf_shocks_9995 = tmp_rf_shocks(quantile_9995,:);
				if ( sum(strcmpi(rf_obj.model,{'GBM','BKM','REL'})) > 0 ) % store relative shocks only
					abs_rf_shocks_mean = [abs_rf_shocks_mean, mean(abs_rf_shocks_quantile)];
					rf_plot_desc = [rf_plot_desc, rf_obj.description];			
					rf_shocks_9999 = [rf_shocks_9999, tmp_rf_shocks_9999];
					rf_shocks_9997 = [rf_shocks_9997, tmp_rf_shocks_9997];
					rf_shocks_9995 = [rf_shocks_9995, tmp_rf_shocks_9995];
				end
			end
		end
		abs_rf_shocks_mean_plot = 100 .* abs_rf_shocks_mean;
		% Plot risk factor shocks in meaningful way?!? Spider chart, bar chart?
		xx = 1:1:length(abs_rf_shocks_mean);
        hs = figure(1);
        clf;
        barh(abs_rf_shocks_mean_plot(1:end), 'facecolor', or_blue);
        h=get (gcf, 'currentaxes');
        set(h,'ytick',xx);
        rf_plot_desc = strrep(rf_plot_desc,"RF_","");
        rf_plot_desc = strrep(rf_plot_desc,"_","-");
        set(h,'yticklabel',rf_plot_desc(1:end));
        xlabel('Risk factor shocks (in pct.)','fontsize',14);
        %title('Risk factor shocks in ATS scenarios','fontsize',14);
        grid on;
        % save plotting
        filename_plot_rf = strcat(path_reports,'/',obj.id,'_rf_plot.png');
        print (hs,filename_plot_rf, "-dpng", "-S600,250");
        filename_plot_rf = strcat(path_reports,'/',obj.id,'_rf_plot.pdf');
        print (hs,filename_plot_rf, "-dpdf", "-S600,250");

        % plot bar charts of selected extreme tail scenarios
        rf_shocks_extreme = [rf_shocks_9999;rf_shocks_9997;rf_shocks_9995;abs_rf_shocks_mean]' .* 100;
        xx = 1:1:numel(rf_plot_desc);
        hs = figure(3);
        clf;
        hb = barh(rf_shocks_extreme);
        set (hb(1), "facecolor", [0.738,0.839,0.902]);
		set (hb(2), "facecolor", [0.417,0.679,0.835]);
		set (hb(3), "facecolor", [0.191,0.507,0.738]);
		set (hb(4), "facecolor", [0.031,0.316,0.609]);
        h=get (gcf, 'currentaxes');
        set(h,'ytick',xx);
        rf_plot_desc = strrep(rf_plot_desc,"RF_","");
        rf_plot_desc = strrep(rf_plot_desc,"_","-");
        set(h,'yticklabel',rf_plot_desc(1:end));
        xlabel('Risk factor shocks (in pct.)','fontsize',12);
        %title('Risk factor shocks in ATS scenarios','fontsize',14);
        legend('99.99%','99.97%','99.95%',['VaR Quantile ',num2str((para_object.quantile)*100),'%']);
        grid on;
        % save plotting
        filename_plot_rf_ext = strcat(path_reports,'/',obj.id,'_rf_plot_tail.png');
        print (hs,filename_plot_rf_ext, "-dpng", "-S700,700");
        filename_plot_rf_ext = strcat(path_reports,'/',obj.id,'_rf_plot_tail.pdf');
        print (hs,filename_plot_rf_ext, "-dpdf", "-S700,700");

        % ----------------------------------------------------------------------
        % plot RF vs quantile smoothing average
        % Idea: sort all risk factor shocks by portfolio PnL, splinefit for
        % smoothing and plotting of most relevant risk factors

        spline_struct = struct();
        spline_struct(1).pp = 'dummy';
        len_tail = 0.2*para_object.mc;
        xx=1:1:len_tail;
        smooth_para = 200;
         rf_cell = {'RF_EQ_EU','RF_IR_EUR_5Y','RF_IR_USD_5Y','RF_COM_GOLD','RF_ALT_BTC','RF_RE_DM'};
        for kk=1:1:length(rf_cell)
			[rf_obj retcode]= get_sub_object(riskfactor_struct,rf_cell{kk});
			if (retcode == 1)
				if ( sum(strcmpi(rf_obj.model,{'GBM','BKM','REL'})) > 0 ) % store relative shocks only
					tmp_rf_shocks = rf_obj.getValue(scen_set,'abs') - rf_obj.getValue('base');
					tmp_rf_shocks = tmp_rf_shocks(sortedscennumbers,:);
					tmp_rf_shocks = tmp_rf_shocks(1:len_tail,:);
					spline_struct( length(spline_struct) + 1).id = strrep(rf_obj.description,'_','');
					spline_struct( length(spline_struct)).distr = tmp_rf_shocks;
					yh = smoothts(tmp_rf_shocks,smooth_para);
					spline_struct( length(spline_struct)).smoothts = yh;
				else % BM model scale by 100
					tmp_rf_shocks = 100*(rf_obj.getValue(scen_set,'abs') - rf_obj.getValue('base'));
					tmp_rf_shocks = tmp_rf_shocks(sortedscennumbers,:);
					tmp_rf_shocks = tmp_rf_shocks(1:len_tail,:);
					spline_struct( length(spline_struct)+ 1).id = strrep(rf_obj.description,'_','');
					spline_struct( length(spline_struct)).distr = tmp_rf_shocks;
					yh = smoothts(tmp_rf_shocks,smooth_para);
					spline_struct( length(spline_struct)).smoothts = yh;
				end
			end
		end
		% Plot
		hq = figure(1);
		clf;
		id_cell = {};
		for jj=2:1:length(spline_struct)
			pp = spline_struct(jj).pp;
			%~ distr = spline_struct(jj).distr .* 100;
			id_cell(jj) = spline_struct(jj).id;
			y = spline_struct(jj).smoothts .* 100;
			plot(xx,y,'linewidth',1.2);
			hold on;
			%~ plot(xx,distr,'.');
			%~ hold on;
		end
		hold off;
		ha =get (gcf, 'currentaxes');
		set(ha,'xtick',[quantile_999 quantile_95 quantile_90 quantile_84 ]);
		set(ha,'xticklabel',{'99.9%','95%','90%','84.1%'});
		xlabel('Quantile','fontsize',14);
		ylabel('Risk Factor Shock (in Pct.)','fontsize',14);
		%title('Risk Factor tail dependency','fontsize',14);
		legend(cellstr(id_cell)(2:end),'fontsize',12,'location','southeast');
		grid on;
		% save plotting
        filename_plot_rf_quantile = strcat(path_reports,'/',obj.id,'_rf_quantile_plot.png');
        print (hq,filename_plot_rf_quantile, "-dpng", "-S1000,400")
        filename_plot_rf_quantile = strcat(path_reports,'/',obj.id,'_rf_quantile_plot.pdf');
        print (hq,filename_plot_rf_quantile, "-dpdf", "-S1000,400")
        
		% ----------------------------------------------------------------------
		% plot extreme tail < MC.quantile only
		hqt = figure(1);
		clf;
		id_cell = {};
		ext_tail = (1-para_object.quantile)*para_object.mc;
		for jj=2:1:length(spline_struct);
			distr = spline_struct(jj).distr .* 100;
			id_cell(jj) = spline_struct(jj).id;
			y = spline_struct(jj).smoothts .* 100;
			%plot(xx(1:ext_tail),y(1:ext_tail),'linewidth',1.2);
			%hold on;
			plot(xx(1:ext_tail),distr(1:ext_tail),'linewidth',1.2);
			hold on;
		end
		hold off;
		hat =get (gcf, 'currentaxes');
		set(hat,'xtick',[quantile_9999 quantile_9995 quantile_999]);
		set(hat,'xticklabel',{'99.99%','99.95%','99.9%'});
		xlabel('Quantile','fontsize',14);
		ylabel('Risk Factor Shock (in Pct.)','fontsize',14);
		%title('Risk Factor tail dependency','fontsize',14);
		legend(cellstr(id_cell)(2:end),'fontsize',12,'location','southeast');
		grid on;
		% save plotting
        filename_plot_rf_quantile_ext = strcat(path_reports,'/',obj.id,'_rf_quantile_plot_tail.png');
        print (hqt,filename_plot_rf_quantile_ext, "-dpng", "-S1000,400")
        filename_plot_rf_quantile_ext = strcat(path_reports,'/',obj.id,'_rf_quantile_plot_tail.pdf');
        print (hqt,filename_plot_rf_quantile_ext, "-dpdf", "-S1000,400")
      end
  end	      					
% --------------    VaR History Plotting   -----------------------------
elseif (strcmpi(type,'history'))    
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  %fprintf('plot: No history VaR plots exists for scenario set >>%s<<\n',scen_set);
  else
	  fprintf('plot: Plotting VaR history results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
	  retcode = plot_hist_var(obj,para_object,path_reports);
	  retcode = plot_hist_var_simple(obj,para_object,path_reports);
  end


% --------------    AA Pie Chart Plotting   -----------------------------
elseif (strcmpi(type,'asset_allocation'))    
  if ( strcmpi(scen_set,'base'))
	  fprintf('plot: Plotting Asset Allocation pie chart results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
	  repstruct = plot_AA_piecharts(repstruct,path_reports,obj);	
  end
			

% -------------    Stress test plotting    ----------------------------- 
elseif (strcmpi(type,'stress'))
  if ~( strcmpi(scen_set,'stress'))
	  %fprintf('plot: No stress report exists for scenario set >>%s<<\n',scen_set);
  else
    if (length(stresstest_struct)>0 && nargin == 5)
		fprintf('plot: Plotting stress results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);
		% prepare stresstest plotting and report output
		stresstest_plot_desc = {stresstest_struct.name};
		p_l_relativ_stress      = 100.*(obj.getValue('stress') - ...
						obj.getValue('base') )./ obj.getValue('base');

        xx = 1:1:length(p_l_relativ_stress)-1;
        hs = figure(1);
        clf;
        barh(p_l_relativ_stress(2:end), 'facecolor', or_blue);
        h=get (gcf, 'currentaxes');
        set(h,'ytick',xx);
        stresstest_plot_desc = strrep(stresstest_plot_desc,"_","");
        set(h,'yticklabel',stresstest_plot_desc(2:end));
        xlabel('Relative PnL (in Pct)','fontsize',14);
        title('Stresstest Results','fontsize',14);
        grid on;
        % save plotting
        filename_plot_stress = strcat(path_reports,'/',obj.id,'_stress_plot.png');
        print (hs,filename_plot_stress, "-dpng", "-S600,300");
        filename_plot_stress = strcat(path_reports,'/',obj.id,'_stress_plot.pdf');
        print (hs,filename_plot_stress, "-dpdf", "-S600,300");
    end % end inner if condition nargin
  end % end stress scen_set condition

 

% -------------    SRRI plotting    ----------------------------- 
elseif (strcmpi(type,'srri'))
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  %fprintf('plot: No SRRI plots exists for scenario set >>%s<<\n',scen_set);
  else
      [ret idx_figure] = get_srri(obj.varhd_rel,tmp_ts,para_object.quantile, ...
					path_reports,obj.id,1,obj.getValue('base'),obj.srri_target); 
	  [ret idx_figure] = get_srri_simple(obj.varhd_rel,tmp_ts,para_object.quantile, ...
					path_reports,obj.id,1,obj.getValue('base'),obj.srri_target); 				
	  fprintf('plot: Plotting SRRI results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);						
  end

 
% -------------    Concentration Risk plotting    ----------------------------- 
elseif (strcmpi(type,'concentration'))
  if ~( strcmpi(scen_set,'base'))
	  %fprintf('plot: No concentration plots exists for scenario set >>%s<<\n',scen_set);
  else
      fprintf('plot: Plotting concentration risk results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);						
	  repstruct = plot_HHI_piecharts(repstruct,path_reports,obj);						
  end
  
  
% -------------    VaR plotting    ----------------------------- 
elseif (strcmpi(type,'var'))
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  %fprintf('plot: No VaR plots exists for scenario set >>%s<<\n',scen_set);
  else
	  printf('plot: Plotting VaR results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);
	  % required input
	  mc = para_object.mc;
	  mc_var_shock = obj.varhd_abs;
	  mc_var_shock_pct = obj.varhd_rel;
	  p_l_absolut_shock = obj.getValue(scen_set);
	  endstaende_reldiff_shock = obj.getValue(scen_set) ./ obj.getValue('base') -1;
	  fund_currency = obj.currency; 	
      plot_vec = 1:1:mc;
      portfolio_shock = obj.getValue(scen_set) - obj.getValue('base');
	  [p_l_absolut_shock scen_order_shock] = sort(portfolio_shock);  
  
      % Plot 1: Histogram and sorted PnL distribution
      hf1 = figure(1);
      clf;
      subplot (1, 2, 1)
		% limit up shocks
		diffshocks = endstaende_reldiff_shock.*100;
		XX=abs(min(diffshocks));
		diffshocks(diffshocks>XX)=XX;	
        hist(diffshocks,40,'facecolor',or_blue);
        %title_string = {'Histogram'; strcat('Portfolio PnL ',scen_set);};
        %title (title_string,'fontsize',12);
        xlabel('Relative shock to portfolio (in Pct)');
      subplot (1, 2, 2)
		plot ( [1, mc], [0, 0], 'color',[0.3 0.3 0.3],'linewidth',1);
		hold on;
        plot ( plot_vec, p_l_absolut_shock,'linewidth',2, 'color',or_blue);
        hold on;
        plot ( [1, mc], [-mc_var_shock, -mc_var_shock], '-','linewidth',1, 'color',or_orange);
        h=get (gcf, 'currentaxes');
        xlabel('MonteCarlo Scenarios');
        set(h,'xtick',[1 mc]);
        set(h,'ytick',[round(min(p_l_absolut_shock)) round(-mc_var_shock/2) 0 ...
							round(mc_var_shock/2) round(max(p_l_absolut_shock))]);
        h=text(0.025*mc,(-0.75*mc_var_shock),num2str(round(-mc_var_shock)));   %add MC Value
        h=text(0.025*mc,(-1.3*mc_var_shock),strcat(num2str(round(mc_var_shock_pct*1000)/10),' %'));   %add MC Value
        ylabel(["Absolute PnL (in ",fund_currency,")"]);
        %title_string = {'Sorted PnL';strcat('Portfolio PnL ',scen_set);};
        %title (title_string,'fontsize',12);
        axis ([1 mc -1.5*mc_var_shock 1.5*mc_var_shock]);
	  % save plotting
	  filename_plot_var = strcat(path_reports,'/',obj.id,'_var_plot.png');
	  print (hf1,filename_plot_var, "-dpng", "-S600,150");
	  filename_plot_var = strcat(path_reports,'/',obj.id,'_var_plot.pdf');
	  print (hf1,filename_plot_var, "-dpdf", "-S600,150");

		% Plot 2: position contributions
	    mc_var_shock = obj.varhd_abs;
	    fund_currency = obj.currency; 	
		pie_chart_values_pos_shock = [];
		pie_chart_values_pos_base = [];
		pie_chart_desc_pos_shock = {};
		pie_chart_desc_pos_base = {};
		% loop through all positions
		for (ii=1:1:length(obj.positions))
			try
			  pos_obj = obj.positions(ii).object;
			  if (isobject(pos_obj))
					pie_chart_values_pos_shock(ii) = (pos_obj.decomp_varhd) ;
					pie_chart_values_pos_base(ii) = pos_obj.getValue('base') ;
					pie_chart_desc_pos_shock(ii) = cellstr( strcat(pos_obj.id));
					pie_chart_desc_pos_base(ii) = cellstr( strcat(pos_obj.id));
			  end
			catch
				printf('Portfolio.print_report: there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
			end
		end
		% prepare vector for piechart:
		[pie_chart_values_sorted_pos_shock sorted_numbers_pos_shock ] = sort(pie_chart_values_pos_shock,'descend');
		[pie_chart_values_sorted_pos_base sorted_numbers_pos_base ] = sort(pie_chart_values_pos_base,'descend');
		
		% plot Top 5 Positions Decomp
		idx = 1; 
		max_positions = 5;
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
		
		% plot Top 5 Positions Basevalue
		idx = 1; 
		max_positions = 5;
		for ii = 1:1:min(length(pie_chart_values_pos_base),max_positions);
			pie_chart_values_plot_pos_base(idx)     = pie_chart_values_sorted_pos_base(ii) ;
			pie_chart_desc_plot_pos_base(idx)       = pie_chart_desc_pos_base(sorted_numbers_pos_base(ii));
			idx = idx + 1;
		end
		% append remaining part
		if (idx == (max_positions + 1))
			pie_chart_values_plot_pos_base(idx)     = obj.getValue('base') - sum(pie_chart_values_plot_pos_base) ;
			pie_chart_desc_plot_pos_base(idx)       = "Other";
		end
		
		pie_chart_values_plot_pos_base = pie_chart_values_plot_pos_base ./ sum(pie_chart_values_plot_pos_base);
		pie_chart_values_plot_pos_shock = pie_chart_values_plot_pos_shock ./ sum(pie_chart_values_plot_pos_shock);
		plot_vec_pie = zeros(1,length(pie_chart_values_plot_pos_shock));
		plot_vec_pie(1) = 1; 
		colormap (colorbrewer_map);
		hf2 = figure(2);
		colormap (colorbrewer_map);
		clf; 
		% Position Basevalue contribution
		subplot (1, 2, 1) 
		desc_cell_pos = strrep(pie_chart_desc_plot_pos_base,"_",""); %remove "_"
		pie(pie_chart_values_plot_pos_base, desc_cell_pos, plot_vec_pie);
		%title_string = strcat('Position contribution to Portfolio Basevalue');
		%title(title_string,'fontsize',12);
		axis ('tic', 'off');   
		
		% Position VaR Contribution
		subplot (1, 2, 2) 
		desc_cell_pos = strrep(pie_chart_desc_plot_pos_shock,"_",""); %remove "_"
		pie(pie_chart_values_plot_pos_shock, desc_cell_pos, plot_vec_pie);
		%title_string = strcat('Position contribution to Portfolio VaR');
		%title(title_string,'fontsize',12);
		axis ('tic', 'off');   
		% save plotting
		filename_plot_var_pos_instr = strcat(path_reports,'/',obj.id,'_var_pos_instr.png');
		print (hf2,filename_plot_var_pos_instr, "-dpng", "-S700,200");
		filename_plot_var_pos_instr = strcat(path_reports,'/',obj.id,'_var_pos_instr.pdf');
		print (hf2,filename_plot_var_pos_instr, "-dpdf", "-S700,200");
  end  
      
% -------------    Market Data Curve plotting    ----------------------------- 
elseif (strcmpi(type,'marketdata'))
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	%fprintf('plot: No mktdata plots exists for scenario set >>%s<<\n',scen_set);
  else
    fprintf('plot: Plotting Market Data results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);		
    hmarket = figure(1);
    clf;
    % get mktdata curves
    ats_scen = round(length(obj.scenario_numbers)/2);
    if isstruct(curve_struct)
      [curve_obj retcode] = get_sub_object(curve_struct,'IR_EUR');
      if retcode == 0
		 printf('plot: Warning: no curve object found for id  >>%s<<\n',obj.id);	
      else
		  subplot (2, 1, 1)
            nodes = any2str(curve_obj.get('nodes'));
			rates_base = curve_obj.get('rates_base');
			rates_mc = curve_obj.get('rates_mc');
			plot (curve_obj.get('nodes'),rates_base,'color',or_blue,"linewidth",1,'marker','x');
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen-2),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen-1),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen+1),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen+2),:),'color',or_orange,"linewidth",0.8);
			hold off;
			grid off;
			title(sprintf ("Curve ID %s", strrep(curve_obj.id,'_','\_')), "fontsize",12);
			xlabel('Nodes (in days)', "fontsize",12);
			ylabel('Rates', "fontsize",12);
		    legend({"Base Scenario Rates","VaR scenarios"},"fontsize",12,"location","southeast");
      end
      [curve_obj retcode] = get_sub_object(curve_struct,'IR_USD');
      if retcode == 0
		 printf('plot: Warning: no curve object found for id  >>%s<<\n',obj.id);	
      else
		  subplot (2, 1, 2)
            nodes = any2str(curve_obj.get('nodes'));
			rates_base = curve_obj.get('rates_base');
			rates_mc = curve_obj.get('rates_mc');
			plot (curve_obj.get('nodes'),rates_base,'color',or_blue,"linewidth",1,'marker','x');
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen-2),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen-1),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen+1),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen+2),:),'color',or_orange,"linewidth",0.8);
			hold off;
			grid off;
			title(sprintf ("Curve ID %s", strrep(curve_obj.id,'_','\_')), "fontsize",12);
			xlabel('Nodes (in days)', "fontsize",12);
			ylabel('Rates', "fontsize",12);
		    legend({"Base Scenario Rates","VaR scenarios"},"fontsize",12,"location","southeast");
      end
      % save plotting
      filename_mktdata_curves = strcat(path_reports,'/',obj.id,'_mktdata_curves.png');
      print (hmarket,filename_mktdata_curves, "-dpng", "-S800,500");
      filename_mktdata_curves = strcat(path_reports,'/',obj.id,'_mktdata_curves.pdf');
      print (hmarket,filename_mktdata_curves, "-dpdf", "-S800,500");
    end
  end      
% -------------------    else    ------------------------------------       
else
	fprintf('plot: Unknown type %s. Doing nothing.\n',type);
end 		

% update report_struct in object
obj = obj.set('report_struct',repstruct);						
end 

% ##############################################################################

% helper function
function yh = smoothts(y,n)

if columns(y) == 1
	y = y';
end
nmean=max(1,round(n/10));
yd = [mean(y(1:nmean)).*ones(1,n),y,mean(y(end-nmean:end)).*ones(1,n)];
yd =    filter(ones(1,n)/n, eye(n,1), yd);
yh = yd(n+1:end-n);

if columns(y) == 1
	yh = yh';
end
end
% ------------------------------------------------------------------------------

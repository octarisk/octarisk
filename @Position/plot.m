% @Position/plot: Plot figures
function obj = plot(obj, para_object,type,scen_set,stresstest_struct = [],curve_struct = [])
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
 
% --------------    Liquidity Plotting     -----------------------------
if (strcmpi(type,'liquidity'))    
  if ( strcmpi(scen_set,'base'))
		fprintf('plot: Plotting liquidity information for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
		cf_dates = obj.get('cf_dates');
		cf_values = obj.getCF('base');
		xx=1:1:length(cf_values);
		plot_desc = datestr(datenum(datestr(para_object.valuation_date)) + cf_dates,'mmm');
		hs = figure(3); 
		clf;
		bar(cf_values, 'facecolor', 'blue');
		h=get (gcf, 'currentaxes');
		set(h,'xtick',xx);
		set(h,'xticklabel',plot_desc);
		xlabel('Cash flow date');
		ylabel(strcat('Cash flow amount (in ',obj.currency,')'));
		title('Projected future cash flows','fontsize',12);
		% save plotting
		filename_plot_cf = strcat(path_reports,'/',obj.id,'_cf_plot.png');
		print (hs,filename_plot_cf, "-dpng", "-S600,200");
  else
	  fprintf('No liquidity plotting possible for scenario set %s === \n',scen_set);  
  end  
    					
% --------------    VaR History Plotting   -----------------------------
elseif (strcmpi(type,'history'))    
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  fprintf('plot: No history VaR plots exists for scenario set >>%s<<\n',scen_set);
  else
	  fprintf('plot: Plotting VaR history results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
	  hist_bv = [obj.hist_base_values,obj.getValue('base')];
	  hist_var = [obj.hist_var_abs,obj.varhd_abs];
	  hist_dates = [obj.hist_report_dates,datestr(para_object.valuation_date)];
	  if (length(hist_bv)>0 && length(hist_bv) == length(hist_var) ...
						&& length(hist_dates) == length(hist_var) ...
						&& length(hist_bv) == length(hist_dates))  	
		hvar = figure(1);
		clf;
		xx=1:1:length(hist_bv);
		hist_var_rel = 100 .* hist_var ./ hist_bv;
		[ax h1 h2] = plotyy (xx,hist_bv, xx,hist_var_rel, @plot, @plot);
        xlabel(ax(1),'Reporting Date','fontsize',12);
        set(ax(1),'xtick',xx);
        set(ax(1),'xlim',[0.8, length(xx)+0.2]);
        set(ax(1),'ylim',[0.98*min(hist_bv), 1.02*max(hist_bv)]);
		set(ax(1),'xticklabel',hist_dates);
		set(ax(2),'xtick',xx);
		set(ax(2),'xlim',[0.8, length(xx)+0.2]);
		set(ax(2),'ylim',[floor(min(hist_var_rel)), ceil(max(hist_var_rel))]);
		set(ax(2),'xticklabel',{});
		set (h1,'linewidth',1);
		set (h1,'marker','o');
		set (h1,'markerfacecolor','auto');
		set (h2,'linewidth',1);
		set (h2,'marker','o');
		set (h2,'markerfacecolor','auto');

		ylabel (ax(1), strcat('Base Value (',obj.currency,')'),'fontsize',12);
		ylabel (ax(2), strcat('VaR relative (in Pct)'),'fontsize',12);
		%~ text (0.5, 0.5, "Base Values (left axis)", ...
		   %~ "color", "red", "horizontalalignment", "center", "parent", ax(1));
		%~ text (4.5, 80, "VaR (right axis)", ...
		   %~ "color", "blue", "horizontalalignment", "center", "parent", ax(2));
		title ('History of Portfolio Base Value and VaR','fontsize',14);
 			
		% save plotting
		filename_plot_varhist = strcat(path_reports,'/',obj.id,'_var_history.png');
		print (hvar,filename_plot_varhist, "-dpng", "-S600,300");		
      else
		fprintf('plot: Plotting VaR history not possible for portfolio >>%s<<, attributes are either not filled or not identical in length\n',obj.id);	
      end	
  end


% -------------    Stress test plotting    ----------------------------- 
elseif (strcmpi(type,'stress'))
  if ~( strcmpi(scen_set,'stress'))
	  fprintf('plot: No stress report exists for scenario set >>%s<<\n',scen_set);
  else
    if (length(stresstest_struct)>0 && nargin == 5)
		fprintf('plot: Plotting stress results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);
		% prepare stresstest plotting and report output
		stresstest_plot_desc = {stresstest_struct.name};
		p_l_relativ_stress      = 100.*(obj.getValue('stress') - ...
						obj.getValue('base') )./ obj.getValue('base');

        xx = 1:1:length(p_l_relativ_stress)-1;
        hs = figure(1,"visible", false); % works for graphic_toolkit gnuplot only, not for qt
        clf;
        barh(p_l_relativ_stress(2:end), 'facecolor', 'blue');
        h=get (gcf, 'currentaxes');
        set(h,'ytick',xx);
        stresstest_plot_desc = strrep(stresstest_plot_desc,"_","");
        set(h,'yticklabel',stresstest_plot_desc(2:end));
        xlabel('Relative PnL (in Pct)');
        title('Stresstest Results','fontsize',12);
        % save plotting
        filename_plot_stress = strcat(path_reports,'/',obj.id,'_stress_plot.png');
        print (hs,filename_plot_stress, "-dpng", "-S600,300");
    end % end inner if condition nargin
  end % end stress scen_set condition

 

% -------------    SRRI plotting    ----------------------------- 
elseif (strcmpi(type,'srri'))
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  fprintf('plot: No SRRI plots exists for scenario set >>%s<<\n',scen_set);
  else
      [ret idx_figure] = get_srri(obj.varhd_rel,tmp_ts,para_object.quantile, ...
								path_reports,obj.id,1,obj.getValue('base')); 
	  fprintf('plot: Plotting SRRI results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);						
  end
 
 
% -------------    VaR plotting    ----------------------------- 
elseif (strcmpi(type,'var'))
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  fprintf('plot: No VaR plots exists for scenario set >>%s<<\n',scen_set);
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
        hist(endstaende_reldiff_shock.*100,40);
        title_string = {'Histogram'; strcat('Portfolio PnL ',scen_set);};
        title (title_string,'fontsize',12);
        xlabel('Relative shock to portflio (in Pct)');
      subplot (1, 2, 2)
        plot ( plot_vec, p_l_absolut_shock,'linewidth',2);
        hold on;
        plot ( [1, mc], [-mc_var_shock, -mc_var_shock], '-','linewidth',1);
        hold on;
        plot ( [1, mc], [0, 0], 'r','linewidth',1);
        h=get (gcf, 'currentaxes');
        xlabel('MonteCarlo Scenarios');
        set(h,'xtick',[1 mc])
        set(h,'ytick',[min(p_l_absolut_shock) -20000 0 20000 max(p_l_absolut_shock)])
        h=text(0.025*mc,(-1.45*mc_var_shock),num2str(round(-mc_var_shock)));   %add MC Value
        h=text(0.025*mc,(-2.1*mc_var_shock),strcat(num2str(round(mc_var_shock_pct*1000)/10),' %'));   %add MC Value
        ylabel(strcat('Absolute PnL (in ',fund_currency,')'));
        title_string = {'Sorted PnL';strcat('Portfolio PnL ',scen_set);};
        title (title_string,'fontsize',12);
		% save plotting
		filename_plot_var = strcat(path_reports,'/',obj.id,'_var_plot.png');
		print (hf1,filename_plot_var, "-dpng", "-S600,200");

		% Plot 2: position contributions
		% reset vectors for charts of riskiest instruments and positions
		pie_chart_values_instr_shock = [];
		pie_chart_desc_instr_shock = {};
		pie_chart_values_pos_shock = [];
		pie_chart_desc_pos_shock = {};
		%~ % loop through all positions
		for (ii=1:1:length(obj.positions))
			try
			  pos_obj = obj.positions(ii).object;
			  if (isobject(pos_obj))
					% Store Values for piechart (Except CASH):
					pie_chart_values_instr_shock(ii) = pos_obj.varhd_abs;
					pie_chart_desc_instr_shock(ii) = cellstr( strcat(pos_obj.id));
					pie_chart_values_pos_shock(ii) = (pos_obj.decomp_varhd) ;
					pie_chart_desc_pos_shock(ii) = cellstr( strcat(pos_obj.id));
			  end
			catch
				printf('Portfolio.plot: there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
			end
		end
	  
		% prepare vector for piechart:
		[pie_chart_values_sorted_instr_shock sorted_numbers_instr_shock ] = sort(pie_chart_values_instr_shock,'descend');
		[pie_chart_values_sorted_pos_shock sorted_numbers_pos_shock ] = sort(pie_chart_values_pos_shock,'descend');
		idx = 1; 

		% plot only maximum 6 highest values
		%for ii = length(pie_chart_values_instr_shock):-1:max(0,length(pie_chart_values_instr_shock)-5)
		for ii = 1:1:min(length(pie_chart_values_instr_shock),6)
			pie_chart_values_plot_instr_shock(idx)   = pie_chart_values_sorted_instr_shock(ii) ;
			pie_chart_desc_plot_instr_shock(idx)     = pie_chart_desc_instr_shock(sorted_numbers_instr_shock(ii));
			pie_chart_values_plot_pos_shock(idx)     = pie_chart_values_sorted_pos_shock(ii) ;
			pie_chart_desc_plot_pos_shock(idx)       = pie_chart_desc_pos_shock(sorted_numbers_pos_shock(ii));
			idx = idx + 1;
		end
		plot_vec_pie = zeros(1,length(pie_chart_values_plot_instr_shock));
		plot_vec_pie(1) = 1;
		pie_chart_values_plot_instr_shock = pie_chart_values_plot_instr_shock ./ sum(pie_chart_values_plot_instr_shock);
		pie_chart_values_plot_pos_shock = pie_chart_values_plot_pos_shock ./ sum(pie_chart_values_plot_pos_shock);
		  
		hf2 = figure(2);
		clf;  
		subplot (1, 2, 1)
		desc_cell_pos = strrep(pie_chart_desc_plot_pos_shock,"_",""); %remove "_"
		pie(pie_chart_values_plot_pos_shock, desc_cell_pos, plot_vec_pie);
		title_string = strcat('Position contribution to VaR',scen_set);
		title(title_string,'fontsize',12);
		axis ('tic', 'off');    
		subplot (1, 2, 2)
		desc_cell_instr = strrep(pie_chart_desc_plot_instr_shock,"_","");
		pie(pie_chart_values_plot_instr_shock, desc_cell_instr , plot_vec_pie);
		%pareto(pie_chart_values_plot_instr_shock,desc_cell_instr);
		title_string = strcat('Riskiest Positions (Standalone VaR',scen_set,')');
		title(title_string,'fontsize',12);
		axis ('tic', 'off');
		% save plotting
		filename_plot_var_pos_instr = strcat(path_reports,'/',obj.id,'_var_pos_instr.png');
		print (hf2,filename_plot_var_pos_instr, "-dpng", "-S600,200");
  end  
      
% -------------    Market Data Curve plotting    ----------------------------- 
elseif (strcmpi(type,'marketdata'))
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	fprintf('plot: No mktdata plots exists for scenario set >>%s<<\n',scen_set);
  else
    fprintf('plot: Plotting Market Data results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);		
    hmarket = figure(1);
    clf;
    % get mktdata curves
    if isstruct(curve_struct)
      [curve_obj retcode] = get_sub_object(curve_struct,'IR_EUR');
      if retcode == 0
		 printf('plot: Warning: no curve object found for id  >>%s<<\n',obj.id);	
      else
		  subplot (2, 1, 1)
            nodes = any2str(curve_obj.get('nodes'));
			rates_base = curve_obj.get('rates_base');
			rates_mc = curve_obj.get('rates_mc');
			plot (curve_obj.get('nodes'),rates_base,'color','blue',"linewidth",1,'marker','x');
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(1),:),'color',[0.5 0.5 0.5],"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(2),:),'color',[0.5 0.5 0.5],"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(4),:),'color',[0.5 0.5 0.5],"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(5),:),'color',[0.5 0.5 0.5],"linewidth",0.8);
			hold off;
			grid off;
			title(sprintf ("Curve ID %s", strrep(curve_obj.id,'_','\_')), "fontsize",12);
			xlabel('Nodes (in days)', "fontsize",12);
			ylabel('Rates', "fontsize",12);
		    legend('Base Scenario Rates','VaR scenarios',"location","southeast");
      end
      [curve_obj retcode] = get_sub_object(curve_struct,'IR_USD');
      if retcode == 0
		 printf('plot: Warning: no curve object found for id  >>%s<<\n',obj.id);	
      else
		  subplot (2, 1, 2)
            nodes = any2str(curve_obj.get('nodes'));
			rates_base = curve_obj.get('rates_base');
			rates_mc = curve_obj.get('rates_mc');
			plot (curve_obj.get('nodes'),rates_base,'color','blue',"linewidth",1,'marker','x');
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(1),:),'color',[0.5 0.5 0.5],"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(2),:),'color',[0.5 0.5 0.5],"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(4),:),'color',[0.5 0.5 0.5],"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(5),:),'color',[0.5 0.5 0.5],"linewidth",0.8);
			hold off;
			grid off;
			title(sprintf ("Curve ID %s", strrep(curve_obj.id,'_','\_')), "fontsize",12);
			xlabel('Nodes (in days)', "fontsize",12);
			ylabel('Rates', "fontsize",12);
		    legend('Base Scenario Rates','VaR scenarios',"location","southeast");
      end
      % save plotting
      filename_mktdata_curves = strcat(path_reports,'/',obj.id,'_mktdata_curves.png');
      print (hmarket,filename_mktdata_curves, "-dpng", "-S800,500");
    end
  end      
% -------------------    else    ------------------------------------       
else
	fprintf('plot: Unknown type %s. Doing nothing.\n',type);
end 								
end 

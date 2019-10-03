function retcode = plot_hist_var_simple(obj,para_object,path_reports)

retcode = 1;
hist_bv = [obj.hist_base_values,obj.getValue('base')];
hist_var = [obj.hist_var_abs,obj.varhd_abs];
hist_dates = [obj.hist_report_dates,datestr(para_object.valuation_date)];
if isempty(obj.hist_cashflow)
	cashinoutflow = [zeros(1,numel(hist_dates)), obj.current_cashflow];
else
	cashinoutflow = [obj.hist_cashflow, obj.current_cashflow];	  
end

  
% set colors
or_green = [0.56863   0.81961   0.13333]; 
or_blue  = [0.085938   0.449219   0.761719]; 
or_orange =  [0.945312   0.398438   0.035156];
light_blue = [0.50000   0.69922   0.99609];


if (numel(hist_bv)>0 && numel(hist_bv) == numel(hist_var))  	
		
		% take only into account 6 last reporting dates
		len = numel(hist_bv);
		maxdates = 2;
		idxstart = 1+len-min(maxdates,len);
		hist_bv = hist_bv(idxstart:end);
		cashinoutflow = cashinoutflow(idxstart:end);
		hist_var = hist_var(idxstart:end);
		hist_dates = hist_dates(idxstart:end);
		nextmonthend = datestr(addtodatefinancial(datenum(hist_dates(end)),1,'months'));
		
		% start plotting
		hvar = figure(1);
		clf;
		xx=1:1:length(hist_bv)+1;
		annotation("textbox",[0.7,0.18,0.1,0.1],"string", ...
				"1 in 1000 event","edgecolor",'white', ...
				"backgroundcolor","white","color",or_orange,"fontsize",14);
		
		annotation("textbox",[0.7,0.43,0.1,0.1],"string", ...
				"most events","edgecolor",'white', ...
				"backgroundcolor","white","color",or_blue,"fontsize",14);
						
		h1 = plot (xx(1:end-1),hist_bv);
		ax=get (gcf, 'currentaxes');
		hold on;
		xlabel(ax,'Reporting Date','fontsize',12);
        set(ax,'visible','on');
        set(ax,'layer','top');
        set(ax,'xtick',xx);
        set(ax,'xlim',[0.8, length(xx)+0.2]);
        set(ax,'ylim',[0.98*min(hist_bv - sqrt(2).*hist_var + cashinoutflow), 1.02*max(hist_bv + sqrt(2).*hist_var)]);
		set(ax,'xticklabel',[hist_dates,nextmonthend]);
		ylabel (ax, strcat('Base Value (',obj.currency,')'),'fontsize',12);
		set (h1,'linewidth',4);
		set (h1,'color',or_blue);
		set (h1,'marker','o');
		set (h1,'markersize',12);
		set (h1,'markerfacecolor',or_blue);

		
		% doing a replot
		var_bv_min = zeros(1,numel(hist_bv));
		%for kk=numel(hist_bv)-1:1:numel(hist_bv)-1
		kk=numel(hist_bv)-1;
		dip = numel(busdays(datenum(hist_dates(kk)),datenum(hist_dates(kk+1))));
		dd = [kk:1/dip:kk+1];
		zz = [0:1/dip:1];
		var_limit= [hist_bv(kk) - hist_var(kk) .* sqrt(dip) ./ ...
				sqrt(10).* sqrt(zz)] + ...
				zz.* cashinoutflow(kk+1);
		var_bv_min(kk) = var_limit(end);
		
		dip = 10;
		kk = numel(hist_bv);
		dd = [kk:1/dip:kk+1];
		zz = [0:1/dip:1];
		var_limit_lower = [hist_bv(kk) - hist_var(kk) .* sqrt(dip) ./ sqrt(10).* sqrt(zz)];	
		var_limit_upper = [hist_bv(kk) + hist_var(kk) .* sqrt(dip) ./ sqrt(10).* sqrt(zz)];	
		plot(dd,var_limit_lower,'color',or_blue,'linestyle','--','linewidth',4);
		hold on;
		plot(dd,var_limit_upper,'color',or_blue,'linestyle','--','linewidth',4);
		hold off;
		
		%~ % save plotting
		filename_plot_varhist = strcat(path_reports,'/',obj.id,'_var_history_simple.png');
		print (hvar,filename_plot_varhist, "-dpng", "-S400,300");	
		filename_plot_varhist = strcat(path_reports,'/',obj.id,'_var_history_simple.pdf');
		print (hvar,filename_plot_varhist, "-dpdf", "-S400,300");	
		
else
	retcode = 0;
	fprintf('plot: Plotting VaR history not possible for portfolio >>%s<<, attributes are either not filled or not identical in length\n',obj.id);	
end

end

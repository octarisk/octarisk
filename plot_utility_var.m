%# Copyright (C) 2025 Stefan Schloegl <schinzilord@octarisk.com>
%#
%# This program is free software; you can redistribute it and/or modify it under
%# the terms of the GNU General Public License as published by the Free Software
%# Foundation; either version 3 of the License, or (at your option) any later
%# version.
%#
%# This program is distributed in the hope that it will be useful, but WITHOUT
%# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
%# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
%# details.

%# -*- texinfo -*-
%# @deftypefn {Function File} {@var{retcode}=} plot_utility_var(@var{obj}, @var{para_object}, @var{path_reports})
%#
%# Plot VAR utility function calibrated by logarithmic model. 
%# Utility beta, initial wealth and initial VaR are used to extrapolate
%# VAR around given actual wealth. Differences between actual VAR and
%# utility VAR are calculated and printed to the plot.
%# 
%# @end deftypefn

function retcode = plot_utility_var(obj,para_object,path_reports);

retcode = 1;

if nargin == 3
	if obj.value_base > 10000000
		wealth_max = ceil(obj.value_base/10000000)*10000000;
		wealth = linspace(0,wealth_max,100000);
	elseif obj.value_base > 1000000
		wealth_max = ceil(obj.value_base/1000000)*1000000;
		wealth = linspace(0,wealth_max,10000);
	elseif obj.value_base > 100000
		wealth_max = ceil(obj.value_base/100000)*100000;
		wealth = linspace(0,wealth_max,1000);
	elseif obj.value_base > 10000
		wealth_max = ceil(obj.value_base/10000)*10000;
		wealth = linspace(0,wealth_max,100);
	end					
	
	hist_bv = [obj.hist_base_values];
	hist_var = [obj.hist_var_abs];

	[VaR_tol VaR_rel] = get_utility_tolerable_var(para_object.utility_wealth_initial, ...
												para_object.utility_var_initial , ...
												para_object.utility_beta, ...
												wealth);

	% actual utility var:
	var_utility_act = get_utility_tolerable_var(para_object.utility_wealth_initial, ...
												para_object.utility_var_initial , ...
												para_object.utility_beta, ...
												obj.value_base);
	var_util_diff = obj.varhd_abs - var_utility_act;	% difference between actual var and utility var
	if var_util_diff > 0
		diff_str = ['WARNING: Actual VaR ',any2str(round(var_util_diff)),' ',obj.currency,' larger than utility VaR. Consider de-risking.'];
	else
		diff_str = ['Actual VaR ',any2str(round(abs(var_util_diff))),' ',obj.currency,' smaller than utility VaR. Consider re-risking'];
	end
	
	% plot limits:
	var_max = ceil(VaR_tol(end)/10000)*10000;
	
	% set colors
	or_green = [0.56863   0.81961   0.13333]; 
	or_blue  = [0.085938   0.449219   0.761719]; 
	or_orange =  [0.945312   0.398438   0.035156];
	light_blue = [0.50000   0.69922   0.99609];

	% plotting
	uvar = figure(1);
	clf;
	h1 = plot(wealth,VaR_tol,'color',or_blue,'linestyle','-','linewidth',4);
	ax=get (gcf, 'currentaxes');
	hold on;

	xlabel(ax,['Wealth (in ',obj.currency,')'],'fontsize',12);
	set(ax,'visible','on');
	set(ax,'layer','top');
	set(ax,'xlim',[0.0, wealth(end)]);
	set(ax,'ylim',[0, max(1.1*obj.varhd_abs,VaR_tol(end))]);
	%set(ax,'xticklabel','xx');
	%set(ax,'xtick',[wealth_max/4, wealth_max/2, 3/4*wealth_max,wealth_max]);
	%set(ax,'xticklabel',{'-200','-100', '0', '100', '200'},'fontsize',9);
	ylabel (ax, ['Tolerable VaR (in ',obj.currency,')'],'fontsize',12);
	set (h1,'linewidth',4);
	h2 = plot(obj.value_base,obj.varhd_abs,"ro");
	set (h2,'color',or_blue);
	set (h2,'marker','o');
	set (h2,'markersize',12);
	set (h2,'markerfacecolor',or_orange);
	annotation("textbox",[0.15,0.15,0.2,0.2],"string", ...
				diff_str,"edgecolor",'white', ...
				"backgroundcolor","white","color",or_orange,"fontsize",12);
	
	if numel(hist_var)>0 && numel(hist_bv) == numel(hist_var)	
		h3 = plot(hist_bv,hist_var,"go-");
	end	
	hold off;

	% save plotting
	filename_plot_var_utility = strcat(path_reports,'/',obj.id,'_var_utility.png');
	print (uvar,filename_plot_var_utility, "-dpng", "-S800,600");	
	filename_plot_var_utility = strcat(path_reports,'/',obj.id,'_var_utility.pdf');
	print (uvar,filename_plot_var_utility, "-dpdf", "-S800,600");	
		

else
	retcode = 0;
	fprintf('plot: Plotting Utility VaR not possible for portfolio >>%s<<, attributes are not filled. \n',obj.id);	
end
		
end




% Helper function

function [VaR_tol VaR_rel] = get_utility_tolerable_var(wealth_0,var_0,beta,wealth)
 
 if nargin < 4 || nargin > 4
    print_usage ();
 end
 
 
VaR_tol = var_0 * (wealth/wealth_0) .^ beta; 
VaR_rel = VaR_tol / wealth;
 
end




% =======
%~ function retcode = plot_utility_var();
%~ retcode = 1;

%~ if nargin == 0

	%~ path_reports = '/Users/schinzilord/Documents/Programmierung/Octavedateien'
	%~ obj.id = 'Private'
	%~ obj.currency = 'EUR'
	%~ obj.value_base = 450000;
	%~ obj.varhd_abs = 43000;

	%~ para_object.utility_beta = 0.77;
	%~ para_object.utility_wealth_initial = 1360000;
	%~ para_object.utility_var_initial = 110000;
	
	%~ obj.hist_base_values = [350000,400000,425000]
	%~ obj.hist_var_abs = [38000,39500,41252]
% =======

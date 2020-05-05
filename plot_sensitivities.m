%# Copyright (C) 2019 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {@var{repstruct} =} plot_sensitivities (@var{obj}, @var{repstruct}, @var{path_reports})
%# Plot interest rate sensitivities of assets, liabilities and total portfolio.
%#
%# @seealso{}
%# @end deftypefn

function repstruct = plot_sensitivities(obj,repstruct,path_reports)

or_green = [0.56863   0.81961   0.13333]; 
or_blue  = [0.085938   0.449219   0.761719]; 
or_orange =  [0.945312   0.398438   0.035156];

bv_a = repstruct.port_assets_basevalue;
bv_l = repstruct.port_liabilities_basevalue;
dur_a = repstruct.port_asset_duration;
dur_l = repstruct.port_liab_duration;
convex_a = repstruct.port_asset_convexity;
convex_l = repstruct.port_liab_convexity;
bv_p = bv_a + bv_l;
x = linspace(-0.02,0.02,101);

if (abs(repstruct.port_liabilities_basevalue - repstruct.port_basevalue_dtl) > 0.01) % plot asset and liability 
	y_a = bv_a .* evaluate_sensi(x,dur_a,convex_a) / 1000;
	y_l = bv_l .* evaluate_sensi(x,dur_l,convex_l) / 1000;
	y_p = y_a + y_l;
	hf = figure(1);
	clf; 
	plot (x,y_a,'linewidth',1.2,'color',or_orange);
	hold on;
	plot (x,y_l,'linewidth',1.2,'color',or_green);
	hold on;
	plot (x,y_p,'linewidth',1.2,'color',or_blue);
	hold off;
	h=get (gcf, 'currentaxes');
	set(h,'xtick',[-0.02 -0.01 0 0.01 0.02]);
	set(h,'xticklabel',{'-200','-100', '0', '100', '200'},'fontsize',9);
	desc_cell = {'Assets','Liabilities','Total Portfolio'};
	legend(desc_cell,'fontsize',9,'location','northeast');	
	%title('Asset - Liability IR sensitivity mismatch','fontsize',12);
	xlabel('Parallel IR shock (in bp)','fontsize',9);
	ytext = ['Profit or Loss (in k',obj.currency,')'];
	ylabel(ytext,'fontsize',9);
	grid on;
else
	y_a = bv_a .* evaluate_sensi(x,dur_a,convex_a) / 1000;
	y_p = y_a;
	hf = figure(1);
	clf; 
	plot (x,y_p,'linewidth',1.2,'color',or_blue);
	hold off;
	h=get (gcf, 'currentaxes');
	set(h,'xtick',[-0.02 -0.01 0 0.01 0.02]);
	set(h,'xticklabel',{'-200','-100', '0', '100', '200'},'fontsize',9);
	desc_cell = {'Total Portfolio'};
	legend(desc_cell,'fontsize',9,'location','northeast');	
	%title('Portfolio IR sensitivity ','fontsize',12);
	xlabel('Parallel IR shock (in bp)','fontsize',9);
	ytext = ['Profit or Loss (in k',obj.currency,')'];
	ylabel(ytext,'fontsize',9);
	grid on;
end
% save plotting
	filename_plot_aa = strcat(path_reports,'/',obj.id,'_ir_sensitivity_chart.png');
	print (hf,filename_plot_aa, "-dpng", "-S400,250");
	filename_plot_aa = strcat(path_reports,'/',obj.id,'_ir_sensitivity_chart.pdf');
	print (hf,filename_plot_aa, "-dpdf", "-S400,250");
end

% ##############################################################################
function [y] = evaluate_sensi(x,dur,convex)
	y = -dur .* x + 0.5 .* x.^2 .* convex;	
end

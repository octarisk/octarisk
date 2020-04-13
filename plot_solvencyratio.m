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
%# @deftypefn {Function File} {@var{m} =} plot_solvencyratio (@var{vola_act}, @var{filepath})
%# Plot solvency ratio and show relationship to safety zones.
%#
%# @seealso{}
%# @end deftypefn

function [ret idx_figure] = plot_solvencyratio(sratio,filepath="",port_id="",idx_figure=1)
or_green = [0.56863   0.81961   0.13333]; 
or_blue  = [0.085938   0.449219   0.761719]; 
or_orange =  [0.945312   0.398438   0.035156];
color_red = [252,141,89]./256;
color_orange = [255,255,191]./256;
color_green = [145,207,96]./256;
color_grey = [0.8 0.8 0.8];
	
try
	if (strcmpi(filepath,""))
		saveflag = false;
	else
		saveflag = true;
	end
	sratio_act = round(sratio*100);
	sratio = max(sratio_act,0); 
	% plot
	h1 = figure(idx_figure);
	clf;
	axis off;
	r1 = rectangle ("Position", [0.1, 0.1, 0.2, 0.2], "Curvature", [0.0, 0.0]);
	hold on;
	r3 = rectangle ("Position", [0.3, 0.1, 0.2, 0.2], "Curvature", [0.0, 0.0]);
	hold on;
	r5 = rectangle ("Position", [0.5, 0.1, 0.2, 0.2], "Curvature", [0.0, 0.0]);
	hold on;
	r7 = rectangle ("Position", [0.7, 0.1, 0.1, 0.2], "Curvature", [0.0, 0.0]);

	set(r1,"facecolor",color_red);
	set(r3,"facecolor",color_orange);
	set(r5,"facecolor",color_green);
	set(r7,"facecolor",color_grey);

	% plot actual solvency ratio
	rectangle ("Position", [0.1+min(0.2*sratio/100,0.695), 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", or_blue);      

	% plot label
	hold on;
	curr_label = strcat(num2str(sratio_act),"%");
	text( 0.08+min(0.2*sratio/100,0.695),0.33,curr_label,"fontsize", 15,"color", or_blue);
	hold off;
	text( 0.15,0.082,"0-100%","fontsize", 15,"color", "black");
	text( 0.35,0.082,"100-200%","fontsize", 15,"color", "black");
	text( 0.55,0.082,"200-300%","fontsize", 15,"color", "black");
	text( 0.72,0.082,">300%","fontsize", 15,"color", "black");
	text( 0.17,0.20,"Action","fontsize", 20,"rotation",0);
	text( 0.37,0.20,"Alert","fontsize", 20,"rotation",0);
	text( 0.56,0.20,"Comfort","fontsize", 20,"rotation",0);
	text( 0.715,0.20,"Riskier","fontsize", 20,"rotation",0);
	titlestring = ["Solvency Ratio"]; 
	title (titlestring,"fontsize", 16);
	 
	% plot png to file
	if (saveflag == true)
		filename_h1 = strcat(filepath,"/",port_id,"_risk_scale.png");
		print (h1, filename_h1, "-dpng", "-S800,150");
		filename_h2 = strcat(filepath,"/",port_id,"_risk_scale.pdf");
		print (h1, filename_h2, "-dpdf", "-S800,150");
	end
	ret = 0;
catch
	ret = 1;
	fprintf('plot_solvencyratio: there was an error: %s\n',lasterr);
end

end

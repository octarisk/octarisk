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
%# @deftypefn {Function File} {@var{m} =} get_srri (@var{vola_act}, @var{horizon}, @var{quantile}, @var{filepath})
%# Classify portfolio VaR according to SRRI classes and given time horizon and quantile.
%# Return particular class and plots the data to file in filepath.
%#
%# @seealso{}
%# @end deftypefn

function [ret idx_figure] = get_srri_simple(vola_act,horizon=250,quantile=normcdf(1),filepath="",port_id="",idx_figure=1,basevalue=0,srri_target=0)
try
	if (strcmpi(filepath,""))
		saveflag = false;
	else
		saveflag = true;
	end
	vola_act = abs(vola_act);
	[act_lvl vola_limit]= get_srri_level(vola_act,horizon,quantile);
	vola_limit = 100.*vola_limit;
	vola_limit = [vola_limit(2:end),max(2*max(vola_limit),100*vola_act)+5];
	vola_limit_shifted = [0, vola_limit(1:end-1)];
	or_blue  = [0.085938   0.449219   0.761719]; 
	% plot
	h2 = figure(1);
	clf;
	 axis off;
	r1 = rectangle ("Position", [0.1, 0.1, 0.1, 0.2], "Curvature", [0.0, 0.0]);
	hold on;
	r2 = rectangle ("Position", [0.2, 0.1, 0.1, 0.2], "Curvature", [0.0, 0.0]);
	hold on;
	r3 = rectangle ("Position", [0.3, 0.1, 0.1, 0.2], "Curvature", [0.0, 0.0]);
	hold on;
	r4 = rectangle ("Position", [0.4, 0.1, 0.1, 0.2], "Curvature", [0.0, 0.0]);
	hold on;
	r5 = rectangle ("Position", [0.5, 0.1, 0.1, 0.2], "Curvature", [0.0, 0.0]);
	hold on;
	r6 = rectangle ("Position", [0.6, 0.1, 0.1, 0.2], "Curvature", [0.0, 0.0]);
	hold on;
	r7 = rectangle ("Position", [0.7, 0.1, 0.1, 0.2], "Curvature", [0.0, 0.0]);
	

	switch (act_lvl)
	  case 1
		set(r1,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.1+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", or_blue); 
	  case 2
		set(r2,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.2+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", or_blue); 
	  case 3
		set(r3,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.3+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", or_blue); 
	  case 4
		set(r4,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.4+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", or_blue); 
	  case 5
		set(r5,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.5+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", or_blue); 
	  case 6
		set(r6,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.6+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", or_blue);
	  case 7
		set(r7,"facecolor",[0.8 0.8 0.8]); 
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.7+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", or_blue);       
	end
	hold on;
	% plot current SRRI level
				 
	annotation ("doublearrow", [0.15,0.85], [0.85,0.85])
	hold off;
	text( 0.14,0.35,"lower risk","fontsize", 15);
	text( 0.63,0.35,"higher risk","fontsize", 15);
	text( 0.135,0.20,"1","fontsize", 40);
	text( 0.235,0.20,"2","fontsize", 40);
	text( 0.335,0.20,"3","fontsize", 40);
	text( 0.435,0.20,"4","fontsize", 40);
	text( 0.535,0.20,"5","fontsize", 40);
	text( 0.635,0.20,"6","fontsize", 40);
	text( 0.735,0.20,"7","fontsize", 40);
	%title ("Risk Classification","fontsize", 16);
	 
	% plot png to file
	if (saveflag == true)
		filename_h2 = strcat(filepath,"/",port_id,"_SRRI_classes_scale_simple.png");
		print (h2, filename_h2, "-dpng", "-S800,150");
		filename_h2 = strcat(filepath,"/",port_id,"_SRRI_classes_scale_simple.pdf");
		print (h2, filename_h2, "-dpdf", "-S800,150");
	end
	ret = 0;
catch
	ret = 1;
	fprintf('get_srri_simple: there was an error: %s\n',lasterr);
end

end

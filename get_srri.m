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

function [ret idx_figure] = get_srri(vola_act,horizon=250,quantile=normcdf(1),filepath="",port_id="",idx_figure=1,basevalue=0)
try
	if (strcmpi(filepath,""))
		saveflag = false;
	else
		saveflag = true;
	end
	vola_act = abs(vola_act);
	[act_lvl vola_limit]= get_level(vola_act,horizon,quantile);
	vola_limit = 100.*vola_limit;
	vola_limit = [vola_limit(2:end),max(2*max(vola_limit),100*vola_act)+5];
	vola_limit_shifted = [0, vola_limit(1:end-1)];

	% plot
	h1 = figure(idx_figure);
	clf;
	if ( basevalue == 0)
		val = vola_limit;
		val_shifted = vola_limit_shifted;
		current = vola_act*100;
		y_label = 'VaR (in Pct)';
		pct_label = "%";
	else
		val = round(basevalue .* vola_limit ./ 100);
		val_shifted = round(basevalue .* vola_limit_shifted ./ 100);
		current = round(basevalue .* vola_act);
		y_label = 'VaR (absolute)';
		pct_label = "";
	end
	
	bar (val, "stacked","facecolor",[0.7 0.7 0.7],"edgecolor",[1 1 1]);
	hold on;
	bar (val_shifted, "stacked","facecolor",[1 1 1],"edgecolor",[1 1 1]);
	hold on;
	plot(act_lvl,current,'*','linewidth',5,'color','red');
	hold off;
	xlabel('SRRI level','fontsize',15);
	ylabel(y_label,'fontsize',15);
	title ("Indexing of Portfolio VaR inside SRRI classes",'fontsize',16);

	idx_figure = idx_figure + 1;
	h2 = figure(2);
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
		rectangle ("Position", [0.1+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", "red"); 
		% plot additional text
		curr_label = strcat(num2str(current),pct_label);
		lower_label = strcat(num2str(val_shifted(act_lvl)),pct_label);
		upper_label = strcat(num2str(val(act_lvl)),pct_label);
		text( 0.1+pixelshift-0.005,0.325,curr_label,"fontsize", 15,"color", "r");
		text( 0.1-0.03,0.08,lower_label,"fontsize", 15);
		text( 0.2-0.03,0.08,upper_label,"fontsize", 15);
	  case 2
		set(r2,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.2+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", "red"); 
		% plot additional text
		curr_label = strcat(num2str(current),pct_label);
		lower_label = strcat(num2str(val_shifted(act_lvl)),pct_label);
		upper_label = strcat(num2str(val(act_lvl)),pct_label);
		text( 0.2+pixelshift-0.005,0.325,curr_label,"fontsize", 15,"color", "r");
		text( 0.2-0.03,0.08,lower_label,"fontsize", 15);
		text( 0.3-0.03,0.08,upper_label,"fontsize", 15);
	  case 3
		set(r3,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.3+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", "red"); 
		% plot additional text
		curr_label = strcat(num2str(current),pct_label);
		lower_label = strcat(num2str(val_shifted(act_lvl)),pct_label);
		upper_label = strcat(num2str(val(act_lvl)),pct_label);
		text( 0.3+pixelshift-0.005,0.325,curr_label,"fontsize", 15,"color", "r");
		text( 0.3-0.03,0.08,lower_label,"fontsize", 15);
		text( 0.4-0.03,0.08,upper_label,"fontsize", 15);
	  case 4
		set(r4,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.4+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", "red"); 
		
		% plot additional text
		curr_label = strcat(num2str(current),pct_label);
		lower_label = strcat(num2str(val_shifted(act_lvl)),pct_label);
		upper_label = strcat(num2str(val(act_lvl)),pct_label);
		text( 0.4+pixelshift-0.005,0.325,curr_label,"fontsize", 15,"color", "r");
		text( 0.4-0.03,0.08,lower_label,"fontsize", 15);
		text( 0.5-0.03,0.08,upper_label,"fontsize", 15);
		
	  case 5
		set(r5,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.5+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", "red"); 
		% plot additional text
		curr_label = strcat(num2str(current),pct_label);
		lower_label = strcat(num2str(val_shifted(act_lvl)),pct_label);
		upper_label = strcat(num2str(val(act_lvl)),pct_label);
		text( 0.5+pixelshift-0.005,0.325,curr_label,"fontsize", 15,"color", "r");
		text( 0.5-0.03,0.08,lower_label,"fontsize", 15);
		text( 0.6-0.03,0.08,upper_label,"fontsize", 15);
	  case 6
		set(r6,"facecolor",[0.8 0.8 0.8]);
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.6+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", "red");
		% plot additional text
		curr_label = strcat(num2str(current),pct_label);
		lower_label = strcat(num2str(val_shifted(act_lvl)),pct_label);
		upper_label = strcat(num2str(val(act_lvl)),pct_label);
		text( 0.6+pixelshift-0.005,0.325,curr_label,"fontsize", 15,"color", "r");
		text( 0.6-0.03,0.08,lower_label,"fontsize", 15);
		text( 0.7-0.03,0.08,upper_label,"fontsize", 15);
	  case 7
		set(r7,"facecolor",[0.8 0.8 0.8]); 
		upper_limit = vola_limit(act_lvl);
		lower_limit = vola_limit_shifted(act_lvl);
		distance = upper_limit - lower_limit;
		pixelshift = ((vola_act*100 - lower_limit) / distance) * 0.1;
		rectangle ("Position", [0.7+pixelshift-0.005, 0.10, 0.005, 0.2], "Curvature", [0.0, 0.0], "facecolor", "red");      
		% plot additional text
		curr_label = strcat(num2str(current),pct_label);
		lower_label = strcat(num2str(val_shifted(act_lvl)),pct_label);
		upper_label = strcat(num2str(val(act_lvl)),pct_label);
		text( 0.7+pixelshift-0.005,0.325,curr_label,"fontsize", 15,"color", "r");
		text( 0.7-0.03,0.08,lower_label,"fontsize", 15);
		text( 0.8-0.03,0.08,upper_label,"fontsize", 15);   
	end
	hold on;
	% plot current SRRI level
				 
	annotation ("doublearrow", [0.15,0.88], [0.88,0.88])
	hold off;
	text( 0.14,0.40,"lower risk","fontsize", 15);
	text( 0.68,0.40,"higher risk","fontsize", 15);
	text( 0.135,0.20,"1","fontsize", 40);
	text( 0.235,0.20,"2","fontsize", 40);
	text( 0.335,0.20,"3","fontsize", 40);
	text( 0.435,0.20,"4","fontsize", 40);
	text( 0.535,0.20,"5","fontsize", 40);
	text( 0.635,0.20,"6","fontsize", 40);
	text( 0.735,0.20,"7","fontsize", 40);
	time = strcat(num2str(horizon),"days");
	titlestring = strcat("SRRI classification"); %,time,",",num2str(quantile*100),"%)");
	title (titlestring,"fontsize", 16);
	 
	% plot png to file
	if (saveflag == true)
		filename_h1 = strcat(filepath,"/",port_id,"_SRRI_classes_chart.png");
		filename_h2 = strcat(filepath,"/",port_id,"_SRRI_classes_scale.png");
		print (h1, filename_h1, "-dpng", "-S800,300");
		print (h2, filename_h2, "-dpng", "-S800,150");
	end
	ret = 0;
catch
	ret = 1;
	fprintf('get_srri: there was an error: %s\n',lasterr);
end

end



function [srri vola_limit] = get_level(vola,horizon,quantile)
% SRRI is specified on 250day horizon for standard deviation = 1
% vola = 0.15855 --> norminv(vola) = 1
	if ~(nargin == 3)
		error('Invalid nargin');
	end
	if ( vola < 0)
		error('Negative volatility not allowed');
	end
	srri = 1;
	levels =  [1,2,3,4,5,6,7];
	vola_limit = [0,0.005,0.02,0.05,0.1,0.15,0.25];

	% scale vola_limit
	days_in_year = 250;
	time_scale = sqrt(horizon)/sqrt(days_in_year);
	quantile_scale = abs(norminv(quantile));

	vola_limit = vola_limit .* time_scale.* quantile_scale;

	for ii=1:1:length(vola_limit)
		if vola >= vola_limit(ii)
			srri = levels(ii);
		else
			return;
		end
	end


end

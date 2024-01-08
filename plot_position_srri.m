%# Copyright (C) 2023 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {@var{retcode} =} plot_position_srri (@var{path_reports}, @var{obj})
%# Plot barchart with relative asset exposure to SRRI levels per position.
%#
%# @seealso{}
%# @end deftypefn


function retcode = plot_position_srri(path_reports,obj)

srri_classes = [1,2,3,4,5,6,7];
srri_exp = [0,0,0,0,0,0,0];

for (ii=1:1:length(obj.positions))
	try
		pos_obj = obj.positions(ii).object;
		if (isobject(pos_obj))
			if (strcmpi(pos_obj.balance_sheet_item,'Asset'))
				%pos_val = pos_obj.value_base;
				%pos_srri = pos_obj.srri_pos;
				srri_exp(pos_obj.srri_pos) = srri_exp(pos_obj.srri_pos) + pos_obj.value_base;
			end
		end
	catch
		printf('plot_position_srri: there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
	end
end		

srri_exp = 100 * srri_exp ./ sum(srri_exp);
labels = {'1','2','3','4','5','6','7'};

% plot stacked bar chart
clf;
hf = figure(1);

hBar = bar([srri_exp],"stacked");

xlabel('SRRI Classes');
ylabel('SRRI Exposure relative (in Pct.)');
title(sprintf('SRRI position exposure'));

set(gca, 'XTickLabel', labels) ;
hold off;
    
% save plotting
filename_plot  = strcat(path_reports,'/',obj.id,'_SRRI_pos_bars.png');
print (hf,filename_plot, "-dpng", "-S700,400");
filename_plot = strcat(path_reports,'/',obj.id,'_SRRI_pos_bars.pdf');
print (hf,filename_plot, "-dpdf", "-S700,400");
	
retcode = 1;

end

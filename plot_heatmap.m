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
%# Major part of the below code is based on the following function:
%# PLOTCONFMAT plots the confusion matrix with colorscale, absolute numbers
%#   and precision normalized percentages
%#
%#   Vahe Tshitoyan, Gutierrez PS
%#   19-march-2021
%#
%# Source: https://github.com/gutierrezps/plotConfMat
%# published under MIT license.

%# -*- texinfo -*-
%# @deftypefn {Function File} {@var{retcode} =} plot_heatmap (@var{input_heatmap}, @var{identifier}, @var{path_reports}, @var{filename}, @var{title_string}, @var{x_axis_label}, @var{y_axis_label}, @var{xlabels}, @var{ylabels}, @var{sum_flag})
%# Generic heatmap plot for any given n x n matrix. set sum_flag to true if you want to append rows and column with respective sums.
%#
%# @seealso{}
%# @end deftypefn


function retcode = plot_heatmap(input_heatmap,identifier,path_reports,filename,title_string,x_axis_label,y_axis_label,xlabels,ylabels,sum_flag)

retcode = 1;
if nargin != 10
	fprintf('plot_heatmap: number of arguments not 10\n');
	retcode = 0
end



% default arguments
fontsize = 14;

input_heatmap
% extend matrix with Size/Style values to include new row/column with sums
if sum_flag
	rows_estab = rows(input_heatmap);
	columns_estab = columns(input_heatmap);
	estab_sum = sum(sum(input_heatmap));
	for ii=1:1:rows_estab
		input_heatmap(rows_estab+1,ii) = sum(input_heatmap(:,ii));
		input_heatmap(ii,columns_estab+1) = sum(input_heatmap(ii,:));
	end
	input_heatmap(rows_estab+1,rows_estab+1) = estab_sum;
	plotmat = input_heatmap;
	xlabels(end+1) = 'Sum';
	ylabels(end+1) = 'Sum';
else
	plotmat = input_heatmap;
end
plotmat

% prepare matrix

plotmat(isnan(plotmat))=0; % in case there are NaN elements
numlabels = size(plotmat, 1); % number of labels

% plotting the matrix
hf = figure(1);
clf; 
	
imagesc(plotmat);
title(sprintf(title_string));
ylabel(y_axis_label); xlabel(x_axis_label);
set(gca, 'FontSize', fontsize);

% set the colormap

confColors = [
	8,81,156;     % 100%
	107,174,214;     % 60%
	198,219,239     % 0%
] ./255;;

confColorMap = zeros(64, 3);
colorPts = int8([0.4 0.6] .* 64);

for i = 1:2
	colors = zeros(colorPts(i), 3);
	for j = 1:3
		colors(:, j) = linspace(confColors(i, j), confColors(i+1, j), colorPts(i))';
	end
	if i == 1
		confColorMap(1:colorPts(1), :) = colors;
	else
		confColorMap(colorPts(1)+1:64, :) = colors;
	end
end

colormap(flipud(confColorMap));

plotmat
% Create strings from the matrix values and remove spaces
textStrings = num2str([plotmat(:)], '%.1f%%\n')
textStrings = strtrim(cellstr(textStrings))

% Create x and y coordinates for the strings and plot them
[x,y] = meshgrid(1:numlabels);
hStrings = text(x(:),y(:),textStrings(:), ...
    'HorizontalAlignment','center', 'FontSize', fontsize);

% Get the middle value of the color range
midValue = mean(get(gca,'CLim'));

% Choose white or black for the text color of the strings so
% they can be easily seen over the background color
textColors = double(repmat(plotmat(:) > midValue,1,3));
for i = 1:length(hStrings)
    set(hStrings(i),'Color', textColors(i,:));
end

% Setting the axis labels
set(gca,'XTick',1:numlabels,...
    'XTickLabel',xlabels,...
    'YTick',1:numlabels,...
    'YTickLabel',ylabels,...
    'TickLength',[0 0]);
    
    
%~ % add colorbar
%~ h = colorbar;
%~ set(h, 'FontSize', fontsize);

% save plotting
	filename_plot_stylebox = strcat(path_reports,'/',identifier,'_',filename,'.png');
	print (hf,filename_plot_stylebox, "-dpng", "-S600,600");
	filename_plot_stylebox = strcat(path_reports,'/',identifier,'_',filename,'.pdf');
	print (hf,filename_plot_stylebox, "-dpdf", "-S600,600");
	filename_plot_stylebox = strcat(path_reports,'/',identifier,'_',filename,'.svg');
	print (hf,filename_plot_stylebox, "-dsvg", "-S600,600");
	
end


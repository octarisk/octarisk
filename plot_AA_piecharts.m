function repstruct = plot_AA_piecharts(repstruct,path_reports,obj)

			
aa_exposure = repstruct.aa_exposure;
aa_cell = repstruct.aa_cell;
[aa_exposure, aa_cell] = sort_cells(aa_exposure,aa_cell);

if ~(isnan(aa_exposure))

	colorbrewer_map = [ ...
	239,243,255;
	198,219,239;
	158,202,225;
	107,174,214;
	49,130,189;
	8,81,156 ...
	] ./255;

	colormap (colorbrewer_map);

	hf = figure(1);
	clf; 
	% Position Custodian distribution
	desc_cell = strrep(aa_cell,"_",""); %remove "_"
	empty_cell = cellstr(cell(numel(desc_cell),1));
	lpie = pie(aa_exposure,desc_cell);
	%titlestring =  ['Asset Allocation'];
	%title(titlestring,'fontsize',16);
	%lleg = legend(desc_cell,'location','east');      
    set(findobj(lpie,'type','text'),'fontsize',18);
    %legend(desc_cell,"fontsize",18,"location","east");
	axis(1.5.*[-1,1,-1,1]);
	axis ('tic', 'off'); 
		
	% save plotting
	filename_plot_aa = strcat(path_reports,'/',obj.id,'_aa_pie_charts.png');
	print (hf,filename_plot_aa, "-dpng", "-S400,400");
	filename_plot_aa = strcat(path_reports,'/',obj.id,'_aa_pie_charts.pdf');
	print (hf,filename_plot_aa, "-dpdf", "-S400,400");
else
	fprintf('Position.plot: AA Index has NaN values. No Plot generated.\n');
end

end

% ##############################################################################
% sort cell and vector
function [vec_plot, cell_plot] = sort_cells(vec_unsorted,cell_unsorted,max_elems = 5);

	[vec_sorted sorted_numbers ] = sort(vec_unsorted,'descend');

	% Top 5 Positions Basevalue
	idx = 1; 
	for ii = 1:1:min(numel(vec_sorted),max_elems);
		vec_plot(idx)  = vec_sorted(ii) ;
		cell_plot(idx) = cell_unsorted(sorted_numbers(ii));
		idx = idx + 1;
	end
	%append remaining part
	if (idx == (max_elems + 1))
		vec_plot(idx)    = sum(vec_unsorted) - sum(vec_plot) ;
		cell_plot(idx)   = "Other";
	end
end

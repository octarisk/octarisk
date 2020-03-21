function repstruct = plot_HHI_piecharts(repstruct,path_reports,obj)

cusbank_undr_exp = repstruct.custodian_bank_underlyings_exposure;
cusbank_undr_cell = repstruct.custodian_bank_underlyings_cell;
HHI_cusbank_undr = calc_HHI(cusbank_undr_exp);
[cusbank_undr_exp, cusbank_undr_cell] = sort_cells(cusbank_undr_exp,cusbank_undr_cell);

des_sponsor_exp = repstruct.designated_sponsor_exposure;
des_spons_cell = repstruct.designated_sponsor_cell;
HHI_des_sponsor = calc_HHI(des_sponsor_exp);
[des_sponsor_exp, des_spons_cell] = sort_cells(des_sponsor_exp,des_spons_cell);
		
custodian_exposure = repstruct.custodian_bank_exposure;
custodian_cell = repstruct.custodian_bank_cell;
HHI_custodian = calc_HHI(custodian_exposure);
[custodian_exposure, custodian_cell] = sort_cells(custodian_exposure,custodian_cell);

issuer_exposure = repstruct.issuer_exposure;
issuer_cell = repstruct.issuer_cell;
HHI_issuer= calc_HHI(issuer_exposure);
[issuer_exposure, issuer_cell] = sort_cells(issuer_exposure,issuer_cell);

counterparty_exposure = repstruct.counterparty_exposure;
counterparty_cell = repstruct.counterparty_cell;
HHI_counterparty = calc_HHI(counterparty_exposure);
[counterparty_exposure, counterparty_cell] = sort_cells(counterparty_exposure,counterparty_cell);

counter_of_origin_exposure = repstruct.country_of_origin_exposure;
counter_of_origin_cell = repstruct.country_of_origin_cell;
HHI_coo = calc_HHI(counter_of_origin_exposure);
[counter_of_origin_exposure, counter_of_origin_cell] = sort_cells(counter_of_origin_exposure,counter_of_origin_cell);

if ~(isnan(HHI_cusbank_undr) && isnan(HHI_des_sponsor) && isnan(HHI_custodian) && ...
	isnan(HHI_issuer) && isnan(HHI_counterparty) && isnan(HHI_coo))

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
		subplot (3, 2, 1) 
		desc_cell = strrep(custodian_cell,"_",""); %remove "_"
		empty_cell = cellstr(cell(numel(desc_cell),1));
		pie(custodian_exposure,desc_cell);
		titlestring =  ['Custodian (HHI = ',num2str(round(HHI_custodian)),')'];
		title(titlestring,'fontsize',12);
		%legend(desc_cell,'location','west');
		axis(1.2.*[-1,1,-1,1]);
		axis ('tic', 'off'); 
		
	% Position Issuer distribution
		subplot (3, 2, 2) 
		desc_cell = strrep(issuer_cell,"_",""); %remove "_"
		%plot_vec_pie = zeros(1,numel(desc_cell));
		%plot_vec_pie(issuer_exposure==max(issuer_exposure)) = 1; 
		pie(issuer_exposure, desc_cell);
		titlestring =  ['Issuer (HHI = ',num2str(round(HHI_issuer)),')'];
		title(titlestring,'fontsize',12);
		axis(1.2.*[-1,1,-1,1]);
		axis ('tic', 'off');   

	% Position Counterparty distribution
		subplot (3, 2, 3) 
		desc_cell = strrep(counterparty_cell,"_",""); %remove "_"
		%plot_vec_pie = zeros(1,numel(desc_cell));
		%plot_vec_pie(counterparty_exposure==max(counterparty_exposure)) = 1; 
		pie(counterparty_exposure, desc_cell);
		titlestring =  ['Counterparty (HHI = ',num2str(round(HHI_counterparty)),')'];
		title(titlestring,'fontsize',12);
		axis(1.2.*[-1,1,-1,1]);
		axis ('tic', 'off');   

	% Position Country of Origin distribution
		subplot (3, 2, 4) 
		desc_cell = strrep(counter_of_origin_cell,"_",""); %remove "_"
		%plot_vec_pie = zeros(1,numel(desc_cell));
		%plot_vec_pie(counter_of_origin_exposure==max(counter_of_origin_exposure)) = 1;
		pie(counter_of_origin_exposure, desc_cell);
		titlestring =  ['Country of Origin (HHI = ',num2str(round(HHI_coo)),')'];
		title(titlestring,'fontsize',12);
		axis(1.2.*[-1,1,-1,1]);
		axis ('tic', 'off');   

	% Position cusbank_undr_exp distribution
		subplot (3, 2, 5) 
		desc_cell = strrep(cusbank_undr_cell,"_",""); %remove "_"
		%plot_vec_pie = zeros(1,numel(desc_cell));
		%plot_vec_pie(counterparty_exposure==max(counterparty_exposure)) = 1; 
		pie(cusbank_undr_exp, desc_cell);
		titlestring =  ['Custodian Bank Underlying (HHI = ',num2str(round(HHI_cusbank_undr)),')'];
		title(titlestring,'fontsize',12);
		axis(1.2.*[-1,1,-1,1]);
		axis ('tic', 'off');  

	% Position des_sponsor_exp distribution
		subplot (3, 2, 6) 
		desc_cell = strrep(des_spons_cell,"_",""); %remove "_"
		%plot_vec_pie = zeros(1,numel(desc_cell));
		%plot_vec_pie(counterparty_exposure==max(counterparty_exposure)) = 1; 
		pie(des_sponsor_exp, desc_cell);
		titlestring =  ['Designated Sponsor (HHI = ',num2str(round(HHI_des_sponsor)),')'];
		title(titlestring,'fontsize',12);
		axis(1.2.*[-1,1,-1,1]);
		axis ('tic', 'off'); 
			
	% save plotting
	filename_plot_hhi = strcat(path_reports,'/',obj.id,'_concentration_pie_charts.png');
	print (hf,filename_plot_hhi, "-dpng", "-S600,700");
	filename_plot_hhi = strcat(path_reports,'/',obj.id,'_concentration_pie_charts.pdf');
	print (hf,filename_plot_hhi, "-dpdf", "-S600,700");
else
	fprintf('Position.plot: At least one HHI Index has NaN values. No Plot generated.\n');
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

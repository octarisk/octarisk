%# Copyright (C) 2023 Stefan Schloegl <schinzilord@octarisk.com>
%#
%# This program is free software; you can redistribute it and/or modify it under
%# the terms of the GNU General Public License as published by the Free Software
%# Foundation; either version 3 of the License, or (at your option) any later
%# version.
%#
%# -*- texinfo -*-
%# @deftypefn {Function File} {@var{retcode} =} plot_balancesheet (@var{identifier}, @var{path_reports}, @var{title_string}, @var{assets_input}, @var{assets_labels_input}, @var{liabs_input}, @var{liabs_labels_input})
%# Generic plot of balance sheet items in two bars (assets and liabs incl. own funds).
%#
%# @seealso{}
%# @end deftypefn

function  retcode = plot_balancesheet(identifier,path_reports,title_string,assets_input,assets_labels_input,liabs_input,liabs_labels_input);
retcode = 1;

% only take unique assets and liab categories into account (no aggregated figures) to not distort plot
[assets_unique liabs_unique] = get_categories_cell();

assets = [];
assets_labels = {};


if (sum(liabs_input) == 0 && sum(assets_input) == 0)
	retcode = 0;
	fprintf('plot: Plotting MVBS balance sheet for portfolio >>%s<< not possible, no exposure MVBS categories.\n',identifier);	
else

	for kk=1:1:numel(assets_labels_input)
		tmp_label = assets_labels_input{kk};
		if (sum(strcmpi(assets_unique,tmp_label)))
			if (assets_input(kk) != 0.0)
				assets(end+1) = assets_input(kk);
				assets_labels(end+1) = tmp_label;
			end
		end
	end


	liabs = [];
	liabs_labels = {};

	for kk=1:1:numel(liabs_labels_input)
		tmp_label = liabs_labels_input{kk};
		if (sum(strcmpi(liabs_unique,tmp_label)))
			if (liabs_input(kk) != 0.0)
				liabs(end+1) = liabs_input(kk);
				liabs_labels(end+1) = tmp_label;
			end
		end
	end
	%%%%%%%%%%%%%%%%


	colorbrewer_map = [ ...
	222,235,247;
	198,219,239;
	158,202,225;
	107,174,214;
	66,146,198; ...
	] ./255;

	% rescacle to kEUR
	assets = assets ./1000;
	liabs = liabs ./1000;
			
	liabs = -liabs; % for plotting: liabs needs to be positive
	% amend own funds to liabs
	liabs(end+1) = sum(assets) - sum(liabs); %since liabs are positive, we need to subtract liabs from assets to get own funds

	if (liabs(end) < 0)	% negative own funds
		liabs_labels(end + 1) = 'Negative Own Funds';
	elseif
		liabs_labels(end + 1) = 'Own Funds';
	end

	dummy_assets = zeros(1,numel(assets));
	dummy_liabs = zeros(1,numel(liabs));

	% plot stacked bar chart
	clf;
	hf1 = figure(1);

	hBarA = bar([assets;dummy_assets],"stacked");
	hold on;
	hBarL = bar([dummy_liabs;liabs],"stacked");

	xlabel('MVBS');
	ylabel('Amount (in kEUR)');
	title(sprintf(title_string));

	labels = ['Assets'; 'Liabilties and Own Funds'];
	set(gca, 'XTickLabel', labels) ;

	% Annotation for Assets:
	xt = get(gca, 'XTick');
	yd = get(hBarA, 'YData');
	barbase = cumsum([zeros(size(assets,1),1) assets(:,1:end-1)],2);
	joblblpos = assets/2 + barbase;
	text(xt(1) * ones(1,size(assets,2)), joblblpos(1,:), assets_labels, 'HorizontalAlignment','center');


	% Annotation for Liabs:
	xt = get(gca, 'XTick');
	yd = get(hBarL, 'YData');
	if (liabs(end) >= 0)
		barbase = cumsum([zeros(size(liabs,1),1) liabs(:,1:end-1)],2);
	else
		barbase = cumsum([zeros(size(liabs,1),1) liabs(:,1:end-1)],2);
		barbase(end) = liabs(end)/16;
	end
	joblblpos = liabs/2 + barbase;
	text(xt(2) * ones(1,size(liabs,2)), joblblpos(1,:), liabs_labels, 'HorizontalAlignment','center');

	% color coding of bar chart
	for ii = 1:1:numel(hBarA)
		if ii>rows(colorbrewer_map)
			kk = mod(ii,rows(colorbrewer_map)) + 1;
		else
			kk = ii;
		end
		set (hBarA(ii), "facecolor", colorbrewer_map(kk,:));
	end

	for ii = 1:1:numel(hBarL)
		if ii>rows(colorbrewer_map)
			kk = mod(ii,rows(colorbrewer_map)) + 1;
		else
			kk = ii;
		end
		set (hBarL(ii), "facecolor", colorbrewer_map(kk,:));
	end
	hold off;
		
	% save plotting
	filename_plot  = strcat(path_reports,'/',identifier,'_mvbs_bars.png');
	print (hf1,filename_plot, "-dpng", "-S700,400");
	filename_plot = strcat(path_reports,'/',identifier,'_mvbs_bars.pdf');
	print (hf1,filename_plot, "-dpdf", "-S700,400");
end 	  
	  
end

% ##############################################################################

function [assets_unique liabilities_unique] = get_categories_cell()

assets_unique = {
'Intangible assets', 
'Deferred tax assets', 
'Pension benefit surplus', 
'Property plant and equipment held for own use', 
'Property (other than for own use)', 
'Holdings in related undertakings including participations', 
'Equities - listed', 
'Equities - unlisted', 
'Government Bonds', 
'Corporate Bonds', 
'Structured notes', 
'Collateralised securities', 
'Collective Investments Undertakings', 
'Derivatives', 
'Deposits other than cash equivalents', 
'Other investments', 
'Assets held for index-linked and unit-linked contracts', 
'Loans on policies', 
'Loans and mortgages to individuals', 
'Other loans and mortgages', 
'Non-life and health similar to non-life', 
'Non-life excluding health', 
'Health similar to non-life', 
'Life and health similar to life excluding health and index-linked and unit-linked', 
'Health similar to life', 
'Life excluding health and index-linked and unit-linked', 
'Life index-linked and unit-linked', 
'Deposits to cedants', 
'Pension claims from government',
'Pension claims from insurance companies',
'Other insurance receivables',
'Reinsurance receivables', 
'Receivables (trade not insurance)', 
'Own shares (held directly)', 
'Amounts due in respect of own fund items or initial fund called up but not yet paid in', 
'Cash and cash equivalents', 
'Physical commodities', 
'Cryptocurrencies',
'Human Capital',
'Any other assets'
};

liabilities_unique = {
'Technical provisions - non-life (excluding health)',
'Technical provisions - health (similar to non-life)',
'Technical provisions - health (similar to life)',
'Technical provisions - life (excluding health and index-linked and unit-linked)',
'Technical provisions - index-linked and unit-linked',
'Other technical provisions',
'Contingent liabilities',
'Provisions other than technical provisions',
'Pension benefit obligations',
'Deposits from reinsurers',
'Deferred tax liabilities',
'Derivatives',
'Debts owed to credit institutions',
'Financial liabilities other than debts owed to credit institutions',
'Insurance and intermediaries payables',
'Reinsurance payables',
'Payables (trade not insurance)',
'Subordinated liabilities not in Basic Own Funds',
'Subordinated liabilities in Basic Own Funds',
'Any other liabilities'
};


end


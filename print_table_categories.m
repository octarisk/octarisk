%# Copyright (C) 2020 Stefan Schlögl <schinzilord@octarisk.com>
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
%#
%# You should have received a copy of the GNU General Public License along with
%# this program; if not, see <http://www.gnu.org/licenses/>.
 
%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{retcode} ] =} print_table_categories(@var{port_obj},@var{repstruct},@var{filepathtex},@var{filepathrecon})
%# Print MVBS table to tex and csv file.
%# 
%# @end deftypefn

function [retcode repstruct] = print_table_categories(port_obj,repstruct,filepathtex,filepathrecon)
retcode = 1;
fprintf('print: Printing  MVBS table for portfolio >>%s<< into file: %s\n',port_obj.id,filepathtex);	
fprintf('print: Printing  MVBS reconciliation for portfolio >>%s<< into file: %s\n',port_obj.id,filepathrecon);	

category_cell = repstruct.category_cell;
category_exposure = repstruct.category_exposure;

% make struct:
catstruct = struct();

for ii=1:length(category_cell)
	catstruct.( category_cell{ii} ) = category_exposure(ii);
end


% loop through categories and aggregate / print:
[assets liabilities cell_indentation cell_double_indentation] = get_categories_cell();

% ###########         Assets        ############################################
% loop through categories cell, check if field filled, take this vlaue, otherwise 0
total_assets = 0;
for ii=1:1:length(assets)
	cat = assets{ii};
	if (isfield(catstruct,cat) && isnumeric(catstruct.(cat)))
		total_assets = total_assets + catstruct.(cat);
	else % otherwise fill with zero
		catstruct.(cat) = 0.0;
	end
end


fqrt = fopen (filepathtex, 'w');
frecon = fopen (filepathrecon, 'w');
fprintf(fqrt, '\\center\n');
fprintf(frecon, 'MVBS Reconciliation\n');
fprintf(frecon, 'Assets\n');
fprintf('=============== Assets ===============\n');
fprintf(fqrt, '\\begin{tabular}{| l | r |} \\hline\n');
fprintf(fqrt, '\\textbf{Assets} \& in %s \\\\\\hline\n',port_obj.currency);	

asset_startcell = 14;
asset_exposure = zeros(1,length(assets));
for ii=1:1:length(assets)
	cat = assets{ii};
	exp = 0;
	if strcmpi(cat,'Investments (other than assets held for index-linked and unit-linked contracts)')
		exp = getfield(catstruct,'Property (other than for own use)') + ...
				getfield(catstruct,'Holdings in related undertakings, including participations') + ...
				getfield(catstruct,'Equities - listed') + ...
				getfield(catstruct,'Equities - unlisted') + ...
				getfield(catstruct,'Government Bonds') + ...
				getfield(catstruct,'Corporate Bonds') + ...
				getfield(catstruct,'Structured notes') + ...
				getfield(catstruct,'Collateralised securities') + ...
				getfield(catstruct,'Collective Investments Undertakings') + ...
				getfield(catstruct,'Derivatives') + ...
				getfield(catstruct,'Deposits other than cash equivalents') + ...
				getfield(catstruct,'Other investments');
		cat = 'Investments';
	elseif strcmpi(cat,'Bonds')
		exp = getfield(catstruct,'Government Bonds') + ...
			getfield(catstruct,'Corporate Bonds') + ...
			getfield(catstruct,'Structured notes') + ...
			getfield(catstruct,'Collateralised securities');

	elseif strcmpi(cat,'Equities')
		exp = getfield(catstruct,'Equities - listed') + ...
			getfield(catstruct,'Equities - unlisted');

	elseif strcmpi(cat,'Insurance and intermediaries receivables')
		exp = getfield(catstruct,'Pension claims from government') + ...
			getfield(catstruct,'Pension claims from insurance companies') + ...
			getfield(catstruct,'Other insurance receivables');
			
	elseif strcmpi(cat,'Loans and mortgages')
		exp = getfield(catstruct,'Loans on policies') + ...
			getfield(catstruct,'Other loans and mortgages') + ...
			getfield(catstruct,'Loans and mortgages to individuals');

	elseif strcmpi(cat,'Reinsurance recoverables from:')
		exp = getfield(catstruct,'Non-life excluding health') + ...
			getfield(catstruct,'Health similar to non-life') + ...
			getfield(catstruct,'Health similar to life') + ...
			getfield(catstruct,'Life excluding health and index-linked and unit-linked') + ...
			getfield(catstruct,'Life index-linked and unit-linked');

	elseif strcmpi(cat,'Non-life and health similar to non-life')
		exp = getfield(catstruct,'Non-life excluding health') + ...
			getfield(catstruct,'Health similar to non-life');

	elseif strcmpi(cat,'Life and health similar to life, excluding health and index-linked and unit-linked')
		exp = getfield(catstruct,'Life excluding health and index-linked and unit-linked') + ...
			getfield(catstruct,'Health similar to life');

	elseif strcmpi(cat,'Total assets')
		exp = total_assets;
	
	else
		exp = getfield(catstruct,cat);

	end

	if abs(exp) ~= 0
		fprintf('%s: %9.0f\n',cat,exp);
		if strcmpi(cat,'Total Assets')
			fprintf(fqrt, '\\textit{Total Assets} \& %9.0f \\\\\\hline\\hline\n',exp);
			fprintf(frecon, 'Total Assets,%1.0f\n',exp);
		elseif (sum(strcmpi(cat,cell_indentation)) > 0)	
			fprintf(fqrt, '\\hspace{0.2cm} %s \& %9.0f \\\\\n',cat,exp);
			fprintf(frecon, '    %s,%1.0f\n',cat,exp);
		elseif (sum(strcmpi(cat,cell_double_indentation)) > 0)	
			fprintf(fqrt, '\\hspace{0.4cm} %s \& %9.0f \\\\\n',cat,exp);
			fprintf(frecon, '        %s,%1.0f\n',cat,exp);		
		else
			fprintf(fqrt, '%s \& %9.0f \\\\\n',cat,exp);
			fprintf(frecon, '%s,%1.0f\n',cat,exp);	
		end
	end
	asset_exposure(ii) = exp;		
end
 
repstruct.mvbs_assets = assets;
repstruct.mvbs_asset_exposure = asset_exposure;

fprintf('=============== Liabilities ===============\n');
fprintf(frecon, 'Liabilities\n');

% ###########         Liabilities        ############################################
% loop through categories cell, check if field filled, take this vlaue, otherwise 0
total_liabs = 0;
for ii=1:1:length(liabilities)
	cat = liabilities{ii};
	if (isfield(catstruct,cat) && isnumeric(catstruct.(cat)))
		total_liabs = total_liabs + catstruct.(cat);
	else % otherwise fill with zero
		catstruct.(cat) = 0.0;
	end
end

if abs(total_liabs) ~= 0
	fprintf(fqrt, '\\textbf{Liabilities} \&  \\\\\\hline\n');	
end

liabs_cell = 56;
liab_exposure = zeros(1,length(liabilities));
for ii=1:1:length(liabilities)
	cat = liabilities{ii};
	exp = 0;
	liabs_cell = liabs_cell + 1;
	if strcmpi(cat,'Subordinated liabilities')
		exp = getfield(catstruct,'Subordinated liabilities not in Basic Own Funds') + ...
			getfield(catstruct,'Subordinated liabilities in Basic Own Funds');

	elseif strcmpi(cat,'Technical provisions – non-life')
		exp = getfield(catstruct,'Technical provisions – non-life (excluding health)') + ...
			getfield(catstruct,'Technical provisions - health (similar to non-life)');

	elseif strcmpi(cat,'Technical provisions - life (excluding index-linked and unit-linked)')
		exp = getfield(catstruct,'Technical provisions - health (similar to life)') + ...
			getfield(catstruct,'Technical provisions – life (excluding health and index-linked and unit-linked)');

	elseif strcmpi(cat,'Technical provisions – non-life (excluding health)')
		exp = getfield(catstruct,cat);

	elseif strcmpi(cat,'Technical provisions - health (similar to non-life)')
		exp = getfield(catstruct,cat);

	elseif strcmpi(cat,'Technical provisions - health (similar to life)')
		exp = getfield(catstruct,cat);

	elseif strcmpi(cat,'Technical provisions – life (excluding health and index-linked and unit-linked)')
		exp = getfield(catstruct,cat);	
		
	elseif strcmpi(cat,'Total liabilities')
		exp = total_liabs;		
		
	else
		exp = getfield(catstruct,cat);
	end
	% print to file
	if (strcmpi(cat,'Technical provisions – non-life (excluding health)') || 
		strcmpi(cat,'Technical provisions - health (similar to non-life)') ||
		strcmpi(cat,'Technical provisions - health (similar to life)') ||
		strcmpi(cat,'Technical provisions – life (excluding health and index-linked and unit-linked)') ||
		strcmpi(cat,'Technical provisions – index-linked and unit-linked')) 
			liabs_cell = liabs_cell + 3;
	end

	if abs(exp) ~= 0
		fprintf('%s: %9.2f\n',cat,exp);
		if strcmpi(cat,'Total Liabilities')
			fprintf(fqrt, '\\textit{Total Liabilities} \& %9.0f \\\\\\hline\\hline\n',exp);
			fprintf(frecon, 'Total Liabilities,%.0f\n',exp);
		elseif (sum(strcmpi(cat,cell_indentation)) > 0)	
			fprintf(fqrt, '\\hspace{0.2cm} %s \& %9.0f \\\\\n',cat,exp);
			fprintf(frecon, '    %s,%.0f\n',cat,exp);
		elseif (sum(strcmpi(cat,cell_double_indentation)) > 0)	
			fprintf(fqrt, '\\hspace{0.4cm} %s \& %9.0f \\\\\n',cat,exp);	
			fprintf(frecon, '        %s,%.0f\n',cat,exp);
		else
			fprintf(fqrt, '%s \& %9.0f \\\\\n',cat,exp);
			fprintf(frecon, '%s,%.0f\n',cat,exp);
		end
	end
	liab_exposure(ii) = exp;
end
repstruct.mvbs_liabilities = liabilities;
repstruct.mvbs_liab_exposure = liab_exposure;
% 
% Own funds
tax = getfield(catstruct,'Deferred tax assets') + getfield(catstruct,'Deferred tax liabilities');

fprintf('=============== Own Funds ===============\n');
fprintf(frecon, 'Own Funds\n');
cat = 'Own Funds before tax';
of_bt = total_assets + total_liabs - tax;
fprintf('%s: %9.2f\n',cat,of_bt);
fprintf('%s: %9.2f\n','Deferred tax',tax);
cat = 'Own Funds after tax';
of_at = total_assets + total_liabs;
fprintf('%s: %9.2f\n',cat,of_at);

fprintf(fqrt, '\\textbf{Own Funds} \&  \\\\\\hline\n');	
fprintf(fqrt, 'Own Funds before tax \& %9.0f \\\\\\hline\n',of_bt);
fprintf(fqrt, '%s \& %9.0f \\\\\\hline\n','Deferred tax',tax);
fprintf(fqrt, '\\textbf{Own Funds after tax} \& %9.0f \\\\\\hline\n',of_at);

fprintf(frecon, 'Own Funds before tax,%1.0f\n',of_bt);
fprintf(frecon, 'Deferred tax,%1.0f\n',tax);
fprintf(frecon, 'Own Funds after tax,%1.0f\n',of_at);

fprintf(fqrt, '\\end{tabular}\n');
fclose (fqrt);
fclose (frecon);

ownfunds = {'Own Funds before tax','Deferred tax','Own Funds after tax'};
ownfunds_exposure = [of_bt;tax;of_at];

repstruct.mvbs_ownfunds = ownfunds;
repstruct.mvbs_ownfunds_exposure = ownfunds_exposure;

end
% ##############################################################################

function [assets liabilities cell_indentation cell_double_indentation] = get_categories_cell()

assets = {
'Intangible assets', 
'Deferred tax assets', 
'Pension benefit surplus', 
'Property, plant & equipment held for own use', 
'Investments (other than assets held for index-linked and unit-linked contracts)', 
'Property (other than for own use)', 
'Holdings in related undertakings, including participations', 
'Equities', 
'Equities - listed', 
'Equities - unlisted', 
'Bonds', 
'Government Bonds', 
'Corporate Bonds', 
'Structured notes', 
'Collateralised securities', 
'Collective Investments Undertakings', 
'Derivatives', 
'Deposits other than cash equivalents', 
'Other investments', 
'Assets held for index-linked and unit-linked contracts', 
'Loans and mortgages', 
'Loans on policies', 
'Loans and mortgages to individuals', 
'Other loans and mortgages', 
'Reinsurance recoverables from:', 
'Non-life and health similar to non-life', 
'Non-life excluding health', 
'Health similar to non-life', 
'Life and health similar to life, excluding health and index-linked and unit-linked', 
'Health similar to life', 
'Life excluding health and index-linked and unit-linked', 
'Life index-linked and unit-linked', 
'Deposits to cedants', 
'Insurance and intermediaries receivables', 
'Pension claims from government',
'Pension claims from insurance companies',
'Other insurance receivables',
'Reinsurance receivables', 
'Receivables (trade, not insurance)', 
'Own shares (held directly)', 
'Amounts due in respect of own fund items or initial fund called up but not yet paid in', 
'Cash and cash equivalents', 
'Physical commodities', 
'Cryptocurrencies',
'Any other assets, not elsewhere shown', 
'Total assets'
};

liabilities = {
'Technical provisions – non-life',
'Technical provisions – non-life (excluding health)',
'Technical provisions - health (similar to non-life)',
'Technical provisions - life (excluding index-linked and unit-linked)',
'Technical provisions - health (similar to life)',
'Technical provisions – life (excluding health and index-linked and unit-linked)',
'Technical provisions – index-linked and unit-linked',
'Other technical provisions',
'Contingent liabilities',
'Provisions other than technical provisions',
'Pension benefit obligations',
'Deposits from reinsurers',
'Deferred tax liabilities',
'Derivatives',
'Debts owed to credit institutions',
'Financial liabilities other than debts owed to credit institutions',
'Insurance & intermediaries payables',
'Reinsurance payables',
'Payables (trade, not insurance)',
'Subordinated liabilities',
'Subordinated liabilities not in Basic Own Funds',
'Subordinated liabilities in Basic Own Funds',
'Any other liabilities, not elsewhere shown',
'Total liabilities'
};

cell_indentation = {
'Property (other than for own use)', 
'Holdings in related undertakings, including participations', 
'Equities', 
'Bonds', 
'Collective Investments Undertakings', 
'Derivatives', 
'Deposits other than cash equivalents', 
'Other investments', 
'Loans on policies', 
'Loans and mortgages to individuals', 
'Other loans and mortgages', 
'Pension claims from government',
'Pension claims from insurance companies',
'Other insurance receivables',
'Non-life and health similar to non-life', 
'Life and health similar to life, excluding health and index-linked and unit-linked', 
'Life index-linked and unit-linked', 
'Technical provisions – non-life (excluding health)',
'Technical provisions - health (similar to non-life)',
'Technical provisions - health (similar to life)',
'Technical provisions – life (excluding health and index-linked and unit-linked)',
'Subordinated liabilities not in Basic Own Funds',
'Subordinated liabilities in Basic Own Funds'
};

cell_double_indentation = {
'Equities - listed', 
'Equities - unlisted', 
'Government Bonds', 
'Corporate Bonds', 
'Structured notes', 
'Collateralised securities', 
'Non-life excluding health', 
'Health similar to non-life', 
'Health similar to life', 
'Life excluding health and index-linked and unit-linked', 
};


end

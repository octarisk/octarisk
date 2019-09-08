%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{mapping_struct} @var{rf_failed_cell}] =} load_riskfactor_mapping(@var{mapping_struct}, @var{rf_struct},@var{path_input}, @var{input_filename_mc_mapping})
%# Load csv file with mapped risk factors for MC scenarios.
%# @end deftypefn

function [rf_struct rf_cell rf_mapping_failed_cell] = load_riskfactor_mapping(rf_struct, rf_cell,path_input,input_filename_mc_mapping)

rf_mapping_failed_cell = {};
filename = strcat(path_input,'/',input_filename_mc_mapping);
rf_mapped = 0;
try
	filestr = fileread(filename);
	linestr = strsplit(filestr,'\n');
	for kk=2:1:length(linestr)
		tmp_line = linestr{kk};
		if ~( isempty(tmp_line) > 0)
			linesplit = strsplit(tmp_line,',');
			if ( numel(linesplit) == 1)
				error('load_riskfactor_mapping: Need at least source and target risk factor in line >>%s<<\n',tmp_line);
			elseif ( numel(linesplit) == 2) 
				srf_id = linesplit{1};
				trf_id = linesplit{2};
				desc_str = trf_id;
			elseif ( numel(linesplit) == 3) 
				srf_id = linesplit{1};
				trf_id = linesplit{2};
				desc_str = linesplit{3};
			else
				error('load_riskfactor_mapping: Too many attributes in line >>%s<<\n',tmp_line);
			end
			
			[srf_obj retcode] = get_sub_object(rf_struct,srf_id);
			if ( retcode == 1)
				trf_obj = srf_obj;
				trf_obj = trf_obj.set('id',trf_id,'name',trf_id,'description',desc_str);
				idx = length(rf_struct) + 1;
				rf_struct( idx ).id = trf_id;
				rf_struct( idx ).object = trf_obj;
				rf_cell{ length(rf_cell) + 1 } =  trf_id;
				rf_mapped = rf_mapped + 1;
			else	
				fprintf('WARNING: load_riskfactor_mapping: Source risk factor not found: >>%s<<',srf_id);
				rf_mapping_failed_cell{ length(rf_mapping_failed_cell) + 1 } =  srf_id;
			end
		end
	end
catch
	fprintf('WARNING: There has been an error for file: >>%s<<.Error: >>%s<<\n',filename,lasterr);
end  % end try catch


fprintf('SUCCESS: mapped >>%d<< risk factor objects.\n',rf_mapped);

end 

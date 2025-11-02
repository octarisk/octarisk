%# Copyright (C) 2025 Stefan Schlögl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{retcode} ] =} export_to_csv(@var{para},@var{instrument_struct},@var{port_obj_struct})
%# Exports MC scenario profit and loss values of instruments and portfolio objects to a csv file.
%# @end deftypefn

function ret = export_to_csv(para,instrument_struct,port_obj_struct)

export_flag = para.get('export_to_csv');
export_flag = 1;
   
      
output_filename = strcat(para.get('path_working_folder'),'/',para.folder_output,'/',para.folder_output_reports,'/','pnlmat.csv');


% determine shred type
shred_type = para.get('shred_type');
if (strcmpi(shred_type,'TOTAL'))
	fprintf('Shred type equals TOTAL. Export to csv.\n');
	export_flag = 1;
else
    fprintf('Shred type not TOTAL. No export to csv.\n');
	export_flag = 0;
end
	
if (export_flag == 1)
	shred = strcat(toupper(para.get('cvar_type')),'_',toupper(shred_type));
	timestep_mc = para.get('mc_timestep');
	fprintf('Exporting to csv file: %s\n',output_filename);  


	% initialize vector with numbers from 1 to numbers MC scenarios
	lenvec = 1:1:para.get('mc');

	% initialize header and matrix with all PnL values:
	header_line = strcat('Scenario');
	mat_export = [0;lenvec'];
	
	try		
		for kk = 1:1:length(port_obj_struct)
			obj = port_obj_struct(kk).object;
			if (isobject(obj))
				base_value = obj.getValue('base');
				scen_values = obj.getValue(timestep_mc);
				fprintf('Exporting portfolio >>%s<< to csv.\n',obj.id);
				tmp_id = strcat(shred,'_PORTFOLIO_',obj.id);
				header_line = strcat(header_line,',',tmp_id);
				mat_export = [mat_export,[base_value;scen_values]];
			end
		end
		
		for kk = 1:1:length(instrument_struct)
			obj = instrument_struct(kk).object;
			if (isobject(obj))
				base_value = obj.getValue('base');
				scen_values = obj.getValue(timestep_mc);
				fprintf('Exporting instrument >>%s<< to csv.\n',obj.id);
				tmp_id = strcat(shred,'_INSTR_',obj.id);
				header_line = strcat(header_line,',',tmp_id);
				mat_export = [mat_export,[base_value;scen_values]];
			end
		end
		

		%write header to file
		fid = fopen(output_filename,'w'); 
		fprintf(fid,'%s\n',header_line);
		fclose(fid);
		%write data to end of file
		dlmwrite(output_filename,mat_export,'-append', 'delimiter', ',','precision','%1.2f');	
	catch   
		fprintf('There was an error: %s\n',lasterr);
	end
	ret = 1;

else
	fprintf('Export flag is false. No Exporting to csv file.\n');
	ret = 0;
end


end % end function

%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
%# Copyright (C) 2009-2014 Pascal Dupuis <cdemills@gmail.com> 
%# (code reuse of his dataframe package)
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
%# @deftypefn {Function File} {[@var{portfolio_struct} @var{id_failed_cell}] =} load_stresstests(@var{portfolio_struct}, @var{valuation_date}, @var{path_stresstests}, @var{file_stresstests}, @var{path_output}, @var{path_archive}, @var{tmp_timestamp}, @var{archive_flag})
%# Load data from stresstest specification file and generate a struct with 
%# parsed data. Store all stresstests in provided struct and return the final 
%# struct and a cell containing the failed position ids.
%# @end deftypefn

function [stresstest_struct id_failed_cell] = load_stresstests(stresstest_struct, ...
                            path_stresstests,file_stresstests,path_output, ...
                            path_archive,tmp_timestamp,archive_flag)

% A) Prepare position object generation
separator = ',';
path_stresstests_in = strcat(path_stresstests,'/',file_stresstests)
path = path_output;

% B) Read in stresstest file
number_stresstests = 0;
id_failed_cell = {};
stresstest_struct(1).id = 'Base';
stresstest_struct(1).name = 'Base';
stresstest_struct(1).objects = '';

in = fileread(path_stresstests_in);
in = strcat(in,"\n");
% ==========================================================
% use custom design for data import -> 
% Copyright (C) 2009-2014 Pascal Dupuis <cdemills@gmail.com>: 
% code from his dataframe package, published under the GNU GPL
%# explicit list taken from 'man pcrepattern' -- we enclose all
  %# vertical separators in case the underlying regexp engine
  %# doesn't have them all.
  eol = '(\r\n|\n|\v|\f|\r|\x85)';
  %# cut into lines -- include the EOL to have a one-to-one
	%# matching between line numbers. Use a non-greedy match.
  lines = regexp (in, ['.*?' eol], 'match');
  %# spare memory
  clear in;
  try
	dummy =  cellfun (@(x) regexp (x, eol), lines); 
  catch  
	error('line 245 -- binary garbage in the input file ? \n');
  end
  %# remove the EOL character(s)
  lines(1 == dummy) = {''};
  lines_out = {};
   %# remove everything beyond the eol character (the character number dummy value found)
  for kk = 1 : 1 : length(lines)
		tmp_lines = lines{kk};
		dummy_eol = dummy(kk);
		if ( length(tmp_lines)>1)
			lines_out{kk} = tmp_lines(1:dummy_eol-1);
		end
  end

  %# extract fields
  content = cellfun (@(x) strsplit (x, separator, 'collapsedelimiters', ...
						false), lines_out, 'UniformOutput', false);             
% ==========================================================
% B.2) extract header from first row:
tmp_header = content{1};
tmp_colname = {};
tmp_position_type = strtrim(tmp_header{1});
for kk = 2 : 1 : length(tmp_header)
	tmp_item = tmp_header{kk};
	 % extract last 4 characters for type
	tmp_header_type{kk-1} = tmp_item(end-3:end);
	tmp_colname{kk-1} = tmp_item(1:end-4); 
end    
% B.3) loop through all entries of file 

tmp_cell_struct = {};          
for jj = 2 : 1 : length(content)
  error_flag = 0;
  object_struct = struct();
  % parse row only if it contains some meaningful data:
  if (length(content{jj}) > 3)  
	
	% B.3b)  Loop through all stresstest
	tmp_cell = content{jj};
	% loop via all entries in row and set object attributes:
	for mm = 2 : 1 : length(tmp_cell)   
		tmp_columnname = lower(tmp_colname{mm-1});
		tmp_cell_item = tmp_cell{mm};
		tmp_cell_type = upper(tmp_header_type{mm-1});
		% B.3b.i) convert item to appropriate type
		if ( strcmp(tmp_cell_type,'NMBR'))
			try
				tmp_entry = str2num(tmp_cell_item);
			catch
				fprintf('Item >>%s<< is not NUMERIC \n',tmp_cell_item);
				tmp_entry = 0.0;
				error_flag = 1;
			end
			 
		elseif ( strcmp(tmp_cell_type,'CHAR'))
			try
				tmp_entry = strtrim(tmp_cell_item);
			catch
				fprintf('Item >>%s<< is not a CHAR \n',tmp_cell_item);
				tmp_entry = '';
				error_flag = 1;
			end
		elseif ( strcmp(tmp_cell_type,'BOOL'))
			try                    
				if (isnumeric (tmp_cell_item))
					tmp_entry = logical(tmp_cell_item);
				elseif ( ischar(tmp_cell_item))
					if ( strcmpi('false',tmp_cell_item) ...
										|| strcmpi('0',tmp_cell_item))
						tmp_entry = 0;
					elseif ( strcmpi('true',tmp_cell_item) ...
										|| strcmpi('1',tmp_cell_item))
						tmp_entry = 1;
					end
				end  
			catch
				fprintf('Item >>%s<< is not a BOOL: %s \n', ...
						tmp_cell_item,lasterr);
				tmp_entry = 0;
				error_flag = 1;
			end    
		elseif ( strcmp(tmp_cell_type,'DATE'))
			try
				tmp_entry = datestr(tmp_cell_item);
			catch
				fprintf('Item >>%s<< is not a DATE \n',tmp_cell_item);
				tmp_entry = '01-Jan-1900';
				error_flag = 1;
			end
		else
			fprintf('Unknown type: >>%s<< for item',tmp_cell_type); 
			frptinf('value >>%s<<. Aborting: >>%s<< \n', ...
					tmp_cell_item,lasterr);
		end
			
		% B.3b.ii) Adjust input data according to columnname
		try
			% special case: term, shockvalue, axis_x,  axis_y,  axis_z,
			if ( strcmp(tmp_columnname,'term'))
				tmp_entry_split = strsplit(tmp_entry, '|');
				tmp_entry = [];
				%lsplit = tmp_entry_split{1};
				if ~( isempty(tmp_entry_split{1}))
					% loop through all shift values and convert it to numbers
					for ll = 1 : 1 : length(tmp_entry_split)    
						tmp_entry = [tmp_entry, str2num(tmp_entry_split{ll})];
					end
				end 
			elseif ( strcmp(tmp_columnname,'shockvalue')) % split into cell
				% shockvalues can be one (separator |), two (Separator ;) or 
				% three (separator $) dimensional
				tmp_entry_matrizes  = strsplit(tmp_entry, '$');
				tmp_cube = [];
				if ~( isempty(tmp_entry_matrizes{1}))
					for gg = 1 : 1 : length(tmp_entry_matrizes)
						tmp_matrix = [];
						tmp_entry_rows = strsplit(tmp_entry_matrizes{gg}, ';');
						if ~( isempty(tmp_entry_rows{1}))
							tmp_entry = [];
							for pp = 1 : 1 : length(tmp_entry_rows)  
								tmp_cols = [];
								tmp_entry_split = strsplit(tmp_entry_rows{pp}, '|');

								if ~( isempty(tmp_entry_split{1}))
									% loop through all shockvalueand convert it to numbers
									for ll = 1 : 1 : length(tmp_entry_split)    
										tmp_cols = cat(2,tmp_cols, str2num(tmp_entry_split{ll}) );
									end
								end
								% append tmp_cols to tmp_matrix
								tmp_matrix = cat(1,tmp_matrix, tmp_cols );
							end
						end
						% append tmp_matrix to tmp_cube
						tmp_cube = cat(3,tmp_cube,tmp_matrix);
					end
				end
				tmp_entry = tmp_cube;
			elseif ( strcmp(tmp_columnname,'axis_x')) % split into cell
				tmp_entry_split = strsplit(tmp_entry, '|');
				tmp_entry = [];
				%lsplit = tmp_entry_split{1};
				if ~( isempty(tmp_entry_split{1}))
					% loop through all shift types and convert it to numbers
					for ll = 1 : 1 : length(tmp_entry_split)    
						tmp_entry = [tmp_entry, str2num(tmp_entry_split{ll}) ];
					end
				end
			elseif ( strcmp(tmp_columnname,'axis_y')) % split into cell
				tmp_entry_split = strsplit(tmp_entry, '|');
				tmp_entry = [];
				%lsplit = tmp_entry_split{1};
				if ~( isempty(tmp_entry_split{1}))
					% loop through all shift types and convert it to numbers
					for ll = 1 : 1 : length(tmp_entry_split)    
						tmp_entry = [tmp_entry, str2num(tmp_entry_split{ll}) ];
					end
				end 
			elseif ( strcmp(tmp_columnname,'axis_z')) % split into cell
				tmp_entry_split = strsplit(tmp_entry, '|');
				tmp_entry = [];
				%lsplit = tmp_entry_split{1};
				if ~( isempty(tmp_entry_split{1}))
					% loop through all shift types and convert it to numbers
					for ll = 1 : 1 : length(tmp_entry_split)    
						tmp_entry = [tmp_entry, str2num(tmp_entry_split{ll}) ];
					end
				end 
			elseif ( strcmp(tmp_columnname,'risktype'))  % split into cell
				try
					tmp_entry = strsplit( tmp_entry, '|');
				catch
					tmp_entry = {};
				end 
			end % end special case
		catch
			fprintf('Object attribute %s could not be set. ',tmp_columnname); 
			fprintf('There was an error: %s\n',lasterr);
			error_flag = 1;
		end
		% B.3b.ii) Store attribute in cell 
		%           (which will be converted to struct later)
		try
			% jj -> rownumber
			% mm -> columnnumber
			tmp_cell_struct{mm - 1, jj - 1} = tmp_entry;
		catch
			error_flag = 1;
		end
		
	end  % end for loop via all attributes
	% save entries in struct
	% save stresstest id
	tmpvec = 1:1:length(tmp_colname)';
	stress_id = tmp_cell_struct{ strcmpi(tmp_colname,'id') * tmpvec' ,jj-1};
	stress_name = tmp_cell_struct{ strcmpi(tmp_colname,'name') * tmpvec' ,jj-1 };
	
	% check whether stress already exists
	
	[substruct retcode_substruct] = get_sub_struct(stresstest_struct,stress_id);
	if ( retcode_substruct == 0)
		substruct = struct();
		substruct.id = stress_id;
		substruct.name = stress_name;
		substruct.objects = '';
	end
	
	% store all other attributes in object substruct
	% a) save attribute values into temporary variables
		if ( strcmpi(tmp_colname,'object') * tmpvec' > 0)
			tmp_objects_id = tmp_cell_struct{ strcmpi(tmp_colname,'object') * tmpvec' ,jj-1 };
		else
			tmp_objects_id = 'Dummy';
		end
		
		if ( strcmpi(tmp_colname,'objecttype') * tmpvec'  > 0)
			tmp_type = tmp_cell_struct{ strcmpi(tmp_colname,'objecttype') * tmpvec' ,jj-1 };
		else
			tmp_type = 'curve';
		end
		
		if ( strcmpi(tmp_colname,'shocktype') * tmpvec' > 0)
			tmp_shock_type = tmp_cell_struct{ strcmpi(tmp_colname,'shocktype') * tmpvec' ,jj-1 };
		else
			tmp_shock_type = 'relative';
		end
		
		if ( strcmpi(tmp_colname,'term') * tmpvec' > 0)
			tmp_term = tmp_cell_struct{ strcmpi(tmp_colname,'term') * tmpvec' ,jj-1 };
		else
			tmp_term = [365];
		end
		
		% set x,y,z axis
		if ( strcmpi(tmp_colname,'axis_x') * tmpvec' > 0)
			tmp_axis_x = tmp_cell_struct{ strcmpi(tmp_colname,'axis_x') * tmpvec' ,jj-1 };
		else
			tmp_axis_x = [365];
		end
		if ( strcmpi(tmp_colname,'axis_y') * tmpvec' > 0)
			tmp_axis_y = tmp_cell_struct{ strcmpi(tmp_colname,'axis_y') * tmpvec' ,jj-1 };
		else
			tmp_axis_y = [365];
		end
		if ( strcmpi(tmp_colname,'axis_z') * tmpvec' > 0)
			tmp_axis_z = tmp_cell_struct{ strcmpi(tmp_colname,'axis_z') * tmpvec' ,jj-1 };
		else
			tmp_axis_z = [365];
		end
		
		if ( strcmpi(tmp_colname,'method_interpolation') * tmpvec' > 0)
			tmp_method_interpolation = tmp_cell_struct{ strcmpi(tmp_colname,'method_interpolation') * tmpvec' ,jj-1 };
		else
			tmp_method_interpolation = 'linear';
		end
		
		if ( strcmpi(tmp_colname,'shockvalue') * tmpvec' > 0)
			tmp_shock_value = tmp_cell_struct{ strcmpi(tmp_colname,'shockvalue') * tmpvec' ,jj-1 };
		else
			tmp_shock_value = 1;
		end
	%b) fill object struct attributes
	[object_struct_tmp retcode] = get_sub_struct(substruct.objects,tmp_objects_id);
	if ( retcode == 0)
		object_struct = substruct.objects;
		index = length(object_struct) + 1;
		object_struct( index ).id = tmp_objects_id;
		object_struct( index ).type = tmp_type;
		object_struct( index ).shock_type = tmp_shock_type;
		object_struct( index ).term = tmp_term;
		object_struct( index ).axis_x = tmp_axis_x;
		object_struct( index ).axis_y = tmp_axis_y;
		object_struct( index ).axis_z = tmp_axis_z;
		object_struct( index ).method_interpolation = tmp_method_interpolation;
		object_struct( index ).shock_value = tmp_shock_value;
	else
		fprintf('WARNING: duplicate entriy for stress >>%s<< and object id >>%s<<. Ignoring duplicate entry.\n',any2str(stress_id),any2str(tmp_objects_id));
		object_struct = substruct.objects;
	end
	% store everything in stresstest_struct
	if ( retcode_substruct == 0)
		index = length(stresstest_struct) + 1;
		stresstest_struct( index ).id = stress_id;
		stresstest_struct( index ).name = stress_name;
		stresstest_struct( index ).objects = object_struct;
	else % overwrite existing stresstest_struct object attribute
		id_cell = {stresstest_struct.id};
		tmpvec = 1:1:length(id_cell);
		index_value = strcmpi(id_cell,stress_id) * tmpvec';
		stresstest_struct( index_value ).objects = object_struct;
	end
	

	% B.3c) Error checking for riskfactor: 
	if ( error_flag > 0 )
		fprintf('ERROR: There has been an error for ');
		fprintf('riskfactor: %s \n',tmp_cell_struct{1, jj - 1});
		id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_cell_struct{1, jj - 1};
		error_flag = 0;
	else
		error_flag = 0;
		number_stresstests = number_stresstests + 1;
	end
  end   % end if loop with meaningful data
end  % next position / next row in specification


% TODO: if several IR vol slices are defined, stack them into one final cube
%		per stresstest


% C) return final position objects  
fprintf('SUCCESS: loaded >>%d<< stresstests. \n',number_stresstests);
if (length(id_failed_cell) > 0 )
    fprintf('WARNING: >>%d<< positions failed: \n',length(id_failed_cell));
    id_failed_cell
end

% clean up

% D) move all parsed files to an TAR in folder archive
if (archive_flag == 1)
    try
        tarfiles = tar( strcat(path_archive,'/archive_stresstests_', ...
                                    tmp_timestamp,'.tar'),strcat(path,'/*'));
    end
end

end % end function

%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
%# Copyright (C) 2009-2014 Pascal Dupuis <cdemills@gmail.com> (code reuse of his dataframe package)
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
%# @deftypefn {Function File} {[@var{mktdata_struct} @var{id_failed_cell}] =} load_mktdata_objects(@var{mktdata_struct}, @var{path_mktdata}, @var{file_mktdata}, @var{path_output}, @var{path_archive}, @var{tmp_timestamp}, @var{archive_flag})
%# Load data from mktdata object specification file and generate objects with parsed data. Store all objects in provided mktdata struct and return the final struct and a cell containing the failed mktdata ids.
%# @end deftypefn

function [corr_matrix cell_unique] = load_correlation_matrix(path_mktdata,file_corr_matrix,path_archive,tmp_timestamp,archive_flag)

% A) Prepare instrument object generation
% A.0) Specify local variables
separator = ',';
file_corrmatrix_in = strcat(path_mktdata,'/',file_corr_matrix);

% B) Loop through correlation file

% B.1) parse input data
in = fileread(file_corrmatrix_in);
% ==========================================================
% use custom design for data import -> Copyright (C) 2009-2014 Pascal Dupuis <cdemills@gmail.com>: 
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
		if (~( regexpi(tmp_lines,'%') || regexpi(tmp_lines,'#')) && ~isempty(tmp_lines))
			dummy_eol = dummy(kk);
			if ( length(tmp_lines)>1)
				lines_out{ length(lines_out) + 1} = tmp_lines(1:dummy_eol-1);
			end
		end
	  end

  %# extract fields
  content = cellfun (@(x) strsplit (x, separator, 'collapsedelimiters', false), lines_out, ...
                       'UniformOutput', false); %# extract fields           
% ==========================================================
% B.2a) extract header from first row:
tmp_header = content{1};
tmp_colname = {};

for kk = 1 : 1 : length(tmp_header)
    tmp_item = tmp_header{kk};
    tmp_header_type{kk} = tmp_item(end-3:end); % extract last 4 characters
    tmp_colname{kk} = tmp_item(1:end-4); %substr(tmp_item, 1, length(tmp_item)-4);  % remove last 4 characters from colname
end   

% B.2b) get unique risk factors in input cell (remove all other values except items starting with 'RF_')
cell_unique = {};
for jj = 2 : 1 : length(content)
    tmp_cell = content{jj};
    for mm = 1 : 1 : 2
        cell_unique{ length(cell_unique) + 1 } = tmp_cell{mm};
    end
end
cell_unique = unique(cell_unique);


% B.2c) reserve correlation matrix (order of entries follows cell_unique);
corr_matrix = eye(length(cell_unique));

% B.3) loop through all correlations 
number_set_corr = 0;  
for jj = 2 : 1 : length(content)
    error_flag = 0;
    % B.3b)  Loop through all attributes
    tmp_cell = content{jj};
    rf1_id = '';
    rf2_id = '';
    corr_rf1_rf2 = 0.0;
    for mm = 1 : 1 : length(tmp_cell)   % loop via all entries in row and set object attributes
        tmp_columnname = lower(tmp_colname{mm});
        tmp_cell_item = tmp_cell{mm};
        tmp_cell_type = upper(tmp_header_type{mm});
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
        else
            fprintf('Type not supported for correlation matrix: >>%s<< for item value >>%s<<. Aborting: >>%s<< \n',tmp_cell_type,tmp_cell_item,lasterr);
        end
        % fprintf('Trying to store item:');
            % tmp_cell_item
        % fprintf('of type: ');
            % tmp_cell_type
        % fprintf(' into column: ');
            % tmp_columnname
        % fprintf('\n');
        % B.3b.ii) Store attributes in temporary variables
        if ( mm == 1 )
            rf1_id = tmp_entry;
        elseif  ( mm == 2 )
            rf2_id = tmp_entry; 
        elseif ( mm == 3 )
            corr_rf1_rf2 = tmp_entry; 
        end
    end
    % B.3c) Store attributes in corr matrix
        % extract index of corresponding risk factors
        idx_rf1= find(ismember(upper(cell_unique),rf1_id));
        idx_rf2= find(ismember(upper(cell_unique),rf2_id));
        % symmetric storage in matrix
        corr_matrix(idx_rf1,idx_rf2) = corr_rf1_rf2;
        corr_matrix(idx_rf2,idx_rf1) = corr_rf1_rf2;
        if ~( idx_rf1 == idx_rf2)   % count correlations only if elements stored not on diagonal
            number_set_corr = number_set_corr + 1;
        end
end  % next next row in specification

% B.4) checking, whether all correlations have been set:
number_rf       = length(cell_unique);
number_theo_corr = (number_rf * (number_rf - 1 )) / 2;  % total number of correlations (lower triangular matrix elements)
if ~( (number_theo_corr == number_set_corr) ) 
    error('ERROR: Not enough correlations (>>%d<<) specified to total number of risk factors >>%d<<. Expected: >>%d<< \n',number_set_corr,number_rf,number_theo_corr);
end

% C) return final matrix and cells  
fprintf('SUCCESS: loaded correlations for >>%d<< riskfactors. \n',number_rf);

% D) save correlation matrix to folder archive
if (archive_flag == 1)
    try
        tmp_filename = strcat(path_archive,'/archive_corr_matrix_',tmp_timestamp,'.dat');
        save ('-text',tmp_filename,'corr_matrix');
    end
end

% finished loading correlations into matrix
end % end function

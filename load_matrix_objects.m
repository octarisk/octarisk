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
%# @deftypefn {Function File} {[@var{matrix_struct} @var{matrix_failed_cell}] =} load_matrix_objects(@var{matrix_struct}, @var{path_mktdata}, @var{input_filename_matrix_index})
%# Load data from mktdata matrix object specification files and 
%# generate a struct with parsed data. Store all objects in provided struct 
%# and return the final struct and a cell containing the failed matrix ids.
%# @end deftypefn

function [matrix_struct matrix_failed_cell] = load_matrix_objects(matrix_struct, ...
                  path_mktdata,input_filename_matrix_index)

% Get list of all files in mktdata folder
tmp_list_files = dir(path_mktdata);

matrix_failed_cell = {};
tmp_len_struct = 0;
% Store marketdata in matrix_struct
for ii = 1 : 1 : length(tmp_list_files)
    tmp_filename = tmp_list_files( ii ).name;
    try % try to find a match between file in mktdata folder and provided string 
      % for correlation matrix
        if ( regexp(tmp_filename,input_filename_matrix_index) == 1)      
            % load matrix values and component cell
            [corr_matrix cell_unique] = load_correlation_matrix(path_mktdata,tmp_filename,'','',0);
            % Generate object and store data
            % remove first string identifying file
            tmp_id = strrep(tmp_filename,input_filename_matrix_index,''); 
            tmp_id = strrep(tmp_id,'.dat',''); % remove file ending
            tmp_matrix_object = Matrix(tmp_id);
            tmp_matrix_object = tmp_matrix_object.set('type','Correlation');     
            tmp_matrix_object = tmp_matrix_object.set('components',cell_unique, ...
                                'matrix',corr_matrix);
            
            matrix_struct( tmp_len_struct + 1).id = tmp_id;
            matrix_struct( tmp_len_struct + 1).object = tmp_matrix_object;
            tmp_len_struct = length(matrix_struct);
        else    % if there is no match do nothing
            tmp_id = 'Nothing found';
        end 
    catch
        fprintf('WARNING: There has been an error for file: >>%s<<',tmp_filename);
        fprintf('and vola object id: >>%s<<. Aborting: >>%s<<\n',tmp_id,lasterr);
        matrix_failed_cell{ length(matrix_failed_cell) + 1 } =  tmp_filename;
    end  % end try catch
end % end of for loop of all files

fprintf('SUCCESS: loaded >>%d<< matrix objects. \n',tmp_len_struct);

end % end of function

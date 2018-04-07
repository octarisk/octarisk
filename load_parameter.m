%# Copyright (C) 2017 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{parameter_struct} @var{id_failed_cell}] =} load_parameter(@var{path_parameter}, @var{filename_parameter})
%# Load data from parameter specification file and generate parameter object with parsed data.
%# @end deftypefn

function [para_struct id_failed_cell] = load_parameter(path_parameter,filename_parameter)

% A) Prepare loading input from file
% A.0) Specify local variables
separator = ',';
path_parameter_file = strcat(path_parameter,'/',filename_parameter);
id_failed_cell = {};

% A.2) read in whole instruments file with
in = fileread(path_parameter_file);
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
            error('load_riskfactors: binary garbage in the input file >>%s<<?',tmp_filename);
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

% A.4) loop via all entries of cell and save into files per riskfactor type
parameter_number = 0;
para_struct = struct();
for ii = 1 : 1 : length(content);
    tmp_entries = content{ii};
    parameter_number = parameter_number + 1;
    tmp_item = tmp_entries{1};
    tmp_type = strtrim(tmp_item(end-3:end)); % extract last 4 characters
    tmp_attribute = strtrim(tmp_item(1:end-4));
    tmp_value = strtrim(tmp_entries{2});

    % store attribute in struct
    if (strcmpi(tmp_type,'BOOL'))
        if ( strcmpi(tmp_value,'true') || strcmpi(tmp_value,'1'))
            tmp_value = true;
        else
            tmp_value = false;
        end
    elseif (strcmpi(tmp_type,'DATE'))
        try
            if (ischar(tmp_value))
                tmp_value = datenum(tmp_value);
            elseif (isnumeric(tmp_value))
                tmp_value = tmp_value;
            else
                error('load_parameter: Unknown Dateformat %s',tmp_value);
            end
        catch
            fprintf('WARNING: load_parameter: item/value %s/%s is not a date. Setting to [].\n',tmp_item,tmp_entries{2});
            tmp_value = [];
            id_failed_cell{ length(id_failed_cell) + 1 } = tmp_item;
        end
    elseif (strcmpi(tmp_type,'NMBR'))
        try
            tmp_value = str2num(tmp_value);
            if ( isempty(tmp_value) )
                fprintf('WARNING: load_parameter: item/value %s/%s is not numeric. Setting to [].\n',tmp_item,tmp_entries{2});
                tmp_value = [];
                id_failed_cell{ length(id_failed_cell) + 1 } = tmp_item;
            end
        catch
            fprintf('WARNING: load_parameter: item/value %s/%s is not numeric. Setting to [].\n',tmp_item,tmp_entries{2});
            tmp_value = [];
            id_failed_cell{ length(id_failed_cell) + 1 } = tmp_item;
        end
    elseif (strcmpi(tmp_type,'CHAR'))
        %tmp_value = tmp_value
    elseif (strcmpi(tmp_type,'CELL'))
        try
            tmp_value = strsplit(tmp_value,'|');
        catch
            fprintf('WARNING: load_parameter: item/value %s/%s is not a cell. Setting to {}.\n',tmp_item,tmp_entries{2});
            tmp_value = {};
            id_failed_cell{ length(id_failed_cell) + 1 } = tmp_item;
        end
    else
        fprintf('WARNING: load_parameter: attribute/type %s/%s undefined\n',tmp_attribute,tmp_type);
    end
    para_struct.( tmp_attribute  ) = tmp_value;
end

% convert struct to object
para_struct.type = 'Parameter';
para_struct = struct2obj(para_struct);

% C) return final riskfactor objects
fprintf('SUCCESS: loaded >>%d<< parameter. \n',parameter_number);
if (length(id_failed_cell) > 0 )
    fprintf('WARNING: >>%d<< parameters failed: \n',length(id_failed_cell));
    id_failed_cell
end

end % end function

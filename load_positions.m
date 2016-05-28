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
%# @deftypefn {Function File} {[@var{portfolio_struct} @var{id_failed_cell}] =} load_positions(@var{portfolio_struct}, @var{valuation_date}, @var{path_positions}, @var{file_positions}, @var{path_output}, @var{path_archive}, @var{tmp_timestamp}, @var{archive_flag})
%# Load data from position specification file and generate objects with parsed data. Store all objects in provided position struct and return the final struct and a cell containing the failed position ids.
%# @end deftypefn

function [tmp_portfolio_struct id_failed_cell] = load_positions(portfolio_struct, path_positions,file_positions,path_output,path_archive,tmp_timestamp,archive_flag)

% A) Prepare position object generation
% A.0) Specify local variables
separator = ',';
path_positions_in = strcat(path_positions,'/',file_positions);
path = path_output;

% A.1) delete all old files in path_output
oldfiles = dir(path);
try
    for ii = 1 : 1 : length(oldfiles)
            tmp_file = oldfiles(ii).name;
            if ( length(tmp_file) > 3 )
                delete(strcat(path,'/',tmp_file));
            end
    end
end    
% A.2) read in whole instruments file with
strtmp = fileread(path_positions_in); 

% A.3) split file according to 'Header'
celltmp = strsplit(strtmp,'Header');

   
% A.4) open file for printing all comments
file_comments = fopen( strcat(path,'/','comments.txt'), 'a');   

% A.6) loop via all entries of cell and save into files per position type
for ii = 1 : 1 : length(celltmp);
    tmp_entries = celltmp{ii};
    if ( regexp(tmp_entries,'#') == 1)    % comment -> skip  print comment to stdout
        fprintf(file_comments, 'Comment found: %s\n',tmp_entries); 
    elseif ( ~isempty(tmp_entries) )
        % extract filename:
        tmp_split_entries = strsplit(tmp_entries,',');
        tmp_rf_type = strtrim(tmp_split_entries{1});
        if ( length(tmp_rf_type) > 1 )
            % save to file
            filename = strcat(path,'/',tmp_rf_type,'.csv');
            %fprintf('Saving position type: >>%s<< to file %s \n',tmp_rf_type ,filename);
            fid = fopen (filename, 'w');
            fprintf(fid, '%s\n',tmp_entries);
            % Close file
            fclose (fid);   
        end
    end
end
fclose (file_comments); % close comments file


% B) Loop through all position files -> loop through all rows (first row = header), for each row loop through all columns = attributes -> store attributes in cell
tmp_list_files = dir(path); % load all files of directory path into cell
number_positions = 0;
number_portfolios = 0;
id_failed_cell = {};
tmp_position_struct = struct();
tmp_portfolio_struct = portfolio_struct;
for ii = 1 : 1 : length(tmp_list_files)
    tmp_filename = tmp_list_files( ii ).name;
    
    if (length(tmp_filename) > 3 && strcmp(tmp_filename,'comments.txt') == 0) 
        % B.1) parse input data
        tmp_filename = strcat(path,'/',tmp_filename);
        in = fileread(tmp_filename);
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
                dummy_eol = dummy(kk);
                if ( length(tmp_lines)>1)
                    lines_out{kk} = tmp_lines(1:dummy_eol-1);
                end
          end

          %# extract fields
          content = cellfun (@(x) strsplit (x, separator, 'collapsedelimiters', false), lines_out, ...
                               'UniformOutput', false); %# extract fields              
        % ==========================================================
        % B.2) extract header from first row:
        tmp_header = content{1};
        tmp_colname = {};
        tmp_position_type = strtrim(tmp_header{1});
        %fprintf('>>>%s<<<\n',tmp_instrument_type);
        for kk = 2 : 1 : length(tmp_header)
            tmp_item = tmp_header{kk};
            tmp_header_type{kk-1} = tmp_item(end-3:end); % extract last 4 characters
            tmp_colname{kk-1} = tmp_item(1:end-4); %substr(tmp_item, 1, length(tmp_item)-4);  % remove last 4 characters from colname
        end  
        % B.3) loop through all entries of file 
        
        tmp_cell_struct = {};           
        for jj = 2 : 1 : length(content)
          error_flag = 0;
          if (length(content{jj}) > 3)  % parse row only if it contains some meaningful data
            
            % B.3b)  Loop through all position attributes
            tmp_cell = content{jj};
            for mm = 2 : 1 : length(tmp_cell)   % loop via all entries in row and set object attributes
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
                            if ( strcmp('false',lower(tmp_cell_item)) || strcmp('0',tmp_cell_item))
                                tmp_entry = 0;
                            elseif ( strcmp('true',lower(tmp_cell_item)) || strcmp('1',tmp_cell_item) )
                                tmp_entry = 1;
                            end
                        end  
                    catch
                        fprintf('Item >>%s<< is not a BOOL: %s \n',tmp_cell_item,lasterr);
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
                    fprintf('Unknown type: >>%s<< for item value >>%s<<. Aborting: >>%s<< \n',tmp_cell_type,tmp_cell_item,lasterr);
                end
                 % fprintf('Trying to store item:');
                     % tmp_entry
                 % fprintf('of type: ');
                     % tmp_cell_type
                 % fprintf(' into column: ');
                     % tmp_columnname
                 % fprintf('\n');
                % B.3b.ii) Store attribute in cell (which will be converted to struct later)
                try
                    % jj -> rownumber
                    % mm -> columnnumber
                    tmp_cell_struct{mm - 1, jj - 1} = tmp_entry;
                catch
                    error_flag = 1;
                end
            end  % end for loop via all attributes
            % B.3c) Error checking for riskfactor: 
            if ( error_flag > 0 )
                fprintf('ERROR: There has been an error for riskfactor: %s \n',tmp_cell_struct{1, jj - 1});
                id_failed_cell{ length(id_failed_cell) + 1 } =  tmp_cell_struct{1, jj - 1};
                error_flag = 0;
            else
                error_flag = 0;
                if ( strcmp(upper(tmp_position_type),'PORTFOLIO'))
                    number_portfolios = number_portfolios + 1;
                elseif ( strcmp(upper(tmp_position_type),'POSITION'))
                    number_positions = number_positions + 1;
                end
                number_positions = number_positions + 1;
            end
          end   % end if loop with meaningful data
        end  % next position / next row in specification

        if ( strcmp(upper(tmp_position_type),'PORTFOLIO'))
            tmp_portfolio_struct = cell2struct(tmp_cell_struct,tmp_colname);
        elseif ( strcmp(upper(tmp_position_type),'POSITION'))
            tmp_position_struct = cell2struct(tmp_cell_struct,tmp_colname);
        else
            fprintf('Unknown type. Neither position nor portfolio');
        end
        
        
    end         % meaningful file
end          % next file with specifications
% finished loading position into struct -> consolidate structure
for kk = 1 : 1 : length(tmp_portfolio_struct)
    tmp_port_id = tmp_portfolio_struct( kk ).id;
    tmp_match_port_pos = strcmp(tmp_port_id,{tmp_position_struct.port_id});
    idx = 1;
    for ll = 1 : 1 : length(tmp_match_port_pos)
        if ( tmp_match_port_pos(ll) == 1 )
            tmp_portfolio_struct( kk ).position(idx) = tmp_position_struct(ll);
            idx = idx + 1;
        end
    end   
end

% C) return final position objects  
fprintf('SUCCESS: loaded >>%d<< positions. \n',number_positions);
fprintf('SUCCESS: loaded >>%d<< portfolios. \n',number_portfolios);
if (length(id_failed_cell) > 0 )
    fprintf('WARNING: >>%d<< positions failed: \n',length(id_failed_cell));
    id_failed_cell
end

% clean up

% D) move all parsed files to an TAR in folder archive
if (archive_flag == 1)
    try
        tarfiles = tar( strcat(path_archive,'/archive_positions_',tmp_timestamp,'.tar'),strcat(path,'/*'));
    end
end

end % end function
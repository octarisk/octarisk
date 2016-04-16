## Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
## Copyright (C) 2009-2014 Pascal Dupuis <cdemills@gmail.com> (code reuse of his dataframe package)
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{riskfactor_struct} @var{id_failed_cell}} = load_riskfactors(@var{riskfactor_struct},@var{valuation_date},@var{path_riskfactors},@var{file_riskfactors},@var{path_output},@var{path_archive},@var{tmp_timestamp})
## Load data from riskfactor specification file and generate objects with parsed data. Store all objects in provided riskfactor struct and return the final struct and a cell containing the failed riskfactor ids.
## @end deftypefn

function [riskfactor_struct id_failed_cell] = load_riskfactors(riskfactor_struct,path_riskfactors,file_riskfactors,path_output,path_archive,tmp_timestamp)

% A) Prepare riskfactor object generation
% A.0) Specify local variables
separator = ',';
path_riskfactors_in = strcat(path_riskfactors,'/',file_riskfactors);
path = path_output;

% A.1) delete all old files in path_output
oldfiles = dir(path);
try
    for ii = 1 : 1 : length(oldfiles)
            tmp_file = oldfiles(ii).name;
            if ( length(tmp_file) > 3 )
                delete(strcat(path,'/',tmp_file));
            endif
    end
end    
% A.2) read in whole instruments file with
strtmp = fileread(path_riskfactors_in); 

% A.3) split file according to 'Header'
celltmp = strsplit(strtmp,'Header');

   
% A.4) open file for printing all comments
file_comments = fopen( strcat(path,'/','comments.txt'), 'a');   

% A.6) loop via all entries of cell and save into files per riskfactor type
for ii = 1 : 1 : length(celltmp);
    tmp_entries = celltmp{ii};
    if ( regexp(tmp_entries,'#') == 1)    % comment -> skip  print comment to stdout
        fprintf(file_comments, 'Comment found: %s\n',tmp_entries);  
    else        % parse entry
        % extract filename:
        tmp_split_entries = strsplit(tmp_entries,',');
        tmp_rf_type = strtrim(tmp_split_entries{1});
        if ( length(tmp_rf_type) > 1 )
            % save to file
            filename = strcat(path,'/',tmp_rf_type,'.csv');
            %fprintf('Saving riskfactor type: >>%s<< to file %s \n',tmp_rf_type ,filename);
            fid = fopen (filename, 'w');
            fprintf(fid, '%s\n',tmp_entries);
            % Close file
            fclose (fid);   
        endif
    endif
endfor
fclose (file_comments); % close comments file


% B) Loop through all riskfactor files
tmp_list_files = dir(path); % load all files of directory path into cell
number_riskfactors = 0;
id_failed_cell = {};
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
          %# use a positive lookahead -- eol is not part of the match
          lines(dummy > 1) = cellfun (@(x) regexp (x, ['.*?(?=' eol ')'], ...
                                                   'match'), lines(dummy > 1));
          %# a field either starts at a word boundary, either by + - . for
          %# a numeric data, either by ' for a string. 
          %# content = cellfun(@(x) regexp(x, '(\b|[-+\.''])[^,]*(''|\b)', 'match'),\
          %# lines, 'UniformOutput', false); %# extract fields
          content = cellfun (@(x) strsplit (x, separator, 'collapsedelimiters', false), lines, ...
                               'UniformOutput', false); %# extract fields               
        % ==========================================================
        % B.2) extract header from first row:
        tmp_header = content{1};
        tmp_colname = {};
        tmp_riskfactor_type = strtrim(tmp_header{1});
        %fprintf('>>>%s<<<\n',tmp_instrument_type);
        for kk = 2 : 1 : length(tmp_header)
            tmp_item = tmp_header{kk};
            tmp_header_type{kk-1} = substr(tmp_item,-4);  % extract last 4 characters
            tmp_colname{kk-1} = substr(tmp_item, 1, length(tmp_item)-4);  % remove last 4 characters from colname
        endfor   
        % B.3) loop through all instruments   
        for jj = 2 : 1 : length(content)
          error_flag = 0;
          if (length(content{jj}) > 3)  % parse row only if it contains some meaningful data
            % B.3a) Generate object of appropriate class
            i = Riskfactor();   % generate Riskfactor object
           
            % B.3b)  Loop through all riskfactor attributes
            tmp_cell = content{jj};
            for mm = 2 : 1 : length(tmp_cell)   % loop via all entries in row and set object attributes
                tmp_columnname = tolower(tmp_colname{mm-1});
                tmp_cell_item = tmp_cell{mm};
                tmp_cell_type = toupper(tmp_header_type{mm-1});
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
                            if ( strcmp('false',tolower(tmp_cell_item)) || strcmp('0',tmp_cell_item))
                                tmp_entry = 0;
                            elseif ( strcmp('true',tolower(tmp_cell_item)) || strcmp('1',tmp_cell_item) )
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
                % B.3b.ii) Store attribute in object
                try
                    % special case: cf_dates and cf_values come as vectors
                    % set new attribute, no special treatment
                    if ( ischar(tmp_entry))
                        if (length(tmp_entry)>0)
                            i = i.set(tmp_columnname,tmp_entry);
                        end
                    else
                        i = i.set(tmp_columnname,tmp_entry);
                    endif
                catch
                    fprintf('Object attribute %s could not be set. There was an error: %s\n',tmp_columnname,lasterr);
                    error_flag = 1;
                end
            endfor
            %disp('=== Final Object ===')
            %i     
            % B.3c) Error checking for riskfactor: 
            if ( error_flag > 0 )
                fprintf('ERROR: There has been an error for riskfactor: %s \n',i.id);
                id_failed_cell{ length(id_failed_cell) + 1 } =  i.id;
                error_flag = 0;
            else
                error_flag = 0;
                number_riskfactors = number_riskfactors + 1;
                riskfactor_struct( number_riskfactors ).id = i.id;
                riskfactor_struct( number_riskfactors ).name = i.id;
                riskfactor_struct( number_riskfactors ).object = i;
            endif
          %  fprintf('Seems to be empty row. Skipping.\n');
          end   % end if loop with meaningful data
        endfor  % next riskfactor / next row in specification
        
    end         % meaningful file
endfor          % next file with specifications
% finished loading riskfactor into object

% C) return final riskfactor objects  
fprintf('SUCCESS: loaded >>%d<< riskfactors. \n',number_riskfactors);
if (length(id_failed_cell) > 0 )
    fprintf('WARNING: >>%d<< riskfactors failed: \n',length(id_failed_cell));
    id_failed_cell
end

% clean up

% D) move all parsed files to an TAR in folder archive
try
    tarfiles = tar( strcat(path_archive,'/archive_riskfactors_',tmp_timestamp,'.tar'),strcat(path,'/*'));
end

end % end function
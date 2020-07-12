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
%# @deftypefn {Function File} {[@var{instrument_struct} @var{id_failed_cell}] =} load_instruments(@var{instrument_struct}, @var{valuation_date}, @var{path_instruments}, @var{file_instruments}, @var{path_output}, @var{path_archive}, @var{tmp_timestamp}, @var{archive_flag})
%# Load data from instrument specification file and generate objects with parsed data. 
%# Store and return all objects in provided instrument structure. 
%# and a cell containing the failed instrument ids.
%# The order of the final instrument structure is automatically set that all 
%# derivatives (OPT,SWAPT,SYNTH) are coming last.
%# @end deftypefn

function [instrument_struct id_failed_cell] = load_instruments(instrument_struct,valuation_date,path_instruments,file_instruments,path_output,path_archive,tmp_timestamp,archive_flag)

% A) Prepare instrument object generation
% A.0) Specify local variables
separator = ',';
path_instruments_in = strcat(path_instruments,'/',file_instruments);
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
strtmp = fileread(path_instruments_in); 

% A.3) split file according to 'Header'
celltmp = strsplit(strtmp,'Header');

 
% A.4) open file for printing all comments
file_comments = fopen( strcat(path,'/','comments.txt'), 'a');   

% A.6) loop via all entries of cell and save into files per instrument type
for ii = 1 : 1 : length(celltmp);
    tmp_entries = celltmp{ii};
    if ( regexp(tmp_entries,'#') == 1)    % comment -> skip  print comment to stdout
        fprintf(file_comments, 'Comment found: %s\n',tmp_entries); 
    elseif ( ~isempty(tmp_entries) )
        % extract filename:
        tmp_split_entries = strsplit(tmp_entries,',');
        tmp_producttype = strtrim(tmp_split_entries{1});
        % save to file
        filename = strcat(path,'/',tmp_producttype,'.csv');
        %fprintf('Saving instrument type: %s to file %s \n',tmp_producttype ,filename);
        fid = fopen (filename, 'w');
        fprintf(fid, '%s\n',tmp_entries);
        % Close file
        fclose (fid);        
    end
end
fclose (file_comments); % close comments file


% B) Loop through all instrument files
tmp_list_files = dir(path); % load all files of directory path into cell

% B.i) Sort tmp_list_files in the following order: last three instrument types are SWAPTION, OPTION and SYNTHETIC
%       then it is assured that all instruments, which serve as underlyings for these three types, already are valuated before calculating derivatives
  % 1. move SWAPTION to last entry in tmp_filelist
    for ii = 1 : 1 : length(tmp_list_files)
        tmp_filename = tmp_list_files( ii ).name;
        if (strcmpi(tmp_filename(1:end-4),'SWAPT'))
            tmp_list_files(end + 1 ) = tmp_list_files( ii );    % append SWAPT entry behind last entry of struct
            tmp_list_files(ii) = [];                            % remove SWAPT entry           
        end
    end
  % 2. move CAPFLOOR to last entry in tmp_filelist
    for ii = 1 : 1 : length(tmp_list_files)
        tmp_filename = tmp_list_files( ii ).name;
        if (strcmpi(tmp_filename(1:end-4),'CAPFLOOR'))
            tmp_list_files(end + 1 ) = tmp_list_files( ii );    % append CAPFLOOR entry behind last entry of struct
            tmp_list_files(ii) = [];                            % remove CAPFLOOR entry           
        end
    end
  % 3. move OPTION to last entry in tmp_filelist
    for ii = 1 : 1 : length(tmp_list_files)
        tmp_filename = tmp_list_files( ii ).name;
        if (strcmpi(tmp_filename(1:end-4),'OPT'))
            tmp_list_files(end + 1 ) = tmp_list_files( ii );    % append OPT entry behind last entry of struct
            tmp_list_files(ii) = [];                            % remove OPT entry           
        end
    end
  % 4. move FORWARD to last entry in tmp_filelist
    for ii = 1 : 1 : length(tmp_list_files)
        tmp_filename = tmp_list_files( ii ).name;
        if (strcmpi(tmp_filename(1:end-4),'FWD'))
            tmp_list_files(end + 1 ) = tmp_list_files( ii );    % append FWD entry behind last entry of struct
            tmp_list_files(ii) = [];                            % remove FWD entry           
        end
    end
  % 5. move SYNTHETICs to last entry in tmp_filelist
    for ii = 1 : 1 : length(tmp_list_files)
        tmp_filename = tmp_list_files( ii ).name;
        if (strcmpi(tmp_filename(1:end-4),'SYNTH'))
            tmp_list_files(end + 1 ) = tmp_list_files( ii );    % append SYNTH entry behind last entry of struct
            tmp_list_files(ii) = [];                            % remove SYNTH entry           
        end
    end

% B.ii) parse files
number_instruments = 0;
id_failed_cell = {};
for ii = 1 : 1 : length(tmp_list_files)
    tmp_filename = tmp_list_files( ii ).name;
    if (length(tmp_filename) > 3 && strcmp(tmp_filename,'comments.txt') == 0) 
        % B.1) parse input data
        tmp_filename = strcat(path,'/',tmp_filename);
        content = parse_file(tmp_filename,separator);

        % B.2) extract header from first row:
        tmp_header = content{1};
        tmp_colname = {};
        tmp_instrument_type = strtrim(tmp_header{1});
        %fprintf('>>>%s<<<\n',tmp_instrument_type);
        for kk = 2 : 1 : length(tmp_header)
            tmp_item = tmp_header{kk};
            tmp_header_type{kk-1} = tmp_item(end-3:end); % extract last 4 characters
            tmp_colname{kk-1} = tmp_item(1:end-4); %substr(tmp_item, 1, length(tmp_item)-4);  % remove last 4 characters from colname
        end   
        % B.3) loop through all instruments   
        for jj = 2 : 1 : length(content)
          error_flag = 0;
          if (length(content{jj}) > 3)  % parse row only if it contains some meaningful data
            % B.3a) Generate object of appropriate class
            if ( sum(strcmpi(tmp_instrument_type,{'FRB','FRN','ILB','ZCB','FAB','CASHFLOW','BOND','SWAPFIXED','SWAPFLOAT','CMSFLOAT','CDS'})) > 0)        % store data in Class Bond
                i = Bond(); 
            elseif ( sum(strcmpi(tmp_instrument_type,{'FWD'})) > 0)        % store data in Class Forward
                i = Forward();  
            elseif ( sum(strcmpi(tmp_instrument_type,{'STOCH'})) > 0)        % store data in Class Stochastic
                i = Stochastic(); 
            elseif ( sum(strcmpi(tmp_instrument_type,{'CAPFLOOR'})) > 0)        % store data in Class CapFloor
                i = CapFloor(); 
            elseif ( sum(strcmpi(tmp_instrument_type,{'DBT'})) > 0)        % store data in Class Debt
                i = Debt();  
            elseif ( sum(strcmpi(tmp_instrument_type,{'COM','RET','COM','STK','ALT','SENSI'})) > 0)        % store data in Class Sensitivity Instrument
                i = Sensitivity();  
            elseif ( sum(strcmpi(tmp_instrument_type,{'SYNTH'})) > 0)        % store data in Class Synthetic Instrument
                i = Synthetic();  
            elseif ( regexpi(tmp_instrument_type,'OPT') == 1)        % store data in Class Option
                i = Option(); 
            elseif ( regexpi(tmp_instrument_type,'SWAPT') == 1)      % store data in Class Swaption
                i = Swaption(); 
            elseif ( sum(strcmpi(tmp_instrument_type,{'RETAIL','DCP','SAVPLAN','GOVPEN','RETEXP','HC'})) > 0)      % store data in Class Retail
                i = Retail(); 
            elseif ( sum(strcmpi(tmp_instrument_type,{'CASH'})) > 0)  % store data in Class Cash
                i = Cash();                     
            end

            % B.3b)  Loop through all instrument attributes
            tmp_cell = content{jj};
            for mm = 2 : 1 : length(tmp_cell)   % loop via all entries in header row and set object attributes
                tmp_columnname = lower(tmp_colname{mm-1});
                tmp_cell_item = tmp_cell{mm};
                tmp_cell_type = upper(tmp_header_type{mm-1});
                % B.3b.i) convert item to appropriate type
                if ( strcmpi(tmp_cell_type,'NMBR'))
                    try
                        if ( isempty(tmp_cell_item))
                            tmp_entry = 0.0;
                        else
                            tmp_entry = str2num(tmp_cell_item);
                        end
                    catch
                        fprintf('Item >>%s<< is not NUMERIC \n',tmp_cell_item);
                        tmp_entry = 0.0;
                        error_flag = 1;
                    end
                     
                elseif ( strcmpi(tmp_cell_type,'CHAR'))
                    try
                        tmp_entry = strtrim(tmp_cell_item);
                    catch
                        fprintf('Item >>%s<< is not a CHAR \n',tmp_cell_item);
                        tmp_entry = '';
                        error_flag = 1;
                    end
                elseif ( strcmpi(tmp_cell_type,'BOOL'))
                    try                    
                        if (isnumeric (tmp_cell_item))
                            tmp_entry = logical(tmp_cell_item);
                        elseif ( ischar(tmp_cell_item))
                            if ( strcmpi('false',tmp_cell_item) || strcmp('0',tmp_cell_item))
                                tmp_entry = 0;
                            elseif ( strcmpi('true',tmp_cell_item) || strcmp('1',tmp_cell_item) )
                                tmp_entry = 1;
                            end
                        end  
                    catch
                        fprintf('Item >>%s<< is not a BOOL: %s \n',tmp_cell_item,lasterr);
                        tmp_entry = 0;
                        error_flag = 1;
                    end    
                elseif ( strcmpi(tmp_cell_type,'DATE'))
                    try
                        % check for number
                        if (length(str2num(tmp_cell_item)) > 0)
                            tmp_entry = str2num(tmp_cell_item);
                            tmp_entry = datestr(valuation_date + tmp_entry);
                        else % otherwise assume its a date
                            % check for empty date
                            if ( isempty(tmp_cell_item) )
                                tmp_entry = datestr(valuation_date);
                            else
                                tmp_entry = datestr(tmp_cell_item);
                            end
                        end
                    catch
                        fprintf('Item >>%s<< is not a DATE \n',tmp_cell_item);
                        tmp_entry = '01-Jan-1900';
                        error_flag = 1;
                    end
                else
                    fprintf('Unknown type: >>%s<< for item value >>%s<< in line >>%d<< and column >>%d<<.\n Aborting: >>%s<< \n',tmp_cell_type,tmp_cell_item,jj,mm,lasterr);
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
                    if ( strcmp(tmp_columnname,'cf_dates'))
                        tmp_cf_dates= strsplit( tmp_entry, '|');
                        % convert cashflow dates to numbers and apply busday rule                        
                        if ( length(tmp_entry) > 1 )
                            if (length(str2num(tmp_cf_dates{1})) > 0) % if cf_dates are days from valuation date
                                tmp_entry = [];
                                for ll = 1 : 1 : length(tmp_cf_dates)    % loop through all cash flows and convert it to numbers
                                    tmp_entry = [tmp_entry, str2num(tmp_cf_dates{ll}) ];
                                end
                                i = i.set(tmp_columnname,tmp_entry);
                            else    % otherwise cf_dates are datestrings
                                tmp_cf_dates = busdate(datenum(tmp_cf_dates,1));
                                tmp_entry = (tmp_cf_dates)' - valuation_date;
                                i = i.set(tmp_columnname,tmp_entry);
                            end
                        else
                            tmp_entry = [];
                        end
                    elseif ( sum(strcmp(tmp_columnname,{'cf_values','sensitivities', ...
								'principal_payment','weights','sensi_prefactor', ...
								'sensi_exponent','sensi_cross', ...
								'extra_payment_values','redemption_values', ...
								'savings_change_values','payout_yield','div_month', ...
								'region_values','style_values', 'expense_values', ...
								'rating_values','duration_values','country_values'})) > 0)
                        if ~( isempty(tmp_entry)) % split into vector
                            %replace | with , and apply str2num
                            tmp_entry = str2num( strrep(tmp_entry,'|',','));
                        else
                            tmp_entry = [];
                        end
                        i = i.set(tmp_columnname,tmp_entry);        
                    elseif ( sum(strcmp(tmp_columnname,{'underlyings', ...
									'riskfactors','shock_type', ...
									'instruments', 'expense_dates', ...
									'extra_payment_dates','redemption_dates', ...
									'savings_change_dates','region_id', ...
									'rating_id', 'style_id', 'duration_id', ...
									'country_id'})) > 0)  % split into cell
                        try
                            tmp_entry = strsplit( tmp_entry, '|');
                        catch
                            tmp_entry = {};
                        end 
                        i = i.set(tmp_columnname,tmp_entry);
                    elseif ( strcmp(tmp_columnname,'type'))
                        %printf('Setting >>%s<< type to subtype: >>%s<< >>%s<<\n',tmp_columnname,tmp_cell_type,tmp_entry);
                        i = i.set('sub_type',tmp_entry);
                    else    % set new attribute, no special treatment
                        if ( ischar(tmp_entry))
                            if (length(tmp_entry)>0)
                                i = i.set(tmp_columnname,tmp_entry);
                            end
                        else
                            i = i.set(tmp_columnname,tmp_entry);
                        end
                    end % end special case for cf dates and values
                catch
                    fprintf('Object attribute %s could not be set for line >>%d<< and column >>%d<<.\n There was an error: %s\n',tmp_columnname,jj,mm,lasterr);
                    error_flag = 1;
                end
            end
            %disp('=== Final Object ===')
            %i     
            % B.3c) Error checking for instrument: 
            if ( error_flag > 0 )
                fprintf('ERROR: There has been an error for instrument: %s \n',i.id);
                id_failed_cell{ length(id_failed_cell) + 1 } =  i.id;
                error_flag = 0;
            else
                error_flag = 0;
                number_instruments = number_instruments + 1;
                instrument_struct( number_instruments ).id = i.id;
                instrument_struct( number_instruments ).name = i.id;
                instrument_struct( number_instruments ).object = i;
            end
          %  fprintf('Seems to be empty row. Skipping.\n');
          end   % end if loop with meaningful data
        end  % next instrument / next row in specification
        
    end         % meaningful file
end          % next file with specifications
% finished loading instruments into object

% C) return final instrument objects  
fprintf('SUCCESS: loaded >>%d<< instruments. \n',number_instruments);
if (length(id_failed_cell) > 0 )
    fprintf('WARNING: >>%d<< instruments failed: \n',length(id_failed_cell));
    id_failed_cell
end

% D) move all parsed files to an TAR in folder archive
if (archive_flag == 1)
    try
        tarfiles = tar( strcat(path_archive,'/archive_instruments_',tmp_timestamp,'.tar'),strcat(path,'/*'));
    end
end

end % end function

% ==============   Helper Function =============================================
function content = parse_file(tmp_filename,separator);
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
end % parse_file

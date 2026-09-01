%# Copyright (C) 2026 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {@var{retcode} =} update_riskfactor_std_history (@var{riskfactor_struct}, @var{path_static}, @var{valuation_date}, @var{rf_id_cell})
%# Append the current calibrated standard deviation of a small tracked set of
%# risk factors (default: the Gold/REIT/Equity/Crypto risk factors driven by
%# the external symmetric-adjustment recalibration) to a rolling history CSV
%# file, @code{<path_static>/riskfactor_std_history.csv} (columns
%# @code{date,risk_factor_id,std}). If a row for today's valuation date and a
%# given risk factor already exists (e.g. octarisk was run more than once on
%# the same day), it is updated in place rather than duplicated. The history
%# is capped to a rolling 24 month window.
%# @*
%# This is the append-only counterpart consumed by
%# @seealso{print_sym_adj_shock_movements} to measure the relative shock-size
%# movement since the last run.
%# @itemize @bullet
%# @item @var{riskfactor_struct}: struct with loaded Riskfactor objects
%# @item @var{path_static}: path to the static folder (history file location)
%# @item @var{valuation_date}: valuation date (datenum or date string)
%# @item @var{rf_id_cell}: OPTIONAL cell with risk factor ids to track.
%# Defaults to @{RF_EQ_HIGH, RF_EQ_LOW, RF_RE_HIGH, RF_COM_HIGH, RF_ALT_HIGH@}
%# @end itemize
%# @end deftypefn
function retcode = update_riskfactor_std_history(riskfactor_struct,path_static,valuation_date,rf_id_cell)

if nargin < 3
    print_usage ();
end
if nargin < 4
    rf_id_cell = {'RF_EQ_HIGH','RF_EQ_LOW','RF_RE_HIGH','RF_COM_HIGH','RF_ALT_HIGH'};
end

retcode = 0;
filename = strcat(path_static,'/riskfactor_std_history.csv');
today_str = datestr(valuation_date,'dd-mmm-yyyy');

% A) read existing history (if any)
dates = {};
ids = {};
stds = [];
if ( exist(filename,'file') )
    fid = fopen(filename,'r');
    fgetl(fid);   % skip header row
    while ( ~feof(fid) )
        line = fgetl(fid);
        if ( ischar(line) && ~isempty(line) )
            parts = strsplit(line,',');
            if ( numel(parts) == 3 )
                dates{ end + 1 } = parts{1};
                ids{ end + 1 }   = parts{2};
                stds( end + 1 )  = str2double(parts{3});
            end
        end
    end
    fclose(fid);
end

% B) update-in-place (if today's row already exists for this risk factor) or
%    append today's std per tracked risk factor
for ii = 1 : 1 : numel(rf_id_cell)
    rf_id = rf_id_cell{ii};
    [rf_obj retcode_obj] = get_sub_object(riskfactor_struct,rf_id);
    if ( retcode_obj == 0 )
        fprintf('WARNING: update_riskfactor_std_history: risk factor >>%s<< not found in riskfactor_struct, skipping.\n',rf_id);
        continue;
    end
    new_std = rf_obj.std;
    match_idx = find(strcmp(dates,today_str) & strcmp(ids,rf_id));
    if ( ~isempty(match_idx) )
        stds(match_idx(1)) = new_std;
    else
        dates{ end + 1 } = today_str;
        ids{ end + 1 }   = rf_id;
        stds( end + 1 )  = new_std;
    end
end

% C) cap to a rolling 24 month window
if ( numel(dates) > 0 )
    cutoff_datenum = addtodatefinancial(valuation_date,-24,'months');
    keep = (datenum(dates) >= cutoff_datenum);
    dates = dates(keep);
    ids   = ids(keep);
    stds  = stds(keep);
end

% D) write history back
fid = fopen(filename,'w');
if (fid == -1)
    fprintf('WARNING: update_riskfactor_std_history: could not open file >>%s<< for writing.\n',filename);
    return;
end
fprintf(fid,'date,risk_factor_id,std\n');
for ii = 1 : 1 : numel(dates)
    fprintf(fid,'%s,%s,%.6f\n',dates{ii},ids{ii},stds(ii));
end
fclose(fid);

retcode = 1;
end

%!test
%! path_static = tempname();
%! mkdir(path_static);
%! rf = Riskfactor();
%! rf = rf.set('id','RF_EQ_HIGH','type','RF_EQ','std',0.25);
%! riskfactor_struct = struct();
%! riskfactor_struct(1).id = 'RF_EQ_HIGH';
%! riskfactor_struct(1).object = rf;
%! retcode = update_riskfactor_std_history(riskfactor_struct,path_static,datenum('30-Aug-2026'),{'RF_EQ_HIGH'});
%! assert(retcode,1);
%! % run again same day -> should update in place, not duplicate
%! rf = rf.set('std',0.26);
%! riskfactor_struct(1).object = rf;
%! update_riskfactor_std_history(riskfactor_struct,path_static,datenum('30-Aug-2026'),{'RF_EQ_HIGH'});
%! filestr = fileread(strcat(path_static,'/riskfactor_std_history.csv'));
%! lines = strsplit(filestr,"\n");
%! lines(cellfun(@isempty,lines)) = [];
%! assert(numel(lines),2);   % header + 1 row (updated in place)
%! assert(~isempty(strfind(lines{2},'0.260000')));
%! % run on a later day -> should append a second row
%! rf = rf.set('std',0.27);
%! riskfactor_struct(1).object = rf;
%! update_riskfactor_std_history(riskfactor_struct,path_static,datenum('30-Sep-2026'),{'RF_EQ_HIGH'});
%! filestr = fileread(strcat(path_static,'/riskfactor_std_history.csv'));
%! lines = strsplit(filestr,"\n");
%! lines(cellfun(@isempty,lines)) = [];
%! assert(numel(lines),3);   % header + 2 rows
%! confirm_cleanup = rmdir(path_static,'s');

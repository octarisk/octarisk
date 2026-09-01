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
%# @deftypefn {Function File} {@var{retcode} =} print_sym_adj_shock_movements (@var{obj}, @var{repstruct}, @var{para_object}, @var{path_reports})
%# Print a LaTeX bridge table splitting the period-over-period move in each
%# tracked asset class's Standalone VaR (Gold/REIT/Equity/Crypto, i.e. the
%# risk factors calibrated by the external symmetric-adjustment process) into
%# an exposure effect and a shock (calibration) effect.
%# @*
%# Must be called after the existing asset-allocation block in
%# @seealso{print_report} has already populated @var{repstruct}.aa_cell,
%# @var{repstruct}.aa_exposure and @var{repstruct}.aa_sa. Maintains a small
%# per-portfolio rolling history file (@code{<path_static>/
%# aa_risk_history_<portfolio_id>.csv}, columns
%# @code{date,asset_class,exposure,standalone_var}), and reads the
%# risk-factor-level std history maintained by
%# @seealso{update_riskfactor_std_history}
%# (@code{<path_static>/riskfactor_std_history.csv}).
%# @*
%# Formulas (per tracked asset class, comparing the latest history row to the
%# closest one strictly before it):
%# @example
%# relative_shock_change    = std_latest / std_previous - 1   (std averaged across
%#                             the asset class's mapped risk factors, if more than
%#                             one, before taking the ratio -- not an average of
%#                             per-factor relative changes)
%# relative_exposure_change = exposure_latest / exposure_previous - 1
%# Exposure Effect = VaR_previous * relative_exposure_change
%# Shock Effect    = VaR_previous * relative_shock_change
%# Residual         = (VaR_latest - VaR_previous) - Exposure Effect - Shock Effect
%# @end example
%# so that @code{Prior VaR + Exposure Effect + Shock Effect + Residual = Current VaR}
%# reconciles exactly. Asset classes without a prior history row yet (e.g.
%# the very first run) are left out of the table body -- an all-new portfolio
%# therefore gets an (otherwise empty) table with just the header.
%# @end deftypefn
function retcode = print_sym_adj_shock_movements(obj,repstruct,para_object,path_reports)

retcode = 0;
if ( nargin < 4 )
    print_usage ();
end

try
    path_static = strcat(para_object.path_working_folder,'/',para_object.folder_static);
    today_str = datestr(para_object.valuation_date,'dd-mmm-yyyy');
    today_datenum = datenum(today_str);

    % asset class label (as used in aa_cell) -> mapped risk factor id(s).
    % hardcoded on purpose (see plan): simple to hand-edit if the mapping
    % between asset classes and their dominant symmetric-adjustment-driven
    % risk factor changes.
    % Equity uses RF_EQ_HIGH only, not RF_EQ_LOW, even though mc-mapping.csv
    % maps some Equity holdings (Europe, North America) to RF_EQ_LOW and
    % others (Asia-Pacific, Emerging Markets) to
    % RF_EQ_HIGH: both are calibrated from the same MSCI_ACWI symmetric-
    % adjustment run each time, so their relative std movement is taken to
    % track together and RF_EQ_HIGH alone is used as the representative
    % series. If that assumption ever stops holding (the two start moving by
    % different relative amounts), the Europe/North America sleeve's own
    % calibration moves will not be reflected here -- re-add RF_EQ_LOW below
    % (get_previous_std_avg already handles an asset class mapped to more
    % than one risk factor, by averaging std levels before taking the ratio).
    aa_labels = {'Equity','Real Estate','Commodity','Alternative'};
    aa_rf_ids = {{'RF_EQ_HIGH'},{'RF_RE_HIGH'},{'RF_COM_HIGH'},{'RF_ALT_HIGH'}};

    if ( ~isfield(repstruct,'aa_cell') || isempty(repstruct.aa_cell) )
        fprintf('print_sym_adj_shock_movements: no asset allocation data in repstruct for portfolio >>%s<<. Skipping.\n',obj.id);
        retcode = write_empty_table(obj,path_reports);
        return;
    end
    aa_cell     = repstruct.aa_cell;
    aa_exposure = repstruct.aa_exposure;
    aa_sa       = repstruct.aa_sa;

    % A) read the two history sources
    [std_dates std_ids std_vals] = read_history_csv(strcat(path_static,'/riskfactor_std_history.csv'),3);
    aa_hist_filename = strcat(path_static,'/aa_risk_history_',obj.id,'.csv');
    [aa_dates aa_classes aa_exp_vals aa_var_vals] = read_history_csv(aa_hist_filename,4);

    % B) build today's rows and per-asset-class bridge figures
    rows_label = {};
    rows_prior = [];
    rows_exposure_effect = [];
    rows_shock_effect = [];
    rows_residual = [];
    rows_current = [];

    for kk = 1 : 1 : numel(aa_labels)
        label = aa_labels{kk};
        idx = find(strcmpi(strtrim(aa_cell),label));
        if ( isempty(idx) )
            continue;   % asset class not present in this portfolio
        end
        idx = idx(1);
        var_current = aa_sa(idx);
        exp_current = aa_exposure(idx);

        % previous exposure/VaR entry for this asset class (strictly before today)
        [exp_previous var_previous] = get_previous_aa_value(aa_dates,aa_classes,aa_exp_vals,aa_var_vals,label,today_datenum);

        % previous/current std, averaged across the asset class's mapped risk factors
        rf_ids = aa_rf_ids{kk};
        [std_previous std_current] = get_previous_std_avg(std_dates,std_ids,std_vals,rf_ids,today_datenum);

        % C) update this asset class's rolling exposure/VaR history with today's values
        [aa_dates aa_classes aa_exp_vals aa_var_vals] = upsert_history_row(aa_dates,aa_classes,aa_exp_vals,aa_var_vals,today_str,label,exp_current,var_current);

        if ( isempty(var_previous) || isempty(std_previous) || isempty(std_current) || exp_previous == 0 )
            continue;   % not enough history yet for this asset class -- leave it out of the table
        end

        relative_exposure_change = exp_current / exp_previous - 1;
        relative_shock_change    = std_current / std_previous - 1;
        exposure_effect = var_previous * relative_exposure_change;
        shock_effect    = var_previous * relative_shock_change;
        residual        = (var_current - var_previous) - exposure_effect - shock_effect;

        rows_label{ end + 1 }            = label;
        rows_prior( end + 1 )            = var_previous;
        rows_exposure_effect( end + 1 )  = exposure_effect;
        rows_shock_effect( end + 1 )     = shock_effect;
        rows_residual( end + 1 )         = residual;
        rows_current( end + 1 )          = var_current;
    end

    % D) persist the updated per-portfolio asset-class history, capped to 24 months
    cutoff_datenum = addtodatefinancial(para_object.valuation_date,-24,'months');
    keep = (datenum(aa_dates) >= cutoff_datenum);
    write_aa_history_csv(aa_hist_filename,aa_dates(keep),aa_classes(keep),aa_exp_vals(keep),aa_var_vals(keep));

    % E) write LaTeX bridge table
    filename = strcat(path_reports,'/table_port_',obj.id,'_sym_adj_attribution.tex');
    fid = fopen(filename,'w');
    fprintf(fid,'\\center\n');
    fprintf(fid,'\\label{table_port_sym_adj_attribution}\n');
    fprintf(fid,'\\begin{tabular}{l|r|r|r|r|r}\n');
    fprintf(fid,'Asset Class \& Prior VaR \& Exposure Effect \& Shock Effect \& Residual \& Current VaR\\\\\\hline\\hline\n');
    for kk = 1 : 1 : numel(rows_label)
        fprintf(fid,'%s \& %9.0f %s \& %9.0f %s \& %9.0f %s \& %9.0f %s \& %9.0f %s\\\\\n', ...
            strrep(rows_label{kk},'_',''),rows_prior(kk),obj.currency,rows_exposure_effect(kk),obj.currency, ...
            rows_shock_effect(kk),obj.currency,rows_residual(kk),obj.currency,rows_current(kk),obj.currency);
    end
    fprintf(fid,'\\end{tabular}\n');
    fclose(fid);

    retcode = 1;
catch
    fprintf('WARNING: print_sym_adj_shock_movements: there was an error >>%s<< for portfolio >>%s<<. Skipping.\n',lasterr,obj.id);
    retcode = 0;
end

end

% ------------------------------------------------------------------------------
% write an (otherwise empty) table shell -- header only, no data rows
function retcode = write_empty_table(obj,path_reports)
    filename = strcat(path_reports,'/table_port_',obj.id,'_sym_adj_attribution.tex');
    fid = fopen(filename,'w');
    fprintf(fid,'\\center\n');
    fprintf(fid,'\\label{table_port_sym_adj_attribution}\n');
    fprintf(fid,'\\begin{tabular}{l|r|r|r|r|r}\n');
    fprintf(fid,'Asset Class \& Prior VaR \& Exposure Effect \& Shock Effect \& Residual \& Current VaR\\\\\\hline\\hline\n');
    fprintf(fid,'\\end{tabular}\n');
    fclose(fid);
    retcode = 1;
end

% ------------------------------------------------------------------------------
% generic reader for the simple append-only history CSVs used here (3 or 4
% columns, first column always a 'dd-mmm-yyyy' date string)
function varargout = read_history_csv(filename,ncols)
    cols = cell(1,ncols);
    for cc = 1 : 1 : ncols
        cols{cc} = {};
    end
    if ( exist(filename,'file') )
        fid = fopen(filename,'r');
        fgetl(fid);   % skip header
        while ( ~feof(fid) )
            line = fgetl(fid);
            if ( ischar(line) && ~isempty(line) )
                parts = strsplit(line,',');
                if ( numel(parts) == ncols )
                    for cc = 1 : 1 : ncols
                        if ( cc >= 3 )   % numeric columns (from column 3 onward)
                            cols{cc}{ end + 1 } = str2double(parts{cc});
                        else
                            cols{cc}{ end + 1 } = parts{cc};
                        end
                    end
                end
            end
        end
        fclose(fid);
    end
    % convert numeric columns to plain numeric arrays
    for cc = 1 : 1 : ncols
        if ( cc >= 3 )
            cols{cc} = cell2mat(cols{cc});
        end
    end
    varargout = cols;
end

% ------------------------------------------------------------------------------
% latest std strictly before today_datenum, averaged across rf_ids, and the
% latest std overall (today's, already appended by update_riskfactor_std_history)
function [std_previous std_current] = get_previous_std_avg(std_dates,std_ids,std_vals,rf_ids,today_datenum)
    std_previous = [];
    std_current = [];
    prev_vals = [];
    cur_vals = [];
    for ii = 1 : 1 : numel(rf_ids)
        rf_id = rf_ids{ii};
        match = strcmp(std_ids,rf_id);
        if ( ~any(match) )
            continue;
        end
        match_dates = datenum(std_dates(match));
        match_vals  = std_vals(match);
        % current: latest row for this risk factor (<= today)
        cur_idx = find(match_dates <= today_datenum);
        if ( ~isempty(cur_idx) )
            [~,mi] = max(match_dates(cur_idx));
            cur_vals(end+1) = match_vals(cur_idx(mi));
        end
        % previous: latest row strictly before today
        prev_idx = find(match_dates < today_datenum);
        if ( ~isempty(prev_idx) )
            [~,mi] = max(match_dates(prev_idx));
            prev_vals(end+1) = match_vals(prev_idx(mi));
        end
    end
    if ( ~isempty(prev_vals) )
        std_previous = mean(prev_vals);
    end
    if ( ~isempty(cur_vals) )
        std_current = mean(cur_vals);
    end
end

% ------------------------------------------------------------------------------
% latest exposure/var strictly before today_datenum for a given asset class label
function [exp_previous var_previous] = get_previous_aa_value(aa_dates,aa_classes,aa_exp_vals,aa_var_vals,label,today_datenum)
    exp_previous = [];
    var_previous = [];
    match = strcmpi(aa_classes,label);
    if ( ~any(match) )
        return;
    end
    match_dates = datenum(aa_dates(match));
    match_exp   = aa_exp_vals(match);
    match_var   = aa_var_vals(match);
    prev_idx = find(match_dates < today_datenum);
    if ( isempty(prev_idx) )
        return;
    end
    [~,mi] = max(match_dates(prev_idx));
    exp_previous = match_exp(prev_idx(mi));
    var_previous = match_var(prev_idx(mi));
end

% ------------------------------------------------------------------------------
% insert or update-in-place today's (exposure,standalone_var) row for a given
% asset class label -- mirrors update_riskfactor_std_history's dedup logic
function [dates classes exp_vals var_vals] = upsert_history_row(dates,classes,exp_vals,var_vals,today_str,label,exp_val,var_val)
    match_idx = find(strcmp(dates,today_str) & strcmpi(classes,label));
    if ( ~isempty(match_idx) )
        exp_vals(match_idx(1)) = exp_val;
        var_vals(match_idx(1)) = var_val;
    else
        dates{ end + 1 }    = today_str;
        classes{ end + 1 }  = label;
        exp_vals( end + 1 ) = exp_val;
        var_vals( end + 1 ) = var_val;
    end
end

% ------------------------------------------------------------------------------
function retcode = write_aa_history_csv(filename,dates,classes,exp_vals,var_vals)
    fid = fopen(filename,'w');
    if (fid == -1)
        fprintf('WARNING: print_sym_adj_shock_movements: could not open file >>%s<< for writing.\n',filename);
        retcode = 0;
        return;
    end
    fprintf(fid,'date,asset_class,exposure,standalone_var\n');
    for ii = 1 : 1 : numel(dates)
        fprintf(fid,'%s,%s,%.6f,%.6f\n',dates{ii},classes{ii},exp_vals(ii),var_vals(ii));
    end
    fclose(fid);
    retcode = 1;
end

%!test
%! path_working_folder = tempname();
%! path_static = strcat(path_working_folder,'/static');
%! mkdir(path_static);
%! % seed a std history with a "previous" (yesterday-equivalent) row and today's row
%! fid = fopen(strcat(path_static,'/riskfactor_std_history.csv'),'w');
%! fprintf(fid,'date,risk_factor_id,std\n');
%! fprintf(fid,'31-Jul-2026,RF_EQ_HIGH,0.200000\n');
%! fprintf(fid,'31-Jul-2026,RF_EQ_LOW,0.180000\n');
%! fprintf(fid,'30-Aug-2026,RF_EQ_HIGH,0.220000\n');
%! fprintf(fid,'30-Aug-2026,RF_EQ_LOW,0.180000\n');
%! fclose(fid);
%! % seed an aa history with a "previous" row for Equity
%! fid = fopen(strcat(path_static,'/aa_risk_history_TESTPORT.csv'),'w');
%! fprintf(fid,'date,asset_class,exposure,standalone_var\n');
%! fprintf(fid,'31-Jul-2026,Equity,0.300000,10000.000000\n');
%! fclose(fid);
%!
%! obj.id = 'TESTPORT';
%! obj.currency = 'EUR';
%! repstruct.aa_cell = {'Equity','Real Estate'};
%! repstruct.aa_exposure = [0.330000, 0.100000];
%! repstruct.aa_sa = [11000.0, 2000.0];
%! para_object.path_working_folder = path_working_folder;
%! para_object.folder_static = 'static';
%! para_object.valuation_date = datenum('30-Aug-2026');
%! path_reports = path_static;
%!
%! retcode = print_sym_adj_shock_movements(obj,repstruct,para_object,path_reports);
%! assert(retcode,1);
%! texstr = fileread(strcat(path_reports,'/table_port_TESTPORT_sym_adj_attribution.tex'));
%! assert(~isempty(strfind(texstr,'Equity')));
%! assert(isempty(strfind(texstr,'RealEstate')));   % no history yet -> left out
%! % Equity is mapped to RF_EQ_HIGH only (RF_EQ_LOW rows above are seeded but
%! % unused, kept to demonstrate that): relative_exposure_change = 0.33/0.30-1 = 0.10 ;
%! % relative_shock_change = 0.22/0.20-1 = 0.10
%! % Exposure Effect = 10000*0.10 = 1000 ; Shock Effect = 10000*0.10 = 1000 ; Residual = (11000-10000)-1000-1000 = -1000
%! assert(~isempty(strfind(texstr,'1000 EUR')));
%! confirm_cleanup = rmdir(path_working_folder,'s');

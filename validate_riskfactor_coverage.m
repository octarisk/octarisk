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
%# @deftypefn {Function File} {@var{orphaned_cell} =} validate_riskfactor_coverage (@var{all_rf_ids}, @var{covered_rf_ids}, @var{whitelist_cell})
%# Validate that every risk factor id loaded from riskfactors.csv is actually
%# driven by the Monte Carlo simulation, i.e. is either a risk factor contained
%# in the correlation matrix, or a target risk factor produced by mc-mapping.csv,
%# or explicitly whitelisted.
%# @*
%# A risk factor id which is defined in riskfactors.csv but present in neither
%# the correlation matrix nor mc-mapping.csv is silently never shocked: its
%# statistical parameters (mean, std, skew, kurt) are simply never read, but
%# this passes every positive-semi-definiteness check of the correlation
%# matrix, because the missing risk factor never shows up as a row/column
%# there in the first place (it is not the same failure mode as a zero
%# row/column, it is a row/column that never exists). This is easy to miss
%# during calibration review, so it must be checked explicitly and loudly.
%# @*
%# Aborts with an error listing the orphaned ids if any are found and no
%# whitelist covers them; returns the (possibly empty) cell of ids that were
%# orphaned but covered by the whitelist, for informational logging.
%# @itemize @bullet
%# @item @var{all_rf_ids}: cell with all risk factor ids loaded from riskfactors.csv
%# @item @var{covered_rf_ids}: cell with all risk factor ids actually used in the
%# Monte Carlo simulation (correlation matrix ids plus mc-mapping.csv target ids)
%# @item @var{whitelist_cell}: OPTIONAL cell with risk factor ids explicitly
%# allowed to remain uncovered (e.g. risk factors only used for stress testing)
%# @end itemize
%# @seealso{load_correlation_matrix, load_riskfactor_mapping}
%# @end deftypefn
function orphaned_whitelisted_cell = validate_riskfactor_coverage(all_rf_ids,covered_rf_ids,whitelist_cell)

if nargin < 2
    print_usage ();
end
if nargin < 3
    whitelist_cell = {};
end

orphaned_cell = {};
orphaned_whitelisted_cell = {};
for ii = 1 : 1 : numel(all_rf_ids)
    rf_id = all_rf_ids{ii};
    if ( sum(strcmpi(rf_id,covered_rf_ids)) == 0 )
        if ( sum(strcmpi(rf_id,whitelist_cell)) > 0 )
            orphaned_whitelisted_cell{ length(orphaned_whitelisted_cell) + 1 } = rf_id;
        else
            orphaned_cell{ length(orphaned_cell) + 1 } = rf_id;
        end
    end
end

if ( ~isempty(orphaned_whitelisted_cell) )
    fprintf('WARNING: validate_riskfactor_coverage: >>%d<< risk factor(s) defined in riskfactors.csv are not driven by the correlation matrix or mc-mapping.csv, but are explicitly whitelisted: %s\n', ...
        numel(orphaned_whitelisted_cell),strjoin(orphaned_whitelisted_cell,', '));
end

if ( ~isempty(orphaned_cell) )
    error(['validate_riskfactor_coverage: >>%d<< risk factor(s) defined in riskfactors.csv are neither ', ...
        'contained in the correlation matrix nor mapped via mc-mapping.csv nor whitelisted, ', ...
        'so their statistical parameters (std, skew, kurt) are never read and they are never shocked: >>%s<<. ', ...
        'Either add them to the correlation matrix / mc-mapping.csv, or add them to ', ...
        'para_object.riskfactor_coverage_whitelist if this is intentional.'], ...
        numel(orphaned_cell),strjoin(orphaned_cell,', '));
end

end

%!test
%! all_ids = {'RF_A','RF_B','RF_C'};
%! covered = {'RF_A','RF_B'};
%! try
%!   validate_riskfactor_coverage(all_ids,covered);
%!   error('Expected error was not thrown');
%! catch err
%!   assert(~isempty(strfind(err.message,'RF_C')));
%! end

%!test
%! all_ids = {'RF_A','RF_B','RF_C'};
%! covered = {'RF_A','RF_B'};
%! whitelisted = validate_riskfactor_coverage(all_ids,covered,{'RF_C'});
%! assert(whitelisted,{'RF_C'});

%!test
%! all_ids = {'RF_A','RF_B'};
%! covered = {'RF_A','RF_B','RF_C'};
%! whitelisted = validate_riskfactor_coverage(all_ids,covered);
%! assert(isempty(whitelisted));

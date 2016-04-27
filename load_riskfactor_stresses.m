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
%# @deftypefn {Function File} {[@var{riskfactor_struct} @var{rf_failed_cell}] =} load_riskfactor_stresses(@var{riskfactor_struct}, @var{stresstest_struct})
%# Generate stresses for risk factor curve objects. Store all stresses in provided struct and return the final struct and a cell containing all failed risk factor ids.
%# @end deftypefn

function [riskfactor_struct rf_failed_cell ] = load_riskfactor_stresses(riskfactor_struct,stresstest_struct)

rf_failed_cell = {};
number_riskfactors = 0;
% loop via all riskfactors, take IDs from struct und apply delta
for ii = 1 : 1 : length( stresstest_struct )
    tmp_shiftvalue  = [stresstest_struct( ii ).shiftvalue]; % get vector of shift value of particular scenario
    tmp_shifttypes  = [stresstest_struct( ii ).shifttype];  % get vector of shift type of particular scenario
    tmp_risktype    = stresstest_struct( ii ).risktype;    % get risk type cell
    
    for kk = 1 : 1 : length( riskfactor_struct )        % check whether risk factor is contained in risk type cell 
        try
            % get parameters of risk factor object          % and apply specific shock
            rf_object   = riskfactor_struct( kk ).object;
            tmp_rf_type = rf_object.type;
            tmp_rf_id   = rf_object.id;
            c = regexp(tmp_rf_id, tmp_risktype);    % regexp of stress test risk type on risk factor id -> return 1 if regexp matches
            k = cellfun(@isempty,c) == 0;           % convert NaN to 0 values
            tmp_shift = tmp_shiftvalue * k';        % get risk factor shift value (multiply regexp match vector with shift value vector -> return shift value
            tmp_shift_type = tmp_shifttypes * k';   % apply same on shift type -> return scalar of shift type

            if ( sum(k) == 1 )
                tmp_stress = [tmp_shift];
            else
                tmp_stress = [0.0];
            end
            rf_object = rf_object.set('scenario_stress',tmp_stress);    % add stress shift value into stress test vector of risk factor -> order preserved
            rf_object = rf_object.set('shift_type',tmp_shift_type);
            % store risk factor object back into struct:
            riskfactor_struct( kk ).object = rf_object; 
            number_riskfactors = number_riskfactors + 1;
        catch
            fprintf('WARNING: There has been an error for curve: >>%s<< in stresstest: >>%s<<. Aborting: >>%s<<\n',tmp_rf_id,stresstest_struct( ii ).id,lasterr);
            rf_failed_cell{ length(rf_failed_cell) + 1 } =  tmp_rf_id;
        end %end try catch
    end     % end for loop through all risk factors
end     % end for loop through all stresstests
 
rf_failed_cell = unique(rf_failed_cell); 
% returning statistics
fprintf('SUCCESS: specified >>%d<< risk factor stresses in %d stresstests.\n',number_riskfactors,ii);
if (length(rf_failed_cell) > 0 )
    fprintf('WARNING: >>%d<< risk factor stress generations failed: \n',length(rf_failed_cell));
    rf_failed_cell
end 

end
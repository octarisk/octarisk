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
%# Generate stresses for risk factor objects (except curves). Store all stresses in provided struct and return the final struct and a cell containing all failed risk factor ids.
%# @end deftypefn

function [riskfactor_struct rf_failed_cell ] = load_riskfactor_stresses(riskfactor_struct,stresstest_struct)

rf_failed_cell = {};
number_riskfactors = 0;
% loop via all riskfactors, take IDs from struct und apply delta
for kk = 1 : 1 : length( riskfactor_struct )        % check whether risk factor is contained in risk type cell 
    tmp_object = riskfactor_struct( kk ).object;
    tmp_rf_id = tmp_object.id;
    % update only Equity, Commodity, FX risk factors etc.
    if ~( strcmpi(tmp_object.type,{'RF_IR','RF_VOLA','RF_SPREAD'}))
        try
            stress_values = zeros(length(stresstest_struct),1) ;
            number_riskfactors = number_riskfactors + 1;
                % iterate via all stress definitions
            for ii = 1:1:length(stresstest_struct)
                    % get struct with all market object shocks
                    subst = stresstest_struct(ii).objects;
                    % get appropriate market object
                    [shockstruct retcode] = get_sub_struct(subst,tmp_object.id);
                    if ( retcode == 1)      % object_id is contained in stress
                            stress_values(ii) = return_stress_shocks(tmp_object,shockstruct);
                    else
                            % apply stress shock base value
                            stress_values(ii) = 0.0; % tmp_object.getValue('base');
                    end
            end
            % set instrument stress vector
            tmp_object = tmp_object.set('scenario_stress',stress_values);
            riskfactor_struct( kk ).object = tmp_object;
        catch
            fprintf('WARNING: load_riskfactor_stresses: There has been an error for riskfactor: >>%s<<. Message: >>%s<<\n',tmp_rf_id,lasterr);
            rf_failed_cell{ length(rf_failed_cell) + 1 } =  tmp_rf_id;
        end %end try catch
    end
end     % end for loop through all risk factors
 
rf_failed_cell = unique(rf_failed_cell); 
% returning statistics
fprintf('SUCCESS: specified >>%d<< risk factor stresses in %d stresstests.\n',number_riskfactors,length(stresstest_struct));
if (length(rf_failed_cell) > 0 )
    fprintf('WARNING: >>%d<< risk factor stress generations failed: \n',length(rf_failed_cell));
    rf_failed_cell
end 

end


% Helper Function for applying market data stresses
function retval = return_stress_shocks(obj,mktstruct)
        retval = 0.0;
        type            = mktstruct.type;
        shock_type      = mktstruct.shock_type;
        shock_value     = mktstruct.shock_value;
        % type index
        if (strcmpi(type,'riskfactor'))
                base_value = obj.getValue('base');
                if (strcmpi(shock_type,'relative'))
                        retval = base_value .* shock_value;
                elseif (strcmpi(shock_type,'absolute'))
                        retval = base_value + shock_value;
                elseif (strcmpi(shock_type,'value'))
                        retval = shock_value;
                else
                        error('return_stress_shocks: unknown stress shock type: >>%s<<\n',any2str(shock_type));
                end
        % other types
        else
                error('return_stress_shocks: unknown stress type: >>%s<<\n',any2str(type));
        end
end

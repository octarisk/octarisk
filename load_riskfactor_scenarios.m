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
%# @deftypefn {Function File} {[@var{riskfactor_struct} @var{rf_failed_cell}] =} load_riskfactor_scenarios(@var{riskfactor_struct}, @var{M_struct}, @var{mc_timestep}, @var{mc_timestep_days},@var{para_object})
%# Generate MC scenario shock values for risk factor curve objects. Store all MC scenario shock values in provided struct and return the final struct and a cell containing all failed risk factor ids.
%# @end deftypefn

function [tmp_riskfactor_struct rf_failed_cell ] = load_riskfactor_scenarios(riskfactor_struct,M_struct,riskfactor_cell,mc_timestep,mc_timestep_days,para_object)

% reorder tmp_riskfactor_struct
tmp_riskfactor_struct = struct();
for ii = 1 : 1 : length( riskfactor_cell ) 
    rf_id = riskfactor_cell{ii};              
    rf_object = get_sub_object(riskfactor_struct, rf_id);
    tmp_riskfactor_struct(ii).object = rf_object;
    tmp_riskfactor_struct(ii).id = rf_id;
end

rf_failed_cell = {};
number_riskfactors = 0;
tmp_id = 'Dummy';
shred_type = para_object.shred_type;
% calculate risk factor MC scenario value

try
	tmp_ts  = mc_timestep;    % get timestep string
	ts      = mc_timestep_days;  % get timestep days
	Y_tmp   = M_struct( 1 ).matrix; % get matrix with correlated random numbers for all risk factors
	for ii = 1 : 1 : length( riskfactor_cell )    % loop via all risk factors in order of their appearance in corr_matrix: 
		rf_id = riskfactor_cell{ii};              % calculate risk factor deltas in each MC scenario
        tmp_rf_type = strsplit(rf_id,'_'){2};
		rf_object = tmp_riskfactor_struct(ii).object;
		tmp_model = rf_object.model;
		tmp_drift = rf_object.mean / 250;
		tmp_sigma = rf_object.std;
		tmp_id = rf_object.id;
		% correlated random variables vector from corr. random matrix M:
		Y       = Y_tmp(:,ii);
		% Case Dependency:
        % only update risk factor if risk factor type is part of shred
        if (strcmpi(shred_type,'TOTAL') || (sum(strcmpi(tmp_rf_type,shred_type))>0 ))
			% Geometric Brownian Motion Riskfactor Modeling
				if ( strcmpi(tmp_model,'GBM') || strcmpi(tmp_model,'SLN')  )
					tmp_delta       = Y + ((tmp_drift - 0.5 .* (tmp_sigma./ sqrt(250)).^2) .* ts);
			% Brownian Motion Riskfactor Modeling
				elseif ( strcmpi(tmp_model,'BM') )
					tmp_delta       = Y + (tmp_drift * ts);
			% Black-Karasinski (log-normal mean reversion) Riskfactor Modeling
				elseif ( strcmpi(tmp_model,'BKM') )
					% startlevel, sigma_p_a, mr_level, mr_rate
					tmp_start       = rf_object.value_base;
					tmp_mr_level    = rf_object.mr_level;
					tmp_mr_rate     = rf_object.mr_rate;    
					tmp_delta       = Y + (tmp_mr_rate * ( tmp_mr_level - tmp_start ) * ts);
			% Ornstein-Uhlenbeck process 
				elseif ( strcmpi(tmp_model,'OU') )    
					% startlevel, sigma_p_a, mr_level, mr_rate
					tmp_start       = rf_object.value_base;
					tmp_mr_level    = rf_object.mr_level;
					tmp_mr_rate     = rf_object.mr_rate;     
					tmp_delta       = Y + (tmp_mr_rate * ( tmp_mr_level - tmp_start ) * ts);
			% Square-root diffusion process
				elseif ( strcmpi(tmp_model,'SRD') )    
					% startlevel, sigma_p_a, mr_level, mr_rate
					tmp_start       = rf_object.value_base;
					tmp_mr_level    = rf_object.mr_level;
					tmp_mr_rate     = rf_object.mr_rate;     
					tmp_delta       = sqrt(tmp_start) .* Y + (tmp_mr_rate * ( tmp_mr_level - tmp_start ) * ts);
					if (2 * tmp_mr_rate * tmp_mr_level < std(Y).^2)
						fprintf('WARNING: load_riskfactor_scenarios: Square root diffusion process can lead to negative values for risk factor >>%s<<: 2*mr_rate*mr_level <= volatility^2.\n',tmp_id);
					end
				end
        else % risk factor NOT to be shocked - not part of shred! Default case:
            fprintf('OCTARISK::load_riskfactor_scenarios: Riskfactor >>%s<< not part of shred, providing base values\n',tmp_id);
            % do not store shocked scenarios
            tmp_delta = rf_object.value_base .* ones(numel(Y),1);
        end
		
        % store increment for actual riskfactor and scenario number
        rf_object = rf_object.set('scenario_mc',tmp_delta,'timestep_mc',tmp_ts);
		% store risk factor object back into struct:
		tmp_riskfactor_struct( ii ).object = rf_object;   
		number_riskfactors = number_riskfactors + 1;
	end  % close loop via all risk factors  
catch
	fprintf('WARNING: OCTARISK::load_riskfactor_scenarios: There has been an error for risk factor: >>%s<< in MC timestep: >>%s<<. Aborting: >>%s<<\n',tmp_id,tmp_ts,lasterr);
	rf_failed_cell{ length(rf_failed_cell) + 1 } =  tmp_id;
end


% clear temporary riskfactor_struct      
rf_failed_cell = unique(rf_failed_cell); 
% returning statistics
fprintf('SUCCESS: generated MC scenario values for >>%d<< risk factors in  MC timesets %s.\n',number_riskfactors,any2str(mc_timestep));

if (length(rf_failed_cell) > 0 )
    fprintf('WARNING: OCTARISK::load_riskfactor_scenarios:  >>%d<< risk factors failed during MC scenario generation: \n',length(rf_failed_cell));
    rf_failed_cell
end 

% now append all riskfactors which are not in riskfactor_cell
for ii = 1 : 1 : length( riskfactor_struct ) 
    rf_id = riskfactor_struct(ii).id;
    if (sum(strcmp(rf_id,riskfactor_cell)) == 0)   % rf_id not contained in MC riskfactor_cell -> append
        rf_object = get_sub_object(riskfactor_struct, rf_id);
        store_index = length(tmp_riskfactor_struct) + 1;
        tmp_riskfactor_struct(store_index).object = rf_object;
        tmp_riskfactor_struct(store_index).id = rf_id;
    end
end

end



%~ % C) Apply marginal distributions to uniform distributed multivariate random numbers
%~ R = zeros(mc,columns(corr_matrix));
%~ distr_type = zeros(1,columns(Z));
%~ shred_type = para_object.shred_type;
%~ % now loop via all columns of Z and apply individual marginal distribution
%~ for ii = 1 : 1 : columns(Z);
    %~ % only update marginal distribution if risk factor type is part of shred
    %~ tmp_rf_id = riskfactor_cell{ii}
    %~ tmp_rf_type = strsplit(tmp_rf_id,'_'){2};
    %~ if (strcmpi(shred_type,'TOTAL') || (sum(strcmpi(tmp_rf_type,shred_type))>0 ))
        %~ % mu needs geometric compounding adjustment
        %~ tmp_mu      = P(1,ii) .^(1/factor_time_horizon);
        %~ % volatility needs adjustment with sqr(t)-rule 
        %~ tmp_sigma   = P(2,ii) ./ sqrt(factor_time_horizon);
        %~ tmp_skew    = P(3,ii);
        %~ tmp_kurt    = P(4,ii);
        %~ tmp_ucr = Z(:,ii);
        %~ %generate distribution based on Pearson System (Type 1-7)
        %~ [ret_vec type]= get_marginal_distr_pearson(tmp_mu,tmp_sigma, ...
                                                    %~ tmp_skew,tmp_kurt,tmp_ucr); 
        %~ distr_type(ii) = type;
    %~ else
        %~ % risk factor NOT to be shocked - not part of shred! Default case:
        %~ ret_vec = zeros(mc,1);
    %~ end
    
    %~ R(:,ii) = ret_vec;
%~ end

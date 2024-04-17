%# Copyright (C) 2024 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{retcode} @var{rlzd_corr} @var{diff_corr}]=} calc_rlzd_corr (@var{riskfactor_cell}, @var{riskfactor_struct}, @var{corr_target}, @var{para_object}, @var{mc_timestep}, @var{path_reports}, @var{plot_flag})
%# Calculate correlation matrix and call plotting function for realized risk factor correlations. Optional (false): plot_flag.
%#
%# @seealso{plot_corr_matrix}
%# @end deftypefn

function [retcode rlzd_corr diff_corr] = calc_rlzd_corr(riskfactor_cell,riskfactor_struct,corr_target,para_object,mc_timestep,path_reports,plot_flag)

retcode = 0;
if nargin < 6 || nargin > 7
	error('plot_rlzd_corr: number of arguments not 6 or 7\n');
end
if nargin == 5
	plot_flag = false;
end

if numel(riskfactor_cell) < 1
	error('plot_rlzd_corr: no risk factors contained in riskfactor_cell\n');
end

rlzd_mc_values = zeros(para_object.mc,numel(riskfactor_cell));

for ii = 1 : 1 : length(riskfactor_cell)
		rf_id = riskfactor_cell{ii};
		[rf_object rf_ret] = get_sub_object(riskfactor_struct, rf_id);
		if rf_ret == 0
			error('plot_rlzd_corr: Risk factor object not found for riskfactor >>%s<<\n',any2str(rf_id));
		end
		tmp_mc = rf_object.getValue(mc_timestep);
		if tmp_mc == 0
			error('plot_rlzd_corr: Risk factor object does not contain scenario values for >>%s<<\n',any2str(mc_timestep));
		end
		if numel(tmp_mc) != para_object.mc
			error('plot_rlzd_corr: Risk factor object scenario values >>%s<< for timestep >>%s<< not matching expected scenario length >>%s<< \n',any2str(numel(tmp_mc)),any2str(mc_timestep),any2str(para_object.mc));
		end
		rlzd_mc_values(:,ii) = tmp_mc;
end

no_rf = numel(riskfactor_cell);
rlzd_corr = zeros(no_rf,no_rf);

% calculate correlations
for ii = 1 : 1 : no_rf
	for jj = ii : 1 : no_rf
		rlzd_corr(ii,jj) = corr(rlzd_mc_values(:,ii),rlzd_mc_values(:,jj));
		rlzd_corr(jj,ii) = rlzd_corr(ii,jj);
	end
end
clear rlzd_mc_values;
rlzd_corr = rlzd_corr .* 100;

[rx ry] = size(rlzd_corr);
[tx ty] = size(corr_target);
if rx != tx || ry != ty
	error('plot_rlzd_corr: Size of realized correlation matrix >>%s<< >>%s<< and target matrix >>%s<< >>%s<<are not matching. \n',any2str(rx),any2str(ry),any2str(tx),any2str(tx));
end
corr_target = corr_target .* 100;
diff_corr = rlzd_corr - corr_target;


% plotting
if plot_flag
	% plot realized matrix
	filename = 'rlzd_corr';
	title_string = 'Realized Correlations';
	x_axis_label = 'Risk factors';
	y_axis_label  = 'Risk factors';
	xlabels = strrep(riskfactor_cell,'_','.');
	ylabels = xlabels;
	retcode = plot_corr_matrix(rlzd_corr,para_object.runcode,path_reports,filename,title_string,x_axis_label,y_axis_label,xlabels,ylabels);
	
	% plot difference
	filename = 'rlzd_corr_diff';
	title_string = 'Difference between target and actual correlations';
	x_axis_label = 'Risk factors';
	y_axis_label  = 'Risk factors';
	xlabels = strrep(riskfactor_cell,'_','.');
	ylabels = xlabels;
	retcode = plot_corr_matrix(diff_corr,para_object.runcode,path_reports,filename,title_string,x_axis_label,y_axis_label,xlabels,ylabels);
	
	
end

end

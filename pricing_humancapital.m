%# Copyright (C) 2020 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{value}] =} pricing_humancapital (@var{obj},@var{value_type},@var{discount},@var{iec},@var{longev})
%#
%# Compute the Human Capital based on discounted future salary payment stream.
%# 
%# This script is a wrapper for the function pricing_humancapital_cpp
%# and handles all input and ouput data.
%# @end deftypefn

function hc_value = pricing_humancapital(obj,valuation_date,value_type,discount_curve,iec,longev,equity)
 
 if nargin < 7 || nargin > 7
     print_usage ();
 end

% retrieve number of days in MC timestep required for annualize risk factor shocks
if strcmpi(value_type,'base') || strcmpi(value_type,'stress')
	scale_rf = 250;
else
	if ( strcmpi(value_type(end),'d') )
		scale_rf = str2num(value_type(1:end-1));  % get timestep days
	elseif ( strcmpi(value_type(end),'y') )
		scale_rf = 365 * str2num(mc_timestep(1:end-1));  % get timestep days
	else
		error('Unknown number of days in timestep: %s\n',value_type);
	end
end
% ------------------------------------------------------------------------------
% get input values
rf_term		= discount_curve.getValue(value_type); % Riskfree yield 
rf_nodes 	= discount_curve.get('nodes');
infl_term 	= iec.getValue(value_type); % Riskfree yield 
infl_nodes	= iec.get('nodes');

% get cash flow dates
obj = obj.rollout ('base',valuation_date);
cf_dates = obj.get('cf_dates');

if ~(strcmpi(obj.term_unit,'years') && obj.term == 1)
	error('pricing_humancapital: term has to be 1 years due to computational constraints');
end

% get timefactor vector
tf_vec = zeros(1,numel(cf_dates));
tf_vec(2:end) = diff(cf_dates) ./ 365;

% get input values
age = year(obj.salary_startdate) - obj.year_of_birth - obj.mortality_shift_years;
	
if valuation_date > datenum(obj.salary_startdate)
	tf_vec(1) = cf_dates(1) / 365;
else
	tf_vec(1) = 1;
end

% update scenario based information for mu_act and rf_term:
	% prepare risk free terms to provide yearly structure
	surv_probs_yearly = zeros(1,numel(tf_vec));
	rf_term_yearly = zeros(rows(rf_term),numel(tf_vec));
	infl_term_yearly = zeros(rows(infl_term),numel(tf_vec));
	tmp_surv_probs = longev.getRate('base',age);

	for ii=1:1:numel(tf_vec)
		tmp_node = cf_dates(ii);
		rf_term_yearly(:,ii) = discount_curve.getRate(value_type,tmp_node);
		infl_term_yearly(:,ii) = iec.getRate(value_type,tmp_node);
		tmp_surv_probs = tmp_surv_probs * longev.getRate('base',age + ii);
		surv_probs_yearly(ii) = tmp_surv_probs;
	end
	% account for spread to discount curve to reflect riskyness of cash flow
	rf_term_yearly = rf_term_yearly + obj.spread_risky;
	% prepare scenario dependent equity shocks
	mu_act = equity.getValue(value_type) .* sqrt(scale_rf/250);	% annualize risk factor shock
	if rows(mu_act) == 1
		mu_act = repmat(mu_act,rows(rf_term),1);
	end
	if rows(infl_term_yearly) == 1
		infl_term_yearly = repmat(infl_term_yearly,rows(rf_term),1);
	end

% ------------------------------------------------------------------------------

%~ Call pricing function C++
global use_parallel_pkg;
global number_parallel_cores;

% get global variable
if use_parallel_pkg == true
%~ Here is the meaning of the options of ndpar_arrayfun
    %~ "IdxDimensions", [2 1] The parallelization (or slicing, or indexing) 
		%~ should be done along the 2nd dimension of u and 1st dimension of v. 
		%~ A value of 0 means no indexing (no slicing), so the argument would be passed "as is".
    %~ "CatDimensions", [2 1] The outputs from each slice should be 
		%~ concatenated along the 2nd dimension of the first output and 1st dimension of the second output
    %~ "Vectorized", true Use only if the function is vectorized along 
		%~ the "indexing" dimensions.
    %~ "ChunksPerProc", 2 It means that each process should make 2 chunks 
		%~ 2 calls to f with "Vectorized", true). Increase this number to 
		%~ minimize memory usage for instance. Increasing this number is 
		%~ also useful if function executions can have very different durations. 
		%~ If a process is finished, it can take over jobs from another process that is still busy.
    
		hc_value  = ndpar_arrayfun(number_parallel_cores,@pricing_humancapital_cpp, ...
						obj.income_fix,obj.income_bonus,tf_vec, ...
						cf_dates,rf_term_yearly,obj.mu_risky,obj.s_risky, ...
						obj.corr,obj.mu_labor,obj.s_labor,mu_act,obj.bonus_cap, ...
						obj.bonus_floor,obj.nmc,surv_probs_yearly,infl_term_yearly, ...
						"Vectorized",true,"ChunksPerProc",1, ...
						"CatDimensions", [1],"VerboseLevel", 0, "IdxDimensions", [0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 1]);                   
else
		hc_value =  pricing_humancapital_cpp(obj.income_fix,obj.income_bonus,tf_vec, ...
					cf_dates,rf_term_yearly,obj.mu_risky,obj.s_risky, ...
					obj.corr,obj.mu_labor,obj.s_labor,mu_act,obj.bonus_cap, ...
					obj.bonus_floor,obj.nmc,surv_probs_yearly,infl_term_yearly);
end

end

%!assert(pricing_humancapital_cpp(80000,20000,[1,1,1], [365,730,1095],[0.005,0.01,0.02],0.02,0.2,0.9,0.005,0.02,-0.2,0.1,-0.5,5000,[0.999,0.99,0.98],[0.01,0.015,0.02]),293920,1000);



%# Copyright (C) 2023 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{sri} @var{VEV}] =} get_sri_level (@var{value_base}, @var{value_mc}, @var{mc_timestep_days})
%# Calculate SRI level per given P&L distribution according to PRIIPS SRI methodology.
%#
%# @seealso{}
%# @end deftypefn
function [sri VEV] = get_sri_level(value_base,value_mc,mc_timestep_days)
% SRI is based on P&L 250day --> scale 2.5percentile to 250d holding period
% calculate equivalent volatility based on relatice 97.5% VaR @250d

	no_scen = rows(value_mc)
	pnl_abs_sorted = sort(value_mc - value_base);
	var_975_rel    = -pnl_abs_sorted(ceil(0.025*no_scen)) / value_base;
	var_975_rel_pa = var_975_rel * sqrt(250/mc_timestep_days);
	
	VaR_ret_space = -var_975_rel_pa
	
	VEV = (sqrt(3.842 - 2*VaR_ret_space) - 1.96) % / sqrt(1) already annualized

	% calculate SRI class:
	sri = 1;
	mrm_class =  [1,2,3,4,5,6,7];
	vev_limit = [0,0.005,0.05,0.12,0.20,0.30,0.80];
	
	for ii=1:1:length(vev_limit)
		if VEV >= vev_limit(ii)
			sri = mrm_class(ii);
		else
			return;
		end
	end
end

%!test
%! assert(get_sri_level(1000,randn(500000,1) * 0.1959 * 1000 + 1000,250),4,eps);

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
%# @deftypefn {Function File} {@var{yield_to_maturity}} = calibrate_yield_to_maturity(@var{valuation_date},@var{tmp_cashflow_dates},@var{tmp_cashflow_values},@var{act_value})
%# Calibrate the yield to maturity according to given cashflows.
%# @end deftypefn

function [yield_to_maturity] = calibrate_yield_to_maturity(valuation_date,tmp_cashflow_dates,tmp_cashflow_values,act_value)

if ( nargin < 7 )
  spread_nodes = [365];
  spread_rates = [0];  
endif
if ( rows(tmp_cashflow_values) > 1 )
	tmp_cashflow_values = tmp_cashflow_values(1,:);
	disp('WARNING: More than one cash flow value scenario provided. Taking only first scenario as base values')
endif
% Start parameter
x0 = 0.01;

%p0=[x0]'; % Guessed parameters.
options(1) = 0;
options(2) = 1e-5;

% Calculate yield to maturity
[x, obj, info, iter] = sqp (x0, @ (x) phi_ytm(x,valuation_date,tmp_cashflow_dates, tmp_cashflow_values,act_value), [], [], -1, 1, 300);	%, obj, info, iter, nf, lambda @g

if (info == 101 )
	%disp ('       +++ SUCCESS: Optimization converged in +++');
	%steps = iter
elseif (info == 102 )
	disp ('       --- WARNING: The BFGS update failed. ---');
elseif (info == 103 )
	disp ('       --- WARNING: The maximum number of iterations was reached. ---');
elseif (info == 104 )
    %disp ('       --- WARNING: The stepsize has become too small. ---');
else
	disp ('       --- WARNING: Optimization did not converge! ---');
endif
% 
% return spread over yield
yield_to_maturity = x;

end 

%-----------------------------------------------------------------
%------------------- Begin Subfunction ---------------------------

% Definition Objective Function for yield to maturity:	       
function obj = phi_ytm (x,valuation_date,cashflow_dates,cashflow_values,act_value)
			tmp_yield = [x];
            nodes = [365];
            tmp_npv = pricing_npv(valuation_date,cashflow_dates, cashflow_values,0,nodes,tmp_yield);
			obj = (act_value - tmp_npv).^2;
endfunction
%------------------------------------------------------------------

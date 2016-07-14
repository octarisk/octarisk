%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
%# Copyright (C) 2016 IRRer-Zins <IRRer-Zins@t-online.de>
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
%# @deftypefn {Function File} { [@var{vola_spread}] =} calibrate_yield_to_maturity(
%# @var{valuation_date}, @var{tmp_cashflow_dates}, @var{tmp_cashflow_values},
%# @var{act_value}) 
%#
%# Calibrate the yield to maturity according to given cashflows.
%# @end deftypefn

function [yield_to_maturity] = calibrate_yield_to_maturity(valuation_date, ...
							tmp_cashflow_dates,tmp_cashflow_values,act_value)


if ( rows(tmp_cashflow_values) > 1 )
	tmp_cashflow_values = tmp_cashflow_values(1,:);
	fprintf('WARNING: More than one cash flow value scenario provided.')
    fprintf('Taking only first scenario as base values')
end
% Start parameter
x0 = 0.01;

%p0=[x0]'; % Guessed parameters.
options(1) = 0;
options(2) = 1e-5;

% Calculate yield to maturity
[x, obj, info, iter] = fmincon (@ (x) phi_ytm(x, valuation_date, ...
                                tmp_cashflow_dates, tmp_cashflow_values, act_value), ...
                                x0, [], [], [], [], -1, 1);

if (info == 1)
	%fprintf ('+++ calibrate_yield_to_maturity: SUCCESS: First-order optimality measure and maximum constraint violation was less than default values. +++\n');
elseif (info == 0)
	fprintf ('--- calibrate_yield_to_maturity: WARNING: BS Number of iterations or function evaluations exceeded default values. ---\n');
    x = -99;
elseif (info == -1)
	fprintf ('--- calibrate_yield_to_maturity: WARNING: BS Stopped by an output function or plot function. ---\n');
    x = -99;
elseif (info == -2)
    fprintf ('--- calibrate_yield_to_maturity: WARNING: BS No feasible point was found. ---\n');
    x = -99;
elseif (info == 2)
	fprintf ('+++ calibrate_yield_to_maturity: SUCCESS: Change in x and maximum constraint violation was less than default values. +++\n');
else
	fprintf ('--- calibrate_yield_to_maturity: WARNING: BS Optimization did not converge! ---\n');
    x = -99;
end

% return yield_to_maturity
yield_to_maturity = x;

end 

%-------------------------------------------------------------------------------
%--------------------------- Begin Subfunction ---------------------------------

% Definition Objective Function for yield to maturity:	       
function obj = phi_ytm (x,valuation_date,cashflow_dates, ...
						cashflow_values,act_value)
			tmp_yield = [x];
            nodes = [365];
            tmp_npv = pricing_npv(valuation_date,cashflow_dates, ...
								  cashflow_values,0,nodes,tmp_yield);
			obj = (act_value - tmp_npv).^2;
end
%-------------------------------------------------------------------------------


%!assert(calibrate_yield_to_maturity('31-Mar-2016', [ 307,672,1037,1402,1768,2133,2498,2863,3229],[ 3.509589,3.500000,3.500000,3.500000,3.509589,3.500000,3.500000,3.500000,103.509589],101.25),0.03408000,0.000001)
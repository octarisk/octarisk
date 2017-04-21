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
%# @deftypefn {Function File} { [@var{vola_spread}] =} calibrate_capfloor_volaspread(@var{capfloor}, @var{valuation_date}, @var{discount_curve}, @var{vola_surface}, @var{market_value})
%# Calibrate the implied volatility spread for Caps/Floors.
%# @end deftypefn

function [vola_spread retcode] = calibrate_capfloor_volaspread(capfloor,valuation_date,discount_curve,vola_surface, market_value)

% Start parameter
x0 = -0.0001;

% Setting lower bound to minimum of volatility value
sigma = min(min(min((vola_surface.values_base))));
lb = -sigma + 0.00001;

% Calling non-linear solver
[x, obj, info, iter] = fmincon (@ (x) phi(x,capfloor,valuation_date,discount_curve,vola_surface, market_value), x0, [], [], [], [], lb, []);


if (info == 1)
	retcode = 0;
	%fprintf ('+++ calibrate_soy_sqp: SUCCESS: First-order optimality measure and maximum constraint violation was less than default values. +++\n');
elseif (info == 0)
	fprintf ('--- calibrate_soy_sqp: WARNING: BS Number of iterations or function evaluations exceeded default values. ---\n');
    retcode = 255;
elseif (info == -1)
	fprintf ('--- calibrate_soy_sqp: WARNING: BS Stopped by an output function or plot function. ---\n');
    retcode = 255;
elseif (info == -2)
    fprintf ('--- calibrate_soy_sqp: WARNING: BS No feasible point was found. ---\n');
    retcode = 255;
elseif (info == 2)
	%fprintf ('+++ calibrate_soy_sqp: SUCCESS: Change in x and maximum constraint violation was less than default values. +++\n');
else
	fprintf ('--- calibrate_soy_sqp: WARNING: BS Optimization did not converge! ---\n');
    retcode = 255;
end

% return spread over yield
vola_spread = x;

end 

%-------------------------------------------------------------------------------
%------------------- Begin Subfunction -----------------------------------------
 
 
% Definition Objective Function:	    
function obj = phi (x,capfloor,valuation_date,discount_curve,vola_surface, market_value)
        obj = capfloor;
		obj.vola_spread = x;
		% cash flow rollout
		obj = obj.rollout(valuation_date,'base',discount_curve,vola_surface);
		% instrument prices
		obj = obj.calc_value(valuation_date,'base',discount_curve);
		% objective function
        obj = abs( obj.getValue('base')  - market_value)^2;
end
                           
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
%# @deftypefn {Function File} {[@var{vola_spread}] =} calibrate_swaption_underlyings(@var{call_flag}, @var{strike}, @var{V_fix}, @var{V_float}, @var{effdate}, @var{sigma}, @var{model}, @var{multiplier}, @var{value})
%# Calibrate the implied volatility spread for European swaptions according to 
%# Black76 or Bachelier (default) valuation model, if underlying fixed and
%# floating legs are used.
%# @end deftypefn

function vola_spread = calibrate_swaption_underlyings(call_flag,strike,V_fix, ...
                                    V_float,effdate,sigma,model,multiplier,value)

if ~(nargin == 9)
    print_usage();
end
% Start parameter
x0 = 0.0001;

% set lower boundary for volatility
lb = -sigma + 0.0001;

% call solver
[x, obj, info, iter] = fmincon ( @(x) phi(x,call_flag,strike,V_fix, ...
                                    V_float,effdate,sigma, ...
                                    model,multiplier,value), ...
                                x0, [], [], [], [], lb, []);	

if (info == 1)
	%fprintf ('+++ calibrate_swaption_underlyings: SUCCESS: First-order optimality measure and maximum constraint violation was less than default values. +++\n');
elseif (info == 0)
	fprintf ('--- calibrate_swaption_underlyings: WARNING: BS Number of iterations or function evaluations exceeded default values. ---\n');
    x = -99;
elseif (info == -1)
	fprintf ('--- calibrate_swaption_underlyings: WARNING: BS Stopped by an output function or plot function. ---\n');
    x = -99;
elseif (info == -2)
    fprintf ('--- calibrate_swaption_underlyings: WARNING: BS No feasible point was found. ---\n');
    x = -99;
elseif (info == 2)
	%fprintf ('+++ calibrate_swaption_underlyings: SUCCESS: Change in x and maximum constraint violation was less than default values. +++\n');
else
	fprintf ('--- calibrate_swaption_underlyings: WARNING: BS Optimization did not converge! ---\n');
    x = -99;
end

% return spread over yield
vola_spread = x;

end 

%-----------------------------------------------------------------
%------------------- Begin Subfunction ---------------------------
 
% Definition Objective Function:	    
function obj = phi (x,call_flag,strike,V_fix, V_float,effdate,sigma,model, ...
                        multiplier,market_value)
	    tmp_swaption_value = swaption_underlyings(call_flag,strike,V_fix, ...
                                    V_float,effdate,sigma+x, ...
                                    model)  .* multiplier;
        obj = abs( tmp_swaption_value  - market_value)^2;
end
 

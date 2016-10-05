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
%# @deftypefn {Function File} { [@var{vola_spread}] =} calibrate_option_barrier(@var{putcallflag}, @var{S}, @var{X}, @var{T}, @var{rf}, @var{sigma}, @var{q}, @var{rebate}, @var{multiplicator}, @var{market_value})
%# Calibrate the implied volatility spread for European Barrier options.
%# @end deftypefn

function vola_spread = calibrate_option_barrier(putcallflag,upordown,outorin, ...
                                            S,X,H,T,rf,sigma,q,rebate, ...
                                            multiplicator,market_value)

% Start parameter
x0 = -0.0001;

% Setting lower bound
lb = -sigma + 0.0001;

% Calling non-linear solver
[x, obj, info, iter] = fmincon (@ (x) phi(x,putcallflag,upordown,outorin, ...
                        S,X,H,T,rf,sigma,q,rebate, multiplicator, ...
                        market_value), x0, [], [], [], [], lb, []);


if (info == 1)
	%fprintf ('+++ calibrate_option_bjsten: SUCCESS: First-order optimality measure and maximum constraint violation was less than default values. +++\n');
elseif (info == 0)
	fprintf ('--- calibrate_option_bjsten: WARNING: BS Number of iterations or function evaluations exceeded default values. ---\n');
    x = -99;
elseif (info == -1)
	fprintf ('--- calibrate_option_bjsten: WARNING: BS Stopped by an output function or plot function. ---\n');
    x = -99;
elseif (info == -2)
    fprintf ('--- calibrate_option_bjsten: WARNING: BS No feasible point was found. ---\n');
    x = -99;
elseif (info == 2)
	%fprintf ('+++ calibrate_option_bjsten: SUCCESS: Change in x and maximum constraint violation was less than default values. +++\n');
else
	fprintf ('--- calibrate_option_bjsten: WARNING: BS Optimization did not converge! ---\n');
    x = -99;
end

% return spread over yield
vola_spread = x;

end 

%-------------------------------------------------------------------------------
%------------------- Begin Subfunction -----------------------------------------
 
 
% Definition Objective Function:	    
function obj = phi (x,putcallflag,upordown,outorin,S,X,H,T,rf,sigma,q,rebate, ...
                                            multiplicator,market_value)
        % set up objective function
        tmp_option_value = option_barrier(putcallflag,upordown,outorin,S,X,H, ...
                            T,rf,sigma + x,q,rebate) .* multiplicator;
        obj = abs( tmp_option_value  - market_value)^2;
end
                           
%!assert(calibrate_option_barrier(1,'D','in',100,90,100,365*0.5,0.08,0.23,0.04,3,1,13.833287),0.0200,0.00001) 
%!assert(calibrate_option_barrier(1,'D','in',100,90,100,365*0.5,0.08,0.32,0.04,3,1,14.881621),-0.0200,0.00001) 
%!assert(calibrate_option_barrier(0,'U','out',100,90,105,365*0.5,0.08,0.20,0.04,3,1,3.7760),0.0500,0.0001) 
%!assert(calibrate_option_barrier(0,'U','out',100,100,105,365*0.5,0.08,0.30,0.04,3,1,5.493),-0.0500,0.0001) 
%!assert(calibrate_option_barrier(0,'U','out',100,110,105,365*0.5,0.08,0.251,0.04,3,1,7.5187),-0.001,0.0001) 


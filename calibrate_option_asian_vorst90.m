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
%# @deftypefn {Function File} { [@var{vola_spread}] =} calibrate_option_asian_vorst90(@var{putcallflag}, @var{S}, @var{X}, @var{T}, @var{rf}, @var{sigma}, @var{multiplicator}, @var{market_value})
%# Calibrate the implied volatility spread for Asian options according to 
%# modified Black-Scholes valuation formula.
%# @end deftypefn

function vola_spread = calibrate_option_asian_vorst90(putcallflag, S, X, T, rf, sigma, ...
                                         divyield, multiplicator, market_value)

% Start parameter
x0 = -0.0001;

% Setting lower bound
lb = -sigma + 0.0001;

% Calling non-linear solver
[x, obj, info, iter] = fmincon (@ (x) phi(x,putcallflag, S, X, T, rf, sigma, ...
                             divyield, multiplicator, market_value), x0, [], [], [], [], lb, []);


if (info == 1)
	%fprintf ('+++ calibrate_option_asian_vorst90: SUCCESS: First-order optimality measure and maximum constraint violation was less than default values. +++\n');
elseif (info == 0)
	fprintf ('--- calibrate_option_asian_vorst90: WARNING: BS Number of iterations or function evaluations exceeded default values. ---\n');
    x = -99;
elseif (info == -1)
	fprintf ('--- calibrate_option_asian_vorst90: WARNING: BS Stopped by an output function or plot function. ---\n');
    x = -99;
elseif (info == -2)
    fprintf ('--- calibrate_option_asian_vorst90: WARNING: BS No feasible point was found. ---\n');
    x = -99;
elseif (info == 2)
	%fprintf ('+++ calibrate_option_asian_vorst90: SUCCESS: Change in x and maximum constraint violation was less than default values. +++\n');
else
	fprintf ('--- calibrate_option_asian_vorst90: WARNING: BS Optimization did not converge! ---\n');
    x = -99;
end

% return spread over yield
vola_spread = x;

end 

%-------------------------------------------------------------------------------
%------------------- Begin Subfunction -----------------------------------------
 
 
% Definition Objective Function:	    
function obj = phi (x,putcallflag,S,X,T,rf,sigma,divyield,multiplicator,market_value)
        % This is where we computer the sum of the square of the errors.
        % The parameters are in the vector p, which for us is a two by one.	
        tmp_option_value = option_asian_vorst90(putcallflag,S,X,T,rf,sigma+x,divyield) ...
                           .* multiplicator;
        obj = abs( tmp_option_value  - market_value)^2;
end
          
 
%!assert(calibrate_option_asian_vorst90(0,80,85,0.25*365,0.05,0.2,0.03,1,4.90),0.0288261340793257,0.000001) 
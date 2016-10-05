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
%# @deftypefn {Function File} { [@var{vola_spread}] =} calibrate_option_willowtree(@var{putcallflag},@var{americanflag}, @var{S}, @var{X}, @var{T}, @var{rf}, @var{sigma}, @var{divyield}, @var{stepsize}, @var{nodes}, @var{multiplicator}, @var{market_value}, @var{path_static})
%# Calibrate implied volatility spread for American options according 
%# to Willowtree valuation formula.
%# @seealso{option_willowtree}
%# @end deftypefn

function vola_spread = calibrate_option_willowtree(putcallflag,americanflag, ...
									S,X,T,rf,sigma,divyield,stepsize,nodes, ...
									multiplicator,market_value,path_static)

% Start parameter
x0 = -0.0001;

if nargin < 13
    path_static = '';
end

% Set lower boundary for volatility
lb = -sigma + 0.0001;
% Call solver
[x, obj, info, iter] = fmincon (@ (x) phi(x,putcallflag,americanflag,S,X,T, ...
                            rf,sigma,divyield,stepsize,nodes,multiplicator, ...
                            market_value,path_static), x0,[], [], [], [], lb, []);


if (info == 1)
	%fprintf ('+++ calibrate_option_willowtree: SUCCESS: First-order optimality measure and maximum constraint violation was less than default values. +++\n');
elseif (info == 0)
	fprintf ('--- calibrate_option_willowtree: WARNING: BS Number of iterations or function evaluations exceeded default values. ---\n');
    x = -99;
elseif (info == -1)
	fprintf ('--- calibrate_option_willowtree: WARNING: BS Stopped by an output function or plot function. ---\n');
    x = -99;
elseif (info == -2)
    fprintf ('--- calibrate_option_willowtree: WARNING: BS No feasible point was found. ---\n');
    x = -99;
elseif (info == 2)
	%fprintf ('+++ calibrate_option_willowtree: SUCCESS: Change in x and maximum constraint violation was less than default values. +++\n');
else
	fprintf ('--- calibrate_option_willowtree: WARNING: BS Optimization did not converge! ---\n');
    x = -99;
end


% return spread over yield
vola_spread = x;

end 


%-------------------------------------------------------------------------------
%------------------- Begin Subfunction -----------------------------------------
%Subfunctions private:

 
% Definition Objective Function:	    
	function obj = phi (x,putcallflag,americanflag,S,X,T,rf,sigma,divyield, ...
						stepsize,nodes,multiplicator,market_value,path_static)
            % This is where we computer the sum of the square of the errors.
            % The parameters are in the vector p, which for us is a two by one.	
			tmp_option_value = option_willowtree(putcallflag,americanflag, ...
							S,X,T,rf,sigma+x,divyield, ...
							stepsize,nodes,path_static) .* multiplicator;
			obj = abs( tmp_option_value  - market_value)^2;
		%----------------------------------------------
end
 
%!assert(calibrate_option_willowtree(0,1,10000,11000,30,0.01,0.2,0.0, 5,20,1,1000),-0.0405609,0.000002) 


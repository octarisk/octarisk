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
%# @deftypefn {Function File} {[@var{vola_spread}] =} calibrate_swaption(@var{PayerReceiverFlag}, @var{F}, @var{X}, @var{T}, @var{r}, @var{sigma}, @var{m}, @var{tau}, @var{multiplicator}, @var{market_value}, @var{model})
%# Calibrate the implied volatility spread for European swaptions according to 
%# Black76 or Bachelier (default) valuation model.
%# In extreme out-of-the-money scenarios there could be no solution in changing 
%# the volatility. But we dont care in this case at all,
%# since the influence of the volatility is neglectable in these extreme cases.
%# @end deftypefn

function vola_spread = calibrate_swaption(PayerReceiverFlag,F,X,T,r,sigma,m, ...
                                            tau,multiplicator,market_value,model)

if ~(nargin == 11)
    print_usage();
end
model = upper(model);
% Start parameter
x0 = 0.0001;

% set lower boundary for volatility
lb = -sigma + 0.0001;

% call solver
[x, obj, info, iter] = fmincon ( @(x) phi(x,PayerReceiverFlag,F,X,T,r,sigma, ...
                                m,tau,multiplicator,market_value,model), ...
                                x0, [], [], [], [], lb, []);	

if (info == 1)
	%fprintf ('+++ calibrate_swaption: SUCCESS: First-order optimality measure and maximum constraint violation was less than default values. +++\n');
elseif (info == 0)
	fprintf ('--- calibrate_swaption: WARNING: BS Number of iterations or function evaluations exceeded default values. ---\n');
    x = -99;
elseif (info == -1)
	fprintf ('--- calibrate_swaption: WARNING: BS Stopped by an output function or plot function. ---\n');
    x = -99;
elseif (info == -2)
    fprintf ('--- calibrate_swaption: WARNING: BS No feasible point was found. ---\n');
    x = -99;
elseif (info == 2)
	%fprintf ('+++ calibrate_swaption: SUCCESS: Change in x and maximum constraint violation was less than default values. +++\n');
else
	fprintf ('--- calibrate_swaption: WARNING: BS Optimization did not converge! ---\n');
    x = -99;
end

% return spread over yield
vola_spread = x;

end 

%-----------------------------------------------------------------
%------------------- Begin Subfunction ---------------------------
 
% Definition Objective Function:	    
function obj = phi (x,PayerReceiverFlag,F,X,T,r,sigma,m,tau,multiplicator,market_value,model)
        if ( strcmp(upper(model),'BLACK76') )
			tmp_swaption_value = swaption_black76(PayerReceiverFlag,F,X,T,r,sigma+x,m,tau) .* multiplicator;
        else
            tmp_swaption_value = swaption_bachelier(PayerReceiverFlag,F,X,T,r,sigma+x,m,tau) .* multiplicator;
        end
        obj = abs( tmp_swaption_value  - market_value)^2;
end
 

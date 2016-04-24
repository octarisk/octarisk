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
%# @deftypefn {Function File} {@var{vola_spread}} = calibrate_swaption(@var{PayerReceiverFlag},@var{F},@var{X},@var{T},@var{r},@var{sigma},@var{m},@var{tau},@var{multiplicator},@var{market_value},@var{model})
%# Calibrate the implied volatility spread for European swaptions according to Black76 or Bachelier (default) valuation model.
%# In extreme out-of-the-money scenarios there could be no solution in changing the volatility. But we dont care in this case at all,
%# since the influence of the volatility is neglectable in this extreme cases.
%# @end deftypefn

function vola_spread = calibrate_swaption(PayerReceiverFlag,F,X,T,r,sigma,m,tau,multiplicator,market_value,model)

if ~(nargin == 11)
    print_usage();
end
model = toupper(model);
% Start parameter
x0 = 0.0001;

%tol = 1e-11;
lb = -sigma + 0.0001;
[x, obj, info, iter] = sqp (x0, @ (x) phi(x,PayerReceiverFlag,F,X,T,r,sigma,m,tau,multiplicator,market_value,model), [], [], lb, [], 300);	%, obj, info, iter, nf, lambda @g

if (info == 101 )
	%disp ('       +++ SUCCESS: Optimization converged in +++');
	%steps = iter
elseif (info == 102 )
	%disp ('       --- WARNING: The BFGS update failed. ---');
    x = -99;
elseif (info == 103 )
	%disp ('       --- WARNING: The maximum number of iterations was reached. ---');
    x = -99;
elseif (info == 104 )
    disp ('       --- WARNING: The stepsize has become too small. ---');
    %x = -99;
else
	%disp ('       --- WARNING: Optimization did not converge! ---');
    x = -99;
end

% return spread over yield
vola_spread = x;

end 

%-----------------------------------------------------------------
%------------------- Begin Subfunction ---------------------------
 
% Definition Objective Function:	    
function obj = phi (x,PayerReceiverFlag,F,X,T,r,sigma,m,tau,multiplicator,market_value,model)
        if ( strcmp(model,'BLACK76') )
			tmp_swaption_value = swaption_black76(PayerReceiverFlag,F,X,T,r,sigma+x,m,tau) .* multiplicator;
        else
            tmp_swaption_value = swaption_bachelier(PayerReceiverFlag,F,X,T,r,sigma+x,m,tau) .* multiplicator;
        end
        obj = abs( tmp_swaption_value  - market_value)^2;
end
 

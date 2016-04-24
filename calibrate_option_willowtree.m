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
%# @deftypefn {Function File} {@var{vola_spread}} = calibrate_option_willowtree(@var{putcallflag},@var{americanflag},@var{S},@var{X},@var{T},@var{rf},@var{sigma},@var{divyield},@var{stepsize},@var{nodes},@var{multiplicator},@var{market_value})
%# Calibrate the implied volatility spread for American options according to Willowtree valuation formula.
%# @end deftypefn

function vola_spread = calibrate_option_willowtree(putcallflag,americanflag,S,X,T,rf,sigma,divyield,stepsize,nodes,multiplicator,market_value)

%option_value = option_bs(putcallflag,S,X,T,rf,sigma) .* multiplicator
% Start parameter
x0 = -0.0001;

%p0=[x0]'; % Guessed parameters.

lb = -sigma + 0.0001;
[x, obj, info, iter] = sqp (x0, @ (x) phi(x,putcallflag,americanflag,S,X,T,rf,sigma,divyield,stepsize,nodes,multiplicator,market_value), [], [], lb, [], 300);	%, obj, info, iter, nf, lambda @g

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
endif

% 
%New_value = option_bs(putcallflag,S,X,T,rf,sigma+x) .* multiplicator
% return spread over yield
vola_spread = x;

end 

%-----------------------------------------------------------------
%------------------- Begin Subfunction ---------------------------
 
 
%-----------------------------------------------------------------
%------------------- Begin Subfunction ---------------------------
%Subfunctions private:

 
% Definition Objective Function:	    
	function obj = phi (x,putcallflag,americanflag,S,X,T,rf,sigma,divyield,stepsize,nodes,multiplicator,market_value)
            % This is where we computer the sum of the square of the errors.
            % The parameters are in the vector p, which for us is a two by one.	
			tmp_option_value = option_willowtree(putcallflag,americanflag,S,X,T,rf,sigma+x,divyield,stepsize,nodes) .* multiplicator;
			obj = abs( tmp_option_value  - market_value)^2;
		%----------------------------------------------
endfunction
 

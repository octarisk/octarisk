%# Copyright (C) 2015 Stefan Schloegl <schinzilord@octarisk.com>
%# Copyright (C) 2006 User vanna at http://www.quantcode.com (it is stated:
%#      "This is a free for everyone site, and all source code created here is freely downloadable."
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
%# @deftypefn {Function File} {[@var{value}] =} option_bs_barrier (@var{CallPutFlag}, @var{UpFlag},@var{S}, @var{X}, @var{H},@var{T}, @var{r}, @var{sigma}, @var{q})
%#
%# Compute the prices of European call or put out or in barrier options according to Black-Scholes valuation formula.
%# The code is written for out barrier options. The values for in barrier options are derived from the no arbitrage condition O = O_out + O_in.
%# This only holds for no rebate options.@*
%# Variables:
%# @itemize @bullet
%# @item @var{CallPutFlag}: Call: '1', Put: '0'
%# @item @var{UpFlag}: Up: 'U', Down: 'D'
%# @item @var{OutorIn}: 'out' or 'in' barrier option
%# @item @var{S}: stock price at time 0
%# @item @var{X}: strike price 
%# @item @var{H}: barrier
%# @item @var{T}: time to maturity in days 
%# @item @var{r}: annual risk-free interest rate (continuously compounded)
%# @item @var{sigma}: implied volatility of the stock price measured as annual standard deviation
%# @item @var{q}: dividend rate p.a., continously compounded
%# @end itemize
%# @seealso{option_willowtree, swaption_black76, option_bs}
%# @end deftypefn

function [optionValue] = option_bs_barrier(PutOrCall,UpOrDown,OutorIn,S0,X,H,T,r,sigma,q,Rebate)
 if nargin < 9 || nargin > 11
    print_usage ();
  end
  if nargin == 9
    divrate = 0.00;
    Rebate = 0.0;
  end 
  if nargin == 10
    Rebate = 0.0;
  end
   
  if ~isnumeric (PutOrCall)
    error ('PutOrCall must be either 1 or 0 ')
  elseif ~ischar (UpOrDown)
    error ('UpOrDown must be either D or U ')
  elseif ~ischar (OutorIn)
    error ('UpOrDown must be either out or in ')
  elseif ~isnumeric (S0)
    error ('Underlying price S0 must be numeric ')
  elseif ~isnumeric (X)
    error ('Strike X must be numeric ')
  elseif ~isnumeric (H)
    error ('Strike H must be numeric ')  
  elseif X < 0
    error ('Strike X must be positive ')
  elseif S0 < 0
    error ('Price S0 must be positive ')    
  elseif ~isnumeric (T)
    error ('Time T in years must be numeric ')
  elseif ( T < 0)
    error ('Time T must be positive ')    
  elseif ~isnumeric (r)
    error ('Riskfree rate r must be numeric ')    
  elseif ~isnumeric (sigma)
    error ('Implicit volatility sigma must be numeric ')
  elseif ~isnumeric (q)
    error ('Dividend rate must be numeric ')     
  elseif ( sigma < 0)
    error ('Volatility sigma must be positive ') 
  elseif ~isnumeric (Rebate)
    error ('Rebate must be numeric ')      
  end
  
T = T ./ 365;

b = r - q;

mu = (b-sigma.^2./2)./(sigma.^2);
lambda = sqrt(mu.^2+2.*r./(sigma.^2));

x1 = log(S0./X)./(sigma.*sqrt(T)) + (1+mu).*sigma.*sqrt(T);
x2 = log(S0./H)./(sigma.*sqrt(T)) + (1+mu).*sigma.*sqrt(T);
y1 = log((H.^2)./(S0.*X))./(sigma.*sqrt(T)) + (1+mu).*sigma.*sqrt(T);
y2 = log(H./S0)./(sigma.*sqrt(T)) + (1+mu).*sigma.*sqrt(T);

z = log(H./S0)./(sigma.*sqrt(T)) + lambda.*sigma*sqrt(T);


%Put
if UpOrDown == 'D'
   if (X > H)
      eta = +1;
      phi = -1;
      A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1)                        - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
      B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2)                        - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
      C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
      D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
      E = Rebate.*exp(-r.*T).*[ normcdf(eta.*x2-eta.*sigma.*sqrt(T)) - ((H./S0).^(2.*mu)).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)) ];
      F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
      put = A - B + C - D + F;
   else
      eta = +1;
      phi = -1;
      F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
      put = F;
   end

elseif UpOrDown == 'U' 
   if (X > H)
      eta = -1;
      phi = -1;
      B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2)                        - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
      D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
      F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
      put = B - D + F;
   else
      eta = -1;
      phi = -1;
      A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1)                        - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
      C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
      F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
      put = A - C + F;
   end
end

%Call
if UpOrDown == 'D'
   if (X > H)
      eta = +1;
      phi = +1;
      A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1)                        - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
      C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
      F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
      call = A - C + F;
   else
      eta = +1;
      phi = +1;
      B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2)                        - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
      D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
      F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
      call = B - D + F;
   end
elseif UpOrDown == 'U'
   if (X > H)
      eta = -1;
      phi = +1;
      F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
      call = F;
   else
      eta = -1;
      phi = +1;
      A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1)                         - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
      B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2)                         - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
      C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1)))  - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
      D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1)))  - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
      E = Rebate.*exp(-r.*T).*[ normcdf(eta.*x2-eta.*sigma.*sqrt(T)) - ((H./S0).^(2.*mu)).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)) ];
      F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
      call = A - B + C - D + F;
   end
end

% select case depending on option type and out or in type
% it is assumed that arbitrage freeness holds: C = C_out + C_in and P = P_in + P_out. This condition holds for rebate == 0 only
if PutOrCall == 0       % Calls
   option_out = call;
   C = option_bs(1,S0,X,T .* 365,r,sigma,q)
   option_in = C - option_out;
elseif PutOrCall == 1   % Puts
   option_out = put;
   P = option_bs(0,S0,X,T .* 365,r,sigma,q)
   option_in = P - option_out;
end

if (strcmp('out',OutorIn))
    optionValue = option_out;
else
    if ( Rebate > 0 )
        fprintf('ERROR: No values for in barrier options incl. rebate can be calculated.');
    end
    optionValue = option_in;
end


end %end function




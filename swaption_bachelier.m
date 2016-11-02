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
%# @deftypefn {Function File} {[@var{SwaptionBachelierValue}] =} swaption_bachelier (@var{PayerReceiverFlag}, @var{F}, @var{X}, @var{T}, @var{r}, @var{sigma}, @var{m}, @var{tau})
%#
%# Compute the price of european interest rate swaptions according to Bachelier Pricing Functions assuming normal-distributed volatilities.
%# Fast implementation, fully vectorized.@*
%# @example
%# @group
%# C = ((F-X)*N(d1) + sigma*sqrt(T)*n(d1))*exp(-rT) * multiplicator(m,tau)
%# P = ((X-F)*N(-d1) + sigma*sqrt(T)*n(d1))*exp(-rT) * multiplicator(m,tau)
%# d1 = (F-X)/(sigma*sqrt(T))
%# @end group
%# @end example
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{PayerReceiverFlag}: Call / Payer '1' (pay fixed) or Put / Receiver '0' (receive fixed, pay floating) swaption
%# @item @var{F}: forward rate of underlying interest rate (forward in T years for tau years)
%# @item @var{X}: strike rate 
%# @item @var{T}: time in days to maturity
%# @item @var{r}: annual risk-free interest rate (continuously compounded)
%# @item @var{sigma}: implied volatility of the interest rate measured as annual standard deviation
%# @item @var{m}: Number of Payments per year (m = 2 -> semi-annual) (continuous compounding is assumed)
%# @item @var{tau}: Tenor of underlying swap in Years 
%# @end itemize
%# @seealso{option_bs}
%# @end deftypefn

function SwaptionBachelierValue = swaption_bachelier(PayerReceiverFlag,F,X,T,r,sigma,m,tau)
 
 if nargin < 8 || nargin > 8
    print_usage ();
 end
   
if ~isnumeric (PayerReceiverFlag)
    error ('PayerReceiverFlag must be either 1 or 0 ')
elseif ~isnumeric (F)
    error ('Underlying future price F must be numeric ')
elseif ~isnumeric (X)
    error ('Strike X must be numeric ')
elseif X < 0
    error ('Strike X must be positive ')   
elseif ~isnumeric (T)
    error ('Time T in years must be numeric ')
elseif ( T < 0)
    error ('Time T must be positive ')    
elseif ~isnumeric (r)
    error ('Riskfree rate r must be numeric ')    
elseif ~isnumeric (sigma)
    error ('Implicit volatility sigma must be numeric ') 
elseif ~isnumeric (m)
    error ('Number of payments must be numeric ') 
elseif (m < 0)
    error ('Number of payments must be positive ')    
elseif (tau < 0)
    error ('Tenor of underlying swap must be positive ') 
elseif ~isnumeric (tau)
    error ('Tenor of underlying swap must be numeric ')     
elseif ( sigma < 0)
    error ('Volatility sigma must be positive ')        
end
T = T ./ 365;

% C = ((F-X)*N(d1) + sigma*sqrt(T)*n(d1))*exp(-rT) * multiplicator(m,tau)
%# P = ((X-F)*N(-d1) + sigma*sqrt(T)*n(d1))*exp(-rT) * multiplicator(m,tau)
    d1 = (F-X)./(sigma.*sqrt(T));

    
% Calculation of BS Price
if ( PayerReceiverFlag == 1 ) % Call / Payer swaption 'p'
    N1 = 0.5.*(1+erf(d1./sqrt(2)));
    n1 = exp(- d1 .^2 /2)./sqrt(2*pi);
    value = ((F-X).*N1 + sigma.*sqrt(T).*n1).*exp(-r.*T);
else   % Put / Receiver swaption 'r'  
    N1 = 0.5.*(1+erf(-d1./sqrt(2)));
    n1 = exp(- d1 .^2 /2)./sqrt(2*pi);
    value = (-(X-F).*N1 + sigma.*sqrt(T).*n1).*exp(-r.*T);
end

   
% Calculate continuous compounding multiplicator for tenor of swap
multi = (1 - (1 ./ ((1 + F ./ m) .^ (tau .* m)))) ./ F;

% Return total Swaption Value
SwaptionBachelierValue = value .* multi;
  
end

%!assert(swaption_bachelier(1,0.0609090679070339,0.062,1825,0.06,0.01219,2,3) * 100, 2.07117344171174,0.00001);
%!assert(swaption_bachelier(0,0.0609090679070339,0.062,1825,0.06,0.01219,2,3) * 100, 2.06419541383222,0.00001);
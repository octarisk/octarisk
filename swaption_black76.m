%# Copyright (C) 2015 Schinzilord <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{SwaptionB76Value}] =} 
%# swaption_black76 (@var{PayerReceiverFlag}, @var{F}, @var{X}, @var{T}, 
%# @var{r}, @var{sigma}, @var{m}, @var{tau})
%#
%# Compute the price of european interest rate swaptions according to Black76 
%# pricing functions.
%# Fast implementation, fully vectorized.@*
%# @example
%# @group
%# C = (F*N( d1) - X*N( d2))*exp(-rT) * multiplicator(m,tau)
%# P = (X*N(-d2) - F*N(-d1))*exp(-rT) * multiplicator(m,tau)
%# d1 = (log(S/X) + (r + 0.5*sigma^2)*T)/(sigma*sqrt(T))
%# d2 = d1 - sigma*sqrt(T)
%# @end group
%# @end example
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{PayerReceiverFlag}: Call / Payer '1' (pay fixed) or Put / Receiver
%#  '0' (receive fixed, pay floating) swaption
%# @item @var{F}: forward rate of underlying interest rate (
%# forward in T years for tau years)
%# @item @var{X}: strike rate 
%# @item @var{T}: time in days to maturity
%# @item @var{r}: annual risk-free interest rate (continuously compounded)
%# @item @var{sigma}: implied volatility of the interest rate measured as annual 
%# standard deviation
%# @item @var{m}: Number of Payments per year (m = 2 -> semi-annual) (continuous 
%# compounding is assumed)
%# @item @var{tau}: Tenor of underlying swap in Years 
%# @end itemize
%# @seealso{swaption_bachelier}
%# @end deftypefn

function SwaptionB76Value = swaption_black76(PayerReceiverFlag,F,X,T,r, ...
                                                sigma,m,tau)

 if nargin < 8 || nargin > 8
    print_usage ();
 end
   
if ~isnumeric (PayerReceiverFlag)
    error ('PayerReceiverFlag must be either 1 or 0 ')
elseif ~isnumeric (F)
    error ('Underlying forward rate F must be numeric ')
elseif ~isnumeric (X)
    error ('Strike X must be numeric ')
elseif X < 0
    error ('Strike X must be positive ')
elseif F < 0
    error ('Price F must be positive ')    
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
    d1 = (log(F./X) + (0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
    d2 = d1 - sigma.*sqrt(T);
    
% Calculation of BS Price
if ( PayerReceiverFlag == 1 ) % Call / Payer swaption 'p'
    N1 = 0.5.*(1+erf(d1./sqrt(2)));
    N2 = 0.5.*(1+erf(d2./sqrt(2)));
    value = (F.*N1 - X.*N2).*exp(-r.*T);
else   % Put / Receiver swaption 'r'  
    N1 = 0.5.*(1+erf(-d1./sqrt(2)));
    N2 = 0.5.*(1+erf(-d2./sqrt(2)));
    value = (X.*N2 - F.*N1).*exp(-r.*T);
end

   
% Calculate continuous compounding multiplicator for tenor of swap
multi = (1 - (1 ./ ((1 + F ./ m) .^ (tau .* m)))) ./ F;

% Return total Swaption Value
SwaptionB76Value = value .* multi;
  
end

%!assert(swaption_black76(1,0.0609090679070339,0.062,1825,0.06,0.2,2,3) * 100,2.07098170368683,0.00000001);
%!assert(swaption_black76(0,0.0609090679070339,0.062,1825,0.06,0.2,2,3) * 100,2.28955623758578,0.00000001);

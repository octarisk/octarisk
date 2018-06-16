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
%# @item @var{sigma}: implied volatility of the interest rate measured as annual standard deviation
%# @item @var{Annuity}: Annuity (Sum of discount factors for underlying term dates)
%# @end itemize
%# @seealso{option_bs}
%# @end deftypefn

function SwaptionBachelierValue = swaption_bachelier(PayerReceiverFlag,F,X,T,sigma,Annuity)
 
 if nargin < 6 || nargin > 6
    print_usage ();
 end
   
if ~isnumeric (PayerReceiverFlag)
    error ('PayerReceiverFlag must be either 1 or 0 ')
elseif ~isnumeric (F)
    error ('Underlying future price F must be numeric ')
elseif ~isnumeric (X)
    error ('Strike X must be numeric ') 
elseif ~isnumeric (T)
    error ('Time T in years must be numeric ')
elseif ( T < 0)
    error ('Time T must be positive ')    
elseif ~isnumeric (sigma)
    error ('Implicit volatility sigma must be numeric ') 
elseif ~isnumeric (Annuity)
    error ('Annuity must be numeric ')       
elseif ~( isempty(sigma(sigma< 0)))
    error ('Volatility sigma must be positive ')      
end
T = T ./ 365;

d1 = (F-X)./(sigma.*sqrt(T));
    
% Calculation of Bachelier Price
if ( PayerReceiverFlag == 1 ) % Call / Payer swaption
    N1 = 0.5.*(1+erf(d1./sqrt(2)));
    n1 = exp(- d1 .^2 /2)./sqrt(2*pi);
    value = sigma.*sqrt(T).*Annuity.*(d1.*N1+n1);
else   % Put / Receiver swaption  
    N1 = 0.5.*(1+erf(-d1./sqrt(2)));
    n1 = exp(- d1 .^2 /2)./sqrt(2*pi);
    value = sigma.*sqrt(T).*Annuity.*((-d1).*N1+n1);
end

% Return total Swaption Value
SwaptionBachelierValue = value;
  
end

%!assert(swaption_bachelier(1,1.954904222037591e-002,0.03,3650,6.656275999999999e-003,8.2844976761307) * 100, 3.468017499703750,0.00000001);
%!assert(swaption_bachelier(0,1.954904222037591e-002,0.03,3650,6.656275999999999e-003,8.2844976761307) * 100,  12.12611104356729,0.00000001);
%# Copyright (C) 2015 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {@var{value} =} option_asian_vorst90 (@var{CallPutFlag}, @var{S}, @var{X}, @var{T}, @var{r}, @var{sigma}, @var{divrate})
%#
%# Compute the prices of european type asian continously geometric average price 
%# call or put options  according to Kemna and Vorst (1990) valuation formula.
%# Convert all input parameter into continuously compounded values with act/365
%# day count convention.
%# The implementation is based on following literature:
%# @itemize @bullet
%# @item "Complete Guide to Option Pricing Formulas", Espen Gaarder Haug, 2nd Edition, page 183ff.
%# @end itemize
%# Variables:
%# @itemize @bullet
%# @item @var{CallPutFlag}: Call: "1", Put: "0"
%# @item @var{S}: stock price at time 0
%# @item @var{X}: strike price 
%# @item @var{T}: time to maturity in days 
%# @item @var{r}: annual risk-free interest rate (continuous, act/365)
%# @item @var{sigma}: annualized implied volatility (continuous, act/365)
%# @item @var{divrate}: dividend rate p.a. (continuous, act/365)
%# @end itemize
%# @seealso{option_bs, option_asian_levy}
%# @end deftypefn

function [value] = option_asian_vorst90(CallPutFlag,S,X,T,r,sigma,divrate)
 
 if nargin < 6 || nargin > 8
    print_usage ();
  end
  if nargin == 6
    divrate = 0.00;
  end
   
  if ~ isnumeric (CallPutFlag)
    error ('CallPutFlag must be either 1 or 0 ')
  elseif ~ isnumeric (S)
    error ('Underlying price S must be numeric ')
  elseif ~ isnumeric (X)
    error ('Strike X must be numeric ')
  elseif X < 0
    error ('Strike X must be positive ')
  elseif S < 0
    error ('Price S must be positive ')    
  elseif ~ isnumeric (T)
    error ('Time T in years must be numeric ')
  elseif ( T < 0)
    error ('Time T must be positive ')    
  elseif ~ isnumeric (r)
    error ('Riskfree rate r must be numeric ')    
  elseif ~ isnumeric (sigma)
    error ('Implicit volatility sigma must be numeric ')
  elseif ~ isnumeric (divrate)
    error ('Dividend rate must be numeric ')     
  elseif ~( isempty(sigma(sigma< 0)))
    error ('Volatility sigma must be positive ')        
  end
  
% convert days to maturity in timefactor (assuming act/365)
T = T ./ 365;

% adjust sigma and cost of carry
sigma_adj = sigma ./ sqrt( 3);
% Formula according to Hull, "Options, Futures and other Derivatives"
%   7th edition, page 564:
b_adj = 0.5 .* ( divrate + r - sigma.^2/6);

% call option_bs
    d1 = (log(S./X) + (b_adj + 0.5.*sigma_adj.^2).*T)./(sigma_adj.*sqrt( T));
    d2 = d1 - sigma_adj.*sqrt(T);

% Calculation of Black-Scholes value
if ( CallPutFlag == 1)
    normcdf1 = 0.5.*(1+erf(d1./sqrt(2)));
    normcdf2 = 0.5.*(1+erf(d2./sqrt(2)));
    value = S .* exp((b_adj-r).*T) .* normcdf1 - X .* exp(-r.*T) .* normcdf2;
else   % Put 
    normcdf1 = 0.5.*(1+erf(-d1./sqrt(2)));
    normcdf2 = 0.5.*(1+erf(-d2./sqrt(2)));
    value = X .* exp(-r.*T) .* normcdf2 - S .* exp((b_adj-r) .*T) .* normcdf1;
end

end
% Test cases from Haug, page 183f:
%!assert(option_asian_vorst90(1,100,90,1*365,0.035,0.2,0.0),11.8625804732081,0.0000001)
%!assert(option_asian_vorst90(0,80,85,0.25*365,0.05,0.2,0.03),4.69222131224534,0.0000001)
%!assert(option_asian_vorst90(0,[70;80;90;100],85,0.25*365,0.05,0.2,0.03),[14.177863720;4.6922213122;0.311810932;0.0022132723],0.00001)

  

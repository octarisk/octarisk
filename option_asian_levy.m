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
%# @deftypefn {Function File} {@var{value} =} option_asian_levy (@var{CallPutFlag}, @var{S}, @var{X}, @var{T}, @var{r}, @var{sigma}, @var{divrate}, @var{n})
%#
%# Compute the prices of european type asian average price call or put options 
%# according to Levy (1992) valuation formula.
%# Convert all input parameter into continuously compounded values with act/365
%# day count convention.
%#
%# The implementation is based on following literature:
%# @itemize @bullet
%# @item "Complete Guide to Option Pricing Formulas", Espen Gaarder Haug, 2nd Edition, page 190ff.
%# @end itemize
%# Variables:
%# @itemize @bullet
%# @item @var{CallPutFlag}: Call: "1", Put: "0"
%# @item @var{S}: stock price at time 0
%# @item @var{X}: strike price 
%# @item @var{T}: time to maturity in days 
%# @item @var{r}: annual risk-free interest rate (continuous, act/365)
%# @item @var{sigma}: annualized implied volatility 
%# @item @var{divrate}: dividend rate p.a. (continuous, act/365)
%# @item @var{n}: number of averaging dates (defaults to continuous: n = number of days to maturity)
%# @end itemize
%# @seealso{option_bs, option_asian_vorst90}
%# @end deftypefn

function Value = option_asian_levy(CallPutFlag,S,X,T,r,sigma,divrate)
 
 if nargin < 6 || nargin > 7
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
  

T = T ./ 365;
T2 = T; % only in this case the values of Haug can be reproduced ?!?
S_A = S;
b = r - divrate; % cost of carry according to Haug
    
S_E = S ./ (T .* b) .* (exp((b-r) .* T2) - exp(-r .* T2));

M1 = (exp((2*b + sigma .^ 2) .* T2) - 1) ./ (2*b + sigma .^ 2);
M2 = (exp(b .* T2) - 1) ./ b;
M = 2*S .^ 2 ./ (b + sigma .^ 2) .*  (M1 - M2);
D = M ./ T .^ 2;
V = log(D) - 2 * (r .* T2 + log(S_E));
Xstar = X - S_A .* ( T - T2 ) ./ T; 
d1 = 1 ./ sqrt(V) .* (log(D)/2 - log(Xstar));
d2 = d1 - sqrt(V);
% implementation based on error function is much faster than normcdf(d1):
normcdf_d1 = 0.5.*(1+erf(d1./sqrt(2)));
normcdf_d2 = 0.5.*(1+erf(d2./sqrt(2)));

% return call or put price
if CallPutFlag == 1 % call
    Value = S_E .* normcdf_d1 - X .* exp(-r .* T2) .* normcdf_d2;
else
    Price_Call = S_E .* normcdf_d1 - X .* exp(-r .* T2) .* normcdf_d2;
    Value = Price_Call - S_E + X .* exp(-r .* T2);
end

end

% Test cases from Haug, page 191ff:
%!assert(option_asian_levy(1,100,[95;100;105],0.75*365,0.1,0.15,0.05),[7.05435649933824;3.78453158217341;1.67287495614393],0.0000001)
%!assert(option_asian_levy(1,100,[95;100;105],0.75*365,0.1,0.35,0.05),[10.12128991523418;7.50377214245155;5.40712811308192],0.0000001)
%!assert(option_asian_levy(1,6.8,6.9,0.5*365,0.07,0.14,0.09),0.0944157786932514,0.0000001) 
%!assert(option_asian_levy(0,6.8,6.9,0.5*365,0.07,0.14,0.09),0.223697742233234,0.0000001)
%!error(option_asian_levy(1,6.8,6.9,0.5*365,0.07,-0.14,0.09)) 
% Test case from Hull "Options, Future and other Derivatives", 7th Edition, page 565
%!assert(option_asian_levy(1,50,50,1*365,0.1,0.4,0.00),5.6168,0.001) 

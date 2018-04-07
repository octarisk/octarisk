%# Copyright (C) 2017 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{value}] =} option_binary (@var{CallPutFlag}, @var{binary_type}, @var{S}, @var{X1}, @var{X2}, @var{T}, @var{r}, @var{sigma}, @var{divrate})
%#
%# Compute the prices of European Binary call or put options according to 
%# Reiner and Rubinstein (Unscrambling the Binary Code, RISK 4 (October 1991), 
%# pp. 75-83)  valuation formulas:@*
%# @*
%# Option type Gap@*
%# A gap call option pays the difference (gap) between spot and either one of two
%# strike values:
%# @example
%# @group
%# C(S,X1,X2,T) = X2*exp(-rT)*N(d)
%# P(S,X1,X2,T) = X2*exp(-rT)*N(-d)
%# d = (log(S/X1) + (r - divrate + 0.5*sigma^2)*T)/(sigma*sqrt(T))
%# @end group
%# @end example
%# @*
%# Option type Cash-or-Nothing@*
%# A cash or nothing option pays the pre-defined amount X2 if the value is larger
%# than the strike X1 (call option) or lower than the strike X1(put option):
%# @example
%# @group
%# C(S,X1,X2,T) = N(d)*X2*exp(-rT)
%# P(S,X1,X2,T) = N(-d)*X2*exp(-rT)
%# d = (log(S/X1) + (r - divrate - 0.5*sigma^2)*T)/(sigma*sqrt(T))
%# @end group
%# @end example
%# @*
%# Option type Asset-or-Nothing@*
%# An asset or nothing option pays the future spot value S if the value is larger
%# than the strike X1(call option) or lower than the strike X1 (put option):
%# @example
%# @group
%# C(S,X1,T) = S*N(d)*exp(-divrate*T)
%# P(S,X1,T) = S*N(-d)*exp(-divrate*T)
%# d = (log(S/X1) + (r - divrate + 0.5*sigma^2)*T)/(sigma*sqrt(T))
%# @end group
%# @end example
%# @*
%# Option type Supershare@*
%# A supershare option has a payoff, if the future spot values lies between
%# an lower bound X1 and upper bound X2, and is zero otherwise:
%# @example
%# @group
%# Value(S,X1,X2,T) = (S*exp(-divrate*T)/X1) * (N(d1) - N(d2))
%# d1 = (log(S/X1) + (r - divrate + 0.5*sigma^2)*T)/(sigma*sqrt(T))
%# d2 = (log(S/X2) + (r - divrate + 0.5*sigma^2)*T)/(sigma*sqrt(T))
%# @end group
%# @end example
%# @*
%# All formulas are taken from Haug, Complete Guide to Option Pricing Formulas,
%# 2nd edition, page 174ff.@*
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{CallPutFlag}: Call: '1', Put: '0'
%# @item @var{binary_type}: can be 'gap','cash','asset'
%# @item @var{S}: stock price at time 0
%# @item @var{X1}: strike price (lower bound for supershare or gap options)
%# @item @var{X2}: payoff strike price (used for Gap and cash options, upper bound 
%# of supershare options)
%# @item @var{T}: time to maturity in days 
%# @item @var{r}: annual risk-free interest rate (continuously compounded, act/365)
%# @item @var{sigma}: implied volatility of the stock price measured as annual 
%# standard deviation
%# @item @var{divrate}: dividend rate p.a., continously compounded
%# @end itemize
%# @seealso{option_willowtree, option_bs}
%# @end deftypefn

function value = option_binary(CallPutFlag,binary_type,S,X1,X2,T,r,sigma,divrate)
 
 if nargin < 7 || nargin > 9
    print_usage ();
  end
  if nargin == 8
    divrate = 0.0;
  end 
   
  if ~isnumeric (CallPutFlag)
    error ('CallPutFlag must be either 1 or 0 ')
  elseif ~isnumeric (S)
    error ('Underlying price S must be numeric ')
  elseif ~isnumeric (X1)
    error ('Strike X1 must be numeric ')
  elseif X1 < 0
    error ('Strike X1 must be positive ')
  elseif ~isnumeric (X2)
    error ('Payoff strike X2 must be numeric ')
  elseif X2 < 0
    error ('Payoff Strike X2 must be positive ')
  elseif S < 0
    error ('Price S must be positive ')    
  elseif ~isnumeric (T)
    error ('Time T in days must be numeric ')
  elseif ( T < 0)
    error ('Time T must be positive ')    
  elseif ~isnumeric (r)
    error ('Riskfree rate r must be numeric ')    
  elseif ~isnumeric (sigma)
    error ('Implicit volatility sigma must be numeric ')
  elseif ~isnumeric (divrate)
    error ('Dividend rate must be numeric ')     
  elseif ~( isempty(sigma(sigma< 0)))
    error ('Volatility sigma must be positive ')         
  end
  
  if ~(any(strcmpi(binary_type,{'gap','cash','asset','supershare'})))
    error('Option binary_type must be either gap, asset, cash or supershare')
  end
  
% b = r - divrate; % cost of carry according to Haug
T = T ./ 365;   % assuming act/365 day count convention (Option class converts)

value = 0.0;    % default value zero

% =====   Valuation of Gap binary options:
if (strcmpi(binary_type,{'gap'}))
    d1 = (log(S./X1) + (r - divrate + 0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
    d2 = d1 - sigma.*sqrt(T);
    if ( CallPutFlag == 1 ) % Call
        normcdf_d1 = 0.5.*(1+erf(d1./sqrt(2)));
        normcdf_d2 = 0.5.*(1+erf(d2./sqrt(2)));
        value = normcdf_d1.*S.*exp(divrate) - normcdf_d2.*X2.*exp(-r.*T);
    else   % Put   
        normcdf_minus_d1 = 0.5.*(1+erf(-d1./sqrt(2)));
        normcdf_minus_d2 = 0.5.*(1+erf(-d2./sqrt(2)));
        value = normcdf_minus_d2.*X2.*exp(-r.*T) - normcdf_minus_d1.*S.*exp(divrate);
    end

% =====   Valuation of Cash-or-Nothing binary options:  
elseif (strcmpi(binary_type,{'cash'}))
    d = (log(S./X1) + (r - divrate - 0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
    if ( CallPutFlag == 1 ) % Call
        N_d = 0.5.*(1+erf(d./sqrt(2)));
        value = N_d.*X2.*exp(-r.*T);
    else   % Put   
        N_d = 0.5.*(1+erf(-d./sqrt(2)));
        value = N_d.*X2.*exp(-r.*T);
    end
    
% =====   Valuation of Asset-or-Nothing binary options:
elseif (strcmpi(binary_type,{'asset'}))
    d = (log(S./X1) + (r - divrate + 0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
    if ( CallPutFlag == 1 ) % Call
        N_d = 0.5.*(1+erf(d./sqrt(2)));
        value = N_d.*S.*exp(-divrate.*T);
    else   % Put   
        N_d = 0.5.*(1+erf(-d./sqrt(2)));
        value = N_d.*S.*exp(-divrate.*T);
    end

% =====   Valuation of Supershare binary options:
elseif (strcmpi(binary_type,{'supershare'}))
    d1 = (log(S./X1) + (r - divrate + 0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
    d2 = (log(S./X2) + (r - divrate + 0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
    
    N_d1 = 0.5.*(1+erf(d1./sqrt(2)));
    N_d2 = 0.5.*(1+erf(d2./sqrt(2)));
    
    % not put or call options available, just one value:
    value = (S.*exp(-divrate.*T)./X1) .* (N_d1 - N_d2);

end

end

%!assert(option_binary(1,'gap',50,50,57,182.5,0.09,0.2,0.0),-0.0052525,sqrt(eps))
%!assert(option_binary(0,'gap',50,50,57,182.5,0.09,0.2,0.0),4.486603975,sqrt(eps))
%!assert(option_binary(0,'cash',100,80,10,9/12*365,0.06,0.35,0.06),2.67104568446135,sqrt(eps))
%!assert(option_binary(0,'asset',70,65,0,0.5*365,0.07,0.27,0.05),20.2069472983686,sqrt(eps))
%!assert(option_binary(0,'supershare',100,90,110,0.25*365,0.10,0.2,0.1),0.738940128705236,sqrt(eps))
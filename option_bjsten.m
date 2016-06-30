%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
%# Copyright (C) 2015 Tobias Setz <tobias.setz@rmetrics.org>
%# Copyright (C) 2015 Diethelm Wuertz
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
%# @deftypefn {Function File} {[@var{value}] =} option_bjsten (@var{CallPutFlag}, @var{S}, @var{X}, @var{T}, @var{r}, @var{sigma}, @var{divrate})
%# Calculate the option price of an American call or 
%# put option stocks, futures, and currencies. The 
%# approximation method by Bjerksund and Stensland is used. @*
%# 
%# The Octave implementation is based on a R function 
%# implemented by Diethelm Wuertz 
%# Rmetrics - Pricing and Evaluating Basic Options, Date 2015-11-09
%# Version 3022.85 @*
%#
%#  References:
%#    Haug E.G., The Complete Guide to Option Pricing Formulas
%# @*
%# Example taken from Reference:
%# @example
%# @group
%# price = option_bjsten(1,42,40,0.75*365,0.04,0.35,0.08)
%# price = 5.2704
%# @end group
%# @end example
%# Variables:
%# @itemize @bullet
%# @item @var{CallPutFlag}: Call: '1', Put: '0'
%# @item @var{S}: stock price at time 0
%# @item @var{X}: strike price 
%# @item @var{T}: time to maturity in days 
%# @item @var{r}: annual risk-free interest rate (continuously compounded)
%# @item @var{sigma}: implied volatility of the stock price measured as annual 
%# standard deviation
%# @item @var{divrate}: dividend rate p.a., continously compounded
%# @end itemize
%# @seealso{option_willowtree, option_bs}
%# @end deftypefn 
    
function [value] = option_bjsten(CallFlag, S, X, Time, r, sigma, divrate)

 if nargin < 6 || nargin > 7
    print_usage ();
  end
  if nargin == 6
    divrate = 0.00;
  end 
   
  if ~isnumeric (CallFlag)
    error ('CallPutFlag must be either 1 or 0 ')
  elseif ~isnumeric (S)
    error ('Underlying price S must be numeric ')
  elseif ~isnumeric (X)
    error ('Strike X must be numeric ')
  elseif X < 0
    error ('Strike X must be positive ')
  elseif S < 0
    error ('Price S must be positive ')    
  elseif ~isnumeric (Time)
    error ('Time T in days must be numeric ')
  elseif ( Time < 0)
    error ('Time T must be positive ')    
  elseif ~isnumeric (r)
    error ('Riskfree rate r must be numeric ')    
  elseif ~isnumeric (sigma)
    error ('Implicit volatility sigma must be numeric ')
  elseif ~isnumeric (divrate)
    error ('Dividend rate must be numeric ')     
  elseif ( sigma < 0)
    error ('Volatility sigma must be positive ')        
  end    
% Transformation
	Time = Time ./ 365;	% days to maturity
    b = r - divrate;    % b equals risk free rate minus dividend yield   
                                               
    % The Bjerksund and Stensland (1993) American approximation:
    if(CallFlag == 1) 
      value = BSAmericanCallApprox(S, X, Time, r, b, sigma);
    elseif(CallFlag == 0) 
      % Use the Bjerksund and Stensland put-call transformation
      value = BSAmericanCallApprox(X, S, Time, r - b, -b, sigma);
    end 
   
end

%-------------------------------------------------------------------------------
%                      Helper Functions
%-------------------------------------------------------------------------------

 % Call Approximation:
function result = BSAmericanCallApprox(S, X, Time, r, b, sigma) 
    
if(b >= r)  
    % Never optimal to exersice before maturity -> return BS price
    result = option_bs(1,S,X,Time,r,sigma,r+b);
else 
    Beta = (1/2 - b./sigma.^2) + sqrt((b./sigma.^2 - 1/2).^2 + 2.*r./sigma.^2);
    BInfinity = Beta./(Beta-1) .* X;
    B0 = max(X, r./(r-b) .* X);
    ht = -(b.*Time + 2.*sigma.*sqrt(Time)) .* B0./(BInfinity-B0);
    % Trigger Price I:
    I = B0 + (BInfinity-B0) .* (1 - exp(ht));
    alpha = (I-X) .* I.^(-Beta);
    if(S >= I)  
        result = S-X;
    else 
        result = alpha.*S.^Beta - alpha.* bsPhi(S,Time,Beta,I,I,r,b,sigma) + ...
				bsPhi(S,Time,1,I,I,r,b,sigma) ...
				- bsPhi(S,Time,1,X,I,r,b,sigma) ...
				- X.*bsPhi(S,Time,0,I,I,r,b,sigma) ...
				+ X.*bsPhi(S,Time,0,X,I,r,b,sigma); 
    end
end
    
end


% Utility function phi:   
function result = bsPhi(S, Time, gamma, H, I, r, b, sigma) 

    lambda = (-r + gamma.*b + 0.5.*gamma .* (gamma-1).*sigma.^2) .* Time;
    d1 = -(log(S./H) + (b+(gamma-0.5).*sigma.^2).*Time) ./ (sigma.*sqrt(Time));
    normcdf_d1 = 0.5.*(1+erf(d1./sqrt(2)));
    
    d2 = d1-2.*log(I./S) ./(sigma.*sqrt(Time));
    normcdf_d2 = 0.5.*(1+erf(d2./sqrt(2)));
    
    kappa = 2 .* b ./ (sigma.^2) + (2.*gamma - 1);
    
    result = exp(lambda).*S.^gamma .* (normcdf_d1-(I./S).^kappa.* normcdf_d2);

end

%!assert(option_bjsten(1,42,40,0.75*365,0.04,0.35,0.08),5.27040387879757,0.00000001);
%!assert(option_bjsten(0,286.867623322,368.7362,3650,0.0045624391,0.210360082233,0.00),122.290954391343,0.00000001); 
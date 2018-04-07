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
%# @deftypefn {Function File} {[@var{value}] =} option_lookback (@var{CallPutFlag}, @var{lookback_type}, @var{S}, @var{X1}, @var{X2}, @var{T}, @var{r}, @var{sigma}, @var{divrate})
%#
%# Compute the prices of European Lookback call or put options of type
%# floating strike or fixed strike.@*
%# @*
%# Floating Strike options:@*
%# A floating strike lookback call / put gives you the right to buy / sell the
%# the underlying security at the lowest / highest price observed during options
%# lifetime. Pricing according to Goldman, Sosin and Gatto (1979) ("Path dependent
%# options: Buy at the Low Sell at the High", Journal of Finance, 34(5), 1111-
%# 1127) valuation formulas.@*
%# @*
%# Fixed Strike options:@*
%# A fixed strike lookback call / put pays out the maximum of the difference 
%# between the highed observed price and the strike and 0 (call option) or the maximum
%# of the difference between strike and lowest observed price and 0 (put option).
%# Pricing according to Conze and Viswanathan (1991) ("Path dependent
%# options: The Case of Lookback Options", Journal of Finance, 36, 1893 - 1907)
%# formulas.
%# @*
%# @*
%# All formulas are taken from Haug, Complete Guide to Option Pricing Formulas,
%# 2nd edition, page 141ff.@*
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{CallPutFlag}: Call: '1', Put: '0'
%# @item @var{lookback_type}: can be 'floating_strike','fixed_strike'
%# @item @var{S}: stock price at time 0
%# @item @var{X1}: strike price (or S_min or S_max for fixed strike)
%# @item @var{X2}: payoff strike of fixed strike option
%# @item @var{T}: time to maturity in days 
%# @item @var{r}: annual risk-free interest rate (continuously compounded, act/365)
%# @item @var{sigma}: implied volatility of the stock price measured as annual 
%# standard deviation
%# @item @var{divrate}: dividend rate p.a., continously compounded
%# @end itemize
%# @seealso{option_binary, option_bs}
%# @end deftypefn

function value = option_lookback(CallPutFlag,lookback_type,S,X1,X2,T,r,sigma,divrate)
 
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
    error ('Strike or minumum/maximum price X1 must be numeric ')
  elseif X1 < 0
    error ('Strike or minumum/maximum priceX1 must be positive ')
  elseif ~isnumeric (X2)
    error ('Fixed Strike X2 must be numeric ')
  elseif X2 < 0
    error ('Fixed Strike X2 must be positive ')
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
  
  if ~(any(strcmpi(lookback_type,{'fixed_strike','floating_strike'})))
    error('Option lookback_type must be either fixed_strike, floating_strike.')
  end
  
b = r - divrate; % cost of carry according to Haug
T = T ./ 365;   % assuming act/365 day count convention (Option class converts)

value = 0.0;    % default value zero

% =====   Valuation of floating_strike lookback options:
if (strcmpi(lookback_type,{'floating_strike'}))
    X = X1; % X1 equals minimum or maximum underlying price
    d1 = (log(S./X) + (b + 0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
    d2 = d1 - sigma.*sqrt(T);
    N_d1 = 0.5.*(1+erf(d1./sqrt(2)));
    N_d2 = 0.5.*(1+erf(d2./sqrt(2)));
    N_minus_d1 = 0.5.*(1+erf(-d1./sqrt(2)));
    N_minus_d2 = 0.5.*(1+erf(-d2./sqrt(2)));
        
    if ( CallPutFlag == 1 ) % Call
        % b == 0    % formula 4.40 in Haug, 2nd Edition
        b_eq_0 = b == 0;
        value_b_eq_0 = S.*exp(-r.*T).*N_d1 - X.*exp(-r.*T).*N_d2 ...
                    + S.*exp(-r.*T).*sigma.*sqrt(T).*(normpdf(d1) + d1.*(N_d1-1));
        % b <> 0    % formula 4.39 in Haug, 2nd Edition
        value_b_ne_0 = S.*exp((b-r).*T).*N_d1 - X.*exp(-r.*T).*N_d2 ...
                    + S.*exp(-r.*T).* (sigma.^2 ./ (2.*b)) ...
                    .* ((S./X).^(-2.*b./sigma.^2)  ...
                    .* normcdf(-d1 + sqrt(T).*2.*b./sigma) - exp(b.*T) .* N_minus_d1);

        value = value_b_ne_0 .* ( 1 - b_eq_0)  + value_b_eq_0 .* b_eq_0;
    else   % Put   
        %b == 0 % formula 4.42 in Haug, 2nd Edition
        b_eq_0 = b == 0;
        value_b_eq_0 = X.*exp(-r.*T).*N_minus_d2 - S.*exp((b-r).*T).*N_minus_d1 ...
                    + S.*exp(-r.*T).*sigma.*sqrt(T).*(normpdf(d1) + d1.*N_d1);
        % b <> 0    % formula 4.41 in Haug, 2nd Edition
        value_b_ne_0 = X.*exp(-r.*T).*N_minus_d2 - S.*exp((b-r).*T).*N_minus_d1 ...
                    + S.*exp(-r.*T).* (sigma.^2 ./ (2.*b)) ...
                    .* (-(S./X).^(-2.*b./sigma.^2)  ...
                    .* normcdf(d1 - sqrt(T).*2.*b./sigma) + exp(b.*T) .* N_d1);
        value = value_b_ne_0 .* ( 1 - b_eq_0)  + value_b_eq_0 .* b_eq_0;
    end

% =====   Valuation of fixed_strike lookback options:   
elseif (strcmpi(lookback_type,{'fixed_strike'}))
    X = X2;     % fixed strike
    S_ext = X1; % maximum or minimum underlying price
    
    if ( CallPutFlag == 1 ) % Call
        % X <= S_ext    % formula 4.43 in Haug, 2nd Edition
            X_le_S_ext = X <= S_ext;
            d1 = (log(S./S_ext) + (b + 0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
            d2 = d1 - sigma.*sqrt(T);
            N_d1 = 0.5.*(1+erf(d1./sqrt(2)));
            N_d2 = 0.5.*(1+erf(d2./sqrt(2)));
            
            value_X_le_S_ext = (S_ext - X).*exp(-r.*T) + S.*exp((b-r).*T).*N_d1 ...
                    - S_ext.*exp(-r.*T).* N_d2...
                    + S.*exp(-r.*T).* (sigma.^2 ./ (2.*b)) ...
                    .* (-(S./S_ext).^(-2.*b./sigma.^2)  ...
                    .* normcdf(d1 - sqrt(T).*2.*b./sigma) + exp(b.*T) .* N_d1);         
        % X > S_ext
            X_gt_S_ext = X > S_ext;
            d1 = (log(S./X) + (b + 0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
            d2 = d1 - sigma.*sqrt(T);
            N_d1 = 0.5.*(1+erf(d1./sqrt(2)));
            N_d2 = 0.5.*(1+erf(d2./sqrt(2)));
            
            value_X_lt_S_ext = S.*exp((b-r).*T).*N_d1 - X.*exp(-r.*T).*N_d2 ...
                    + S.*exp(-r.*T).* (sigma.^2 ./ (2.*b)) ...
                    .* (-(S./X).^(-2.*b./sigma.^2)  ...
                    .* normcdf(d1 - sqrt(T).*2.*b./sigma) + exp(b.*T) .* N_d1); 
        % sum up both cases for each scenario
        value = value_X_le_S_ext .* X_le_S_ext + value_X_lt_S_ext .* X_gt_S_ext;
    
    else    % Put 
        % X < S_ext % formula 4.44 in Haug, 2nd Edition
            X_lt_S_ext = X < S_ext;
            d1 = (log(S./X) + (b + 0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
            d2 = d1 - sigma.*sqrt(T);
            N_minus_d1 = 0.5.*(1+erf(-d1./sqrt(2)));
            N_minus_d2 = 0.5.*(1+erf(-d2./sqrt(2)));
    
            value_X_lt_S_ext = X.*exp(-r.*T).*N_minus_d2 - S.*exp((b-r).*T).*N_minus_d1 ...
                    + S.*exp(-r.*T).* (sigma.^2 ./ (2.*b)) ...
                    .* ((S./X).^(-2.*b./sigma.^2)  ...
                    .* normcdf(-d1 + sqrt(T).*2.*b./sigma) - exp(b.*T) .* N_minus_d1);          
        % X >= S_ext
            X_ge_S_ext = X >= S_ext;
            d1 = (log(S./S_ext) + (b + 0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
            d2 = d1 - sigma.*sqrt(T);
            N_minus_d1 = 0.5.*(1+erf(-d1./sqrt(2)));
            N_minus_d2 = 0.5.*(1+erf(-d2./sqrt(2)));
            
            value_X_ge_S_ext = (X - S_ext).*exp(-r.*T) - S.*exp((b-r).*T).*N_minus_d1 ...
                    + S_ext .* exp(-r.*T).*N_minus_d2 ...
                    + S.*exp(-r.*T).* (sigma.^2 ./ (2.*b)) ...
                    .* ((S./S_ext).^(-2.*b./sigma.^2)  ...
                    .* normcdf(-d1 + sqrt(T).*2.*b./sigma) - exp(b.*T) .* N_minus_d1);  
        % sum up both cases for each scenario           
        value = value_X_ge_S_ext .* X_ge_S_ext + value_X_lt_S_ext .* X_lt_S_ext;
    end
end

end

% test cases taken from Haug, Complete Guide to Option Pricing Formulas, 2nd Edition
%!assert(option_lookback(1,'floating_strike',120,100,[],0.5*365,0.1,0.3,0.06),25.3533552718102,sqrt(eps))
%!assert(option_lookback(0,'floating_strike',120,100,[],0.5*365,0.1,0.3,0.06),25.8296927631406,sqrt(eps))
%!assert(option_lookback(0,'fixed_strike',100,100,[95;100;105;95;100;105;95;100;105],0.5*365,0.1,[0.1;0.1;0.1;0.2;0.2;0.2;0.3;0.3;0.3],0.0),[0.689932906632536;3.391664811220333;8.147811933723904;4.444777261815151;8.317720806810394;13.073867929313964;8.921301544387653;13.157879570425349;17.914026692928921],sqrt(eps))
%!assert(option_lookback(1,'fixed_strike',100,100,[95;100;105;95;100;105;95;100;105],0.5*365,0.1,[0.1;0.1;0.1;0.2;0.2;0.2;0.3;0.3;0.3],0.0),[13.26872236114894;8.51257523864536;4.39079352220685;18.92633698922830;14.17018986672472;9.89053230962382;24.98576014032539;20.22961301782182;15.85119902980109],sqrt(eps))

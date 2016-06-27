%# Copyright (C) 2015 Stefan Schloegl <schinzilord@octarisk.com>
%# Copyright (C) 2006 User vanna at http://www.quantcode.com 
%# although no explicit license statement is given, the following is given:
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
%# @deftypefn {Function File} {[@var{value}] =} option_bs_barrier (@var{CallPutFlag}, @var{UpFlag}, @var{S}, @var{X}, @var{H}, @var{T}, @var{r}, @var{sigma}, @var{q})
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

function [optionValue] = option_bs_barrier_haug(PutOrCall,UpOrDown,OutorIn,S0,X,H,T,r,sigma,q,Rebate)
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
    error ('barrier H must be numeric ')  
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


% ##########    in barrier options   ###############

% Down-and-in call S > H
if UpOrDown == 'D' && strcmp('in',OutorIn) && PutOrCall == 1
    % S0 >= H
        V_SgreqH = S0 >= H;
        eta = +1;
        phi = +1;
        A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1) - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
        B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2) - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
        D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        E = Rebate.*exp(-r.*T).*[ normcdf(eta.*x2-eta.*sigma.*sqrt(T)) - ((H./S0).^(2.*mu)).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)) ];
        %if X >= H
            V_XgreqH = X >= H;
            optionValue_XgreH = C + E;
        %else
            V_XsmqH = X < H;
            optionValue_XsmqH = A - B + D + E;
        %end
        optionValue_SgreqH = V_XgreqH .* optionValue_XgreH + V_XsmqH .* optionValue_XsmqH;
    % S0 < H
        V_SsmH = S0 < H;
        if T > 0
            optionValue_SsmH = max(S0 - X, 0);
        else
            optionValue_SsmH = Rebate;
        end
    % concatenating final vector
    optionValue = V_SsmH .* optionValue_SsmH + V_SgreqH .* optionValue_SgreqH;
    
end

% Up-and-in call
if UpOrDown == 'U' && strcmp('in',OutorIn) && PutOrCall == 1
    if S0 < H
        eta = -1;
        phi = +1;
        A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1) - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
        B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2) - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
        D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        E = Rebate.*exp(-r.*T).*[ normcdf(eta.*x2-eta.*sigma.*sqrt(T)) - ((H./S0).^(2.*mu)).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)) ];
        if X >= H
            optionValue = A + E;
        else
            optionValue = B - C + D + E;
        end
    else    % S0 >= H
        if T > 0
            optionValue = max(S0 - X, 0);
        else
            optionValue = Rebate;
        end
    end
end

% Down-and-in put
if UpOrDown == 'D' && strcmp('in',OutorIn) && PutOrCall == 0
    if S0 >= H
        eta = +1;
        phi = -1;
        A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1) - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
        B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2) - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
        D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        E = Rebate.*exp(-r.*T).*[ normcdf(eta.*x2-eta.*sigma.*sqrt(T)) - ((H./S0).^(2.*mu)).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)) ];
        if X >= H
            optionValue = B - C + D + E;
        else
            optionValue = A + E;
        end
    else    % S0 <= H
        if T > 0
            optionValue = max(X - S0, 0);
        else
            optionValue = Rebate;
        end
    end
end

% Up-and-in put
if UpOrDown == 'U' && strcmp('in',OutorIn) && PutOrCall == 0
    if S0 < H
        eta = -1;
        phi = -1;
        A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1) - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
        B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2) - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
        D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        E = Rebate.*exp(-r.*T).*[ normcdf(eta.*x2-eta.*sigma.*sqrt(T)) - ((H./S0).^(2.*mu)).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)) ];
        if X >= H
            optionValue = A - B + D + E;
        else
            optionValue = C + E;
        end
    else    % S0 >= H
        if T > 0
            optionValue = max(X - S0, 0);
        else
            optionValue = Rebate;
        end
    end
end

% ##########    out barrier options   ###############
% Down-and-out call
if UpOrDown == 'D' && strcmp('out',OutorIn) && PutOrCall == 1
    if S0 >= H
        eta = 1;
        phi = 1;
        A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1) - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
        B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2) - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
        D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        E = Rebate.*exp(-r.*T).*[ normcdf(eta.*x2-eta.*sigma.*sqrt(T)) - ((H./S0).^(2.*mu)).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)) ];
        F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
        if X >= H
            optionValue = A - C + F;
        else
            optionValue = B - D + F;
        end
    else    % S0 <= H
        if T > 0
            optionValue = max(S0 - X, 0);
        else
            optionValue = Rebate;
        end
    end
end

% Up-and-out call
if UpOrDown == 'U' && strcmp('out',OutorIn) && PutOrCall == 1
    if S0 < H
        eta = -1;
        phi = 1;
        A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1) - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
        B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2) - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
        D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
        if X >= H
            optionValue =  F;
            %disp("X >= 0, U out call")
        else
            optionValue = A - B + C - D + F;
            %disp("X < 0, U out call")
        end
    else    % S0 >= H
        if T > 0
            optionValue = max(S0 - X, 0);
            %disp("T > 0, S0 >= H, U out call")
        else
            optionValue = Rebate;
            %disp("T = 0, S0 >= H, U out call")
        end
    end
end

% Down-and-out put
if UpOrDown == 'D' && strcmp('out',OutorIn) && PutOrCall == 0
    if S0 >= H
        eta = 1;
        phi = -1;
        A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1) - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
        B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2) - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
        D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
        if X >= H
            optionValue =  A - B + C - D + F;
        else
            optionValue = F;
        end
    else    % S0 <= H
        if T > 0
            optionValue = max(X - S0, 0);
        else
            optionValue = Rebate;
        end
    end
end

% Up-and-out put
if UpOrDown == 'U' && strcmp('out',OutorIn) && PutOrCall == 0
    if S0 < H
        eta = -1;
        phi = -1;
        A = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x1) - phi.*X.*exp(-r.*T).*normcdf(phi.*x1-phi.*sigma.*sqrt(T));
        B = phi.*S0.*exp((b-r).*T).*normcdf(phi.*x2) - phi.*X.*exp(-r.*T).*normcdf(phi.*x2-phi.*sigma.*sqrt(T));
        D = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y2).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y2-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        C = phi.*S0.*exp((b-r).*T).*normcdf(eta.*y1).*((H./S0).^(2.*(mu+1))) - phi.*X.*exp(-r.*T).*normcdf(eta.*y1-eta.*sigma.*sqrt(T)).*((H./S0).^(2.*mu));
        F = Rebate.*[((H./S0).^(mu+lambda)).*normcdf(eta.*z)+((H./S0).^(mu-lambda)).*normcdf(eta.*z-2.*eta.*lambda.*sigma.*sqrt(T))];
        if X >= H
            optionValue =  B - D + F;
        else
            optionValue = A - C + F;
        end
    else    % S0 <= H
        if T > 0
            optionValue = max(X - S0, 0);
        else
            optionValue = Rebate;
        end
    end
end

end %end function

% Tests taken from Haug, Table 4-13 "Value of Standard Barrier Options", Page 154
% Tests down in call
%!assert(option_bs_barrier_haug(1,'D','in',100,90,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [7.762670;9.009344],0.000001)
%!assert(option_bs_barrier_haug(1,'D','in',100,100,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [4.010942;5.137039],0.000001)
%!assert(option_bs_barrier_haug(1,'D','in',100,110,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.057613;2.851683],0.000001)
%!assert(option_bs_barrier_haug(1,'D','in',100,90,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [13.833287;14.881621],0.000001)
%!assert(option_bs_barrier_haug(1,'D','in',100,100,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [7.849428;9.204497],0.000001)
%!assert(option_bs_barrier_haug(1,'D','in',100,110,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.979520;5.304301],0.000001)
% Tests up in call
%!assert(option_bs_barrier_haug(1,'U','in',100,90,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [14.111173;15.209846],0.000001)
%!assert(option_bs_barrier_haug(1,'U','in',100,100,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [8.448206;9.727822],0.000001)
%!assert(option_bs_barrier_haug(1,'U','in',100,110,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [4.590969;5.835036],0.000001)
% Tests down out call
%!assert(option_bs_barrier_haug(1,'D','out',100,90,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [9.024568;8.833358],0.000001)
%!assert(option_bs_barrier_haug(1,'D','out',100,100,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [6.792437;7.028540],0.000001)
%!assert(option_bs_barrier_haug(1,'D','out',100,110,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [4.875858;5.413700],0.000001)
%!assert(option_bs_barrier_haug(1,'D','out',100,90,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
%!assert(option_bs_barrier_haug(1,'D','out',100,100,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
%!assert(option_bs_barrier_haug(1,'D','out',100,110,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
% Tests up out call
%!assert(option_bs_barrier_haug(1,'U','out',100,90,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.678913;2.634042],0.000001)
%!assert(option_bs_barrier_haug(1,'U','out',100,100,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.358020;2.438942],0.000001)
%!assert(option_bs_barrier_haug(1,'U','out',100,110,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.345349;2.431533],0.000001)
% Test down out put
%!assert(option_bs_barrier_haug(0,'D','out',100,90,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.279838;2.416990],0.000001)
%!assert(option_bs_barrier_haug(0,'D','out',100,100,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.294750;2.425810],0.000001)
%!assert(option_bs_barrier_haug(0,'D','out',100,110,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.625214;2.624607],0.000001)
%!assert(option_bs_barrier_haug(0,'D','out',100,90,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
%!assert(option_bs_barrier_haug(0,'D','out',100,100,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
%!assert(option_bs_barrier_haug(0,'D','out',100,110,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
% Test up out put
%!assert(option_bs_barrier_haug(0,'U','out',100,90,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.775955;4.229237],0.000001)
%!assert(option_bs_barrier_haug(0,'U','out',100,100,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [5.493228;5.803252],0.000001)
%!assert(option_bs_barrier_haug(0,'U','out',100,110,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [7.518722;7.564957],0.000001)
% Test down in put
%!assert(option_bs_barrier_haug(0,'D','in',100,90,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.958582;3.876894],0.000001)
%!assert(option_bs_barrier_haug(0,'D','in',100,100,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [6.567705;7.798846],0.000001)
%!assert(option_bs_barrier_haug(0,'D','in',100,110,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [11.975228;13.307747],0.000001)
%!assert(option_bs_barrier_haug(0,'D','in',100,90,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.284469;3.332803],0.000001)
%!assert(option_bs_barrier_haug(0,'D','in',100,100,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [5.908504;7.263574],0.000001)
%!assert(option_bs_barrier_haug(0,'D','in',100,110,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [11.646491;12.971272],0.000001)
% Test up in put
%!assert(option_bs_barrier_haug(0,'U','in',100,90,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [1.465313;2.065833],0.000001)
%!assert(option_bs_barrier_haug(0,'U','in',100,100,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.372075;4.422589],0.000001)
%!assert(option_bs_barrier_haug(0,'U','in',100,110,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [7.084567;8.368582],0.000001)


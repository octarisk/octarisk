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
%# @deftypefn {Function File} {@var{value} =} option_willowtree (@var{CallPutFlag}, @var{AmericanFlag}, @var{S}, @var{X}, @var{T}, @var{r}, @var{sigma}, @var{dividend}, @var{dk})
%# @deftypefnx {Function File} {@var{value} =} option_willowtree (@var{CallPutFlag}, @var{AmericanFlag}, @var{S}, @var{X}, @var{T}, @var{r}, @var{sigma}, @var{dividend}, @var{dk}, @var{nodes})
%#
%# Computes the price of european or american equity options according to the willow tree model.@*
%# The willow tree approach provides a fast and accurate way of calculating option prices. Furthermore, massive parallelization due to litte memory consumption  is possible.
%# This implementation of the willow tree concept is based on following
%# literature:
%# @itemize @bullet
%# @item 'Willow Tree', Andy C.T. Ho, Master thesis, May 2000
%# @item 'Willow Power: Optimizing Derivative Pricing Trees', Michael Curran, ALGO RESEARCH QUARTERLY, Vol. 4, No. 4, December 2001
%# @end itemize
%#
%# Efficient parallel computation for column vectors of S,X,r and sigma is possible (advantage: linear increase of calculation time in timesteps and nodes).@*
%# Runtime of parallel computations incl. tree transition optimization (360 days maturity, 5 day stepsize, 20 willow tree nodes) are performed (at 46 GFlops machine, 4 Gb Ram) in:@*
%# 50      | 0.5s @*
%# 500      | 0.5s @*
%# 5000     | 1.1s @*
%# 50000    | 9.0s @*
%# 200000   | 32s @*
%#
%# Example of an American Call Option with continuous dividends:@*
%# (365 days to maturity, vector with different spot prices and volatilities, strike = 8, r = 0.06, dividend = 0.05, timestep 5 days, 20 nodes):
%# @code{option_willowtree(1,1,[7;8;9;7;8;9],8,365,0.06,[0.2;0.2;0.2;0.3;0.3;0.3],0.05,5,20)}
%#
%# Variables:
%# @itemize @bullet
%# @item @var{CallPutFlag}: Call: '1', Put: '0'
%# @item @var{AmericanFlag}: American option: '1', European Option: '0'
%# @item @var{S}: stock price at time 0
%# @item @var{X}: strike price 
%# @item @var{T}: time in days to maturity
%# @item @var{r}: annual risk-free interest rate (continuously compounded, act/365)
%# @item @var{sigma}: implied volatility of the stock price measured as annual standard deviation
%# @item @var{dividend}: continuous dividend yield, act/365
%# @item @var{dk}: size of timesteps for valuation points (optimal accuracy vs. runtime choice : 5 days timestep)
%# @item @var{nodes}: number of nodes for willow tree setup. Number of nodes must be in list [10,15,20,30,40,50]. These vectors are optimized by Currans suggested Method to fulfill variance constraint (optimal accuracy vs. runtime choice: 20 nodes)
%# @end itemize
%# @seealso{option_binomial, option_bs, option_exotic_mc}
%# @end deftypefn

function [option_willowtree delta] = option_willowtree(CallFlag,AmericanFlag,S0,K,T,rf,sigma,dividend,dk,nodes)

%-------------------------------------------------------------------------
%           Error Handling
%-------------------------------------------------------------------------
 if nargin < 9 || nargin > 10
    print_usage ();
  end


if ! isnumeric (CallFlag)
    error ('CallPutFlag must be either 1 or 0 ')
elseif ! isnumeric (AmericanFlag)
    error ('AmericanFlag must be either 1 or 0 ')    
elseif ! isnumeric (S0)
    error ('Underlying price S must be numeric ')
elseif ! isnumeric (K)
    error ('Strike K must be numeric ')
elseif K < 0
    error ('Strike K must be positive ')
elseif S0 < 0
    error ('Price S0 must be positive ')    
elseif ! isnumeric (T)
    error ('Time T in years must be numeric ')
elseif ( T < 0)
    error ('Time T must be positive ')    
elseif ! isnumeric (rf)
    error ('Riskfree rate rf must be numeric ')    
elseif ! isnumeric (sigma)
    error ('Implicit volatility sigma must be numeric ') 
elseif ( sigma < 0)
    error ('Volatility sigma must be positive ')
elseif ! isnumeric (dk)
    error ('stepsize in days (dk) must be numeric ') 
elseif ( dk < 0)
    error ('stepsize in days (dk)  must be positive ')     
end
 
 
% possible number of nodes:
nodes_possible = [10,15,20,30,40,50];
if nargin < 10
    z_method  = 20; %default 20 nodes
else
    if ! isnumeric (nodes)
        error ('Number of nodes must be numeric ')
    end
    z_method = nodes_possible(lookup(nodes_possible,nodes));
end 
 
%-------------------------------------------------------------------------
%           Setup of input parameters
%-------------------------------------------------------------------------

% For calculation of greeks add additional values to input vectors: (todo: adjust for different length of input vectors)
    % % % calculate change in S, r, sigma, T
    % length_input = length(S0);
    % S_greeks = cat(1,S0,S0 + 1);
    % S_greeks = cat(1,S_greeks,S0);
    % S_greeks = cat(1,S_greeks,S0);
    % S_greeks = cat(1,S_greeks,S0);
     
    % rf_greeks       = [rf;rf;rf + 0.01;rf;rf];
    % sigma_greeks    = [sigma;sigma;sigma;sigma + 0.1;sigma];
    % % %T_greeks        = [T;T;T;T;T-1];

    % S0 = S_greeks; 
    % %rf = rf_greeks;
    % sigma = sigma_greeks;
    % % %T = T_greeks
 
 
divyield = dividend;
if AmericanFlag==1,
    AmericanOptionFlag = 1; 
else
    AmericanOptionFlag = 0; 
end
        
if CallFlag==1,
	callputflag=1;
else
	callputflag=-1;
end
rf_input = rf;

% checking for consistency between S0 and K (either equal size, or S0 has fixed value while K is a vector)
if (rows(S0) < rows(K))
    if (rows(S0) > 1 )
        error ('Number of rows of spot (S0) and strike (K) does not match')
    else
        S0 = repmat(S0,rows(K),1);
    end
end

% applying multidimensionality (shifting all variables to 3rd dimension (1st (time) and 2nd (nodes) dimensions are used for building tree)
S0      = reshape(S0,1,1,rows(S0));
K       = reshape(K,1,1,rows(K));
T       = reshape(T,1,1,rows(T));
rf       = reshape(rf,1,1,rows(rf));
sigma   = reshape(sigma,1,1,rows(sigma));
T_years = T ./ 365;

% Vectors with z-values 
% solver optimization: (qi' * z_i^2) = 1 for n =10,15,20,30,40,50. Only z(1) and z(n) have been adjusted to fulfill variance = 1 condition.
z_10 = [
-1.818408193,-1.036433389,-0.67448975,-0.385320466,-0.125661347,0.125661347,0.385320466,0.67448975,1.036433389,1.818408193
];
z_15 = [
-2.019979732,-1.318010897,-1.009990169,-0.776421761,-0.579132162,-0.402250065,-0.237202109,-0.078412413,0.078412413 ...
,0.237202109,0.402250065,0.579132162,0.776421761,1.009990169,1.318010897,2.019979732
];
z_20 = [
-2.110897894,-1.439531471,-1.15034938,-0.934589291,-0.755415026,-0.597760126,-0.45376219,-0.318639364,-0.189118426 ...
,-0.062706778,0.062706778,0.189118426,0.318639364,0.45376219,0.597760126,0.755415026,0.934589291,1.15034938,1.439531471 ...
,2.110897894
];
z_30 = [
-2.269187459,-1.644853627,-1.382994127,-1.191816172,-1.036433389,-0.902734792,-0.783500375,-0.67448975, ...
-0.572967548,-0.477040428,-0.385320466,-0.296737838,-0.210428394,-0.125661347,-0.041789298,0.041789298, ...
0.125661347,0.210428394,0.296737838,0.385320466,0.477040428,0.572967548,0.67448975,0.783500375,0.902734792, ...
1.036433389,1.191816172,1.382994127,1.644853627,2.269187459
];
z_40 = [
-2.518840503,-1.780464342,-1.534120544,-1.356311745,-1.213339622,-1.091620367,-0.98423496,-0.887146559, ...
-0.797776846,-0.71436744,-0.635657014,-0.560703032,-0.488776411,-0.419295753,-0.351784345,-0.285840875, ...
-0.221118713,-0.157310685,-0.094137414,-0.031337982,0.031337982,0.094137414,0.157310685,0.221118713, ...
0.285840875,0.351784345,0.419295753,0.488776411,0.560703032,0.635657014,0.71436744,0.797776846, ...
0.887146559,0.98423496,1.091620367,0.98423496,1.213339622,1.356311745,1.780464342,2.518840503
];
z_50 = [
-2.510808322,-1.880793608,-1.644853627,-1.475791028,-1.340755034,-1.22652812,-1.126391129,-1.036433389, ...
-0.954165253,-0.877896295,-0.806421247,-0.738846849,-0.67448975,-0.612812991,-0.55338472,-0.495850347, ...
-0.439913166,-0.385320466,-0.331853346,-0.279319034,-0.227544977,-0.176374165,-0.125661347,-0.075269862, ...
-0.025068908,0.025068908,0.075269862,0.125661347,0.176374165,0.227544977,0.279319034,0.331853346,0.385320466, ...
0.439913166,0.495850347,0.55338472,0.612812991,0.67448975,0.738846849,0.806421247,0.738846849,0.877896295, ...
0.954165253,1.126391129,1.22652812,1.340755034,1.475791028,1.644853627,1.880793608,2.510808322
];
% getting desired z vector:
if ( z_method == 10)
    z = z_10';
elseif ( z_method == 15 )
    z = z_15';   
elseif ( z_method == 20 )
    z = z_20';
elseif ( z_method == 30 )
    z = z_30';   
elseif ( z_method == 40 )
    z = z_40';
elseif ( z_method == 50 )
    z = z_50';
else
    z = z_20'; %default 20 nodes
end

% Calculate equally distributed values for q
n = length(z);
q = ones(n,1) ./n; 
% for convenience, transpose vector
zi = z';
zj = z;

% Rounding Time according to timesteps dt and number of nodes
N = round(T/dk);
if ( N < 2 )    % in case of days to maturity <= dk -> adjust dk
    N = 2;
    dk = dk / 2;
end
T = dk * N;
dt=T/(N.*365);  % timestep between two valuation points in years


%-------------------------------------------------------------------------
%           Generation of the Willow Tree via Optimization
%-------------------------------------------------------------------------
% Iterating through the time nodes to optimize transition matrizes
for ii = 1 : 1 : (N-1) 
    %disp('Optimizing transition matrix per timestep:')
    %ii
    h = dk;             % constant time steps only
    tk = ii .* h;
    alpha = h / tk;
    beta = 1 ./sqrt(1+alpha);
    F = abs(zj - beta .* zi).^3;
    F = reshape(F,1,n^2);
    p = [1:n^2];
    u = ones(n,1);
    r = z.^2;

    % constraints:
        b = [];
        A = [];
        btmp = [];
        % 1) Pu = u -> unity vector
        B = zeros(n,n^2);
        for i = 1:1:n
            B(i,:) = [ zeros(1,(i-1)*n), ones(1,n) , zeros(1,n^2-i*n) ];
            btmp(i) = 1;
        end
        b = [b;btmp'];
        A = [A;B];

        % 2) Pz = bz 
        B = zeros(n,n^2);
        for i = 1:1:n
            B(i,:) = [ zeros(1,(i-1)*n), zi , zeros(1,n^2-i*n) ];
        end
        btmp = ones(n,1) .* beta .* zj; 
        b = [b;btmp];
        A = [A;B];

        % 3) Pr = b^2r + (1-b^2)u
        B = zeros(n,n^2);
        for i = 1:1:n
            B(i,:) = [ zeros(1,(i-1)*n), zi.^2 , zeros(1,n^2-i*n) ];
        end
        btmp = ones(n,1) .* ((beta^2 .* zj.^2) + (1 - beta.^2)) ;
        b = [b;btmp];
        A = [A;B];

        % 4) q'P = q'
        B = zeros(n,n^2);
        for i = 1:1:n
            B(i,:) = [ zeros(1,(i-1)*n), q' , zeros(1,n^2-i*n) ];
        end
        b = [b;q];
        A = [A;B];

    % Formulate Minimization Problem
    % min trace(PF)
        c = F;              % Cost coefficients
        A;              % Matrix of constraint coefficients
        b;                 % The right hand side of constraints
        lb = zeros(n^2,1);  % lower bound 
        ub = [];            % Upper bound 
        ctype = char(repmat(83,1,length(b)));   % char(83) = S: constraint type indicates equality 
        vartype = char(repmat(67,1,n^2));   % Variable type C (=char(67)) continuous variable
        s = 1;              % sense = 1: minimization problem (1)
        % linear programming parameters:
        param.msglev = 1;   % Level of messages output by solver. 3 is full output. Default is 1 (errors and warning only).
        param.itlim = 100000;   % Simplex iterations limit
        [xmin, fmin, errnum, extra] = glpk(c,A,b,lb,ub,ctype,vartype,s,param);  % final optimization
        Pmin = reshape(xmin,n,n);   % reshape output to have transition vectors for each node in one column
        Transition_matrix(:,:,ii) = Pmin'; % transpose and append, ready for vector multiplication 
end

%-------------------------------------------------------------------------
%           Discounting values through the Willow Tree
%-------------------------------------------------------------------------

% Setting tree at final timestep with underlying asset prices

% Assuming geometric brownian motion:
S_T = S0 .* (exp( (rf  - divyield - (sigma.^2 ./ 2)) .* T_years + sigma .* sqrt(T_years) .* z));

[a b c] = size(S0);
% getting payoff of option at time T
V_T = max(callputflag.*(S_T - K ),0);
% discounting iteratively
discount_factor = exp(-rf_input'.*dt);

% matrix rows(rf_input) x n is needed for discounting timestep values
discount_factor_mat = exp(-rf_input'.*dt);
discount_factor_mat = repmat(discount_factor_mat,n,1);
present_value = V_T;
% discounting from node k=T to k=1
%tic;

tmp_drift = rf  - divyield;

% %#%#%#%#%#  iterating through timesteps and discounting expected values  %#%#%#%#%#%#%#%#%#

for ii = (N-1) : -1 : 1  
    timestep_value  = (Transition_matrix(:,:,ii) * present_value) .* discount_factor_mat ;
    timestep_value  = reshape(timestep_value,n,1,c);
    % Assuming geometric brownian motion:
    S_act           = S0 .* exp( ((tmp_drift - (sigma.^2 ./ 2)) .* dt .* ii) + sigma .* sqrt(dt .* ii) .* z);
    immediate_val   = callputflag.*(S_act - K);
    present_value   = max(timestep_value,AmericanOptionFlag.*immediate_val) ;
    % Saving present values for greeks
    if ( ii == 2)
        V_t2 = present_value;
    elseif ( ii == 1)
        V_t1 = present_value;
    end
end

% discounting from node k=+1 to k=0 
immediate_val   = callputflag.*(S0 - K);
present_value   = q' * (present_value) .* discount_factor;
present_value   = reshape(present_value,1,1,c);
V_option        =  max(present_value,AmericanOptionFlag.*immediate_val) ;
V_option        = reshape(V_option,c,1,1);
%V_eur_option    = (q' * ( exp(-rf*T_years) .* V_T))';
%iterate_time = toc
%total_time = iterate_time + optim_time;
option_willowtree = V_option;

% Calculation of Greeks:
S_t0 = S0;
S_t1 = S0 .* exp( (tmp_drift - ((sigma).^2 ./ 2)) .* dt .* 1 + sigma .* sqrt(dt .* 1) .* z);
S_t2 = S0 .* exp( (tmp_drift - ((sigma).^2 ./ 2)) .* dt .* 2 + sigma .* sqrt(dt .* 2) .* z);
%disp('Value per t');
V_t0(1,1,:) = V_option;

% Calculating delta:
delta = callputflag .*( sum(abs(V_t1 - V_t0))) ./ ( sum(abs(S_t1 - S_t0)) );
delta = reshape(delta,c,1,1);
%delta = delta(1:length_input);
% Calculating gamma: not working reliably  -> wrong?
% gamma = (abs(mean(V_t2) - mean(V_t1) ) +  abs( mean(V_t1) - V_t0  ))./2;
% gamma = reshape(gamma,c,1,1);
% % Calculating Theta: averaging of change in option value at nodes at origin (n/2 and 1+n/2) -> wrong?
% theta1 = (V_t2(n/2,:,:) - V_t1(n/2,:,:)) ./ dt;
% theta2 = (V_t2(1+n/2,:,:) - V_t1(1+n/2,:,:)) ./ dt;
% theta = 0.5 .*(theta1 + theta2);
% theta = reshape(theta,c,1,1);

% reshape for greeks
% V_matrix = reshape(V_option,length_input,5);
% V_base = V_matrix(:,1);
% V_delta = V_matrix(:,2);
% V_rho = V_matrix(:,3);
% V_sigma = V_matrix(:,4);
% %V_tau = V_matrix(:,5);

% delta   = callputflag .* abs(V_delta - V_base);
% rho     = V_rho - V_base;
% vega    = (V_sigma - V_base ) ./ 10;
% %theta   = V_tau - V_base
% option_willowtree = V_base;
end
  
% !assert(option_willowtree(1,1,9,10,365,0.06,0.3,0.05,5,20),0.69927,0.01)

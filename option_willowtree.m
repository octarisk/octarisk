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
%# @deftypefnx {Function File} {@var{value} =} option_willowtree (@var{CallPutFlag}, @var{AmericanFlag}, @var{S}, @var{X}, @var{T}, @var{r}, @var{sigma}, @var{dividend}, @var{dk}, @var{nodes}, @var{path_static})
%#
%# Computes the price of european or american equity options according to the 
%# willow tree model.@*
%# The willow tree approach provides a fast and accurate way of calculating 
%# option prices. 
%# This implementation of the willow tree concept is based on following
%# literature:
%# @itemize @bullet
%# @item 'Willow Tree', Andy C.T. Ho, Master thesis, May 2000
%# @item 'Willow Power: Optimizing Derivative Pricing Trees', Michael Curran, 
%# ALGO RESEARCH QUARTERLY, Vol. 4, No. 4, December 2001
%# @end itemize
%#
%# Example of an American Call Option with continuous dividends:@*
%# (365 days to maturity, vector with different spot prices and volatilities, 
%# strike = 8, r = 0.06, dividend = 0.05, timestep 5 days, 20 nodes):
%# @code{option_willowtree(1,1,[7;8;9;7;8;9],8,365,0.06,[0.2;0.2;0.2;0.3;0.3;0.3],0.05,5,20)}
%#
%# Variables:
%# @itemize @bullet
%# @item @var{CallPutFlag}: Call: '1', Put: '0'
%# @item @var{AmericanFlag}: American option: '1', European Option: '0'
%# @item @var{S}: stock price at time 0
%# @item @var{X}: strike price 
%# @item @var{T}: time in days to maturity
%# @item @var{r}: annual risk-free interest rate (cont, act/365)
%# @item @var{sigma}: implied volatility of the stock price
%# @item @var{dividend}: continuous dividend yield, act/365
%# @item @var{dk}: size of timesteps for valuation points (default: 5 days)
%# @item @var{nodes}: number of nodes for willow tree setup. 
%# Number of nodes must be in list [10,15,20,30,40,50]. These vectors are 
%# optimized by Currans Method to fulfill variance constraint (default: 20)
%# @end itemize
%# @seealso{option_binomial, option_bs, option_exotic_mc}
%# @end deftypefn

function [option_willowtree V_eur_option] = option_willowtree(CallFlag,AmericanFlag,S0,K,T,rf,sigma,dividend,dk,nodes,path_static)

%-------------------------------------------------------------------------
%           Error Handling
%-------------------------------------------------------------------------
 if nargin < 9 || nargin > 11
    print_usage ();
 end


if ~isnumeric (CallFlag)
    error ('CallPutFlag must be either 1 or 0 ')
elseif ~isnumeric (AmericanFlag)
    error ('AmericanFlag must be either 1 or 0 ')    
elseif ~isnumeric (S0)
    error ('Underlying price S must be numeric ')
elseif ~isnumeric (K)
    error ('Strike K must be numeric ')
elseif K < 0
    error ('Strike K must be positive ')
elseif S0 < 0
    error ('Price S0 must be positive ')    
elseif ~isnumeric (T)
    error ('Time T in years must be numeric ')
elseif ( T < 0)
    error ('Time T must be positive ')    
elseif ~isnumeric (rf)
    error ('Riskfree rate rf must be numeric ')    
elseif ~isnumeric (sigma)
    error ('Implicit volatility sigma must be numeric ') 
elseif ~( isempty(sigma(sigma< 0)))
    error ('Volatility sigma must be positive ')        
elseif ~isnumeric (dk)
    error ('stepsize in days (dk) must be numeric ') 
elseif ( dk < 0)
    error ('stepsize in days (dk)  must be positive ')     
end
 
% possible number of nodes:
nodes_possible = [10,15,20,30,40,50];
if nargin < 10
    z_method  = 20; %default 20 nodes
else
    if ~isnumeric (nodes)
        error ('Number of nodes must be numeric ')
    end
    z_method = nodes_possible(lookup(nodes_possible,nodes));
end 
% set load and save path for optimized willowtree
willowtree_save_flag = 1;
if (nargin < 11 || strcmp(path_static,'') )
   path_static = pwd;
   willowtree_save_flag = 0;   
end

%-------------------------------------------------------------------------
%           Setup of input parameters
%-------------------------------------------------------------------------

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

% checking for consistency between S0 and K (either equal size, or S0 has fixed 
% value while K is a vector)
if (rows(S0) < rows(K))
    if (rows(S0) > 1 )
        error ('Number of rows of spot (S0) and strike (K) does not match')
    else
        S0 = repmat(S0,rows(K),1);
    end
end

% applying multidimensionality (shifting all variables to 3rd dimension 
% (1st (time) and 2nd (nodes) dimensions are used for building tree)
S0      = reshape(S0,1,1,rows(S0));
K       = reshape(K,1,1,rows(K));
T       = reshape(T,1,1,rows(T));
rf      = reshape(rf,1,1,rows(rf));
sigma   = reshape(sigma,1,1,rows(sigma));
divyield   = reshape(divyield,1,1,rows(divyield));
T_years = T ./ 365;

% Rounding Time according to timesteps dt and number of nodes
N = round(T/dk); % total number of timesteps
if ( N < 2 )     % in case of days to maturity <= dk -> adjust dk
    N = 2;
    dk = dk / 2;
end
T   = dk * N;
dt  = T / (N.*365);  % timestep between two valuation points in years

% generate Willowtree according to timesteps and number of nodes
[Transition_matrix z] = generate_willowtree(N,dk,z_method,willowtree_save_flag,path_static);
n = length(z);
q = ones(n,1) ./n;

%-------------------------------------------------------------------------
%           Discounting values through the Willow Tree
%-------------------------------------------------------------------------

% Setting tree at final timestep with underlying asset prices

% Assuming geometric brownian motion:

S_T = S0 .* (exp( (rf  - divyield - (sigma.^2 ./ 2)) .* T_years + ...
        sigma .* sqrt(T_years) .* z));

[a b c] = size(S0);
% getting payoff of option at time T
V_T = max(callputflag.*(S_T - K ),0);
% discounting iteratively
discount_factor = exp(-rf_input'.*dt);

% matrix rows(rf_input) x n is needed for discounting timestep values
discount_factor_mat = exp(-rf_input'.*dt);
discount_factor_mat = repmat(discount_factor_mat,n,1);
present_value = V_T;


tmp_drift = rf  - divyield;

% ######## iterating through timesteps and discounting expected values  ########
for ii = (N-1) : -1 : 1  
    timestep_value  = (Transition_matrix(:,:,ii) * present_value) .* ...
                                        discount_factor_mat ;
    timestep_value  = reshape(timestep_value,n,1,c);
    % Assuming geometric brownian motion:
    S_act       = S0 .* exp( ((tmp_drift - (sigma.^2 ./ 2)) .* dt .* ii) + ...
                            sigma .* sqrt(dt .* ii) .* z);
    immediate_val   = callputflag.*(S_act - K);
    present_value   = max(timestep_value,AmericanOptionFlag.*immediate_val) ;
end

immediate_val   = callputflag.*(S0 - K);
present_value   = q' * (present_value) .* discount_factor;
present_value   = reshape(present_value,1,1,c);
V_option        =  max(present_value,AmericanOptionFlag.*immediate_val) ;
V_option        = reshape(V_option,c,1,1);
V_eur_option    = (q' * ( exp(-rf*T_years) .* V_T))';

option_willowtree = V_option;

end
  
  
%!assert(option_willowtree(1,1,[7;8;9;7;8;9],8,365,0.06,[0.2;0.2;0.2;0.3;0.3;0.3],0.05,5,20),[0.2329429;0.6444019;1.2907739;0.4810619;0.9480669;1.5731179 ],0.00001)
%!assert(option_willowtree(0,0,[7;8;9;7;8;9],10,90,0.06,[0.2;0.2;0.2;0.3;0.3;0.3],0.05,1,30),[2.9389219;1.9511749;1.0359799;2.9389429;1.9929989;1.1649079],0.00001)
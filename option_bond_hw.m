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
%# @deftypefn {Function File} {[@var{value}] =} option_bond_hw (@var{CallPutFlag}, @var{S}, @var{X}, @var{T}, @var{r}, @var{sigma}, @var{divrate})
%#
%# Compute the value of a put or call bond option using Hull-White Tree model.
%# 
%# This script is a wrapper for the function pricing_callable_bond_cpp
%# and handles all input and ouput data.
%# References:
%# @itemize @bullet
%# @item Hull, Options, Futures and other derivatives, 6th Edition
%# @end itemize
%# 
%# @seealso{pricing_callable_bond_cpp}
%# @end deftypefn

function [value] = option_bond_hw()
 
% if nargin < 6 || nargin > 7
    % print_usage ();
% end

  
% +++++++++++++++++++++ Set input data +++++++++++++++++++++

% Yearly zero coupon rates and tenors
Rates = [-0.005,-0.004,-0.01,0.0001,0.0001,0.0003,0.00138,0.00248488,0.0035760,0.0045624,0.00545];

Tenors = [1,2,3,4,5,6,7,8,9,10,11];

% Rates = [0.0343,0.03824,0.04183,0.04512,0.04812,0.05086];

% Tenors = [0.56,1,1.5,2,2.5,3];
nodes = Tenors .* 365;

% Specify callable bond
notional = 100;

cf_dates = [314,679,1044,1409,1775,2140,2505,2870,3236,3601]
cf_vals = [1.29041,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,101.5]


% Hull White tree parameters
alpha = 0.1
sigma = 0.01

% Strike price for puts on the discount bond
K = 1 * notional;

% days to maturity of callable feature
days_to_mat = 1044
% get index of nearest neighbour of call maturity and cash flow dates
Mat = interp1(cf_dates,[1:length(cf_dates)],days_to_mat,'nearest')
if (isnan(Mat))
    Mat = length(cf_dates);
end

% +++++++++++++++++++++ Derive values from input data +++++++++++++++++++++

% Maturity (T) number of time steps (N) and time increment (dt)
T = cf_dates(end)/365
% TODO: according to cash flow pattern and call rates, dt has to be calculated

timeincrements = diff(cf_dates);
N = length(cf_dates);

% one more timestep required for tree
dt = [cf_dates(1),timeincrements,timeincrements(end)]./365
Timevec = [cf_dates,cf_dates(end) + timeincrements(end)] ./ 365

% interpolate interest rates based on discount curve and for nodes of bond
tmp_t = 0;
for ii = 1 : 1 : length(dt)
    tmp_t = tmp_t + dt(ii) * 365;
    R_matrix(:,ii) = interpolate_curve(nodes,Rates,tmp_t);
end

% Start Calculation in C++
tic;
disp("C++")  
[EUPut EUCall AMPut AMCall cppB] = pricing_callable_bond_cpp(T,N,alpha,sigma,cf_dates,cf_vals,R_matrix,dt,Timevec,notional,Mat,K);

cppB
EUPut
EUCall
AMPut
AMCall

cpptime = toc

% return values

end

%!assert(option_bs(0,[10000;9000;11000],11000,365,0.01,[0.2;0.025;0.03]),[1351.5596289;1890.5481719;83.4751769],0.000002)
%!assert(option_bs(1,[10000;9000;11000],11000,365,0.01,[0.2;0.025;0.03]),[461.0114579;3.0875e-013;192.9270059],0.000002)

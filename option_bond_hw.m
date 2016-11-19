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
%# @deftypefn {Function File} {[@var{value}] =} option_bond_hw (@var{value_type},@var{bond},@var{curve},@var{callschedule},@var{putschedule})
%#
%# Compute the value of a put or call bond option using Hull-White Tree model.
%# 
%# This script is a wrapper for the function pricing_callable_bond_cpp
%# and handles all input and ouput data. Input data: value type,
%# bond instrument, curve instrument, call and put schedule.
%# References:
%# @itemize @bullet
%# @item Hull, Options, Futures and other derivatives, 7th Edition
%# @end itemize
%# 
%# @seealso{pricing_callable_bond_cpp}
%# @end deftypefn

function [OptionValue] = option_bond_hw(value_type,bond,curve,callschedule,putschedule)
 
 if nargin < 5 || nargin > 5
     print_usage ();
 end

  
% +++++++++++++++++++++ Set input data +++++++++++++++++++++

% Example from Hull Option Futures and other derivatives
% Yearly zero coupon rates and tenors
% Specify callable bond
notional = bond.notional;
cf_dates = bond.cf_dates;
cf_values = bond.getCF(value_type);

% ------------------------------------------------------------------------------
% A) specify in put parameters 
% Hull White tree parameters
alpha = bond.alpha;
sigma = bond.sigma;

% Strike price for puts on the discount bond

% get call or put schedule
% call date
% days to maturity of callable feature
call_dates = callschedule.get('nodes');
call_strike = callschedule.getValue(value_type);
put_dates = putschedule.get('nodes');
put_strike = putschedule.getValue(value_type);

% ------------------------------------------------------------------------------
% B) Map cash flow and call/put dates to tree dates 
last_cf_date = cf_dates(end);

% rollout all cash flows:
N = round(bond.treenodes);
stepsize = max(round(last_cf_date / N),1);
tree_dates = [0:stepsize:last_cf_date];

% append final cf date
if (cf_dates(end) > tree_dates(end))
    tree_dates = [tree_dates,cf_dates(end)]; % first case: append final cf date
elseif (cf_dates(end) < tree_dates(end))
    tree_dates = tree_dates(1:end-1);   % remove last tree date
    if ( sum(tree_dates==cf_dates(end) ) == 0)  % append final cf date to tree dates
        tree_dates = [tree_dates,cf_dates(end)];
    end
end % else: final tree_date equal to cf_date -> do nothing

% insert all other cash flow dates to tree
for (jj = 1:1:length(cf_dates)-1)
    if ( sum(tree_dates==cf_dates(jj) ) == 0)  % insert days to maturity inside tree
        tree_dates = sort([tree_dates,cf_dates(jj)]);
    end
end

% map call dates to tree
for jj = 1:1:length(call_dates)
    if ( sum(tree_dates==call_dates(jj) ) == 0)  % insert days to maturity inside tree
        tree_dates = sort([tree_dates,call_dates]);
    end
end
% map put dates to tree
for jj = 1:1:length(put_dates)
    if ( sum(tree_dates==put_dates(jj) ) == 0)  % insert days to maturity inside tree
        tree_dates = sort([tree_dates,put_dates]);
    end
end

tree_cf = zeros(rows(cf_values),columns(tree_dates));
% map all bond cash flows to nearest tree date:
for kk = 1 : 1 : length(cf_dates)
    idx = interp1(tree_dates,[1:length(tree_dates)],cf_dates(kk),'nearest');
    tree_cf(:,idx) = cf_values(:,kk);
end
% ------------------------------------------------------------------------------


% ------------------------------------------------------------------------------
% C)  Derive tree values from input data 

% Maturity (T) number of time steps (N) and time increment (dt)
T = tree_dates(end)/365;
% TODO: according to cash flow pattern and call rates, dt has to be calculated

timeincrements = diff(tree_dates);
N = length(tree_dates);

% one more timestep required for tree
dt = [tree_dates(1),timeincrements,timeincrements(end)]./365;
Timevec = [tree_dates,tree_dates(end) + timeincrements(end)] ./ 365;

% interpolate interest rates based on discount curve and for nodes of bond
tmp_t = 0;
for ii = 1 : 1 : length(dt)
    tmp_t = tmp_t + dt(ii) * 365;
    R_matrix(:,ii) = curve.getRate(value_type,tmp_t);
end

% expand cash flow vector and sigma to math R_matrix scenario row size
if ( rows(R_matrix) > 1 )
    if ( rows(tree_cf) == 1)
        tree_cf = repmat(tree_cf,rows(R_matrix),1);
    end
    if ( rows(sigma) == 1)
        sigma = repmat(sigma,rows(R_matrix),1);
    end
end
% ------------------------------------------------------------------------------

% D) Calculate call value for all call/put dates
% tic;
% disp("C++")
OptionValueCall = 0.0;
OptionValuePut = 0.0;
if ( length(call_dates) > 0 )   % only if call schedule has some dates
    for mm = 1 : 1 : length(call_dates)
        % get index of nearest neighbour of call maturity and cash flow dates
        Mat = interp1(tree_dates,[1:length(tree_dates)],call_dates(mm),'nearest'); 
        if (isnan(Mat))
            Mat = length(tree_dates);
        end
        % calculate strike value
        K = call_strike(mm) * notional;
        american_flag = callschedule.american_flag;
        
        % Call pricing funciton C++ 
        [Put Call] = pricing_callable_bond_cpp(T,N,alpha,sigma,tree_dates, ...
                    tree_cf,R_matrix,dt,Timevec,notional,Mat,K,american_flag);
        OptionValueCall += Call;
    end
end        
if ( length(put_dates) > 0 )   % only if put schedule has some dates
    for mm = 1 : 1 : length(put_dates)
        % get index of nearest neighbour of call maturity and cash flow dates
        Mat = interp1(tree_dates,[1:length(tree_dates)],put_dates(mm),'nearest'); 
        if (isnan(Mat))
            Mat = length(tree_dates);
        end
        % calculate strike value
        K = put_strike(mm) * notional;
        american_flag = putschedule.american_flag;
        
        % Call pricing funciton C++ 
        [Put Call cppB pu pm pd r Q] = pricing_callable_bond_cpp(T,N,alpha,sigma,tree_dates, ...
                    tree_cf,R_matrix,dt,Timevec,notional,Mat,K,american_flag);
        BondBaseValue = cppB(round(rows(cppB)/2),1);
        OptionValuePut += Put;
    end
end        
% cpptime = toc;
% return values: Putvalue is valuable to bond holder, call value reduces price
OptionValue = OptionValuePut - OptionValueCall;

end


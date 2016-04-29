%# Copyright (C) 2015 Schinzilord <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{theo_value} ] =} pricing_forward_oop (@var{forward}, @var{discount_nodes}, @var{discount_rates})
%#
%# Compute the theoretical value of equity and bond forwards.@*
%# In the 'oop' version no input data checks are performed. @* 
%# Pre-requirements:@*
%# @itemize @bullet
%# @item installed octave financial package
%# @item custom functions timefactor, discount_factor, interpolate_curve
%# @end itemize
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{forward}: Structure with relevant information for specification of the object forward:@*
%#      @itemize @bullet
%#      @item forward.type                   Equity, Bond
%#      @item forward.currency               [optional] Currency (string, ISO code)
%#      @item forward.maturity_date          Maturity date of forward
%#      @item forward.valuation_date         [optional] Valuation date (default today)
%#      @item forward.strike_price           strike price (float).  Can be a 1xN vector.
%#      @item forward.underlying_price       market price of underlying (float), in forward currency units. Can be a 1xN vector.
%#      @item forward.storage_cost           [optional] continuous storage cost p.a. (default 0)
%#      @item forward.convenience_yield      [optional] continuous convenience yield p.a. (default 0)
%#      @item forward.dividend_yield         [optional] continuous dividend yield p.a. (default 0)
%#      @item forward.compounding_type       [optional] compounding type [simple, discrete, continuous] (default 'disc')
%#      @item forward.compounding_frequency  [optional] compounding frequency [daily, weekly, monthly, semi-annual, annual] (default 'daily')
%#      @item forward.day_count_convention   [optional] day count convenction (e.g. 'act/act' or '30/360E') (default 'act/act')
%#      @end itemize
%# @item @var{discount_nodes}: tmp_nodes is a 1xN vector with all timesteps of the given curve
%# @item @var{discount_rates}: tmp_rates is a MxN matrix with discount curve rates defined in columns. Each row contains a specific scenario with different curve structure
%# @item @var{theo_value}: returs a 1xN vector with all forward values per scenario
%# @end itemize
%# @seealso{timefactor, discount_factor, interpolate_curve}
%# @end deftypefn

function [theo_value] = pricing_forward_oop(forward,discount_nodes,discount_rates,underlying_price)

if nargin < 4 || nargin > 4
    print_usage ();
 end

 % Getting basis properties
    comp_type = forward.compounding_type;
    comp_freq = forward.compounding_freq;
    basis = forward.basis;
    valuation_date = forward.valuation_date;
    currency = forward.currency;


% --- Mapping mandatory structure field items --- 
    type = forward.sub_type;
    storage_cost = forward.storage_cost; % continuous storage cost p.a.
    convenience_yield = forward.convenience_yield; % continuous convenience_yield p.a.
    dividend_yield = forward.dividend_yield;
    maturity_date = datenum(forward.maturity_date);
    strike = forward.strike_price;

    % convert valuation_date
if (ischar(valuation_date))
    valuation_date = datenum(valuation_date);
endif
days_to_maturity    = maturity_date - valuation_date; 
if ( days_to_maturity < 1)
    disp('Maturity Date is equal or before valuation date. Return value 0.')
    theo_value = zeros(length(underlying_price),1);
    return
end
if ( rows(discount_rates) > 1 && rows(underlying_price) > 1 && (rows(underlying_price) ~= rows(discount_rates)))
    error('Rows of underlying price not equal to 1 or to number of rows of discount_rats. Aborting.')  
end


% Get discount curve and calculate cost of carry
discount_rate       = interpolate_curve(discount_nodes,discount_rates,days_to_maturity);
cost_of_carry       = discount_rate - forward.dividend_yield + forward.storage_cost - forward.convenience_yield;

% Calculate forward value for equity and bond forwards
if ( strcmp(type,'Equity') == 1 || strcmp(type,'EQFWD') == 1)
    df_forward      = discount_factor (valuation_date, maturity_date, cost_of_carry, comp_type, basis, comp_freq);
    df_discount     = discount_factor (valuation_date, maturity_date, discount_rate, comp_type, basis, comp_freq);
    forward_price   = underlying_price ./ df_forward;
    payoff          = (forward_price - strike ) .* df_discount;
elseif ( strcmp(type,'Bond') == 1 || strcmp(type,'BONDFWD') == 1)
    df_discount     = discount_factor (forward.valuation_date, forward.maturity_date, discount_rate, comp_type, basis, comp_freq);
    payoff          = underlying_price - (strike .* df_discount);
else
    error('Not a valid type.')
end

theo_value = payoff;


end

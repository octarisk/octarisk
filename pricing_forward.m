%# Copyright (C) 2015 Schinzilord <schinzilord@octarisk.com>
%# Copyright (C) 2016 IRRer-Zins <IRRer-Zins@t-online.de>
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
%# @deftypefn {Function File} {[@var{theo_value} ] =} pricing_forward (@var{valuation_date}, @var{forward}, @var{discount_curve_object}, @var{underlying_object}, @var{und_curve_object},@var{fx})
%#
%# Compute the theoretical value and price of FX, equity and bond forwards and 
%# futures.@*
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{valuation_date}: valuation date
%# @item @var{forward}: forward object
%# @item @var{discount_curve_object}: discount curve for forward
%# @item @var{underlying_object}: underlying object of forward
%# @item @var{und_curve_object}: discount curve object of underlying object
%# @item @var{fx}: fx object with currency conversion rate between forward and underlying currency
%# @end itemize
%# @seealso{timefactor, discount_factor, convert_curve_rates}
%# @end deftypefn

function [theo_value theo_price] = pricing_forward(valuation_date,value_type, forward, ...
    discount_curve_object, underlying_object, und_curve_object, fx )

if nargin < 5 || nargin > 7
    print_usage ();
end

% Getting instrument properties
comp_type = forward.compounding_type;
comp_freq = forward.compounding_freq;
basis = forward.basis;
currency = forward.currency;
type = forward.sub_type;
storage_cost = forward.storage_cost; % continuous storage cost p.a.
convenience_yield = forward.convenience_yield; % continuous convenience_yield p.a.
dividend_yield = forward.dividend_yield;
maturity_date = datenum(forward.maturity_date,1);
strike = forward.strike_price;

% Getting curve properties
% Get Discount Curve nodes and rate and related attributes
discount_nodes  = discount_curve_object.nodes;
discount_rates  = discount_curve_object.getValue(value_type);
interp_discount = discount_curve_object.method_interpolation;
curve_basis     = discount_curve_object.basis;
curve_comp_type = discount_curve_object.compounding_type;
curve_comp_freq = discount_curve_object.compounding_freq;

% Getting underlying properties
% distinguish between index or RF underlyings for EQ and Bond Forwards
if ( sum(strcmpi(type,{'Equity','EQFWD','BondFuture','EquityFuture'})) > 0 )
    if ( strfind(underlying_object.id,'RF_') )   % underlying instrument is a risk factor
        tmp_underlying_sensitivity = forward.underlying_sensitivity;
        tmp_underlying_delta = underlying_object.getValue(value_type);
        underlying_price = Riskfactor.get_abs_values(underlying_object.model, ...
            tmp_underlying_delta, forward.underlying_price_base, ...
            tmp_underlying_sensitivity);
    else    % underlying is a index
        underlying_price = underlying_object.getValue(value_type);
    end
    
elseif ( sum(strcmpi(type,{'FX'})) > 0 )
    if nargin < 5
        error('pricing_forward: No foreign curve object provided.');
    end
    % getting underlying curve properties
    foreign_nodes           = und_curve_object.nodes;
    foreign_rates           = und_curve_object.getValue(value_type);
    interp_foreign          = und_curve_object.method_interpolation;
    curve_basis_foreign     = und_curve_object.basis;
    curve_comp_type_foreign = und_curve_object.compounding_type;
    curve_comp_freq_foreign = und_curve_object.compounding_freq;
    % Getting underlying currency properties
    underlying_price = underlying_object.getValue(value_type);
    
elseif ( sum(strcmpi(type,{'FX','Bond','BONDFWD'})) > 0 )
    if nargin < 5
        error('pricing_forward: No foreign curve object provided.');
    end
    % getting underlying curve properties
    und_nodes           = und_curve_object.nodes;
    und_rates           = und_curve_object.getValue(value_type);
    interp_und          = und_curve_object.method_interpolation;
    curve_basis_und     = und_curve_object.basis;
    curve_comp_type_und = und_curve_object.compounding_type;
    curve_comp_freq_und = und_curve_object.compounding_freq;
    % Getting underlying currency properties
    underlying_price = underlying_object.getValue(value_type);

end

% convert valuation_date
if (ischar(valuation_date))
    valuation_date = datenum(valuation_date,1);
end
days_to_maturity    = maturity_date - valuation_date;
if ( days_to_maturity < 1)
    disp('Maturity Date is equal or before valuation date. Return value 0.')
    theo_value = zeros(length(underlying_price),1);
    return
end
if ( rows(discount_rates) > 1 && rows(underlying_price) > 1 ...
        && (rows(underlying_price) ~= rows(discount_rates)))
    error('Rows of underlying price not equal to 1 or to number of rows of discount_rats. Aborting.')
end

% convert underlying value into forward currency
if ( ~strcmpi(forward.currency,underlying_object.currency))
   %Conversion of currency:
    fx_id = strcat('FX_', forward.currency, underlying_object.currency);
    % distinguish between FX object / struct
    if ( isobject(fx))
        if ( ~strcmpi(fx_id,fx.id))
            warning('FX Object id %s does not match required fx rate %s \n',fx.id,fx_id);
        end
        fx_obj = fx;
    elseif ( isstruct(fx)) % provided fx is struct
        fx_obj = get_sub_object(fx, fx_id);
    else
        error('Forward: provided fx variable is neither a struct nor an fx object.\n');
    end
    % get conversion rate
    fx_rate  = fx_obj.getValue(value_type);
    underlying_price = underlying_price ./ fx_rate;
end

% get curve rates and convert
% Problem: convenience yield / storage costs have convention CONT act/365

% Get discount curve and calculate cost of carry
discount_rate_curve = discount_curve_object.getRate(value_type,days_to_maturity);
% Convert discount rate to cont rate act/365
discount_rate_cont  = convert_curve_rates(valuation_date,days_to_maturity, ...
    discount_rate_curve, curve_comp_type,curve_comp_freq, ...
    curve_basis, 'cont','annual',3);

% calculate cost of carry curve rate (compounding type cont act/365
cost_of_carry_cont       = discount_rate_cont - forward.dividend_yield ...
    + forward.storage_cost - forward.convenience_yield;

% calculate cost of carry curve rate (compounding type cont act/365)
cost_of_carry_fut       = - forward.dividend_yield ...
    + forward.storage_cost - forward.convenience_yield;
    
% convert cost of carry curve to instrument convention
cost_of_carry_instr = convert_curve_rates(valuation_date,days_to_maturity, ...
    cost_of_carry_cont, 'cont','annual',3, ...
    comp_type,comp_freq,basis);

% Convert discount rate from curve rate convention to instrument convention
discount_rate_instr = convert_curve_rates(valuation_date,days_to_maturity, ...
    discount_rate_curve, curve_comp_type,curve_comp_freq, ...
    curve_basis, comp_type,comp_freq,basis);

% #####  Calculate forward value for equity forwards  #####
if ( sum(strcmpi(type,{'Equity','EQFWD'})) > 0 )
    df_forward      = discount_factor (valuation_date, maturity_date, ...
        cost_of_carry_instr , comp_type, basis, comp_freq);
    df_discount     = discount_factor (valuation_date, ...
        maturity_date, discount_rate_curve, ...
        curve_comp_type, curve_basis, curve_comp_freq);
    forward_price   = underlying_price ./ df_forward;
    payoff          = (forward_price - strike ) .* df_discount;
 
 
% #####  Calculate forward value for bond forwards  #####
elseif ( sum(strcmpi(type,{'Bond','BONDFWD'})) > 0 )
    % the value of a bond forward is the discounted value of the underlying
    % bond at settlement date. However, if the bond pays coupons, the future
    % value of these payments has to be subtracted from the future bond price
    % which is discounted. Moreover, accrued interest have to be paid at
    % settlement, making it necessary to add these AI to the forward price.
    % get PV of underlying Bond CF from valuation date until maturity date
    %     discounted with underlying bonds discount curve
    und_cf_dates    = underlying_object.cf_dates;
    und_cf_values   = underlying_object.cf_values;
    dtm = maturity_date - valuation_date;
    und_cf_values   = und_cf_values(und_cf_dates < dtm);
    und_cf_dates    = und_cf_dates(und_cf_dates < dtm);
    und_spread      = underlying_object.soy;
    
    pv_und_bond_int = pricing_npv(valuation_date, ...
            und_cf_dates, und_cf_values, und_spread, und_nodes, ...
            und_rates, curve_basis, curve_comp_type, curve_comp_freq, interp_und, ...
            curve_comp_type_und, curve_basis_und, curve_comp_freq_und);
            
    % calculate accrued interest from bonds last CF date < Ts until Ts
    if ~(isempty(und_cf_dates))
        last_coupon_cf_date = und_cf_dates(end);
    else
        last_coupon_cf_date = 0; %use valuation date
    end
        und_notional    = underlying_object.notional;
        und_coupon_rate = underlying_object.coupon_rate;
        und_basis       = underlying_object.basis;
        accr_interest   = timefactor(last_coupon_cf_date,dtm,und_basis) ...
                        * und_notional * und_coupon_rate;
    
    % get discount factor of forward curve df_discount(Tv,Ts)
    df_discount     = discount_factor (valuation_date, ...
        maturity_date, discount_rate_curve, ...
        curve_comp_type, curve_basis, curve_comp_freq);

    % calculate value and price of forward      
    payoff          = underlying_price - pv_und_bond_int - ( strike + 
                                                accr_interest ) .* df_discount;          
    forward_price   = (underlying_price - pv_und_bond_int) ./ df_discount ...
                        - accr_interest; 
 
% #####  Calculate future value for bond future  #####
elseif ( sum(strcmpi(type,{'BondFuture'})) > 0 )  
    df_discount     = discount_factor (valuation_date, ...
        maturity_date, discount_rate_curve, ...
        curve_comp_type, curve_basis, curve_comp_freq);
    % get attribute values of underlying bond
    last_coupon_date = underlying_object.last_coupon_date;
    comp_weight     = forward.component_weight;
    coupon_rate     = underlying_object.coupon_rate;
    notional        = underlying_object.notional;
    % calculate accrued interest from last bond coupon date to forward settlement
    accr_int        = coupon_rate * timefactor(last_coupon_date + ...
                            valuation_date, maturity_date,3) * notional;
    % calc price from netbasis in stress or MC scenario
    if ~(strcmpi(value_type,'base'))
        price_from_nb_flag = true;
    else
        price_from_nb_flag = forward.calc_price_from_netbasis;
    end  
    % a) calculate forward price from given net basis
    if true(price_from_nb_flag)
        net_basis       = forward.net_basis;
        % calculate forward price and payoff value
        forward_price   = net_basis + (underlying_price ./ df_discount - accr_int) ...
                                    ./ comp_weight;
        payoff          = forward_price - strike;
    % b) calculate net basis and assume future value is 0.0 per definition
    else
        forward_price = strike;
        payoff = forward_price - (underlying_price ./ df_discount - accr_int) ...
                                    ./ comp_weight;
    end

% #####  Calculate value for equity future  #####
elseif ( sum(strcmpi(type,{'EquityFuture'})) > 0 ) 
    % cost of carry discount factor
    df_forward      = discount_factor (valuation_date, maturity_date, ...
        cost_of_carry_fut , 'cont', 3, 'annual');
    % future interest rate discount factor
    df_discount     = discount_factor (valuation_date, ...
        maturity_date, discount_rate_curve, ...
        curve_comp_type, curve_basis, curve_comp_freq);
    % no discrete dividends are assumed, only continuous!
    disc_payments = 0.0;
    % calc price from netbasis in stress or MC scenario
    if ~(strcmpi(value_type,'base'))
        price_from_nb_flag = true;
    else
        price_from_nb_flag = forward.calc_price_from_netbasis;
    end   
    % a) calculate future price from given net basis
    if true(price_from_nb_flag)
        net_basis       = forward.net_basis;
        % calculate forward price and payoff value
        forward_price   = (underlying_price - disc_payments) * df_forward  ...
                                    ./ df_discount + net_basis;
        payoff          = forward_price - strike;
    % b) calculate net basis and assume future value is 0.0 per definition in
    %   base case only
    else
        forward_price = strike;
        payoff = forward_price - (underlying_price - disc_payments) * df_forward  ...
                                    ./ df_discount;
    end
    
% #####  Calculate forward value for FX forwards    #####
elseif ( sum(strcmpi(type,{'FX'})) > 0 )
    % Pricing Formula: 
    % FX_SPOT_PRICE quoted in units of domestic currency per unit of foreign
    % FX_FWD_Price quoted in units of domestic currency per unit of foreign
    % FX_FWD_Price = FX_SPOT_PRICE * DF_FOREIGN / DF_DOMESTIC
    % Payoff is discounted difference between forward price and strike
    % extract rate from foreign curve
    foreign_rate_curve = und_curve_object.getRate(value_type,days_to_maturity);
    % Convert foreign rate from curve rate convention to instrument convention
    foreign_rate_instr  = convert_curve_rates(valuation_date,days_to_maturity, ...
        foreign_rate_curve, curve_comp_type_foreign, ...
        curve_comp_freq_foreign, curve_basis_foreign, ...
        comp_type,comp_freq,basis);
    % calculate discount factors
    df_foreign      = discount_factor (valuation_date, maturity_date, ...
        foreign_rate_instr , comp_type, basis, comp_freq);
    df_discount     = discount_factor (valuation_date, maturity_date, ...
        discount_rate_instr, comp_type, basis, comp_freq);
    % pricing of forward
    forward_price   = underlying_price .* df_foreign ./ df_discount;
    payoff          = (forward_price - strike ) .* df_discount;
else
    error('pricing_forward: not a valid type: >>%s<<',type)
end

theo_value = payoff;
theo_price = forward_price;

end

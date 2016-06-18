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
%# @deftypefn {Function File} {[@var{theo_value} ] =} pricing_forward (@var{forward}, @var{discount_curve}, @var{underlying})
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
%# @item @var{forward}: Structure with relevant information for specification of 
%# the object forward:@*
%#      @itemize @bullet
%#      @item forward.type                   Equity, Bond
%#      @item forward.currency               [optional] Currency (string, ISO code)
%#      @item forward.maturity_date          Maturity date of forward
%#      @item forward.valuation_date         [optional] Valuation date 
%# (default today)
%#      @item forward.strike_price           strike price (float).  
%# Can be a 1xN vector.
%#      @item forward.underlying_price       market price of underlying (float), 
%# in forward currency units. Can be a 1xN vector.
%#      @item forward.storage_cost           [optional] continuous storage 
%# cost p.a. (default 0)
%#      @item forward.convenience_yield      [optional] continuous convenience 
%# yield p.a. (default 0)
%#      @item forward.dividend_yield         [optional] continuous dividend 
%# yield p.a. (default 0)
%#      @item forward.compounding_type       [optional] compounding type 
%# [simple, discrete, continuous] (default 'disc')
%#      @item forward.compounding_frequency  [optional] compounding frequency 
%# [daily, weekly, monthly, semi-annual, annual] (default 'daily')
%#      @item forward.day_count_convention   [optional] day count convenction 
%# (e.g. 'act/act' or '30/360E') (default 'act/act')
%#      @end itemize
%# @item @var{discount_nodes}: tmp_nodes is a 1xN vector with all timesteps of 
%# the given curve
%# @item @var{discount_rates}: tmp_rates is a MxN matrix with discount curve 
%# rates defined in columns. Each row contains a specific scenario with 
%# different curve structure
%# @item @var{theo_value}: returs a 1xN vector with all forward values 
%# @item @var{theo_price}: returs a 1xN vector with all forward prices 
%# @end itemize
%# @seealso{timefactor, discount_factor, interpolate_curve}
%# @end deftypefn

function [theo_value theo_price] = pricing_forward(value_type, forward, ...
                 discount_curve_object, underlying_object, foreign_curve_object )

if nargin < 4 || nargin > 5
    print_usage ();
end

 % Getting instrument properties
    comp_type = forward.compounding_type;
    comp_freq = forward.compounding_freq;
    basis = forward.basis;
    valuation_date = forward.valuation_date;
    currency = forward.currency;
    type = forward.sub_type;
    storage_cost = forward.storage_cost; % continuous storage cost p.a.
    convenience_yield = forward.convenience_yield; % continuous convenience_yield p.a.
    dividend_yield = forward.dividend_yield;
    maturity_date = datenum(forward.maturity_date);
    strike = forward.strike_price;

 % Getting curve properties
    % Get Discount Curve nodes and rate and related attributes
        discount_nodes  = discount_curve_object.get('nodes');
        discount_rates  = discount_curve_object.getValue(value_type);
        interp_discount = discount_curve_object.get('method_interpolation');
        curve_basis     = discount_curve_object.get('basis');
        curve_comp_type = discount_curve_object.get('compounding_type');
        curve_comp_freq = discount_curve_object.get('compounding_freq');
        
 % Getting underlying properties 
    % distinguish between index or RF underlyings for EQ and Bond Forwards
    if ( sum(strcmpi(type,{'Equity','EQFWD','Bond'})) > 0 )
        if ( strfind(underlying_object.get('id'),'RF_') )   % underlying instrument is a risk factor
            tmp_underlying_sensitivity = forward.get('underlying_sensitivity'); 
            tmp_underlying_delta = underlying_object.getValue(value_type);
            underlying_price = Riskfactor.get_abs_values(underlying_object.model, ...
                                tmp_underlying_delta, obj.underlying_price_base, ...
                                tmp_underlying_sensitivity);
        else    % underlying is a index 
            underlying_price = underlying_object.getValue(value_type);
        end
    elseif ( sum(strcmpi(type,{'FX'})) > 0 )
        if nargin < 5
            error('pricing_forward: No foreign curve object provided.');
        end
        % getting foreign curve properties
        foreign_nodes           = foreign_curve_object.get('nodes');
        foreign_rates           = foreign_curve_object.getValue(value_type);
        interp_foreign          = foreign_curve_object.get('method_interpolation');
        curve_basis_foreign     = foreign_curve_object.get('basis');
        curve_comp_type_foreign = foreign_curve_object.get('compounding_type');
        curve_comp_freq_foreign = foreign_curve_object.get('compounding_freq');
        % Getting underlying currency properties
        underlying_price = underlying_object.getValue(value_type);
    end
     
    


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
if ( rows(discount_rates) > 1 && rows(underlying_price) > 1 
    && (rows(underlying_price) ~= rows(discount_rates)))
    error('Rows of underlying price not equal to 1 or to number of rows of discount_rats. Aborting.')  
end

% get curve rates and convert
% Problem: convenience yield / storage costs have convention CONT act/365

% Get discount curve and calculate cost of carry
discount_rate_curve       = interpolate_curve(discount_nodes,discount_rates, ...
                                              days_to_maturity,interp_discount);

% Convert discount rate to cont rate act/365
discount_rate_cont  = convert_curve_rates(valuation_date,days_to_maturity, ...
                        discount_rate_curve, curve_comp_type,curve_comp_freq, ...
                        curve_basis, 'cont','annual',3);
                        
% calculate cost of carry curve rate (compounding type conv act/365                      
cost_of_carry_cont       = discount_rate_cont - forward.dividend_yield ...
                            + forward.storage_cost - forward.convenience_yield;

% convert cost of carry curve to instrument convention
cost_of_carry_instr = convert_curve_rates(valuation_date,days_to_maturity, ...
                        cost_of_carry_cont, 'cont','annual',3, ...
                        comp_type,comp_freq,basis);
                        
% Convert discount rate from curve rate convention to instrument convention
discount_rate_instr = convert_curve_rates(valuation_date,days_to_maturity, ...
                        discount_rate_curve, curve_comp_type,curve_comp_freq, ...
                        curve_basis, comp_type,comp_freq,basis);
                        
% #####  Calculate forward value for equity and bond forwards  #####
if ( sum(strcmpi(type,{'Equity','EQFWD'})) > 0 )
    df_forward      = discount_factor (valuation_date, maturity_date, ...
                            cost_of_carry_instr , comp_type, basis, comp_freq);
    df_discount     = discount_factor (valuation_date, maturity_date, ...
                            discount_rate_instr, comp_type, basis, comp_freq);
    forward_price   = underlying_price ./ df_forward;
    payoff          = (forward_price - strike ) .* df_discount;
    
% #####  Calculate forward value for bond forwards  #####
elseif ( sum(strcmpi(type,{'Bond','BONDFWD'})) > 0 )
    df_discount     = discount_factor (forward.valuation_date, ...
                                forward.maturity_date, discount_rate_instr, ...
                                comp_type, basis, comp_freq);
    forward_price   = underlying_price ./ df_discount;                           
    payoff          = underlying_price - (strike .* df_discount);
    
% #####  Calculate forward value for FX forwards    #####
elseif ( sum(strcmpi(type,{'FX'})) > 0 )                                              
    % extract rate from foreign curve   
    foreign_rate_curve  = interpolate_curve(foreign_nodes,foreign_rates, ...
                                              days_to_maturity,interp_foreign);
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
    % pricing reverse engineered
    forward_price   = 1 ./ underlying_price;  
    payoff          = (forward_price - strike ) .* df_discount;    
else
    error('pricing_forward_oop: not a valid type: >>%s<<',type)
end

theo_value = payoff;
theo_price = forward_price;

end

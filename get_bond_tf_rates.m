%# Copyright (C) 2016 Schinzilord <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{tf_vec} @var{rate_vec} @var{df_vec}] =} get_bond_tf_rates(@var{valuation_date}, @var{cashflow_dates}, @var{cashflow_values}, @var{spread_constant}, @var{discount_nodes}, @var{discount_rates}, @var{basis}, @var{comp_type}, @var{comp_freq}, @var{interp_discount})
%#
%# Compute the time factors, rates and discount factors for a
%# given cash flow pattern according to a given discount curve 
%# and day count convention etc.@*
%# Pre-requirements:@*
%# @itemize @bullet
%# @item installed octave financial package
%# @item custom functions timefactor, discount_factor, interpolate_curve, 
%# and convert_curve_rates
%# @end itemize
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{valuation_date}:  Structure with relevant information for 
%# specification of the forward:@*
%# @item @var{cashflow_dates}:  cashflow_dates is a 1xN vector with all 
%# timesteps of the cash flow pattern
%# @item @var{cashflow_values}: cashflow_values is a MxN matrix with cash flow 
%# pattern.
%# @item @var{spread_constant}: a constant spread added to the total yield 
%# extracted from discount curve and spread curve (can be used to spread over yield)
%# @item @var{discount_nodes}:  tmp_nodes is a 1xN vector with all timesteps of 
%# the given curve
%# @item @var{discount_rates}:  tmp_rates is a MxN matrix with discount curve 
%# rates defined in columns. Each row contains a specific scenario with different 
%# curve structure
%# @item @var{basis}:   OPTIONAL: day-count convention of instrument (either 
%# basis number between 1 and 11, or specified as string (act/365 etc.)
%# @item @var{comp_type}:   OPTIONAL: compounding type of instrument 
%# (disc, cont, simple)
%# @item @var{comp_freq}:   OPTIONAL: compounding frequency of instrument 
%# (1,2,3,4,6,12 payments per year)
%# @item @var{comp_type_curve}: OPTIONAL: compounding type of curve 
%# @item @var{basis_curve}: OPTIONAL: day-count convention of curve 
%# @item @var{comp_freq_curve}: OPTIONAL: compounding frequency of curve 
%# @item @var{interp_discount}: OPTIONAL: interpolation method of discount curve 
%# @item @var{sensi_flag}: OPTIONAL: boolean variable (calculate sensitivities)
%# (default: linear)
%# @item @var{tf_vec}: returns a Mx1 vector with time factors per cash flow date
%# @item @var{rate_vec}:  returns a Mx1 vector with rates per cf date
%# @item @var{df_vec}:  returns a Mx1 vector with discount factors per cf date
%# method)
%# @end itemize
%# @seealso{timefactor, discount_factor, interpolate_curve, convert_curve_rates}
%# @end deftypefn

function [tf_vec rate_vec df_vec] = get_bond_tf_rates(valuation_date, ...
            cashflow_dates, cashflow_values, spread_constant, discount_nodes, ...
            discount_rates, basis, comp_type, comp_freq, interp_discount, ...
            comp_type_curve, basis_curve, comp_freq_curve, sensi_flag)
% This function calculates the net present value, duration and convexity of a 
% cash flows for a given discount and spread curve.
 if nargin < 6 || nargin > 14
    print_usage ();
 end
 
if ( nargin < 7 )
  basis = 3;  
  comp_type = 'disc';
  comp_freq = 1;
  interp_discount = 'linear';
  comp_type_curve  = comp_type;
  basis_curve      = basis; 
  comp_freq_curve  = comp_freq;
elseif ( nargin == 7 )
  comp_type = 'disc';
  comp_freq = 1;
  interp_discount = 'linear';
  interp_spread  = 'linear';
  comp_type_curve  = comp_type;
  basis_curve      = basis; 
  comp_freq_curve  = comp_freq;
elseif ( nargin == 8 )
  comp_freq = 1;
  interp_discount = 'linear';
  interp_spread  = 'linear';
  comp_type_curve  = comp_type;
  basis_curve      = basis; 
  comp_freq_curve  = comp_freq;
elseif ( nargin == 9 )
  interp_discount = 'linear';
  interp_spread  = 'linear'; 
  comp_type_curve  = comp_type;
  basis_curve      = basis; 
  comp_freq_curve  = comp_freq;
elseif ( nargin == 10 )
  interp_spread  = 'linear';
  comp_type_curve  = comp_type;
  basis_curve      = basis; 
  comp_freq_curve  = comp_freq;  
elseif ( nargin == 11 )
  comp_type_curve  = comp_type;
  basis_curve      = basis; 
  comp_freq_curve  = comp_freq;   
elseif ( nargin == 12 )
  basis_curve      = basis; 
  comp_freq_curve  = comp_freq;  
elseif ( nargin == 13 )
  comp_freq_curve  = comp_freq;  
end

if (nargin < 14)
    sensi_flag = false;
end

if ischar(comp_freq)
    if ( regexpi(comp_freq,'^da'))
        comp_freq = 365;
    elseif ( regexpi(comp_freq,'^week'))
        comp_freq = 52;
    elseif ( regexpi(comp_freq,'^month'))
        comp_freq = 12;
    elseif ( regexpi(comp_freq,'^quarter'))
        comp_freq = 4;
    elseif ( regexpi(comp_freq,'^semi-annual'))
        comp_freq = 2;
    elseif ( regexpi(comp_freq,'^annual'))
        comp_freq = 1;       
    else
        error('pricing_npv:Need valid compounding frequency. Unknown >>%s<<',comp_freq)
    end
end

% Start time:
if ischar(valuation_date)
   valuation_date = datenum(valuation_date);
end

% ------------------------------------------------------------------
% interpolate curve and calculate time factors

% preallocate vectors
tf_vec  = zeros(1,length(cashflow_values));
rate_vec = tf_vec;
df_vec = tf_vec;
    
for zz = 1 : 1 : columns(cashflow_values)   % loop via all cashflows  
    tmp_dtm = cashflow_dates(zz);
    % Get yield at actual spot value
        % get discount rate from discount curve
        rate_curve = interpolate_curve(discount_nodes,discount_rates, ...
                                        tmp_dtm,interp_discount);  
    % convert spread rate convention (cont, act/365) to curve conv
        spread_constant_conv = convert_curve_rates(valuation_date,tmp_dtm, ...
                    spread_constant,'continuous','annual',3, ...
                    comp_type_curve,comp_freq_curve,basis_curve);
    % combine with constant spread (e.g. spread over yield)
        yield_total 	= rate_curve  + spread_constant_conv;  
        tmp_cf_date 	= valuation_date + tmp_dtm;            
    % Get actual discount factor and time factor acc. to curve convention
        tmp_df 			= discount_factor (valuation_date, tmp_cf_date, ...
                                           yield_total, comp_type_curve, ...
                                           basis_curve, comp_freq_curve); 
    % Get timefactor of instrument cash flows for duration calculation
        tmp_tf          = timefactor(valuation_date,tmp_cf_date,basis); 
    % store in vector
    tf_vec(zz) = tmp_tf;
    rate_vec(zz) = yield_total;
    df_vec(zz) = tmp_df;
end 
% ------------------------------------------------------------------  


              
end
 
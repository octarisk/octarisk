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
%# @deftypefn {Function File} {[@var{npv} @var{MacDur} ] =} pricing_npv(@var{valuation_date}, @var{cashflow_dates}, @var{cashflow_values}, @var{spread_constant}, @var{discount_nodes}, @var{discount_rates}, @var{basis}, @var{comp_type}, @var{comp_freq}, @var{interp_discount})
%#
%# Compute the net present value and Maccaulay Duration of a given cash flow 
%# pattern according to a given discount curve and day count convention etc.@*
%# Pre-requirements:@*
%# @itemize @bullet
%# @item installed octave finance package
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
%# (default: linear)
%# @item @var{npv}: returs a 1xN vector with all net present values per scenario
%# @item @var{MacDur}:  returs a 1xN vector with all Maccaulay durations
%# @end itemize
%# @seealso{timefactor, discount_factor, interpolate_curve, convert_curve_rates}
%# @end deftypefn

function [npv MacDur] = pricing_npv(valuation_date,cashflow_dates, ...
            cashflow_values, spread_constant,discount_nodes,discount_rates, ...
            basis, comp_type, comp_freq, interp_discount, comp_type_curve, ...
            basis_curve, comp_freq_curve)
% This function calculates the net present value, duration and convexity of a 
% cash flows for a given discount and spread curve.
 if nargin < 6 || nargin > 13
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

% Start time:
if ischar(valuation_date)
   valuation_date = datenum(valuation_date);
end

% ------------------------------------------------------------------
% Calculate net present value
tmp_npv = 0;
tmp_npv_duration_minus100bp = 0;
tmp_npvduration_plus100bp = 0;
MacDur = 0;
for zz = 1 : 1 : columns(cashflow_values)   % loop via all cashflows  
    tmp_dtm = cashflow_dates(zz);
    tmp_cf_value = cashflow_values(:,zz);
    if ( tmp_dtm > 0 )  % discount only future cashflows
        % Get yield at actual spot value
            % get discount rate from discount curve
			rate_curve = interpolate_curve(discount_nodes,discount_rates, ...
                                            tmp_dtm,interp_discount);  
            % convert curve rate convention into instrument convention
            yield_discount = convert_curve_rates(valuation_date,tmp_dtm,rate_curve, ...
                        comp_type_curve,comp_freq_curve,basis_curve, ...
                        comp_type,comp_freq,basis);
            % combine with constant spread (e.g. spread over yield)
			yield_total 	= yield_discount  + spread_constant;            
			tmp_cf_date 	= valuation_date + tmp_dtm;
        % Get actual discount factor
			tmp_df 			= discount_factor (valuation_date, tmp_cf_date, ...
                                    yield_total, comp_type, basis, comp_freq);           
			tmp_tf          = timefactor(valuation_date,tmp_cf_date,basis);  
        %Calculate actual NPV of cash flows    
			tmp_npv_cashflow = tmp_cf_value .* tmp_df;
			MacDur = MacDur + tmp_tf .* tmp_npv_cashflow;
        % Add actual cash flow npv to total npv
			tmp_npv 		= tmp_npv+ tmp_npv_cashflow;
    end
end 
% ------------------------------------------------------------------  

% Return NPV and MacDur
npv = tmp_npv;
MacDur = MacDur ./ npv;
            
            
end
 

%!assert(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028;0.005,0.015,0.019,0.024;-0.04,0.03,-0.02,0.05],11,'cont','annual','monotone-convex'),[101.0136109;102.2586319;104.6563569],0.000002)
%!assert(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028],0,'discrete','annual','smith-wilson'),101.1471149,0.000001)
%!assert(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028],3,'discrete','annual','monotone-convex'),101.1365279,0.000001)
%!assert(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028],3,'discrete','annual','linear'),101.1740699,0.000001)


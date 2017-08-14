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
%# @deftypefn {Function File} {[@var{npv} @var{MacDur} @var{Convexity} @var{MonDur} @var{Convexity_alt}] =} pricing_npv(@var{valuation_date}, @var{cashflow_dates}, @var{cashflow_values}, @var{spread_constant}, @var{discount_nodes}, @var{discount_rates}, @var{basis}, @var{comp_type}, @var{comp_freq}, @var{interp_discount})
%#
%# Compute the net present value, Macaulay Duration, Convexity and Monetary
%# duration of a given cash flow pattern according to a given discount curve 
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
%# @item @var{valuation_date}:  valuation date (preferred as datenum)@*
%# @item @var{cashflow_dates}:  cashflow_dates is a 1xN vector with all 
%# timesteps of the cash flow pattern
%# @item @var{cashflow_values}: cashflow_values is a MxN matrix with cash flow 
%# pattern.
%# @item @var{spread_constant}: a constant spread added to the total yield 
%# extracted from discount curve and spread curve (can be used to spread over yield)
%# @item @var{discount_nodes}:  discount_nodes is a 1xN vector with all timesteps of 
%# the given curve
%# @item @var{discount_rates}:  discount_rates is a MxN matrix with discount curve 
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
%# @item @var{npv}: returns a Mx1 vector with all net present values per scenario
%# @item @var{MacDur}:  returns a Mx1 vector with all Macaulay durations
%# @item @var{Convexity}:  returns a Mx1 vector with all convexities
%# @item @var{MonDur}:  returns a Mx1 vector with all Monetary durations
%# @item @var{Convexity_alt}:  returns a Mx1 vector with Convexity (alternative 
%# method)
%# @end itemize
%# @seealso{timefactor, discount_factor, interpolate_curve, convert_curve_rates}
%# @end deftypefn

function [npv MacDur Convexity MonDur Convexity_alt] = pricing_npv(valuation_date, ...
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
% Calculate net present value
MacDur = 0;
Convexity = 0;
Convexity_alt = 0;
MonDur = 0.0;

% get rid of past cashflows
cashflow_values(cashflow_dates<0) = [];
cashflow_dates(cashflow_dates<0) = [];

% convert spread rate convention (cont, act/365) to curve conv
spread_constant_vec = convert_curve_rates(valuation_date,cashflow_dates', ...
                        spread_constant,'continuous','annual',3, ...
                        comp_type_curve,comp_freq_curve,basis_curve);

% get discount rate from discount curve
% distinguish between interpolation methods
if ( strcmpi(interp_discount,'linear'))
	rate_curve_vec = interpolate_curve_vectorized(discount_nodes, ...
						discount_rates, cashflow_dates);
else
	rate_curve_vec = zeros(rows(discount_rates),length(cashflow_dates));
	for zz = 1 : 1 : columns(cashflow_dates);
		tmp_dtm = cashflow_dates(zz);
		if ( tmp_dtm > 0 )
				rate_curve_vec(:,zz) = interpolate_curve(discount_nodes,discount_rates, ...
                                            tmp_dtm,interp_discount);
		end
	end
end 
rate_curve_vec = max(rate_curve_vec,-0.99999);
yield_total = rate_curve_vec'  + spread_constant_vec ;

% get discount factors
df_vec 		= discount_factor (valuation_date, (valuation_date + cashflow_dates)', ...
                            yield_total, comp_type_curve, ...
                            basis_curve, comp_freq_curve)';									

% calculate net present value (call cpp function for efficient column loop)
npv 		= calculate_npv_cpp(cashflow_values,df_vec);

% calculate sensitivities only if flag is set	
if (sensi_flag == true && npv(1) > 0.0)
	tf_vec  = timefactor(valuation_date,valuation_date + cashflow_dates,basis); 
	
	% get npv of all single cash flows
	npv_cashflows = cashflow_values .* df_vec;
	
	% calculate durations
	MacDur = sum(tf_vec .* npv_cashflows,2);
	MonDur = sum(tf_vec .* df_vec.^2 .* cashflow_values,2);

	% calculate convexities
	if ( regexpi(comp_type_curve,'disc'))
		Convexity = sum(npv_cashflows .* (tf_vec + 1/comp_freq ) ...
				.* tf_vec ./ ( 1 + yield_total'/comp_freq).^2,2);
	elseif ( regexpi(comp_type_curve,'cont')) 
		Convexity = sum(npv_cashflows .* tf_vec.^2,2);
	else    % in case of simple compounding
		Convexity = sum(2 .* tf_vec.^2 .* cashflow_values .* df_vec.^3,2);
	end
	% calculating alternative Convexity
	Convexity_alt = sum(npv_cashflows .* (tf_vec.^2 + tf_vec) ...
					./ ( 1 + yield_total'),2);
	
	% calculate sensitivities 
	MacDur = MacDur ./ npv;
	Convexity = Convexity ./ npv;    
	Convexity_alt = Convexity_alt ./ npv;
end
              
end
 

%!assert(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028;0.005,0.015,0.019,0.024;-0.04,0.03,-0.02,0.05],11,'cont','annual','monotone-convex'),[101.014302298068;102.259330913865;104.657072744736],0.000002)
%!assert(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028],0,'discrete','annual','smith-wilson'),101.143631260860,0.000001)
%!assert(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028],3,'discrete','annual','monotone-convex'),101.133566977140,0.000001)
%!assert(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028],3,'discrete','annual','linear'),101.171107422211,0.000001)

%!assert(pricing_npv(datenum('31-Dec-2015'),[314,679,1044,1409,1775,2140,2505,2870,3236,3601,3966],[1.504109589,1.5,1.5,1.5,1.504109589,1.5,1.5,1.5,1.504109589,1.5,101.5], 0.0,[314],[0.01],3, 'simple', 'annual', 'linear', 'simple', 3, 'annual'),105.811112622,0.00000001)            
%!assert(pricing_npv(datenum('31-Dec-2015'),[314,679,1044,1409,1775,2140,2505,2870,3236,3601,3966],[1.504109589,1.5,1.5,1.5,1.504109589,1.5,1.5,1.5,1.504109589,1.5,101.5], 0.0,[314],[0.01],3, 'simple', 'annual', 'linear', 'cont', 3, 'annual'),105.283752847214,0.00000001)            
%!assert(pricing_npv(datenum('31-Dec-2015'),[314,679,1044,1409,1775,2140,2505,2870,3236,3601,3966],[1.504109589,1.5,1.5,1.5,1.504109589,1.5,1.5,1.5,1.504109589,1.5,101.5], 0.0,[314],[0.01],3, 'simple', 'annual', 'linear', 'cont', 0, 'annual'),105.291914185406,0.00000001)            
%!assert(pricing_npv(datenum('31-Dec-2015'),[314,679,1044,1409,1775,2140,2505,2870,3236,3601,3966],[1.504109589,1.5,1.5,1.5,1.504109589,1.5,1.5,1.5,1.504109589,1.5,101.5], 0.0,[314],[0.01],3, 'simple', 'annual', 'linear', 'disc', 0, 'annual'),105.344763058056,0.00000001)            

%!test
%! [npv MacDur Convexity]=pricing_npv(datenum('31-Dec-2015'),[314,679,1044,1409,1775,2140,2505,2870,3236,3601,3966],[1.504109589,1.5,1.5,1.5,1.504109589,1.5,1.5,1.5,1.504109589,1.5,101.5], 0.0,[365,3650],[0.01,0.02],3, 'simple', 'annual', 'linear', 'disc', 0, 'annual', true);
%! assert(npv,95.6356279635214,0.00000001)
%! assert(MacDur,10.0488785788358,0.00000001)
%! assert(Convexity,111.693228473846,0.00000001)

%!test
%! [npv MacDur Convexity] = pricing_npv(datenum('31-Dec-2015'),[314,679,1044,1409,1775,2140,2505,2870,3236,3601,3966],[1.504109589,1.5,1.5,1.5,1.504109589,1.5,1.5,1.5,1.504109589,1.5,101.5], 0.0,[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015],[0.00010026,0.00010027,0.00010027,0.00010014,0.00010009,0.00096236,0.00231387,0.00376975,0.005217,0.00660956,0.00791501,0.00910955,0.01018287],3, 'simple', 'annual', 'linear', 'cont', 3, 'annual', true);
%! assert(npv,105.619895059963,0.0000001)
%! assert(MacDur,10.0933391311109,0.0000001)
%! assert(Convexity,106.724246965361,0.0000001)

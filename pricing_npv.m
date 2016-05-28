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
%# @deftypefn {Function File} {[@var{npv} @var{MacDur} ] =} pricing_npv(@var{valuation_date}, @var{cashflow_dates}, @var{cashflow_values}, @var{spread_constant} ...
%#										, @var{discount_nodes}, @var{discount_rates}, @var{spread_nodes}, @var{spread_rates}, @var{basis}, @var{comp_type}, @var{comp_freq}, @var{interp_discount}, @var{interp_spread})
%#
%# Computes the net present value and Maccaulay Duration of a given cash flow pattern according to a given discount curve, spread curve and day count convention etc.@*
%# Pre-requirements:@*
%# @itemize @bullet
%# @item installed octave finance package
%# @item custom functions timefactor, discount_factor, interpolate_curve
%# @end itemize
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{valuation_date}: 	Structure with relevant information for specification of the forward:@*
%# @item @var{cashflow_dates}: 	cashflow_dates is a 1xN vector with all timesteps of the cash flow pattern
%# @item @var{cashflow_values}: cashflow_values is a MxN matrix with cash flow pattern.
%# @item @var{spread_constant}: a constant spread added to the total yield extracted from discount curve and spread curve (can be used to spread over yield)
%# @item @var{discount_nodes}: 	tmp_nodes is a 1xN vector with all timesteps of the given curve
%# @item @var{discount_rates}: 	tmp_rates is a MxN matrix with discount curve rates defined in columns. Each row contains a specific scenario with different curve structure
%# @item @var{spread_nodes}: 	OPTIONAL: spread_nodes is a 1xN vector with all timesteps of the given spread curve
%# @item @var{spread_rates}: 	OPTIONAL: spread_rates is a MxN matrix with spread curve rates defined in columns. Each row contains a specific scenario with different curve structure
%# @item @var{basis}:			OPTIONAL: day-count convention (either basis number between 1 and 11, or specified as string (act/365 etc.)
%# @item @var{comp_type}:		OPTIONAL: compounding type (disc, cont, simple)
%# @item @var{comp_freq}:		OPTIONAL: compounding frequency (1,2,3,4,6,12 payments per year)
%# @item @var{interp_discount}: OPTIONAL: interpolation method of discount curve  (default: linear)
%# @item @var{interp_spread}:   OPTIONAL: interpolatoin method of spread curve (default: linear)
%# @item @var{npv}: 			returs a 1xN vector with all net present values per scenario
%# @item @var{MacDur}: 			returs a 1xN vector with all Maccaulay durations
%# @end itemize
%# @seealso{timefactor, discount_factor, interpolate_curve}
%# @end deftypefn

function [npv MacDur] = pricing_npv(valuation_date,cashflow_dates, cashflow_values,spread_constant,discount_nodes,discount_rates,spread_nodes,spread_rates,basis,comp_type,comp_freq,interp_discount,interp_spread)
% This function calculates the net present value, duration and convexity of a cash flows for a given discount and spread curve.
if ( nargin < 7 )
  spread_nodes = [365];
  spread_rates = [0]; 
  basis = 3;  
  comp_type = 'disc';
  comp_freq = 1;
  interp_discount = 'linear';
  interp_spread  = 'linear';
elseif ( nargin < 9 )
  basis = 3;
  comp_type = 'disc';
  comp_freq = 1;
  interp_discount = 'linear';
  interp_spread  = 'linear';
elseif ( nargin < 10 )
  comp_type = 'disc';
  comp_freq = 1;
  interp_discount = 'linear';
  interp_spread  = 'linear';
elseif ( nargin < 11 )
  comp_freq = 1;
  interp_discount = 'linear';
  interp_spread  = 'linear';
elseif ( nargin < 12 )
  interp_discount = 'linear';
  interp_spread  = 'linear'; 
elseif ( nargin < 13 )
  interp_spread  = 'linear'; 
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
			yield_discount 	= interpolate_curve(discount_nodes,discount_rates,tmp_dtm,interp_discount);  % get discount rate from discount curve
			yield_spread 	= interpolate_curve(spread_nodes,spread_rates,tmp_dtm,interp_spread);        % get spread rate from spread curve
			yield_total 	= yield_discount + yield_spread + spread_constant;            % combine with constant spread (e.g. spread over yield)
			tmp_cf_date 	= valuation_date + tmp_dtm;
        % Get actual discount factor
			tmp_df 			= discount_factor (valuation_date, tmp_cf_date, yield_total, comp_type, basis, comp_freq);           
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
 
 %      Valid Basis are:
%            0 = actual/actual (default)
%            1 = 30/360 SIA
%            2 = actual/360
%            3 = actual/365
%            4 = 30/360 PSA
%            5 = 30/360 ISDA
%            6 = 30/360 European
%            7 = act/365 Japanese
%            8 = act/act ISMA
%            9 = act/360 ISMA
%           10 = act/365 ISMA
%           11 = 30/360E (ISMA)
%tmp_df = (1 + yield_total).^(-tmp_dtm./365)


%if ( tmp_dtm > 0 )  % discount only future cashflows
        %% Get yield at actual spot value
        %yield_discount 	= interpolate_curve(discount_nodes,discount_rates,tmp_dtm);  % get discount rate from discount curve
        %yield_spread 	= interpolate_curve(spread_nodes,spread_rates,tmp_dtm);        % get spread rate from spread curve
        %yield_total 				= yield_discount + yield_spread + spread_constant;            % combine with constant spread (e.g. spread over yield)
        %%yield_duration_minus100bp 	= yield_total - 0.01;
        %%yield_duration_plus100bp 	= yield_total + 0.01;
        %tmp_cf_date 				= valuation_date + tmp_dtm;
        %% Get actual discount factor
        %tmp_df 						= discount_factor (valuation_date, tmp_cf_date, yield_total, comp_type, basis, comp_freq); 
        %%tmp_df_duration_minus100bp 	= discount_factor (valuation_date, tmp_cf_date, yield_duration_minus100bp, comp_type, basis, comp_freq); 
        %%tmp_df_duration_plus100bp 	= discount_factor (valuation_date, tmp_cf_date, yield_duration_plus100bp, comp_type, basis, comp_freq);     
        %tmp_tf = timefactor(valuation_date,tmp_cf_date,basis);  
        %%Calculate actual NPV of cash flows    
        %tmp_npv_cashflow 			= tmp_cf_value .* tmp_df;
        %%tmp_npv_cashflow_duration_minus100bp = tmp_cf_value .* tmp_df_duration_minus100bp;
        %%tmp_npv_cashflow_duration_plus100bp 	= tmp_cf_value .* tmp_df_duration_plus100bp;
        %MacDur = MacDur + tmp_tf .* tmp_npv_cashflow;
        %% Add actual cash flow npv to total npv
        %tmp_npv 					= tmp_npv+ tmp_npv_cashflow;
        %%tmp_npv_duration_minus100bp = tmp_npv_duration_minus100bp+ tmp_npv_cashflow_duration_minus100bp;
        %%tmp_npvduration_plus100bp 	= tmp_npvduration_plus100bp+ tmp_npv_cashflow_duration_plus100bp;
    %end
%MacDur_sensi = abs(tmp_npv_duration_minus100bp - tmp_npvduration_plus100bp) ./ 2;

%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {@var{spread_over_yield}} = calibrate_soy_sqp(@var{valuation_date},@var{tmp_cashflow_dates},@var{tmp_cashflow_values},@var{tmp_act_value},@var{tmp_nodes},@var{tmp_rates},@var{spread_nodes},@var{spread_rates},@var{basis},@var{comp_type},@var{comp_freq})
%# Calibrate the spread over yield according to given cashflows discounted on an appropriate yield curve.
%# @end deftypefn

function [spread_over_yield ] = calibrate_soy_sqp(valuation_date,tmp_cashflow_dates, tmp_cashflow_values,tmp_act_value,tmp_nodes,tmp_rates,spread_nodes,spread_rates,basis,comp_type,comp_freq)

if ( nargin == 6 )
  spread_nodes = [365];
  spread_rates = [0]; 
  basis = 3;  
  comp_type = 'disc';
  comp_freq = 1;
elseif ( nargin == 8 )
  basis = 3;
  comp_type = 'disc';
  comp_freq = 1;
elseif  ( nargin == 9 )
  comp_type = 'disc'
  comp_freq = 1
elseif ( nargin == 10 )
  comp_freq = 1
elseif ( nargin > 11)
    error("Too many arguments")
endif
if ( rows(tmp_cashflow_values) > 1 )
	tmp_cashflow_values = tmp_cashflow_values(1,:);
	disp("WARNING: More than one cash flow value scenario provided. Taking only first scenario as base values")
endif
% Start parameter
x0 = -0.0001;

% Start time:
if ischar(valuation_date)
   valuation_date = datenum(valuation_date);
end


%p0=[x0]'; % Guessed parameters.
options(1) = 0;
options(2) = 1e-5;
[x, obj, info, iter] = sqp (x0, @ (x) phi_soy(x,valuation_date,tmp_cashflow_dates, tmp_cashflow_values,tmp_act_value,tmp_nodes,tmp_rates,spread_nodes,spread_rates,basis,comp_type,comp_freq), [], [], -1, 1, 300);	%, obj, info, iter, nf, lambda @g

if (info == 101 )
	%disp ("       +++ SUCCESS: Optimization converged in +++");
	%steps = iter
elseif (info == 102 )
	disp ("       --- WARNING: The BFGS update failed. ---");
elseif (info == 103 )
	disp ("       --- WARNING: The maximum number of iterations was reached. ---");
elseif (info == 104 )
    %disp ("       --- WARNING: The stepsize has become too small. ---");
else
	disp ("       --- WARNING: Optimization did not converge! ---");
endif
% 
% return spread over yield
spread_over_yield = x;

end 

%------------------------------------------------------------------
%------------------- Begin Subfunctions ---------------------------
 
% Definition Objective Function for spread over yield:	    
function obj = phi_soy (x,valuation_date,cashflow_dates, cashflow_values,act_value,discount_nodes,discount_rates,spread_nodes,spread_rates,basis,comp_type,comp_freq)
         tmp_npv = 0;
         %tmp_npv = pricing_npv(valuation_date,cashflow_dates, cashflow_values,x,discount_nodes,discount_rates,spread_nodes,spread_rates,basis,comp_type,comp_freq);
         for zz = 1 : 1 : length(cashflow_values)   % loop via all cashflows  
            tmp_dtm = cashflow_dates(zz);
            tmp_cf_value = cashflow_values(zz);
            if ( tmp_dtm > 0 )  % discount only future cashflows
                yield_discount = interpolate_curve(discount_nodes,discount_rates,tmp_dtm);  % get discount rate from discount curve
                yield_spread = interpolate_curve(spread_nodes,spread_rates,tmp_dtm);        % get spread rate from spread curve
                yield_total = yield_discount .+ yield_spread .+ x;            % combine with constant spread (e.g. spread over yield)
                tmp_cf_date = valuation_date .+ tmp_dtm;
                tmp_df = discount_factor (valuation_date, tmp_cf_date, yield_total, comp_type, basis, comp_freq);      
                %tmp_df = (1 .+ yield_total).^(-tmp_dtm./365);
                tmp_npv_cashflow = tmp_cf_value .* tmp_df;
                tmp_npv = tmp_npv.+ tmp_npv_cashflow;
            end
        endfor 
        obj = (act_value - tmp_npv).^2;
endfunction
%------------------------------------------------------------------

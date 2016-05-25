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
%# @deftypefn {Function File} { [@var{vola_spread}] =} calibrate_soy_sqp(@var{valuation_date},@var{tmp_cashflow_dates},@var{tmp_cashflow_values},@var{tmp_act_value},@var{tmp_nodes},@var{tmp_rates},@var{spread_nodes},@var{spread_rates},@var{basis},@var{comp_type},@var{comp_freq})
%# Calibrate the spread over yield according to given cashflows discounted on an appropriate yield curve.
%# @end deftypefn

function [spread_over_yield retcode] = calibrate_soy_sqp(valuation_date,tmp_cashflow_dates, ...
                tmp_cashflow_values,tmp_act_value,tmp_nodes,tmp_rates,spread_nodes,spread_rates,basis,comp_type,comp_freq)

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
    error('Too many arguments')
end
if ( rows(tmp_cashflow_values) > 1 )
	tmp_cashflow_values = tmp_cashflow_values(1,:);
	disp('WARNING: More than one cash flow value scenario provided. Taking only first scenario as base values')
end
% Start parameter
retcode = 0;
x0 = -0.0001;

% Start time:
if ischar(valuation_date)
   valuation_date = datenum(valuation_date);
end


%p0=[x0]'; % Guessed parameters.
options(1) = 0;
options(2) = 1e-5;
[x, obj, info, iter] = sqp (x0, @ (x) phi_soy(x,valuation_date,tmp_cashflow_dates, tmp_cashflow_values, ...
            tmp_act_value,tmp_nodes,tmp_rates,spread_nodes,spread_rates,basis,comp_type,comp_freq), [], [], -1, 1, 300);	%, obj, info, iter, nf, lambda @g

if (info == 101 )
	%disp ('       +++ SUCCESS: Optimization converged in +++');
	%steps = iter
elseif (info == 102 )
	disp ('       --- WARNING: The BFGS update failed. ---');
    retcode = 255;
elseif (info == 103 )
	disp ('       --- WARNING: The maximum number of iterations was reached. ---');
    retcode = 255;
elseif (info == 104 )
    %disp ('       --- WARNING: The stepsize has become too small. ---');
else
	disp ('       --- WARNING: Optimization did not converge! ---');
    retcode = 255;
end
% 
% return spread over yield
spread_over_yield = x;

end 

%------------------------------------------------------------------
%------------------- Begin Subfunctions ---------------------------
 
% Definition Objective Function for spread over yield:	    
function obj = phi_soy (x,valuation_date,cashflow_dates, cashflow_values,act_value,discount_nodes, ...
                discount_rates,spread_nodes,spread_rates,basis,comp_type,comp_freq)
        % Calling pricing function with actual spread
        tmp_npv = pricing_npv(valuation_date,cashflow_dates, cashflow_values,x,discount_nodes, ...
                discount_rates,spread_nodes,spread_rates,basis,comp_type,comp_freq);
        obj = (act_value - tmp_npv).^2;
end
%------------------------------------------------------------------

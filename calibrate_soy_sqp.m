%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} { [@var{vola_spread}] =} calibrate_soy_sqp(@var{valuation_date}, @var{tmp_cashflow_dates}, @var{tmp_cashflow_values}, @var{tmp_act_value}, @var{tmp_nodes}, @var{tmp_rates}, @var{spread_nodes}, @var{spread_rates}, @var{basis}, @var{comp_type}, @var{comp_freq}, @var{,interp_discount}, @var{interp_spread})
%#
%# Calibrate the spread over yield according to given cashflows discounted on an 
%# appropriate yield curve.
%# @end deftypefn

function [spread_over_yield retcode] = calibrate_soy_sqp(valuation_date, ...
                tmp_cashflow_dates, tmp_cashflow_values,tmp_act_value, ...
                tmp_nodes,tmp_rates, basis,comp_type,comp_freq, ...
                interp_discount, comp_type_curve, basis_curve, comp_freq_curve)

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
  comp_type_curve  = comp_type;
  basis_curve      = basis; 
  comp_freq_curve  = comp_freq;
elseif  ( nargin == 8 )
  comp_type = 'disc';
  comp_freq = 1;
  interp_discount = 'linear';
  comp_type_curve  = comp_type;
  basis_curve      = basis; 
  comp_freq_curve  = comp_freq;
elseif ( nargin == 9 )
  comp_freq = 1;
  interp_discount = 'linear';
  comp_type_curve  = comp_type;
  basis_curve      = basis; 
  comp_freq_curve  = comp_freq;
elseif ( nargin == 10 )
  interp_discount = 'linear';   
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
elseif ( nargin > 13)
    error('Too many arguments')
end
if ( rows(tmp_cashflow_values) > 1 )
	tmp_cashflow_values = tmp_cashflow_values(1,:);
	fprintf('WARNING: More than one cash flow value scenario provided.')
    fprintf('Taking only first scenario as base values')
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
[x, obj, info, iter] = fmincon (@ (x) phi_soy(x,valuation_date, ...
            tmp_cashflow_dates, tmp_cashflow_values,tmp_act_value, ...
            tmp_nodes,tmp_rates,basis,comp_type, comp_freq,interp_discount, ...
            comp_type_curve, basis_curve, comp_freq_curve), x0,[], [], [], [], -1, 1);

if (info == 1)
	%fprintf ('+++ calibrate_soy_sqp: SUCCESS: First-order optimality measure and maximum constraint violation was less than default values. +++\n');
elseif (info == 0)
	fprintf ('--- calibrate_soy_sqp: WARNING: BS Number of iterations or function evaluations exceeded default values. ---\n');
    retcode = 255;
elseif (info == -1)
	fprintf ('--- calibrate_soy_sqp: WARNING: BS Stopped by an output function or plot function. ---\n');
    retcode = 255;
elseif (info == -2)
    fprintf ('--- calibrate_soy_sqp: WARNING: BS No feasible point was found. ---\n');
    retcode = 255;
elseif (info == 2)
	%fprintf ('+++ calibrate_soy_sqp: SUCCESS: Change in x and maximum constraint violation was less than default values. +++\n');
else
	fprintf ('--- calibrate_soy_sqp: WARNING: BS Optimization did not converge! ---\n');
    retcode = 255;
end

% return spread over yield
spread_over_yield = x;

end 

%-------------------------------------------------------------------------------
%------------------- Begin Subfunctions ----------------------------------------
 
% Definition Objective Function for spread over yield:	    
function obj = phi_soy (x,valuation_date,cashflow_dates, cashflow_values, ...
                        act_value,discount_nodes, discount_rates, basis, ...
                        comp_type, comp_freq, interp_discount, ...
                        comp_type_curve, basis_curve, comp_freq_curve)
        % Calling pricing function with actual spread
        tmp_npv = pricing_npv(valuation_date,cashflow_dates, cashflow_values,x, ...
                discount_nodes, discount_rates,basis,comp_type,comp_freq, ...
                interp_discount, comp_type_curve, basis_curve, comp_freq_curve);
        obj = (act_value - tmp_npv).^2;
end
%------------------------------------------------------------------

%!assert(calibrate_soy_sqp(datenum('31-Dec-2015'),[182,547,912],[3,3,103],99.9,[90,365,730,1095],[0.01,0.02,0.025,0.028],3,'discrete','annual','monotone-convex'),0.0103811242758234,0.0000001)                

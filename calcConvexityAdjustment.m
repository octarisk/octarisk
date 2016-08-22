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
%# @deftypefn {Function File} {[@var{adj_rate} @var{adj}] =} calcVolaShock (@var{valuation_date}, @var{r}, @var{sigma}, @var{t1}, @var{t2}, @var{basis}, @var{comp_type})
%#
%# Return convexity adjustment to a given forward rate with specified forward
%# start and end dates and forward volatility. @*
%# Implementation according to H.P. Deutsch, Derivate und Interne Modelle, 
%# 4th Edition, Section 14.5 Convexity Adjustment.
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{valuation_date}: valuation date [required] 
%# @item @var{r}: forward rate [required] 
%# @item @var{sigma}: forward volatility (act/365 continuous) [required] 
%# @item @var{t1}: forward start date [required] 
%# @item @var{t2}: forward end date [required] 
%# @item @var{basis}: day count convention of instrument [optional]
%# @item @var{comp_type}: compounding type: [simple, disc, cont] (string) [optional]
%# @item @var{adj_rate}: OUTPUT: adjusted forward rate
%# @item @var{adj}: OUTPUT: adjustment only
%# @end itemize
%#
%# @seealso{timefactor}
%# @end deftypefn

function [adj_rate adj] = calcConvexityAdjustment(valuation_date,r,sigma,t1,t2,basis,comp_type)

% Error and input checks
 if nargin < 5 || nargin > 7
    print_usage ();
 end
 
if nargin < 6
   basis = 3;
   comp_type = 'cont';
end
if nargin < 7
   comp_type = 'cont';
end

if ~isnumeric(r)
    error('calcConvexityAdjustment: Rate r is not a valid number')
end
if ischar(valuation_date) 
   valuation_date = datenum(valuation_date);
end
if ~isnumeric(sigma) || sigma < 0
    error('calcConvexityAdjustment: Volatility sigma is not a valid number')
end

% calculate timefactors
tau = timefactor(valuation_date + t1, valuation_date + t2, basis);
Tminust = timefactor(valuation_date, valuation_date + t1, basis);

% calculate convexity adjustment according to compounding type
if regexpi(comp_type,'cont')
    adj = 0.5 .* r.^2 * sigma.^2 .* Tminust .* tau;
elseif regexpi(comp_type,'disc')
    adj = 0.5 .* r.^2 * sigma.^2 .* Tminust .* tau .* (tau + 1) ./ (1 + r);
elseif  regexpi(comp_type,'simp') || regexpi(comp_type,'smp')
    adj = r.^2 .* sigma.^2 .* Tminust .* tau  ./ (1 + tau .* r);
else  % e.g. linear compounding -> interest rate equals tradeable 
      % linear combination of money and ZCB -> no adjustment required
    adj = 0;
end

% calculate total forward rate incl. convexity adjustment:
adj_rate = r + adj;

end

%!assert(calcConvexityAdjustment('31-Dec-2015',0.0100501670841679,0.8,1095,1460,3,'simple'),0.0102421686841733,0.00000001);
%!assert(calcConvexityAdjustment('31-Dec-2015',0.0100501670841679,0.8,1460,1825,3,'simple'),0.0103061692175084,0.00000001);
%!assert(calcConvexityAdjustment('31-Dec-2015',0.01000,0.8,1460,1825,3,'cont'),0.0101280000000000,0.00000001);
%!assert(calcConvexityAdjustment('31-Dec-2015',0.01000,0.8,1460,1825),0.0101280000000000,0.00000001); 
%!assert(calcConvexityAdjustment('31-Dec-2015',0.01000,0.8,1460,1825,3),0.0101280000000000,0.00000001);
%!error(calcConvexityAdjustment('31-Dec-2015',0.01000,-0.1,1460,1825,3));
%!error(calcConvexityAdjustment('31-Dec-2015',0.01000,0.4,1825,1460,3));
%!error(calcConvexityAdjustment('31-Dec-2015',0.01000,0.8,1460));
%!assert(calcConvexityAdjustment('31-Dec-2015',0.0100501670841682,0.00555,1460,1825,3,'simple'),0.0100501794052708,0.00000001);
%!assert(calcConvexityAdjustment('31-Dec-2015',0.0100501670841679,0.00555,1095,1460,3,'simple'),0.0100501763249950,0.00000001);
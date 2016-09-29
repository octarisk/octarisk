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
%# @deftypefn {Function File} {[@var{adj_rate} @var{adj}] =} calcVolaShock (@var{valuation_date}, @var{model}, @var{r}, @var{sigma}, @var{t1}, @var{t2}, @var{basis}, @var{comp_type})
%#
%# Return convexity adjustment to a given forward rate with specified forward
%# start and end dates and forward volatility. @*
%# Implementation of log-normal convexity adjustment according to H.P. Deutsch, 
%# Derivate und Interne Modelle, 4th Edition, Section 14.5 Convexity Adjustment.
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{valuation_date}: valuation date [required] 
%# @item @var{instrument}: instrument struct or object (with model, basis) [required] 
%# @item @var{r}: forward rate [required] 
%# @item @var{sigma}: forward volatility (act/365 continuous) [required] 
%# @item @var{t1}: forward start date [required] 
%# @item @var{t2}: forward end date [required] 
%# @item @var{adj_rate}: OUTPUT: adjusted forward rate
%# @item @var{adj}: OUTPUT: adjustment only
%# @end itemize
%#
%# @seealso{timefactor}
%# @end deftypefn

function [adj_rate adj] = calcConvexityAdjustment(valuation_date,instrument,r,sigma,t1,t2)

% Error and input checks
 if nargin < 6 || nargin > 6
    print_usage ();
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

% get instrument related attributes for all models
basis       = instrument.basis;
comp_type   = instrument.compounding_type;
model       = instrument.model;
% calculate timefactors
tau = timefactor(valuation_date + t1, valuation_date + t2, basis);
Tminust = timefactor(valuation_date, valuation_date + t1, basis);
    
% calculate convexity adjustment according to model
if (strcmpi(model,'Black'))            % Log-Normal model 
    % calculate convexity adjustment according to compounding type
    % Source: H.P. Deutsch, Derivate und Interne Modelle, 4th Edition, 
    %         Section 14.5 Convexity Adjustment.
    if regexpi(comp_type,'cont')
        adj = 0.5 .* r.^2 .* sigma.^2 .* Tminust .* tau;
    elseif regexpi(comp_type,'disc')
        adj = 0.5 .* r.^2 .* sigma.^2 .* Tminust .* tau .* (tau + 1) ./ (1 + r);
    elseif  regexpi(comp_type,'simp') || regexpi(comp_type,'smp')
        adj = r.^2 .* sigma.^2 .* Tminust .* tau  ./ (1 + tau .* r);
    else  % e.g. linear compounding -> interest rate equals tradeable 
          % linear combination of money and ZCB -> no adjustment required
        adj = 0;
    end
elseif (strcmpi(model,'Normal'))            % Normal model
    % calculate convexity adjustment for CMS Caps / Floors
    if (strcmpi(instrument.sub_type,'CAP') || strcmpi(instrument.sub_type,'FLOOR'))
        K = instrument.strike;
        if (instrument.CapFlag == true)
            psi = 1;
        else
            psi = -1;
        end
        % calculate adjustment according to S. Schlenkrich's approximation of 
        % "Multi-Curve Convexity", 2015, SSRN 2667405, Appendix A.1, Formula 15
        adj = psi .* sigma.^2 .* tau .*  normcdf( psi .* ( r - K ) ./ ...
                                                    ( sigma .* sqrt(tau)));
    
    % calculate convexity adjustment for other instruments (e.g. CMS swaps)
    else
       % calculate convexity adjustment according to compounding type
        if regexpi(comp_type,'cont')
            adj = 0.5 .* sigma.^2 .* Tminust .* tau;
        elseif regexpi(comp_type,'disc')
            adj = 0.5 .* sigma.^2 .* Tminust .* tau .* (tau + 1) ./ (1 + r);
        elseif  regexpi(comp_type,'simp') || regexpi(comp_type,'smp')
            adj = sigma.^2 .* Tminust .* tau  ./ (1 + tau .* r);
        else  % e.g. linear compounding -> interest rate equals tradeable 
              % linear combination of money and ZCB -> no adjustment required
            adj = 0;
        end
    end
else    % all other models: not yet implemented
    adj = 0.0;
end

% calculate total forward rate incl. convexity adjustment:
adj_rate = r + adj;

end

%!shared i
%! i = struct();
%! i.model = 'Black';
%! i.basis = 3;
%! i.compounding_type = 'simple';
%!assert(calcConvexityAdjustment('31-Dec-2015',i,0.0100501670841679,0.8,1095,1460),0.0102421686841733,0.00000001);
%!assert(calcConvexityAdjustment('31-Dec-2015',i,0.0100501670841679,0.8,1460,1825),0.0103061692175084,0.00000001);
%!error(calcConvexityAdjustment('31-Dec-2015',i,0.01000,-0.1,1460,1825));
%!error(calcConvexityAdjustment('31-Dec-2015',i,0.01000,0.4,1825,1460));
%!error(calcConvexityAdjustment('31-Dec-2015',i,0.01000,0.8,1460));
%!assert(calcConvexityAdjustment('31-Dec-2015',i,0.0100501670841682,0.00555,1460,1825),0.0100501794052708,0.00000001);
%!assert(calcConvexityAdjustment('31-Dec-2015',i,0.0100501670841679,0.00555,1095,1460),0.0100501763249950,0.00000001);

%!shared k
%! k = struct();
%! k.model = 'Black';
%! k.basis = 3;
%! k.compounding_type = 'cont';
%!assert(calcConvexityAdjustment('31-Dec-2015',k,0.01000,0.8,1460,1825),0.0101280000000000,0.00000001); 

%!shared j
%! j = struct();
%! j.model = 'Black';
%! j.basis = 3;
%! j.compounding_type = 'disc';
%!assert(calcConvexityAdjustment('31-Dec-2015',j,0.01000,0.8,1460,1825),0.0102534653465347,0.00000001); 

%!shared n
%! n = struct();
%! n.model = 'Normal';
%! n.basis = 3;
%! n.sub_type = 'CMS';
%! n.compounding_type = 'cont';
%!assert(calcConvexityAdjustment('31-Dec-2015',n,0.01000,0.00555,1460,1825),0.010061605,0.00000001); 

%!shared m
%! m = struct();
%! m.model = 'Normal';
%! m.basis = 3;
%! m.compounding_type = 'disc';
%! m.strike = 0.01;
%! m.sub_type = 'Cap';
%! m.CapFlag = true;
%!assert(calcConvexityAdjustment('31-Dec-2015',m,0.01000,0.00555,1460,1825),0.01001540125,0.00000001); 
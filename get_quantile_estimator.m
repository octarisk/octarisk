%# Copyright (C) 2018 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{w}] =} get_quantile_estimator (@var{kernel}, @var{scenarios}, @var{vec}, @var{alpha}, @var{bandwidth})
%#
%# Compute the scenario weights based on various Kernels (e.g. Epanechnikov (ep), 
%# Harrell-Davis (hd) estimator, equal weights for a given bandwidth (ew) or
%# singular weight on quantile scenario (singular).
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{kernel}: Specify Kernel ('hd', 'ep', 'ew', 'singular')
%# @item @var{scenarios}: number of total scenarios
%# @item @var{vec}: scenarios, for which weighs shall be computed
%# @item @var{alpha}: quantile (e.g. 0.005) 
%# @item @var{bandwidth}: bandwidth around scenario quantile (+- scenarios, ep only)
%# @item @var{w}: OUTPUT: column vector with scenario weights
%# @end itemize
%# @end deftypefn

function w = get_quantile_estimator(kernel,scenarios,vec,alpha,bandwidth = 0)
if nargin < 4 || nargin > 5
    print_usage ();
end

if ~isnumeric (scenarios)
    error ('scenarios must be numeric ')
elseif ~isnumeric (bandwidth)
    error ('bandwidth must be numeric ')
elseif ~isnumeric (alpha)
    error ('alpha must be numeric ')  
elseif ( alpha > 1 || alpha < 0 )
    error ('alpha must be a level of significance between 0 and 1 ')
elseif (max(vec) > scenarios || length(vec) > scenarios)
    error ('Length of vec must be smaller or equal to number of scenarios')
end
    bandwidth = round(bandwidth);
if ( max(round(alpha * scenarios),1) - bandwidth < 0 ...
        || max(round(alpha * scenarios),1) + bandwidth > scenarios )
    error ('The bandwidth %d around the significant scenarios %d cannot exceed scenario numbers 1 and %d ',round(bandwidth / 2),max(round(alpha * scenarios),1),scenarios);
end

kernel = tolower(kernel);

switch (kernel)

  case {'harrell_davis' , 'harrelldavis' , 'hd' }
    w = harrell_davis_weight(scenarios,vec,alpha);

  case {'epanechnikov' , 'ep'}
    w = epanechnikov_weight(scenarios,bandwidth,alpha);
    w = w(vec);
    
  case {'equal_weight' , 'equalweight' , 'ew'}
    w = get_ew_weights(scenarios,bandwidth,alpha);
    w = w(vec);
    
  case {'delta', 'singular' }
    w = get_ew_weights(scenarios,0,alpha);
    w = w(vec); 
    
  otherwise
    error('get_quantile_estimator: %s not implemented.',kernel);
    
end % end switch

% return column vector
if rows(w) < columns(w)
    w = w';
end
  
end

% ##############################################################################
% Helper Function
function w = get_ew_weights(scenarios,bandwidth,alpha)
    scenweight = 1 / (2*bandwidth + 1);
    alpha_scen = max(round(alpha * scenarios),1);
    tt = 1:1:scenarios;
    w(tt) = scenweight;
    w(tt < (alpha_scen - bandwidth)) = 0.0;
    w(tt > (alpha_scen + bandwidth)) = 0.0;
    if ( abs(sum(w) - 1.0) > 100*eps)
        error('get_quantile_estimator::get_ew_weights:Something went wrong. Sum of weights not equal to 1.0: deviation %f',sum(w) - 1.0);
    end
end

% ##############################################################################
%!test
%! tt = 1:50000;
%! ep_vec = get_quantile_estimator('ep',50000,tt,0.005,125);
%! assert(ep_vec(250),5.975969141323312e-003,eps*100);
%! assert(sum(ep_vec),1.0,eps*100);

%!test
%! tt = 1:50000;
%! hd_vec = get_quantile_estimator('hd',50000,tt,0.005,125);
%! assert(hd_vec(250),0.02531990008091822,eps*100);
%! assert(sum(hd_vec),1.0,eps*100);

%!test
%! tt = 1:50000;
%! ew_vec = get_quantile_estimator('ew',50000,tt,0.005,124);
%! assert(ew_vec(250),4.016064257028112e-003,eps*100);
%! assert(sum(ew_vec),1.0,eps*100);

%!test
%! tt = 1:50000;
%! ew_vec = get_quantile_estimator('singular',50000,tt,0.005,124);
%! assert(ew_vec(250),1,eps*100);
%! assert(sum(ew_vec),1.0,eps*100);

%Manual tests:
% pkg load statistics;
% scenarios  = 50000
% alpha    = 0.005
% ii = 100 :  400;
% bandwidth = 50
% hd_vec = get_quantile_estimator('hd',scenarios,ii,alpha);
% ep_vec = get_quantile_estimator('ep',scenarios,ii,alpha,bandwidth);
% ew_vec = get_quantile_estimator('ew',scenarios,ii,alpha,bandwidth);
% sing_vec = get_quantile_estimator('singular',scenarios,ii,alpha);
% figure(1);
% clf;
% plot ( ii, hd_vec, 'r' );
% hold on;
% plot ( ii, ep_vec, 'g' );
% hold on;
% plot ( ii, ew_vec, 'b' );
% hold on;
% plot ( ii, sing_vec, 'm' );
% legend ('Harrell-Davis Estimator','Epanechnikov Weights','Equal Weight', 'Singular Weight');

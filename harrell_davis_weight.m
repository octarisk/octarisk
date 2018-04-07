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
%# @deftypefn {Function File} {[@var{X}] =} harrell_davis_weight (@var{scenarios}, @var{observation}, @var{alpha})
%#
%# Compute the Harrell-Davis (1982) quantile estimator and jacknife standard errors of quantiles. 
%# The quantile estimator is a weighted linear combination or order statistics in which the order statistics used 
%# in traditional nonparametric quantile estimators are given the greatest weight. In small samples the H-D estimator 
%# is more efficient than traditional ones, and the two methods are asymptotically equivalent. 
%# The H-D estimator is the limit of a bootstrap average as the number of bootstrap resamples becomes infinitely large. 
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{scenarios}: number of total scenarios
%# @item @var{observation}: input vector for which HD weights shall be calculated
%# @item @var{alpha}: quantile (e.g. 0.005) 
%# @item @var{X}: OUTPUT: HD-weight corresponding to observation vector
%# @end itemize
%# @end deftypefn

function X = harrell_davis_weight(scenarios,observation,alpha)
% ############################################################################################
% #                                  Harrell-Davis Estimator                                 #
% ############################################################################################
  if nargin < 3 || nargin > 3
    print_usage ();
  end
   
  if ~isnumeric (scenarios)
    error ('scenarios must be numeric ')
  elseif ~isnumeric (observation)
    error ('observation must be numeric ')
  elseif ~isnumeric (alpha)
    error ('alpha must be numeric ')  
  elseif ( alpha > 1 || alpha < 0 )
    error ('alpha must be a level of significance between 0 and 1 ')
  end

    % Calculating the Weights of the Beta Distribution
    a = ( scenarios + 1 ) * alpha;
    b = ( scenarios + 1 ) * ( 1 - alpha);
    x_1 = observation ./ scenarios;
    x_2 = (observation - 1 ) ./ scenarios;
    beta_1 = betainc_vec( x_1' , a , b );
    beta_2 = betainc_vec( x_2' , a , b );
    X = beta_1 - beta_2;
    
end

%!test
%! hd_vec = harrell_davis_weight(600,1:3,0.005);
%! assert(hd_vec,[ 0.0796170388679505;0.2425460273970582;0.2540220601759450],1e-12);

%# Tests:
%scenarios  = 50000
%alpha    = 0.01
% ii = 250 :  750;
% hd_vec = harrell_davis_weight(scenarios,ii,alpha);
% figure(1);
% clf;
% plot ( ii, hd_vec, 'r' );
% title ('Harrell-Davis Estimator');


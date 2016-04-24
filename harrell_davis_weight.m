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
%# @deftypefn {Function File} {} harrell_davis_weight (@var{scenarios}, @var{observation}, @var{alpha})
%#
%# Compute the Harrell-Davis (1982) quantile estimator and jacknife standard errors of quantiles. 
%# The quantile estimator is a weighted linear combination or order statistics in which the order statistics used 
%# in traditional nonparametric quantile estimators are given the greatest weight. In small samples the H-D estimator 
%# is more efficient than traditional ones, and the two methods are asymptotically equivalent. 
%# The H-D estimator is the limit of a bootstrap average as the number of bootstrap resamples becomes infinitely large. 
%#
%# @end deftypefn

function X = harrell_davis_weight(scenarios,observation,alpha)
% %#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#
% #                                  Harrell-Davis Estimator                                 #
% %#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#
  if nargin < 3 || nargin > 3
    print_usage ();
  endif
   
  if ! isnumeric (scenarios)
    error ('scenarios must be numeric ')
  elseif ! isnumeric (observation)
    error ('observation must be numeric ')
  elseif ! isnumeric (alpha)
    error ('alpha must be numeric ')  
  elseif ( alpha > 1 || alpha < 0 )
    error ('alpha must be a level of significance between 0 and 1 ')
  endif

    % Calculating the Weights of the Beta Distribution
    a = ( scenarios + 1 ) * alpha;
    b = ( scenarios + 1 ) * ( 1 - alpha);
    x_1 = observation ./ scenarios;
    x_2 = (observation .- 1 ) ./ scenarios;
    beta_1 = betacdf( x_1 , a , b );
    beta_2 = betacdf( x_2 , a , b );
    X = beta_1 .- beta_2;
    
endfunction

%# Tests:
%scenarios  = 50000
%alpha    = 0.01
% ii = 250 :  750;
% hd_vec = harrell-davis-weight(scenarios,ii,alpha);
% figure(1);
% clf;
% plot ( ii, hd_vec, 'r' );
% title ('Harrell-Davis Estimator');


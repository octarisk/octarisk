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
%# @deftypefn {Function File} {[@var{X}] =} epanechnikov_weight (@var{scenarios}, @var{bandwidth}, @var{alpha})
%#
%# Compute the scenario weights based on the Epanechnikov  Kernel (1969)
%# quantile estimator. The Epanechnikov Kernel has the highest efficiency of 
%# all kernels.
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{scenarios}: number of total scenarios
%# @item @var{bandwidth}: bandwidth around scenario quantile (+- scenarios)
%# @item @var{alpha}: quantile (e.g. 0.005) 
%# @item @var{X}: OUTPUT: EP-weight column vector
%# @end itemize
%# @end deftypefn

function X = epanechnikov_weight(scenarios,bandwidth,alpha)
% ##############################################################################
% #                                  Epanechnikov Estimator                    #
% ##############################################################################
  if nargin < 3 || nargin > 3
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
  end
  bandwidth = round(bandwidth);
  if ( max(round(alpha * scenarios),1) - round(bandwidth) < 0 ...
            || max(round(alpha * scenarios),1) + round(bandwidth) > scenarios )
    error ('The bandwidth %d around the significant scenarios %d cannot exceed scenario numbers 1 and %d ',round(bandwidth / 2),max(round(alpha * scenarios),1),scenarios);
  end

  % Calculating the Weights 
  
  observation = 1:1:scenarios;
  h = (bandwidth + 0.5) / scenarios;
  x_1 = observation ./ scenarios;
  x_2 = (observation - 1 ) ./ scenarios;

  K_1 = ep_kernel(x_1,alpha,h);
  K_2 = ep_kernel(x_2,alpha,h);
  X = K_1' - K_2';
  
  if ( abs(sum(X) - 1.0) > 10*eps)
    error('Something went wrong. Sum of weights not equal to 1.0: deviation %f',sum(X) - 1.0);
  end
  
end

% Helper Kernel Function:
function K = ep_kernel(x,p,h);
      K = 0.5 + 0.75 .*(x - p) ./ h - 0.25 .* ((x - p) ./ h).^3;
      llimit = p - h;
      ulimit = p + h;
      K(x<=llimit)=0.0;
      K(x>=ulimit)=1.0;
end      

%!test
%! ep_vec = epanechnikov_weight(50000,125,0.005);
%! assert(ep_vec(250),5.975969141323312e-003,eps*10);
%! assert(sum(ep_vec),1.0,eps*10);

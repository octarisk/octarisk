%# Copyright (C) 2017 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} { [@var{calibrated_value} @var{retcode}] =} calibrate_generic(@var{objf}, @var{x0}, @var{lb}, @var{ub}) 
%#
%# Calibrate a given objective function according to start parameter and bounds.
%# This function calls the generic optimizer fmincon.
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{objf}: pointer to objective function
%# @item @var{x0}: start value
%# @item @var{lb}: lower bound
%# @item @var{ub}: upper bound
%# @end itemize
%# @seealso{fmincon}
%# @end deftypefn

function [calibrated_value retcode] = calibrate_generic(objf,x0,lb,ub)

if nargin < 2
    x0 = 0.0;
    lb = [];
    ub = [];
end
if nargin < 3
    lb = [];
    ub = [];
end
if nargin < 4
    ub = [];
end

options(1) = 0;
options(2) = 1e-5;
retcode = 0;

% Calculate generic objective function
[x, obj, info, iter] = fmincon (objf, x0, [], [], [], [], lb, ub);

if (info == 1)
    %fprintf ('+++ calibrate_generic: SUCCESS: First-order optimality measure and maximum constraint violation was less than default values. +++\n');
elseif (info == 0)
    fprintf ('--- calibrate_generic: WARNING: BS Number of iterations or function evaluations exceeded default values. ---\n');
    x = -99;
    retcode = 255;
elseif (info == -1)
    fprintf ('--- calibrate_generic: WARNING: BS Stopped by an output function or plot function. ---\n');
    x = -99;
    retcode = 255;
elseif (info == -2)
    fprintf ('--- calibrate_generic: WARNING: BS No feasible point was found. ---\n');
    x = -99;
    retcode = 255;
elseif (info == 2)
    %fprintf ('+++ calibrate_generic: SUCCESS: Change in x and maximum constraint violation was less than default values. +++\n');
else
    fprintf ('--- calibrate_generic: WARNING: BS Optimization did not converge! ---\n');
    retcode = 255;
    x = -99;
end

% return calibrated value
calibrated_value = x;

end 

%!test
%! [x retcode] = calibrate_generic(@(x)(x-1)^2-1,[0.5],-2,2);
%! assert(x,1.0,sqrt(eps))
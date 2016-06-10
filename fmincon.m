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
%# @deftypefn {Function File} { [@var{x} @var{obj} @var{info} @var{iter} @var{nf} @var{lambda}] =} fmincon(@var{objf}, @var{x0}, @var{A}, @var{b}, @var{Aeq}, @var{beq}, @var{lb}, @var{ub})
%# Direct Matlab function call fmincon to Octave non-linear solver sqp.
%# Only basic non-linear solver without boundary conditions is supported.
%# Return values are also mapped to fmincon expected return values.
%# @end deftypefn


function [x, obj, info, iter, nf, lambda] = fmincon (objf,x0,A,b,Aeq,beq,lb,ub)
% Wrapper function for Matlab compatibility 
cef = [];
cif = [];
maxiter = 300;
tolerance = [];
[x, obj, info, iter, nf, lambda] = sqp (x0, objf, cef, cif, lb, ub, maxiter, tolerance);

% map return codes for Matlab compatibility
% 101 -> normally -> 1
if info == 101
    info = 1;
    
% 102 -> BFGS update failed -> -1 
elseif info == 102
    info = -1;
    
% 103 -> max number iterations reached -> 0
elseif info == 103
    info = 0;

% 104 -> stepsize has become too small -> 2   
elseif info == 104
    info = 2;

% else
else 
    info = -3;
end

end
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
%# Wrap basic functionality of Matlab's solver fmincon to Octave's sqp. @*
%# Non-linear constraint functions provided by fmincon's function handle 
%# @code{nonlincon} are NOT processed. @*
%# Return codes are also mapped according to fmincon expected return codes. 
%# Note: This function mimics the behaviour of fmincon only.@*
%# In order to speed up minimizing, a bounded minimization algorithm fminbnd
%# is used in a first try. If this fails, sqp algorithm is called.
%# 
%# Matlab:
%# @example
%# @group
%# A*x <= b
%# Aeq*x = beq
%# lb <= x <= ub
%# @end group
%# @end example
%# Octave: 
%# @example
%# @group
%# g(x) = -Aeq*x + beq = 0
%# h(x) = -A*x + b >= 0
%# lb <= x <= ub
%# @end group
%# @end example
%# See the following example:
%# @example
%# @group
%# [x obj info iter] = fmincon (@@(x)100*(x(2)-x(1)^2)^2 + (1-x(1))^2,[0.5,0],[1,2],1,[2,1],1)
%# x = [0.41494,0.17011]
%# obj =  0.34272
%# info =  1
%# iter =  6
%# @end group
%# @end example
%# Explanation of Input Parameters:
%# @*
%# @itemize @bullet
%# @item @var{objf}: pointer to objective function
%# @item @var{x0}: initial values
%# @item @var{A}: inequality constraint matrix
%# @item @var{b}: inequality constraint vector
%# @item @var{Aeq}: equality constraint matrix
%# @item @var{beq}: equality constraint vector
%# @item @var{lb}: lower bound (required for fminbnd, defaults to -10)
%# @item @var{ub}: upper bound (required for fminbnd, defaults to 10)
%# @end itemize
%# @seealso{sqp}
%# @end deftypefn

function [x, obj, info, iter, nf, lambda] = fmincon (objf,x0,A,b,Aeq,beq,lb,ub)
% Wrapper function for Matlab compatibility 

maxiter = 300;
tolerance = 0.0001; %sqrt(eps);
iter = [];
nf = [];
lambda = [];

if nargin < 3
    A = [];
    b = [];
    Aeq = [];
    beq = [];
    lb = [];
    ub = [];
end

if nargin < 5
    Aeq = [];
    beq = [];
    lb = [];
    ub = [];
end

if nargin < 7
    lb = [];
    ub = [];
end

% Specify gradiant and Hessian equations:
if ~( isempty(A) && isempty(b) )
    h = @(x) -A *x+b;
else
    h = [];
end
if ~( isempty(Aeq) && isempty(beq) )
    g = @(x) -Aeq *x+beq;
else
    g = [];
end

% 1st try: Call Octave fminbnd solver (faster algorithm)
try
    options = optimset ('MaxIter',maxiter,'TolX',sqrt(eps));
    if isempty(ub)
        ub = 10;
    end
    if isempty(lb)
        lb = -10;
    end
    [x, obj, info, output]  = fminbnd (objf, lb , ub, options);
catch
    info = 0;
end

% 2nd try: in case of no solution, call unbounded nonlinear solver
if ~(info == 1)
    % Call Octave sqp solver:
    [x, obj, info, iter, nf, lambda] = sqp (x0, objf, g, h, lb, ub, maxiter, tolerance);

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

% return values
end
%!assert(fmincon (@(x)100*(x(2)-x(1)^2)^2 + (1-x(1))^2,[0.5,0],[1,2],1,[2,1],1),[0.41494;0.17011],0.0001)


% % #############      Call Octave fmin  ########################################


% options = optimset ('MaxIter',maxiter,'TolFun',tolerance,'TolX',sqrt(eps));
% tic
% [x, obj, info] = fminunc (objf, x0, options);
% fminunc_time = toc
% fprintf('Soy: >>%f<< Obj: >>%f<<\n',x,obj);
% info
% if ( info == 2)
    % info = 1;
% end
% iter = [];
% nf = [];
% lambda = [];


% % ############# Call Octave fminbnd   ##########################################

% a = lb;
% b = ub;
% options = optimset ('MaxIter',maxiter,'TolX',sqrt(eps));
% tic
% [x, obj, info, output]  = fminbnd (objf, a , b, options);
% fminbnd_time  = toc
% fprintf('Soy: >>%f<< Obj: >>%f<<\n',x,obj);
% info
% iter = [];
% nf = [];
% lambda = [];
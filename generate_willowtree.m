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
%# @deftypefn {Function File} {@var{value} =} generate_willowtree (@var{N}, @var{dk}, @var{z_method}, @var{willowtree_save_flag}, @var{path_static})
%#
%# Computes the willow tree used e.g. for option pricing.@*
%# The willow tree is used as a lean and accurate option pricing lattice.
%# This implementation of the willow tree concept is based on following
%# literature:
%# @itemize @bullet
%# @item 'Willow Tree', Andy C.T. Ho, Master thesis, May 2000
%# @item 'Willow Power: Optimizing Derivative Pricing Trees', Michael Curran, 
%# ALGO RESEARCH QUARTERLY, Vol. 4, No. 4, December 2001
%# @end itemize
%#
%# Number of nodes must be in list [10,15,20,30,40,50]. These vectors are 
%# optimized by Currans Method to fulfill variance constraint (default: 20)
%#
%# Variables:
%# @itemize @bullet
%# @item @var{N}: Number of timesteps in tree
%# @item @var{dk}: timestep size of tree
%# @item @var{z_method}: number of nodes per timestep
%# @item @var{willowtree_save_flag}: boolean variable for saving tree to file
%# @item @var{path_static}: path to directory if file shall be saved
%# @item @var{Transition_matrix}: [output] optimized transition probabilities 
%# ("the Tree")
%# @item @var{z}: [output] Z(0,1) distributed random variables used in tree
%# @end itemize
%# @seealso{option_willowtree}
%# @end deftypefn


function [Transition_matrix z] = generate_willowtree(N,dk,z_method,willowtree_save_flag,path_static)

 if nargin < 5 || nargin > 5
    print_usage ();
 end

if ~isnumeric (z_method)
    error ('number of z_method nodes must be numeric ')     
elseif ~isnumeric (dk)
    error ('stepsize in days (dk) must be numeric ') 
elseif ( dk < 0)
    error ('stepsize in days (dk)  must be positive ')  
elseif ~isnumeric(N) || N < 0
    error ('Number of timesteps N must be a positive integer')    
end

% Vectors with z-values 
% solver optimization: (qi' * z_i^2) = 1 for n =10,15,20,30,40,50. Only z(1) 
% and z(n) have been adjusted to fulfill variance = 1 condition.
z_10 = [
-1.818408193,-1.036433389,-0.67448975,-0.385320466,-0.125661347,0.125661347, ...
0.385320466,0.67448975,1.036433389,1.818408193
];
z_15 = [
-2.019979732,-1.318010897,-1.009990169,-0.776421761,-0.579132162, ...
-0.402250065,-0.237202109,-0.078412413,0.078412413 ...
,0.237202109,0.402250065,0.579132162,0.776421761,1.009990169, ...
1.318010897,2.019979732
];
z_20 = [
-2.110897894,-1.439531471,-1.15034938,-0.934589291,-0.755415026, ...
-0.597760126,-0.45376219,-0.318639364,-0.189118426 ...
,-0.062706778,0.062706778,0.189118426,0.318639364,0.45376219,0.597760126, ...
0.755415026,0.934589291,1.15034938,1.439531471 ...
,2.110897894
];
z_30 = [
-2.269187459,-1.644853627,-1.382994127,-1.191816172,-1.036433389, ...
-0.902734792,-0.783500375,-0.67448975, ...
-0.572967548,-0.477040428,-0.385320466,-0.296737838,-0.210428394, ...
-0.125661347,-0.041789298,0.041789298, ...
0.125661347,0.210428394,0.296737838,0.385320466,0.477040428,0.572967548, ...
0.67448975,0.783500375,0.902734792, ...
1.036433389,1.191816172,1.382994127,1.644853627,2.269187459
];
z_40 = [
-2.518840503,-1.780464342,-1.534120544,-1.356311745,-1.213339622, ...
-1.091620367,-0.98423496,-0.887146559, ...
-0.797776846,-0.71436744,-0.635657014,-0.560703032,-0.488776411, ...
-0.419295753,-0.351784345,-0.285840875, ...
-0.221118713,-0.157310685,-0.094137414,-0.031337982,0.031337982, ...
0.094137414,0.157310685,0.221118713, ...
0.285840875,0.351784345,0.419295753,0.488776411,0.560703032, ...
0.635657014,0.71436744,0.797776846, ...
0.887146559,0.98423496,1.091620367,0.98423496,1.213339622, ...
1.356311745,1.780464342,2.518840503
];
z_50 = [
-2.510808322,-1.880793608,-1.644853627,-1.475791028,-1.340755034, ...
-1.22652812,-1.126391129,-1.036433389, ...
-0.954165253,-0.877896295,-0.806421247,-0.738846849,-0.67448975, ...
-0.612812991,-0.55338472,-0.495850347, ...
-0.439913166,-0.385320466,-0.331853346,-0.279319034,-0.227544977, ...
-0.176374165,-0.125661347,-0.075269862, ...
-0.025068908,0.025068908,0.075269862,0.125661347,0.176374165,0.227544977, ...
0.279319034,0.331853346,0.385320466, ...
0.439913166,0.495850347,0.55338472,0.612812991,0.67448975,0.738846849, ...
0.806421247,0.738846849,0.877896295, ...
0.954165253,1.126391129,1.22652812,1.340755034,1.475791028,1.644853627, ...
1.880793608,2.510808322
];
% getting desired z vector:
if ( z_method == 10)
    z = z_10';
elseif ( z_method == 15 )
    z = z_15';   
elseif ( z_method == 20 )
    z = z_20';
elseif ( z_method == 30 )
    z = z_30';   
elseif ( z_method == 40 )
    z = z_40';
elseif ( z_method == 50 )
    z = z_50';
else
    z = z_20'; %default 20 nodes
end

% Calculate equally distributed values for q
n = length(z);
q = ones(n,1) ./n; 
% for convenience, transpose vector
zi = z';
zj = z;




%-------------------------------------------------------------------------
%           Generation of the Willow Tree via Optimization
%-------------------------------------------------------------------------
% check whether there exists an optimized transition matrix for the set of 
% timesteps, nodes and stepsize (N,n,dk)
tmp_filename = strcat(path_static,'/wt_transition_',num2str(N), ...
                    '_',num2str(n),'_',num2str(dk),'.mat');        
if ( willowtree_save_flag == 1 && exist(tmp_filename,'file'))
  %fprintf('Taking file >>%s<< with WT transition matrix.\n',tmp_filename);
  tmp_load_struct = load(tmp_filename);
  Transition_matrix = tmp_load_struct.Transition_matrix;
else % Iterating through the time nodes to optimize transition matrizes 
  % loop through all timesteps and optimize transition probabilities
  for ii = 1 : 1 : (N-1)    
    h = dk;             % constant time steps only
    tk = ii .* h;
    alpha = h / tk;
    beta = 1 ./sqrt(1+alpha);
    F = abs(zj - beta .* zi).^3;
    F = reshape(F,1,n^2);
    p = [1:n^2];
    u = ones(n,1);
    r = z.^2;

    % constraints:
    b = [];
    A = [];
    btmp = [];
    
    % 1) Pu = u -> unity vector
        B = zeros(n,n^2);
        for i = 1:1:n
            B(i,:) = [ zeros(1,(i-1)*n), ones(1,n) , zeros(1,n^2-i*n) ];
            btmp(i) = 1;
        end
        b = [b;btmp'];
        A = [A;B];

    % 2) Pz = bz 
        B = zeros(n,n^2);
        for i = 1:1:n
            B(i,:) = [ zeros(1,(i-1)*n), zi , zeros(1,n^2-i*n) ];
        end
        btmp = ones(n,1) .* beta .* zj; 
        b = [b;btmp];
        A = [A;B];

    % 3) Pr = b^2r + (1-b^2)u
        B = zeros(n,n^2);
        for i = 1:1:n
            B(i,:) = [ zeros(1,(i-1)*n), zi.^2 , zeros(1,n^2-i*n) ];
        end
        btmp = ones(n,1) .* ((beta^2 .* zj.^2) + (1 - beta.^2)) ;
        b = [b;btmp];
        A = [A;B];

    % 4) q'P = q'
        B = zeros(n,n^2);
        for i = 1:1:n
            B(i,:) = [ zeros(1,(i-1)*n), q' , zeros(1,n^2-i*n) ];
        end
        b = [b;q];
        A = [A;B];

    % Formulate Minimization Problem
    % min trace(PF)
        c = F;              % Cost coefficients
        A;              % Matrix of constraint coefficients
        b;                 % The right hand side of constraints
        lb = zeros(n^2,1);  % lower bound 
        ub = [];            % Upper bound 
        % char(83) = S: constraint type indicates equality 
        ctype = char(repmat(83,1,length(b))); 
        % Variable type C (=char(67)) continuous variable        
        vartype = char(repmat(67,1,n^2));   
        s = 1;              % sense = 1: minimization problem (1)
        % linear programming parameters:
        % Level of messages output by solver. 3 is full output. 
        % Default is 1 (errors and warning only).
        param.msglev = 1;   
        param.itlim = 100000;   % Simplex iterations limit
        % start optimization
        [xmin, fmin, errnum, extra] = glpk(c,A,b,lb,ub,ctype,vartype,s,param); 
        % reshape output to have transition vectors for each node in one column
        Pmin = reshape(xmin,n,n);   
         % transpose and append, ready for vector multiplication 
        Transition_matrix(:,:,ii) = Pmin';
  end   % end for loop for all steps of transition matrix
  if ( willowtree_save_flag == 1 )    % save transition matrix only if desired
    fprintf('Save Willowtree transition matrix to >>%s<< \n',tmp_filename);
    % save newly generated transition matrix for later use
    save ('-v7',tmp_filename,'Transition_matrix');   
  end
end     % end if loop, whether transition matrix shall be generated

end

%!test
%! [T z] = generate_willowtree(11,1,20,0,pwd);
%! assert(sum(sum(sum(T))),200,sqrt(eps))
%! assert(sum(z),0,sqrt(eps))
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
%# @deftypefn {Function File} {[@var{A_scaled} @var{pos_sem_def_bool}] =} correct_correlation_matrix(@var{M})
%# Return a positive semi-definite matrix @var{A_scaled} to a given input 
%# matrix @var{M}. This function tests for indefiniteness of the input matrix 
%# and eventuallry adjusts negative Eivenvalues to 0 or slightly positive values 
%# via some iteration steps.
%# @*
%# Reference: 'Implementing Value at Risk', Best, Philip W., 1998.
%# @end deftypefn

function [A_scaled pos_sem_def_bool]= correct_correlation_matrix(M)
fprintf('\n'); 
pos_sem_def_bool = testpsd(M);
if (pos_sem_def_bool == true)
    fprintf  ('Input matrix is positive semidefinite\n')
    A_scaled = M;
    return;
else
    fprintf ('Input matrix is not positive semidefinite. Starting correction.\n')
end
A_scaled = M;
limit = 0.0;
step = 0;
break_bool = 0;
while ( pos_sem_def_bool == 0 ) 
    %tic;
    %limit
    lambda_min = limitEV(A_scaled,limit);
    [V lambda] = eig(A_scaled);
    A = V * lambda_min * inv(V);
    A_scaled = rescale ( A );
    pos_sem_def_bool = testpsd(A_scaled);
    limit = step * 0.00000001;  
    step = step + 1;
    %toc;
    if ( step > 50 )
        break_bool = 1;
        break;
    end
end
if ( break_bool == 1 )
    fprintf ('!! Warning: No positive semidefinite solution was reached !!\n');
end
% Get final test statistics
    A_scaled_diff = A_scaled - M;
    %max(abs(A_scaled_diff));
    Max_diff = max(max(abs(A_scaled_diff)));
    %StdDev_diff = std(std(A_scaled_diff));
    Frobenius_Norm = norm(A_scaled_diff,'fro');
    %Max_Singular_Value_Norm = norm(A_scaled_diff);
%fprintf('Test statistics: \n');    
%fprintf('Standard deviation of delta:  %1.4f \n', StdDev_diff);
fprintf('Maximum correlation deviation: %1.4f \n', Max_diff);    
fprintf('Frobenius norm: %1.4f \n', Frobenius_Norm);
%fprintf(' Maximum singular value: %1.4f \n', Max_Singular_Value_Norm);
%fprintf('Algorithm converged after %d steps.\n', step);
pos_sem_def_bool =testpsd(A_scaled);
if (pos_sem_def_bool == true)
    fprintf ('Correction successful: Matrix is positive semidefinite.\n')
end
end
% %#%#%#%#%#%#%#%#%#%##    Helper Functions    %#%#%#%#%#%#%#%#%#%#

% Function for rescaling and symmetrizing
function res = rescale ( A )
    % columnwise rescaling to diagonal elements == 1
    Balance = diag(1./sqrt(diag(A)));
    A_scaled = Balance * A * Balance';
    % symmetrizing: taking lower triangular matrix and mirror values to 
    %               upper triangular matrix
    trilower = tril(A_scaled);
    %D = diag(trilower);
    [nr,nc]=size(trilower);
    triupper = trilower';
    res = trilower + triupper - eye(nc);
end

% set Eigenvalues to limit
function lambda = limitEV(M, limit)
    % get Eigenvalues and Eigenvectors
    [V lambda] = eig(M);
    lambda(lambda < 0 ) = limit;
end

% test matrix for positive semidefinitness
function pos_sem_def_bool = testpsd(M)
    [V lambda] = eig(M);
    pos_sem_def_bool = all( all ( lambda >= 0 ));
end

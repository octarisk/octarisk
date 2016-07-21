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
%# @deftypefn {Function File} {[@var{R} @var{distr_type} ] =} cenario_generation_MC (@var{corr_matrix}, @var{P}, @var{mc}, @var{copulatype}, @var{nu}, @var{time_horizon})
%#
%# Compute correlated random numbers according to Gaussian or Student-t copulas and
%# arbitrary marginal distributions within the Pearson distribution system.@*
%#
%# @seealso{get_marginal_distr_pearson, mvnrnd, normcdf, mvtrnd ,tcdf}
%# @end deftypefn

function [R distr_type] = scenario_generation_MC(corr_matrix,P,mc, ...
                            copulatype,nu,time_horizon,path_static,stable_seed)
% A) input data checks
[rr_c cc_c] = size(corr_matrix);
[pp_p cc_p] = size(P);
if ( cc_c ~= cc_p )
    error('octarisk::scenario_generation_MC: Numbers of risk factors and parameters does not match!');
end

% 1) Input Arguments checks
if nargin < 5
    nu = 10;
    time_horizon = 256;
end
if nargin < 6
    % assuming provided volatility and return are on yearly time horizon, 
    % will be scaled to time_horizon
    time_horizon = 256; 
end

if nargin < 7
    path_static = pwd;
    stable_seed = 0;
end

if nargin < 8
    stable_seed = 0;
end

% 2) Time horizon check
factor_time_horizon = 256 / time_horizon;

% 3) Test for positive semi-definiteness
fprintf('Testing correlation matrix for positive semi-definiteness:\n');
corr_matrix = correct_correlation_matrix(corr_matrix);

% B.1) Generating multivariate random variables if stable_seed is 0
    tmp_number_rf = rows(corr_matrix);  % get number of risk factors
    tmp_filename = strcat(path_static,'/random_numbers_',num2str(mc),'_', ...
                            num2str(tmp_number_rf),'_',copulatype,'.mat');
    % use existing random numbers                        
    if ( exist(tmp_filename,'file') && (stable_seed == 1))
        fprintf('Taking file >>%s<< with random numbers from static folder\n',tmp_filename);
        Y_struct = load(tmp_filename);  % read in from stored file
        Y = Y_struct.Y;
    % otherwise draw new random numbers and save to static folder for next run
    else 
        fprintf('New random numbers are drawn for %d MC scenarios and Copulatype %s.\n',mc,copulatype);
        if ( strcmp(copulatype, 'Gaussian') == 1 ) % Gaussian copula   
            % draw random variables from multivariate normal distribution
            Y   = mvnrnd(0,corr_matrix,mc);      
        elseif ( strcmp(copulatype, 't') == 1) % t-copula 
            % draw random variables from multivariate student-t distribution
            Y   = mvtrnd(corr_matrix,nu,mc);     
        end
        if (stable_seed == 1)
            save ('-v7',tmp_filename,'Y');
        end
    end

% B.2) Calculate cumulative distribution functions 
%      -> map t- or normdistributed random numbers to intervall [0,1]  
if ( strcmp(copulatype, 'Gaussian') == 1 ) % Gaussian copula   
    Z   = normcdf(Y,0,1);                % generate bivariate normal copula
elseif ( strcmp(copulatype, 't') == 1) % t-copula 
    Z   = tcdf(Y,nu);                   % generate bivariate normal copula
end

%     statistical checks:
% std_Y = std(Y)
% corr_Y = corr(Y)
% norm(abs(corr_Y - corr_matrix))


% C) Generate custom distributed random variables from 
%    correlated univariate randon numbers
R = zeros(mc,columns(corr_matrix));
distr_type = zeros(1,columns(Z));
% now loop via all columns of Z and apply individual marginal distribution
for ii = 1 : 1 : columns(Z);
    tmp_ucr = Z(:,ii);
    % mu needs geometric compounding adjustment
    tmp_mu      = P(1,ii) .^(1/factor_time_horizon); 
    % volatility needs adjustment with sqr(t)-rule 
    tmp_sigma   = P(2,ii) ./ sqrt(factor_time_horizon); 
    tmp_skew    = P(3,ii);
    tmp_kurt    = P(4,ii);
    %generate distribution based on Pearson System (Type 1-7)
    [ret_vec type]= get_marginal_distr_pearson(tmp_mu,tmp_sigma, ...
                                                tmp_skew,tmp_kurt,tmp_ucr); 
    distr_type(ii) = type;
    R(:,ii) = ret_vec;
end

end

%!test 
%! fprintf('HOLD ON...\n');
%! fprintf('\tscenario_generation_MC:\tGenerating MC scenarios\n');
%! pkg load statistics;
%! corr_matrix = [1,0.2,-0.3;0.2,1,0;-0.3,0.0,1];
%! P = [0,0,0;0.2,0.5,0.4;-0.3,0,0.3;3,1.5,4.5];
%! mc = 100000;
%! copulatype = 't';
%! nu = 4;
%! [R distr_type] = scenario_generation_MC(corr_matrix,P,mc,copulatype,nu,256);
%! assert(distr_type,[1,2,4])
%! mean_target = P(1,1);   % mean
%! mean_act = mean(R(:,1));
%! assert(mean_act,mean_target,0.01)
%! sigma_target = P(2,2);   % sigma
%! sigma_act = std(R(:,2));
%! assert(sigma_act,sigma_target,0.1)
%! skew_target = P(3,1);   % skew
%! skew_act = skewness(R(:,1));
%! assert(skew_act,skew_target,0.1)
%! kurt_target = P(4,3);   % kurt    
%! kurt_act = kurtosis(R(:,3));
%! assert(kurt_act,kurt_target,0.5)
%! pkg unload statistics;
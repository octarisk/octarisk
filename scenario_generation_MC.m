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
                            copulatype,nu,time_horizon,path_static,para_object)
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
end




% overwrite stable_seed setting --> always draw new random numbers.
% seed is set during octarisk startup, therefore the random numbers should be always the same automatically
stable_seed = para_object.stable_seed;
use_sobol  = para_object.use_sobol;
sobol_seed = para_object.sobol_seed;
filepath_sobol_direction_number = strcat(para_object.path_working_folder,...
							'/',para_object.path_sobol_direction_number, ...
							'/',para_object.filename_sobol_direction_number);

% 2) Time horizon check
factor_time_horizon = 256 / time_horizon;

% 3) Test for positive semi-definiteness
fprintf('Testing correlation matrix for positive semi-definiteness:\n');
corr_matrix = correct_correlation_matrix(corr_matrix);
new_corr = false;
% B.1) Generating multivariate random variables if stable_seed is 0
    tmp_number_rf = rows(corr_matrix);  % get number of risk factors
    tmp_filename = strcat(path_static,'/random_numbers_',num2str(mc),'_', ...
                            num2str(tmp_number_rf),'_',copulatype,'.mat');
    % use existing random numbers                        
    if ( exist(tmp_filename,'file') && (stable_seed == 1))
        fprintf('scenario_generation_MC: Taking file >>%s<< with random numbers from static folder\n',tmp_filename);
        Y_struct = load(tmp_filename);  % read in from stored file
        Y = Y_struct.Y;
		% test random numbers for matching correlation settings
		frob_norm = norm(abs(corr(Y) - corr_matrix));
		if (frob_norm > 0.05)
			fprintf('scenario_generation_MC: WARNING: Frobenius norm %s of correlation matrix drawn from random numbers minus correlation settings > 0.05. New random numbers will be drawn.\n',any2str(frob_norm));
			new_corr = true;
		end
    % otherwise draw new random numbers and save to static folder for next run
    else 
		new_corr = true;
    end
	
	% draw new random numbers
	if ( new_corr == true)
		dim = length(corr_matrix);
		if ( use_sobol == false)
			fprintf('scenario_generation_MC: New random numbers are drawn for %d MC scenarios and Copulatype %s.\n',mc,copulatype);
			randn_matrix = randn(mc,dim);
		else
			% generate Sobol numbers
			sobol_seed = max(sobol_seed,1);	% minimum Sobol seed = 1: first Sobol numbers 0.5
			fprintf('scenario_generation_MC: Use Sobol numbers with seed %d for %d MC scenarios and Copulatype %s.\n',sobol_seed,mc,copulatype);
			if ( dim > 21201)
				error('scenario_generation_MC: Sobol numbers only support up to 21201 dimensions. Use different Sobol generator or MC instead.');
			end
			sobol_matrix = calc_sobol_cpp(mc+sobol_seed,dim,filepath_sobol_direction_number);
			% remove all rows < seed
			sobol_matrix(1:sobol_seed,:) = [];
			% get standard normal distributed random numbers
			randn_matrix = norminv(sobol_matrix);
			% scale randn_matrix to get 0,1 distributed numbers (Sobol numbers
			% systematically underestimate standard deviation)
			randn_matrix = randn_matrix ./ std(randn_matrix);
		end
		
		% apply Copula
		if ( strcmp(copulatype, 'Gaussian') == 1 ) % Gaussian copula   
			% draw random variables from multivariate normal distribution
			Y   = mvnrnd_custom(zeros(1,dim),corr_matrix,mc,randn_matrix);  
		elseif ( strcmp(copulatype, 't') == 1) % t-copula 
			% draw random variables from multivariate student-t distribution
			Y   = mvtrnd_custom(corr_matrix,nu,mc,randn_matrix);     
		end
		if (stable_seed == 1)
			save ('-v7',tmp_filename,'Y');
		end
    end
	

% B.2) Calculate cumulative distribution functions 
%      -> map t- or normdistributed random numbers to intervall [0,1]  
if ( strcmpi(copulatype, 'Gaussian') ) % Gaussian copula   
    Z   = normcdf(Y,0,1);                % generate bivariate normal copula
elseif ( strcmpi(copulatype, 't')) % t-copula 
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

% ##############################################################################
% custom functions 
%# Copyright (C) 2003 Iain Murray
%# taken and modified from Octave's statistical package
function s = mvnrnd_custom(mu,sigma,n,randn_matrix);  

	mu = zeros(1,length(sigma));
	d = columns(sigma);
	tol=eps*norm (sigma, "fro");
	
	try
		U = chol (sigma + tol*eye (d),"upper");
	catch
		[E , Lambda] = eig (sigma);

		if min (diag (Lambda)) < -100*tol
		  error('sigma must be positive semi-definite. Lowest eigenvalue %g', ...
				min (diag (Lambda)));
		else
		  Lambda(Lambda<0) = 0;
		end
		warning ("mvnrnd:InvalidInput","Cholesky factorization failed. Using diagonalized matrix.")
		U = sqrt (Lambda) * E';
	end

	% draw univariate random numbers
	s = randn_matrix*U + mu;

end

% ##############################################################################
%# Copyright (C) 2012  Arno Onken <asnelt@asnelt.org>, Iñigo Urteaga
%# taken and modified from Octave's statistical package
function x = mvtrnd_custom (sigma, nu, n,randn_matrix)


  if (!isvector (nu) || any (nu <= 0))
    error ("mvtrnd: nu must be a positive scalar or vector");
  endif
  nu = nu(:);

  if (nargin > 2)
    if (! isscalar (n) || n < 0 | round (n) != n)
      error ("mvtrnd: n must be a non-negative integer")
    endif
    if (isscalar (nu))
      nu = nu * ones (n, 1);
    else
      if (length (nu) != n)
        error ("mvtrnd: n must match the length of nu")
      endif
    endif
  else
    n = length (nu);
  endif

  # Normalize sigma
  if (any (diag (sigma) != 1))
    sigma = sigma ./ sqrt (diag (sigma) * diag (sigma)');
  endif

  # Dimension
  d = size (sigma, 1);
  # Draw samples
  y = mvnrnd_custom (zeros (1, d), sigma, n, randn_matrix);
  u = repmat (chi2rnd (nu), 1, d);
  x = y .* sqrt (repmat (nu, 1, d) ./ u);
end


%!test 
%! fprintf('HOLD ON...\n');
%! fprintf('\tscenario_generation_MC:\tGenerating MC and Sobol scenarios with stable Seed and Gaussian Copula\n');
%! corr_matrix = [1,0.2,-0.3;0.2,1,0;-0.3,0.0,1];
%! P = [0,0,0;0.2,0.5,0.4;-0.3,0,0.3;3,1.5,4.5];
%! mc = 100000;
%! copulatype = 'Gaussian';
%! nu = 4;
%! para_object.stable_seed = 0;
%! para_object.use_sobol = false;
%! para_object.sobol_seed = 1;
%! para_object.path_working_folder = pwd;
%! para_object.path_sobol_direction_number = '';
%! para_object.filename_sobol_direction_number = '';						
%! rand('state',666 .*ones(625,1));	% set seed
%! randn('state',666 .*ones(625,1));	% set seed
%! [R distr_type] = scenario_generation_MC(corr_matrix,P,mc,copulatype,nu,256,[],para_object);
%! assert(distr_type,[1,2,4])
%! mean_target = P(1,1);   % mean
%! mean_act = mean(R(:,1));
%! assert(mean_act,mean_target,0.01)
%! sigma_target = P(2,2);   % sigma
%! sigma_act = std(R(:,2));
%! assert(sigma_act,sigma_target,0.01)
%! skew_target = P(3,1);   % skew
%! skew_act = skewness(R(:,1));
%! assert(skew_act,skew_target,0.06)
%! kurt_target = P(4,3);  % kurt    
%! kurt_act = kurtosis(R(:,3));
%! assert(kurt_act,kurt_target,0.03)

%# Copyright (C) 2016,2017,2018 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{R} @var{distr_type} @var{Z}] =} scenario_generation_MC (@var{corr_matrix}, @var{P}, @var{mc}, @var{copulatype}, @var{nu}, @var{time_horizon}, @var{path_static}, @var{para_object})
%#
%# Compute correlated random numbers according to Gaussian or Student-t copulas and
%# arbitrary marginal distributions within the Pearson distribution system.@*
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{corr_matrix}:   Correlation matrix
%# @item @var{P}:   matrix with statistical parameter (columns: risk factors, 
%# rows: four moments of distribution (mean, std, skew, kurt)
%# @item @var{mc}:   number of MC scenarios
%# @item @var{copulatype}:   t, Gaussian or Frank, Gumbel, Clayton (FGC)
%# @item @var{nu}:   degree of freedom (scalar for t, scalar or vector for FGC)
%# @item @var{time_horizon}:   time horizon in days (assumed 256 days in year)
%# @item @var{path_static}:   path to static files (e.g. random numbers)
%# @item @var{para_object}:   object with parameters (stable_seed, use_sobol, 
%# sobol_seed, path_working_folder, path_sobol_direction_number, 
%# filename_sobol_direction_number,frob_norm_limit)
%# @item @var{R}:    OUTPUT: scenario matrix (rows: scenarios, cols: risk factors)
%# @item @var{distr_type}:    OUTPUT: cell with marginal distribution types 
%# @item @var{Z}:    OUTPUT: copula dependence (uniform marginal distributions)
%# according to Pearson
%# @end itemize
%# @seealso{get_marginal_distr_pearson, mvnrnd, normcdf, mvtrnd ,tcdf}
%# @end deftypefn

function [R distr_type Z] = scenario_generation_MC(corr_matrix,P,mc, ...
                            copulatype,nu,time_horizon,path_static,para_object)
% A) Input checks
    % 1) Arguments checks
    if nargin < 8
        print_usage ();
    end
                                
    % A) input data checks
    [rr_c cc_c] = size(corr_matrix);
    [pp_p cc_p] = size(P);
    if ( cc_c ~= cc_p )
        error('scenario_generation_MC: Numbers of risk factors and parameters does not match!');
    end

    % overwrite stable_seed setting --> always draw new random numbers.
    % seed is set during octarisk startup, therefore the random numbers should be always the same automatically
    stable_seed = para_object.stable_seed;
    use_sobol  = para_object.use_sobol;
    sobol_seed = para_object.sobol_seed;
    frob_norm_limit = para_object.frob_norm_limit;
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
% use existing correlated random numbers                        
if ( exist(tmp_filename,'file') && (stable_seed == 1))
    fprintf('scenario_generation_MC: Taking file >>%s<< with random numbers from static folder\n',tmp_filename);
    Z_struct = load(tmp_filename);  % read in from stored file
    Z = Z_struct.Z;
    % test random numbers for matching correlation settings
    frob_norm = norm(abs(corr(Z) - corr_matrix));
    if (frob_norm > frob_norm_limit)
        fprintf('scenario_generation_MC: WARNING: Frobenius norm %s of correlation matrix drawn from random numbers minus correlation settings > %s. New random numbers will be drawn.\n',any2str(frob_norm),any2str(frob_norm_limit));
        new_corr = true;
    else
		fprintf('scenario_generation_MC: Frobenius norm %s of correlation matrix drawn from random numbers minus correlation settings <= %s. No new random numbers will be drawn.\n',any2str(frob_norm),any2str(frob_norm_limit));
    end
% otherwise draw new random numbers and save to static folder for next run
else 
    new_corr = true;
end

% B.2) draw new random numbers and apply copula
if ( new_corr == true)
    dim = length(corr_matrix);
    if ( use_sobol == false)
        fprintf('scenario_generation_MC: New random numbers are drawn for %d MC scenarios and Copulatype %s.\n',mc,copulatype);
        randn_matrix = randn(mc,dim);
    else
        % generate Sobol numbers
        sobol_seed = max(sobol_seed,1); % minimum Sobol seed = 1: first Sobol numbers 0.5
        fprintf('scenario_generation_MC: Use Sobol numbers with seed %d for %d MC scenarios and Copulatype %s.\n',sobol_seed,mc,copulatype);
        if ( dim > 21201)
            error('scenario_generation_MC: Sobol numbers only support up to 21201 dimensions. Use different Sobol generator or MC instead.');
        end
        sobol_matrix = calc_sobol_cpp(mc+sobol_seed,dim,filepath_sobol_direction_number);
        % remove all rows < seed
        sobol_matrix(1:sobol_seed,:) = [];
        % get standard normal distributed random numbers
        randn_matrix = norminv(sobol_matrix);
        % scale randn_matrix to get 0,1 normally distributed numbers
        randn_matrix = randn_matrix ./ std(randn_matrix);
    end
    
    % ############    apply Copula    ######################################
    if ( strcmpi(copulatype, 'Gaussian') ) % Gaussian copula   
        % draw random variables from multivariate normal distribution
        Y   =   mvnrnd_custom(zeros(1,dim),corr_matrix,mc,randn_matrix);  
        Z   =   normcdf(Y,0,1); 
        
    elseif ( strcmpi(copulatype, 't')) % t-copula 
        % draw random variables from multivariate student-t distribution
        Y   =   mvtrnd_custom(corr_matrix,nu,mc,randn_matrix);    
        Z   =   tcdf(Y,nu);
        
    elseif ( strcmpi(copulatype, 'Clayton') || strcmpi(copulatype, 'Gumbel') 
                                                || strcmpi(copulatype, 'Frank')) 
        % draw uniform distributed correlated random numbers 
        % for n scenarios and d risk factors
        Y   =   normcdf(mvnrnd_custom(zeros(1,dim),corr_matrix,mc,randn_matrix));
        % apply copula
        Z   =   mvarchcop (copulatype,Y,nu);  
        
    else
        error('scenario_generation_MC: unknown Copula type >>%s<<. Must be >>t<< or >>Gaussian<<.\n',copulatype);
    end
    
    if (stable_seed == 1)
        save ('-v7',tmp_filename,'Z');
    end
    
end
    

% C) Apply marginal distributions to uniform distributed multivariate random numbers
R = zeros(mc,columns(corr_matrix));
distr_type = zeros(1,columns(Z));
% now loop via all columns of Z and apply individual marginal distribution
for ii = 1 : 1 : columns(Z);
    % mu needs geometric compounding adjustment
    tmp_mu      = P(1,ii) .^(1/factor_time_horizon);
    % volatility needs adjustment with sqr(t)-rule 
    tmp_sigma   = P(2,ii) ./ sqrt(factor_time_horizon);
    tmp_skew    = P(3,ii);
    tmp_kurt    = P(4,ii);
    tmp_ucr = Z(:,ii);
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

% ##############################################################################
%# Copyright (C) 2012  Arno Onken <asnelt@asnelt.org>
%# Clayton copula taken and modified from Octave's statistical package
function x =  mvarchcop (copulatype,u,theta)
  % u = uniform distributed (correlated) random numbers (rand(n,d) for corr = eye)
  n = rows(u);
  d = columns(u);
  if (n > 1 && isscalar (theta))
      theta = repmat (theta, n, 1);
  end
        
  switch lower(copulatype)
    case 'clayton'
        if (d == 2)
          x = zeros (n, 2);
          % Conditional distribution method for the bivariate case which also
          % works for theta < 0
          x(:, 1) = u(:, 1);
          x(:, 2) = (1 + u(:, 1) .^ (-theta) .* (u(:, 2) ...
                              .^ (-theta ./ (1 + theta)) - 1)) .^ (-1 ./ theta);
        else
          % Apply the algorithm by Marshall and Olkin:
          % Frailty distribution for Clayton copula is gamma
          y = randg (1 ./ theta, n, 1);
          x = (1 - log (u) ./ repmat (y, 1, d)) .^ (-1 ./ repmat (theta, 1, d));
        end
        k = find (theta == 0);
        if (any (k))
          % Produkt copula at columns k
          x(k, :) = u(k, :);
        end
        
    case 'frank'       
        % Apply the algorithm by Marshall and Olkin:
        if (theta < 0)
            error('scenario_generation_MC: theta %s must be >= 0 for Frank.',any2str(theta));
        end
        if (theta == 0)
            x = u;
        else
            gamma = floor( 1+log(rand(n,1))./(log(1-exp(-theta.*rand(n,1)))));
            x = -log(1-exp(log(u)./(gamma.*ones(1,d))).*(1-exp(-theta)))./theta ;
        end
        
    case 'gumbel'
        % Apply the algorithm by Marshall and Olkin:
        if theta < 1
            error('scenario_generation_MC: theta %s must be >= 1 for Gumbel.',any2str(theta));
        end
        if theta == 1
            x = u;
        else
            V = rand(n,1).* pi - pi/2;
            W = -log(rand(n,1));
            T = V + pi/2;
            gamma = sin(T./theta).^(1./theta).*cos(V).^(-1) ...
                                        .*((cos(V-T./theta))./W).^(1-1./theta);
            x = exp( - (-log(u)).^(1./theta)./(gamma*ones(1,d))  );
        end
    end % endswitch

end

 
%!test 
%! fprintf('HOLD ON...\n');
%! fprintf('\tscenario_generation_MC:\tGenerating MC scenarios and Gaussian Copula\n');
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
%! para_object.frob_norm_limit = 0.05;                 
%! rand('state',666 .*ones(625,1)); % set seed
%! randn('state',666 .*ones(625,1));    % set seed
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



%###############################################################################
% Testing all copulas
% function copulatestmv()

% %########################## Generate random numbers correlated with copulae ##########
% pkg load statistics;

% dim = 2; %2 or 3

% if dim == 3
    % % 3 dimensions
    % corr_matrix = [1, -0.2, 0.5; -0.2, 1, 0.3; 0.5, 0.3, 1]
    % P = [0,0.2,0,3;0,0.2,0,3;0,0.2,0,3]';
% elseif dim == 2
    % % % 2 dimensions
    % corr_matrix = [1, 0.9; 0.9, 1]
    % P = [0,0.2,0,3;0,0.2,0,3]';
% else
    % error('Dimension has to be 2 or 3 for example plots');
% end

% % Copula parameter
% nu = 2; % t degree of freedom
% mc = 5000

% % ~linear correlation (Pearson) coefficient of 0.5
% theta_gumbel    = 1.6 .* ones(mc,1); % Clayton degree of freedoms per scenario
% theta_frank     = 3.1 .* ones(mc,1);
% theta_clayton   = 1.1 .* ones(mc,1);

% % ~linear correlation (Pearson) coefficient of 0.9
% theta_gumbel    = 5 .* ones(mc,1); % Clayton degree of freedoms per scenario
% theta_frank     = 20 .* ones(mc,1);
% theta_clayton   = 5 .* ones(mc,1);
% eye_matrix = eye(rows(corr_matrix),rows(corr_matrix));
% para_object.stable_seed = 0;
% para_object.use_sobol = false;
% para_object.sobol_seed = 1;
% para_object.frob_norm_limit = 0.05;
% para_object.path_working_folder = pwd;
% para_object.path_sobol_direction_number = '';
% para_object.filename_sobol_direction_number = ''; 

% % generate scenarios                       
% [ZZ distr_type Z] = scenario_generation_MC(corr_matrix,P,mc,'Gaussian',nu,256,[],para_object);
% [TT distr_type T] = scenario_generation_MC(corr_matrix,P,mc,'t',nu,256,[],para_object);
% [GG distr_type G] = scenario_generation_MC(eye_matrix,P,mc,'Gumbel',theta_gumbel,256,[],para_object);
% [FF distr_type F] = scenario_generation_MC(eye_matrix,P,mc,'Frank',theta_frank,256,[],para_object);
% [CC distr_type C] = scenario_generation_MC(eye_matrix,P,mc,'Clayton',theta_clayton,256,[],para_object);

% % Plotting
% if (columns(G) == 3)
    % figure(1);
    % clf;
    % scatter3(Z(:,1),Z(:,2),Z(:,3),'.');
    % axis([0 1 0 1]);
    % title('Correlated with Gaussian Copula','FontSize',20);

    % figure(2);
    % clf;
    % scatter3(T(:,1),T(:,2),T(:,3),'.');
    % axis([0 1 0 1]);
    % title('Correlated with t Copula','FontSize',20);

    % figure(3);
    % clf;
    % scatter3(C(:,1),C(:,2),C(:,3),'.');
    % axis([0 1 0 1]);
    % title('Correlated with Clayton Copula','FontSize',20);
    
    % figure(4);
    % clf;
    % scatter3(G(:,1),G(:,2),G(:,3),'.');
    % axis([0 1 0 1]);
    % title('Correlated with Gumbel Copula','FontSize',20);
    
    % figure(5);
    % clf;
    % scatter3(F(:,1),F(:,2),F(:,3),'.');
    % axis([0 1 0 1]);
    % title('Correlated with Frank Copula','FontSize',20);
% else (columns(G) == 2)
    % tic;
    % figure(1);
        % clf;
        % subplot(1,1,1);
        % [n1,ctr1] = hist(ZZ(:,1),20);
        % [n2,ctr2] = hist(ZZ(:,2),20);
        % subplot(2,2,2);
        % plot(ZZ(:,1),ZZ(:,2),'.');
        % axis([-1 1 -1 1]);
        % h1 = gca;
        % titlestr = strcat('Gaussian Copula (Correlation=',any2str(corr(ZZ)(1,2)), ')');
        % title(titlestr,'FontSize',20);
        % xlabel('Distribution 1: norm 0.2','FontSize',16);
        % ylabel('Distribution 2: norm 0.2','FontSize',16);
        % set(h1,'FontSize',14); %,"rotation",90)
        % subplot(2,2,4);
        % bar(ctr1,-n1,1);
        % axis('off');
        % h2 = gca;
        % subplot(2,2,1);
        % barh(ctr2,-n2,1);
        % axis('off');
        % h3 = gca;
        % set(h1,'Position',[.35 .35 .55 .55]);
        % set(h2,'Position',[.35 .1 .55 .15]);
        % set(h3,'Position',[.1 .35 .15 .55]);
        % colormap([.8 .8 1]);

    % figure(2);
        % clf;
        % subplot(1,1,1);
        % [n1,ctr1] = hist(TT(:,1),20);
        % [n2,ctr2] = hist(TT(:,2),20);
        % subplot(2,2,2);
        % plot(TT(:,1),TT(:,2),'.');
        % axis([-1 1 -1 1]);
        % h1 = gca;
        % titlestr = strcat('t Copula (nu=',any2str(nu),')(Correlation=',any2str(corr(TT)(1,2)), ')');
        % title(titlestr,'FontSize',20);
        % xlabel('Distribution 1: norm 0.2','FontSize',16);
        % ylabel('Distribution 2: norm 0.2','FontSize',16);
        % set(h1,'FontSize',14); %,"rotation",90)
        % subplot(2,2,4);
        % bar(ctr1,-n1,1);
        % axis('off');
        % h2 = gca;
        % subplot(2,2,1);
        % barh(ctr2,-n2,1);
        % axis('off');
        % h3 = gca;
        % set(h1,'Position',[.35 .35 .55 .55]);
        % set(h2,'Position',[.35 .1 .55 .15]);
        % set(h3,'Position',[.1 .35 .15 .55]);
        % colormap([.8 .8 1]);

    % figure(3);
        % clf;
        % subplot(1,1,1);
        % [n1,ctr1] = hist(CC(:,1),20);
        % [n2,ctr2] = hist(CC(:,2),20);
        % subplot(2,2,2);
        % plot(CC(:,1),CC(:,2),'.');
        % axis([-1 1 -1 1]);
        % h1 = gca;
        % titlestr = strcat('Clayton Copula (theta=',any2str(theta_clayton(1)),')(Correlation=',any2str(corr(CC)(1,2)), ')');
        % title(titlestr,'FontSize',20);
        % xlabel('Distribution 1: norm 0.2','FontSize',16);
        % ylabel('Distribution 2: norm 0.2','FontSize',16);
        % set(h1,'FontSize',14); %,"rotation",90)
        % subplot(2,2,4);
        % bar(ctr1,-n1,1);
        % %axis([-2 2 -max(n1)*1.1 0]);
        % axis('off');
        % h2 = gca;
        % subplot(2,2,1);
        % barh(ctr2,-n2,1);
        % %axis([-max(n2)*1.1 0 -2 2]);
        % axis('off');
        % h3 = gca;
        % set(h1,'Position',[.35 .35 .55 .55]);
        % set(h2,'Position',[.35 .1 .55 .15]);
        % set(h3,'Position',[.1 .35 .15 .55]);
        % colormap([.8 .8 1]);
        
    % figure(4);
        % clf;
        % subplot(1,1,1);
        % [n1,ctr1] = hist(FF(:,1),20);
        % [n2,ctr2] = hist(FF(:,2),20);
        % subplot(2,2,2);
        % plot(FF(:,1),FF(:,2),'.');
        % axis([-1 1 -1 1]);
        % h1 = gca;
        % titlestr = strcat('Frank Copula (theta=',any2str(theta_frank(1)),')(Correlation=',any2str(corr(FF)(1,2)), ')');
        % title(titlestr,'FontSize',20);
        % xlabel('Distribution 1: norm 0.2','FontSize',16);
        % ylabel('Distribution 2: norm 0.2','FontSize',16);
        % set(h1,'FontSize',14); %,"rotation",90)
        % subplot(2,2,4);
        % bar(ctr1,-n1,1);
        % axis('off');
        % h2 = gca;
        % subplot(2,2,1);
        % barh(ctr2,-n2,1);
        % axis('off');
        % h3 = gca;
        % set(h1,'Position',[.35 .35 .55 .55]);
        % set(h2,'Position',[.35 .1 .55 .15]);
        % set(h3,'Position',[.1 .35 .15 .55]);
        % colormap([.8 .8 1]);
        
    % figure(5);
        % clf;
        % subplot(1,1,1);
        % [n1,ctr1] = hist(GG(:,1),20);
        % [n2,ctr2] = hist(GG(:,2),20);
        % subplot(2,2,2);
        % plot(GG(:,1),GG(:,2),'.');
        % axis([-1 1 -1 1]);
        % h1 = gca;
        % titlestr = strcat('Gumbel Copula (theta=',any2str(theta_gumbel(1)),')(Correlation=',any2str(corr(GG)(1,2)), ')');
        % title(titlestr,'FontSize',20);
        % xlabel('Distribution 1: norm 0.2','FontSize',16);
        % ylabel('Distribution 2: norm 0.2','FontSize',16);
        % set(h1,'FontSize',14); %,"rotation",90)
        % subplot(2,2,4);
        % bar(ctr1,-n1,1);
        % axis('off');
        % h2 = gca;
        % subplot(2,2,1);
        % barh(ctr2,-n2,1);
        % axis('off');
        % h3 = gca;
        % set(h1,'Position',[.35 .35 .55 .55]);
        % set(h2,'Position',[.35 .1 .55 .15]);
        % set(h3,'Position',[.1 .35 .15 .55]);
        % colormap([.8 .8 1]);
        % plottime = toc
        
        
    % figure(6);
        % clf;
        % subplot(2,3,1);
            % plot(Z(:,1),Z(:,2),'.');
            % axis([0 1 0 1]);
            % h1 = gca;
            % titlestr = strcat('Gaussian Copula (Correlation=',any2str(corr(Z)(1,2)), ')');
            % title(titlestr,'FontSize',20);
            % xlabel('Distribution 1: uniform','FontSize',16);
            % ylabel('Distribution 2: uniform','FontSize',16);
            % set(h1,'FontSize',14); %,"rotation",90)
        % subplot(2,3,2);
            % plot(T(:,1),T(:,2),'.');
            % axis([0 1 0 1]);
            % h1 = gca;
            % titlestr = strcat('t Copula (nu=',any2str(nu),')(Correlation=',any2str(corr(T)(1,2)), ')');
            % title(titlestr,'FontSize',20);
            % xlabel('Distribution 1: uniform','FontSize',16);
            % ylabel('Distribution 2: uniform','FontSize',16);
            % set(h1,'FontSize',14); %,"rotation",90)
        % subplot(2,3,3);
            % plot(C(:,1),C(:,2),'.');
            % axis([0 1 0 1]);
            % h1 = gca;
            % titlestr = strcat('Clayton Copula (theta=',any2str(theta_clayton(1)),')(Correlation=',any2str(corr(C)(1,2)), ')');
            % title(titlestr,'FontSize',20);
            % xlabel('Distribution 1: uniform','FontSize',16);
            % ylabel('Distribution 2: uniform','FontSize',16);
            % set(h1,'FontSize',14); %,"rotation",90)
        % subplot(2,3,4);
            % plot(G(:,1),G(:,2),'.');
            % axis([0 1 0 1]);
            % h1 = gca;
            % titlestr = strcat('Gumbel Copula (theta=',any2str(theta_gumbel(1)),')(Correlation=',any2str(corr(G)(1,2)), ')');
            % title(titlestr,'FontSize',20);
            % xlabel('Distribution 1: uniform','FontSize',16);
            % ylabel('Distribution 2: uniform','FontSize',16);
            % set(h1,'FontSize',14); %,"rotation",90)
        % subplot(2,3,5);
            % plot(F(:,1),F(:,2),'.');
            % axis([0 1 0 1]);
            % h1 = gca;
            % titlestr = strcat('Frank Copula (theta=',any2str(theta_frank(1)),')(Correlation=',any2str(corr(F)(1,2)), ')');
            % title(titlestr,'FontSize',20);
            % xlabel('Distribution 1: uniform','FontSize',16);
            % ylabel('Distribution 2: uniform','FontSize',16);
            % set(h1,'FontSize',14); %,"rotation",90)
        
        
% end


% end

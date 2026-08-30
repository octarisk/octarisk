%# Copyright (C) 2016 Stefan Schlögl <schinzilord@octarisk.com>
%# Copyright (C) 2013 Martin Becker and Stefan Kloessner:
%# modified R package 'PearsonDS':
%# http://CRAN.R-project.org/package=PearsonDS
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
%#
%# You should have received a copy of the GNU General Public License along with
%# this program; if not, see <http://www.gnu.org/licenses/>.
%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{r} @var{type} ] =} get_marginal_distr_pearson (@var{mu}, @var{sigma}, @var{skew}, @var{kurt}, @var{Z})
%#
%# Compute a marginal distribution for given set of uniform random variables
%# with given mean, standard deviation skewness and kurtosis. The mapping is
%# done via the Pearson distribution family.
%# @*
%# The implementation is based on the R package 'PearsonDS: Pearson Distribution
%# System' and the function 'pearsonFitM' by @*
%# Martin Becker and Stefan Kloessner (2013) @*
%# R package version 0.97. @*
%# URL: http://CRAN.R-project.org/package=PearsonDS @*
%# licensed under the GPL >= 2.0 @*
%# Input and output variables:
%# @itemize @bullet
%# @item @var{mu}:      mean of marginal distribution (scalar)
%# @item @var{sigma}:   standard deviation of marginal distribution (scalar)
%# @item @var{skew}:    skewness of marginal distribution (scalar)
%# @item @var{kurt}:    kurtosis of marginal distribution (scalar)
%# @item @var{Z}:       uniform distributed random variables (Nx1 vector)
%# @item @var{r}:       OUTPUT: Nx1 vector with random variables distributed
%# according to Pearson type (vector)
%# @item @var{type}:    OUTPUT: Pearson distribution type (I - VII) (scalar)
%# @end itemize
%# The marginal distribution type is chosen according to the input parameters
%# out of the Pearson Type I-VII distribution family: @*
%# @itemize @bullet
%# @item @var{Type 0}   = normal distribution
%# @item @var{Type I}   = generalization of beta distribution
%# @item @var{Type II}  = symmetric beta distribution
%# @item @var{Type III} = gamma or chi-squared distribution
%# @item @var{Type IV}  = special distribution, not related to any other
%# distribution
%# @item @var{Type V}   = inverse gamma distribution
%# @item @var{Type VI}  = beta-prime or F distribution
%# @item @var{Type VII} = Student's t distribution
%# @end itemize
%# @seealso{discount_factor, classify_pearson}
%# @end deftypefn
function [r,type] = get_marginal_distr_pearson(mu,sigma,skew,kurt,Z)

% Classify Pearson Distribution Type I - VII and calculate shape parameters
% (scale and location will be applied in the end)
retvec = classify_pearson(mu,sigma,skew,kurt);
type = retvec(1);

if ( kurt <= 0.0)
    error('ERROR: et_marginal_distr_pearson: kurtosis has to be larger than 0.0\n');
end

% classify_pearson signals an invalid or ill-shaped (boundary-singularity /
% bimodal) parameterization by returning type = NaN. Propagate this as a
% NaN vector instead of silently generating a distorted distribution.
if ( isnan(type) )
    r = NaN(size(Z));
    return;
end

% generate standard marginal distribution (zero mean, unit variance) values for
% given correlated random numbers
if ( type == 0)
    % normal distribution
    r = norminv(Z,0,1);
elseif ( type == 1)
    % generalization of beta distribution
    m1 = retvec(2);
    m2 = retvec(3);
    a1 = retvec(4);
    a2 = retvec(5);
    r = a1 + (a2 - a1) .* betainv_vec(Z,m1+1,m2+1);
elseif ( type == 2)
    % symmetric beta distribution
    m = retvec(2);
    a1 = retvec(3);
    if ( m <= -1.0)
        fprintf('WARN: get_marginal_distr_pearson: symmetric beta distribution: kurtosis has to be larger than 1 for skewness equals 0. Setting kurtosis to 1.5.\n');
        m = -0.5;
    end
    r = a1 + 2*abs(a1) .* betainv_vec(Z,m+1,m+1);
elseif ( type == 3)
    % gamma or chi-squared distribution
    m  = retvec(2);
    a1 = retvec(3);
    c1 = retvec(4);
    r = c1 .* gaminv(Z,m+1,1) + a1;
elseif ( type == 4)
    % special distribution, not related to any other distribution
    m = retvec(2);
    nu = retvec(3);
    a = retvec(4);
    lambda = retvec(5);
    r_uncorr = rpears4(m,nu,a,lambda,length(Z));
    % uncorrelated distribution -> draw correlated univariate random numbers
    % from 'empirical' pearson type IV distribution:
    r =  empirical_inv (Z, r_uncorr);
elseif ( type == 5)
    % inverse gamma distribution
    c1 = retvec(2);
    c2 = retvec(3);
    C1 = retvec(4);
    r = -((c1 - C1) ./ c2) ./ gaminv(Z,1./c2 - 1,1) - C1;
elseif ( type == 6)
    % beta-prime or F distribution
    a1 = retvec(2) ;
    a2 = retvec(3);
    m1 = retvec(4);
    m2 = retvec(5);
    % Map to the beta-prime/F distribution (single formula, verified against
    % the reference R implementation PearsonDS::pearsonFitM).
    nu1 = 2*(m2 + 1);
    nu2 = -2*(m1 + m2 + 1);
    % classify_pearson's Type VI root ordering (a1,a2) is not guaranteed to
    % satisfy a2 >= a1 -- unlike Type I/IV/VII, whose ordering conventions
    % keep every other branch in this file an increasing function of Z
    % (norminv/betainv_vec/gaminv/tinv/empirical_inv all are), a2 < a1 here
    % makes (a2-a1) negative and r a DEcreasing function of Z. Since Z is the
    % shared copula draw, a decreasing marginal for this risk factor flips
    % the sign of its correlation with every other risk factor while leaving
    % same-type correlations intact (two sign flips cancel) -- exactly the
    % failure mode this guards against. finv(1-Z,nu1,nu2) has the identical
    % distribution to finv(Z,nu1,nu2) (mirrors the uniform draw), so this
    % restores the increasing convention without altering the marginal shape
    % (mean/std/skew/kurt).
    if ( a2 >= a1 )
        r = a2 + (a2 - a1) .* (nu1./nu2) .* finv(Z,nu1,nu2);
    else
        r = a2 + (a2 - a1) .* (nu1./nu2) .* finv(1-Z,nu1,nu2);
    end
elseif ( type == 7)
    % Student's t distribution
    nu = retvec(2);
    c0 = retvec(3);
    c2 = retvec(4);
    r = sqrt(c0 ./ (1-c2)) .* tinv(Z,nu);
end

% apply scale and location parameter
r = r.*sigma + mu;

end % end of Main function

%%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%##

function r = rpears4(m,nu,a,lam,len_vec)
%   Implemention taken from 'Non-Uniform Random Variate Generation'
%      by Luc Devroye (1986)
%   http://www.eirene.de/Devroye.pdf

%  === returns random Pearson IV deviate ===
%
%   'A Guide to the Pearson Type IV Distribution'
%   Joel Heinrich—University of Pennsylvania
%   December 21, 2004
%   http://www-cdf.fnal.gov/physics/statistics/notes/cdf6820_pearson4.pdf


% Calling implementation of the complex hypergeometric distribution of
% CDF/MEMO/STATISTICS/PUBLIC/6820
% gammar2_cs = -log(gammar2_c(m,nu/2));

% Calling implementation of the function type4norm of
% CDF/MEMO/STATISTICS/PUBLIC/6820
k = 0.5*(2/sqrt(pi))*gammar2_c(m,nu/2)*exp(gammaln(m)-gammaln(m-0.5))/a;
logk = log(k);

% Define variables
b = 2*(m-1);
M = atan(-nu./b);
cosM = a ./ sqrt(b-1);
rM = b.*log(cosM) - nu.*M;
rC = exp(-rM - logk);

r = zeros(len_vec,1);
j = 1:numel(r);
% log-concave density: Solution of Excercise 2.7C (Devroye: page 308)
while length(j) > 0
    U = 4*rand(size(j)); % Draw random numbers from univariate distribution([0,4])
    S = (U>2);
    U(S) = U(S) - 2;
    negative_Estar = log(max(U,1)-(U>1));
    X = min(U,1) - negative_Estar;
    Z = log(rand(size(j))) + negative_Estar;
    X = M + (2*S-1).*X.*rC;
    k = (abs(X) < pi/2) & (Z <= b.*log(abs(cos(X))) - nu.*X - rM);
    r(j(k)) = X(k);
    j(k) = [];
end

% Map to Pearson type IV distribution
r = a.*tan(r) + lam;
end % end of rpears4 function

%%#%#%#%#%#%#%#%#%#%#%#%#%#%#%#%##

%=======================
% Implementation of the complex hypergeometric distribution from
% the C-Code example from
% http://www-cdf.fnal.gov/physics/statistics/notes/cdf6820_pearson4.pdf
% CDF/MEMO/STATISTICS/PUBLIC/6820:
% 'A Guide to the Pearson Type IV Distribution'
% by Joel Heinrich—University of Pennsylvania
% December 21, 2004
function retval = gammar2_c(x,y)
%/* returns abs(gamma(x+iy)/gamma(x))^2 */
y2=y*y;
xmin = max(2*y2,10);
r=1;
s=1;
p=1;
f=0;
while(x<xmin)
    t = y/x;
    x = x + 1;
    r = r *( 1 + t*t);
end

while (p > s*eps)
    f = f + 1;
    p = p * (y2 + f*f) / (x  * f);
    x = x + 1;
    s = s + p;
end
% scale retval
retval = 1.0/(r*s);
end
%=======================

% NOTE: classify_pearson used to be a private subfunction defined here. It is
% now its own file, classify_pearson.m, so it can be reused directly (e.g. as
% a fast, sampling-free integrity check on candidate (skew,kurt) risk factor
% calibrations in perform_rf_stat_tests.m) without duplicating this logic.
% See classify_pearson.m and PEARSON_METHODOLOGY.md.

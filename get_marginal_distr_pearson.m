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
%# @item @var{mu}: 		mean of marginal distribution (scalar)
%# @item @var{sigma}: 	standard deviation of marginal distribution (scalar)
%# @item @var{skew}: 	skewness of marginal distribution (scalar)
%# @item @var{kurt}: 	kurtosis of marginal distribution (scalar)
%# @item @var{Z}: 		uniform distributed random variables (Nx1 vector)
%# @item @var{r}: 		OUTPUT: Nx1 vector with random variables distributed 
%# according to Pearson type (vector)
%# @item @var{type}: 	OUTPUT: Pearson distribution type (I - VII) (scalar)
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
%# @seealso{discount_factor}
%# @end deftypefn

function [r,type] = get_marginal_distr_pearson(mu,sigma,skew,kurt,Z)

% Classify Pearson Distribution Type I - VII and calculate shape parameters 
% (scale and location will be applied in the end)
retvec = classify_pearson(mu,sigma,skew,kurt);
type = retvec(1);

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
    r = a1 + (a2 - a1) .* betainv(Z,m1+1,m2+1);
elseif ( type == 2)
    % symmetric beta distribution
    m = retvec(2);
    a1 = retvec(3);
    r = a1 + 2*abs(a1) .* betainv(Z,m+1,m+1);
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
    % get nu1 and nu2 taking into account the order -> case dependency
    if a2 < 0
        nu1 = 2*(m2 + 1);
        nu2 = -2*(m1 + m2 + 1);
        r = a2 + (a2 - a1) .* (nu1./nu2) .* finv(Z,nu1,nu2);
    else % a2 > a1
        nu1 = 2*(m1 + 1);
        nu2 = -2*(m1 + m2 + 1);
        r = a1 + (a1 - a2) .* (nu1./nu2) .* finv(Z,nu1,nu2);
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



function retvec = classify_pearson(mean,stddev,skewness,kurtosis)
% function for classification of pearson distribution system and calculation 
% of scale and shape parameters
% Modified and apapted from Function 'pearsonFitM':
%   Martin Becker and Stefan Klößner (2013). 
%   PearsonDS: Pearson Distribution System. 
%   R package version 0.97. URL http://CRAN.R-project.org/package=PearsonDS
% licensed under the GPL >= 2.0

mmm = mean; 
vvv = stddev^2; 
sss = skewness; 
kkk = kurtosis;

% special case singularity:  
if (abs(10*kkk - 12*sss^2 - 18) < sqrt(realmin))
    disp('Pearson distribution system: special case singularity for values of skewness and kurtosis')
    type = 1;       % special case Type I
    a1 = 1/2*((-sss*(kkk+3)-sqrt(sss^2*(kkk+3)^2-4*(4*kkk-3*sss^2)*(2*kkk-3*sss^2-6)))/(2*kkk-3*sss^2-6));
    a2 = 1/2*((-sss*(kkk+3)+sqrt(sss^2*(kkk+3)^2-4*(4*kkk-3*sss^2)*(2*kkk-3*sss^2-6)))/(2*kkk-3*sss^2-6));
    if (a1>0) 
        tmp = a1; 
        a1 = a2; 
        a2 = tmp; 
    end
    c1  = sss*(kkk+3);
    c2  = (2*kkk-3*sss^2-6);
        
    m1 = c1 ./ (c2 .* (a2 - a1));
    m2 = -c1 ./ (c2 .* (a2 - a1));
    retvec = [ type, m1, m2, a1, a2 ]; 
    return;    
end

% start calculation of parameters for normal cases
  c0  = (4*kkk-3*sss^2)/(10*kkk-12*sss^2-18);
  c1  = sss*(kkk+3)/(10*kkk-12*sss^2-18);
  c2  = (2*kkk-3*sss^2-6)/(10*kkk-12*sss^2-18);
  
% get appropriate distribution type Pearson type I to VII
  if (sss == 0)
    if (kkk == 3)
        type=0;                            % type 0 (normal distribution)
        retvec = [ type, 0, 1 ];
    elseif (kkk<3)                         % type II
      a1 = -1/2*(-sqrt(-16*kkk*(2*kkk-6))/(2*kkk-6));
      m = (c1 + a1) ./ (c2 .* 2*abs(a1));
      if ( m < -1)
        disp('WARNING: no distribution type defined, setting to default case')
        m = -0.999;
      end
      % return:
         type = 2;                        % type II -> scale*beta(a,a)+location
         retvec = [type, m, a1 ];
    elseif (kkk>3)                        % type VII
      r      = 6*(kkk-1)/(2*kkk-6);
      dof    = 1+r;
      type=7;                                            
      retvec = [ type, dof, c0, c2 ];
    end  
  elseif ~(2*kkk-3*sss^2-6 == 0)
    kap = 0.25*sss^2*(kkk+3)^2/((4*kkk-3*sss^2)*(2*kkk-3*sss^2-6));
    if (kap<0)                            % type I
      a1 = 1/2*((-sss*(kkk+3)-sqrt(sss^2*(kkk+3)^2-4*(4*kkk-3*sss^2)*(2*kkk-3*sss^2-6)))/(2*kkk-3*sss^2-6));
      a2 = 1/2*((-sss*(kkk+3)+sqrt(sss^2*(kkk+3)^2-4*(4*kkk-3*sss^2)*(2*kkk-3*sss^2-6)))/(2*kkk-3*sss^2-6));
      if (a1>0) 
        tmp = a1; 
        a1 = a2; 
        a2 = tmp; 
      end  
      a  = c1;
      m1 = -(sss*(kkk+3)+a1*(10*kkk-12*sss^2-18)/1)/(sqrt(sss^2*(kkk+3)^2-4*(4*kkk-3*sss^2)*(2*kkk-3*sss^2-6)));
      m2 = -(-sss*(kkk+3)-a2*(10*kkk-12*sss^2-18)/1)/(sqrt(sss^2*(kkk+3)^2-4*(4*kkk-3*sss^2)*(2*kkk-3*sss^2-6)));
       if ~((m1>-1)&&(m2>-1))
         disp('WARNING: get_marginal_distr_pearson: no distribution type defined, setting to default case')
         m1 = -0.999;
         m2 = m1;
       end
      type=1;
      retvec = [ type, m1, m2, a1, a2 ];
    elseif (kap==1 )                      % type V
      C1 = c1/(2*c2);
      retvec = [ type, c1, c2, C1 ]
    elseif (kap>1)                        % type VI
      a1 = 1/2*((-sss*(kkk+3)-sqrt(sss^2*(kkk+3)^2-4*(4*kkk-3*sss^2)*(2*kkk-3*sss^2-6)))/(2*kkk-3*sss^2-6));
      a2 = 1/2*((-sss*(kkk+3)+sqrt(sss^2*(kkk+3)^2-4*(4*kkk-3*sss^2)*(2*kkk-3*sss^2-6)))/(2*kkk-3*sss^2-6));
      if (a1>0) 
        tmp = a1; 
        a1 = a2; 
        a2 = tmp;
      end
      a  = c1;
      m1 = (a + a1)/(c2*(a2-a1));
      m2 = - (a + a2)/(c2*(a2-a1));      
      type=6;
      retvec = [ type, a1, a2, m1, m2 ];
    end  
    if ((kap>0)&&(kap<1))                  % type IV
      r        = 6*(kkk-sss^2-1)/(2*kkk-3*sss^2-6);
      nu       = -r*(r-2)*sss/sqrt(16*(r-1)-sss^2*(r-2)^2);
      scale    = - sqrt(vvv*(16*(r-1)-sss^2*(r-2)^2))/4;
      location = - mmm - ((r-2)*sss*sqrt(vvv))/4;
      m      = 1+r/2;
      type=4;
      b = 2*(m-1);
      location = sqrt(b.^2 .* (b-1) ./ (b.^2 + nu.^2)); 
      scale = location.*nu ./ b; 
      retvec = [ type, m, nu, location, scale ];
    end
  else                                      % type III
    m = (c0./c1 - c1) ./ c1;
    a1 = -c0 ./ c1;
    type=3;
    retvec = [ type, m, a1, c1 ];
  end

end
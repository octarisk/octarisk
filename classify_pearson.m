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
%# @deftypefn {Function File} {@var{retvec} =} classify_pearson (@var{mean}, @var{stddev}, @var{skewness}, @var{kurtosis})
%#
%# Classify a set of target moments (mean, standard deviation, skewness, raw/
%# Pearson kurtosis -- normal distribution = 3, NOT excess kurtosis) into a
%# Pearson distribution Type (0, I-VII) and calculate the shape/location/scale
%# parameters used by @seealso{get_marginal_distr_pearson} to actually
%# generate the distribution.
%# @*
%# This is a pure, deterministic, O(1) classification -- no random sampling
%# is involved. It is the recommended way to validate a candidate (skew,kurt)
%# risk-factor calibration before deploying it: for a small subset of
%# (skew,kurt) combinations, no admissible Pearson distribution exists without
%# a boundary singularity (an unbounded density spike, which would otherwise
%# distort a Monte Carlo risk factor). In that case @var{retvec}(1) is @code{NaN}
%# instead of a valid type number, and @seealso{get_marginal_distr_pearson}
%# propagates this as an all-@code{NaN} output vector rather than silently
%# generating the pathological shape. See PEARSON_METHODOLOGY.md for the full
%# derivation and a boundary map of safe vs. rejected (skew,kurt) regions.
%# @*
%# Modified and adapted from Function 'pearsonFitM':
%#   Martin Becker and Stefan Klößner (2013).
%#   PearsonDS: Pearson Distribution System.
%#   R package version 0.97. URL http://CRAN.R-project.org/package=PearsonDS
%# licensed under the GPL >= 2.0
%# @seealso{get_marginal_distr_pearson}
%# @end deftypefn

function retvec = classify_pearson(mean,stddev,skewness,kurtosis)

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
      if ( m <= -1)
        disp('WARNING: get_marginal_distr_pearson: Type II shape parameter <= 0 (invalid beta distribution). No distribution generated.')
        type = NaN;
        retvec = [ type ];
        return;
      elseif ( m < 0)
        disp('WARNING: get_marginal_distr_pearson: Type II shape parameter in (0,1) leads to a symmetric beta distribution with a boundary singularity (U-shaped / bimodal), unsuitable for Monte Carlo risk factor generation. No distribution generated.')
        type = NaN;
        retvec = [ type ];
        return;
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
         disp('WARNING: get_marginal_distr_pearson: Type I shape parameter(s) <= 0 (invalid beta distribution). No distribution generated.')
         type = NaN;
         retvec = [ type ];
         return;
       elseif ( m1 < 0 || m2 < 0 )
         disp('WARNING: get_marginal_distr_pearson: Type I shape parameter(s) in (0,1) lead to a boundary singularity (spike) in the generalized beta distribution, unsuitable for Monte Carlo risk factor generation. No distribution generated.')
         type = NaN;
         retvec = [ type ];
         return;
       end
      type=1;
      retvec = [ type, m1, m2, a1, a2 ];
    elseif (kap==1 )                      % type V
      type = 5;
      C1 = c1/(2*c2);
      retvec = [ type, c1, c2, C1 ];
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
      % validate the resulting F-distribution degrees of freedom (matches
      % the single, non-branching nu1/nu2 formula used to build r later --
      % verified against the reference R implementation, PearsonDS::
      % pearsonFitM, which has no case distinction on the sign of a2).
      % nu2<=0 is an invalid/undefined F-distribution; nu1<=2 gives the
      % F-density an unbounded boundary singularity (spike) at zero, the
      % Type VI analogue of the Type I/II beta shape<1 pathology.
      nu1_chk = 2*(m2 + 1);
      nu2_chk = -2*(m1 + m2 + 1);
      if ( nu2_chk <= 0 )
        disp('WARNING: get_marginal_distr_pearson: Type VI parameterization yields non-positive denominator degrees of freedom (invalid beta-prime/F distribution). No distribution generated.')
        type = NaN;
        retvec = [ type ];
        return;
      elseif ( nu1_chk <= 2 )
        disp('WARNING: get_marginal_distr_pearson: Type VI parameterization yields numerator degrees of freedom <= 2, causing a boundary singularity (spike) in the beta-prime/F distribution, unsuitable for Monte Carlo risk factor generation. No distribution generated.')
        type = NaN;
        retvec = [ type ];
        return;
      end
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

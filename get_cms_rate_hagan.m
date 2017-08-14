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
%# @deftypefn {Function File} {@var{forward_rate}=} get_cms_rate_hagan(@var{valuation_date}, @var{value_type}, @var{swap}, @var{curve}, @var{sigma}, @var{payment_date})
%#
%# Compute the cms rate of an underlying swap floating leg incl. convexity 
%# adjustment. The implementation of cms convexity adjustment is based on
%# P.S. Hagan, Convexity Conundrums, 2003.
%# There is a minor issue with Hagans formulas: An adjustment to the 
%# value of the swaplet / caplet / floorlet is being calculated. For calculation 
%# of this adjustment a volatility is required. The volatility has to be 
%# interpolated from a given volatility cube with a given moneyness. In case of 
%# swaplets, the moneyness can be assumed to be 1.0. For caplets / floorlets, the 
%# moneyness can be calculated as (cms_rate-X) or (cms_rate/X). Here either the
%# adjusted cms rate or still the unadjusted cms rate can be used to calculate
%# the moneyness.@*
%# Explanation of Input Parameters:
%# @*
%# @itemize @bullet
%# @item @var{valuation_date}: valuation date
%# @item @var{value_type}: value type (e.g. base or stress)
%# @item @var{swap}: swap instrument object, underlying of cms swap
%# @item @var{curve}: discount curve object
%# @item @var{sigma}: volatility used for calculating convexity adjustment
%# @item @var{payment_date}: payment date of cashflow
%# @end itemize
%# @seealso{discount_factor, timefactor, rollout_structured_cashflows}
%# @end deftypefn

function [cms_rate convex_adj] = get_cms_rate_hagan(valuation_date,value_type,instrument,swap,curve,sigma,payment_date)
 
 if nargin < 7 || nargin > 7
    print_usage ();
 end

% Curve variables
nodes = curve.get('nodes');
rates = curve.getValue(value_type);
basis_curve = curve.get('basis');
comp_type_curve = curve.get('compounding_type');
comp_freq_curve = curve.get('compounding_freq');
interp_method = curve.get('method_interpolation');

comp_type = swap.get('compounding_type');
comp_freq = swap.get('compounding_freq');
basis = swap.get('basis');

model = instrument.cms_model;
% Start Calculation

% get relevant discount factors from start date to end_date with term
cms_dates = rollout_structured_cashflows(valuation_date, value_type, ...
                    swap, curve);
% add issue date to cms_dates
days_to_issue = datenum(swap.issue_date) - valuation_date;

cms_dates = [days_to_issue,cms_dates];
% Preallocate memory
cms_df = zeros(rows(rates),length(cms_dates));

% time factor between valuation date and swap issue date
TF = timefactor(valuation_date,datenum(swap.issue_date),basis);

for ii = 1:1:length(cms_dates)
    tmp_date = cms_dates(ii);
    % interpolate rates from given curve rates
    r_curve = curve.getRate(value_type,tmp_date);
    % calculate discount factor
    cms_df(:,ii) = discount_factor (valuation_date, (tmp_date + valuation_date), ...
                        r_curve, comp_type_curve, basis_curve, comp_freq_curve);
end
% calculate time factor
tf_df = zeros(1,length(cms_dates)-1);
for ii = 1:1:length(cms_dates)-1
    tf_df(:,ii) = timefactor(cms_dates(ii),cms_dates(ii+1),basis);
end

% cms_df
% tf_df
% TODO: implement swap premiums at start and end of swap lifetime
prem_end = 0.0; %swap.premium_at_end;
prem_start = 0.0; %swap.premium_at_start;

cms_df(:,1) = cms_df(:,1) .* (prem_start + swap.notional);
cms_df(:,2:end-1) = cms_df(:,2:end-1) .* (swap.notional);
cms_df(:,end) = cms_df(:,end) .* (prem_end + swap.notional);

% Calculate CMS rate:

% get difference between first and last df
nominator = cms_df(:,1) .- cms_df(:,end);

 % sum up all timefactor weighted discount factors
cms_df_tmp = cms_df(:,2:end);  % remove first discount factor
Annuity = sum(cms_df_tmp.*tf_df,2);
cms_rate = nominator ./ Annuity;
                       

% Convexity Adjustment according to Hagan Paper "Convexity Conundrums", 2003:
% number of underlying cms payments per year
if ( swap.term == 365)
    q = 365 / (swap.term ); 
elseif ( swap.term == 12)
    q = 1; 
elseif ( swap.term == 6)
    q = 2; 
elseif ( swap.term == 3)
    q = 4; 
elseif ( swap.term == 2)
    q = 6; 
elseif ( swap.term == 1)
    q = 12; 
else    
    q = 1;
end

% Appendix A.1 Model 1: formula A.2c 
% timefactor between CMS instrument issue date and payment date
payment_date = valuation_date + payment_date;
nom_t0_tp = timefactor(datenum(swap.issue_date),payment_date,basis);
denom_t0_t1 = q.^-(1); % timefactor between underlying cms payment date and fixing date
delta = nom_t0_tp ./ denom_t0_t1;

n = length(tf_df); % n is total number of payments of underlying swap
dG = dG(cms_rate,delta,n,q); % calculate derivative of Bond pricing function G

% Discount Factor: Hagan specifies adjustment to value, but we want adjustment to rates
% Calculation of discount factor at payment date
rate_paymentdate = curve.getRate(value_type,payment_date - valuation_date);
Dt_p = discount_factor (valuation_date, payment_date, ...
                rate_paymentdate, comp_type_curve, basis_curve, comp_freq_curve);
% distinguish between CMS Swaplets, Caplets and Floorlets
convex_adj = 0.0;
if ( regexpi( instrument.sub_type,'FLOATING') || regexpi( instrument.sub_type,'FRN_SPECIAL'))                         
    if (strcmpi(model,'Black')) % Formula 3.5b
        convex_adj = dG .* (exp(sigma.^2 .* TF) -1) .* cms_rate.^2 .*  Annuity ./ Dt_p;
    else    % normal model Formula 3.6b
        convex_adj = dG .* TF .* sigma.^2 .*  Annuity ./ Dt_p;
    end
elseif ( regexpi( instrument.sub_type,'^CAP') )  % CMS rate adjustment to caplet
    X = instrument.strike;
    h = (cms_rate - X) ./ (sigma*sqrt(TF));
    cdf_h = 0.5.*(1+erf(h./sqrt(2)));
    if (strcmpi(model,'Black')) % Formula 3.5c
        %convex_adj = yet to be implemented...
        fprintf('WARNING: get_cms_rate_hagan: Convexity Adjustment for Cap Black model not yet implemented. Setting adjustment to zero.\n');
    else    % normal model Formula 3.6c
        convex_adj = dG .* TF .* sigma.^2 .*  Annuity ./ Dt_p .* cdf_h;
    end
elseif ( regexpi( instrument.sub_type,'^FLOOR') )  % CMS rate adjustment to floorlet
    X = instrument.strike;
    h = (X - cms_rate) ./ (sigma*sqrt(TF));
    cdf_h = 0.5.*(1+erf(h./sqrt(2)));
    if (strcmpi(model,'Black')) % Formula 3.5d
        %convex_adj =  yet to be implemented...
        fprintf('WARNING: get_cms_rate_hagan: Convexity Adjustment for floor Black model not yet implemented. Setting adjustment to zero.\n');
    else    % normal model Formula 3.6d
        convex_adj = -dG .* TF .* sigma.^2 .*  Annuity ./ Dt_p .* cdf_h;
    end
end

end % end main function

% #######################   Derivative functions   #############################
% first derivative of G (Appendix A.1 Model 1: formula A.3 of Hagans paper)
% G is standard bond math model: G ~ (f / (1 + f/q)^delta)*(1 - (1/(1+f/q)^n))^(-1)
% dG = (((q+x)/q)^(n-δ) (q (-1+((q+x)/q)^n)-x (n+(-1+((q+x)/q)^n) (-1+δ))))/((q+x) (-1+((q+x)/q)^n)^2)
function ret = dG(f,delta,n,q)
    % f = cms_rate
    % t_0 = CMS swaps start date
    % t_1 = CMS swap new cf date
    % t_p = pay date
    % n = number of underlying swaps payment
    %delta = ( t_p - t_0 ) ./ ( t_1 - t_0 )
    % q = number of payments per period
    fq = f./q;
    ret = (1 + fq - delta.*fq) .* ( (1+fq ).^(n - delta - 1) ./ ( (1+fq ).^(n) - 1) ) ...
                - n.*fq .* ( (1+fq ).^(n - delta - 1) ./ ( (1+fq ).^(n) - 1).^2 );
end
%######################

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
%# @deftypefn {Function File} {@var{forward_rate}=} get_cms_rate(@var{valuation_date}, @var{value_type}, @var{swap}, @var{curve}, @var{sigma}, @var{model})
%#
%# Compute the cms rate of an underlying swap floating leg and discount curve.
%# Explanation of Input Parameters:
%# @*
%# @itemize @bullet
%# @item @var{valuation_date}: valuation date
%# @item @var{value_type}: value type (e.g. base or stress)
%# @item @var{swap}: swap instrument object, underlying of cms swap
%# @item @var{curve}: discount curve object
%# @end itemize
%# @seealso{interpolate_curve, timefactor}
%# @end deftypefn

function [cms_rate convex_adj] = get_cms_rate(valuation_date,value_type,swap,curve,sigma,model)
 
 if nargin < 6 || nargin > 6
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
 
% Start Calculation

% get relevant discount factors from start date to end_date with term
cms_dates = rollout_structured_cashflows(valuation_date, value_type, ...
                    swap, curve);
% add issue date to cms_dates
days_to_issue = datenum(swap.issue_date) - valuation_date;

cms_dates = [days_to_issue,cms_dates];
cms_df = zeros(rows(rates),length(cms_dates));

tf_start = timefactor(valuation_date,datenum(swap.issue_date),basis);

for ii = 1:1:length(cms_dates)
    tmp_date = cms_dates(ii);
    % interpolate rates from given curve rates
    r_curve = interpolate_curve(nodes,rates,tmp_date,interp_method);
    % calculate discount factor
    cms_df(:,ii) = discount_factor (valuation_date, (tmp_date + valuation_date), ...
                        r_curve, comp_type_curve, basis_curve, comp_freq_curve);
end
% calculate time factor
tf_df = zeros(1,length(cms_dates)-1);
for ii = 1:1:length(cms_dates)-1
    tf_df(:,ii) = timefactor(cms_dates(ii),cms_dates(ii+1),basis);
end

% TODO: implement swap premiums at start and end of swap lifetime
prem_end = 0.0; %swap.premium_at_end;
prem_start = 0.0; %swap.premium_at_start;

cms_df(:,1) = cms_df(:,1) .* (prem_start + swap.notional);
cms_df(:,end) = cms_df(:,end) .* (prem_end + swap.notional);

% Calculate CMS rate:

% get difference between first and last df per scenario
nominator = cms_df(:,1) .- cms_df(:,end);

 % sum up all timefactor weighted discount factors per scenario
cms_df_tmp = cms_df(:,2:end);  % remove first discount factor
denominator = sum(cms_df_tmp.*tf_df,2);

cms_rate = nominator ./ denominator;
                        
% Calculate Convexity Adjustment (for simple or cont compounding only)
comp_type = swap.get('compounding_type');
% get derivatives of bond pricing function
dP = dP(cms_df,cms_rate,comp_type);
ddP = ddP(cms_df,cms_rate,comp_type);

if (strcmpi(model,'Black'))
    convex_adj = -0.5 .* cms_rate.^2 .* sigma.^2 .* tf_start .* ddP ./ dP;
else    % normal model
    convex_adj = -0.5 .* sigma.^2 .* tf_start .* ddP ./ dP;
end
cms_rate = cms_rate .+ convex_adj;

end % end function

% #########################   Helper functions   ###############################
% first derivative of P
function ret = dP(cms_df,cms_rate,comp_type)
    ret = 0.0;
    if ( regexpi(comp_type,'cont'))
        for ii=2:1:columns(cms_df)
            ret += - cms_rate .* (ii-1) .* ( cms_df(:,ii) ./ cms_df(:,1) );
        end
        ret += -(columns(cms_df)-1) .* (cms_df(:,end) ./ cms_df(:,1) );
        
    else    % simple or discrete (not yet implemented) compounding
        for ii=2:1:columns(cms_df)
            ret += - cms_rate .* (ii-1) .* ( cms_df(:,ii) ./ cms_df(:,1) ).^2;
        end
        ret += -(columns(cms_df)-1) .* (cms_df(:,end) ./ cms_df(:,1) ).^2;
    end
end

% second derivative of P
function ret = ddP(cms_df,cms_rate,comp_type)
    ret = 0.0;
    if ( regexpi(comp_type,'cont'))
        for ii=2:1:columns(cms_df)
            ret += 2 .* cms_rate .* (ii-1)^2 .* ( cms_df(:,ii) ./ cms_df(:,1) );
        end
        ret += 2 .* (columns(cms_df)-1)^2 .* (cms_df(:,end) ./ cms_df(:,1) );
        
    else    % simple or discrete (not yet implemented) compounding
        for ii=2:1:columns(cms_df)
            ret += 2 .* cms_rate .* (ii-1)^2 .* ( cms_df(:,ii) ./ cms_df(:,1) ).^3;
        end
        ret += 2 .* (columns(cms_df)-1)^2 .* (cms_df(:,end) ./ cms_df(:,1) ).^3;
    end
end
%######################


%!test
%! valuation_date = datenum('31-Dec-2015');
%! t1 = 3650;
%! t2 = 1825;
%! swap = Bond();
%! swap = swap.set('Name','SWAP_FLOAT','coupon_rate',0.00,'value_base',1,'coupon_generation_method','forward','last_reset_rate',-0.000,'sub_type','SWAP_FLOATING','spread',0.00);
%! swap = swap.set('maturity_date',datestr(valuation_date + t1 + t2),'notional',1,'compounding_type','simple','issue_date', datestr(valuation_date + t1),'term',365,'notional_at_end',0,'notional_at_start',0);
%! value_type = 'base';  
%! model = 'Black'; 
%! sigma = 0.80; 
%! ref_curve = Curve();
%! ref_curve = ref_curve.set('id','EUR-SWAP','nodes',[3650,4015,4380,4745,5110,5475],'rates_base',[0.005563194,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821], 'rates_stress',[0.005563194,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821;0.005563194,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821],'method_interpolation','linear');
%! [cms_rate convex_adj] = get_cms_rate(valuation_date,value_type,swap,ref_curve,sigma,model);
%! assert(cms_rate,0.0236882325476831,0.0000001);
%! assert(convex_adj,0.00757345168259905,0.0000001);
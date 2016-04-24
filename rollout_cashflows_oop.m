%# Copyright (C) 2015 Schinzilord <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{ret_dates} @var{ret_values}] =} rollout_cashflows_oop (@var{bond_struct})
%# @deftypefnx  {Function File} {[@var{ret_dates} @var{ret_values}] =} rollout_cashflows_oop (@var{bond_struct}, @var{tmp_nodes}, @var{tmp_rates}, @var{valuation_date}, @var{method_interpolation})
%#
%# Compute the dates and values of cash flows given definitions for fixed rate bonds, floating rate notes and zero coupon bonds.@*
%# In the 'oop' version no input data checks are performed. @* 
%# Pre-requirements:@*
%# @itemize @bullet
%# @item installed octave finance package
%# @item custom functions timefactor, discount_factor, get_forward_rate and interpolate_curve
%# @end itemize
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{bond_struct}: Structure with relevant information for specification of the bond:@*
%#      @itemize @bullet
%#      @item bond_struct.type:                	Fixed Rate Bond (FRB), Floating Rate Note (FRN), Zero Coupon Bond (ZCB), Fixed Amortizing Bond (FAB)
%#      @item bond_struct.issue_date:          	Issue Date of Fixed Rate bond [DD-Mmm-YYYY]
%#      @item bond_struct.maturity_date:       	Maturity Date of Fixed Rate bond  [DD-Mmm-YYYY]
%#      @item bond_struct.compounding_type:    	Compounding Type [simple,disc,cont]
%#      @item bond_struct.compounding_freq:    	Compounding Frequency for coupon rates per year [1,2,4,12]
%#      @item bond_struct.term:                	Term of coupon payments in months [12,6,3,1]
%#      @item bond_struct.day_count_convention: 	Day Count Convention 
%#      @item bond_struct.notional:            	Notional Amount
%#      @item bond_struct.notional_at_start:    Boolean Parameter: Notional Amount paid at start
%#      @item bond_struct.notional_at_end:      Boolean Parameter: Notional Amount paid at maturity
%#      @item bond_struct.coupon_rate:         	Coupon Rate
%#      @item bond_struct.coupon_generation_method: 	Coupon Generation Method (forward, backward, zero)
%#      @item bond_struct.business_day_rule:   	Business day rule: days added to payment date
%#      @item bond_struct.business_day_direction: 	Business day direction: 1 
%#      @item bond_struct.enable_business_day_rule: 	Boolean flag for enabling business day rule
%#      @item bond_struct.spread:              	Constant Spread applied to forward rates
%#      @item bond_struct.long_first_period:   	Boolean parameter for long first coupon period, otherwise short (regular) period
%#      @item bond_struct.long_last_period:    	Boolean parameter for long last coupon period, otherwise short (regular) period
%#      @item bond_struct.last_reset_rate:	    Last reset rate used for determining fist cash flow of FRN
%#      @item bond_struct.fixed_annuity         Boolean parameter: true = annuity loan (total annuity payment is fixed), false = amortizable loan (amortization rate is fixed, interest payments variable)
%#      @item bond_struct.in_arrears            Boolean parameter: true = payments at end of period, false: payments at beginning of period (default)
%#      @end itemize
%# @item @var{tmp_nodes}: only relevant for type FRN: tmp_nodes is a 1xN vector with all timesteps of the given curve
%# @item @var{tmp_rates}: only relevant for type FRN: tmp_rates is a MxN matrix with curve rates defined in columns. Each row contains a specific scenario with different curve structure
%# @item @var{ret_dates}: returns a 1xN vector with time in days until all cash flows
%# @item @var{ret_values}: returs a MxN matrix with all cash flow values at each time step. Each cf row corresponds to rates defined in tmp_rates
%# @item @var{valuation_date}: Optional: valuation date
%# @item @var{method_interpolation}: Optional: interpolation method used for retrieving forward rate
%# @end itemize
%# @seealso{timefactor, discount_factor, get_forward_rate, interpolate_curve}
%# @end deftypefn

function [ret_dates ret_values] = rollout_cashflows_oop(bond,tmp_nodes,tmp_rates,valuation_date,method_interpolation)
% Parse bond struct
if nargin < 1 || nargin > 5
    print_usage ();
 end
if nargin < 4
    valuation_date = today;
    method_interpolation = 'smith-wilson';
end
if (nargin > 3)
    if (ischar(valuation_date))
        valuation_date = datenum(valuation_date); 
    end
end 
if (nargin < 5)
    method_interpolation = 'smith-wilson';
end
% --- Checking object field items --- 
    compounding_type = bond.compounding_type;
    issue_date = bond.issue_date;
    day_count_convention = bond.day_count_convention;
    coupon_rate  = bond.coupon_rate;
    coupon_generation_method = bond.coupon_generation_method; 
    notional_at_start = bond.notional_at_start; 
    notional_at_end = bond.notional_at_end; 
    business_day_rule = bond.business_day_rule;
    business_day_direction = bond.business_day_direction;
    enable_business_day_rule = bond.enable_business_day_rule;
    long_first_period = bond.long_first_period;
    long_last_period = bond.long_last_period;
    spread = bond.spread;
    in_arrears_flag = bond.in_arrears;

% --- Checking mandatory structure field items --- 

    type = bond.sub_type;
    if (  strcmp(type,'ZCB') == 1 )
        coupon_generation_method = 'zero';
        bond.term = '0';
    elseif ( strcmp(type,'FRN') == 1 || strcmp(type,'SWAP_FLOAT') == 1)

            last_reset_rate = bond.last_reset_rate;

    elseif ( strcmp(type,'FAB') == 1)
        
            fixed_annuity_flag = bond.fixed_annuity;

    end
    notional = bond.notional;
    term = bond.term;
    compounding_freq = bond.compounding_freq;
    maturity_date = bond.maturity_date;

% check for existing interest rate curve for FRN
if (nargin < 2 && strcmp(type,'FRN') == 1)
    error('Too few arguments. No existing IR curve (nodes and rates) for type FRN.');
end

if (nargin < 2 && strcmp(type,'SWAP_FLOAT') == 1)
    error('Too few arguments. No existing IR curve (nodes and rates) for type FRN.');
end

if ( datenum(issue_date) > datenum(maturity_date ))
    error('Error: Issue date later than maturity date');
end

% ----------------------------------------------------------------------------------------
% Start Calculation:
issuevec = datevec(issue_date);
todayvec = datevec(valuation_date);
matvec = datevec(maturity_date);

%      Valid Basis are:
%            0 = act/act (default)
%            1 = 30/360 SIA
%            2 = act/360
%            3 = act/365
%            4 = 30/360 PSA
%            5 = 30/360 ISDA
%            6 = 30/360 European
%            7 = act/365 Japanese
%            8 = act/act ISMA
%            9 = act/360 ISMA
%           10 = act/365 ISMA
%           11 = 30/360E (ISMA)
dcc_cell = cellstr( ['act/act';'30/360 SIA';'act/360';'act/365';'30/360 PSA';'30/360 ISDA';'30/360 European';'act/365 Japanese';'act/act ISMA';'act/360 ISMA';'act/365 ISMA';'30/360E']);
findvec = strcmp(day_count_convention,dcc_cell);
tt = 1:1:length(dcc_cell);
tt = (tt - 1)';
dcc = dot(single(findvec),tt);
%-------------------------------------------------------------------------------------------------------
% cashflow rollout: method backwards
if ( strcmp(coupon_generation_method,'backward') == 1 )
cf_date = matvec;
cf_dates = cf_date;

while datenum(cf_date) >= datenum(issue_date)
    cf_year = cf_date(:,1);
    cf_month = cf_date(:,2);
    cf_day  = cf_date(:,3);
    cf_original_day  = matvec(:,3);
    
    % depending on frequency, adjust year, month or day
    % rollout for annual (compounding frequency = 1 payment per year)
    if ( term == 12)
        new_cf_year = cf_year - 1;
        new_cf_month = cf_month;
        new_cf_day = cf_day;
    % rollout for semi-annual (compounding frequency = 2 payments per year)
    elseif ( term == 6)
        new_cf_year = cf_year;
        new_cf_month = cf_month - 6;
        if ( new_cf_month <= 0 )
            new_cf_month = cf_month + 6;
            new_cf_year = cf_year - 1;
        end
        % error checking for end of month
        new_cf_day = check_day(new_cf_year,new_cf_month,cf_original_day);
    % rollout for quarter (compounding frequency = 4 payments per year)
    elseif ( term == 3)
        new_cf_year = cf_year;
        new_cf_month = cf_month - 3;
        if ( new_cf_month <= 0 )
            new_cf_month = cf_month + 9;
            new_cf_year = cf_year - 1;
        end
        % error checking for end of month
        new_cf_day = check_day(new_cf_year,new_cf_month,cf_original_day);
    % rollout for monthly (compounding frequency = 12 payments per year)
    elseif ( term == 1)
        cf_day = cf_original_day;
        new_cf_year = cf_year;
        new_cf_month = cf_month - 1;
        if ( new_cf_month <= 0 )
            new_cf_month = cf_month + 11;
            new_cf_year = cf_year - 1;
        end
        % error checking for end of month
        new_cf_day = check_day(new_cf_year,new_cf_month,cf_original_day);
    end
        
    cf_date = [new_cf_year, new_cf_month, new_cf_day, 0, 0, 0];
    if datenum(cf_date) >= datenum(issue_date) 
        cf_dates = [cf_dates ; cf_date];
    end
endwhile % end coupon generation backward


% cashflow rollout: method forward
elseif ( strcmp(coupon_generation_method,'forward') == 1 )
cf_date = issuevec;
cf_dates = cf_date;

while datenum(cf_date) <= datenum(maturity_date)
    cf_year = cf_date(:,1);
    cf_month = cf_date(:,2);
    cf_day  = cf_date(:,3);
    cf_original_day  = issuevec(:,3);
    
    % depending on frequency, adjust year, month or day
    % rollout for annual (compounding frequency = 1 payment per year)
    if ( term == 12)
        new_cf_year = cf_year + 1;
        new_cf_month = cf_month;
        new_cf_day = cf_day;
    % rollout for semi-annual (compounding frequency = 2 payments per year)
    elseif ( term == 6)
        new_cf_year = cf_year;
        new_cf_month = cf_month + 6;
        if ( new_cf_month >= 13 )
            new_cf_month = cf_month - 6;
            new_cf_year = cf_year + 1;
        end
        % error checking for end of month
        new_cf_day = check_day(new_cf_year,new_cf_month,cf_original_day);
    % rollout for quarter (compounding frequency = 4 payments per year)
    elseif ( term == 3)
        new_cf_year = cf_year;
        new_cf_month = cf_month + 3;
        if ( new_cf_month >= 13 )
            new_cf_month = cf_month - 9;
            new_cf_year = cf_year + 1;
        end
        % error checking for end of month
        new_cf_day = check_day(new_cf_year,new_cf_month,cf_original_day);
    % rollout for monthly (compounding frequency = 12 payments per year)
    elseif ( term == 1)
        cf_day = cf_original_day;
        new_cf_year = cf_year;
        new_cf_month = cf_month + 1;
        if ( new_cf_month >= 13 )
            new_cf_month = cf_month - 11;
            new_cf_year = cf_year + 1;
        end
        % error checking for end of month
        new_cf_day = check_day(new_cf_year,new_cf_month,cf_original_day);
    end
        
    cf_date = [new_cf_year, new_cf_month, new_cf_day, 0, 0, 0];
    if datenum(cf_date) <= datenum(maturity_date) 
        cf_dates = [cf_dates ; cf_date];
    end
endwhile        % end coupon generation forward
%-------------------------------------------------------------------------------------------------------
% cashflow rollout: method zero
elseif ( strcmp(coupon_generation_method,'zero') == 1 )
    % rollout for zero coupon bonds -> just one cashflow at maturity
        cf_dates = [issuevec ; matvec];
end 
%-------------------------------------------------------------------------------------------------------     

% Sort CF Dates:
cf_dates = datevec(sort(datenum(cf_dates)));

%-------------------------------------------------------------------------------------------------------
% Adjust first and last coupon period to implement issue date:
if (long_first_period == true)
    if ( datenum(cf_dates(1,:)) > datenum(issue_date) )
        cf_dates(1,:) = issuevec;
    end
else
    if ( datenum(cf_dates(1,:)) > datenum(issue_date) )
        cf_dates = [issuevec;cf_dates];
    end    
end
if (long_last_period == true)
    if ( datenum(cf_dates(rows(cf_dates),:)) < datenum(maturity_date) )
        cf_dates(rows(cf_dates),:) = matvec;
    end
else
    if ( datenum(cf_dates(rows(cf_dates),:)) < datenum(maturity_date) )
        cf_dates = [cf_dates;matvec];
    end
end
cf_business_dates = datevec(busdate(datenum(cf_dates)-1 + business_day_rule,business_day_direction));
cf_dates = cf_dates;
%-------------------------------------------------------------------------------------------------------


%-------------------------------------------------------------------------------------------------------
% %#%#%#%#%#   Calculate Cash Flow values depending on type   %#%#%#%#%#   
%
% Type FRB: Calculate CF Values for all CF Periods
if ( strcmp(type,'FRB') == 1 || strcmp(type,'SWAP_FIXED') == 1 )
    cf_datesnum = datenum(cf_dates);
    %cf_datesnum = cf_datesnum((cf_datesnum-today)>0)
    d1 = cf_datesnum(1:length(cf_datesnum)-1);
    d2 = cf_datesnum(2:length(cf_datesnum));
    for ii = 1: 1 : length(d2)
        cf_values(ii) = ((1 ./ discount_factor (d1(ii), d2(ii), coupon_rate, compounding_type, dcc, compounding_freq)) - 1) .* notional;
    end
    ret_values = cf_values;
    % Add notional payments
    if ( notional_at_start == 1)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - notional;     
    end
    if ( notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + notional;
    end
    
% Type FRN: Calculate CF Values for all CF Periods with forward rates based on spot rate defined 
elseif ( strcmp(type,'FRN') == 1 || strcmp(type,'SWAP_FLOAT') == 1 )
    cf_datesnum = datenum(cf_dates);
    %cf_datesnum = cf_datesnum((cf_datesnum-valuation_date)>0);
    d1 = cf_datesnum(1:length(cf_datesnum)-1);
    d2 = cf_datesnum(2:length(cf_datesnum));
    notvec = zeros(1,length(d1));
    notvec(length(notvec)) = 1;
    cf_values = zeros(rows(tmp_rates),length(d1));
    for ii = 1 : 1 : length(d1)
        % convert dates into years from tody
        [tf dip dib] = timefactor (d1(ii), d2(ii), dcc);
        t1 = (d1(ii) - valuation_date) ./ dib;
        t2 = (d2(ii) - valuation_date) ./ dib;
        if ( t1 > 0 && t2 > 0 )             % for future cash flows use forward rates
            forward_rate = (spread + get_forward_rate(tmp_nodes,tmp_rates,t1,t2-t1,compounding_type,method_interpolation)) .* tf;
        elseif ( t1 < 0 && t2 > 0 )         % if last cf date is in the past, while next is in future, use last reset rate
            forward_rate = last_reset_rate .* tf;
        else    % if both cf dates t1 and t2 lie in the past omit cash flow
            forward_rate = 0.0;
        end
        cf_values(:,ii) = forward_rate;
    end
    ret_values = cf_values .* notional;
    % Add notional payments
    if ( notional_at_start == true)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - notional;     
    end
    if ( notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + notional;
    end
% Type ZCB: Zero Coupon Bond has notional cash flow at maturity date
elseif ( strcmp(type,'ZCB') == 1 )   
    ret_values = notional;
    
% Type FAB: Calculate CF Values for all CF Periods for fixed amortizing bonds (annuity loans and amortizable loans)
elseif ( strcmp(type,'FAB') == 1 )
    % fixed annuity: fixed total payments     
    if ( fixed_annuity_flag == 1)    
        number_payments = length(cf_dates) -1;
        m = compounding_freq;
        total_term = number_payments / m ; % total term of annuity in years
        if ( in_arrears_flag == 1)  % in arrears payments (at end of period)    
            rate = (notional * (( 1 + coupon_rate )^total_term * coupon_rate ) / (( 1 + coupon_rate )^total_term - 1) ) / (m + coupon_rate / 2 * ( m + 1 ));            
        else                        % in advance payments
            rate = (notional * (( 1 + coupon_rate )^total_term * coupon_rate ) / (( 1 + coupon_rate )^total_term - 1) ) / (m + coupon_rate / 2 * ( m - 1 ));   
        end  
        ret_values = ones(1,number_payments) .* rate;
    % fixed amortization: only amortization is fixed, coupon payments are variable
    else                            
        number_payments = length(cf_dates) -1;
        m = compounding_freq;
        total_term = number_payments / m;                             % total term of annuity in years
        amortization_rate = notional / number_payments;  
        cf_datesnum = datenum(cf_dates);
        d1 = cf_datesnum(1:length(cf_datesnum)-1);
        d2 = cf_datesnum(2:length(cf_datesnum));
        cf_values = zeros(1,number_payments);
        amount_outstanding = notional;
        for ii = 1: 1 : number_payments
            cf_values(ii) = ((1 ./ discount_factor (d1(ii), d2(ii), coupon_rate, compounding_type, dcc, compounding_freq)) - 1) .* amount_outstanding;
            amount_outstanding = amount_outstanding - amortization_rate;
        end
        ret_values = cf_values + amortization_rate;
    end    
end
%-------------------------------------------------------------------------------------------------------

cf_dates;
cf_business_dates;
ret_dates = datenum(cf_business_dates)(2:rows(cf_business_dates));
if enable_business_day_rule == 1
    pay_dates = cf_business_dates;
else
    pay_dates = cf_dates;
end
pay_dates(1,:)=[];
ret_dates = datenum(pay_dates)' - valuation_date;
ret_dates = ret_dates(ret_dates>0);
ret_values = ret_values(:,(end-length(ret_dates)+1):end);

end



%----------------------------------------------------------------------------------
%                           Helper Functions
%----------------------------------------------------------------------------------
function new_cf_day = check_day(cf_year,cf_month,cf_day)
 % error checking for valid days 29,30 or 31 at end of month
        if ( cf_day <= 28 )
            new_cf_day = cf_day;
        elseif ( cf_day == 29 || cf_day == 30 )
            if ( cf_month == 2 )
                if ( yeardays(cf_year) == 366 )
                    new_cf_day = 29;
                else
                    new_cf_day = 28;
                end
            else
                new_cf_day = cf_day;
            end
        elseif ( cf_day == 31 ) 
            new_cf_day = eomday (cf_year, cf_month);
        end
        
end


%check_busi_day = isbusday(datenum(cd_business_dates)),
%diff_dates = diff( [datenum(issue_date) ; datenum(cf_dates)]);

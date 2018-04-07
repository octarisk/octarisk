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
%# @deftypefn {Function File} {[@var{ret_dates} @var{ret_values} @var{accrued_interest}] =} rollout_structured_cashflows (@var{valuation_date}, @var{value_type}, @var{instrument}, @var{ref_curve}, @var{surface}, @var{riskfactor})
%#
%# Compute cash flow dates and cash flows values,
%# accrued interests and last coupon date for fixed rate bonds, 
%# floating rate notes, amortizing bonds, zero coupon bonds and 
%# structured products like caps and floors, CM Swaps, capitalized or averaging
%# CMS floaters or inflation linked bonds.
%#
%# @seealso{timefactor, discount_factor, get_forward_rate, interpolate_curve}
%# @end deftypefn

function [ret_dates ret_values ret_interest_values ret_principal_values ...
                                    accrued_interest last_coupon_date] = ...
                    rollout_structured_cashflows(valuation_date, value_type, ...
                    instrument, ref_curve, surface,riskfactor)

% Input checks
if nargin < 3 || nargin > 6
    print_usage ();
end
if nargin < 4
    ref_curve = [];
    surface = [];
    riskfactor = [];
end  
if nargin < 5
    surface = [];
    riskfactor = [];
end  
if nargin < 6
    riskfactor = [];
end  

% ######################   Initial fill of para structure ###################### 
para = fill_para_struct(nargin,valuation_date, value_type, ...
                    instrument, ref_curve, surface,riskfactor);

% ######################   Calculate Cash Flow dates  ##########################   
para = get_cf_dates(para);
    
% ############   Calculate Cash Flow values depending on type   ################   
% Type Fixed Rate Bonds
if ( strcmpi(para.type,'FRB') || strcmpi(para.type,'SWAP_FIXED') )
    para = get_cfvalues_FRB(para.valuation_date, value_type, para, instrument);

% Type ZCB: Zero Coupon Bond has notional cash flow at maturity date
elseif ( strcmpi(para.type,'ZCB'))   
    para.ret_values = para.notional;
    para.cf_principal = para.notional;
    para.cf_interest = 0;
    
% Type FRN: Calculate CF Values for all CF Periods with forward rates based on 
elseif ( strcmpi(para.type,'FRN') || strcmpi(para.type,'SWAP_FLOATING') ...
                    || strcmpi(para.type,'CAP') || strcmpi(para.type,'FLOOR'))
    para = get_cfvalues_FRNCAPFLOOR(para.valuation_date, value_type, ...
                                                    para, instrument, surface);

% Type Inflation Linked Bonds: Calculate CPI adjustedCF Values 
elseif ( strcmpi(para.type,'ILB') || strcmpi(para.type,'CAP_INFL') ...
                                        || strcmpi(para.type,'FLOOR_INFL') )
    para = get_cfvalues_ILB(para.valuation_date, value_type, para, ...
                                    instrument, ref_curve, surface, riskfactor);
                                                    
% Type Credit Default Swaps
elseif ( strcmpi(para.type,'CDS_FIXED') || strcmpi(para.type,'CDS_FLOATING') )
    para = get_cfvalues_CDS(para.valuation_date, value_type, para, ...
                                    instrument, ref_curve, surface, riskfactor);

% Type Forward Rate Agreement   
elseif ( strcmpi(para.type,'FRA') )
    para = get_cfvalues_FRA(para.valuation_date, value_type, para, instrument);

% Type Forward Volatility Agreement 
elseif ( strcmpi(para.type,'FVA') )
    para = get_cfvalues_FVA(para.valuation_date, value_type, para, ...
                                                        instrument, surface);


% Type Averaging FRN: Average forward or historical rates of cms_sliding period
elseif ( strcmpi(para.type,'FRN_FWD_SPECIAL') ...
                            || strcmpi(para.type,'SWAP_FLOATING_FWD_SPECIAL'))
    para = get_cfvalues_FRN_FWD_SPECIAL(para.valuation_date, value_type, ...
                                                    para, instrument, surface);
    
% Special floating types (capitalized, average, min, max) based on CMS rates
elseif ( strcmpi(para.type,'FRN_SPECIAL') || strcmpi(para.type,'FRN_CMS_SPECIAL'))
    para = get_cfvalues_FRN_SPECIAL(para.valuation_date, value_type, ...
                                        para, instrument, ref_curve, surface);

% Type CMS and CMS Caps/Floors: Calculate CF Values with cms rates
elseif ( strcmpi(para.type,'CMS_FLOATING') || strcmpi(para.type,'CAP_CMS') ...
                                            || strcmpi(para.type,'FLOOR_CMS'))
    para = get_cfvalues_CMS_FLOATING_CAPFLOOR(para.valuation_date, ...
                            value_type, para, instrument, ref_curve, surface);
   
% Type FAB: Calculate CF Values for all CF Periods for fixed amortizing bonds 
elseif ( strcmpi(para.type,'FAB'))
    para = get_cfvalues_FAB(para.valuation_date, value_type, para, ...
                                    instrument, ref_curve, surface, riskfactor);

else
    error('rollout_structured_cashflows: Unknown instrument type >>%s<<',any2str(para.type));
end

% ####################   Calculate Final Cash Flow values  #####################   
para    = get_final_cf_values(para);

% ######################   Calculate Accrued Interest  #########################   
para    = calc_accrued_interest(para);

% ###################   prepare main function return values  ###################   
ret_dates               = para.ret_dates;
ret_values              = para.ret_values;
ret_interest_values     = para.ret_interest_values;
ret_principal_values    = para.ret_principal_values;
last_coupon_date        = para.last_coupon_date;
accrued_interest        = para.accrued_interest;

end % end of main function

% ##############################################################################
% ##############################################################################

%-------------------------------------------------------------------------------
%                 General Helper Functions
%-------------------------------------------------------------------------------
function para = calc_accrued_interest(para)
% calculate time in days from last coupon date (zero if valuation_date == coupon_date)
ret_date_last_coupon = para.ret_dates_all_cfs(para.ret_dates_all_cfs<0);

% distinguish three different cases:
% A) issue_date.......first_cf_date...valuation_date....2nd_cf_date.....mat_date
% B) valuation_date...issue_date......first_cf_date.....2nd_cf_date.....mat_date
% C) issue_date.......valuation_date..first_cf_date.....2nd_cf_date.....mat_date

% adjustment to accrued interest required if calculated
% from next cashflow (background: next cashflow is adjusted for
% for actual days in period (in e.g. act/365 dcc), so the
% CF has to be adjusted back by 355/366 in leap year to prevent
% double counting of one day
% therefore a generic approach was chosen where the time factor is always 
% adjusted by actual days in year / days in leap year

if length(ret_date_last_coupon) > 0                 % CASE A
    para.last_coupon_date = ret_date_last_coupon(end);
    ret_date_last_coupon = -ret_date_last_coupon(end);  
    [tf dip dib] = timefactor (para.valuation_date - ret_date_last_coupon, ...
                            para.valuation_date, para.dcc);
    % correct next coupon payment if leap year
    % adjustment from 1 to 365 days in base for act/act
    if dib == 1
        dib = 365;
    end    
    days_from_last_coupon = ret_date_last_coupon;
    days_to_next_coupon = para.ret_dates(1);
    adj_factor = dib / (days_from_last_coupon + days_to_next_coupon);
    if ~( para.term == 365)
        adj_factor = adj_factor .* para.term / 12;
    end
    tf = tf * adj_factor;
else
    % last coupon date is first coupon date for Cases B and C:
    para.last_coupon_date = para.ret_dates(1);
    % if valuation date before issue date -> tf = 0
    if ( para.valuation_date <= para.issuedatenum )    % CASE B
        tf = 0;
        
    % valuation date after issue date, but before first cf payment date
    else                                            % CASE C
        [tf dip dib] = timefactor(para.issue_date,para.valuation_date,para.dcc);
        days_from_last_coupon = para.valuation_date - para.issuedatenum;
        days_to_next_coupon = para.ret_dates(1) ; 
        adj_factor = dib / (days_from_last_coupon + days_to_next_coupon);
        if ~( term == 365)
        adj_factor = adj_factor * para.term / 12;
        end
        tf = tf .* adj_factor;
    end
end
% value of next coupon -> accrued interest is pro-rata share of next coupon
ret_value_next_coupon = para.ret_interest_values(:,1);

% scale tf according to term:
if ~( para.term == 365 || para.term == 0)
    tf = tf * 12 / para.term;
% term = maturity --> special calculation for accrued int
elseif ( para.term == 0) 
    if ( para.valuation_date <= para.issuedatenum )    % CASE B
        tf = 0;
    else                                            % CASE A/C
        tf_id_md = timefactor(para.issuedatenum, para.maturitydatenum, para.dcc);
        tf_id_vd = timefactor(para.issuedatenum, para.valuation_date, para.dcc);
        tf = tf_id_vd ./ tf_id_md;
    end
end

% TODO: why is there a vector of accrued_interest with length of
%       scenario values for FRB in case C?
para.accrued_interest = ret_value_next_coupon .* tf;
para.accrued_interest = para.accrued_interest(1);

end

% ##############################################################################
function [para] = get_final_cf_values(para)

    % special treatment for term == 0 (means all cash flows summed up at Maturity)
    if ( para.term == 0 )
        para.cf_dates = [para.issuevec;para.cf_dates(end,:)];
        para.cf_business_dates = [para.issuevec;para.cf_business_dates(end,:)];
        para.ret_values = sum(para.ret_values,2);
        para.cf_interest = sum(para.cf_interest,2);
        para.cf_principal = sum(para.cf_principal,2);
    end
    % end special treatment

    % apply business day rules
    if para.enable_business_day_rule == 1
        pay_dates_num = para.cf_business_datesnum;
    else
        pay_dates_num = para.cf_datesnum;
    end
    para.ret_dates_all_cfs = pay_dates_num - para.valuation_date;
    % delete first cf date, if no cf occurs
    if ( sum(para.ret_values(:,1)) == 0.0)
        pay_dates_num(1,:)=[];
    end

    para.ret_dates = pay_dates_num' - para.valuation_date;

    if ( columns(para.ret_values) < columns(para.ret_dates))
        para.ret_dates = para.ret_dates(end-columns(para.ret_values)+1:end);
    end

    % calculate final return vectors for dates, total, interest and principal cash flows
    para.ret_dates = para.ret_dates(para.ret_dates>0);  % only future cash flows
    para.ret_values = para.ret_values(:,(end-length(para.ret_dates)+1):end);
    para.ret_interest_values = para.cf_interest(:,(end-length(para.ret_dates)+1):end);
    para.ret_principal_values = para.cf_principal(:,(end-length(para.ret_dates)+1):end);

end % end get_final_cf_values

% ##############################################################################
function para = fill_para_struct(nargin,valuation_date, value_type, ...
                    instrument, ref_curve, surface,riskfactor)
                    
para = struct();
para.valuation_date = valuation_date;
if (ischar(valuation_date))
    para.valuation_date = datenum(valuation_date,1); 
end

if nargin > 3 
% get curve variables:
    para.tmp_nodes    = ref_curve.get('nodes');
    para.tmp_rates    = ref_curve.getValue(value_type);

% Get interpolation method and other curve related attributes
    para.method_interpolation = ref_curve.get('method_interpolation');
    para.basis_curve     = ref_curve.get('basis');
    para.comp_type_curve = ref_curve.get('compounding_type');
    para.comp_freq_curve = ref_curve.get('compounding_freq');
end
       
% --- Checking object field items --- 
    para.compounding_type = instrument.compounding_type;
    if (strcmp(instrument.issue_date,'01-Jan-1900'))
        para.issue_date = datestr(valuation_date);
    else
        para.issue_date = instrument.issue_date;
    end
    para.day_count_convention    = instrument.day_count_convention;
    para.dcc                     = instrument.basis;
    para.coupon_rate             = instrument.coupon_rate;
    para.coupon_generation_method = instrument.coupon_generation_method; 
    para.notional_at_start       = instrument.notional_at_start; 
    para.notional_at_end         = instrument.notional_at_end; 
    para.business_day_rule       = instrument.business_day_rule;
    para.business_day_direction  = instrument.business_day_direction;
    para.enable_business_day_rule = instrument.enable_business_day_rule;
    para.long_first_period       = instrument.long_first_period;
    para.long_last_period        = instrument.long_last_period;
    para.spread                  = instrument.spread;
    para.in_arrears_flag         = instrument.in_arrears;
    % floor forward rate at 0.000001:
    para.floor_flag = false;        % false: default setting, no global parameter
% --- Checking mandatory structure field items --- 

    para.type = instrument.sub_type;
    if (  strcmpi(para.type,'ZCB') || strcmpi(para.type,'FRA') || strcmpi(para.type,'FVA'))
        para.coupon_generation_method = 'zero';
    elseif ( strcmpi(para.type,'FRN') || strcmpi(para.type,'SWAP_FLOATING') ...
                    || strcmpi(para.type,'CAP') || strcmpi(para.type,'FLOOR'))
            para.last_reset_rate = instrument.last_reset_rate;
    elseif ( strcmpi(para.type,'FAB'))
            para.fixed_annuity_flag = instrument.fixed_annuity;
            para.use_principal_pmt_flag = instrument.use_principal_pmt;
            para.use_annuity_amount = instrument.use_annuity_amount;
    end
    para.notional = instrument.notional;
    para.term = instrument.term;
    para.term_unit = instrument.term_unit;
    para.compounding_freq = instrument.compounding_freq;
    para.maturity_date = instrument.maturity_date;
    
    if ( para.term != 0)
        if ( strcmpi(para.term_unit,'months'))
            para.term_factor = 12 / para.term;
        elseif ( strcmpi(para.term_unit,'days') )
            para.term_factor = 365 / para.term;
        else % years
            para.term_factor = 1 / para.term;
        end
    else % Special case: all cash flows are paid at maturity
        para.term = datenum(para.maturity_date) - datenum(para.issue_date);
        para.term_unit = 'days';
        para.term_factor = 1;         
    end
    para.comp_freq = para.term_factor;

    %----------------------------------
% check for existing interest rate curve for FRN
if (nargin < 2 && strcmp(para.type,'FRN') == 1)
    error('Too few arguments. No existing IR curve for type FRN.');
end

if (nargin < 2 && strcmp(para.type,'SWAP_FLOATING') == 1)
    error('Too few arguments. No existing IR curve for type FRN.');
end

% assume format of dates to be dd-mmm-yyyy to speed up conversion
if ( ischar(para.maturity_date))
    para.maturitydatenum = datenum_fast(para.maturity_date,1);
else
    para.maturitydatenum = datenum(para.maturity_date);
end

if ( ischar(para.issue_date))
    para.issuedatenum = datenum_fast(para.issue_date,1);
else
    para.issuedatenum = datenum(para.issue_date);
end

if ( para.issuedatenum > para.maturitydatenum)
    error('Error: Issue date later than maturity date');
end

% return values for cash flows:
para.ret_values     = [0]; 
para.cf_principal   = [0];
para.cf_interest    = [0];
                    
end  % end fill_para
% ##############################################################################

%-------------------------------------------------------------------------------
%                  Instrument Cash Flow rollout Functions
%-------------------------------------------------------------------------------
function para = get_cfvalues_FAB(valuation_date, value_type, para, instrument, ref_curve, surface, riskfactor)  
    % Cash flow rollout for 4 different cases:
    % annuity = total cash flows consisting of principal cash flows and 
    %           interest cash flows
    %
    % 1. FIXED_ANNUITY = true: constant cashflows CF = CF_interest_i + CF_principal_i
    %       1a) USE_ANNUITY_AMOUNT == true, ANNUITY_AMOUNT = XXX:
    %               annuity amount is given by attribute
    %               CF = annuity_amount --> calculate principal and interest CFs
    %       1b) USE_ANNUITY_AMOUNT == false:    
    %               annuity amount is calculation as function(notional, term, coupon rate)
    %               CF = f(not,rate,term) --> calculate principal and interest CFs
    %
    % 2. fixed FIXED_ANNUITY = false: constant principal cashflows, variable interest and notional CFs
    %                           CF_i = CF_principal_fixed + CF_interest_i
    %       2a) USE_PRINCIPAL_PMT_FLAG == true, PRINCIPAL_PAYMENT = [xxx, yyy]
    %               principal payments are given by attribute (principal payment vector)
    %               CF_principal = [vector], calculate interest CFs for outstanding amount
    %       2b) USE_PRINCIPAL_PMT_FLAG == false:
    %               constant amortization rate is calculated as function(notional,number_payments)
    %               CF_principal_i = constant, total CF and CF_interest variable
    %
    %  -------------------------------------------------------------------------------------------- 
    %  (1) FIXED_ANNUITY = true
    %                                         |
    %       a) USE_ANNUITY_AMOUNT == true     | b)  USE_ANNUITY_AMOUNT == false
    %                                         |
    %           CF_TOTAL_t = ANNUITY_AMOUNT = |         CF_TOTAL_t = f(notional,rate,term) = const.
    %                           const.        | 
    %  --------------------------------------------------------------------------------------------
    %                                       
    %  (2) FIXED_ANNUITY = false
    %                                         |
    %       a) USE_PRINCIPAL_PMT_FLAG == true | b)  USE_PRINCIPAL_PMT_FLAG == false
    %                                         |
    %           PRINCIPAL_PAYMENT = [vector]  |         PRINCIPAL_PAYMENT = f(notional,rate,term) = const.
    %                                         |
    %           CF_TOTAL_t = PRINCIPAL_PAYMENT|         CF_TOTAL_t = PRINCIPAL_PAYMENT + CF_interest
    %                       + CF_interest     | 
    %  --------------------------------------------------------------------------------------------
    %
    % fixed annuity: fixed total payments 
    if ( para.fixed_annuity_flag == 1)
        if ( para.use_annuity_amount == 0)   % calculate annuity from coupon rate and notional
            number_payments = rows(para.cf_dates) -1;
            m = para.comp_freq;
            total_term = number_payments / m;  % total term of annuity in years
            % Discrete compounding only with act/365 day count convention
            % TODO: implement simple and continuous compounding for annuity
            %       calculation
            d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
            d2 = para.cf_datesnum(2:length(para.cf_datesnum));
            cf_interest = zeros(1,number_payments);
            amount_outstanding_vec = zeros(1,number_payments);
            if ( para.coupon_rate == 0) % special treatment: pay back notional at maturity
              rate = 0.0;
              amount_outstanding_vec(1) = para.notional;
              cf_principal = zeros(1,number_payments);
              cf_principal(end) = para.notional;    % pay back notional at maturity
              ret_values = cf_principal;
            else
              if ( para.in_arrears_flag == 1)  % in arrears payments (at end of period)
                rate = (para.notional * (( 1 + para.coupon_rate )^total_term * para.coupon_rate ) ...
                                    / (( 1 + para.coupon_rate  )^total_term - 1) ) ...
                                    / (m + para.coupon_rate / 2 * ( m + 1 ));
              else                        % in advance payments
                rate = (para.notional * (( 1 + para.coupon_rate )^total_term * para.coupon_rate ) ...
                                    / (( 1 + para.coupon_rate )^total_term - 1) ) ...
                                    / (m + para.coupon_rate / 2 * ( m - 1 ));
              end
              ret_values = ones(1,number_payments) .* rate;

              % calculate principal and interest cf
              amount_outstanding_vec(1) = para.notional;
              % get interest rates at nodes
              rate_interest = ((1 ./ discount_factor (d1, d2, ...
                                      para.coupon_rate, para.compounding_type, para.dcc, ...
                                      para.compounding_freq)) - 1)';
                                      
              % cashflows of first date
              cf_interest(1) = para.notional.* rate_interest(1);
              % cashflows of remaining dates
              for ii = 2 : 1 : number_payments
                amount_outstanding_vec(ii) = amount_outstanding_vec(ii - 1) ...
                                            - ( rate -  cf_interest(ii-1) );
                cf_interest(ii) = amount_outstanding_vec(ii) .* rate_interest(ii);
              end
              cf_principal = ret_values - cf_interest;
            end   % end coupon_rate <> 0.0
    else    % use fixed given annuity_amount
            annuity_amt = instrument.annuity_amount;
            number_payments = rows(para.cf_dates) -1;
            m = para.comp_freq;
            d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
            d2 = para.cf_datesnum(2:length(para.cf_datesnum));
            cf_interest = zeros(1,number_payments);
            rate_interest = ((1 ./ discount_factor (d1, d2, ...
                                      para.coupon_rate, para.compounding_type, para.dcc, ...
                                      para.compounding_freq)) - 1)';
            amount_outstanding = para.notional;
            %amount_outstanding_vec = zeros(number_payments,1);
            for ii = 1: 1 : number_payments
                cf_interest(ii) = rate_interest(ii) .* amount_outstanding;
                % deduct annuity amount and add back interest cash flows:
                amount_outstanding = amount_outstanding - annuity_amt + cf_interest(ii);
                %amount_outstanding_vec(ii) = amount_outstanding;
            end
            ret_values = annuity_amt .* ones(1,number_payments);
            ret_values(end) = ret_values(end) + amount_outstanding;
            cf_principal = ret_values - cf_interest;
    end
    % fixed amortization: only amortization is fixed, coupon payments are 
    %                       variable
    else
        % given principal payments, used at each cash flow date for amortization
        if ( para.use_principal_pmt_flag == 1)
            number_payments = rows(para.cf_dates) -1;
            m = para.comp_freq;
            princ_pmt = instrument.principal_payment;
            % trim length of principal payments to length of total payments (fill with 0)
            if length(princ_pmt) < number_payments
                princ_pmt = [princ_pmt, zeros(1,number_payments - length(princ_pmt))];
                %fprintf('WARNING: rollout_structured_cashflow: FAB >>%s<< with given principal payments has less cash flows values than dates. Filling with 0.0.\n',instrument.id);
            elseif length(princ_pmt) > number_payments
                princ_pmt = princ_pmt(1:number_payments);
                %fprintf('WARNING: rollout_structured_cashflow: FAB >>%s<< with given principal payments has more cash flows values than dates. Skipping cash flows.\n',instrument.id);
            end

            % calculate principal and interest cf
            d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
            d2 = para.cf_datesnum(2:length(para.cf_datesnum));
            %cf_interest = zeros(1,number_payments);
            amount_outstanding_vec = para.notional - cumsum(princ_pmt);
            cf_interest = amount_outstanding_vec .* ((1 ./ ...
                            discount_factor (d1, d2, para.coupon_rate, ...
                                para.compounding_type, para.dcc, para.compounding_freq))' - 1);

            cf_principal = princ_pmt .* ones(1,number_payments);
            % add outstanding amount at maturity to principal cashflows
            cf_principal(end) = amount_outstanding_vec(end);
            ret_values = cf_principal + cf_interest;
        % fixed amortization rate, total amortization of bond until maturity
        else 
            number_payments = rows(para.cf_dates) -1;
            m = para.comp_freq;
            total_term = number_payments / m;   % total term of annuity in years
            amortization_rate = para.notional / number_payments;  
            d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
            d2 = para.cf_datesnum(2:length(para.cf_datesnum));
            cf_values = zeros(1,number_payments);
            rate_interest = ((1 ./ discount_factor (d1, d2, ...
                                      para.coupon_rate, para.compounding_type, para.dcc, ...
                                      para.compounding_freq)) - 1)';
            amount_outstanding = para.notional;
            amount_outstanding_vec = zeros(number_payments,1);
            for ii = 1: 1 : number_payments
                cf_values(ii) = rate_interest(ii) .* amount_outstanding;
                amount_outstanding = amount_outstanding - amortization_rate;
                amount_outstanding_vec(ii) = amount_outstanding;
            end
            ret_values = cf_values + amortization_rate;
            cf_principal = ret_values - cf_values;
            cf_interest = cf_values;
        %amount_outstanding_vec
        end
    end  
    % prepayment: calculate modified cash flows while including prepayment
    if ( instrument.prepayment_flag == 1)
        
        % Calculation rule:
        % Extract PSA factor either from provided prepayment surface (depending
        % on coupon_rate of FAB instrument and absolute ir shock or kept at 1.
        % The absolute ir shock is extracted from a factor weighing absolute
        % difference of the riskfactor curve base values to value_type values.
        % Then this PSA factor is kept constant for all FAB cash flows.
        % The PSA prepayment rate is extracted either from a constant prepayment
        % rate or from the ref_curve (PSA prepayment rate curve) depending
        % on the cash flow term.
        % Prepayment_rate(i) = psa_factor(const) * PSA_prepayment(i)
        % This prepayment rate is then used to iteratively calculated
        % prepaid principal values and interest rate.
        % 
        % Implementation: use either constant prepayment rate or use prepayment 
        %                   curve for calculation of scaling factor
        pp_type = instrument.prepayment_type; % either full or default
        use_outstanding_balance = instrument.use_outstanding_balance;
        % case 1: prepayment curve:   
        if ( strcmpi(instrument.prepayment_source,'curve'))
            pp_curve_interp = para.method_interpolation;
            pp_curve_nodes = para.tmp_nodes;
            pp_curve_values = para.tmp_rates;
        % case 2: constant prepayment rate: set up pseudo constant curve
        elseif ( strcmpi(instrument.prepayment_source,'rate'))
            pp_curve_interp = 'linear';
            pp_curve_nodes = [0];
            pp_curve_values = instrument.prepayment_rate;
            comp_type_curve = 'cont';
            basis_curve = 3;
            comp_freq_curve = 'annual';
        end
        
        % generate PSA factor dummy surface if not provided
        if (nargin < 5 ||  ~isobject(surface)) 
            pp = Surface();
            pp = pp.set('axis_x',[0.01],'axis_x_name','coupon_rate','axis_y',[0.0], ...
                'axis_y_name','ir_shock','values_base',[1],'type','PREPAYMENT');
        else % take provided PSA factor surface
            pp = surface;
        end
        
        % preallocate memory
        cf_principal_pp = zeros(rows(pp_curve_values),number_payments);
        cf_interest_pp = zeros(rows(pp_curve_values),number_payments);
        
        % calculate absolute IR shock from provided riskfactor curve
        if (nargin < 6 ||  ~isobject(riskfactor)) 
            abs_ir_shock = 0.0;
        else    % calculate absolute IR shock of scenario minus base scenario
            abs_ir_shock_rates =  riskfactor.getValue(value_type) ...
                                - riskfactor.getValue('base');
            % interpolate shock at factor term structure
            abs_ir_shock = 0.0;
            for ff = 1 : 1 : length(instrument.psa_factor_term)
                abs_ir_shock = abs_ir_shock + interpolate_curve(riskfactor.nodes, ...
                                                        abs_ir_shock_rates,ff);    
            end
            abs_ir_shock = abs_ir_shock ./ length(instrument.psa_factor_term);
        end
        % extract PSA factor from prepayment procedure (independent of PSA curve)
        prepayment_factor = pp.interpolate(para.coupon_rate,abs_ir_shock);
                
        % case 1: full prepayment with rate from prepayment curve or 
        %           constant rate
        if ( strcmpi(pp_type,'full'))
            Q_scaling = ones(rows(pp_curve_values),1);
            % if outstanding balance should not be used, the prepayment from
            % all cash flows since issue date are recalculated
            if ( use_outstanding_balance == 0 )
                for ii = 1 : 1 : number_payments 
                     % get prepayment rate at days to cashflow
                    tmp_timestep = d2(ii) - d2(1); 
                    % extract PSA factor from prepayment procedure               
                    prepayment_rate = interpolate_curve(pp_curve_nodes, ...
                                    pp_curve_values,tmp_timestep,pp_curve_interp);
                    prepayment_rate = prepayment_rate .* prepayment_factor;
                    % convert annualized prepayment rate
                    lambda = ((1 ./ discount_factor (d1(ii), d2(ii), ...
                    prepayment_rate, para.comp_type_curve, ...
                    para.basis_curve, para.comp_freq_curve)) - 1);  

                    %       (cf_principal_pp will be matrix (:,ii))
                    cf_principal_pp(:,ii) = Q_scaling .* ( cf_principal(ii) ...
                                        + lambda .* ( amount_outstanding_vec(ii) ...
                                        -  cf_principal(ii ) ));
                    cf_interest_pp(:,ii) = cf_interest(ii) .* Q_scaling;
                    % calculate new scaling Factor
                    Q_scaling = Q_scaling .* (1 - lambda);
                end
            % use_outstanding_balance = true: recalculate cash flow values from
            % valuation date (notional = outstanding_balance) until maturity
            % with current prepayment rates and psa factors
            else
                out_balance = instrument.outstanding_balance;
                % use only payment dates > valuation date  
                original_payments = length(para.cf_dates);
                number_payments = length(para.cf_datesnum);
                d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
                d2 = para.cf_datesnum(2:length(para.cf_datesnum));
                % preallocate memory
                amount_outstanding_vec = zeros(rows(prepayment_factor),number_payments) ...
                                                                .+ out_balance;              
                cf_interest_pp = zeros(rows(prepayment_factor),number_payments);
                cf_principal_pp = zeros(rows(prepayment_factor),number_payments); 
                cf_annuity = zeros(rows(prepayment_factor),number_payments);                
                % calculate all principal and interest cash flows including
                % prepayment cashflows. use future cash flows only
                for ii = 1 : 1 : number_payments
                    if ( para.cf_datesnum(ii) > valuation_date)
                        eff_notional = amount_outstanding_vec(:,ii-1);
                         % get prepayment rate at days to cashflow
                        tmp_timestep = d2(ii-1) - para.issuedatenum;
                        % extract PSA factor from prepayment procedure               
                        prepayment_rate = interpolate_curve(pp_curve_nodes, ...
                                        pp_curve_values,tmp_timestep,pp_curve_interp);
                        prepayment_rate = prepayment_rate .* prepayment_factor;
                        % convert annualized prepayment rate
                        lambda = ((1 ./ discount_factor (d1(ii-1), d2(ii-1), ...
                                            prepayment_rate, para.comp_type_curve, ...
                                            para.basis_curve, para.comp_freq_curve)) - 1);
                        % calculate interest cashflow
                        [tf dip dib] = timefactor (d1(ii-1), d2(ii-1), para.dcc);
                        eff_rate = para.coupon_rate .* tf; 
                        cf_interest_pp(:,ii) = eff_rate .* eff_notional;
                        
                        % annuity principal
                        rem_cf = 1 + number_payments - ii;  %remaining cash flows
                        tmp_interest = cf_interest_pp(:,ii);
                        tmp_divisor = (1 - (1 + eff_rate) .^ (-rem_cf));
                        cf_annuity(:,ii) = tmp_interest ./ tmp_divisor - tmp_interest;
                        
                        %cf_scaled_annuity = (1 - lambda) .* cf_annuity(:,ii);
                        cf_prepayment = eff_notional .* lambda;
                        cf_principal_pp(:,ii) = (1 - lambda) .* cf_annuity(:,ii) + cf_prepayment;
                        %tmp_annuity = cf_annuity(:,ii)
                        %tmp_scaled_annuity = (1 - lambda) .* tmp_annuity
                        % calculate new amount outstanding (remaining amount >0)
                        amount_outstanding_vec(:,ii) = max(0,eff_notional-cf_principal_pp(:,ii));
                    end
                end
            end
        % case 2: TODO implementation
        elseif ( strcmpi(pp_type,'default'))
            cf_interest_pp = cf_interest;
            cf_principal_pp = cf_principal;
        end 
        ret_values_pp = cf_interest_pp + cf_principal_pp;
        % overwrite original values with values including prepayments
        ret_values = ret_values_pp;
        cf_principal = cf_principal_pp;
        cf_interest = cf_interest_pp;
        
    end % end prepayment procedure
    
    para.ret_values     = ret_values;
    para.cf_interest    = cf_interest;
    para.cf_principal   = cf_principal;
end % end get_cfvalues_FAB
% ##############################################################################
function para = get_cfvalues_FRB(valuation_date, value_type, para, instrument)

    d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
    d2 = para.cf_datesnum(2:length(para.cf_datesnum));
    % preallocate memory
    cf_principal = zeros(1,length(d1));
    % calculate all cash flows (assume prorated == true --> deposit method
    cf_values = ((1 ./ discount_factor(d1, d2, para.coupon_rate, ...
                                para.compounding_type, para.dcc, ...
                                para.compounding_freq)) - 1)' .* para.notional;
    % prorated == false: adjust deposit method to bond method --> in case
    % of leap year adjust time period length by adding one day and
    % recalculate cash flow
    if ( instrument.prorated == false) 
        delta_coupon = cf_values - para.coupon_rate .* para.notional;
        delta_prorated = para.notional .* para.coupon_rate / 365;
        if ( abs(delta_coupon - delta_prorated) < sqrt(eps))
            cf_values = ((1 ./ discount_factor(d1+1, d2, ...
                            para.coupon_rate, para.compounding_type, para.dcc, ...
                            para.compounding_freq)) - 1)' .* para.notional;
        end
    end

    ret_values = cf_values;
    cf_interest = cf_values;
    % Add notional payments
    if ( para.notional_at_start == 1)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - para.notional;     
        cf_principal(:,1) = - para.notional;
    end
    if ( para.notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + para.notional;
        cf_principal(:,end) = para.notional;
    end
    
    % return struct
    para.ret_values     = ret_values;
    para.cf_interest    = cf_interest;
    para.cf_principal   = cf_principal;
end % end get_cfvalues_FRB

% ##############################################################################
function para = get_cfvalues_FRA(valuation_date, value_type, para, instrument)
% Type FRA: Calculate CF Value for Forward Rate Agreements
% Forward Rate Agreement has following times and discount factors
% -----X------------------------X---------------------------X----
%      T0           Tt (maturity date FRA)           Tu (underlying mat date)
% Discount Factors:             |---------------------------|
%                                    forward rate ---> du   
%                                    strike rate  ---> dk
% Calculate cashflow as forward discounting of difference of compounded strike 
% and compounded forward rates:
% Cashflow = notional * (1/du - 1/dk) * du = notional * (1 - du / dk)
% Value <---------  discounting  ------    Cashflow at Tt    

    T0 = para.valuation_date;   % valuation_date
    Tt = para.cf_datesnum(2) - T0; % cash flow date = maturity date of FRA
    Tu = datenum(instrument.underlying_maturity_date,1) - T0; % underlyings maturity date
    % preallocate memory
    cf_values = zeros(rows(para.tmp_rates),1);
        
    % only future cashflows, underlying > instrument mat date
    if ( Tu >= Tt && Tt >= 0)   
        % get forward rate from Tt -> Tu
        forward_rate = get_forward_rate(para.tmp_nodes,para.tmp_rates, ...
                    Tt,Tu-Tt,para.compounding_type,para.method_interpolation, ...
                    para.compounding_freq, para.dcc, para.valuation_date, ...
                    para.comp_type_curve, para.basis_curve, para.comp_freq_curve,para.floor_flag);

        % get discount factors
        % underlying forward rate discount factor
        du = discount_factor(Tt, Tu, forward_rate, ...
                                para.comp_type_curve, para.basis_curve, para.comp_freq_curve);
        
        % strike discount factor    
        strike_rate_conv = convert_curve_rates(Tt,Tu,instrument.strike_rate, ...
                'cont','annual',3,para.comp_type_curve,para.comp_freq_curve,para.basis_curve);
        dk_strike = discount_factor(Tt, Tu, strike_rate_conv, ...
                                para.comp_type_curve, para.basis_curve, para.comp_freq_curve);
                                           
        % calculate cash flow
        if ( strcmpi(instrument.coupon_prepay,'discount')) % Coupon Prepay = Discount
            cf_values(:,1) = para.notional .* ( 1 - du ./ dk_strike );
        else    % in fine
            cf_values(:,1) = para.notional .* ( 1 - du ./ dk_strike ) ./ du;
        end
    else    % past cash flows or invalid cash flows
        fprintf('rollout_structured_cashflows: FRA >>%s<< has invalid cash flow dates or invalid (underlyings) maturity date. cf_values = 0.0.\n', instrument.id);
        cf_values = 0.0;
    end
    para.ret_values = cf_values;
    para.cf_principal = cf_values;
    para.cf_interest = 0.0;
end     % end get_cfvalues_FRA
% ##############################################################################
function para = get_cfvalues_FVA(valuation_date, value_type, para, instrument, surface) 
% Type FVA: Calculate CF Value for Forward Volatility Agreements
% Forward Volatility Agreement has following times steps and discount factors
% -----X------------------------X---------------------------X----
%      T0           Tt (maturity date FVA)           Tu (underlying mat date)
% Discount Factors:             |---------------------------|
%                                    volatility at Tu ---> Tu_vol 
%                                    volatility at Tt ---> Tt_vol   
%                                    strike volatility  ---> K_vol
% Calculate cashflow as square root of difference between standardized variances 
% and strike volatility:
% Cashflow = notional * (sqrt( (Tu_vol^2 - Tt_vol^2) / TF_Tu) - K_vol)
% Value <---------  discounting  ------    Cashflow at Tt    
    T0 = para.valuation_date;   % valuation_date
    Tt = para.cf_datesnum(2) - T0; % cash flow date = maturity date of FRA
    Tu = datenum(instrument.underlying_maturity_date,1) - T0; % underlyings maturity date
    
    % only future cashflows, underlying > instrument mat date
    if ( Tu >= Tt && Tt >= 0)   
        if ( strcmpi(surface.type,'IR')) % Surface type IR
            % get volatility according to term, tenor and moneyness 1
            term    = Tu-Tt; % underlying tenor
            Tu_vol  = surface.getValue(value_type,Tu,term,1);
            Tt_vol  = surface.getValue(value_type,Tt,term,1);
        else % Surface type INDEX
            % get volatility according to term and moneyness 1
            Tu_vol  = surface.getValue(value_type,Tu,1);
            Tt_vol  = surface.getValue(value_type,Tt,1);
        end
        % get time factors
        TF_Tu       = timefactor(0,Tu,para.dcc);
        TF_Tt       = timefactor(0,Tt,para.dcc);
        TF_Tt_Tu    = timefactor(Tt,Tu,para.dcc);
        % calculate forward variance
        fwd_var = (Tu_vol.^2 .* TF_Tu - Tt_vol.^2 .* TF_Tt);
        % preallocate memory
        cf_values = zeros(rows(fwd_var),1);
        % calculate final cashflows
        if ( fwd_var > 0.0)
            if ( strcmpi(instrument.fva_type,'volatility'))
                cf_values(:,1) = para.notional .* (sqrt( fwd_var ./ TF_Tt_Tu) - instrument.strike_rate);
            elseif ( strcmpi(instrument.fva_type,'variance'))
                cf_values(:,1) = para.notional .* ( fwd_var ./ TF_Tt_Tu - instrument.strike_rate.^2);
            else
                fprintf('rollout_structured_cashflows: FRV >>%s<< has unknown fva_type >>%s<<\n', instrument.id, instrument.fva_type);
            end
        else    % prevent complex cf values
            fprintf('rollout_structured_cashflows: FRV >>%s<< has negative forward variance. cf_values = 0.0.\n', instrument.id);
            cf_values(:,1) = 0.0;
        end
    else    % past cash flows or invalid cash flows
        fprintf('rollout_structured_cashflows: FRV >>%s<< has invalid cash flow dates or invalid (underlyings) maturity date. cf_values = 0.0.\n', instrument.id);
        cf_values = 0.0;
    end
    para.ret_values = cf_values;
    para.cf_principal = cf_values;
    para.cf_interest = 0.0;
end % end get_cfvalues_FVA
% ##############################################################################
function para = get_cfvalues_CDS(valuation_date, value_type, para, instrument, ref_curve, surface, riskfactor)
    % Type CDS: Calculate CF Values for Credit Default Swaps
    % Valuation according to the probability model.
    % The following CDS types are supported:
    % either receive protection or provide protection (multiply all cash flows by -1)
    % ----------------       premium_leg cashflows   -------------------------------
    % premium leg cash flow dates taken from CDS itself
    % cds_use_initial_premium == false  | cds_use_initial_premium == true
    %                                   |
    % FIXED: CFs from coupon rate       |   use initial_premium for fixed payment
    %           and spread.             |   at issue_date. 
    %                                   |
    % FLOATING: CFs from forward rates  |
    %           of reference curve      |-------------------------------------------
    %
    %  credit_state > DEFAULT: get expectation rates from Hazard curve 
    %  -> calculate expected premium cash flows from survival probabilities
    %  credit_state == DEFAULT: no premium paid in this case
    %
    % ----------------     protection_leg cashflows   ------------------------------ 
    %  credit_state > DEFAULT: get expectation rates from Hazard curve 
    %               protection leg cash flow dates taken from reference asset
    %  -> expected default_cf = 
    %               notional * loss_given_default * survival_prob * hazard_rate
    %  credit_state == DEFAULT: default_cf  = notional * loss_given_default
    %
        
    % For CDS instruments ref_curve is used as hazard curve,
    % surface is used for reference asset, riskfactor as ref object for FLOATER.
    reference_asset = surface;
    hazard_curve = ref_curve;
    
    % get credit state of reference asset -> in default -> premium leg = 0
    %                           protection leg = notional * loss_given_default
    % credit state != default -> payout according default probability weights
    if ( strcmpi(reference_asset.get('credit_state'),'D'))
        cf_interest = 0.0;
        cf_principal = para.notional * instrument.loss_given_default;
        % cashflow one day after valuation date
        para.cf_datesnum = max(para.issuedatenum,para.valuation_date + 1); 
        para.cf_business_datesnum = para.cf_datesnum;
        % adjust sign of cashflows
        if ( instrument.cds_receive_protection == false) % protection provider
            cf_principal = -cf_principal;
        end
        ret_values = cf_principal;
    else    % credit_state != default
    
        % get CF dates from reference_asset:
        ref_cf_dates = reference_asset.get('cf_dates');
        d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
        d2 = para.cf_datesnum(2:length(para.cf_datesnum));
        
        % -------------   premium leg: get interest cash flows  --------------------
        if ( instrument.cds_use_initial_premium == false)
            if ( strcmpi(para.type,'CDS_FIXED') )
                % calculate all cash flows (prorated == true --> deposit method
                cf_interest = ((1 ./ discount_factor(d1, d2, para.coupon_rate, ...
                                    para.compounding_type, para.dcc, ...
                                    para.compounding_freq)) - 1)' .* para.notional;
                % prorated == false: adjust deposit method to bond method --> in 
                % leap year adjust time period length by adding one day and
                % recalculate cash flow
                if ( instrument.prorated == false) 
                    delta_coupon = cf_interest - para.coupon_rate .* para.notional;
                    delta_prorated = para.notional .* para.coupon_rate / 365;
                    if ( abs(delta_coupon - delta_prorated) < sqrt(eps))
                        cf_interest = ((1 ./ discount_factor(d1+1, d2, ...
                                    para.coupon_rate, para.compounding_type, para.dcc, ...
                                    para.compounding_freq)) - 1)' .* para.notional;
                    end
                end
            else    % CDS_FLOATING
                reference_curve = riskfactor;   % reference curve to extract forward rates
                tmp_nodes_ref = reference_curve.get('nodes');
                tmp_rates_ref = reference_curve.getValue(value_type);
                cf_interest = zeros(rows(tmp_rates_ref),length(d1));
                [tf dip dib] = timefactor (d1, d2, para.dcc);
                for ii = 1 : 1 : length(d1)
                    % convert dates into years from valuation date with timefactor
                    t1 = (d1(ii) - para.valuation_date);
                    t2 = (d2(ii) - para.valuation_date);
              
                    if ( t1 >= 0 && t2 >= t1 )        % for future cash flows use forward rate
                        payment_date        = t2;
                        % adjust forward start and end date for in fine vs. in arrears
                        if ( instrument.in_arrears == 0)    % in fine
                            fsd  = t1;
                            fed  = t2;
                        else    % in arrears
                            fsd  = t2;
                            fed  = t2 + (t2 - t1);
                        end
                         % get forward rate from provided curve (Why compfreq / basis from para?)
                        forward_rate_curve = get_forward_rate(tmp_nodes_ref,tmp_rates_ref, ...
                            fsd,fed-fsd,para.compounding_type,para.method_interpolation, ...
                            para.compounding_freq, para.dcc, para.valuation_date, ...
                            para.comp_type_curve, para.basis_curve, para.comp_freq_curve,para.floor_flag);
                                    
                        % calculate final floating cash flows
                        forward_rate = (para.spread + forward_rate_curve) .* tf(ii);

                    elseif ( t1 < 0 && t2 > 0 ) % if last cf date is in the past, while
                                            % next is in future, use last reset rate
                        forward_rate = (para.spread + instrument.last_reset_rate) .* tf(ii);
                    else    % if both cf dates t1 and t2 lie in the past omit cash flow
                        forward_rate = 0.0;
                    end
                    cf_interest(:,ii) = forward_rate .* para.notional;
                end
                    
            end % end get interest cash flows
        else    % use initial premium at issue_date 
            idx_vec = para.issuedatenum == para.cf_datesnum;
            idx = idx_vec' * [1:1:length(idx_vec)]';
            cf_interest = zeros(1,length(para.cf_datesnum));
            cf_interest(idx) = instrument.cds_initial_premium;
        end
        issue_date_reldays = para.issuedatenum - para.valuation_date;
        % get probability weights for all interest cash flows:
        hr_nodes_int = d2 - para.valuation_date;
        hr_timesteps = d2-d1;
        if ( instrument.cds_use_initial_premium == true)
            hr_nodes_int = [issue_date_reldays,hr_nodes_int']';
            hr_timesteps = [issue_date_reldays;hr_nodes_int(2:end) - hr_nodes_int(1:end-1)];
            d2 = hr_nodes_int + para.valuation_date;
            d1 = d2 - hr_timesteps;
        end
        hazard_rates_curve = hazard_curve.getRate(value_type,hr_nodes_int)';
        % convert hazard rates (timefactor)
        hazard_rates = convert_curve_rates(para.valuation_date, ...
                    hr_timesteps,hazard_rates_curve, ...
                    para.comp_type_curve,para.comp_freq_curve,para.basis_curve,para.compounding_type, ...
                    para.compounding_freq,para.dcc);
        % calculate survival probabilities
        survival_probs = cumprod(discount_factor(d1, d2, hazard_rates, ...
                                    para.compounding_type, para.dcc, para.compounding_freq))';

        cf_interest = cf_interest .* survival_probs;
        hr_nodes_int = hr_nodes_int';

        % ------------   protection leg: get default cash flows  ------------------
        % payout of probability weighted default cfs at all ref_cf_dates
        % append issue date
        
        princ_dates = sort([issue_date_reldays,ref_cf_dates]);
        princ_dates = princ_dates(princ_dates>=issue_date_reldays);
        hr_nodes_princ = princ_dates(2:end);
        hr_timesteps = hr_nodes_princ - princ_dates(1:end-1);
        d2 = princ_dates(2:end) + para.valuation_date;
        d1 = d2 - hr_timesteps;
        hazard_rates_curve = hazard_curve.getRate(value_type,hr_nodes_princ)';
        % convert hazard rates (timefactor)
        hazard_rates = convert_curve_rates(para.valuation_date, ...
                    hr_timesteps',hazard_rates_curve, ...
                    para.comp_type_curve,para.comp_freq_curve,para.basis_curve,para.compounding_type, ...
                    para.compounding_freq,para.dcc);
        % calculate survival probabilities
        survival_probs = cumprod(discount_factor(d1, d2, hazard_rates', ...
                                    para.compounding_type, para.dcc, para.compounding_freq));
        hazard_rates = (1 ./ discount_factor(d1, d2, hazard_rates', ...
                                    para.compounding_type, para.dcc, para.compounding_freq)) - 1;
        
        cf_principal = -para.notional .* hazard_rates .* survival_probs ...
                                                 .* instrument.loss_given_default;
        
        % --------------------------------------------------------------------------
        % adjust sign of cashflows
        if ( instrument.cds_receive_protection == false) % protection provider
            cf_interest = -cf_interest;
            cf_principal = -cf_principal;
        end

        % sum up final cashflows (all unique time steps from protection and premium)
        % and adjust cf_datesnum if necessary
        para.cf_datesnum = unique([(para.cf_datesnum - para.valuation_date)',hr_nodes_int,hr_nodes_princ]);
        ret_values = zeros(rows(cf_interest),columns(para.cf_datesnum));
        ret_cf_interest  = zeros(rows(cf_interest),columns(para.cf_datesnum));
        ret_cf_principal  = zeros(rows(cf_principal),columns(para.cf_datesnum));
        for ii=1:columns(para.cf_datesnum)
            tmp_date = para.cf_datesnum(ii);
            tmp_int_cf = cf_interest(:,hr_nodes_int==tmp_date);
            tmp_princ_cf = cf_principal(:,hr_nodes_princ==tmp_date);
            if ~ (isempty(tmp_int_cf))
                ret_values(:,ii) = cf_interest(:,hr_nodes_int==tmp_date); 
                ret_cf_interest(:,ii) = cf_interest(:,hr_nodes_int==tmp_date); 
            end
            if ~ (isempty(tmp_princ_cf))
                ret_values(:,ii) = ret_values(:,ii) + cf_principal(:,hr_nodes_princ==tmp_date);
                ret_cf_principal(:,ii) = cf_principal(:,hr_nodes_princ==tmp_date);
            end
        end
        para.cf_datesnum = (para.cf_datesnum + para.valuation_date)';
        cf_interest = ret_cf_interest;
        cf_principal = ret_cf_principal;
        
        para.cf_business_datesnum = para.cf_datesnum;
    end % end credit_state != default
    
    para.ret_values = ret_values;
    para.cf_principal = cf_principal;
    para.cf_interest = cf_interest;
end % end get_cfvalues_CDS
% ##############################################################################
function para = get_cfvalues_ILB(valuation_date, value_type, para, instrument, ref_curve, surface, riskfactor)
    
    % remap input objects: ref_curve, surface, riskfactor
    iec     = ref_curve;
    hist    = surface;
    cpi     = riskfactor;
    notional_tmp = para.notional;
    %cf_datesnum = cf_datesnum((cf_datesnum-today)>0)
    d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
    d2 = para.cf_datesnum(2:length(para.cf_datesnum));
    
    % get current CPI level
    cpi_level = cpi.getValue(value_type);
        
    % get historical index level for indexation lag > 0
    if (instrument.use_indexation_lag == true)
        adjust_for_month = instrument.infl_exp_lag;
        tmp_date = addtodatefinancial(para.issuedatenum, 0, -adjust_for_month, 0);
        diff_days = para.valuation_date - tmp_date;
        cpi_initial = hist.getRate(value_type,-diff_days);
    else % Compute initial index level from historical rate without lag
        days_from_issuedate = para.issuedatenum - para.valuation_date;
        cpi_initial = hist.getRate(value_type,days_from_issuedate);
    end
    % preallocate memory
    no_scen = max(length(iec.getRate(value_type,0)),length(cpi_level));
    cf_values = zeros(no_scen,length(d1));
    cf_principal = zeros(no_scen,length(d1));
    inflation_index = zeros(no_scen,length(d1));
    
    % precalculate rates at nodes
    rates_interest = ((1 ./ discount_factor(d1, d2, para.coupon_rate, ...
                                            para.compounding_type, para.dcc, ...
                                            para.compounding_freq)) - 1)';
                                            
    % calculate all cash flows (assume prorated == true --> deposit method
    for ii = 1: 1 : length(d2)
        % convert dates into years from valuation date with timefactor
        % check for indexation_lag and adjust timesteps accordingly
        tmp_d1 = d1(ii);
        tmp_d2 = d2(ii);
        adjust_for_month = 0;
        if (instrument.use_indexation_lag == true)
            adjust_for_month = instrument.infl_exp_lag;
            tmp_d1 = addtodatefinancial(tmp_d1, 0, -adjust_for_month, 0);
            tmp_d2 = addtodatefinancial(tmp_d2, 0, -adjust_for_month, 0);
        end
        % get timefactors and cf dates
        [tf dip dib] = timefactor (tmp_d1, tmp_d2, para.dcc);
        t1 = (tmp_d1 - para.valuation_date);
        t2 = (tmp_d2 - para.valuation_date);
        % future cash flows only, but adjust for indexation lag
        if ( t2 >= 0 - (adjust_for_month * 31) && t2 >= t1 ) 
            % adjust notional according to CPI adjustment factor based on
            % interpolated inflation expectation curve rates
            % distinguish between t1 and t2
            iec_rate = iec.getRate(value_type,t2);
            % special case: if indexation lag too large, take hist CPI level
            if ( t2 > 0) 
                adj_cpi_factor = 1 ./ discount_factor(para.valuation_date, tmp_d2, iec_rate, ...
                                                iec.compounding_type, iec.basis, ...
                                                iec.compounding_freq);
                % take adjust cpi factor relative to initial cpi value
                new_cpi_level = adj_cpi_factor .* cpi_level;
                inflation_index(:,ii) = adj_cpi_factor .* cpi_level;
            else
                new_cpi_level = hist.getRate(value_type,t2);
                inflation_index(:,ii) = new_cpi_level;
            end
            notional_tmp = para.notional .* new_cpi_level ./ cpi_initial;
            
            cf_values(:,ii) = rates_interest(ii) .* notional_tmp;
            % prorated == false: adjust deposit method to bond method --> in case
            % of leap year adjust time period length by adding one day and
            % recalculate cash flow
            if ( instrument.prorated == false) 
                delta_coupon = cf_values(ii) - para.coupon_rate .* notional_tmp;
                delta_prorated = notional_tmp .* para.coupon_rate / 365;
                if ( abs(delta_coupon - delta_prorated) < sqrt(eps))
                    cf_values(:,ii) = ((1 ./ discount_factor(d1(ii)+1, d2(ii), ...
                                para.coupon_rate, para.compounding_type, para.dcc, ...
                                para.compounding_freq)) - 1) .* notional_tmp;
                end
            end
            
            % overwrite ILB cashflows in case of Caps or Floors
            if (strcmpi(para.type,'CAP_INFL') || strcmpi(para.type,'FLOOR_INFL'))
                % expand inflation index
                inflation_index = [ones(rows(inflation_index),1) .* cpi_initial, inflation_index];
                % calculate inflation rate derived from inflation_index
                % allow only for discrete compounding
                inflation_rate = inflation_index(:,ii+1) ./ inflation_index(:,ii) - 1;
                strike_rate = instrument.strike;
                % TODO: additional curve object with variable strike rate
                %strike_rate = strike_curve.getRate(value_type,t2);
                if ( instrument.CapFlag == true)
                    cf_values(:,ii) = para.notional .* (inflation_rate - strike_rate);
                else
                    cf_values(:,ii) = para.notional .* (strike_rate - inflation_rate);
                end
            end
        else    % if both cf dates t1 and t2 lie in the past omit cash flow
            cf_values(:,ii)  = 0.0;
        end
    end
    ret_values = cf_values;
    cf_interest = cf_values;
    % Add CPI adjusted notional payments at end
    if ( para.notional_at_start == 1)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - notional_tmp;     
        cf_principal(:,1) = - notional_tmp;
    end
    if ( para.notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + notional_tmp;
        cf_principal(:,end) = notional_tmp;
    end
    
    para.ret_values = ret_values;
    para.cf_principal = cf_principal;
    para.cf_interest = cf_interest;
end % end function get_cfvalues_ILB

% ##############################################################################
function para = get_cfvalues_FRN_FWD_SPECIAL(valuation_date, value_type, para, instrument, surface)
    
    % remove after adapting final transformation steps
    ret_values = para.ret_values ;
    cf_principal = para.cf_principal;
    cf_interest = para.cf_interest ;
    
    %cf_datesnum = cf_datesnum((cf_datesnum-valuation_date)>0);
    d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
    d2 = para.cf_datesnum(2:length(para.cf_datesnum));
    notvec = zeros(1,length(d1));
    notvec(length(notvec)) = 1;
    cf_values = zeros(rows(para.tmp_rates),length(d1));
    cf_principal = zeros(rows(para.tmp_rates),length(d1));
    sliding_term = instrument.fwd_sliding_term; % averaging period
    und_term = instrument.fwd_term;     % term of averaging period
    hist = surface;
    if ~( mod(sliding_term,und_term) == 0 )
        error('ERROR: rollout_structured_cashflow:FRN_FWD_SPECIAL: Sliding term and averaging term does not match! mod(sliding_term,und_term) = %s',any2str(mod(sliding_term,averaging_term)));
    end
        
    for ii = 1 : 1 : length(d1)
        % convert dates into years from valuation date with timefactor
        [tf dip dib] = timefactor (d1(ii), d2(ii), para.dcc);
        t1 = (d1(ii) - para.valuation_date);
        t2 = (d2(ii) - para.valuation_date);
  
        if ( t1 >= 0 && t2 >= t1 )        % for future cash flows use forward rate
            payment_date        = t2;
            % adjust forward start and end date for in fine vs. in arrears
            if ( instrument.in_arrears == 0)    % in fine
                fsd  = t1;
                fed  = t2;
                timing_adjustment = 1; % no timing adjustment required for in fine
            else    % in arrears
                fsd  = t2;
                fed  = t2 + (t2 - t1);
            end
                        
            % calculate timing adjustment
            timing_adjustment = 1;
            if ( instrument.in_arrears == 0)    % in fine
                fsd  = t1;
                fed  = t2;
            else    % in arrears
                fsd  = t2;
                fed  = t2 + (t2 - t1);
            end
            
            % calculate forward rates and build average of historical rates 
            % Loop via all dates in [fsd,fsd-sliding_term] and get rates
            % from historical curve (if t<t0) and from forward rate (if t>t0)
            avg_rate = zeros(1, sliding_term / und_term);
            idx = 1;
            for kk = sliding_term : -und_term : und_term
                avg_date_begin  = fed - kk;
                avg_date_end    = fed - kk + und_term;
                % get rate depending on date
                if (avg_date_begin < 0) % take historical rates
                    rate_curve = hist.getRate(value_type,avg_date_begin);
                else                    % get forward rate for period
                    rate_curve = get_forward_rate(para.tmp_nodes,para.tmp_rates, ...
                        avg_date_begin,avg_date_end - avg_date_begin, ...
                        para.compounding_type,para.method_interpolation, ...
                        para.compounding_freq, para.dcc, para.valuation_date, ...
                        para.comp_type_curve, para.basis_curve, ...
                        para.comp_freq_curve,para.floor_flag);
                end
                % store rate in array
                avg_rate(idx) = rate_curve;
                idx = idx + 1;
            end
            % apply function
            if ( strcmpi(instrument.rate_composition,'average'))
                forward_rate_curve = mean(avg_rate);
            elseif ( strcmpi(instrument.rate_composition,'max'))
                forward_rate_curve = max(avg_rate);
            elseif ( strcmpi(instrument.rate_composition,'min'))
                forward_rate_curve = min(avg_rate);
            end 
            
            % calculate final floating cash flows
            forward_rate = (para.spread + forward_rate_curve) .* tf;
            
        elseif ( t1 < 0 && t2 > 0 )     % if last cf date is in the past, while
                                        % next is in future, use last reset rate
            forward_rate = (para.spread + para.last_reset_rate) .* tf;
        else    % if both cf dates t1 and t2 lie in the past omit cash flow
            forward_rate = 0.0;
        end
        cf_values(:,ii) = forward_rate;
    end
    ret_values = cf_values .* para.notional;
    cf_interest = ret_values;
    % Add notional payments
    if ( para.notional_at_start == true)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - para.notional;  
        cf_principal(:,1) = - para.notional;
    end
    if ( para.notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + para.notional;
        cf_principal(:,end) = para.notional;
    end
    
    para.ret_values = ret_values;
    para.cf_principal = cf_principal;
    para.cf_interest = cf_interest;
    
end % end function get_cfvalues_FRN_FWD_SPECIAL
% ##############################################################################
function para = get_cfvalues_FRNCAPFLOOR(valuation_date, value_type, para, instrument, surface)
    %cf_datesnum = cf_datesnum((cf_datesnum-valuation_date)>0);
    d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
    d2 = para.cf_datesnum(2:length(para.cf_datesnum));
    notvec = zeros(1,length(d1));
    notvec(length(notvec)) = 1;
    cf_values = zeros(rows(para.tmp_rates),length(d1));
    cf_principal = zeros(rows(para.tmp_rates),length(d1));
    [tf dip dib] = timefactor (d1, d2, para.dcc);
    for ii = 1 : 1 : length(d1)
        % convert dates into years from valuation date with timefactor
        t1 = (d1(ii) - valuation_date);
        t2 = (d2(ii) - valuation_date);
  
        if ( t1 >= 0 && t2 >= t1 )        % for future cash flows use forward rate
            payment_date        = t2;
            % adjust forward start and end date for in fine vs. in arrears
            if ( instrument.in_arrears == 0)    % in fine
                fsd  = t1;
                fed  = t2;
                timing_adjustment = 1; % no timing adjustment required for in fine
            else    % in arrears
                fsd  = t2;
                fed  = t2 + (t2 - t1);
            end
             % get forward rate from provided curve
            forward_rate_curve = get_forward_rate(para.tmp_nodes,para.tmp_rates, ...
                    fsd,fed-fsd,para.compounding_type,para.method_interpolation, ...
                    para.compounding_freq, para.dcc, valuation_date, ...
                    para.comp_type_curve, para.basis_curve, para.comp_freq_curve,para.floor_flag);
                        
            % calculate timing adjustment
            timing_adjustment = 1;
            if ( instrument.in_arrears == 0)    % in fine
                fsd  = t1;
                fed  = t2;
                timing_adjustment = 1; % no timing adjustment required for in fine
            else    % in arrears
                fsd  = t2;
                fed  = t2 + (t2 - t1);
                % for in arrears, a timing adjustment is required:
                if ( isobject(surface))
                    % get volatility according to moneyness and term
                    tenor   = fsd; % days until foward start date
                    term    = fed-fsd; % days of caplet / floorlet
                    sigma   = surface.getValue(value_type,tenor,term,1);
                    % assuming correlation = 1, forward vola = discount vola
                    %   and simple compounding, act/365
                    df_t1_t2 = discount_factor(valuation_date + t1, ...
                                valuation_date + t2, forward_rate_curve, ...
                                'simple', 3, para.comp_freq_curve);
                    % calculate time factor from issue date to forward start date
                    tf_t_reset_date = timefactor (d1(1), d1(1) + fsd, para.dcc);
                    timing_adjustment = 1 + sigma.^2 .* (1 - df_t1_t2) .* tf_t_reset_date;
                else
                    fprintf('WARNING: rollout_structured_cashflows: no timing adjustment for in Arrears instrument can be calculated. No Volatility surface set. \n');
                    timing_adjustment = 1; % no timing adjustment required for in fine
                end
            end
            % adjust forward rate by timing adjustment
            forward_rate_curve = forward_rate_curve .* timing_adjustment;
            % calculate final floating cash flows
            if (strcmpi(para.type,'CAP') || strcmpi(para.type,'FLOOR'))
                % call function to calculate probability weighted forward rate
                X = instrument.strike;  % get from strike curve ?!?
                % calculate timefactor of forward start date
                tf_fsd = timefactor (valuation_date, valuation_date + fsd, para.dcc);
                % calculate moneyness 
                if (instrument.CapFlag == true)
                    moneyness_exponent = 1;
                else
                    moneyness_exponent = -1;
                end
                moneyness = (forward_rate_curve ./ X) .^ moneyness_exponent;
                % get volatility according to moneyness and term
                tenor   = fsd; % days until foward start date
                term    = fed-fsd; % days of caplet / floorlet
                sigma = surface.getValue(value_type,tenor,term,moneyness);
                % account for vola spread (set by e.g. calibration)
                sigma   = sigma + instrument.vola_spread; 
                
                % add convexity adjustment to forward rate
                if ( instrument.convex_adj == true )
                    [adj_rate ca] = calcConvexityAdjustment(valuation_date, ...
                            instrument, forward_rate_curve,sigma,fsd,fed);
                else
                    adj_rate = forward_rate_curve;
                end
                % calculate forward rate according to CAP/FLOOR model
                forward_rate = getCapFloorRate(instrument.CapFlag, ...
                        adj_rate, X, tf_fsd, sigma, instrument.model);
                % adjust forward rate to term of caplet / floorlet
                forward_rate = forward_rate .* tf(ii);
            else % all other floating swap legs and floater
                forward_rate = (para.spread + forward_rate_curve) .* tf(ii);
            end
        elseif ( t1 < 0 && t2 > 0 )     % if last cf date is in the past, while
                                        % next is in future, use last reset rate
            if (strcmpi(para.type,'CAP') || strcmpi(para.type,'FLOOR'))
                if instrument.CapFlag == true
                    forward_rate = max(para.last_reset_rate - instrument.strike,0) .* tf(ii);
                else
                    forward_rate = max(instrument.strike - para.last_reset_rate,0) .* tf(ii);
                end
            else
                forward_rate = (para.spread + para.last_reset_rate) .* tf(ii);
            end
        else    % if both cf dates t1 and t2 lie in the past omit cash flow
            forward_rate = 0.0;
        end
        cf_values(:,ii) = forward_rate;
    end
    ret_values = cf_values .* para.notional;
    cf_interest = ret_values;
    % Add notional payments
    if ( para.notional_at_start == true)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - para.notional;  
        cf_principal(:,1) = - para.notional;
    end
    if ( para.notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + para.notional;
        cf_principal(:,end) = para.notional;
    end
    
    para.ret_values = ret_values;
    para.cf_principal = cf_principal;
    para.cf_interest = cf_interest;
end % end function get_cfvalues_FRNCAPFLOOR
% ##############################################################################
function para = get_cfvalues_FRN_SPECIAL(valuation_date, value_type, para, instrument, ref_curve, surface)
    
    % assume in fine -> fixing at forward start date -> use issue date as first
    para.cf_datesnum = [para.issuedatenum;para.cf_datesnum];
    d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
    d2 = para.cf_datesnum(2:length(para.cf_datesnum));
    notvec = zeros(1,length(d1));
    notvec(length(notvec)) = 1;
    cms_rates = zeros(rows(para.tmp_rates),length(d1));
    cms_tf    = zeros(rows(para.tmp_rates),length(d1));
    cf_principal = zeros(rows(para.tmp_rates),length(d1));
    [tf dip dib] = timefactor (d1, d2, para.dcc);
    % get instrument attributes
    sliding_term        = instrument.cms_sliding_term;
    sliding_term_unit   = instrument.cms_sliding_term_unit;
    underlying_term     = instrument.cms_term;
    underlying_term_unit = instrument.cms_term_unit;
    underlying_spread   = instrument.cms_spread;
    underlying_comp_type = instrument.cms_comp_type;
    model               = instrument.cms_model; 
    
    % preset swap
    swap = Bond();
    swap = swap.set('Name','SWAP_CMS','coupon_rate',0.00, ...
                    'value_base',1,'coupon_generation_method', ...
                    'forward','last_reset_rate',-0.000, ...
                    'sub_type', 'SWAP_FIXED','spread',0.00, ...
                    'notional',1,'notional_at_end',0, ...
                    'compounding_type',underlying_comp_type, ...
                    'term',underlying_term, 'term_unit', underlying_term_unit, ...
                    'notional_at_start',0); 
    for ii = 2 : 1 : length(d1)
        t1 = (d1(ii) - valuation_date);
        t2 = (d2(ii) - valuation_date);
        if ( t1 >= 0 && t2 >= t1 )    % for future cash flows use forward rates
        % (I) Calculate CMS x-let value with or without convexity adjustment and 
        %   distinguish between swaplets, caplets and floorlets 
            % payment date of FRN special is maturity date -> use date for CA
            %     ( will be incorporated in nominator of delta of Hagan)
            payment_date        = para.maturitydatenum - valuation_date;
            if ( instrument.in_arrears == 0)    % in fine
                fixing_start_date  = t1;
            else    % in arrears
                fixing_start_date  = t2;
            end
             % fixing_start_date
             % payment_date
            % set up underlying swap
            
            swap_issue_date = addtodatefinancial(valuation_date,fixing_start_date,'days');
            swap_mat_date = addtodatefinancial(swap_issue_date,sliding_term,sliding_term_unit);
            dtm_tmp = swap_mat_date - swap_issue_date;
            swap = swap.set('maturity_date',swap_mat_date, ...
                            'issue_date', swap_issue_date);
            % get volatility according to moneyness and term
            if ( regexpi(surface.moneyness_type,'-'))
                moneyness = 0.0; % surface with absolute moneyness
            else
                moneyness = 1.0; % surface with relative moneyness
            end
            tenor   = fixing_start_date; % days until foward start date
            sigma   = surface.getValue(value_type,tenor,dtm_tmp,moneyness);  
            % calculate cms_rate according to cms model and instrument type
            % either adjustments for swaplets, caplets or floorlets are calculated
            if ( strcmpi( instrument.cms_convex_model,'Hull' ) )
                [cms_rate convex_adj] = get_cms_rate_hull(valuation_date,value_type, ...
                        swap,ref_curve,sigma,model);
            elseif ( strcmpi( instrument.cms_convex_model,'Hagan' ) )
                [cms_rate convex_adj] = get_cms_rate_hagan(valuation_date,value_type, ...
                        instrument,swap,ref_curve,sigma,payment_date);
            end
             % set convexity adjustment to zero if necessary
            if ( instrument.convex_adj == false )
                convex_adj = 0.0;
            end 
            % get final capitalized rate
            final_rate = (para.spread + cms_rate + convex_adj) .* tf(ii);
            
        elseif ( t1 < 0 && t2 > 0 )     % if last cf date is in the past, while
                                        % next is in future, use last reset rate
            final_rate = (para.spread + para.last_reset_rate) .* tf(ii);
            
        else    % if both cf dates t1 and t2 lie in the past omit cash flow
            final_rate = 0.0;
        end 
        cms_tf(:,ii) = tf(ii);  % store timefactor of cms rate        
        cms_rates(:,ii) = final_rate;
    end
    
    cms_rates(:,1)=[];  % remove first cms_rates
    cms_tf(:,1)=[];  % remove first time factor
    % Capitalized Floater adjustments:
    % 1. only final cash flow at maturity date
    para.cf_dates    = [para.issuevec;para.matvec];
    para.cf_datesnum = datenum(para.cf_dates);
    % update business date
    if ( para.enable_business_day_rule == true)
        para.cf_business_dates = datevec(busdate(para.cf_datesnum-1 + para.business_day_rule, ...
                                    para.business_day_direction));
        para.cf_business_datesnum = datenum(para.cf_business_dates);   
    else
        para.cf_business_datesnum = para.cf_datesnum;
        para.cf_business_dates = para.cf_dates;
    end
                            
    % 2. adjust cms rates according to rate composition function
    if ( strcmpi(instrument.rate_composition,'capitalized'))
        tmp_rates = prod(1+cms_rates,2) - 1;
        % convert curve rates to instrument type
        tmp_rates = convert_curve_rates(valuation_date,para.cf_dates(:,end), ...
                                tmp_rates,'simple','annual',para.basis_curve, ...
                                para.compounding_type,para.compounding_freq,para.dcc);
        % annualize rate after simple capitalization was performed:
        if ( regexpi(para.compounding_type,'mp'))    % simple
            adj_rate = para.term_factor .* tmp_rates ./ (length(cms_rates));
        elseif ( regexpi(para.compounding_type,'cont')) % continuous
            adj_rate = log(1+tmp_rates .* para.term_factor) ./ (length(cms_rates));
        else    % discrete compounding
            adj_rate = (prod(1+cms_rates .* para.term_factor,2)) ...
                        ^(1/(para.term_factor .* length(cms_rates))) - 1;
        end
    else
        % annualize rate before operation is performed:
        if ( regexpi(para.compounding_type,'mp'))    % simple
            tmp_rates = cms_rates ./ cms_tf;
        elseif ( regexpi(para.compounding_type,'cont')) % continuous
            tmp_rates = log(1+cms_rates ./ cms_tf);
        else    % discrete compounding
            tmp_rates = (1+cms_rates).^(1./cms_tf) - 1;
        end
        % distinguish rate composition methods
        if ( strcmpi(instrument.rate_composition,'average'))
            adj_rate = mean(tmp_rates);
        elseif ( strcmpi(instrument.rate_composition,'max'))
            adj_rate = max(tmp_rates);
        elseif ( strcmpi(instrument.rate_composition,'min'))
            adj_rate = min(tmp_rates);
        end  
    end
    
    % adjust adj_rate to term and compounding type of instrument
    instr_adj_rate = (1 ./ discount_factor(valuation_date, ...
                            para.maturity_date, adj_rate, ...
                            para.compounding_type, para.dcc, para.compounding_freq)) - 1;                  
    ret_values  = instr_adj_rate .* para.notional;
    cf_interest = ret_values;
    % Add notional payments at end (start will be neglected)
    if ( para.notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values = ret_values + para.notional;
        cf_principal = para.notional;
    end
    para.ret_values = ret_values;
    para.cf_principal = cf_principal;
    para.cf_interest = cf_interest;
    
end     % end function get_cfvalues_FRN_SPECIAL
% ##############################################################################
function para = get_cfvalues_CMS_FLOATING_CAPFLOOR(valuation_date, value_type, para, instrument, ref_curve, surface)
    
    % remove after adapting final transformation steps
    ret_values = para.ret_values;
    cf_principal = para.cf_principal;
    cf_interest = para.cf_interest ;
    
    % assume in fine -> fixing at forward start date -> use issue date as first
    para.cf_datesnum = [para.issuedatenum;para.cf_datesnum];
    d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
    d2 = para.cf_datesnum(2:length(para.cf_datesnum));
    notvec = zeros(1,length(d1));
    notvec(length(notvec)) = 1;
    cf_values = zeros(rows(para.tmp_rates),length(d1));
    cf_principal = zeros(rows(para.tmp_rates),length(d1));
    [tf dip dib] = timefactor (d1, d2, para.dcc);
    % get instrument data
    sliding_term        = instrument.cms_sliding_term;
    sliding_term_unit   = instrument.cms_sliding_term_unit;
    underlying_term     = instrument.cms_term;
    underlying_term_unit = instrument.cms_term_unit;
    underlying_spread   = instrument.cms_spread;
    underlying_comp_type = instrument.cms_comp_type;
    model               = instrument.cms_model;
    % preset up underlying swap
    swap = Bond();
    swap = swap.set('Name','SWAP_CMS','coupon_rate',0.00, ...
                    'value_base',1,'coupon_generation_method', ...
                    'forward','last_reset_rate',-0.000, ...
                    'sub_type', 'SWAP_FLOATING','spread',0.00, ...
                    'notional',1,'compounding_type',underlying_comp_type, ...
                    'term',underlying_term, 'term_unit', underlying_term_unit, ...
                    'notional_at_end',0, ...
                    'notional_at_start',0); 
    for ii = 2 : 1 : length(d1)
        t1 = (d1(ii) - valuation_date);
        t2 = (d2(ii) - valuation_date);
        if ( t1 >= 0 && t2 >= t1 )    % for future cash flows use forward rates
        % (I) Calculate CMS x-let value with or without convexity adjustment and 
        %   distinguish between swaplets, caplets and floorlets 
            
            payment_date        = t2;
            if ( instrument.in_arrears == 0)    % in fine
                fixing_start_date  = t1;
            else    % in arrears
                fixing_start_date  = t2;
            end
            %fixing_start_date
            %payment_date
            
            % set up underlying swap
            swap_issue_date = addtodatefinancial(valuation_date,fixing_start_date,'days');
            swap_mat_date = addtodatefinancial(swap_issue_date,sliding_term,sliding_term_unit);
            dtm_tmp = swap_mat_date - swap_issue_date;
            swap = swap.set('maturity_date',swap_mat_date, ...
                            'issue_date', swap_issue_date);
                            
            % get volatility according to moneyness and term
            if ( regexpi(surface.moneyness_type,'-'))
                moneyness = 0.0; % surface with absolute moneyness
            else
                moneyness = 1.0; % surface with relative moneyness
            end
            tenor   = fixing_start_date; % days until foward start date
            sigma   = surface.getValue(value_type,tenor,dtm_tmp,moneyness); 
                
            % calculate cms_rate according to cms model and instrument type
            % either adjustments for swaplets, caplets or floorlets are calculated
            if ( strcmpi( instrument.cms_convex_model,'Hull' ) )
                [cms_rate convex_adj] = get_cms_rate_hull(valuation_date,value_type, ...
                        swap,ref_curve,sigma,model);
            elseif ( strcmpi( instrument.cms_convex_model,'Hagan' ) )
                [cms_rate convex_adj] = get_cms_rate_hagan(valuation_date,value_type, ...
                        instrument,swap,ref_curve,sigma,payment_date);
            end
             % set convexity adjustment to zero if necessary
            if ( instrument.convex_adj == false )
                convex_adj = 0.0;
            end 
            
        % (II) Calculate final floating cash flows: special cap/floorrate
            if (strcmpi(para.type,'CAP_CMS') || strcmpi(para.type,'FLOOR_CMS'))
                % call function to calculate probability weighted forward rate
                X = instrument.strike;  % TODO: get from strike curve ?!?
                % calculate timefactor of forward start date
                tf_fsd = timefactor (valuation_date, valuation_date + fixing_start_date, para.dcc);
                % calculate moneyness 
                if (instrument.CapFlag == true)
                    moneyness_exponent = 1;
                else
                    moneyness_exponent = -1;
                end
                % distinguish between Hagan (adjustmen to value) and Hull 
                % (adjustment to rate) convexity adjustment:
                if ( strcmpi( instrument.cms_convex_model,'Hull' ) )
                    cms_rate  = cms_rate + convex_adj;
                end
                % get volatility according to moneyness and term
                if ( regexpi(surface.moneyness_type,'-')) % surface with absolute moneyness
                    moneyness = (X - cms_rate);
                else % surface with relative moneyness
                    moneyness = (cms_rate ./ X) .^ moneyness_exponent; 
                end
                
                % get volatility according to moneyness and term
                tenor   = fixing_start_date; % days until foward start date
                term    = t2 - t1; % days of caplet / floorlet
                % current implementation: option term is term of cap
                % in principle one could use cms_sliding term to get appropriate volatility
                sigma   = surface.getValue(value_type,tenor,term,moneyness);
                % account for vola spread (set by e.g. calibration)
                sigma   = sigma + instrument.vola_spread; 
            
                % calculate CAP/FLOOR rate according to model based on cms rate
                cms_rate = getCapFloorRate(instrument.CapFlag, ...
                        cms_rate, X, tf_fsd, sigma, instrument.model);
                
                % adjust cms rate to term of caplet / floorlet and add back
                % convexity adjustment in case of Hagan
                if ( strcmpi( instrument.cms_convex_model,'Hagan' ) )
                    cms_rate = (cms_rate + convex_adj) .* tf(ii);
                else
                    cms_rate = cms_rate .* tf(ii);
                end
            else % all other CMS floating swap legs
                cms_rate = (para.spread + cms_rate + convex_adj) .* tf(ii);
            end
        elseif ( t1 < 0 && t2 > 0 )     % if last cf date is in the past, while
                                        % next is in future, use last reset rate
            if (strcmpi(para.type,'CAP_CMS') || strcmpi(para.type,'FLOOR_CMS'))
                if instrument.CapFlag == true
                    cms_rate = max(para.last_reset_rate - instrument.strike,0) .* tf(ii);
                else
                    cms_rate = max(instrument.strike - para.last_reset_rate,0) .* tf(ii);
                end
            else
                cms_rate = (para.spread + para.last_reset_rate) .* tf(ii);
            end
        else    % if both cf dates t1 and t2 lie in the past omit cash flow
            cms_rate = 0.0;
        end
        cf_values(:,ii) = cms_rate;
    end
    ret_values = cf_values .* para.notional;
    cf_interest = ret_values;
    % Add notional payments
    if ( para.notional_at_start == true)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - para.notional;  
        cf_principal(:,1) = - para.notional;
    end
    if ( para.notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + para.notional;
        cf_principal(:,end) = para.notional;
    end

    para.ret_values = ret_values;
    para.cf_principal = cf_principal;
    para.cf_interest = cf_interest;
end % end function get_cfvalues_CMS_FLOATING_CAPFLOOR
% ##############################################################################

%-------------------------------------------------------------------------------
%                           Cash flow date rollout functions
%-------------------------------------------------------------------------------
% final cash flow date rollout function
function para = get_cf_dates(para)
    
% Cash flow date calculation:
    issuevec = datevec_fast(para.issuedatenum);
    todayvec = datevec_fast(para.valuation_date);
    matvec = datevec_fast(para.maturitydatenum);
    % cashflow rollout: method backwards
    if ( strcmpi(para.coupon_generation_method,'backward') )
        cf_date = matvec;
        cf_dates = cf_date;
        cfdatenum = para.maturitydatenum;
        mult = 0;
        while cfdatenum >= para.issuedatenum
            mult += 1;
            [cfdatenum cf_date] = addtodatefinancial(para.maturitydatenum, -para.term * mult, para.term_unit);
            if cfdatenum >= para.issuedatenum
                cf_dates = [cf_dates ; cf_date];
            end
        end % end coupon generation backward
        % flip cf_date vector (since backward has reverse order)
        cf_dates = flipud(cf_dates);

    % cashflow rollout: method forward
    elseif ( strcmpi(para.coupon_generation_method,'forward') )
        cf_date = issuevec;
        cf_dates = cf_date;
        cfdatenum = para.issuedatenum;
        mult = 0;
        while cfdatenum <= para.maturitydatenum
            mult += 1;
            [cfdatenum cf_date] = addtodatefinancial(para.issuedatenum, para.term * mult, para.term_unit);
            if ( cfdatenum <= para.maturitydatenum)
                cf_dates = [cf_dates ; cf_date];
            end
        end        % end coupon generation forward

    % cashflow rollout: method zero
    elseif ( strcmpi(para.coupon_generation_method,'zero'))
        % rollout for zero coupon bonds -> just one cashflow at maturity
            cf_dates = [issuevec ; matvec];
    end 

    % Adjust first and last coupon period to implement issue date:
    if (para.long_first_period == true)
        if ( datenum(cf_dates(1,:)) > para.issuedatenum )
            cf_dates(1,:) = issuevec;
        end
    else
        if ( datenum(cf_dates(1,:)) > para.issuedatenum )
            cf_dates = [issuevec;cf_dates];
        end
    end
    if (para.long_last_period == true)
        if ( datenum(cf_dates(rows(cf_dates),:)) < para.maturitydatenum )
            cf_dates(rows(cf_dates),:) = matvec;
        end
    else
        if ( datenum(cf_dates(rows(cf_dates),:)) < para.maturitydatenum )
            cf_dates = [cf_dates;matvec];
        end
    end
    %special case: long_last_period == long_first_period == true || only one cashflow (e.g. monthly term):
    if (rows(cf_dates) == 1)
       cf_dates = [issuevec;matvec];
    end

    % one time and forever: get datenum of cf_dates
    cf_datesnum = datenum_fast(cf_dates);
    if ( para.enable_business_day_rule == true)
        cf_business_datesnum = busdate(cf_datesnum-1 + para.business_day_rule, ...
                                            para.business_day_direction);
        cf_business_dates = datevec(cf_business_datesnum);
    else
        cf_business_datesnum = cf_datesnum;
        cf_business_dates = cf_dates;
    end

    % store return values in para struct
    para.cf_dates               = cf_dates;
    para.cf_datesnum            = cf_datesnum;
    para.cf_business_dates      = cf_business_dates;
    para.cf_business_datesnum   = cf_business_datesnum;
    para.issuevec               = issuevec;
    para.matvec                 = matvec;
    
end
%-------------------------------------------------------------------------------

%-------------------------------------------------------------------------------
%            Custom datenum and datevec Functions 
%-------------------------------------------------------------------------------
% Octave's built in functions have been cleaned from unused code. Now only
% date format 'dd-mmm-yyyy' is allowed to improve performance
function [day] = datenum_fast (input1, format = 1)

  ## Days until start of month assuming year starts March 1.
  persistent monthstart = [306; 337; 0; 31; 61; 92; 122; 153; 184; 214; 245; 275];
  persistent monthlength = [31; 28; 31; 30; 31; 30; 31; 31; 30; 31; 30; 31];


  if (ischar (input1) || iscellstr (input1)) % input is 
    [year, month, day, hour, minute, second] = datevec_fast (input1, 1);
  else  % input is vector
      second = 0;
      minute = 0;
      hour   = 0;
      day   = input1(:,3);
      month = input1(:,2);
      year  = input1(:,1);
  end

  month(month < 1) = 1;  # For compatibility.  Otherwise allow negative months.

  % no fractional month possible

  % Set start of year to March by moving Jan. and Feb. to previous year.
  % Correct for months > 12 by moving to subsequent years.
  year += ceil ((month-14)/12);

  % Lookup number of days since start of the current year.
    day += monthstart (mod (month-1,12) + 1) + 60;

  % Add number of days to the start of the current year.  Correct
  % for leap year every 4 years except centuries not divisible by 400.
  day += 365*year + floor (year/4) - floor (year/100) + floor (year/400);

end

% ##############################################################################
function [y, m, d, h, mi, s] = datevec_fast (date, f = 1, p = [])

  if (nargin < 1 || nargin > 3)
    print_usage ();
  end

  if (ischar (date))
    date = cellstr (date);
  end

  if (isnumeric (f))
    p = f;
    f = [];
  end

  if (isempty (f))
    f = -1;
  end

  if (isempty (p))
    p = (localtime (time ())).year + 1900 - 50;
  end

  % datestring input
  if (iscell (date))

    nd = numel (date);

    y = m = d = h = mi = s = zeros (nd, 1);
    % hard coded: format string always dd-mm-yyyy
    f = '%d-%b-%Y';
    rY = 7;
    ry = 0;
    fy = 1;
    fm = 1;
    fd = 1;
    fh = 0;
    fmi = 0;
    fs = 0;
    found = 1;

    for k = 1:nd
        [found y(k) m(k) d(k) h(k) mi(k) s(k)] = ...
            __date_str2vec_custom__ (date{k}, p, f, rY, ry, fy, fm, fd, fh, fmi, fs);
    end

  % datenum input
  else 
    date = date(:);

    % Move day 0 from midnight -0001-12-31 to midnight 0000-3-1
    z = double (floor (date) - 60);
    % Calculate number of centuries; K1 = 0.25 is to avoid rounding problems.
    a = floor ((z - 0.25) / 36524.25);
    % Days within century; K2 = 0.25 is to avoid rounding problems.
    b = z - 0.25 + a - floor (a / 4);
    % Calculate the year (year starts on March 1).
    y = floor (b / 365.25);
    % Calculate day in year.
    c = fix (b - floor (365.25 * y)) + 1;
    % Calculate month in year.
    m = fix ((5 * c + 456) / 153);
    d = c - fix ((153 * m - 457) / 5);
    % Move to Jan 1 as start of year.
    ++y(m > 12);
    m(m > 12) -= 12;

    % no fractional time units
    s = 0;
    h = 0;
    mi = 0;
    

  end

  if (isvector(date) && length(date) > 1)
    if ( rows(date) > columns(date))
        date = date';
    end
    y = date(:,1);
    m = date(:,2);
    d = date(:,3);
    h = date(:,4);
    mi = date(:,5);
    s = date(:,6);
  end
  
  
  if (nargout <= 1)
    y = [y, m, d, h, mi, s];
  end

end
% ##############################################################################
function [found, y, m, d, h, mi, s] = __date_str2vec_custom__ (ds, p, f, rY, ry, fy, fm, fd, fh, fmi, fs)

  % strptime will always be possible
  [tm, nc] = strptime (ds, f);

  if (nc == columns (ds) + 1)
    found = true;
    y = tm.year + 1900; m = tm.mon + 1; d = tm.mday;
    h = 0; mi = 0; s = 0;
  else
    y = m = d = h = mi = s = 0;
    found = false;
  end

end
% ------------------------------------------------------------------------------
%!test
%! bond_struct=struct();
%! bond_struct.sub_type                 = 'FRB';
%! bond_struct.issue_date               = '21-Sep-2010';
%! bond_struct.maturity_date            = '17-Sep-2022';
%! bond_struct.compounding_type         = 'simple';
%! bond_struct.compounding_freq         = 1  ;
%! bond_struct.term                     = 12   ;
%! bond_struct.term_unit                = 'months';
%! bond_struct.day_count_convention     = 'act/365';
%! bond_struct.basis                    = 3;
%! bond_struct.prorated                 = true;
%! bond_struct.notional                 = 100 ;
%! bond_struct.coupon_rate              = 0.035; 
%! bond_struct.coupon_generation_method = 'backward' ;
%! bond_struct.business_day_rule        = 0 ;
%! bond_struct.business_day_direction   = 1  ;
%! bond_struct.enable_business_day_rule = 0;
%! bond_struct.spread                   = 0.00 ;
%! bond_struct.long_first_period        = false;
%! bond_struct.long_last_period         = false;
%! bond_struct.last_reset_rate          = 0.0000000;
%! bond_struct.fixed_annuity            = 1;
%! bond_struct.in_arrears               = 0;
%! bond_struct.notional_at_start        = false;
%! bond_struct.notional_at_end          = true;
%! bond_struct.prepayment_flag          = false;
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('31-Mar-2016','base',bond_struct);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_dates,[170,535,900,1265,1631,1996,2361]);

%!test
%! bond_struct=struct();
%! bond_struct.sub_type                 = 'FRB';
%! bond_struct.issue_date               = '21-Sep-2010';
%! bond_struct.maturity_date            = '17-Sep-2022';
%! bond_struct.compounding_type         = 'simple';
%! bond_struct.compounding_freq         = 1  ;
%! bond_struct.term                     = 12   ;
%! bond_struct.term_unit                = 'months';
%! bond_struct.day_count_convention     = 'act/365';
%! bond_struct.basis                    = 3;
%! bond_struct.prorated                 = true;
%! bond_struct.notional                 = 100 ;
%! bond_struct.coupon_rate              = 0.035; 
%! bond_struct.coupon_generation_method = 'backward' ;
%! bond_struct.business_day_rule        = 0 ;
%! bond_struct.business_day_direction   = 1  ;
%! bond_struct.enable_business_day_rule = 0;
%! bond_struct.spread                   = 0.00 ;
%! bond_struct.long_first_period        = false;
%! bond_struct.long_last_period         = false;
%! bond_struct.last_reset_rate          = 0.0000000;
%! bond_struct.fixed_annuity            = 1;
%! bond_struct.in_arrears               = 0;
%! bond_struct.notional_at_start        = false;
%! bond_struct.notional_at_end          = true;
%! bond_struct.prepayment_flag          = false;
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('31-Mar-2016','base',bond_struct);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_values,[3.5096,3.5000,3.5000,3.5000,3.5096,3.5000,103.5000],0.0001);

%!test
%! bond_struct=struct();
%! bond_struct.sub_type                 = 'FAB';
%! bond_struct.issue_date               = '01-Nov-2011';
%! bond_struct.maturity_date            = '01-Nov-2021';
%! bond_struct.compounding_type         = 'simple';
%! bond_struct.compounding_freq         = 1  ;
%! bond_struct.term                     = 12   ;
%! bond_struct.term_unit                = 'months';
%! bond_struct.day_count_convention     = 'act/365';
%! bond_struct.basis                    = 3;
%! bond_struct.use_annuity_amount       = 0;
%! bond_struct.notional                 = 100 ;
%! bond_struct.coupon_rate              = 0.0333; 
%! bond_struct.coupon_generation_method = 'backward' ;
%! bond_struct.business_day_rule        = 0 ;
%! bond_struct.business_day_direction   = 1  ;
%! bond_struct.enable_business_day_rule = 0;
%! bond_struct.spread                   = 0.00 ;
%! bond_struct.long_first_period        = false;
%! bond_struct.long_last_period         = false;
%! bond_struct.last_reset_rate          = 0.0000000;
%! bond_struct.fixed_annuity            = 1;
%! bond_struct.in_arrears               = 0;
%! bond_struct.notional_at_start        = false;
%! bond_struct.notional_at_end          = true;
%! bond_struct.prepayment_flag          = false;
%! bond_struct.use_principal_pmt        = 0;
%! bond_struct.use_outstanding_balance  = 0;
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('01-Nov-2011','base',bond_struct);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_values,11.92133107 .* ones(1,10),0.00001);

%!test
%! bond_struct=struct();
%! bond_struct.sub_type                 = 'FAB';
%! bond_struct.issue_date               = '01-Nov-2011';
%! bond_struct.maturity_date            = '01-Nov-2021';
%! bond_struct.compounding_type         = 'simple';
%! bond_struct.compounding_freq         = 1  ;
%! bond_struct.term                     = 12   ;
%! bond_struct.term_unit                = 'months';
%! bond_struct.day_count_convention     = 'act/365';
%! bond_struct.basis                    = 3;
%! bond_struct.notional                 = 100 ;
%! bond_struct.coupon_rate              = 0.0333; 
%! bond_struct.coupon_generation_method = 'backward' ;
%! bond_struct.business_day_rule        = 0 ;
%! bond_struct.business_day_direction   = 1  ;
%! bond_struct.enable_business_day_rule = 0;
%! bond_struct.use_annuity_amount       = 0;
%! bond_struct.spread                   = 0.00 ;
%! bond_struct.long_first_period        = false;
%! bond_struct.long_last_period         = false;
%! bond_struct.last_reset_rate          = 0.0000000;
%! bond_struct.fixed_annuity            = 1;
%! bond_struct.in_arrears               = 0;
%! bond_struct.notional_at_start        = false;
%! bond_struct.notional_at_end          = true;
%! bond_struct.prepayment_type          = 'full';  % ['full','default']
%! bond_struct.prepayment_source        = 'curve'; % ['curve','rate']
%! bond_struct.prepayment_flag          = true;
%! bond_struct.prepayment_rate          = 0.00; 
%! bond_struct.use_principal_pmt        = 0;
%! bond_struct.use_outstanding_balance  = 0;
%! c = Curve();
%! c = c.set('id','PSA_CURVE','nodes',[0,900],'rates_stress',[0.0,0.06;0.0,0.08;0.01,0.10],'method_interpolation','linear','compounding_type','simple');
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('01-Nov-2011','stress',bond_struct,c);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_values(:,end),[7.63168805976622;6.53801392731666;5.48158314020277 ],0.0000001);     

%!test 
%! bond_struct=struct();
%! bond_struct.sub_type                 = 'SWAP_FLOATING';
%! bond_struct.issue_date               = '31-Mar-2018';
%! bond_struct.maturity_date            = '28-Mar-2028';
%! bond_struct.compounding_type         = 'disc';
%! bond_struct.compounding_freq         = 1;
%! bond_struct.term                     = 365;
%! bond_struct.term_unit                = 'days';
%! bond_struct.day_count_convention     = 'act/365';
%! bond_struct.basis                    = 3;
%! bond_struct.notional                 = 100 ;
%! bond_struct.coupon_rate              = 0.00; 
%! bond_struct.coupon_generation_method = 'forward' ;
%! bond_struct.business_day_rule        = 0 ;
%! bond_struct.business_day_direction   = 1  ;
%! bond_struct.enable_business_day_rule = 0;
%! bond_struct.spread                   = 0.00 ;
%! bond_struct.long_first_period        = false;
%! bond_struct.long_last_period         = false;
%! bond_struct.last_reset_rate          = 0.0000000;
%! bond_struct.fixed_annuity            = 1;
%! bond_struct.in_arrears               = 0;
%! bond_struct.notional_at_start        = false;
%! bond_struct.notional_at_end          = false;
%! bond_struct.prepayment_type          = 'full';  % ['full','default']
%! bond_struct.prepayment_source        = 'curve'; % ['curve','rate']
%! bond_struct.prepayment_flag          = true;
%! bond_struct.prepayment_rate          = 0.00; 
%! discount_nodes = [730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380];
%! discount_rates = [0.0001001034,0.0001000689,0.0001000684,0.0001000962,0.0003066350,0.0013812064,0.002484882,0.0035760168,0.0045624391,0.0054502705,0.0062599362];
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',discount_nodes,'rates_base',discount_rates,'method_interpolation','linear');
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('31-Mar-2016','base',bond_struct,c);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_values(end),1.5281850227882421,0.000000001);
%! assert(ret_values(1),0.0100004900156492,0.000000001);

%!test 
%! cap_struct=struct();
%! cap_struct.sub_type                 = 'CAP';
%! cap_struct.issue_date               = '31-Mar-2017';
%! cap_struct.maturity_date            = '30-Jun-2017';
%! cap_struct.compounding_type         = 'cont';
%! cap_struct.compounding_freq         = 1;
%! cap_struct.term                     = 3;
%! cap_struct.term_unit                = 'months';
%! cap_struct.day_count_convention     = 'act/365';
%! cap_struct.basis                    = 3;
%! cap_struct.notional                 = 10000 ;
%! cap_struct.coupon_rate              = 0.00; 
%! cap_struct.coupon_generation_method = 'forward' ;
%! cap_struct.business_day_rule        = 0 ;
%! cap_struct.business_day_direction   = 1  ;
%! cap_struct.enable_business_day_rule = 0;
%! cap_struct.spread                   = 0.00 ;
%! cap_struct.long_first_period        = false;
%! cap_struct.long_last_period         = false;
%! cap_struct.last_reset_rate          = 0.0000000;
%! cap_struct.fixed_annuity            = 1;
%! cap_struct.in_arrears               = 0;
%! cap_struct.notional_at_start        = false;
%! cap_struct.notional_at_end          = false;
%! cap_struct.strike                   = 0.08;
%! cap_struct.CapFlag                  = true;
%! cap_struct.model                    = 'Black';
%! cap_struct.convex_adj               = true;
%! cap_struct.vola_spread              = 0.0;
%! ref_nodes = [365,730];
%! ref_rates = [0.07,0.07];
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',ref_nodes,'rates_base',ref_rates,'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.2);
%! v = v.set('type','IRVol');
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('31-Mar-2016','base',cap_struct,c,v);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_dates,456,0.000000001);
%! assert(ret_values,5.63130599411650,0.000000001);

%!test 
%! cap_struct=struct();
%! cap_struct.sub_type                 = 'FLOOR';
%! cap_struct.issue_date               = '30-Dec-2018';
%! cap_struct.maturity_date            = '29-Dec-2020';
%! cap_struct.compounding_type         = 'simple';
%! cap_struct.compounding_freq         = 1;
%! cap_struct.term                     = 365;
%! cap_struct.term_unit                = 'days';
%! cap_struct.day_count_convention     = 'act/365';
%! cap_struct.basis                    = 3;
%! cap_struct.notional                 = 10000;
%! cap_struct.coupon_rate              = 0.00; 
%! cap_struct.coupon_generation_method = 'forward' ;
%! cap_struct.business_day_rule        = 0 ;
%! cap_struct.business_day_direction   = 1  ;
%! cap_struct.enable_business_day_rule = 0;
%! cap_struct.spread                   = 0.00 ;
%! cap_struct.long_first_period        = false;
%! cap_struct.long_last_period         = false;
%! cap_struct.last_reset_rate          = 0.0000000;
%! cap_struct.notional_at_start        = false;
%! cap_struct.notional_at_end          = false;
%! cap_struct.strike                   = 0.005;
%! cap_struct.in_arrears               = 0;
%! cap_struct.CapFlag                  = true;
%! cap_struct.model                    = 'Black';
%! cap_struct.convex_adj               = true;
%! cap_struct.vola_spread              = 0.0;
%! ref_nodes = [30,1095,1460];
%! ref_rates = [0.01,0.01,0.01];
%! sigma                               = 0.8000;
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',ref_nodes,'rates_base',ref_rates,'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',sigma);
%! v = v.set('type','IRVol');
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('31-Dec-2015','base',cap_struct,c,v);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_dates,[1460,1825]);
%! assert(ret_values,[69.3193486314239,74.0148444015558],0.000000001);

%!test 
%! cap_struct=struct();
%! cap_struct.sub_type                 = 'CAP';
%! cap_struct.issue_date               = '30-Dec-2018';
%! cap_struct.maturity_date            = '29-Dec-2020';
%! cap_struct.compounding_type         = 'simple';
%! cap_struct.compounding_freq         = 1;
%! cap_struct.term                     = 365;
%! cap_struct.term_unit                = 'days';
%! cap_struct.day_count_convention     = 'act/365';
%! cap_struct.basis                    = 3;
%! cap_struct.notional                 = 10000;
%! cap_struct.coupon_rate              = 0.00; 
%! cap_struct.coupon_generation_method = 'forward' ;
%! cap_struct.business_day_rule        = 0 ;
%! cap_struct.business_day_direction   = 1  ;
%! cap_struct.enable_business_day_rule = 0;
%! cap_struct.spread                   = 0.00 ;
%! cap_struct.long_first_period        = false;
%! cap_struct.long_last_period         = false;
%! cap_struct.last_reset_rate          = 0.0000000;
%! cap_struct.notional_at_start        = false;
%! cap_struct.notional_at_end          = false;
%! cap_struct.strike                   = 0.005;
%! cap_struct.in_arrears               = 0;
%! cap_struct.CapFlag                  = true;
%! cap_struct.model                    = 'Normal';
%! cap_struct.convex_adj               = false;
%! cap_struct.vola_spread              = 0.0;
%! ref_nodes = [30,1095,1460];
%! ref_rates = [0.01,0.01,0.01];
%! sigma                               = 0.00555;
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',ref_nodes,'rates_base',ref_rates,'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',sigma);
%! v = v.set('type','IRVol');
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('31-Dec-2015','base',cap_struct,c,v);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_dates,[1460,1825]);
%! assert(ret_values,[68.7744654466300,74.03917364111012],0.000000001);
   
%!test 
%! cap_struct=struct();
%! cap_struct.sub_type                 = 'FLOOR';
%! cap_struct.issue_date               = '30-Dec-2018';
%! cap_struct.maturity_date            = '29-Dec-2020';
%! cap_struct.compounding_type         = 'simple';
%! cap_struct.compounding_freq         = 1;
%! cap_struct.term                     = 365;
%! cap_struct.term_unit                = 'days';
%! cap_struct.day_count_convention     = 'act/365';
%! cap_struct.basis                    = 3;
%! cap_struct.notional                 = 10000;
%! cap_struct.coupon_rate              = 0.00; 
%! cap_struct.coupon_generation_method = 'forward' ;
%! cap_struct.business_day_rule        = 0 ;
%! cap_struct.business_day_direction   = 1  ;
%! cap_struct.enable_business_day_rule = 0;
%! cap_struct.spread                   = 0.00 ;
%! cap_struct.long_first_period        = false;
%! cap_struct.long_last_period         = false;
%! cap_struct.last_reset_rate          = 0.0000000;
%! cap_struct.notional_at_start        = false;
%! cap_struct.notional_at_end          = false;
%! cap_struct.strike                   = 0.005;
%! cap_struct.in_arrears               = 0;
%! cap_struct.CapFlag                  = false;
%! cap_struct.model                    = 'Normal';
%! cap_struct.convex_adj               = false;
%! cap_struct.vola_spread              = 0.0;
%! ref_nodes = [30,1095,1460];
%! ref_rates = [0.01,0.01,0.01];
%! sigma                               = 0.00555;
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',ref_nodes,'rates_base',ref_rates,'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',sigma);
%! v = v.set('type','IRVol');
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('31-Dec-2015','base',cap_struct,c,v);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_dates,[1460,1825]);
%! assert(ret_values,[18.2727946049505,23.5375027994284],0.000000001);
   
%!test 
%! bond_struct=struct();
%! bond_struct.sub_type                 = 'ZCB';
%! bond_struct.issue_date               = '31-Mar-2016';
%! bond_struct.maturity_date            = '30-Mar-2021';
%! bond_struct.compounding_type         = 'disc';
%! bond_struct.compounding_freq         = 1;
%! bond_struct.term                     = 365;
%! bond_struct.term_unit                = 'days';
%! bond_struct.day_count_convention     = 'act/365';
%! bond_struct.basis                    = 3;
%! bond_struct.notional                 = 1 ;
%! bond_struct.coupon_rate              = 0.00; 
%! bond_struct.coupon_generation_method = 'forward' ;
%! bond_struct.business_day_rule        = 0 ;
%! bond_struct.business_day_direction   = 1  ;
%! bond_struct.enable_business_day_rule = 0;
%! bond_struct.spread                   = 0.00 ;
%! bond_struct.long_first_period        = false;
%! bond_struct.long_last_period         = false;
%! bond_struct.last_reset_rate          = 0.0000000;
%! bond_struct.fixed_annuity            = 1;
%! bond_struct.in_arrears               = 0;
%! bond_struct.notional_at_start        = false;
%! bond_struct.notional_at_end          = false;
%! comp_type_curve                      = 'cont';
%! basis_curve                          = 'act/act';
%! comp_freq_curve                      = 'annual';
%! discount_nodes = [1825];
%! discount_rates = [0.0001000962];
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('31-Mar-2016','base',bond_struct);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_dates,1825);
%! assert(ret_values,1);

%!test
%! bond_struct=struct();
%! bond_struct.sub_type                 = 'FRB';
%! bond_struct.issue_date               = '22-Nov-2011';
%! bond_struct.maturity_date            = '09-Nov-2026';
%! bond_struct.compounding_type         = 'simple';
%! bond_struct.compounding_freq         = 1  ;
%! bond_struct.term                     = 12   ;
%! bond_struct.term_unit                = 'months';
%! bond_struct.day_count_convention     = 'act/365';
%! bond_struct.basis                    = 3;
%! bond_struct.prorated                 = true;
%! bond_struct.notional                 = 100 ;
%! bond_struct.coupon_rate              = 0.015; 
%! bond_struct.coupon_generation_method = 'backward' ;
%! bond_struct.business_day_rule        = 0 ;
%! bond_struct.business_day_direction   = 1  ;
%! bond_struct.enable_business_day_rule = 0;
%! bond_struct.spread                   = 0.00 ;
%! bond_struct.long_first_period        = false;
%! bond_struct.long_last_period         = false;
%! bond_struct.last_reset_rate          = 0.0000000;
%! bond_struct.fixed_annuity            = 1;
%! bond_struct.in_arrears               = 0;
%! bond_struct.notional_at_start        = false;
%! bond_struct.notional_at_end          = true;
%! bond_struct.prepayment_flag          = false;
%! [ret_dates ret_values ret_int ret_princ accrued_interest] = rollout_structured_cashflows('31-Dec-2015','base',bond_struct);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_dates,[314,679,1044,1409,1775,2140,2505,2870,3236,3601,3966],0.000000001);
%! assert(ret_values,[1.504109589,1.5,1.5,1.5,1.504109589,1.5,1.5,1.5,1.504109589,1.5,101.5],0.000000001);
%! assert(accrued_interest,0.213698630136987,0.0000001);

%!test
%! bond_struct=struct();
%! bond_struct.sub_type                 = 'FRB';
%! bond_struct.issue_date               = '22-Nov-2011';
%! bond_struct.maturity_date            = '30-Sep-2021';
%! bond_struct.compounding_type         = 'simple';
%! bond_struct.compounding_freq         = 1;
%! bond_struct.term                     = 6;
%! bond_struct.term_unit                = 'months';
%! bond_struct.prorated                 = true;
%! bond_struct.day_count_convention     = 'act/365';
%! bond_struct.basis                    = 3;
%! bond_struct.notional                 = 100 ;
%! bond_struct.coupon_rate              = 0.02125; 
%! bond_struct.coupon_generation_method = 'backward' ;
%! bond_struct.business_day_rule        = 0 ;
%! bond_struct.business_day_direction   = 1  ;
%! bond_struct.enable_business_day_rule = 0;
%! bond_struct.spread                   = 0.00 ;
%! bond_struct.long_first_period        = false;
%! bond_struct.long_last_period         = false;
%! bond_struct.last_reset_rate          = 0.0000000;
%! bond_struct.fixed_annuity            = 1;
%! bond_struct.in_arrears               = 0;
%! bond_struct.notional_at_start        = false;
%! bond_struct.notional_at_end          = true;
%! bond_struct.prepayment_flag          = false;
%!  [ret_dates ret_values ret_int ret_princ accrued_interest] = rollout_structured_cashflows('31-Dec-2015','base',bond_struct);
%!  assert(ret_values,ret_int + ret_princ,sqrt(eps))
%!  assert(ret_dates,[91,274,456,639,821,1004,1186,1369,1552,1735,1917,2100],0.000000001);
%!  assert(ret_values,[1.06541095890411,1.06541095890411,1.05958904109589,1.06541095890411,1.05958904109589,1.06541095890411,1.05958904109589,1.06541095890411,1.06541095890411,1.06541095890411,1.05958904109589,101.06541095890411],0.000000001);
%!  assert(accrued_interest,0.535616438356163,0.0000001);

%!test
%! bond_struct=struct();
%! bond_struct.id                       = 'TestFAB';
%! bond_struct.sub_type                 = 'FAB';
%! bond_struct.issue_date               = '12-Mar-2016';
%! bond_struct.maturity_date            = '12-Feb-2020';
%! bond_struct.compounding_type         = 'simple';
%! bond_struct.compounding_freq         = 1  ;
%! bond_struct.term                     = 3   ;
%! bond_struct.term_unit                = 'months';
%! bond_struct.day_count_convention     = 'act/act';
%! bond_struct.basis                    = 0;
%! bond_struct.notional                 = 34300000 ;
%! bond_struct.coupon_rate              = 0.02147; 
%! bond_struct.coupon_generation_method = 'backward' ;
%! bond_struct.business_day_rule        = 0 ;
%! bond_struct.business_day_direction   = 1  ;
%! bond_struct.enable_business_day_rule = 0;
%! bond_struct.spread                   = 0.00 ;
%! bond_struct.long_first_period        = false;
%! bond_struct.long_last_period         = false;
%! bond_struct.last_reset_rate          = 0.0000000;
%! bond_struct.fixed_annuity            = 0;
%! bond_struct.use_annuity_amount       = 0;
%! bond_struct.in_arrears               = 0;
%! bond_struct.notional_at_start        = false;
%! bond_struct.notional_at_end          = true;
%! bond_struct.prepayment_flag          = false;
%! bond_struct.principal_payment        = [147000.00] .* ones(1,16);
%! bond_struct.use_principal_pmt        = 1;
%! [ret_dates ret_values ret_int ret_princ] = rollout_structured_cashflows('31-Mar-2016','base',bond_struct);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_values(1:3),[269210.818333330,330524.621420768,329731.287322407],0.001)
%! assert(ret_values(end),32120669.536636274,0.001)

    
% testing FRN special floaters: average, min, max, capitalized CMS rates in fine and in arrears
%!test
%! valuation_date = datenum('30-Jun-2016');
%! cap_float = Bond();
%! cap_float = cap_float.set('Name','TEST_FRN_SPECIAL','coupon_rate',0.00,'value_base',100,'coupon_generation_method','forward','last_reset_rate',-0.000,'sub_type','FRN_SPECIAL','spread',0.00);
%! cap_float = cap_float.set('maturity_date','28-Jun-2026','notional',100,'compounding_type','simple','issue_date','30-Jun-2016','term',365,'term_unit','days','notional_at_end',1,'convex_adj',false);
%! cap_float = cap_float.set('cms_model','Normal','cms_sliding_term',1825,'cms_term',365,'cms_spread',0.0,'cms_comp_type','simple','cms_convex_model','Hagan','in_arrears',0,'day_count_convention','act/365');
%! ref_curve = Curve();
%! ref_curve = ref_curve.set('id','IR_EUR','nodes',[365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300,7665,8030,8395,8760,9125], ...
%!       'rates_base',[-0.0011206280,-0.001240769,-0.001150661,-0.0007102520,-0.0000300010,0.0008896040,0.0018981976,0.0029556280,0.0039820610,0.005027342,0.0059025460,0.006667721,0.007372754,0.007958249,0.008374833,0.008612803, ...
%!                     0.008781331,0.0089597410,0.009217389,0.009583927,0.0100790350,0.010662948,0.011305847,0.011987858,0.0126891510], ...
%!       'method_interpolation','linear','compounding_type','continuous');                     
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.001);
%! v = v.set('type','IRVol');
%! value_type = 'base'; 
% average, in fine, CA false
%! cap_float = cap_float.set('rate_composition','average');
%! [ret_dates ret_values ret_interest_values ret_principal_values ...
%!                                     accrued_interest last_coupon_date] = ...
%!                     rollout_structured_cashflows(valuation_date, value_type, ...
%!                     cap_float, ref_curve, v);
%! assert(ret_values,108.271971385784,sqrt(eps));
% min, in fine, CA false
%! cap_float = cap_float.set('rate_composition','min');
%! [ret_dates ret_values ret_interest_values ret_principal_values ...
%!                                     accrued_interest last_coupon_date] = ...
%!                     rollout_structured_cashflows(valuation_date, value_type, ...
%!                     cap_float, ref_curve, v);
%! assert(ret_values,99.9700569884139,sqrt(eps));
% max, in fine, CA false
%! cap_float = cap_float.set('rate_composition','max');
%! [ret_dates ret_values ret_interest_values ret_principal_values ...
%!                                     accrued_interest last_coupon_date] = ...
%!                     rollout_structured_cashflows(valuation_date, value_type, ...
%!                     cap_float, ref_curve, v);
%! assert(ret_values,115.219608147154,sqrt(eps));
% capitalized, in fine, CA false
%! cap_float = cap_float.set('rate_composition','capitalized');
%! [ret_dates ret_values ret_interest_values ret_principal_values ...
%!                                     accrued_interest last_coupon_date] = ...
%!                     rollout_structured_cashflows(valuation_date, value_type, ...
%!                     cap_float, ref_curve, v);
%! assert(ret_values,108.571656255091,sqrt(eps));
% capitalized, in arrears
%! cap_float = cap_float.set('rate_composition','capitalized','in_arrears',1);
%! [ret_dates ret_values ret_interest_values ret_principal_values ...
%!                                     accrued_interest last_coupon_date] = ...
%!                     rollout_structured_cashflows(valuation_date, value_type, ...
%!                     cap_float, ref_curve, v);
%! assert(ret_values,110.223626446553,sqrt(eps));

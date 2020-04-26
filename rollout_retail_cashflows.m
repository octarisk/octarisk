
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
%# @deftypefn {Function File} {[@var{ret_dates} @var{ret_values} @var{accrued_interest}] =} rollout_retail_cashflows (@var{valuation_date}, @var{value_type}, @var{instrument}, @var{ref_curve}, @var{surface}, @var{riskfactor})
%#
%# Compute cash flow dates and cash flows values,
%# accrued interests and last coupon date for retail products.
%#
%# @seealso{timefactor, discount_factor, get_forward_rate, interpolate_curve}
%# @end deftypefn

function [ret_dates ret_values ret_interest_values ret_principal_values ...
                                    accrued_interest last_coupon_date] = ...
                    rollout_retail_cashflows(valuation_date, value_type, ...
                    instrument, obj1, obj2, obj3)

% Input checks
if nargin < 3 || nargin > 6
    print_usage ();
end
if nargin < 4
    obj1 = [];
    obj2 = [];
    obj3 = [];
end  
if nargin < 5
    obj2 = [];
    obj3 = [];
end  
if nargin < 6
    obj3 = [];
end  

% ######################   Initial fill of para structure ###################### 
para = fill_para_struct(nargin,valuation_date, value_type, ...
                    instrument, obj1, obj2, obj3);

% ######################   Calculate Cash Flow dates  ##########################   
para = get_cf_dates(para);
    

% ############   Calculate Cash Flow values depending on type   ################     
switch (para.type)

% Type Retail instruments
case {'SAVPLAN' 'DCP'}
    para = get_cfvalues_RETAIL(para.valuation_date, value_type, para, instrument);

case {'RETEXP' }
    para = get_cfvalues_RETEXP(para.valuation_date, value_type, para, ...
		instrument, obj1, obj2);
		
case {'GOVPEN' }
    para = get_cfvalues_GOVPEN(para.valuation_date, value_type, para, ...
		instrument, obj1, obj2, obj3); 
		       
otherwise
    error('rollout_retail_cashflows: Unknown instrument type >>%s<<',any2str(para.type));
end

% ####################   Calculate Final Cash Flow values  #####################   
para    = get_final_cf_values(para);

% ######################   Calculate Accrued Interest  #########################   
para.accrued_interest  = para.ret_interest_values(:,end);
para.last_coupon_date = 0;

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
%                 General Helper Functions
%-------------------------------------------------------------------------------
function [para] = get_final_cf_values(para)

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
    para.notional = instrument.notional;
    para.term = instrument.term;
    para.term_unit = instrument.term_unit;
    para.compounding_freq = instrument.compounding_freq;
    para.maturity_date = instrument.maturity_date;
    
    if ( strcmpi(para.type,'SAVPLAN') || strcmpi(para.type,'DCP')) 
		para.maturity_date = instrument.savings_enddate;
		para.issue_date = instrument.savings_startdate;
	elseif ( strcmpi(para.type,'RETEXP') || strcmpi(para.type,'GOVPEN') ) 
		para.maturity_date = instrument.retirement_enddate;
		para.issue_date = instrument.retirement_startdate;	
    end
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

% ##############################################################################
function para = get_cfvalues_GOVPEN(valuation_date, value_type, para, instrument, iec, longev, longev_widow)

    d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
    d2 = para.cf_datesnum(2:length(para.cf_datesnum));

	year_valdate = datevec(valuation_date)(1);
	birthyear = instrument.year_of_birth - instrument.mortality_shift_years;
	age_valdate = year_valdate - birthyear;
	
	if instrument.widow_pension_flag == true
		birthyear_widow = instrument.year_of_birth_widow - instrument.mortality_shift_years_widow;
		age_valdate_widow = year_valdate - birthyear_widow;
	end
	
	% get expense payment dates only in the past up to age 120:
	pensiondates = para.cf_datesnum(para.cf_datesnum >= valuation_date);
	[yy tmp_mm tmp_dd] = datevec(valuation_date);
    new_yy = birthyear + 120;
    max_date =   datenum([new_yy tmp_mm tmp_dd]);
    pensiondates = pensiondates(para.cf_datesnum <= max_date);
        	
	% calculate expense values per expdate
	yearly_pension_value = instrument.pension_scores * ...
				instrument.value_per_score * (1 - instrument.tax_rate) * 12;
	pension_values = ones(1,length(pensiondates)) * yearly_pension_value;
	
	% get survival probabilities and extend until age 120
	survival_probs = longev.get('rates_base');
	survival_years = longev.get('nodes');
	if max(survival_years) < 120
		delta_years = [max(survival_years)+1:1:120];
		delta_probs = ones(1,length(delta_years)) .* survival_probs(end);
		survival_probs = [survival_probs,delta_probs];
		survival_years = [survival_years,delta_years];
	end
	
	
	if instrument.widow_pension_flag == true	% widow
		% get survival probabilities and extend until age 120
		survival_probs_widow = longev_widow.get('rates_base');
		survival_years_widow = longev_widow.get('nodes');
		if max(survival_years) < 120
			delta_years_widow = [max(survival_years_widow)+1:1:120];
			delta_probs_widow = ones(1,length(delta_years_widow)) .* survival_probs_widow(end);
			survival_probs_widow = [survival_probs_widow,delta_probs_widow];
			survival_years_widow = [survival_years_widow,delta_years_widow];
		end
		
	end
	
	ier = iec.getRate(value_type,1);
	ret_values = zeros(rows(ier),length(pensiondates));
	for ii=1:1:length(pensiondates)
		% adjust expense values for inflation
		term_days = pensiondates(ii) - valuation_date;
		ier = iec.getRate(value_type,term_days);
		infl_factor = 1 ./ discount_factor(valuation_date, pensiondates(ii), ier, ...
                                iec.compounding_type, iec.day_count_convention, ...
                                iec.compounding_freq);
        % adjust expense values for mortality
        year_cf = datevec(pensiondates(ii))(1);
        age_cf = year_cf - birthyear;
        survival_years_tmp = survival_years(survival_years>age_valdate);
        survival_probs_tmp = survival_probs(survival_years>age_valdate);
        survival_years_tmp = survival_years_tmp(survival_years_tmp<=age_cf);
        survival_probs_tmp = survival_probs_tmp(survival_years_tmp<=age_cf);
        cum_survival = prod(survival_probs_tmp,2) ;                              
		ret_values(:,ii) = cum_survival .* infl_factor .* pension_values(ii);
		
		% adjust for widow pension:
		if instrument.widow_pension_flag == true
			age_cf_widow = year_cf - birthyear_widow;
			survival_years_tmp = survival_years_widow(survival_years_widow>age_valdate_widow);
			survival_probs_tmp = survival_probs_widow(survival_years_widow>age_valdate_widow);
			survival_years_tmp = survival_years_tmp(survival_years_tmp<=age_cf_widow);
			survival_probs_tmp = survival_probs_tmp(survival_years_tmp<=age_cf_widow);
			cum_survival_widow = prod(survival_probs_tmp,2);
			widow_pension = instrument.widow_pension_rate .* (1-cum_survival) ...
						.* cum_survival_widow .* infl_factor .* pension_values(ii);
			ret_values(:,ii) = 	ret_values(:,ii) + 	widow_pension;	
		end
	end

	cf_interest = zeros(rows(ret_values),columns(ret_values));
    cf_principal = ret_values;
    
    % return struct
    para.ret_values     = ret_values;
    para.cf_interest    = cf_interest;
    para.cf_principal   = cf_principal;
	
end       
        
% ##############################################################################
function para = get_cfvalues_RETEXP(valuation_date, value_type, para, instrument, iec, longev)

    d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
    d2 = para.cf_datesnum(2:length(para.cf_datesnum));

	year_valdate = datevec(valuation_date)(1);
	birthyear = instrument.year_of_birth - instrument.mortality_shift_years;
	age_valdate = year_valdate - birthyear;
	
	% get expense payment dates only in the past:
	expdates = para.cf_datesnum(para.cf_datesnum >= valuation_date);
	[yy tmp_mm tmp_dd] = datevec(valuation_date);
	new_yy = birthyear + 120;
    max_date =   datenum([new_yy tmp_mm tmp_dd]);
    expdates = expdates(para.cf_datesnum <= max_date);
    
	% calculate expense values per expdate
	if isempty(instrument.expense_values)
		error('rollout_retail_cashflows: no expenses set.');
	else
		expense_values = zeros(rows(expdates),1);
		exp_change_dates = datenum(instrument.expense_dates);
		for kk=1:1:length(exp_change_dates)
			exp_chg_date = exp_change_dates(kk);
			expense_values(expdates>=exp_chg_date) = instrument.expense_values(kk);
		end
	end
	
	% get survival probabilities and extend until age 120
	survival_probs = longev.get('rates_base');
	survival_years = longev.get('nodes');
	if max(survival_years) < 120
		delta_years = [max(survival_years)+1:1:120];
		delta_probs = ones(1,length(delta_years)) .* survival_probs(end);
	end
	survival_probs = [survival_probs,delta_probs];
	survival_years = [survival_years,delta_years];
	
	
	
	ier = iec.getRate(value_type,1);
	ret_values = zeros(rows(ier),length(expdates));
	for ii=1:1:length(expdates)
		% adjust expense values for inflation
		term_days = expdates(ii) - valuation_date;
		ier = iec.getRate(value_type,term_days);
		infl_factor = 1 ./ discount_factor(valuation_date, expdates(ii), ier, ...
                                iec.compounding_type, iec.day_count_convention, ...
                                iec.compounding_freq);
        % adjust expense values for mortality
        year_cf = datevec(expdates(ii))(1);
        age_cf = year_cf - birthyear;
        survival_years_tmp = survival_years(survival_years>age_valdate);
        survival_probs_tmp = survival_probs(survival_years>age_valdate);
        survival_years_tmp = survival_years_tmp(survival_years_tmp<=age_cf);
        survival_probs_tmp = survival_probs_tmp(survival_years_tmp<=age_cf);
        cum_survival = prod(survival_probs_tmp,2);                                
		ret_values(:,ii) = cum_survival .* infl_factor .* expense_values(ii);
	end

	cf_interest = zeros(rows(ret_values),columns(ret_values));
    cf_principal = ret_values;
    
    % return struct
    para.ret_values     = ret_values;
    para.cf_interest    = cf_interest;
    para.cf_principal   = cf_principal;
	
end
% ##############################################################################
function para = get_cfvalues_RETAIL(valuation_date, value_type, para, instrument)

    d1 = para.cf_datesnum(1:length(para.cf_datesnum)-1);
    d2 = para.cf_datesnum(2:length(para.cf_datesnum));

	% get savings payment dates only in the past:
	savdates = para.cf_datesnum(para.cf_datesnum <= valuation_date);
	
	% calculate savings rate vec
	if isempty(instrument.savings_change_values)
		savings_rate = instrument.savings_rate;
	else
		savings_rate = zeros(rows(savdates),1);
		sav_change_dates = datenum(instrument.savings_change_dates);
		for kk=1:1:length(sav_change_dates)
			sav_chg_date = sav_change_dates(kk);
			savings_rate(savdates>=sav_chg_date) = instrument.savings_change_values(kk);
		end
	end
	% calculate interest an principal cf values
	int_cf_values = ((1 ./ discount_factor(savdates, instrument.maturity_date, para.coupon_rate, ...
                                para.compounding_type, para.dcc, ...
                                para.compounding_freq))-1) .* savings_rate;
	princ_cf_values = ones(length(int_cf_values),1) .* savings_rate;
	
	% sum up all future values of cash flows
	cf_interest = sum(int_cf_values);
	cf_principal = sum(princ_cf_values);
	
	% take into account extra payments and redemption option
	if strcmpi(instrument.sub_type,'SAVPLAN')
		% calculate interest an principal cf values
		[redemption_date] = addtodatefinancial(valuation_date, ...
						instrument.notice_period, instrument.notice_period_unit);
		% putable cashflows
		int_cf_values_putable = ((1 ./ discount_factor(savdates, redemption_date, para.coupon_rate, ...
									para.compounding_type, para.dcc, ...
									para.compounding_freq))-1) .* savings_rate;
		
		% sum up all future values of cash flows
		cf_interest_putable = sum(int_cf_values_putable);
		
		% take into account extra payments:
		extra_dates = datenum(instrument.extra_payment_dates);
		if ~(length(extra_dates) == length(instrument.extra_payment_values) )
			error('rollout_structured_cashflows: length of extra payments and dates dont match for >>%s<<',instrument.id);
		end

		for kk=1:1:length(extra_dates)
			tmp_date = extra_dates(kk);
			if (tmp_date <= valuation_date)
				tmp_val = instrument.extra_payment_values(kk);
				cf_interest = cf_interest + ((1 ./ discount_factor(tmp_date, ...
									instrument.maturity_date,  ...
									para.coupon_rate,para.compounding_type, para.dcc, ...
									para.compounding_freq))-1) .* tmp_val;
				cf_principal = cf_principal + tmp_val;   
				% putable cashflows
				cf_interest_putable = cf_interest_putable + ((1 ./ discount_factor(tmp_date, redemption_date,  ...
									para.coupon_rate,para.compounding_type, para.dcc, ...
									para.compounding_freq))-1) .* tmp_val;
			end             
		end
		
		% pay out bonus interests
		cf_interest = cf_interest + cf_interest * instrument.bonus_value_current;
		cf_interest_putable = cf_interest_putable + cf_interest_putable * instrument.bonus_value_redemption;
		cf_principal_putable = cf_principal;
	elseif strcmpi(instrument.sub_type,'DCP')
		% take into account redemption values at next redemption date
		if ~isempty(instrument.redemption_dates)
		  redemption_dates 	= datenum(instrument.redemption_dates) - valuation_date;
		  redemption_values 	= instrument.redemption_values;
		  redemption_date_future = redemption_dates(redemption_dates>0);
		  if ~isempty(redemption_date_future)		
			redemption_date = valuation_date + redemption_date_future(1); 
			redemption_dates(redemption_dates<0)=0;
			redemption_value = interpolate_curve(redemption_dates', ...
							redemption_values,1,'next');
			% get PV of future savings and deduct FV from redemption value 
			future_payment_days = para.cf_datesnum(para.cf_datesnum>valuation_date);
			future_payment_days = future_payment_days(future_payment_days<=redemption_date);
			% FV discount factor
			fv_rate = interpolate_curve(para.tmp_nodes,para.tmp_rates, ...
						redemption_date-valuation_date,para.method_interpolation);
			fv_df = (1 ./ discount_factor(valuation_date, redemption_date, fv_rate, ...
									para.compounding_type, para.dcc, ...
									para.compounding_freq));
			% get DF of	future_payment_days	
			adj_red_value = 0;
			for kk=1:1:length(future_payment_days)
				tmp_date = future_payment_days(kk);
				tmp_node = tmp_date-valuation_date;
				pv_rate = interpolate_curve(para.tmp_nodes,para.tmp_rates, ...
						tmp_node,para.method_interpolation);
                    
				pv_df = (discount_factor(valuation_date, tmp_date, pv_rate, ...
									para.compounding_type, para.dcc, ...
									para.compounding_freq)) ;										
				adj_red_value = adj_red_value + pv_df .* fv_df .* savings_rate(end);
			end
		  end		
		else
			% floor: value of instrument cannot be negative
			redemption_date  = valuation_date;
			redemption_value = 0.0;
			adj_red_value = 0.0;
		end
				
		% sum up all future values of cash flows
		cf_interest_putable = 0.0;
		cf_principal_putable = redemption_value - adj_red_value;
	end
	ret_values_putable = cf_interest_putable + cf_principal_putable;
	ret_values = ones(rows(ret_values_putable),1) .* (cf_interest + cf_principal);
	cf_principal =  ones(rows(ret_values_putable),1)  .* cf_principal;
	
    % only final cash flow at maturity date
    para.cf_dates    = [para.issuevec;datevec(redemption_date);datevec(instrument.maturity_date)];
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
    
    % return struct: first column cashflows at redemption date, second column at maturity date
    para.ret_values     = [ret_values_putable,ret_values];
    para.cf_interest    = [cf_interest_putable,cf_interest];
    para.cf_principal   = [cf_principal_putable,cf_principal];
end % end get_cfvalues_RETAIL



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

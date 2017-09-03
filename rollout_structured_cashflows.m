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
%# Compute the dates and values of cash flows (interest and principal and 
%# accrued interests and last coupon date for fixed rate bonds, 
%# floating rate notes, amortizing bonds, zero coupon bonds and 
%# structured products like caps and floors, CM Swaps, capitalized or averaging
%# CMS floaters or inflation linked bonds.@*
%# For FAB, ref_curve is used as prepayment curve, surface for PSA factors,
%# riskfactor for IR Curve shock extraction.
%# For Inflation Linked Bonds ref_curve is used as inflation expectation curve,
%# surface is used for Consumer Price Index.
%#
%# @seealso{timefactor, discount_factor, get_forward_rate, interpolate_curve}
%# @end deftypefn

function [ret_dates ret_values ret_interest_values ret_principal_values ...
                                    accrued_interest last_coupon_date] = ...
                    rollout_structured_cashflows(valuation_date, value_type, ...
                    instrument, ref_curve, surface,riskfactor)

%TODO: introduce prepayment type 'default'

% Parse bond struct
if nargin < 3 || nargin > 6
    print_usage ();
 end

if (ischar(valuation_date))
    valuation_date = datenum(valuation_date); 
end

if nargin > 3 
% get curve variables:
    tmp_nodes    = ref_curve.get('nodes');
    tmp_rates    = ref_curve.getValue(value_type);

% Get interpolation method and other curve related attributes
    method_interpolation = ref_curve.get('method_interpolation');
    basis_curve     = ref_curve.get('basis');
    comp_type_curve = ref_curve.get('compounding_type');
    comp_freq_curve = ref_curve.get('compounding_freq');
 end
                                
% --- Checking object field items --- 
    compounding_type = instrument.compounding_type;
    if (strcmp(instrument.issue_date,'01-Jan-1900'))
        issue_date = datestr(valuation_date);
    else
        issue_date = instrument.issue_date;
    end
    day_count_convention    = instrument.day_count_convention;
    dcc                     = instrument.basis;
    coupon_rate             = instrument.coupon_rate;
    coupon_generation_method = instrument.coupon_generation_method; 
    notional_at_start       = instrument.notional_at_start; 
    notional_at_end         = instrument.notional_at_end; 
    business_day_rule       = instrument.business_day_rule;
    business_day_direction  = instrument.business_day_direction;
    enable_business_day_rule = instrument.enable_business_day_rule;
    long_first_period       = instrument.long_first_period;
    long_last_period        = instrument.long_last_period;
    spread                  = instrument.spread;
    in_arrears_flag         = instrument.in_arrears;

% --- Checking mandatory structure field items --- 

    type = instrument.sub_type;
    if (  strcmpi(type,'ZCB') || strcmpi(type,'FRA') || strcmpi(type,'FVA'))
        coupon_generation_method = 'zero';
    elseif ( strcmpi(type,'FRN') || strcmpi(type,'SWAP_FLOATING') || strcmpi(type,'CAP') || strcmpi(type,'FLOOR'))
            last_reset_rate = instrument.last_reset_rate;
    elseif ( strcmpi(type,'FAB'))
            fixed_annuity_flag = instrument.fixed_annuity;
            use_principal_pmt_flag = instrument.use_principal_pmt;
            use_annuity_amount = instrument.use_annuity_amount;
    end
    notional = instrument.notional;
    term = instrument.term;
    compounding_freq = instrument.compounding_freq;
    maturity_date = instrument.maturity_date;

    % get term time factor (payments per year)
    if ( mod(term,365) == 0 && term ~= 0)
        term_factor = 365 / term; 
    elseif ( term == 12 || term == 52)
        term_factor = 1; 
    elseif ( term == 6)
        term_factor = 2; 
    elseif ( term == 3)
        term_factor = 4; 
    elseif ( term == 1)
        term_factor = 12;
    elseif ( term == 0) % All cash flows are paid at maturity
        term_factor = 1;         
    else    
        term_factor = 1;
    end
    comp_freq = term_factor;
% check for existing interest rate curve for FRN
if (nargin < 2 && strcmp(type,'FRN') == 1)
    error('Too few arguments. No existing IR curve for type FRN.');
end

if (nargin < 2 && strcmp(type,'SWAP_FLOATING') == 1)
    error('Too few arguments. No existing IR curve for type FRN.');
end
maturitydatenum = datenum(maturity_date);
issuedatenum = datenum(issue_date);
if ( issuedatenum > maturitydatenum)
    error('Error: Issue date later than maturity date');
end

% ------------------------------------------------------------------------------
% Start Calculation:
issuevec = datevec(issue_date);
todayvec = datevec(valuation_date);
matvec = datevec(maturity_date);
% floor forward rate at 0.000001:
floor_flag = false;
% cashflow rollout: method backwards
if ( strcmpi(coupon_generation_method,'backward') )
	cf_date = matvec;
	cf_dates = cf_date;
    cfdatenum = maturitydatenum;
	while cfdatenum >= issuedatenum
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
			
		% rollout for annual 365 days (compounding frequency = 1 payment per year)
		elseif ( term == 365 || term == 52 || term == 0)
			new_cf_date = cfdatenum-365;
			new_cf_date = datevec(new_cf_date);
			new_cf_year = new_cf_date(:,1);
			new_cf_month = new_cf_date(:,2);
			new_cf_day = new_cf_date(:,3);    
			
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
		% update cf_date
		cf_date = [new_cf_year, new_cf_month, new_cf_day, 0, 0, 0];
		cfdatenum = datenum(cf_date);
		if cfdatenum >= issuedatenum
			cf_dates = [cf_dates ; cf_date];
		end
	end % end coupon generation backward
    % flip cf_date vector (since backward has reverse order)
	cf_dates = flipud(cf_dates);

% cashflow rollout: method forward
elseif ( strcmpi(coupon_generation_method,'forward') )
	cf_date = issuevec;
	cf_dates = cf_date;
	cfdatenum = issuedatenum;
	while cfdatenum <= maturitydatenum
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
		% rollout for annual 365 days (compounding frequency = 1 payment per year)
		elseif ( term == 365 || term == 52 || term == 0)
			new_cf_date = cfdatenum + 365;
			new_cf_date = datevec(new_cf_date);
			new_cf_year = new_cf_date(:,1);
			new_cf_month = new_cf_date(:,2);
			new_cf_day = new_cf_date(:,3);   
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
		else
			error('rollout_cashflows_oop: unknown term >>%s<<',any2str(term));
		end
		% update cf_date
		cf_date = [new_cf_year, new_cf_month, new_cf_day, 0, 0, 0];
		cfdatenum = datenum(cf_date);
		if ( cfdatenum <= maturitydatenum)
			cf_dates = [cf_dates ; cf_date];
		end
	end        % end coupon generation forward

%-------------------------------------------------------------------------------
% cashflow rollout: method zero
elseif ( strcmpi(coupon_generation_method,'zero'))
    % rollout for zero coupon bonds -> just one cashflow at maturity
        cf_dates = [issuevec ; matvec];
end 
%-------------------------------------------------------------------------------    

%-------------------------------------------------------------------------------
% Adjust first and last coupon period to implement issue date:
if (long_first_period == true)
    if ( datenum(cf_dates(1,:)) > issuedatenum )
        cf_dates(1,:) = issuevec;
    end
else
    if ( datenum(cf_dates(1,:)) > issuedatenum )
        cf_dates = [issuevec;cf_dates];
    end
end
if (long_last_period == true)
    if ( datenum(cf_dates(rows(cf_dates),:)) < maturitydatenum )
        cf_dates(rows(cf_dates),:) = matvec;
    end
else
    if ( datenum(cf_dates(rows(cf_dates),:)) < maturitydatenum )
        cf_dates = [cf_dates;matvec];
    end
end
%special case: long_last_period == long_first_period == true || only one cashflow (e.g. monthly term):
if (rows(cf_dates) == 1)
   cf_dates = [issuevec;matvec];
end

% one time and forever: get datenum of cf_dates
cf_datesnum = datenum(cf_dates);
if ( enable_business_day_rule == true)
	cf_business_datesnum = busdate(cf_datesnum-1 + business_day_rule, ...
										business_day_direction);
	cf_business_dates = datevec(cf_business_datesnum);
else
	cf_business_datesnum = cf_datesnum;
	cf_business_dates = cf_dates;
end

%-------------------------------------------------------------------------------

%-------------------------------------------------------------------------------
% ############   Calculate Cash Flow values depending on type   ################   
%
% Type FRB: Calculate CF Values for all CF Periods
if ( strcmpi(type,'FRB') || strcmpi(type,'SWAP_FIXED') )

    d1 = cf_datesnum(1:length(cf_datesnum)-1);
    d2 = cf_datesnum(2:length(cf_datesnum));
    % preallocate memory
    cf_principal = zeros(1,length(d1));
    % calculate all cash flows (assume prorated == true --> deposit method
	cf_values = ((1 ./ discount_factor(d1, d2, coupon_rate, ...
										compounding_type, dcc, ...
										compounding_freq)) - 1)' .* notional;
	% prorated == false: adjust deposit method to bond method --> in case
	% of leap year adjust time period length by adding one day and
	% recalculate cash flow
	if ( instrument.prorated == false) 
		delta_coupon = cf_values - coupon_rate .* notional;
		delta_prorated = notional .* coupon_rate / 365;
		if ( abs(delta_coupon - delta_prorated) < sqrt(eps))
			cf_values = ((1 ./ discount_factor(d1+1, d2, ...
								coupon_rate, compounding_type, dcc, ...
								compounding_freq)) - 1)' .* notional;
		end
	end

    ret_values = cf_values;
    cf_interest = cf_values;
    % Add notional payments
    if ( notional_at_start == 1)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - notional;     
        cf_principal(:,1) = - notional;
    end
    if ( notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + notional;
        cf_principal(:,end) = notional;
    end

% ##############################################################################
%
% Type FRA: Calculate CF Value for Forward Rate Agreements
% Forward Rate Agreement has following times and discount factors
% -----X------------------------X---------------------------X----
%      T0		    Tt (maturity date FRA)           Tu (underlying mat date)
% Discount Factors:             |---------------------------|
%                                    forward rate ---> du   
%                                    strike rate  ---> dk
% Calculate cashflow as forward discounting of difference of compounded strike 
% and compounded forward rates:
% Cashflow = notional * (1/du - 1/dk) * du = notional * (1 - du / dk)
% Value <---------  discounting  ------    Cashflow at Tt    
elseif ( strcmpi(type,'FRA') )
    T0 = valuation_date;	% valuation_date
    Tt = cf_datesnum(2) - T0; % cash flow date = maturity date of FRA
	Tu = datenum(instrument.underlying_maturity_date) - T0; % underlyings maturity date
	% preallocate memory
	cf_values = zeros(rows(tmp_rates),1);
		
	% only future cashflows, underlying > instrument mat date
	if ( Tu >= Tt && Tt >= 0)	
		% get forward rate from Tt -> Tu
		forward_rate = get_forward_rate(tmp_nodes,tmp_rates, ...
					Tt,Tu-Tt,compounding_type,method_interpolation, ...
                    compounding_freq, basis_curve, valuation_date, ...
					comp_type_curve, basis_curve, comp_freq_curve,floor_flag);

		% get discount factors
		% underlying forward rate discount factor
		du = discount_factor(Tt, Tu, forward_rate, ...
								comp_type_curve, basis_curve, comp_freq_curve);
		
		% strike discount factor	
		strike_rate_conv = convert_curve_rates(Tt,Tu,instrument.strike_rate, ...
				'cont','annual',3,comp_type_curve,comp_freq_curve,basis_curve);
		dk_strike = discount_factor(Tt, Tu, strike_rate_conv, ...
								comp_type_curve, basis_curve, comp_freq_curve);
										   
		% calculate cash flow
		if ( strcmpi(instrument.coupon_prepay,'discount')) % Coupon Prepay = Discount
			cf_values(:,1) = notional .* ( 1 - du ./ dk_strike );
		else	% in fine
			cf_values(:,1) = notional .* ( 1 - du ./ dk_strike ) ./ du;
		end
	else	% past cash flows or invalid cash flows
		fprintf('rollout_structured_cashflows: FRA >>%s<< has invalid cash flow dates or invalid (underlyings) maturity date. cf_values = 0.0.\n', instrument.id);
		cf_values = 0.0;
	end
    ret_values = cf_values;
	cf_principal = cf_values;
    cf_interest = 0.0;

% ##############################################################################
%
% Type FVA: Calculate CF Value for Forward Volatility Agreements
% Forward Volatility Agreement has following times steps and discount factors
% -----X------------------------X---------------------------X----
%      T0		    Tt (maturity date FVA)           Tu (underlying mat date)
% Discount Factors:             |---------------------------|
%                                    volatility at Tu ---> Tu_vol 
%                                    volatility at Tt ---> Tt_vol   
%                                    strike volatility  ---> K_vol
% Calculate cashflow as square root of difference between standardized variances 
% and strike volatility:
% Cashflow = notional * (sqrt( (Tu_vol^2 - Tt_vol^2) / TF_Tu) - K_vol)
% Value <---------  discounting  ------    Cashflow at Tt    
elseif ( strcmpi(type,'FVA') )
    T0 = valuation_date;	% valuation_date
    Tt = cf_datesnum(2) - T0; % cash flow date = maturity date of FRA
	Tu = datenum(instrument.underlying_maturity_date) - T0; % underlyings maturity date
	
		
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
		TF_Tu 		= timefactor(0,Tu,dcc);
		TF_Tt 		= timefactor(0,Tt,dcc);
		TF_Tt_Tu 	= timefactor(Tt,Tu,dcc);
		% calculate forward variance
		fwd_var = (Tu_vol.^2 .* TF_Tu - Tt_vol.^2 .* TF_Tt);
		% preallocate memory
		cf_values = zeros(rows(fwd_var),1);
		% calculate final cashflows
		if ( fwd_var > 0.0)
			if ( strcmpi(instrument.fva_type,'volatility'))
				cf_values(:,1) = notional .* (sqrt( fwd_var ./ TF_Tt_Tu) - instrument.strike_rate);
			elseif ( strcmpi(instrument.fva_type,'variance'))
				cf_values(:,1) = notional .* ( fwd_var ./ TF_Tt_Tu - instrument.strike_rate.^2);
			else
				fprintf('rollout_structured_cashflows: FRV >>%s<< has unknown fva_type >>%s<<\n', instrument.id, instrument.fva_type);
			end
		else	% prevent complex cf values
			fprintf('rollout_structured_cashflows: FRV >>%s<< has negative forward variance. cf_values = 0.0.\n', instrument.id);
			cf_values(:,1) = 0.0;
		end
	else	% past cash flows or invalid cash flows
		fprintf('rollout_structured_cashflows: FRV >>%s<< has invalid cash flow dates or invalid (underlyings) maturity date. cf_values = 0.0.\n', instrument.id);
		cf_values = 0.0;
	end
    ret_values = cf_values;
	cf_principal = cf_values;
    cf_interest = 0.0;
	
% ##############################################################################

% Type Inflation Linked Bonds: Calculate CPI adjustedCF Values 
elseif ( strcmpi(type,'ILB') || strcmpi(type,'CAP_INFL') || strcmpi(type,'FLOOR_INFL') )
	% remap input objects: ref_curve, surface,riskfactor
	iec 	= ref_curve;
	hist 	= surface;
	cpi 	= riskfactor;
	notional_tmp = notional;
    %cf_datesnum = cf_datesnum((cf_datesnum-today)>0)
    d1 = cf_datesnum(1:length(cf_datesnum)-1);
    d2 = cf_datesnum(2:length(cf_datesnum));
	
	% get current CPI level
	cpi_level = cpi.getValue(value_type);
	% without indexation lag initial and current level are equal
	cpi_initial = cpi_level;
		
	% get historical index level for indexation lag > 0
	if (instrument.use_indexation_lag == true)
		adjust_for_month = instrument.infl_exp_lag;
		if (adjust_for_month ~= 0) % adjust for lag
			adjust_for_years = floor(adjust_for_month/12);
			adjust_for_month = adjust_for_month - floor(adjust_for_month/12) * 12;
			% calculate indexation lag in days:
			[valdate_yy valdate_mm valdate_dd] = datevec(valuation_date);
			tmp_date = datenum(valdate_yy - adjust_for_years,valdate_mm - adjust_for_month, valdate_dd  );
			%new_cf_day = check_day(valdate_yy,valdate_mm - adjust_for_month,valdate_dd - adjust_for_years )
			diff_days = valuation_date - tmp_date	;
			cpi_initial = hist.getRate(value_type,-diff_days);
		end
	end
    % preallocate memory
	no_scen = max(length(iec.getRate(value_type,0)),length(cpi_level));
	cf_values = zeros(no_scen,length(d1));
    cf_principal = zeros(no_scen,length(d1));
	inflation_index = zeros(no_scen,length(d1));
	
	% precalculate rates at nodes
	rates_interest = ((1 ./ discount_factor(d1, d2, coupon_rate, ...
                                            compounding_type, dcc, ...
                                            compounding_freq)) - 1)';
											
    % calculate all cash flows (assume prorated == true --> deposit method
    for ii = 1: 1 : length(d2)
        % convert dates into years from valuation date with timefactor
		% check for indexation_lag and adjust timesteps accordingly
		tmp_d1 = d1(ii);
		tmp_d2 = d2(ii);
		if (instrument.use_indexation_lag == true)
			adjust_for_month = instrument.infl_exp_lag;
			if (adjust_for_month ~= 0) % adjust for lag
				adjust_for_years = floor(adjust_for_month/12);
				adjust_for_month = adjust_for_month - floor(adjust_for_month/12) * 12;
				[d1_yy d1_mm d1_dd] = datevec(tmp_d1);
				tmp_d1 = datenum(d1_yy - adjust_for_years,d1_mm - adjust_for_month, d1_dd );
				[d2_yy d2_mm d2_dd] = datevec(tmp_d2);
				tmp_d2 = datenum(d2_yy - adjust_for_years,d2_mm - adjust_for_month, d2_dd );
			end
		end
		% get timefactors and cf dates
        [tf dip dib] = timefactor (tmp_d1, tmp_d2, dcc);
        t1 = (tmp_d1 - valuation_date);
        t2 = (tmp_d2 - valuation_date);
		
        if ( t2 >= 0 && t2 >= t1 )        % future cash flows only
            % adjust notional according to CPI adjustment factor based on
            % interpolated inflation expectation curve rates
            % distinguish between t1 and t2
			iec_rate = iec.getRate(value_type,t2);
			adj_cpi_factor = 1 ./ discount_factor(valuation_date, tmp_d2, iec_rate, ...
                                            iec.compounding_type, iec.basis, ...
                                            iec.compounding_freq);	
			% take adjust cpi factor relativ to initial cpi value
            notional_tmp = notional .* adj_cpi_factor .* cpi_level ./ cpi_initial;
			inflation_index(:,ii) = adj_cpi_factor .* cpi_level;
            cf_values(:,ii) = rates_interest(ii) .* notional_tmp;
			% prorated == false: adjust deposit method to bond method --> in case
			% of leap year adjust time period length by adding one day and
			% recalculate cash flow
			if ( instrument.prorated == false) 
				delta_coupon = cf_values(ii) - coupon_rate .* notional_tmp;
				delta_prorated = notional_tmp .* coupon_rate / 365;
				if ( abs(delta_coupon - delta_prorated) < sqrt(eps))
					cf_values(:,ii) = ((1 ./ discount_factor(d1(ii)+1, d2(ii), ...
										coupon_rate, compounding_type, dcc, ...
										compounding_freq)) - 1) .* notional_tmp;
				end
			end
			
			% overwrite ILB cashflows in case of Caps or Floors
            if (strcmpi(type,'CAP_INFL') || strcmpi(type,'FLOOR_INFL'))
				% expand inflation index
				inflation_index = [ones(rows(inflation_index),1) .* cpi_initial, inflation_index];
                % calculate inflation rate derived from inflation_index
				% allow only for discrete compounding
				inflation_rate = inflation_index(:,ii+1) ./ inflation_index(:,ii) - 1;
				strike_rate = instrument.strike;
				% TODO: additional curve object with variable strike rate
				%strike_rate = strike_curve.getRate(value_type,t2);
				if ( instrument.CapFlag == true)
					cf_values(:,ii) = notional .* (inflation_rate - strike_rate);
				else
					cf_values(:,ii) = notional .* (strike_rate - inflation_rate);
				end
            end
        else    % if both cf dates t1 and t2 lie in the past omit cash flow
            cf_values(:,ii)  = 0.0;
        end
    end
    ret_values = cf_values;
    cf_interest = cf_values;
    % Add CPI adjusted notional payments at end
    if ( notional_at_start == 1)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - notional_tmp;     
        cf_principal(:,1) = - notional_tmp;
    end
    if ( notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + notional_tmp;
        cf_principal(:,end) = notional_tmp;
    end

	% ##############################################################################

% Type Averaging FRN: Average forward or historical rates of cms_sliding period
elseif ( strcmpi(type,'FRN_FWD_SPECIAL') || strcmpi(type,'SWAP_FLOATING_FWD_SPECIAL'))
    %cf_datesnum = cf_datesnum((cf_datesnum-valuation_date)>0);
    d1 = cf_datesnum(1:length(cf_datesnum)-1);
    d2 = cf_datesnum(2:length(cf_datesnum));
    notvec = zeros(1,length(d1));
    notvec(length(notvec)) = 1;
    cf_values = zeros(rows(tmp_rates),length(d1));
    cf_principal = zeros(rows(tmp_rates),length(d1));
    sliding_term = instrument.fwd_sliding_term;	% averaging period
	und_term = instrument.fwd_term;		% term of averaging period
	hist = surface;
	if ~( mod(sliding_term,und_term) == 0 )
		error('ERROR: rollout_structured_cashflow:FRN_FWD_SPECIAL: Sliding term and averaging term does not match! mod(sliding_term,und_term) = %s',any2str(mod(sliding_term,averaging_term)));
	end
		
    for ii = 1 : 1 : length(d1)
        % convert dates into years from valuation date with timefactor
        [tf dip dib] = timefactor (d1(ii), d2(ii), dcc);
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
				avg_date_begin 	= fed - kk;
				avg_date_end 	= fed - kk + und_term;
				% get rate depending on date
				if (avg_date_begin < 0)	% take historical rates
					rate_curve = hist.getRate(value_type,avg_date_begin);
				else					% get forward rate for period
					rate_curve = get_forward_rate(tmp_nodes,tmp_rates, ...
                        avg_date_begin,avg_date_end - avg_date_begin,compounding_type,method_interpolation, ...
                        compounding_freq, basis_curve, valuation_date, ...
                        comp_type_curve, basis_curve, comp_freq_curve,floor_flag);
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
            forward_rate = (spread + forward_rate_curve) .* tf;
			
        elseif ( t1 < 0 && t2 > 0 )     % if last cf date is in the past, while
                                        % next is in future, use last reset rate
            forward_rate = (spread + last_reset_rate) .* tf;
        else    % if both cf dates t1 and t2 lie in the past omit cash flow
            forward_rate = 0.0;
        end
        cf_values(:,ii) = forward_rate;
    end
    ret_values = cf_values .* notional;
    cf_interest = ret_values;
    % Add notional payments
    if ( notional_at_start == true)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - notional;  
        cf_principal(:,1) = - notional;
    end
    if ( notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + notional;
        cf_principal(:,end) = notional;
    end
	
% ##############################################################################

% Type FRN: Calculate CF Values for all CF Periods with forward rates based on 
%           spot rate defined 
elseif ( strcmpi(type,'FRN') || strcmpi(type,'SWAP_FLOATING') || strcmpi(type,'CAP') || strcmpi(type,'FLOOR'))
    %cf_datesnum = cf_datesnum((cf_datesnum-valuation_date)>0);
    d1 = cf_datesnum(1:length(cf_datesnum)-1);
    d2 = cf_datesnum(2:length(cf_datesnum));
    notvec = zeros(1,length(d1));
    notvec(length(notvec)) = 1;
    cf_values = zeros(rows(tmp_rates),length(d1));
    cf_principal = zeros(rows(tmp_rates),length(d1));
	[tf dip dib] = timefactor (d1, d2, dcc);
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
            forward_rate_curve = get_forward_rate(tmp_nodes,tmp_rates, ...
                        fsd,fed-fsd,compounding_type,method_interpolation, ...
                        compounding_freq, basis_curve, valuation_date, ...
                        comp_type_curve, basis_curve, comp_freq_curve,floor_flag);
                        
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
                                'simple', 3, comp_freq_curve);
                    % calculate time factor from issue date to forward start date
                    tf_t_reset_date = timefactor (d1(1), d1(1) + fsd, dcc);
                    timing_adjustment = 1 + sigma.^2 .* (1 - df_t1_t2) .* tf_t_reset_date;
                else
                    fprintf('WARNING: rollout_structured_cashflows: no timing adjustment for in Arrears instrument can be calculated. No Volatility surface set. \n');
                    timing_adjustment = 1; % no timing adjustment required for in fine
                end
            end
            % adjust forward rate by timing adjustment
            forward_rate_curve = forward_rate_curve .* timing_adjustment;
            % calculate final floating cash flows
            if (strcmpi(type,'CAP') || strcmpi(type,'FLOOR'))
                % call function to calculate probability weighted forward rate
                X = instrument.strike;  % get from strike curve ?!?
                % calculate timefactor of forward start date
                tf_fsd = timefactor (valuation_date, valuation_date + fsd, dcc);
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
                forward_rate = (spread + forward_rate_curve) .* tf(ii);
            end
        elseif ( t1 < 0 && t2 > 0 )     % if last cf date is in the past, while
                                        % next is in future, use last reset rate
            if (strcmpi(type,'CAP') || strcmpi(type,'FLOOR'))
                if instrument.CapFlag == true
                    forward_rate = max(last_reset_rate - instrument.strike,0) .* tf(ii);
                else
                    forward_rate = max(instrument.strike - last_reset_rate,0) .* tf(ii);
                end
            else
                forward_rate = (spread + last_reset_rate) .* tf(ii);
            end
        else    % if both cf dates t1 and t2 lie in the past omit cash flow
            forward_rate = 0.0;
        end
        cf_values(:,ii) = forward_rate;
    end
    ret_values = cf_values .* notional;
    cf_interest = ret_values;
    % Add notional payments
    if ( notional_at_start == true)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - notional;  
        cf_principal(:,1) = - notional;
    end
    if ( notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + notional;
        cf_principal(:,end) = notional;
    end

% ##############################################################################

% Special floating types (capitalized, average, min, max) based on CMS rates
elseif ( strcmpi(type,'FRN_SPECIAL') || strcmpi(type,'FRN_CMS_SPECIAL'))
    % assume in fine -> fixing at forward start date -> use issue date as first
    cf_datesnum = [datenum(issue_date);datenum(cf_dates)];
    d1 = cf_datesnum(1:length(cf_datesnum)-1);
    d2 = cf_datesnum(2:length(cf_datesnum));
    notvec = zeros(1,length(d1));
    notvec(length(notvec)) = 1;
    cms_rates = zeros(rows(tmp_rates),length(d1));
    cms_tf    = zeros(rows(tmp_rates),length(d1));
    cf_principal = zeros(rows(tmp_rates),length(d1));
    [tf dip dib] = timefactor (d1, d2, dcc);
	% get instrument attributes
	sliding_term        = instrument.cms_sliding_term;
	underlying_term     = instrument.cms_term;
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
					'term',underlying_term, ...
					'notional_at_start',0);	
    for ii = 2 : 1 : length(d1)
        t1 = (d1(ii) - valuation_date);
        t2 = (d2(ii) - valuation_date);
        if ( t1 >= 0 && t2 >= t1 )    % for future cash flows use forward rates
        % (I) Calculate CMS x-let value with or without convexity adjustment and 
        %   distinguish between swaplets, caplets and floorlets 
            % payment date of FRN special is maturity date -> use date for CA
            %     ( will be incorporated in nominator of delta of Hagan)
            payment_date        = maturitydatenum - valuation_date;
            if ( instrument.in_arrears == 0)    % in fine
                fixing_start_date  = t1;
            else    % in arrears
                fixing_start_date  = t2;
            end
             % fixing_start_date
             % payment_date
            % set up underlying swap
            swap = swap.set('maturity_date',datestr(valuation_date + fixing_start_date + sliding_term), ...
                            'issue_date', datestr(valuation_date + fixing_start_date));
            % get volatility according to moneyness and term
            if ( regexpi(surface.moneyness_type,'-'))
                moneyness = 0.0; % surface with absolute moneyness
            else
                moneyness = 1.0; % surface with relative moneyness
            end
            tenor   = fixing_start_date; % days until foward start date
            sigma   = surface.getValue(value_type,tenor,sliding_term,moneyness);  
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
            final_rate = (spread + cms_rate + convex_adj) .* tf(ii);
            
        elseif ( t1 < 0 && t2 > 0 )     % if last cf date is in the past, while
                                        % next is in future, use last reset rate
            final_rate = (spread + last_reset_rate) .* tf(ii);
            
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
    cf_dates    = [issuevec;matvec];
	cf_datesnum = datenum(cf_dates);
    % update business date
	if ( enable_business_day_rule == true)
		cf_business_dates = datevec(busdate(cf_datesnum-1 + business_day_rule, ...
                                    business_day_direction));
		 cf_business_datesnum = datenum(cf_business_dates);   
	else
		cf_business_datesnum = cf_datesnum;
		cf_business_dates = cf_dates;
	end
                            
    % 2. adjust cms rates according to rate composition function
    if ( strcmpi(instrument.rate_composition,'capitalized'))
        tmp_rates = prod(1+cms_rates,2) - 1;
        % convert curve rates to instrument type
        tmp_rates = convert_curve_rates(valuation_date,cf_dates(:,end), ...
                                tmp_rates,'simple','annual',basis_curve, ...
                                compounding_type,compounding_freq,dcc);
        % annualize rate after simple capitalization was performed:
        if ( regexpi(compounding_type,'mp'))    % simple
            adj_rate = term_factor .* tmp_rates ./ (length(cms_rates));
        elseif ( regexpi(compounding_type,'cont')) % continuous
            adj_rate = log(1+tmp_rates .* term_factor) ./ (length(cms_rates));
        else    % discrete compounding
            adj_rate = (prod(1+cms_rates .* term_factor,2)) ...
                        ^(1/(term_factor .* length(cms_rates))) - 1;
        end
    else
        % annualize rate before operation is performed:
        if ( regexpi(compounding_type,'mp'))    % simple
            tmp_rates = cms_rates ./ cms_tf;
        elseif ( regexpi(compounding_type,'cont')) % continuous
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
    instr_adj_rate = (1 ./ discount_factor(datestr(valuation_date), ...
                            datestr(maturity_date), adj_rate, ...
                            compounding_type, dcc, compounding_freq)) - 1;                  
    ret_values  = instr_adj_rate .* notional;
    cf_interest = ret_values;
    % Add notional payments at end (start will be neglected)
    if ( notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values = ret_values + notional;
        cf_principal = notional;
    end

% ##############################################################################

% Type CMS and CMS Caps/Floors: Calculate CF Values for all CF Periods with cms rates
elseif ( strcmpi(type,'CMS_FLOATING') || strcmpi(type,'CAP_CMS') || strcmpi(type,'FLOOR_CMS'))
    % assume in fine -> fixing at forward start date -> use issue date as first
    cf_datesnum = [datenum(issue_date);datenum(cf_dates)]; 
    d1 = cf_datesnum(1:length(cf_datesnum)-1);
    d2 = cf_datesnum(2:length(cf_datesnum));
    notvec = zeros(1,length(d1));
    notvec(length(notvec)) = 1;
    cf_values = zeros(rows(tmp_rates),length(d1));
    cf_principal = zeros(rows(tmp_rates),length(d1));
    [tf dip dib] = timefactor (d1, d2, dcc);
	% get instrument data
	sliding_term        = instrument.cms_sliding_term;
	underlying_term     = instrument.cms_term;
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
					'term',underlying_term,'notional_at_end',0, ...
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
            swap = swap.set('maturity_date',datestr(valuation_date + fixing_start_date + sliding_term), ...
                            'issue_date', datestr(valuation_date + fixing_start_date));
							
            % get volatility according to moneyness and term
            if ( regexpi(surface.moneyness_type,'-'))
                moneyness = 0.0; % surface with absolute moneyness
            else
                moneyness = 1.0; % surface with relative moneyness
            end
            tenor   = fixing_start_date; % days until foward start date
            sigma   = surface.getValue(value_type,tenor,sliding_term,moneyness); 
				
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
            if (strcmpi(type,'CAP_CMS') || strcmpi(type,'FLOOR_CMS'))
                % call function to calculate probability weighted forward rate
                X = instrument.strike;  % TODO: get from strike curve ?!?
                % calculate timefactor of forward start date
                tf_fsd = timefactor (valuation_date, valuation_date + fixing_start_date, dcc);
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
                cms_rate = (spread + cms_rate + convex_adj) .* tf(ii);
            end
        elseif ( t1 < 0 && t2 > 0 )     % if last cf date is in the past, while
                                        % next is in future, use last reset rate
            if (strcmpi(type,'CAP_CMS') || strcmpi(type,'FLOOR_CMS'))
                if instrument.CapFlag == true
                    cms_rate = max(last_reset_rate - instrument.strike,0) .* tf(ii);
                else
                    cms_rate = max(instrument.strike - last_reset_rate,0) .* tf(ii);
                end
            else
                cms_rate = (spread + last_reset_rate) .* tf(ii);
            end
        else    % if both cf dates t1 and t2 lie in the past omit cash flow
            cms_rate = 0.0;
        end
        cf_values(:,ii) = cms_rate;
    end
    ret_values = cf_values .* notional;
    cf_interest = ret_values;
    % Add notional payments
    if ( notional_at_start == true)    % At notional payment at start
        ret_values(:,1) = ret_values(:,1) - notional;  
        cf_principal(:,1) = - notional;
    end
    if ( notional_at_end == true) % Add notional payment at end to cf vector:
        ret_values(:,end) = ret_values(:,end) + notional;
        cf_principal(:,end) = notional;
    end

% ##############################################################################
    
% Type ZCB: Zero Coupon Bond has notional cash flow at maturity date
elseif ( strcmp(type,'ZCB') == 1 )   
    ret_values = notional;
    cf_principal = notional;
    cf_interest = 0;
 
% ##############################################################################
   
% Type FAB: Calculate CF Values for all CF Periods for fixed amortizing bonds 
%           (annuity loans and amortizable loans)
elseif ( strcmp(type,'FAB') == 1 )
    % Cash flow rollout for 4 different cases:
	% annuity = total cash flows consisting of principal cash flows and 
	%           interest cash flows
	%
	% 1. FIXED_ANNUITY = true: constant cashflows CF = CF_interest_i + CF_principal_i
	%		1a) USE_ANNUITY_AMOUNT == true, ANNUITY_AMOUNT = XXX:
	%				annuity amount is given by attribute
	%				CF = annuity_amount --> calculate principal and interest CFs
	%		1b) USE_ANNUITY_AMOUNT == false:	
	%				annuity amount is calculation as function(notional, term, coupon rate)
	%				CF = f(not,rate,term) --> calculate principal and interest CFs
	%
	% 2. fixed FIXED_ANNUITY = false: constant principal cashflows, variable interest and notional CFs
	%							CF_i = CF_principal_fixed + CF_interest_i
	%		2a) USE_PRINCIPAL_PMT_FLAG == true, PRINCIPAL_PAYMENT = [xxx, yyy]
	%				principal payments are given by attribute (principal payment vector)
	%				CF_principal = [vector], calculate interest CFs for outstanding amount
	%		2b) USE_PRINCIPAL_PMT_FLAG == false:
	%				constant amortization rate is calculated as function(notional,number_payments)
	%				CF_principal_i = constant, total CF and CF_interest variable
	%
	%  --------------------------------------------------------------------------------------------	
	%  (1) FIXED_ANNUITY = true
	%										  |
	%		a) USE_ANNUITY_AMOUNT == true	  |	b) 	USE_ANNUITY_AMOUNT == false
	%										  |
	%			CF_TOTAL_t = ANNUITY_AMOUNT = |			CF_TOTAL_t = f(notional,rate,term) = const.
	%							const.		  |	
	%  --------------------------------------------------------------------------------------------
	%										
	%  (2) FIXED_ANNUITY = false
	%										  |
	%		a) USE_PRINCIPAL_PMT_FLAG == true |	b)	USE_PRINCIPAL_PMT_FLAG == false
	%										  |
	%			PRINCIPAL_PAYMENT = [vector]  |			PRINCIPAL_PAYMENT = f(notional,rate,term) = const.
	%										  |
	%			CF_TOTAL_t = PRINCIPAL_PAYMENT|			CF_TOTAL_t = PRINCIPAL_PAYMENT + CF_interest
	%						+ CF_interest	  |	
	%  --------------------------------------------------------------------------------------------
	%
    % fixed annuity: fixed total payments 
    if ( fixed_annuity_flag == 1)
        if ( use_annuity_amount == 0)   % calculate annuity from coupon rate and notional
            number_payments = rows(cf_dates) -1;
            m = comp_freq;
            total_term = number_payments / m;  % total term of annuity in years
            % Discrete compounding only with act/365 day count convention
            % TODO: implement simple and continuous compounding for annuity
            %       calculation
            d1 = cf_datesnum(1:length(cf_datesnum)-1);
            d2 = cf_datesnum(2:length(cf_datesnum));
            cf_interest = zeros(1,number_payments);
            amount_outstanding_vec = zeros(1,number_payments);
            if ( coupon_rate == 0) % special treatment: pay back notional at maturity
              rate = 0.0;
              amount_outstanding_vec(1) = notional;
              cf_principal = zeros(1,number_payments);
              cf_principal(end) = notional;    % pay back notional at maturity
              ret_values = cf_principal;
            else
              if ( in_arrears_flag == 1)  % in arrears payments (at end of period)
                rate = (notional * (( 1 + coupon_rate )^total_term * coupon_rate ) ...
                                    / (( 1 + coupon_rate  )^total_term - 1) ) ...
                                    / (m + coupon_rate / 2 * ( m + 1 ));
              else                        % in advance payments
                rate = (notional * (( 1 + coupon_rate )^total_term * coupon_rate ) ...
                                    / (( 1 + coupon_rate )^total_term - 1) ) ...
                                    / (m + coupon_rate / 2 * ( m - 1 ));
              end
              ret_values = ones(1,number_payments) .* rate;

              % calculate principal and interest cf
              amount_outstanding_vec(1) = notional;
			  % get interest rates at nodes
			  rate_interest = ((1 ./ discount_factor (d1, d2, ...
                                      coupon_rate, compounding_type, dcc, ...
                                      compounding_freq)) - 1)';
									  
              % cashflows of first date
              cf_interest(1) = notional.* rate_interest(1);
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
            number_payments = rows(cf_dates) -1;
            m = comp_freq;
            d1 = cf_datesnum(1:length(cf_datesnum)-1);
            d2 = cf_datesnum(2:length(cf_datesnum));
			cf_interest = zeros(1,number_payments);
            rate_interest = ((1 ./ discount_factor (d1, d2, ...
                                      coupon_rate, compounding_type, dcc, ...
                                      compounding_freq)) - 1)';
            amount_outstanding = notional;
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
        if ( use_principal_pmt_flag == 1)
            number_payments = rows(cf_dates) -1;
            m = comp_freq;
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
            d1 = cf_datesnum(1:length(cf_datesnum)-1);
            d2 = cf_datesnum(2:length(cf_datesnum));
            %cf_interest = zeros(1,number_payments);
			amount_outstanding_vec = notional - cumsum(princ_pmt);
			cf_interest = amount_outstanding_vec .* ((1 ./ ...
                            discount_factor (d1, d2, coupon_rate, ...
                                compounding_type, dcc, compounding_freq))' - 1);

            cf_principal = princ_pmt .* ones(1,number_payments);
            % add outstanding amount at maturity to principal cashflows
            cf_principal(end) = amount_outstanding_vec(end);
            ret_values = cf_principal + cf_interest;
        % fixed amortization rate, total amortization of bond until maturity
        else 
            number_payments = rows(cf_dates) -1;
            m = comp_freq;
            total_term = number_payments / m;   % total term of annuity in years
            amortization_rate = notional / number_payments;  
            cf_datesnum = datenum(cf_dates);
            d1 = cf_datesnum(1:length(cf_datesnum)-1);
            d2 = cf_datesnum(2:length(cf_datesnum));
            cf_values = zeros(1,number_payments);
			rate_interest = ((1 ./ discount_factor (d1, d2, ...
                                      coupon_rate, compounding_type, dcc, ...
                                      compounding_freq)) - 1)';
            amount_outstanding = notional;
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
            pp_curve_interp = method_interpolation;
            pp_curve_nodes = tmp_nodes;
            pp_curve_values = tmp_rates;
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
        prepayment_factor = pp.interpolate(coupon_rate,abs_ir_shock);
                
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
                    prepayment_rate, comp_type_curve, basis_curve, comp_freq_curve)) - 1);  

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
                cf_datesnum = datenum(cf_dates);
                original_payments = length(cf_dates);
                number_payments = length(cf_datesnum);
                d1 = cf_datesnum(1:length(cf_datesnum)-1);
                d2 = cf_datesnum(2:length(cf_datesnum));
                % preallocate memory
                amount_outstanding_vec = zeros(rows(prepayment_factor),number_payments) ...
                                                                .+ out_balance;              
                cf_interest_pp = zeros(rows(prepayment_factor),number_payments);
                cf_principal_pp = zeros(rows(prepayment_factor),number_payments); 
                cf_annuity = zeros(rows(prepayment_factor),number_payments);                
                issue_date = datenum(instrument.issue_date);
                % calculate all principal and interest cash flows including
                % prepayment cashflows. use future cash flows only
                for ii = 1 : 1 : number_payments
                    if ( cf_datesnum(ii) > valuation_date)
                        eff_notional = amount_outstanding_vec(:,ii-1);
                         % get prepayment rate at days to cashflow
                        tmp_timestep = d2(ii-1) - issue_date;
                        % extract PSA factor from prepayment procedure               
                        prepayment_rate = interpolate_curve(pp_curve_nodes, ...
                                        pp_curve_values,tmp_timestep,pp_curve_interp);
                        prepayment_rate = prepayment_rate .* prepayment_factor;
                        % convert annualized prepayment rate
                        lambda = ((1 ./ discount_factor (d1(ii-1), d2(ii-1), ...
                                            prepayment_rate, comp_type_curve, ...
                                            basis_curve, comp_freq_curve)) - 1);
                        % calculate interest cashflow
                        [tf dip dib] = timefactor (d1(ii-1), d2(ii-1), dcc);
                        eff_rate = coupon_rate .* tf; 
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
end
% ##############################################################################
% ##############################################################################

%-------------------------------------------------------------------------------

% special treatment for term == 0 (means all cash flows summed up at Maturity)
if ( term == 0 )
    cf_dates = [issuevec;cf_dates(end,:)];
    cf_business_dates = [issuevec;cf_business_dates(end,:)];
    ret_values = sum(ret_values,2);
    cf_interest = sum(cf_interest,2);
    cf_principal = sum(cf_principal,2);
end
% end special treatment

ret_dates_tmp = cf_business_datesnum;
ret_dates = ret_dates_tmp(2:rows(cf_business_dates));
if enable_business_day_rule == 1
    pay_dates_num = cf_business_datesnum;
else
    pay_dates_num = cf_datesnum;
end
ret_dates_all_cfs = pay_dates_num - valuation_date;
pay_dates_num(1,:)=[];
ret_dates = pay_dates_num' - valuation_date;
ret_dates_tmp = ret_dates;              % store all cf dates for later use
ret_dates = ret_dates(ret_dates>0);

ret_values = ret_values(:,(end-length(ret_dates)+1):end);
ret_interest_values = cf_interest(:,(end-length(ret_dates)+1):end);
ret_principal_values = cf_principal(:,(end-length(ret_dates)+1):end);
%-------------------------------------------------------------------------------
% #################   Calculation of accrued interests   #######################   
%
% calculate time in days from last coupon date (zero if valuation_date == coupon_date)
ret_date_last_coupon = ret_dates_all_cfs(ret_dates_all_cfs<0);

% distinguish three different cases:
% A) issue_date.......first_cf_date....valuation_date...2nd_cf_date.....mat_date
% B) valuation_date...issue_date......first_cf_date.....2nd_cf_date.....mat_date
% C) issue_date.......valuation_date..firist_cf_date.....2nd_cf_date.....mat_date

% adjustment to accrued interest required if calculated
% from next cashflow (background: next cashflow is adjusted for
% for actual days in period (in e.g. act/365 dcc), so the
% CF has to be adjusted back by 355/366 in leap year to prevent
% double counting of one day
% therefore a generic approach was chosen where the time factor is always 
% adjusted by actual days in year / days in leap year

if length(ret_date_last_coupon) > 0                 % CASE A
    last_coupon_date = ret_date_last_coupon(end);
    ret_date_last_coupon = -ret_date_last_coupon(end);  
    [tf dip dib] = timefactor (valuation_date - ret_date_last_coupon, ...
                            valuation_date, dcc);
    % correct next coupon payment if leap year
    % adjustment from 1 to 365 days in base for act/act
    if dib == 1
        dib = 365;
    end    
    days_from_last_coupon = ret_date_last_coupon;
    days_to_next_coupon = ret_dates(1);
    adj_factor = dib / (days_from_last_coupon + days_to_next_coupon);
    if ~( term == 365)
		adj_factor = adj_factor .* term / 12;
    end
    tf = tf * adj_factor;
else
    % last coupon date is first coupon date for Cases B and C:
    last_coupon_date = ret_dates(1);
    % if valuation date before issue date -> tf = 0
    if ( valuation_date <= issuedatenum )    % CASE B
        tf = 0;
        
    % valuation date after issue date, but before first cf payment date
    else                                            % CASE C
        [tf dip dib] = timefactor (issue_date, valuation_date, dcc);
        days_from_last_coupon = valuation_date - issuedatenum;
        days_to_next_coupon = ret_dates(1) ; 
        adj_factor = dib / (days_from_last_coupon + days_to_next_coupon);
        if ~( term == 365)
        adj_factor = adj_factor * term / 12;
        end
        tf = tf .* adj_factor;
    end
end
% value of next coupon -> accrued interest is pro-rata share of next coupon
ret_value_next_coupon = ret_interest_values(:,1);

% scale tf according to term:
if ~( term == 365 || term == 0)
    tf = tf * 12 / term;
% term = maturity --> special calculation for accrued int
elseif ( term == 0) 
    if ( valuation_date <= issuedatenum )    % CASE B
        tf = 0;
    else                                            % CASE A/C
        tf_id_md = timefactor(issue_date, maturity_date, dcc);
        tf_id_vd = timefactor(issue_date, valuation_date, dcc);
        tf = tf_id_vd ./ tf_id_md;
    end
end

% TODO: why is there a vector of accrued_interest with length of
%       scenario values for FRB in case C?
accrued_interest = ret_value_next_coupon .* tf;
accrued_interest = accrued_interest(1);

%-------------------------------------------------------------------------------

end



%-------------------------------------------------------------------------------
%                           Helper Functions
%-------------------------------------------------------------------------------
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

%!test
%! bond_struct=struct();
%! bond_struct.sub_type                 = 'FRB';
%! bond_struct.issue_date               = '21-Sep-2010';
%! bond_struct.maturity_date            = '17-Sep-2022';
%! bond_struct.compounding_type         = 'simple';
%! bond_struct.compounding_freq         = 1  ;
%! bond_struct.term                     = 12   ;
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
%! [ret_dates ret_values ret_int ret_princ accrued_interest] = rollout_structured_cashflows('31-Dec-2015','base',bond_struct);
%! assert(ret_values,ret_int + ret_princ,sqrt(eps))
%! assert(ret_dates,[90,274,455,639,820,1004,1185,1369,1551,1735,1916,2100],0.000000001);
%! assert(ret_values,[1.0595890411,1.0712328767,1.0537671233,1.0712328767,1.0537671233,1.0712328767,1.0537671233,1.0712328767,1.0595890411,1.0712328767,1.0537671233,101.0712328767],0.000000001);
%! assert(accrued_interest,0.535616438356163,0.0000001);

%!test
%! bond_struct=struct();
%! bond_struct.id						= 'TestFAB';
%! bond_struct.sub_type                 = 'FAB';
%! bond_struct.issue_date               = '12-Mar-2016';
%! bond_struct.maturity_date            = '12-Feb-2020';
%! bond_struct.compounding_type         = 'simple';
%! bond_struct.compounding_freq         = 1  ;
%! bond_struct.term                     = 3   ;
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
%! cap_float = cap_float.set('maturity_date','28-Jun-2026','notional',100,'compounding_type','simple','issue_date','30-Jun-2016','term',365,'notional_at_end',1,'convex_adj',false);
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
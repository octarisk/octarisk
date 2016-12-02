function s = rollout (bond, value_type, arg1, arg2, arg3, arg4)
  s = bond;

  if ( strcmpi(s.sub_type,'FRN') || strcmpi(s.sub_type,'SWAP_FLOATING'))
    if ( nargin < 3 )
        error ('rollout for sub_type FRN or SWAP_FLOATING: expecting reference curve object');
    elseif ( nargin == 3)
        tmp_curve_object = arg1;
        valuation_date = datestr(today);
    elseif ( nargin == 4)
        tmp_curve_object = arg1;
        valuation_date = datestr(arg2);
    elseif ( nargin == 5)
        tmp_curve_object = arg1;
        valuation_date = datestr(arg2);
        vola_surface = arg3;
        vola_riskfactor = Riskfactor();
    elseif ( nargin == 6)
        tmp_curve_object = arg1;
        valuation_date = datestr(arg2);
        vola_surface = arg3;
        vola_riskfactor = arg4;
    end
    
    if ischar(valuation_date)
        valuation_date = datenum(valuation_date);
    end

    % call function for generating CF dates and values and accrued_interest
    if ( nargin <= 4)
        % no vola surface set
        [ret_dates ret_values ret_int ret_principal accr_int last_coupon_date ] = rollout_structured_cashflows( ...
                valuation_date,value_type,s,tmp_curve_object);
    elseif ( nargin > 4)
        [ret_dates ret_values ret_int ret_principal accr_int last_coupon_date ] = rollout_structured_cashflows( ...
                valuation_date,value_type,s,tmp_curve_object, vola_surface);
    end
                                
  % Fixed Amortizing Bonds                              
  elseif ( strcmpi(s.sub_type,'FAB'))
    % arg1: ref_curve (PSA prepayment curve)
    % arg2: valuation date
    % arg3: PSA factor surface
    % arg4: interest rate curve for abs ir shock value extraction
    if ( nargin == 3)
        psa_curve = Curve();
        valuation_date = arg1;
        psa_factor_surface = [];
        ir_shock_curve = [];
    elseif ( nargin == 4)
        psa_curve = arg2;
        valuation_date = datestr(arg1);
        psa_factor_surface = [];
        ir_shock_curve = [];
    elseif ( nargin == 5)
        psa_curve = arg2;
        valuation_date = datestr(arg1);
        psa_factor_surface = arg3;
        ir_shock_curve = [];
    elseif ( nargin == 6)
        psa_curve = arg2;
        valuation_date = datestr(arg1);
        psa_factor_surface = arg3;
        ir_shock_curve = arg4;
    end
    
    if ischar(valuation_date)
        valuation_date = datenum(valuation_date);
    end

    % call function for generating CF dates and values and accrued_interest
    [ret_dates ret_values ret_int ret_principal accr_int last_coupon_date ] = rollout_structured_cashflows( ...
                                valuation_date,value_type,s,psa_curve, ...
                                psa_factor_surface,ir_shock_curve);
                                
  % type CASHFLOW -> duplicate all base cashflows
  elseif ( strcmpi(s.sub_type,'CASHFLOW') )
    ret_dates  = s.get('cf_dates');
    ret_values = s.get('cf_values');
    accr_int = 0.0;
    last_coupon_date = 0.0;
  
  % type CMS Floating Leg or FRN Special (capitalized, average, min, max CMS rates)
  elseif ( strcmpi(s.sub_type,'CMS_FLOATING') || strcmpi(s.sub_type,'FRN_SPECIAL'))
    if ( nargin < 5 )
        error ('rollout for sub_type CMS_FLOATING or FRN_SPECIAL: expecting valuation_date,curve,vola,vola risk factor objects');
    end
    valuation_date  = arg1;
    curve_object    = arg2;
    vola_surface    = arg3;
  
    % call function for generating CF dates and values and accrued_interest
    [ret_dates ret_values ] = rollout_structured_cashflows(valuation_date, ...
                            value_type, s, curve_object, vola_surface);
    accr_int = 0.0;
    last_coupon_date = 0.0;
    
  % type stochastic -> get cash flows from underlying surface and risk factor quantiles
  elseif ( strcmpi(s.sub_type,'STOCHASTICCF') )
    % arg1: riskfactor random variable -> cashflows drawn from surface
    % arg2: surface containing all cashflows per scenario and cf_date
    % calculate cash flow values from risk factor and surface
    rvec = arg1.getValue(value_type); 
    % distinguish between uniform and normal distributed risk factor values
    if ( strcmpi(s.stochastic_rf_type,'normal') )
        rvec = normcdf(rvec);   % convert normal(0,1) distributed random number
                                % to [0,1] uniform distributed number
    elseif ( strcmpi(s.stochastic_rf_type,'t') )
        df = s.t_degree_freedom; % degree of freedom for t distributed risk factor
        rvec = tcdf(rvec,df);   % convert t(df) distributed random number
                                % to [0,1] uniform distributed number
    end
    % uniform distribution of riskfactor -> do nothing
       
    % get all cash flow values from risk factor and underlying matrix surface
    ret_dates = s.get('cf_dates');
    ret_values = zeros(length(rvec),length(ret_dates));
    for ii = 1:1:length(ret_dates)
      tmp_cf_date = ret_dates(ii);
      tmp_cf_values = arg2.interpolate(tmp_cf_date,rvec);
      ret_values(:,ii) = tmp_cf_values;
    end
    accr_int = 0.0;
    last_coupon_date = 0.0;
    
  % all other bond types (like FRB etc.)
  else  
    if ( nargin < 3)
        valuation_date = datestr(today);
    elseif ( nargin == 3)
        valuation_date = datestr(arg1);
    end
    % call function for rolling out cashflows
    [ret_dates ret_values ret_int ret_principal accr_int last_coupon_date] = ...
                    rollout_structured_cashflows(valuation_date,value_type,s);
  end
  
  % store outstanding balance for FAB only (sum of all remaining principal cf

  if ( strcmp(s.sub_type,'FAB'))
      if (s.use_outstanding_balance == 0)
        s = s.set('outstanding_balance',sum(ret_principal,2));
      end
  end
  % set property value pairs to object
  s = s.set('cf_dates',ret_dates);
  s = s.set('accrued_interest',accr_int);
  s = s.set('last_coupon_date',last_coupon_date);
  if ( strcmp(value_type,'stress'))
      s = s.set('cf_values_stress',ret_values);
  elseif ( strcmp(value_type,'base')) 
      s = s.set('cf_values',ret_values);
  else
      s = s.set('cf_values_mc',ret_values,'timestep_mc_cf',value_type);
  end
   
end



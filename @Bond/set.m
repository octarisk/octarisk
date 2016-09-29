function s = set (bond, varargin)
  s = bond;
  if (length (varargin) < 2 || rem (length (varargin), 2) ~= 0)
    error ('set: expecting property/value pairs');
  end
  while (length (varargin) > 1)
    prop = varargin{1};
    prop = lower(prop);
    val = varargin{2};
    varargin(1:2) = [];
    % ====================== set spread over yield ======================
    if (ischar (prop) && strcmp (prop, 'soy'))
      if (isvector (val) && isreal (val))
        s.soy = val;
      else
        error ('set: expecting the value to be a real vector');
      end
    % ====================== set accrued_interest ======================  
     elseif (ischar (prop) && strcmp (prop, 'accrued_interest'))   
      if (isreal (val))
        s.accrued_interest = val;
      else
        error ('set: expecting accrued_interest to be a real number');
      end 
    % ====================== set last_coupon_date ======================  
     elseif (ischar (prop) && strcmp (prop, 'last_coupon_date'))   
      if (isreal (val))
        s.last_coupon_date = val;
      else
        error ('set: expecting last_coupon_date to be a real number');
      end       
    % ====================== set ir_shock ======================
    elseif (ischar (prop) && strcmp (prop, 'ir_shock'))   
      if (isreal (val))
        s.ir_shock = val;
      else
        error ('set: expecting ir_shock to be a real number');
      end
    % ====================== set convexity ======================
    elseif (ischar (prop) && strcmp (prop, 'convexity'))   
      if (isreal (val))
        s.convexity = val;
      else
        error ('set: expecting convexity to be a real number');
      end
    % ====================== set dollar_convexity ======================
    elseif (ischar (prop) && strcmp (prop, 'dollar_convexity'))   
      if (isreal (val))
        s.dollar_convexity = val;
      else
        error ('set: expecting dollar_convexity to be a real number');
      end
    % ====================== set rates_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'cf_values_mc'))   
      if (isreal (val))
        [mc_rows mc_cols mc_stack] = size(s.cf_values_mc);
        if ( mc_cols > 0 || mc_rows > 0) % appending vector to existing vector
            if ( length(val) == length(s.cf_values_mc(:,:,mc_stack)))
                s.cf_values_mc(:,:,mc_stack + 1) = val;
            else
                error('set: expecting length of new input vector to equal length of already existing rate vector');
            end
        else    % setting vector
            s.cf_values_mc(:,:,1) = val;
        end  
        
      else
        error ('set: expecting the mc cf values to be real ');
      end 
    % ====================== set cf_values_stress ======================
    elseif (ischar (prop) && strcmp (prop, 'cf_values_stress'))   
      if (isreal (val))
        s.cf_values_stress = val;
      else
        error ('set: expecting the cf stress value to be real ');
      end
    % ====================== set cf_values ======================
    elseif (ischar (prop) && strcmp (prop, 'cf_values'))   
      if (isvector (val) && isreal (val))
        s.cf_values = val;
      else
        error ('set: expecting the base values to be a real vector');
      end
    % ====================== set cf_dates ======================
    elseif (ischar (prop) && strcmp (prop, 'cf_dates'))   
      if (isvector (val) && isreal (val))
        s.cf_dates = val;
      else
        error ('set: expecting cf_dates to be a real vector');
      end 
    % ====================== set timestep_mc_cf: appending or setting timestep vector ======================
    elseif (ischar (prop) && strcmp (prop, 'timestep_mc_cf'))   
      if (iscell(val) && length(val) == 1)
        tmp_cell = s.timestep_mc_cf;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            s.timestep_mc_cf{length(tmp_cell) + 1} = char(val);
        else    % setting vector
            s.timestep_mc_cf = val;
        end      
      elseif (iscell(val) && length(val) > 1) % replacing timestep_mc_cf cell vector with new vector
        s.timestep_mc_cf = val;
      elseif ( ischar(val) )
        tmp_cell = s.timestep_mc_cf;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            s.timestep_mc_cf{length(tmp_cell) + 1} = char(val);
        else    % setting vector
            s.timestep_mc_cf = cellstr(val);
        end 
      else
        error ('set: expecting the cell value to be a cell vector');
      end   
    % ====================== set value_mc: if isvector -> append to existing vector / matrix, if ismatrix -> replace existing value
    elseif (ischar (prop) && strcmp (prop, 'value_mc'))   
      if (isvector (val) && isreal (val))
        tmp_vector = [s.value_mc];
        if ( rows(tmp_vector) > 0 ) % appending vector to existing vector
            if ( rows(tmp_vector) == rows(val) )
                s.value_mc = [tmp_vector, val];
            else
                error ('set: expecting equal number of rows')
            end
        else    % setting vector
            s.value_mc = val;
        end      
      elseif (ismatrix(val) && isreal(val)) % replacing value_mc matrix with new matrix
        s.value_mc = val;
      else
        if ( isempty(val))
            s.value_mc = [];
        else
            error ('set: expecting the value to be a real vector');
        end
      end
    % ====================== set timestep_mc: appending or setting timestep vector ======================
    elseif (ischar (prop) && strcmp (prop, 'timestep_mc'))   
      if (iscell(val) && length(val) == 1)
        tmp_cell = s.timestep_mc;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            s.timestep_mc{length(tmp_cell) + 1} = char(val);
        else    % setting vector
            s.timestep_mc = val;
        end      
      elseif (iscell(val) && length(val) > 1) % replacing timestep_mc cell vector with new vector
        s.timestep_mc = val;
      elseif ( ischar(val) )
        tmp_cell = s.timestep_mc;
        if ( length(tmp_cell) > 0 ) % appending vector to existing vector
            s.timestep_mc{length(tmp_cell) + 1} = char(val);
        else    % setting vector
            s.timestep_mc = cellstr(val);
        end 
      else
        error ('set: expecting the cell value to be a cell vector');
      end  
    % ====================== set value_stress ======================
    elseif (ischar (prop) && strcmp (prop, 'value_stress'))   
      if (isvector (val) && isreal (val))
        s.value_stress = val;
      else
        if ( isempty(val))
            s.value_stress = [];
        else
            error ('set: expecting value_stress to be a real vector');
        end
      end
    % ====================== set value_base ======================
    elseif (ischar (prop) && strcmp (prop, 'value_base'))   
      if (isreal (val) && isnumeric(val))
        s.value_base = val;
      else
        error ('set: expecting value_base to be a real numeric vector');
      end 
    % ====================== set name ======================
    elseif (ischar (prop) && strcmp (prop, 'name'))   
      if (ischar (val) )
        s.name = strtrim(val);
      else
        error ('set: expecting name to be a char');
      end
    % ====================== set id ======================
    elseif (ischar (prop) && strcmp (prop, 'id'))   
      if (ischar(val))
        s.id = strtrim(val);
      else
        error ('set: expecting id to be a char');
      end
    % ====================== set prepayment_source ======================
    elseif (ischar (prop) && strcmp (prop, 'prepayment_source'))   
      if (ischar(val))
        s.prepayment_source = strtrim(val);
      else
        error ('set: expecting prepayment_source to be a char');
      end
    % ====================== set prepayment_type ======================
    elseif (ischar (prop) && strcmp (prop, 'prepayment_type'))   
      if (ischar(val))
        s.prepayment_type = strtrim(val);
      else
        error ('set: expecting prepayment_type to be a char');
      end
    % ====================== set issue_date ======================
    elseif (ischar (prop) && strcmp (prop, 'issue_date'))   
      if (ischar (val))
        s.issue_date = datestr(strtrim(val),1);
      elseif ( isnumeric(val))
        s.issue_date = datestr(val);
      else
        error ('set: expecting issue_date to be a char or integer');
      end  
    % ====================== set maturity_date ======================
    elseif (ischar (prop) && strcmp (prop, 'maturity_date'))   
      if (ischar (val))
        s.maturity_date = datestr(strtrim(val),1);
      elseif ( isnumeric(val))
        s.maturity_date = datestr(val);
      else
        error ('set: expecting maturity_date to be a char or integer');
      end 
    % ====================== set spread_curve  ======================
    elseif (ischar (prop) && strcmp (prop, 'spread_curve'))   
      if (ischar (val))
        s.spread_curve = strtrim(val);
      else
        error ('set: expecting spread_curve to be a char');
      end 
      
    % ====================== set reference_curve  ======================
    elseif (ischar (prop) && strcmp (prop, 'reference_curve'))   
      if (ischar (val))
        s.reference_curve = strtrim(val);
      else
        error ('set: expecting reference_curve to be a char');
      end  
    % ====================== set discount_curve  ======================
    elseif (ischar (prop) && strcmp (prop, 'discount_curve'))   
      if (ischar (val))
        s.discount_curve = strtrim(val);
      else
        error ('set: expecting discount_curve to be a char');
      end 
    % ====================== set prepayment_curve  ======================
    elseif (ischar (prop) && strcmp (prop, 'prepayment_curve'))   
      if (ischar (val))
        s.prepayment_curve = strtrim(val);
      else
        error ('set: expecting prepayment_curve to be a char');
      end 
    % ====================== set coupon_generation_method  ====================
    elseif (ischar (prop) && strcmp (prop, 'coupon_generation_method'))   
      if (ischar (val))
        s.coupon_generation_method = strtrim(val);
      else
        error ('set: expecting coupon_generation_method to be a char');
      end 
    % ====================== set term ======================
    elseif (ischar (prop) && strcmp (prop, 'term'))   
      if (isnumeric (val) && isreal (val))
        s.term = val;
      else
        error ('set: expecting term to be a real number');
      end 
    % ====================== set outstanding_balance ======================
    elseif (ischar (prop) && strcmp (prop, 'outstanding_balance'))   
      if (isnumeric (val) && isreal (val))
        s.outstanding_balance = val;
      else
        error ('set: expecting outstanding_balance to be a real number');
      end  
    % ====================== set prepayment_rate ======================
    elseif (ischar (prop) && strcmp (prop, 'prepayment_rate'))   
      if (isnumeric (val) && isreal (val))
        s.prepayment_rate = val;
      else
        error ('set: expecting prepayment_rate to be a real number');
      end   
    % ====================== set ytm ======================
    elseif (ischar (prop) && strcmp (prop, 'ytm'))   
      if (isnumeric (val) && isreal (val))
        s.ytm = val;
      else
        error ('set: expecting ytm to be a real number');
      end   
    % ====================== set compounding_freq  ======================
    elseif (ischar (prop) && strcmp (prop, 'compounding_freq'))   
      if (isnumeric (val) && isreal(val))
        s.compounding_freq  = val;
      elseif (ischar(val))
        s.compounding_freq  = val;
      else
        error ('set: expecting compounding_freq to be a real number or char');
      end       
    % ====================== set day_count_convention ======================
    elseif (ischar (prop) && strcmp (prop, 'day_count_convention'))   
      if (ischar (val))
        s.day_count_convention = strtrim(val);
      else
        error ('set: expecting day_count_convention to be a char');
      end 
    % ====================== set compounding_type ======================
    elseif (ischar (prop) && strcmp (prop, 'compounding_type'))   
      if (ischar (val))
        s.compounding_type = strtrim(val);
      else
        error ('set: expecting compounding_type to be a char');
      end 
    % ====================== set sub_type ======================
    elseif (ischar (prop) && strcmp (prop, 'sub_type'))   
      if (ischar (val))
        s.sub_type = strtrim(val);
      else
        error ('set: expecting sub_type to be a char');
      end   
    % ====================== set valuation_date ======================
    elseif (ischar (prop) && strcmp (prop, 'valuation_date'))   
      if (ischar (val))
        s.valuation_date = datestr(strtrim(val),1);
      elseif ( isnumeric(val))
        s.valuation_date = datestr(val);
      else
        error ('set: expecting valuation_date to be a char or integer');
      end 
    % ====================== set asset_class ======================
    elseif (ischar (prop) && strcmp (prop, 'asset_class'))   
      if (ischar (val))
        s.asset_class = strtrim(val);
      else
        error ('set: expecting asset_class to be a char');
      end 
    % ====================== set currency ======================
    elseif (ischar (prop) && strcmp (prop, 'currency'))   
      if (ischar (val))
        s.currency = strtrim(val);
      else
        error ('set: expecting currency to be a char');
      end 
    % ====================== set description ======================
    elseif (ischar (prop) && strcmp (prop, 'description'))   
      if (ischar (val))
        s.description = strtrim(val);
      else
        error ('set: expecting description to be a char');
      end 
    % ====================== set notional ======================
    elseif (ischar (prop) && strcmp (prop, 'notional'))   
      if (isnumeric (val) && isreal (val))
        s.notional = val;
      else
        error ('set: expecting notional to be a real number');
      end 
    % ====================== set coupon_rate ======================
    elseif (ischar (prop) && strcmp (prop, 'coupon_rate'))   
      if (isnumeric (val) && isreal (val))
        s.coupon_rate = val;
      else
        error ('set: expecting coupon_rate to be a real number');
      end 
    % ====================== set business_day_rule ======================
    elseif (ischar (prop) && strcmp (prop, 'business_day_rule'))   
      if (isnumeric (val) && isreal (val))
        s.business_day_rule = val;
      else
        error ('set: expecting business_day_rule to be a real number');
      end 
    % ====================== set business_day_direction ======================
    elseif (ischar (prop) && strcmp (prop, 'business_day_direction'))   
      if (isnumeric (val) && isreal (val))
        s.business_day_direction = val;
      else
        error ('set: expecting business_day_direction to be a real number');
      end 
    % ====================== set enable_business_day_rule ======================
    elseif (ischar (prop) && strcmp (prop, 'enable_business_day_rule'))   
      if (isnumeric (val) && isreal (val))
        s.enable_business_day_rule = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.enable_business_day_rule = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.enable_business_day_rule = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting enable_business_day_rule to false.',val);
            s.enable_business_day_rule = logical(0);
        end
      elseif ( islogical(val))
        s.enable_business_day_rule = val;
      else
        error ('set: expecting enable_business_day_rule to be a real number or true/false');
      end 
    % ====================== set prepayment_flag ======================
    elseif (ischar (prop) && strcmp (prop, 'prepayment_flag'))   
      if (isnumeric (val) && isreal (val))
        s.prepayment_flag = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.prepayment_flag = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.prepayment_flag = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting prepayment_flag to false.',val);
            s.prepayment_flag = logical(0);
        end
      elseif ( islogical(val))
        s.prepayment_flag = val;
      else
        error ('set: expecting prepayment_flag to be a real number or true/false');
      end
    % ====================== set clean_value_base ======================
    elseif (ischar (prop) && strcmp (prop, 'clean_value_base'))   
      if (isnumeric (val) && isreal (val))
        s.clean_value_base = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.clean_value_base = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.clean_value_base = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting clean_value_base to false.',val);
            s.clean_value_base = logical(0);
        end
      else
        error ('set: expecting clean_value_base to be a real number or true/false');
      end   
    % ====================== set spread ======================
    elseif (ischar (prop) && strcmp (prop, 'spread'))   
      if (isnumeric (val) && isreal (val))
        s.spread = val;
      else
        error ('set: expecting spread to be a real number');
      end 
    % ====================== set principal_payment ======================
    elseif (ischar (prop) && strcmp (prop, 'principal_payment'))   
      if (isnumeric (val) && isreal (val))
        s.principal_payment = val;
      else
        error ('set: expecting principal_payment to be a real number');
      end       
    % ====================== set psa_factor_term ======================
    elseif (ischar (prop) && strcmp (prop, 'psa_factor_term'))   
      if (isnumeric (val) && isreal (val))
        s.psa_factor_term = val;
      else
        error ('set: expecting psa_factor_term to be a real number');
      end 
    % ====================== set use_outstanding_balance ======================
    elseif (ischar (prop) && strcmp (prop, 'use_outstanding_balance'))   
      if (isnumeric (val) && isreal (val))
        s.use_outstanding_balance = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.use_outstanding_balance = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.use_outstanding_balance = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting use_outstanding_balance to false.',val);
            s.use_outstanding_balance = logical(0);
        end
      elseif ( islogical(val))
        s.use_outstanding_balance = val;    
      else
        error ('set: expecting use_outstanding_balance to be a real number');
      end   
    % ====================== set long_first_period ======================
    elseif (ischar (prop) && strcmp (prop, 'long_first_period'))   
      if (isnumeric (val) && isreal (val))
        s.long_first_period = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.long_first_period = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.long_first_period = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting long_first_period to false.',val);
            s.long_first_period = logical(0);
        end
      elseif ( islogical(val))
        s.long_first_period = val;    
      else
        error ('set: expecting long_first_period to be a real number');
      end 
    % ====================== set use_principal_pmt ======================
    elseif (ischar (prop) && strcmp (prop, 'use_principal_pmt'))   
      if (isnumeric (val) && isreal (val))
        s.use_principal_pmt = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.use_principal_pmt = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.use_principal_pmt = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting use_principal_pmt to false.',val);
            s.use_principal_pmt = logical(0);
        end
      elseif ( islogical(val))
        s.use_principal_pmt = val;    
      else
        error ('set: expecting use_principal_pmt to be a real number');
      end   
    % ====================== set long_last_period ======================
    elseif (ischar (prop) && strcmp (prop, 'long_last_period'))   
      if (isnumeric (val) && isreal (val))
        s.long_last_period = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.long_last_period = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.long_last_period = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting long_last_period to false.',val);
            s.long_last_period = logical(0);
        end
      elseif ( islogical(val))
        s.long_last_period = val; 
      else
        error ('set: expecting long_last_period to be a real number');
      end 
    % ====================== set last_reset_rate ======================
    elseif (ischar (prop) && strcmp (prop, 'last_reset_rate'))   
      if (isnumeric (val) && isreal (val))
        s.last_reset_rate = val;
      else
        error ('set: expecting last_reset_rate to be a real number');
      end 
    % ====================== set mod_duration ======================
    elseif (ischar (prop) && strcmp (prop, 'mod_duration'))   
      if (isnumeric (val) && isreal (val))
        s.mod_duration = val;
      else
        error ('set: expecting mod_duration to be a real number');
      end
    % ====================== set mac_duration ======================
    elseif (ischar (prop) && strcmp (prop, 'mac_duration'))   
      if (isnumeric (val) && isreal (val))
        s.mac_duration = val;
      else
        error ('set: expecting mac_duration to be a real number');
      end      
    % ====================== set eff_duration ======================
    elseif (ischar (prop) && strcmp (prop, 'eff_duration'))   
      if (isnumeric (val) && isreal (val))
        s.eff_duration = val;
      else
        error ('set: expecting eff_duration to be a real number');
      end      
    % ====================== set eff_convexity ======================
    elseif (ischar (prop) && strcmp (prop, 'eff_convexity'))   
      if (isnumeric (val) && isreal (val))
        s.eff_convexity = val;
      else
        error ('set: expecting eff_convexity to be a real number');
      end      
    % ====================== set dv01 ======================
    elseif (ischar (prop) && strcmp (prop, 'dv01'))   
      if (isnumeric (val) && isreal (val))
        s.dv01 = val;
      else
        error ('set: expecting dv01 to be a real number');
      end   
    % ====================== set pv01 ======================
    elseif (ischar (prop) && strcmp (prop, 'pv01'))   
      if (isnumeric (val) && isreal (val))
        s.pv01 = val;
      else
        error ('set: expecting pv01 to be a real number');
      end      
    % ====================== set dollar_duration ======================
    elseif (ischar (prop) && strcmp (prop, 'dollar_duration'))   
      if (isnumeric (val) && isreal (val))
        s.dollar_duration = val;
      else
        error ('set: expecting dollar_duration to be a real number');
      end
    % ====================== set spread_duration ======================
    elseif (ischar (prop) && strcmp (prop, 'spread_duration'))   
      if (isnumeric (val) && isreal (val))
        s.spread_duration = val;
      else
        error ('set: expecting spread_duration to be a real number');
      end
    % ====================== set in_arrears ======================
    elseif (ischar (prop) && strcmp (prop, 'in_arrears'))   
      if (isnumeric (val) && isreal (val))
        s.in_arrears = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.in_arrears = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.in_arrears = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting in_arrears to false.',val);
            s.in_arrears = logical(0);
        end
      elseif ( islogical(val))
        s.in_arrears = val;
      else
        error ('set: expecting in_arrears to be a real number');
      end  
    % ====================== set fixed_annuity ======================
    elseif (ischar (prop) && strcmp (prop, 'fixed_annuity'))   
      if (isnumeric (val) && isreal (val))
        s.fixed_annuity = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.fixed_annuity = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.fixed_annuity = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting fixed_annuity to false.',val);
            s.fixed_annuity = logical(0);
        end
      elseif ( islogical(val))
        s.fixed_annuity = val;
      else
        error ('set: expecting fixed_annuity to be a real number');
      end 
    % ====================== set notional_at_start ======================
    elseif (ischar (prop) && strcmp (prop, 'notional_at_start'))   
      if (isnumeric (val) && isreal (val))
        s.notional_at_start = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.notional_at_start = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.notional_at_start = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting notional_at_start to false.',val);
            s.notional_at_start = logical(0);
        end
      elseif ( islogical(val))
        s.notional_at_start = val;
      else
        error ('set: expecting notional_at_start to be a real number');
      end 
    % ====================== set notional_at_end  ======================
    elseif (ischar (prop) && strcmp (prop, 'notional_at_end'))   
      if (isnumeric (val) && isreal (val))
        s.notional_at_end = logical(val);
      elseif ( ischar(val))
        if ( strcmp('false',lower(val)))
            s.notional_at_end = logical(0);
        elseif ( strcmp('true',lower(val)))
            s.notional_at_end = logical(1);
        else
            printf('WARNING: Unknown val: >>%s<<. Setting notional_at_end to false.',val);
            s.notional_at_end = logical(0);
        end
      elseif ( islogical(val))
        s.notional_at_end = val;
      else
        error ('set: expecting notional_at_end to be a real number');
      end       
    else
      error ('set: invalid property of bond class: %s',prop);
    end
  end
end

     

      
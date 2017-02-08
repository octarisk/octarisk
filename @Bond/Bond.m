classdef Bond < Instrument
   
    properties   % All properties of Class Bond with default values
        issue_date = '01-Jan-1900';
        maturity_date = '';
        compounding_type = 'disc';
        compounding_freq = 1;  
        term = 12;               
        day_count_convention = 'act/365';
        notional = 0;           
        coupon_rate = 0.0;        
        coupon_generation_method = 'backward';
        business_day_rule = 0; 
        business_day_direction = 1;
        enable_business_day_rule = 0;
        spread = 0.0;           % spread value only be used for floater        
        long_first_period = 0;  
        long_last_period = 0;   
        last_reset_rate = 0.00001;
        discount_curve = 'IR_EUR';
        reference_curve = 'IR_EUR';
        spread_curve = 'SPREAD_DUMMY';
        vola_surface = '';
        spot_value = 0.0;
        ir_shock   = 0.01;      % shock used for calculation of effective duration
        in_arrears = false;         % boolean flag: if set to 0, in fine is assumed
        fixed_annuity = 0;      % property only needed for fixed amortizing bond 
               % -> fixed annuity annuity flag (annuity loan or amortizable loan)
        annuity_amount = 0;     % fixed annnuity amount (only if fixed_annuity == 1)
        use_annuity_amount = 0; % BOOL: flag for using fixed annuity amount
        use_principal_pmt = 1;
        principal_payment = 0.0; % principal payment (use_principal_pmt flag has
                                 % to be set to true and fixed_annuity == false
        notional_at_start = 0; 
        notional_at_end = 1;
        calibration_flag = 1;   % flag set to true, if calibration 
                                %(mark to market) successful
        % attributes required for fixed amortizing bonds with prepayments
        prepayment_type         = 'full';  % ['full','default']
        prepayment_source       = 'curve'; % ['curve','rate']
        prepayment_flag         = false;   % toggle prepayment on and off
        prepayment_rate         = 0.00;    % constant prepayment rate in case
                                            % no prepayment curve is specified
        prepayment_curve        = 'PSA-BASE';  % specify prepayment curve
        prepayment_procedure    = ''; % specify prepayment_procedure (coupon rate / abs_shock_ir)
        clean_value_base        = 0; % BOOL: value_base is clean without accr interest
        outstanding_balance     = 0.0;  % outstanding balance for FAB only
        psa_factor_term         = [365,1825];   % factor terms for abs_ir_shock calc
        use_outstanding_balance = 0;    % BOOL: use outstanding balance at 
                                        % valuation date for payments
        stochastic_riskfactor   = 'RF_MATRIX';    % used for stochastic cf
        stochastic_surface      = 'SURFACE_MATRIX';  % used for stochastic cf
        stochastic_rf_type      = 'normal';       % either t, normal or univariate
        t_degree_freedom        = 120;  % degrees of freedom for t distribution
        % attributes for CMS Floating and Fixed Legs
        convex_adj              = true; % Boolean: use convexity adjustment
        cms_convex_model        = 'Hull'; % Model for calculating convexity adj.
        cms_model               = 'Black'; % volatility model [Black, normal]
        cms_sliding_term        = 1825; % sliding term of CMS float leg in days
        cms_term                = 365; % term of CMS
        cms_spread              = 0.0; % spread of CMS
        cms_comp_type           = 'simple'; % CMS compounding type
        vola_spread             = 0.0;
        prorated                = true; % Bool: true means deposit method 
			%  (adjust cash flows for leap year), false = bond method (fixed coupon)
        rate_composition        = 'capitalize'; % function for CMS rates
                                    % ['capitalize', 'average', 'max', 'min']
		% callable bond specific attributes
        embedded_option_flag    = false; % true: bond is call or putable
        alpha                   = 0.1; % callable bond mean reversion constant
        sigma                   = 0.01; % callable bond rate volatility
        treenodes               = 50; % callable bond tree nodes
        call_schedule           = ''; % callable bond call schedule curve
        put_schedule            = ''; % callable bond put schedule curve
		% Inflation Linked bond specific attributes
		cpi_index				= ''; % Consumer Price Index
		infl_exp_curve			= ''; % Inflation Expectation Curve
		cpi_historical_curve	= ''; % Curve with historical values for CPI
		infl_exp_lag			= ''; % inflation expectation lag (in months)
		use_indexation_lag		= false; % Bool: true -> use infl_exp_lag
    end
   
    properties (SetAccess = private)
        convexity = 0.0;
        eff_convexity = 0.0;
        dollar_convexity = 0.0;
        basis = 3;
        cf_dates = [];
        cf_values = [];
        cf_values_mc  = [];
        cf_values_stress = [];
        timestep_mc_cf = {};
        ytm = 0.0;
        soy = 0.0;      % spread over yield
        sub_type = 'FRB';
        mac_duration = 0.0;
        mod_duration = 0.0;
        eff_duration = 0.0;
        spread_duration = 0.0;
        dollar_duration = 0.0;
        dv01 = 0.0;
        pv01 = 0.0;
        accrued_interest = 0.0;
        last_coupon_date = 0;
        embedded_option_value = 0.0;
    end
   
   methods
      function b = Bond(tmp_name)
        if nargin < 1
            name  = 'BOND_TEST';
            id    = 'BOND_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Bond test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'Bond';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'bond',currency,value_base, ...
                        asset_class);      
      end 
      % method display properties
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);              
         fprintf('issue_date: %s\n',b.issue_date);         
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('compounding_type: %s\n',b.compounding_type); 
         if (ischar(b.compounding_freq))
            fprintf('compounding_freq: %s\n',b.compounding_freq); 
         else
            fprintf('compounding_freq: %d\n',b.compounding_freq);  
         end
         fprintf('term: %d\n',b.term);   
         fprintf('day_count_convention: %s\n',b.day_count_convention); 
         fprintf('basis: %d\n',b.basis); 
         fprintf('Notional: %f %s\n',b.notional,b.currency); 
         fprintf('coupon_rate: %f\n',b.coupon_rate);  
         fprintf('coupon_generation_method: %s\n',b.coupon_generation_method ); 
         fprintf('business_day_rule: %d\n',b.business_day_rule); 
         fprintf('business_day_direction: %d\n',b.business_day_direction); 
         fprintf('enable_business_day_rule: %d\n',b.enable_business_day_rule); 
         fprintf('spread: %f\n',b.spread); 
         fprintf('spread over yield: %f\n',b.soy); 
         fprintf('long_first_period: %d\n',b.long_first_period); 
         fprintf('long_last_period: %d\n',b.long_last_period);  
         fprintf('last_reset_rate: %f\n',b.last_reset_rate); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('reference_curve: %s\n',b.reference_curve); 
         fprintf('spread_curve: %s\n',b.spread_curve); 
         fprintf('accrued_interest: %f\n',b.accrued_interest); 
         fprintf('last_coupon_date: %d\n',b.last_coupon_date);
         fprintf('principal_payment: %f\n',b.principal_payment); 
         fprintf('use_principal_pmt: %d\n',b.use_principal_pmt);
         fprintf('use_outstanding_balance: %d\n',b.use_outstanding_balance);
		 fprintf('prorated: %s\n',any2str(b.prorated)); 
		 fprintf('in_arrears: %s\n',any2str(b.in_arrears)); 
         if ( regexpi(b.sub_type,'CMS'))
            fprintf('vola_surface: %s\n',b.vola_surface); 
            fprintf('cms_model: %s\n',b.cms_model); 
            fprintf('cms_sliding_term: %s\n',any2str(b.cms_sliding_term)); 
            fprintf('cms_term: %s\n',any2str(b.cms_term)); 
            fprintf('cms_spread: %s\n',any2str(b.cms_spread)); 
            fprintf('cms_comp_type: %s\n',b.cms_comp_type); 
            fprintf('cms_convex_model: %s\n',b.cms_convex_model); 
         end 
         if ( b.embedded_option_flag == true)
            fprintf('embedded_option_value: %f\n',b.embedded_option_value); 
            fprintf('alpha: %s\n',any2str(b.alpha)); 
            fprintf('sigma: %s\n',any2str(b.sigma)); 
            fprintf('treenodes: %s\n',any2str(b.treenodes)); 
            fprintf('call_schedule: %s\n',b.call_schedule); 
            fprintf('put_schedule: %s\n',b.put_schedule); 
            fprintf('vola_surface: %s\n',b.vola_surface); 
         end 
         if ( regexpi(b.sub_type,'FRN_SPECIAL'))
            fprintf('vola_surface: %s\n',b.vola_surface); 
            fprintf('rate_composition: %s\n',b.rate_composition); 
            fprintf('cms_model: %s\n',b.cms_model); 
            fprintf('cms_sliding_term: %s\n',any2str(b.cms_sliding_term)); 
            fprintf('cms_term: %s\n',any2str(b.cms_term)); 
            fprintf('cms_spread: %s\n',any2str(b.cms_spread)); 
            fprintf('cms_comp_type: %s\n',b.cms_comp_type); 
            fprintf('cms_convex_model: %s\n',b.cms_convex_model);
         end 
         if ( strcmpi(b.sub_type,'STOCHASTICCF'))
            fprintf('stochastic_riskfactor: %s\n',b.stochastic_riskfactor); 
            fprintf('stochastic_surface: %s\n',b.stochastic_surface); 
            fprintf('stochastic_rf_type: %s\n',b.stochastic_rf_type); 
            if ( strcmpi(b.stochastic_rf_type,'t'))
                fprintf('t_degree_freedom: %d\n',b.t_degree_freedom); 
            end
         end
		 if ( strcmpi(b.sub_type,'ILB'))
            fprintf('cpi_index: %s\n',b.cpi_index); 
            fprintf('infl_exp_curve: %s\n',b.infl_exp_curve); 
            fprintf('cpi_historical_curve: %s\n',b.cpi_historical_curve); 
			fprintf('infl_exp_lag: %s\n',any2str(b.infl_exp_lag));
			fprintf('use_indexation_lag: %s\n',any2str(b.use_indexation_lag));
         end
		
         %fprintf('spot_value: %f %s\n',b.spot_value,b.currency);
         % display all mc values and cf values
         cf_stress_rows = min(rows(b.cf_values_stress),5);
         [mc_rows mc_cols mc_stack] = size(b.cf_values_mc);
         % looping via all cf_dates if defined
         if ( length(b.cf_dates) > 0 )
            fprintf('CF dates:\n[ ');
            for (ii = 1 : 1 : length(b.cf_dates))
                fprintf('%d,',b.cf_dates(ii));
            end
            fprintf(' ]\n');
         end
         % looping via all cf base values if defined
         if ( length(b.cf_values) > 0 )
            fprintf('CF Base values:\n[ ');
            for ( kk = 1 : 1 : min(columns(b.cf_values),10))
                    fprintf('%f,',b.cf_values(kk));
                end
            fprintf(' ]\n');
         end   
          % looping via all stress rates if defined
         if ( rows(b.cf_values_stress) > 0 )
            tmp_cf_values = b.getCF('stress');
            fprintf('CF Stress values:\n[ ');
            for ( jj = 1 : 1 : min(rows(tmp_cf_values),5))
                for ( kk = 1 : 1 : min(columns(tmp_cf_values),10))
                    fprintf('%f,',tmp_cf_values(jj,kk));
                end
                fprintf(' ]\n');
            end
            fprintf('\n');
         end    
         % looping via first 3 MC scenario values
         for ( ii = 1 : 1 : mc_stack)
            if ( length(b.timestep_mc_cf) >= ii )
                fprintf('MC timestep: %s\n',b.timestep_mc_cf{ii});
                tmp_cf_values = b.getCF(b.timestep_mc_cf{ii});
                fprintf('CF Scenariovalue:\n[ ')
                for ( jj = 1 : 1 : min(rows(tmp_cf_values),5))
                    for ( kk = 1 : 1 : min(columns(tmp_cf_values),10))
                        fprintf('%f,',tmp_cf_values(jj,kk));
                    end
                    fprintf(' ]\n');
                end
                fprintf('\n');
            else
                fprintf('MC timestep cf not defined\n');
            end
         end

      end
      function obj = set.sub_type(obj,sub_type)
         if (strcmpi(sub_type,'Fixed Rate Bond'))   % replace Fixed Rate Bond
            sub_type = 'FRB';
         end
         if ~(strcmpi(sub_type,'FRB') || strcmpi(sub_type,'FRN') ...
                || strcmpi(sub_type,'CASHFLOW') || strcmpi(sub_type,'FAB') ...
                || strcmpi(sub_type,'SWAP_FIXED') || strcmpi(sub_type,'SWAP_FLOATING') ...
                || strcmpi(sub_type,'ZCB')  || strcmpi(sub_type,'STOCHASTICCF') ...
                || strcmpi(sub_type,'CMS_FLOATING') || strcmpi(sub_type,'FRN_SPECIAL') ...
				|| strcmpi(sub_type,'ILB'))
            error('Bond sub_type must be either FRB, FRN, ILB, CASHFLOW, SWAP_FIXED, STOCHASTICCF, SWAP_FLOATING, FRN_SPECIAL or CMS_FLOATING: %s',sub_type)
         end
         obj.sub_type = sub_type;
      end % set.sub_type
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
      
      function obj = set.term(obj,term)
        if ( isempty(term))
            fprintf('Need valid term for id >>%s<<. Setting to default value 12 month.\n',obj.id);
            obj.term = 12;
        else
            if ( sum(term == [0;1;3;6;12;52;365]) == 0)
                fprintf('Need valid term in [0;1;3;6;12;52;365] for id >>%s<<. Setting to default value 12 month.\n',obj.id);
                obj.term = 12;
            else 
                obj.term = term;
            end
        end
      end % set.term
      
      function obj = set.coupon_generation_method(obj,coupon_generation_method)
        if ( strcmpi(coupon_generation_method,'backward'))
            obj.coupon_generation_method = 'backward';
        elseif ( strcmpi(coupon_generation_method,'forward') )
            obj.coupon_generation_method = 'forward';
        else
            fprintf('Need valid coupon_generation_method for id >>%s<<. Setting to default value backward.\n',obj.id);
            obj.coupon_generation_method = 'backward';
        end
      end % set.coupon_generation_method
      
      function obj = set.cf_dates(obj,cf_dates)
        % check for length of vectors cf_dates and cf_values
        if ~( isempty(obj.cf_values))
            if ~( columns(cf_dates) == columns(obj.cf_values)  )
                fprintf('WARNING: Bond.set(cf_dates): Number of columns of cf_dates (>>%s<<) not equal to cf_values columns (>>%s<<) for id >>%s<<\n',any2str(columns(cf_dates)),any2str(columns(obj.cf_values)),obj.id);
            end
        end
        obj.cf_dates = cf_dates;
      end % set.cf_dates
      
      function obj = set.cf_values(obj,cf_values)
        % check for length of vectors cf_dates and cf_values
        if ~( isempty(obj.cf_dates))
            if ~( columns(cf_values) == columns(obj.cf_dates)  )
                fprintf('WARNING: Bond.set(cf_values): Number of columns of cf_values (>>%s<<) not equal to cf_dates (>>%s<<) for id >>%s<<\n',any2str(columns(cf_values)),any2str(columns(obj.cf_dates)),obj.id);
            end
        end
        obj.cf_values = cf_values;
      end % set.cf_values
      
      % setting compounding frequency to numeric value
      function obj = set.compounding_freq(obj,comp_freq)
        if ischar(comp_freq)
            if ( strcmpi(comp_freq,'daily') || strcmpi(comp_freq,'day'))
                compounding = 365;
            elseif ( strcmpi(comp_freq,'weekly') || strcmpi(comp_freq,'week'))
                compounding = 52;
            elseif ( strcmpi(comp_freq,'monthly') || strcmpi(comp_freq,'month'))
                compounding = 12;
            elseif ( strcmpi(comp_freq,'quarterly')  ||  strcmpi(comp_freq,'quarter'))
                compounding = 4;
            elseif ( strcmpi(comp_freq,'semi-annual'))
                compounding = 2;
            elseif ( strcmpi(comp_freq,'annual') )
                compounding = 1;       
            else
                fprintf('Need valid compounding frequency for id >>%s<<. Setting to default value 1.\n',obj.id);
                compounding = 1;
            end
        elseif isnumeric(comp_freq)
            compounding = comp_freq;
        else
            compounding = 1;
            fprintf('Need valid compounding frequency for id >>%s<<. Setting to default value 1.\n',obj.id);
        end 
        obj.compounding_freq = compounding;
      end % set.compounding_freq
  
      function obj = set.rate_composition(obj,rate_composition)
         if ~(strcmpi(rate_composition,'capitalized') || strcmpi(rate_composition,'average') ...
                || strcmpi(rate_composition,'min') || strcmpi(rate_composition,'max'))
            error('Bond rate_composition must be either capitalized, average, min, max : %s for id >>%s<<.\n',rate_composition,obj.id);
         end
         obj.rate_composition = tolower(rate_composition);
      end % set.rate_composition
  
   end % end static methods
   
end 

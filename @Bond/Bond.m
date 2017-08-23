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
		stochastic_zero_base	= true;	%Boolean: always zero value in base case
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
		% attributes for Special FRN / SWAP_FLOATING
		fwd_sliding_term        = 1825; % sliding term of forward float leg in days
        fwd_term                = 365; % term of forward rates
		
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
		
		% Key rate duration specific attributes
		key_term 				= [365,730,1095,1460,1825,2190,2555,2920,3285,3650]; % term structure of key rates
		key_rate_shock 			= 0.01; % key rate shock size (cont, act/365)
		key_rate_width 			= 365;% width of key rate shocks
		
		% Forward rate agreement
		strike_rate				= 0.0; % strike rate (cont, act/365)
		underlying_maturity_date = '01-Jan-1900';
		coupon_prepay			= 'discount'; % in ['discount','in fine'];
		
		% Forward volatility / variance agreement
		fva_type				= 'volatility'; % in ['volatility','variance']
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
		key_rate_eff_dur = [];
		key_rate_mon_dur = [];
		key_rate_eff_convex = [];
		key_rate_mon_convex = [];
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
		 if ~( isempty(b.key_rate_eff_dur))
			fprintf('Key rate term: %s\n',any2str(b.key_term)); 
			fprintf('Key rate Effective Duration: %s\n',any2str(b.key_rate_eff_dur));
			fprintf('Key rate Monetary Duration: %s\n',any2str(b.key_rate_mon_dur));
			fprintf('Key rate Effective Convexity: %s\n',any2str(b.key_rate_eff_convex));
			fprintf('Key rate Monetary Convexity: %s\n',any2str(b.key_rate_mon_convex));
		 end
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
		 if ( strcmpi(b.sub_type,'FRA'))
			fprintf('strike_rate (cont, act/365): %s\n',any2str(b.strike_rate));
            fprintf('underlying_maturity_date: %s\n',any2str(b.underlying_maturity_date)); 
            fprintf('coupon_prepay: %s\n',any2str(b.coupon_prepay));
			fprintf('fva_type: %s\n',any2str(b.fva_type));
         end 
		 if ( strcmpi(b.sub_type,'FVA'))
			fprintf('strike_rate (cont, act/365): %s\n',any2str(b.strike_rate));
            fprintf('underlying_maturity_date: %s\n',any2str(b.underlying_maturity_date)); 
            fprintf('vola_surface: %s\n',any2str(b.vola_surface)); 
         end 
		 if ( regexpi(b.sub_type,'_FWD_SPECIAL'))
			fprintf('rate_composition: %s\n',b.rate_composition);
            fprintf('fwd_sliding_term: %s\n',any2str(b.fwd_sliding_term)); 
            fprintf('fwd_term: %s\n',any2str(b.fwd_term)); 
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
				|| strcmpi(sub_type,'ILB') || strcmpi(sub_type,'SWAP_FLOATING_FWD_SPECIAL') ...
				|| strcmpi(sub_type,'FRN_FWD_SPECIAL')  || strcmpi(sub_type,'FRA') ...
				|| strcmpi(sub_type,'FVA'))
            error('Bond sub_type must be either FRB, FRN, ZCB, ILB, CASHFLOW, SWAP_FIXED, STOCHASTICCF, SWAP_FLOATING, FRN_SPECIAL, CMS_FLOATING, FRA, FVA, FRN_FWD_SPECIAL or SWAP_FLOATING_FWD_SPECIAL: %s',sub_type)
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
            error('Bond rate_composition must be either capitalized, average, min, max : >>%s<< for id >>%s<<.\n',rate_composition,obj.id);
         end
         obj.rate_composition = tolower(rate_composition);
      end % set.rate_composition
  
      function obj = set.coupon_prepay(obj,coupon_prepay)
         if ~(strcmpi(coupon_prepay,'discount') || strcmpi(coupon_prepay,'in fine'))
            error('Bond coupon_prepay must be in [Discount,in Fine] : >>%s<< for id >>%s<<.\n',coupon_prepay,obj.id);
         end
         obj.coupon_prepay = tolower(coupon_prepay);
      end % set.coupon_prepay
  
   end % end methods
   
   %static methods: 
   methods (Static = true)
   
	function retval = help (format,retflag)
		formatcell = {'plain text','html','texinfo'};
		% input checks
		if ( nargin == 0 )
			format = 'plain text';	
		end
		if ( nargin < 2 )
			retflag = 0;	
		end

		% format check
		if ~( strcmpi(format,formatcell))
			fprintf('WARNING: Bond.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
			format = 'plain text';
		end	

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Bond(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Bond()\n\
\n\
Class for setting up various Bond objects.\n\
Cash flows are generated specific for each Bond sub type and subsequently\n\
discounted to calculate the Bond value. All bonds can have embedded options\n\
(Option pricing according to Hull-White model).\n\
\n\
@itemize @bullet\n\
@item FRB: Fixed Rate Bond\n\
@item FRN: Floating Rate Note: Calculate CF Values based on forward rates of a given reference curve.\n\
@item ZCB: Zero Coupon Bond\n\
@item ILB: Inflation Linked Bond\n\
@item CASHFLOW: Cash flow instruments. Custom cash flow dates and values are discounted.\n\
@item SWAP_FIXED: Swap fixed leg\n\
@item SWAP_FLOATING: Swap floating leg\n\
@item FRN_CMS_SPECIAL: Special type floating rate notes (capitalized, average, min, max) based on CMS rates\n\
@item CMS_FLOATING: Floating leg based on CMS rates\n\
@item FRA: Forward Rate Agreement\n\
@item FVA: Forward Volatility Agreement\n\
@item FRN_FWD_SPECIAL:  Averaging FRN: Average forward or historical rates of cms_sliding period\n\
@item STOCHASTICCF: Stochastic cash flow instrument (cash flows values are derived from an empirical cash flow distribution)\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Bond object @var{obj}:\n\
@itemize @bullet\n\
@item Bond(@var{id}) or Bond(): Constructor of a Bond object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{valuation_date},@var{scenario}, @var{discount_curve})\n\
@item obj.calc_value(@var{valuation_date},@var{scenario}, @var{discount_curve}, @var{call_schedule}, @var{put_schedule}):\n\
Calculate the net present value of cash flows of Bonds (including pricing of embedded options)\n\
\n\
@item obj.rollout(@var{scenario}, @var{valuation_date}): used for FRB and CASHFLOW  instruments\n\
@item obj.rollout(@var{scenario}, @var{valuation_date}, @var{reference_curve}, @var{vola_surface}): used for CMS_FLOATING or FRN_SPECIAL\n\
@item obj.rollout(@var{scenario}, @var{reference_curve}, @var{valuation_date}, @var{vola_surface}): used for FRN, FRA, FVA, SWAP_FLOATING\n\
@item obj.rollout(@var{scenario},@var{valuation_date}, @var{psa_curve}, @var{psa_factor_surface}, @var{ir_shock_curve}): used for FAB with prepayments\n\
@item obj.rollout(@var{scenario},@var{valuation_date}, @var{inflation_expectation_curve}, @var{historical_rates}, @var{consumer_price_index}): used for ILB\n\
@item obj.rollout(@var{scenario},@var{valuation_date}, @var{riskfactor}, @var{cashflow_surface}): used for Stochastic CF instruments\n\
Cash flow rollout for Bonds\n\
\n\
@item obj.calc_sensitivities(@var{valuation_date},@var{discount_curve}, @var{reference_curve})\n\
Calculate analytical and numerical sensitivities for the given Bond instrument.\n\
\n\
@item obj.calc_key_rates(@var{valuation_date},@var{discount_curve})\n\
Calculate key rate sensitivities for the given Bond instrument.\n\
\n\
@item obj.calc_spread_over_yield(@var{valuation_date},@var{scenario}, @var{discount_curve}) or\n\
@item obj.calc_spread_over_yield(@var{valuation_date},@var{scenario}, @var{discount_curve}, @var{call_schedule}, @var{put_schedule})\n\
Calibrate spread over yield in order to match the Bond price with the market price. The interest rate spread will be used for further pricing.\n\
\n\
@item obj.calc_yield_to_mat(@var{valuation_date}): Calculate yield to maturity for given cash flow structure.\n\
\n\
@item obj.getValue(@var{scenario}): Return Bond value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item Bond.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Bond objects:\n\
@itemize @bullet\n\
@item @var{id}: Instrument id. Has to be unique identifier. (Default: empty string)\n\
@item @var{name}: Instrument name. (Default: empty string)\n\
@item @var{description}: Instrument description. (Default: empty string)\n\
@item @var{value_base}: Base value of instrument of type real numeric. (Default: 0.0)\n\
@item @var{currency}: Currency of instrument of type string. (Default: 'EUR')\n\
During instrument valuation and aggregation, FX conversion takes place if corresponding FX rate is available.\n\
@item @var{asset_class}: Asset class of instrument. (Default: 'derivative')\n\
@item @var{type}: Type of instrument, specific for class. Set to 'Bond'.\n\
@item @var{value_stress}: Line vector with instrument stress scenario values.\n\
@item @var{value_mc}: Line vector with instrument scenario values.\n\
MC values for several @var{timestep_mc} are stored in columns.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. If new timesteps are set, values are automatically appended.\n\
\n\
For illustration see the following example:\n\
A 9 month floating rate note instrument will be calibrated and priced.\n\
The resulting spread over yield value (0.00398785481397732),\n\
base value (99.7917725092950) and effective duration (3.93109370316470e-005)is retrieved:\n\
@example\n\
@group\n\
\n\
disp('Pricing Floating Rate Bond Object and calculating sensitivities')\n\
b = Bond();\n\
b = b.set('Name','Test_FRN','coupon_rate',0.00,'value_base',99.7527, ...\n\
'coupon_generation_method','backward','compounding_type','simple');\n\
b = b.set('maturity_date','30-Mar-2017','notional',100, ...\n\
'compounding_type','simple','issue_date','21-Apr-2011');\n\
b = b.set('term',3,'last_reset_rate',-0.0024,'sub_Type','FRN','spread',0.003);\n\
r = Curve();\n\
r = r.set('id','REF_IR_EUR','nodes',[30,91,365,730], ...\n\
'rates_base',[0.0001002740,0.0001002740,0.0001001390,0.0001000690], ...\n\
'method_interpolation','linear');\n\
b = b.rollout('base',r,'30-Jun-2016');\n\
c = Curve();\n\
c = c.set('id','IR_EUR','nodes',[30,90,180,365,730], ...\n\
'rates_base',[0.0019002740,0.0019002740,0.0019002301,0.0019001390,0.001900069], ...\n\
'method_interpolation','linear');\n\
b = b.set('clean_value_base',99.7527,'spread',0.003);\n\
b = b.calc_spread_over_yield('30-Jun-2016',c);\n\
b.get('soy')\n\
b = b.calc_value('30-Jun-2016','base',c);\n\
b.getValue('base')\n\
b = b.calc_sensitivities('30-Jun-2016',c,r);\n\
b.get('eff_duration')\n\
@end group\n\
@end example\n\
\n\
@end deftypefn";

		% format help text
		[retval status] = __makeinfo__(textstring,format);
		% status
		if (status == 0)
			% depending on retflag, return textstring
			if (retflag == 0)
				% print formatted textstring
				fprintf("\'CapFloor\' is a class definition from the file /octarisk/@CapFloor/CapFloor.m\n");
				fprintf("\n%s\n",retval);
				retval = [];
			end
		end

		
	end % end of static method help
	
   end	% end of static method
   
end 

classdef Retail < Instrument
   
    properties   % All properties of Class Retail with default values
        issue_date = '01-Jan-1900';
        maturity_date = '';
        compounding_type = 'disc';
        compounding_freq = 1;  
        term = 12;     
        term_unit = 'months';   % can be [days,months,years]
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
        discount_curve = 'IR_EUR';
        reference_curve = 'IR_EUR';
        ir_shock   = 0.01;      % shock used for calculation of effective duration
        in_arrears = false;         % boolean flag: if set to 0, in fine is assumed
        notional_at_start = 0; 
        notional_at_end = 1;
        calibration_flag = 1;   % flag set to true, if calibration 
                                %(mark to market) successful
        prorated                = true; % Bool: true means deposit method 
            %  (adjust cash flows for leap year), false = bond method (fixed coupon)
         
        % Savings Plan attributes
        savings_rate = 0;	    % savings rate in absolute terms
        redemption_values = [];
        redemption_dates = '';	% fixed redemption value at given dates
        savings_startdate = '';	% begin of savings period
        savings_enddate = '';   % end of savings period
        notice_period= 0;		% notice period (0 = not redeemable)
        notice_period_unit = 'months'; 
        protection_scheme_limit = 100000; % limit of deposit guarantee
        bonus_value_current = 0.0;
        bonus_value_redemption = 0.0;
        extra_payment_values = []; % value of extra payments
        extra_payment_dates = '';  % at given dates
        savings_change_values = []; % savings rate changes at given dates  
        savings_change_dates = '';  % dates on which saving values changes
             
        % Retirement Expenses attributes
        year_of_birth	= 1983;	% start date for all longevity calculations
        year_of_birth_widow	= 1983;	% start date for all longevity calculations
		retirement_startdate = '';
		retirement_enddate = '';
		expense_values = [];  % value of expenses
		expense_dates = '';	  % valid starting at given dates
		infl_exp_curve = '';
		longevity_table = '';
		longevity_table_widow = '';
		mortality_table = '';
		mortality_shift_years = 0;	% number in years, how to shift survival/mortality values
		mortality_shift_years_widow = 0;	% number in years, how to shift survival/mortality values
		 
        % Retirement Government pension
        pension_scores = 0; 	% Rentenpunkte
        widow_pension_rate = 0.6; 	% Ratio of Widow pension
        value_per_score = 0;	% Wert pro Rentenpunkt: gross_pension = value_per_score x pension_scores
        tax_rate = 0;			% tax rate: net pension = gross penion x (1- tax_rate)
        widow_pension_flag = 0;	% boolean: take into account pension payments for widow
        
        % Human Capital specific attributes
        income_fix = 0;			% fixed (steady) component of salary
		income_bonus = 0;		% bonus (risky) component of salary
		mu_risky 	= 0.0;		% drift of risky component
		s_risky  	= 0.0;		% Volatility of risky (equity like) component
		corr		= 0.0;		% correlation between risky and steady component
		mu_labor	= 0.0;		% real drift of fix and bonus components
		s_labor		= 0.0;		% volatility of steady salary growth
		nmc			= 100;		% Number of inner MC scenarios (100-500 should be enough)
		bonus_cap	= 0.0;		% maximum increase of bonus component
		bonus_floor = 0.0;		% maximum decrease of bonus component
		spread_risky = 0.0;	% spread applied to discount curve used for discounting future income stream        
        salary_startdate = '';	% start date of salary income
        salary_enddate = '';	% end date of salary
        equity_riskfactor = '';	% Equity risk factor (used for calculation of first bonus payment
        
        % Key rate duration specific attributes
        key_term                = [365,730,1095,1460,1825,2190,2555,2920,3285,3650]; % term structure of key rates
        key_rate_shock          = 0.01; % key rate shock size (cont, act/365)
        key_rate_width          = 365;% width of key rate shocks
        
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
        sub_type = 'SAVPLAN';
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
      function b = Retail(tmp_name)
        if nargin < 1
            name  = 'RETAIL_TEST';
            id    = 'RETAIL_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Retail test instrument';
        value_base = 100.00;      
        currency = 'EUR';
        asset_class = 'Bond';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'retail',currency,value_base, ...
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
         fprintf('term: %d %s\n',b.term,b.term_unit);   
         fprintf('day_count_convention: %s\n',b.day_count_convention); 
         fprintf('basis: %d\n',b.basis); 
         fprintf('Notional: %f %s\n',b.notional,b.currency); 
         fprintf('coupon_rate: %f %% %s %s\n',b.coupon_rate .* 100,b.compounding_type,b.day_count_convention);  
         fprintf('coupon_generation_method: %s\n',b.coupon_generation_method ); 
         fprintf('business_day_rule: %d\n',b.business_day_rule); 
         fprintf('business_day_direction: %d\n',b.business_day_direction); 
         fprintf('enable_business_day_rule: %d\n',b.enable_business_day_rule); 
         fprintf('spread: %f %% %s %s\n',b.spread .* 100,b.compounding_type,b.day_count_convention); 
         fprintf('long_first_period: %d\n',b.long_first_period); 
         fprintf('long_last_period: %d\n',b.long_last_period);  
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('reference_curve: %s\n',b.reference_curve); 
         fprintf('accrued_interest: %f\n',b.accrued_interest); 
         fprintf('last_coupon_date: %d\n',b.last_coupon_date);
         fprintf('prorated: %s\n',any2str(b.prorated)); 
         fprintf('in_arrears: %s\n',any2str(b.in_arrears)); 
         if strcmpi( b.sub_type,'RETEXP') 
			fprintf('year_of_birth: %d\n',b.year_of_birth); 
			fprintf('retirement_startdate: %s\n',b.retirement_startdate); 
			fprintf('retirement_enddate: %s\n',b.retirement_enddate); 
			fprintf('mortality_shift_years: %f\n',b.mortality_shift_years); 
			fprintf('infl_exp_curve: %s\n',b.infl_exp_curve); 
			fprintf('longevity_table: %s\n',b.longevity_table); 
			fprintf('mortality_table: %s\n',b.mortality_table); 
			fprintf('expense_values: %s\n',any2str(b.expense_values)); 
			fprintf('expense_dates: %s\n',any2str(b.expense_dates)); 
         end
         if strcmpi( b.sub_type,'GOVPEN') 
			fprintf('year_of_birth: %d\n',b.year_of_birth); 
			fprintf('year_of_birth_widow: %d\n',b.year_of_birth_widow);
			fprintf('retirement_startdate: %s\n',b.retirement_startdate); 
			fprintf('retirement_enddate: %s\n',b.retirement_enddate); 
			fprintf('mortality_shift_years: %f\n',b.mortality_shift_years); 
			fprintf('mortality_shift_years_widow: %f\n',b.mortality_shift_years_widow); 
			fprintf('infl_exp_curve: %s\n',b.infl_exp_curve); 
			fprintf('longevity_table: %s\n',b.longevity_table); 
			fprintf('longevity_table_widow: %s\n',b.longevity_table_widow); 
			fprintf('mortality_table: %s\n',b.mortality_table); 
			fprintf('pension_scores: %f\n',b.pension_scores); 
			fprintf('value_per_score: %f\n',b.value_per_score); 
			fprintf('tax_rate: %f\n',b.tax_rate); 
			fprintf('widow_pension_flag: %s\n',any2str(b.widow_pension_flag)); 
         end
         if strcmpi( b.sub_type,'SAVPLAN')
			fprintf('savings_rate: %f  %s\n',b.savings_rate,b.currency); 
			fprintf('redemption_values: %s\n',any2str(b.redemption_values)); 
			fprintf('redemption_dates: %s\n',any2str(b.redemption_dates)); 
			fprintf('savings_startdate: %s\n',any2str(b.savings_startdate)); 
			fprintf('savings_enddate: %s\n',any2str(b.savings_enddate)); 
			fprintf('notice_period: %s %s\n',any2str(b.notice_period),b.notice_period_unit); 
			fprintf('protection_scheme_limit: %s %s\n',any2str(b.protection_scheme_limit),b.currency); 
			fprintf('bonus_value_current: %s\n',any2str(b.bonus_value_current)); 
			fprintf('bonus_value_redemption: %s\n',any2str(b.bonus_value_redemption)); 
			fprintf('extra_payment_values: %s %s\n',any2str(b.extra_payment_values),b.currency); 
			fprintf('extra_payment_dates: %s\n',any2str(b.extra_payment_dates)); 
			fprintf('embedded_option_value: %s %s\n',any2str(b.embedded_option_value),b.currency); 
			fprintf('Breakeven rate redemption: %f %% %s %s\n',100* b.ytm,b.compounding_type,b.day_count_convention); 
         end
         if strcmpi( b.sub_type,'DCP')
			fprintf('savings_rate: %f  %s\n',b.savings_rate,b.currency); 
			fprintf('redemption_values: %s\n',any2str(b.redemption_values)); 
			fprintf('redemption_dates: %s\n',any2str(b.redemption_dates)); 
			fprintf('savings_startdate: %s\n',any2str(b.savings_startdate)); 
			fprintf('savings_enddate: %s\n',any2str(b.savings_enddate)); 
			fprintf('notice_period: %s %s\n',any2str(b.notice_period),b.notice_period_unit); 
			fprintf('protection_scheme_limit: %s %s\n',any2str(b.protection_scheme_limit),b.currency); 
			fprintf('extra_payment_values: %s %s\n',any2str(b.extra_payment_values),b.currency); 
			fprintf('extra_payment_dates: %s\n',any2str(b.extra_payment_dates)); 
			fprintf('savings_change_values: %s %s\n',any2str(b.savings_change_values),b.currency); 
			fprintf('savings_change_dates: %s\n',any2str(b.savings_change_dates)); 
			fprintf('embedded_option_value: %s %s\n',any2str(b.embedded_option_value),b.currency); 
			fprintf('Breakeven rate redemption: %f %% %s %s\n',100* b.ytm,b.compounding_type,b.day_count_convention); 
         end
         if strcmpi( b.sub_type,'HC')
			fprintf('income_fix: %f  %s\n',b.income_fix,b.currency); 
			fprintf('income_bonus: %f  %s\n',b.income_bonus,b.currency); 
			fprintf('mu_risky: %f\n',b.mu_risky); 
			fprintf('s_risky: %f\n',b.s_risky); 
			fprintf('corr: %f\n',b.corr); 
			fprintf('mu_labor: %f\n',b.mu_labor); 
			fprintf('s_labor: %f\n',b.s_labor); 
			fprintf('nmc: %d\n',b.nmc); 
			fprintf('bonus_cap: %f\n',b.bonus_cap); 
			fprintf('bonus_floor: %f\n',b.bonus_floor); 
			fprintf('spread_risky: %f\n',b.spread_risky); 
			fprintf('year_of_birth: %d\n',b.year_of_birth); 
			fprintf('salary_startdate: %s\n',b.salary_startdate); 
			fprintf('salary_enddate: %s\n',b.salary_enddate); 
			fprintf('mortality_shift_years: %f\n',b.mortality_shift_years); 
			fprintf('infl_exp_curve: %s\n',b.infl_exp_curve); 
			fprintf('longevity_table: %s\n',b.longevity_table);  
			fprintf('equity_riskfactor: %s\n',b.equity_riskfactor);  
         end
         if ~( isempty(b.mac_duration))
            fprintf('eff_duration: %s\n',any2str(b.eff_duration)); 
            fprintf('eff_convexity: %s\n',any2str(b.eff_convexity)); 
            fprintf('dv01: %s\n',any2str(b.dv01)); 
            fprintf('pv01: %s\n',any2str(b.pv01)); 
            fprintf('spread_duration: %s\n',any2str(b.spread_duration)); 
         end
         if ~( isempty(b.key_rate_eff_dur))
            fprintf('Key rate term: %s\n',any2str(b.key_term)); 
            fprintf('Key rate Effective Duration: %s\n',any2str(b.key_rate_eff_dur));
            fprintf('Key rate Monetary Duration: %s\n',any2str(b.key_rate_mon_dur));
            fprintf('Key rate Effective Convexity: %s\n',any2str(b.key_rate_eff_convex));
            fprintf('Key rate Monetary Convexity: %s\n',any2str(b.key_rate_mon_convex));
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
         if ~(strcmpi(sub_type,'DCP') || strcmpi(sub_type,'SAVPLAN') ...
				|| strcmpi(sub_type,'RETEXP') || strcmpi(sub_type,'GOVPEN') || strcmpi(sub_type,'HC'))
            error('Retail sub_type must be either DCP, RETEXP, GOVPEN, HC or SAVPLAN: %s',sub_type)
         end
         obj.sub_type = sub_type;
      end % set.sub_type
      
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
      
      
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
      
      function obj = set.cf_values(obj,cf_values)
        % check for length of vectors cf_dates and cf_values
        if ~( isempty(obj.cf_dates))
            if ~( columns(cf_values) == columns(obj.cf_dates)  )
                fprintf('WARNING: Retail.set(cf_values): Number of columns of cf_values (>>%s<<) not equal to cf_dates (>>%s<<) for id >>%s<<\n',any2str(columns(cf_values)),any2str(columns(obj.cf_dates)),obj.id);
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
  
	  function obj = set.coupon_prepay(obj,coupon_prepay)
         if ~(strcmpi(coupon_prepay,'discount') || strcmpi(coupon_prepay,'in fine') || strcmpi(coupon_prepay,'in arrears'))
            error('Retail coupon_prepay must be in [Discount,in Fine] : >>%s<< for id >>%s<<.\n',coupon_prepay,obj.id);
         end
         obj.coupon_prepay = tolower(coupon_prepay);
         if (strcmpi(coupon_prepay,'in fine') || strcmpi(coupon_prepay,'discount'))
            obj.in_arrears = false;
         else
            obj.in_arrears = true;
         end
      end % set.coupon_prepay
      
      function obj = set.term_unit(obj,term_unit)
         if ~(strcmpi(term_unit,'days') || strcmpi(term_unit,'months') ...
                || strcmpi(term_unit,'years'))
            error('Retail term_unit must be in [days,months,years] : >>%s<< for id >>%s<<.\n',term_unit,obj.id);
         end
         obj.term_unit = tolower(term_unit);
         
         if ( strcmpi(obj.sub_type,'HC') && ~(strcmpi(term_unit,'years')))
			error('Retail type HC must have term unit 1 years.');
         end
      end % set.term_unit
            
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
textstring = "@deftypefn{Octarisk Class} {@var{object}} = Retail(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = Retail()\n\
\n\
Class for setting up various Retail objects like saving plans with bonus or\n\
defined contribution pension plans and retirement expenses.\n\
Cash flows are generated specific for each Retail sub type and subsequently\n\
discounted to calculate the Retail value.\n\
\n\
@itemize @bullet\n\
@item DCP: Defined contribution savings plan with guaranteed value at maturity and surrender value.\n\
@item SAVPLAN: Savings plan with optional bonus at maturity.\n\
@item RETEXP: Modelling retirement expenses depending on survival rates and inflation expectation rates.\n\
@item GOVPEN: Modelling government pensions depending on survival rates and inflation expectation rates.\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for Retail object @var{obj}:\n\
@itemize @bullet\n\
@item Retail(@var{id}) or Retail(): Constructor of a Bond object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{valuation_date},@var{scenario}, @var{discount_curve})\n\
Calculate the net present value of cash flows of Bonds (including pricing of embedded options)\n\
\n\
@item obj.rollout(@var{scenario}, @var{valuation_date}): used for SAVPLAN and DCP without redemption\n\
@item obj.rollout(@var{scenario}, @var{valuation_date}, @var{discount_curve}): used for DCP with redemption\n\
@item obj.rollout(@var{scenario}, @var{valuation_date}, @var{inflation_exp_curve}, @var{longevity_table}): used for retirement expenses and government pensions\n\
\n\
@item obj.calc_sensitivities(@var{valuation_date},@var{discount_curve})\n\
Calculate numerical sensitivities for the given Retail instrument.\n\
\n\
@item obj.calc_key_rates(@var{valuation_date},@var{discount_curve})\n\
Calculate key rate sensitivities for the given Retail instrument.\n\
\n\
@item obj.getValue(@var{scenario}): Return Retail value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item Retail.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of Retail objects:\n\
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
@end itemize\n\
\n\
For illustration see the following example:\n\
A monthly savings plan with extra payments and bonus at maturity is valuated.\n\
The resulting base value (52803.383344) and effective duration (4.9362)is retrieved:\n\
@example\n\
@group\n\
\n\
disp('Pricing Savings Plan');\n\
rates_base = [0.0056,0.02456];\n\
rates_stress = rates_base + [-0.05;-0.03;0.0;0.03;0.05];\n\
valuation_date = '31-May-2019';\n\
r = Retail();\n\
r = r.set('Name','Test_SAVPLAN','sub_type','SAVPLAN', ...\n\
'coupon_rate',0.0155,'coupon_generation_method', ...\n\
'backward','term',1,'term_unit','months');\n\
r = r.set('maturity_date','05-May-2024','compounding_type', ...\n\
'simple','savings_rate',500);\n\
r = r.set('savings_startdate','05-May-2014', ...\n\
'savings_enddate','05-May-2021');\n\
r = r.set('extra_payment_values',[17500], ...\n\
'extra_payment_dates',cellstr('17-May-2019'), ...\n\
'bonus_value_current',0.5,'bonus_value_redemption',0.15);\n\
r = r.set('notice_period',3,'notice_period_unit','months');\n\
r = r.rollout('base',valuation_date);\n\
r = r.rollout('stress',valuation_date);\n\
c = Curve();\n\
c = c.set('id','IR_EUR','nodes',[365,7300]);\n\
c = c.set('rates_base',rates_base,'rates_stress',rates_stress);\n\
c = c.set('method_interpolation','linear');\n\
r = r.calc_value(valuation_date,'base',c);\n\
r = r.calc_value(valuation_date,'stress',c);\n\
r = r.calc_sensitivities(valuation_date,c);\n\
r = r.calc_key_rates(valuation_date,c);\n\
r\n\
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
                fprintf("\'Bond\' is a class definition from the file /octarisk/@Bond/Bond.m\n");
                fprintf("\n%s\n",retval);
                retval = [];
            end
        end

        
    end % end of static method help
    
   end  % end of static method
   
end 

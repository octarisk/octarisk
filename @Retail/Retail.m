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
         if strcmpi( b.sub_type,'SAVPLAN')
			fprintf('savings_rate: %f  %s\n',b.savings_rate,b.currency); 
			fprintf('redemption_values: %s\n',any2str(b.redemption_values)); 
			fprintf('redemption_dates: %s\n',any2str(b.redemption_dates)); 
			fprintf('savings_startdate: %s\n',any2str(b.savings_startdate)); 
			fprintf('savings_enddate: %s\n',any2str(b.savings_enddate)); 
			fprintf('notice_period: %s %s\n',any2str(b.notice_period),b.notice_period_unit); 
			fprintf('protection_scheme_limit: %s\n',any2str(b.protection_scheme_limit)); 
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
			fprintf('protection_scheme_limit: %s\n',any2str(b.protection_scheme_limit)); 
			fprintf('extra_payment_values: %s %s\n',any2str(b.extra_payment_values),b.currency); 
			fprintf('extra_payment_dates: %s\n',any2str(b.extra_payment_dates)); 
			fprintf('embedded_option_value: %s %s\n',any2str(b.embedded_option_value),b.currency); 
			fprintf('Breakeven rate redemption: %f %% %s %s\n',100* b.ytm,b.compounding_type,b.day_count_convention); 
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
         if ~(strcmpi(sub_type,'DCP') || strcmpi(sub_type,'SAVPLAN') )
            error('Retail sub_type must be either DCP, or SAVPLAN: %s',sub_type)
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
defined contribution pension plans.\n\
Cash flows are generated specific for each Retail sub type and subsequently\n\
discounted to calculate the Retail value.\n\
\n\
@itemize @bullet\n\
@item DCP: Defined contribution savings plan with guaranteed value at maturity and surrender value.\n\
@item SAVPLAN: Savings plan with optional bonus at maturity.\n\
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
@item obj.calc_value(@var{valuation_date},@var{scenario}, @var{discount_curve}, @var{call_schedule}, @var{put_schedule}):\n\
Calculate the net present value of cash flows of Bonds (including pricing of embedded options)\n\
\n\
@item obj.rollout(@var{scenario}, @var{valuation_date}): used for FRB and CASHFLOW  instruments\n\
@item obj.rollout(@var{scenario}, @var{valuation_date}, @var{reference_curve}, @var{vola_surface}): used for CMS_FLOATING or FRN_SPECIAL\n\
\n\
@item obj.calc_sensitivities(@var{valuation_date},@var{discount_curve}, @var{reference_curve})\n\
Calculate analytical and numerical sensitivities for the given Bond instrument.\n\
\n\
@item obj.calc_key_rates(@var{valuation_date},@var{discount_curve})\n\
Calculate key rate sensitivities for the given Bond instrument.\n\
\n\
@item obj.getValue(@var{scenario}): Return Bond value for given @var{scenario}.\n\
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
b = b.set('term',3,'term_unit','months','last_reset_rate',-0.0024,'sub_Type','FRN','spread',0.003);\n\
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
                fprintf("\'Bond\' is a class definition from the file /octarisk/@Bond/Bond.m\n");
                fprintf("\n%s\n",retval);
                retval = [];
            end
        end

        
    end % end of static method help
    
   end  % end of static method
   
end 

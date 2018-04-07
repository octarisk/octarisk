classdef CapFloor < Instrument
   
    properties   % All properties of Class CapFloor with default values
        issue_date = '01-Jan-1900';
        maturity_date = '';
        compounding_type = 'cont';
        compounding_freq = 1;  
        term = 12; 
        term_unit = 'months';   % can be [days,months,years]
        day_count_convention = 'act/365';
        notional = 0;                 
        coupon_generation_method = 'backward';
        business_day_rule = 0; 
        business_day_direction = 1;
        enable_business_day_rule = 0;
        spread = 0.0;       
        long_first_period = 0;  
        long_last_period = 0;   
        last_reset_rate = 0.00001;
        discount_curve = 'IR_EUR';
        reference_curve = 'IR_EUR';
        ir_shock   = 0.01;      % shock used for calculation of effective duration
        vola_shock = 0.0001;    % shock used for calculation of vega
        in_arrears = 0;
        notional_at_start = 0; 
        notional_at_end = 0;
        coupon_rate = 0.0;
        prorated = true; % Bool: true means deposit method 
        %  (adjust cash flows for leap year), false = bond method (fixed coupon)
                                %(mark to market) successful            
        vola_surface = 'RF_VOLA_IR_EUR';
        strike = 0.005;
        convex_adj = true;      % flag for using convex adj. for forward rates
        % attributes for CMS Floating and Fixed Legs
        cms_model               = 'Black'; % volatility model [Black, normal]
        cms_convex_model        = 'Hull'; % Model for calculating convexity adj.
        cms_sliding_term        = 1825; % sliding term of CMS float leg in days
        cms_sliding_term_unit   = 'days';   % can be [days,months,years]
        cms_term                = 365; % term of CMS
        cms_term_unit           = 'days';   % can be [days,months,years]
        cms_spread              = 0.0; % spread of CMS
        cms_comp_type           = 'simple'; % CMS compounding type
        vola_spread             = 0.0;
        % Inflation Linked bond specific attributes
        cpi_index               = ''; % Consumer Price Index
        infl_exp_curve          = ''; % Inflation Expectation Curve
        cpi_historical_curve    = ''; % Curve with historical values for CPI
        infl_exp_lag            = ''; % inflation expectation lag (in months)
        use_indexation_lag      = false; % Bool: true -> use infl_exp_lag
        calibration_flag = 1;       % BOOL: if true, no calibration will be done
    end
   
    properties (SetAccess = private)
        convexity = 0.0;
        eff_convexity = 0.0;
        dollar_convexity = 0.0;
        cf_dates = [];
        cf_values = [];
        cf_values_mc  = [];
        cf_values_stress = [];
        timestep_mc_cf = {};
        ytm = 0.0;
        soy = 0.0;      % spread over yield
        sub_type = 'CAP';
        mac_duration = 0.0;
        mod_duration = 0.0;
        eff_duration = 0.0;
        vega = 0.0;
        theta = 0.0;
        spread_duration = 0.0;
        dollar_duration = 0.0;
        dv01 = 0.0;
        pv01 = 0.0;
        accrued_interest = 0.0;
        basis = 3;
        model = 'Black';
        CapFlag = true;
    end

   methods
      function b = CapFloor(tmp_name)
        if nargin < 1
            name  = 'CAP_TEST';
            id    = 'CAP_TEST';           
        else
            name  = tmp_name;
            id    = name;
        end
        description = 'Cap test instrument';
        value_base = 1;      
        currency = 'EUR';
        asset_class = 'Derivative';   
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'capfloor',currency,value_base, ...
                        asset_class); 
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);      
         fprintf('issue_date: %s\n',b.issue_date);
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('strike: %f \n',b.strike);     
         fprintf('term: %d %s\n',b.term,b.term_unit);      
         fprintf('notional: %f \n',b.notional);  
         fprintf('notional_at_start: %d \n',b.notional_at_start);
         fprintf('notional_at_end: %d \n',b.notional_at_end);          
         fprintf('reference_curve: %s\n',b.reference_curve);  
         fprintf('vola_surface: %s\n',b.vola_surface ); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('compounding_type: %s\n',b.compounding_type);  
         fprintf('compounding_freq: %d\n',b.compounding_freq);    
         fprintf('day_count_convention: %s\n',b.day_count_convention); 
         fprintf('model: %s\n',b.model); 
         fprintf('convex_adj: %s\n',any2str(b.convex_adj)); 
         if ( regexpi(b.sub_type,'CMS'))
            fprintf('cms_model: %s\n',b.cms_model); 
            fprintf('cms_sliding_term: %s %s\n',any2str(b.cms_sliding_term), ...
                                                    b.cms_sliding_term_unit); 
            fprintf('cms_term: %s %s\n',any2str(b.cms_term),b.cms_term_unit); 
            fprintf('cms_spread: %s\n',any2str(b.cms_spread)); 
            fprintf('cms_comp_type: %s\n',b.cms_comp_type); 
            fprintf('cms_convex_model: %s\n',b.cms_convex_model); 
         end 
         if ( regexpi(b.sub_type,'INFL'))
            fprintf('cpi_index: %s\n',b.cpi_index); 
            fprintf('infl_exp_curve: %s\n',b.infl_exp_curve); 
            fprintf('cpi_historical_curve: %s\n',b.cpi_historical_curve); 
            fprintf('infl_exp_lag: %s\n',any2str(b.infl_exp_lag));
            fprintf('use_indexation_lag: %s\n',any2str(b.use_indexation_lag));
         end         
         fprintf('ir_shock: %f \n',b.ir_shock);
         fprintf('vola_spread: %f \n',b.vola_spread);
         fprintf('eff_duration: %f \n',b.eff_duration);
         fprintf('eff_convexity: %f \n',b.eff_convexity);
         fprintf('vega: %f \n',b.vega);
         fprintf('theta: %f \n',b.theta);
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
                fprintf('Scenariovalue:\n[ ')
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
         if ~(strcmpi(sub_type,'CAP') || strcmpi(sub_type,'FLOOR') ...
                || strcmpi(sub_type,'CAP_CMS') || strcmpi(sub_type,'FLOOR_CMS') ...
                || strcmpi(sub_type,'FLOOR_INFL') || strcmpi(sub_type,'CAP_INFL'))
            error('CapFloor sub_type must be either CAP(_CMS / _INFL), FLOOR(_CMS / _INFL)')
         end
         obj.sub_type = sub_type;
         if regexpi(sub_type,'CAP') 
            obj.CapFlag = true;
         else
            obj.CapFlag = false;
         end
      end % set.sub_type
      
      function obj = set.term_unit(obj,term_unit)
         if ~(strcmpi(term_unit,'days') || strcmpi(term_unit,'months') ...
                || strcmpi(term_unit,'years'))
            error('CapFloor term_unit must be in [days,months,years] : >>%s<< for id >>%s<<.\n',term_unit,obj.id);
         end
         obj.term_unit = tolower(term_unit);
      end % set.term_unit
      
      function obj = set.cms_term_unit(obj,cms_term_unit)
         if ~(strcmpi(cms_term_unit,'days') || strcmpi(cms_term_unit,'months') ...
                || strcmpi(cms_term_unit,'years'))
            error('CapFloor cms_term_unit must be in [days,months,years] : >>%s<< for id >>%s<<.\n',cms_term_unit,obj.id);
         end
         obj.cms_term_unit = tolower(cms_term_unit);
      end % set.cms_term_unit
      
      function obj = set.cms_sliding_term_unit(obj,cms_sliding_term_unit)
         if ~(strcmpi(cms_sliding_term_unit,'days') || strcmpi(cms_sliding_term_unit,'months') ...
                || strcmpi(cms_sliding_term_unit,'years'))
            error('CapFloor cms_sliding_term_unit must be in [days,months,years] : >>%s<< for id >>%s<<.\n',cms_sliding_term_unit,obj.id);
         end
         obj.cms_sliding_term_unit = tolower(cms_sliding_term_unit);
      end % set.cms_sliding_term_unit
      
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
   end 
   
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
            fprintf('WARNING: CapFloor.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
            format = 'plain text';
        end 

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} {@var{object}} = CapFloor(@var{id})\n\
@deftypefnx{Octarisk Class} {@var{object}} = CapFloor()\n\
\n\
Class for setting up CapFloor objects.\n\
Plain vanilla caps and floors (consisting of caplet and floorlets) can be based\n\
on interest rates or inflation rates. Cash flows are generated according to\n\
different models (Black, Normal, Analytic) and subsequently discounted to calculate\n\
the CapFloor value.\n\
\n\
@itemize @bullet\n\
@item CAP: Plain Vanilla interest rate cap. Valuation model either [\'black\',\'normal\',\'analytic\']\n\
@item FLOOR: Plain Vanilla interest rate floor. Valuation model either [\'black\',\'normal\',\'analytic\']\n\
@item CAP_CMS: CMS interest rate cap. Valuation model either [\'black\',\'normal\',\'analytic\']\n\
@item FLOOR_CMS: CMS interest rate floor. Valuation model either [\'black\',\'normal\',\'analytic\']\n\
@item CAP_INFL: Cap on inflation expectation rates (derived from inflation index values).\n\
Analytical model only (cash flow value based on difference of inflation rate and strike rate)\n\
@item FLOOR_INFL: Floor on inflation rates (derived from inflation index values).\n\
Analytical model only (cash flow value based on difference of inflation rate and strike rate)\n\
@end itemize\n\
\n\
In the following, all methods and attributes are explained and a code example is given.\n\
\n\
Methods for CapFloor object @var{obj}:\n\
@itemize @bullet\n\
@item CapFloor(@var{id}) or CapFloor(): Constructor of a CapFloor object. @var{id} is optional and specifies id and name of new object.\n\
\n\
@item obj.set(@var{attribute},@var{value}): Setter method. Provide pairs of attributes and values. Values are checked for format and constraints.\n\
\n\
@item obj.get(@var{attribute}): Getter method. Query the value of specified attribute.\n\
\n\
@item obj.calc_value(@var{valuation_date},@var{scenario}, @var{discount_curve}):\n\
Calculate the net present value of cash flows of Caps and Floors.\n\
\n\
@item obj.rollout(@var{valuation_date},@var{scenario}, @var{reference_curve}, @var{vola_surface}): used for (CMS) Caps and Floors\n\
@item obj.rollout(@var{valuation_date},@var{scenario}, @var{inflation_exp_rates}, @var{historical_inflation}, @var{consumer_price_index}): used for Inflation Caps and Floors\n\
Cash flow rollout for (Inflation) Caps and Floors.\n\
\n\
@item obj.calc_sensitivity(@var{valuation_date},@var{scenario},  @var{reference_curve}, @var{vola_surface}, @var{discount_curve})\n\
Calculate numerical sensitivities (durations, vega, theta) for the given CapFloor instrument.\n\
\n\
@item obj.calc_vola_spread(@var{valuation_date},@var{scenario}, @var{discount_curve}, @var{volatility_surface})\n\
Calibrate volatility spread in order to match the CapFloor price with the market price. The volatility spread will be used for further pricing.\n\
\n\
@item obj.getValue(@var{scenario}): Return CapFloor value for given @var{scenario}.\n\
Method inherited from Superclass @var{Instrument}\n\
\n\
@item CapFloor.help(@var{format},@var{returnflag}): show this message. Format can be [plain text, html or texinfo].\n\
If empty, defaults to plain text. Returnflag is boolean: True returns \n\
documentation string, false (default) returns empty string. [static method]\n\
@end itemize\n\
\n\
Attributes of CapFloor objects:\n\
@itemize @bullet\n\
@item @var{id}: Instrument id. Has to be unique identifier. (Default: empty string)\n\
@item @var{name}: Instrument name. (Default: empty string)\n\
@item @var{description}: Instrument description. (Default: empty string)\n\
@item @var{value_base}: Base value of instrument of type real numeric. (Default: 0.0)\n\
@item @var{currency}: Currency of instrument of type string. (Default: 'EUR')\n\
During instrument valuation and aggregation, FX conversion takes place if corresponding FX rate is available.\n\
@item @var{asset_class}: Asset class of instrument. (Default: 'derivative')\n\
@item @var{type}: Type of instrument, specific for class. Set to 'CapFloor'.\n\
@item @var{value_stress}: Line vector with instrument stress scenario values.\n\
@item @var{value_mc}: Line vector with instrument scenario values.\n\
MC values for several @var{timestep_mc} are stored in columns.\n\
@item @var{timestep_mc}: String Cell array with MC timesteps. If new timesteps are set, values are automatically appended.\n\
\n\
@item @var{model}: Valuation model for (CMS) Caps and Floors can be either [\'black\',\'normal\',\'analytic\'].\n\
Inflation Caps and Floors are valuated by analytical model only.\n\
@end itemize\n\
\n\
\n\
For illustration see the following example:\n\
A 2 year Cap starting in 3 years is priced with Black model.\n\
The resulting Cap value (137.0063959386) and volatility spread (-0.0256826614604929)is retrieved:\n\
@example\n\
@group\n\
\n\
disp('Pricing Cap Object with Black Model')\n\
cap = CapFloor();\n\
cap = cap.set('id','TEST_CAP','name','TEST_CAP','issue_date','30-Dec-2018', ...\n\
'maturity_date','29-Dec-2020','compounding_type','simple');\n\
cap = cap.set('term',365,'term_unit','days','notional',10000, ...\n\
'coupon_generation_method','forward','notional_at_start',0, ...\n\
'notional_at_end',0);\n\
cap = cap.set('strike',0.005,'model','Black','last_reset_rate',0.0, ...\n\
'day_count_convention','act/365','sub_type','CAP');\n\
c = Curve();\n\
c = c.set('id','IR_EUR','nodes',[30,1095,1460],'rates_base',[0.01,0.01,0.01], ...\n\
'method_interpolation','linear');\n\
v = Surface();\n\
v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90, ...\n\
'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');\n\
v = v.set('values_base',0.8);\n\
v = v.set('type','IRVol');\n\
cap = cap.rollout('31-Dec-2015','base',c,v);\n\
cap = cap.calc_value('31-Dec-2015','base',c);\n\
base_value = cap.getValue('base')\n\
cap = cap.set('value_base',135.000);\n\
cap = cap.calc_vola_spread('31-Dec-2015',c,v);\n\
cap = cap.rollout('31-Dec-2015','base',c,v);\n\
cap = cap.calc_value('31-Dec-2015','base',c);\n\
vola_spread = cap.vola_spread\n\
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
    
   end  % end of static method
end 

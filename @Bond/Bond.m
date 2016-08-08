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
        spot_value = 0.0;       
        in_arrears = 0;
        fixed_annuity = 0;      % property only needed for fixed amortizing bond 
               % -> fixed annuity annuity flag (annuity loan or amortizable loan) 
        notional_at_start = 0; 
        notional_at_end = 1;
        calibration_flag = 0;   % flag set to true, if calibration 
                                %(mark to market) successful
        % variables required for fixed amortizing bonds with prepayments
        prepayment_type          = 'full';  % ['full','default']
        prepayment_source        = 'curve'; % ['curve','rate']
        prepayment_flag          = false;   % toggle prepayment on and off
        prepayment_rate          = 0.00;    % constant prepayment rate in case
                                            % no prepayment curve is specified
        prepayment_curve         = 'PSA-BASE';  % specify prepayment curve
        clean_value_base = 0; % BOOL: value_base is clean without accr interest
    end
   
    properties (SetAccess = private)
        convexity = 0.0;
        eff_convexity = 0.0;
        basis = 3;
        cf_dates = [];
        cf_values = [];
        cf_values_mc  = [];
        cf_values_stress = [];
        ytm = 0.0;
        soy = 0.0;      % spread over yield
        sub_type = 'FRB';
        timestep_mc_cf = {};
        mac_duration = 0.0;
        mod_duration = 0.0;
        eff_duration = 0.0;
        dollar_duration = 0.0;
        dv01 = 0.0;
        accrued_interest = 0.0;
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
         %fprintf('cf_dates: %f\n',b.cf_dates); 
         %fprintf('cf_values: %f\n',b.cf_values); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('reference_curve: %s\n',b.reference_curve); 
         fprintf('spread_curve: %s\n',b.spread_curve); 
         fprintf('accrued_interest: %d\n',b.accrued_interest); 
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
         if ~(strcmpi(sub_type,'FRB') || strcmpi(sub_type,'FRN') ...
                || strcmpi(sub_type,'CASHFLOW') || strcmpi(sub_type,'FAB') ...
                || strcmpi(sub_type,'SWAP_FIXED') || strcmpi(sub_type,'SWAP_FLOATING') ...
                || strcmpi(sub_type,'ZCB'))
            error('Bond sub_type must be either FRB, FRN, CASHFLOW, SWAP_FIXED or SWAP_FLOATING: %s',sub_type)
         end
         obj.sub_type = sub_type;
      end % set.sub_type
      function obj = set.day_count_convention(obj,day_count_convention)
         obj.day_count_convention = day_count_convention;
         % Call superclass method to set basis
         obj.basis = Instrument.get_basis(obj.day_count_convention);
      end % set.day_count_convention
   end 
   
end 

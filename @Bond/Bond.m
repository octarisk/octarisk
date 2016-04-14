classdef Bond < Instrument
   
    properties   % All properties of Class Bond with default values
        issue_date = datestr(today);
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
        spread = 0.0;             
        long_first_period = 0;  
        long_last_period = 0;   
        last_reset_rate = 0.00001;
        discount_curve = 'RF_IF_EUR';
        reference_curve = 'RF_IF_EUR';
        spread_curve = 'RF_SPREAD_DUMMY';
        base_value = 0.0;       
        in_arrears = 0;
        fixed_annuity = 0;      % property only needed for fixed amortizing bond -> fixed annuity annuity flag (annuity loan or amortizable loan) 
        notional_at_start = 0; 
        notional_at_end = 1;             
    end
   
    properties (SetAccess = private)
        convexity = 0.0;
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
    end
   
   methods
      function b = Bond(name,id,description,sub_type,currency,base_value,asset_class,valuation_date,riskfactors,sensitivities,special_num,special_str,tmp_cf_dates,tmp_cf_values)
        if nargin < 12
           name = 'Dummy';
           id = 'Dummy';
           description = 'Test bond instrument for testing purposes';
           sub_type = 'FRB';
           currency = 'EUR';
           base_value = 100;
           asset_class = 'Fixed Income';
           riskfactors = {'RF_IR_DUMMY','RF_IR_DUMMY','RF_SPREAD_DUMMY'};
           sensitivities = [1,1,1];
           special_num = [100,0.00,12,0.0,0.0002,0];
           special_str = {'01-Feb-2011','01-Feb-2025','forward','simple','30/360'};
           tmp_cf_dates = [];
           tmp_cf_values = [];
           valuation_date = today;
        elseif( nargin == 12)
           tmp_cf_dates = [];
           tmp_cf_values = [];
        elseif ( nargin == 14)
            if ( length(tmp_cf_dates) > 0 )
                tmp_cf_dates = (tmp_cf_dates)' .- valuation_date;
            endif
        end
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'bond',currency,base_value,asset_class,valuation_date);
        % setting property sub_type
        if ( strcmp(sub_type,'') )
            error("Error: No sub_type specified");
        else
            b.sub_type = sub_type;
        endif
        if ( strcmp(sub_type,'CASHFLOW') == 0 ) % special case CASHFLOW instrument -> no informatio needed
            % setting property issue_date
            if ( length(special_str) >= 1 )
                if ( !strcmp(special_str{1},'') )
                    b.issue_date =  datestr(special_str{1});
                endif
            endif
            % setting property maturity_date
            if ( length(special_str) < 2 )
                error("Error: No maturity date specified");
            else
                b.maturity_date = datestr(special_str{2});
            endif  
            % setting property compounding_type
            if ( length(special_str) >= 4  )
                b.compounding_type = tolower(special_str{4});
            endif
            % setting property term and compounding_freq
            if ( length(special_num) < 3  )
                error("Error: No term specified");
            else
                b.term = special_num(3);
                b.compounding_freq = 12 / b.term;
            endif
            % setting property day_count_convention
            if ( length(special_str) >= 5  )
                b.day_count_convention = special_str{5};
            endif
            % setting property coupon_generation_method 
            if ( length(special_str) >= 3  )
                b.coupon_generation_method  = tolower(special_str{3});
            endif      
            % setting property notional
            if ( length(special_num) < 1  )
                error("Error: No notional specified");
            else
                b.notional = special_num(1);  
            endif
            % setting property coupon_rate
            if ( length(special_num) < 2  )
                error("Error: No coupon_rate specified");
            else
                b.coupon_rate = special_num(2);  
            endif 
            % setting property enable_business_day_rule
            if ( length(special_num) >= 6  )
                b.enable_business_day_rule = special_num(6);
            endif
            % setting property business_day_rule
            if ( length(special_num) >= 7  )
                b.business_day_rule = special_num(7);
            endif
            % setting property business_day_direction
            if ( length(special_num) >= 8  )
                b.business_day_direction = special_num(8);
            endif
            % setting property notional_at_start
            if ( length(special_num) >= 8  )
                b.notional_at_start= special_num(8);
            endif
            % setting property notional_at_end
            if ( length(special_num) >= 9  )
                b.notional_at_end = special_num(9);
            endif
            % setting property in_arrears_flag
            if ( length(special_num) >= 10  )
                b.in_arrears = special_num(10);
            endif
            % setting property fixed_annuity
            if ( length(special_num) >= 11  )
                b.fixed_annuity = special_num(11);
            endif
            % setting property spread
            if ( length(special_num) >= 4  )
                b.spread = special_num(4);
            endif
            % setting property long_first_period
            if ( length(special_str) >= 6  )
                b.long_first_period = special_str{6};
            endif    
            % setting property long_last_period
            if ( length(special_str) >= 7  )
                b.long_last_period = special_str{7};
            endif 
            % setting property last_reset_rate
            if ( length(special_num) >= 5 )
                b.last_reset_rate = special_num(5);
            endif
        endif
        % setting property discount_curve
        if ( length(riskfactors) < 1  )
            error("Error: No discount_curve specified");
        else
            b.discount_curve = riskfactors{1};
        endif
        % setting property reference_curve
        if ( length(riskfactors) >= 2  )
            b.reference_curve = riskfactors{2};
        endif
        % setting property spread_curve
        if ( length(riskfactors) >= 3 )
            b.spread_curve = riskfactors{3};
        endif
        b.cf_dates = tmp_cf_dates;
        b.cf_values = tmp_cf_values;
        
        % Call static methods
        %b.base_value = Bond.calc_value(b.notional,b.coupon_rate);
        % Call superclass method to set basis
        b.basis = Instrument.get_basis(b.day_count_convention);
      end 
      
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
         fprintf('Notional: %f %s\n',b.notional,b.currency); 
         fprintf('coupon_rate: %f\n',b.coupon_rate);  
         fprintf('coupon_generation_method: %s\n',b.coupon_generation_method ); 
         fprintf('business_day_rule: %d\n',b.business_day_rule); 
         fprintf('business_day_direction: %d\n',b.business_day_direction); 
         fprintf('enable_business_day_rule: %d\n',b.enable_business_day_rule); 
         fprintf('spread: %f\n',b.spread); 
         fprintf('long_first_period: %d\n',b.long_first_period); 
         fprintf('long_last_period: %d\n',b.long_last_period);  
         fprintf('last_reset_rate: %f\n',b.last_reset_rate); 
         %fprintf('cf_dates: %f\n',b.cf_dates); 
         %fprintf('cf_values: %f\n',b.cf_values); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('reference_curve: %s\n',b.reference_curve); 
         fprintf('spread_curve: %s\n',b.spread_curve); 
         %fprintf('base_value: %f\n',b.base_value);
         % display all mc values and cf values
         cf_stress_rows = min(rows(b.cf_values_stress),5);
         [mc_rows mc_cols mc_stack] = size(b.cf_values_mc);
         % looping via all cf_dates if defined
         if ( length(b.cf_dates) > 0 )
            fprintf('CF dates:\n[ ');
            for (ii = 1 : 1 : length(b.cf_dates))
                fprintf('%d,',b.cf_dates(ii));
            endfor
            fprintf(' ]\n');
         endif
         % looping via all cf base values if defined
         if ( length(b.cf_values) > 0 )
            fprintf('CF Base values:\n[ ');
            for ( kk = 1 : 1 : min(columns(b.cf_values),10))
                    fprintf('%f,',b.cf_values(kk));
                endfor
            fprintf(' ]\n');
         endif   
          % looping via all stress rates if defined
         if ( rows(b.cf_values_stress) > 0 )
            tmp_cf_values = b.getCF('stress');
            fprintf('CF Stress values:\n[ ');
            for ( jj = 1 : 1 : min(rows(tmp_cf_values),5))
                for ( kk = 1 : 1 : min(columns(tmp_cf_values),10))
                    fprintf('%f,',tmp_cf_values(jj,kk));
                endfor
                fprintf(' ]\n');
            endfor
            fprintf('\n');
         endif    
         % looping via first 3 MC scenario values
         for ( ii = 1 : 1 : mc_stack)
            if ( length(b.timestep_mc_cf) >= ii )
                fprintf('MC timestep: %s\n',b.timestep_mc_cf{ii});
                tmp_cf_values = b.getCF(b.timestep_mc_cf{ii});
                fprintf('Scenariovalue:\n[ ')
                for ( jj = 1 : 1 : min(rows(tmp_cf_values),5))
                    for ( kk = 1 : 1 : min(columns(tmp_cf_values),10))
                        fprintf('%f,',tmp_cf_values(jj,kk));
                    endfor
                    fprintf(' ]\n');
                endfor
                fprintf('\n');
            else
                fprintf('MC timestep cf not defined\n');
            endif
         endfor

      end
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'FRB') || strcmpi(sub_type,'FRN') || strcmpi(sub_type,'CASHFLOW') || strcmpi(sub_type,'FAB') || strcmpi(sub_type,'SWAP_FIXED') || strcmpi(sub_type,'SWAP_FLOATING') || strcmpi(sub_type,'ZCB'))
            error('Bond sub_type must be either FRB, FRN, CASHFLOW, SWAP_FIXED or SWAP_FLOATING: %s',sub_type)
         end
         obj.sub_type = sub_type;
      end % set.sub_type
   end 
   
   methods (Static = true)
      function market_value = calc_value_tmp(notional,coupon_rate)
            market_value = notional .* coupon_rate;
      end 
      
   end
end 

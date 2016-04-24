classdef Swaption < Instrument
   
    properties   % All properties of Class Swaption with default values
        maturity_date = '';
        compounding_type = 'disc';
        compounding_freq = 1;               
        day_count_convention = 'act/365';
        spread = 0.0;             
        discount_curve = 'RF_IF_EUR';
        underlying = 'RF_IF_EUR';
        vola_surface = 'RF_VOLA_IR_EUR';
        vola_sensi = 1;
        strike = 0.025;
        spot = 0.025;
        multiplier = 100;
        tenor = 10;
        no_payments = 1;
    end
   
    properties (SetAccess = private)
        basis = 3;
        cf_dates = [];
        cf_values = [];
        vola_surf = [];
        vola_surf_mc  = [];
        vola_surf_stress = [];
        vola_spread = 0.0;
        sub_type = 'SWAPT_EUR_PAY';
        model = 'BLACK76';
    end

   methods
      function b = Swaption(name,id,description,sub_type,currency,base_value,asset_class,valuation_date,riskfactors,sensitivities,special_num,special_str,tmp_cf_dates,tmp_cf_values)
        if nargin < 12
           name = 'SWAPTIONC20161217';
           id = 'SWAPTIONC20161217';
           description = 'Payer Swaption on EUR Rate for testing purposes';
           sub_type = 'SWAPT_EUR_PAY';
           currency = 'EUR';
           base_value = 7.5;
           asset_class = 'Derivative';
           riskfactors = {'RF_VOLA_IR_EUR','RF_IR_EUR','STRIKE','RF_IR_EUR','TENOR','NO_PAYMENTS'};
           sensitivities = [1,0.025,0.025,0.0,10,1];
           special_num = [100,1];
           special_str = {'18-Mar-2018','disc','30/360','BLACK76'};
           tmp_cf_dates = [];
           tmp_cf_values = [];
           valuation_date = today;
        elseif( nargin == 12)
           tmp_cf_dates = [];
           tmp_cf_values = [];
        elseif ( nargin == 14)
            if ( length(tmp_cf_dates) > 0 )
                tmp_cf_dates = (tmp_cf_dates)' .- today;
            endif
        end
        % use constructor inherited from Class Instrument
        b = b@Instrument(name,id,description,'swaption',currency,base_value,asset_class,valuation_date);
        % setting property sub_type
        if ( strcmp(sub_type,'') )
            error('Error: No sub_type specified');
        else
            b.sub_type = sub_type;
        endif

        % setting property maturity_date
        if ( length(special_str) >= 1 )
            if ( !strcmp(special_str{1},'') )
                b.maturity_date =  datestr(special_str{1});
            endif
        endif

        % parsing attribute special_str
            % setting property compounding_type
            if ( length(special_str) >= 2  )
                b.compounding_type = tolower(special_str{2});
            endif

            % setting property day_count_convention
            if ( length(special_str) >= 3  )
                b.day_count_convention = special_str{3};
            endif
            
            % setting property model
            if ( length(special_str) >= 4  )
                b.model = toupper(special_str{4});
            endif
 
        % parsing attribute special_num
            % setting property multiplier
            if ( length(special_num) >= 1  )
                b.multiplier = special_num(1);  
            endif
            % setting property compounding_freq
            if ( length(special_num) >= 2  )
                b.compounding_freq = special_num(2);  
            endif 

        % parsing attribute sensitivities
            % setting property vola_sensi
            if ( length(sensitivities) < 1  )
                error('Error: No vola_sensi specified');
            else
                b.vola_sensi = sensitivities(1);
            endif        
            % setting property spot
            if ( length(sensitivities) < 2  )
                error('Error: No spot specified');
            else
                b.spot = sensitivities(2);
            endif       
            % setting property strike
            if ( length(sensitivities) < 3  )
                error('Error: No strike specified');
            else
                b.strike = sensitivities(3);
            endif
            % setting property spread
            if ( length(sensitivities) >= 4  )
                b.spread = sensitivities(4);
            endif
            % setting property tenor
            if ( length(sensitivities) < 5  )
                error('Error: No tenor specified');
            else
                b.tenor = sensitivities(5);
            endif
            % setting property no_payments
            if ( length(sensitivities) < 6  )
                error('Error: No no_payments specified');
            else
                b.no_payments = sensitivities(6);
            endif

        % parsing attribute riskfactors
            % setting property vola surface
            if ( length(riskfactors) < 1  )
                error('Error: No vola_surface specified');
            else
                b.vola_surface = riskfactors{1};
            endif
             % setting property underlying
            if ( length(riskfactors) < 2  )
                error('Error: No underlying specified');
            else
                b.underlying = riskfactors{2};
            endif
             % setting property discount_curve
            if ( length(riskfactors) < 4  )
                error('Error: No discount_curve specified');
            else
                b.discount_curve = riskfactors{4};
            endif
        b.cf_dates = tmp_cf_dates;
        b.cf_values = tmp_cf_values;
        
        % Call static superclass method to set basis
        b.basis = Instrument.get_basis(b.day_count_convention);
      end 
      
      function disp(b)
         disp@Instrument(b)
         fprintf('sub_type: %s\n',b.sub_type);                   
         fprintf('maturity_date: %s\n',b.maturity_date);      
         fprintf('spot: %f \n',b.spot); 
         fprintf('strike: %f \n',b.strike);
         fprintf('multiplier: %f \n',b.multiplier);         
         fprintf('underlying: %s\n',b.underlying);  
         fprintf('vola_surface: %s\n',b.vola_surface ); 
         fprintf('discount_curve: %s\n',b.discount_curve); 
         fprintf('spread: %f\n',b.spread); 
         fprintf('tenor: %f\n',b.tenor); 
         fprintf('no_payments: %f\n',b.no_payments); 
         fprintf('vola_sensi: %f\n',b.vola_sensi); 
         fprintf('compounding_type: %s\n',b.compounding_type);  
         fprintf('compounding_freq: %d\n',b.compounding_freq);    
         fprintf('day_count_convention: %s\n',b.day_count_convention); 
         fprintf('model: %s\n',b.model); 
         %fprintf('base_value: %f\n',b.base_value);
         % % display all mc values and cf values
         % cf_stress_rows = min(rows(b.cf_values_stress),5);
         % [mc_rows mc_cols mc_stack] = size(b.cf_values_mc);
         % % looping via all cf_dates if defined
         % if ( length(b.cf_dates) > 0 )
            % fprintf('CF dates:\n[ ');
            % for (ii = 1 : 1 : length(b.cf_dates))
                % fprintf('%d,',b.cf_dates(ii));
            % endfor
            % fprintf(' ]\n');
         % endif
         % % looping via all cf base values if defined
         % if ( length(b.cf_values) > 0 )
            % fprintf('CF Base values:\n[ ');
            % for ( kk = 1 : 1 : min(columns(b.cf_values),10))
                    % fprintf('%f,',b.cf_values(kk));
                % endfor
            % fprintf(' ]\n');
         % endif   
          % % looping via all stress rates if defined
         % if ( rows(b.cf_values_stress) > 0 )
            % tmp_cf_values = b.getCF('stress');
            % fprintf('CF Stress values:\n[ ');
            % for ( jj = 1 : 1 : min(rows(tmp_cf_values),5))
                % for ( kk = 1 : 1 : min(columns(tmp_cf_values),10))
                    % fprintf('%f,',tmp_cf_values(jj,kk));
                % endfor
                % fprintf(' ]\n');
            % endfor
            % fprintf('\n');
         % endif    
         % % looping via first 3 MC scenario values
         % for ( ii = 1 : 1 : mc_stack)
            % if ( length(b.timestep_mc_cf) >= ii )
                % fprintf('MC timestep: %s\n',b.timestep_mc_cf{ii});
                % tmp_cf_values = b.getCF(b.timestep_mc_cf{ii});
                % fprintf('Scenariovalue:\n[ ')
                % for ( jj = 1 : 1 : min(rows(tmp_cf_values),5))
                    % for ( kk = 1 : 1 : min(columns(tmp_cf_values),10))
                        % fprintf('%f,',tmp_cf_values(jj,kk));
                    % endfor
                    % fprintf(' ]\n');
                % endfor
                % fprintf('\n');
            % else
                % fprintf('MC timestep cf not defined\n');
            % endif
         % endfor

      end
      % converting object <-> struct for saving / loading purposes
      % function b = saveobj (a)
          % disp('Converting object to struct');
          % b = struct(a);       
      % end
      function b = loadobj (t,a)
          disp('Converting stuct to object');
          b = Option();
          b.id          = a.id;
          b.name        = a.name; 
          b.description = a.description;  
          b = b.set('timestep_mc',a.timestep_mc);
          b = b.set('value_mc',a.value_mc);
          b.spot            = a.spot;
          b.strike          = a.strike;
          b.maturity_date   = a.maturity_date;
          b.discount_curve  = a.discount_curve;
          b.compounding_type = a.compounding_type;
          b.compounding_freq = a.compounding_freq;               
          b.day_count_convention = a.day_count_convention;
          b.spread          = a.spread;             
          b.underlying      = a.underlying;
          b.vola_surface    = a.vola_surface;
          b.vola_sensi      = a.vola_sensi;
          b.tenor           = a.tenor;
          b.no_payments     = a.no_payments;
          b.multiplier      = a.multiplier;
          b.basis           = a.basis;
          b.cf_dates        = a.cf_dates;
          b.cf_values       = a.cf_values;
          b.vola_surf       = a.vola_surf;
          b.vola_surf_mc    = a.vola_surf_mc;
          b.vola_surf_stress = a.vola_surf_stress;
          b.vola_spread     = a.vola_spread;
          b.sub_type        = a.sub_type;
      end  
      function obj = set.sub_type(obj,sub_type)
         if ~(strcmpi(sub_type,'SWAPT_EUR_REC') || strcmpi(sub_type,'SWAPT_EUR_PAY') )
            error('Swaption sub_type must be either SWAPT_EUR_REC, SWAPT_EUR_PAY')
         end
         obj.sub_type = sub_type;
      end % set.sub_type
   end 
   
   methods (Static = true)  % this has no meaning, just placeholder if static methods required in future
      function market_value = calc_value_tmp(notional,coupon_rate)
            market_value = notional .* coupon_rate;
      end       
   end
end 
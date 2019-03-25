% @Position/calc_risk.m: Calculate risk figures based on pre-aggregated portfolio / position values
function obj = calc_risk (obj, scen_set, para)
    if ~(nargin == 3)
        print_usage ();
    end

    if ( regexp(scen_set,'stress'))
        %
    elseif ( strcmpi(scen_set,'base'))
        %
    else % calculate VaR risk figures
        no_scen = para.mc;
        if ( strcmpi(obj.type,'PORTFOLIO'))
          
          base_value = obj.getValue('base');
          pnl_abs = obj.getValue(scen_set) .- base_value;
          tt = 1:1:no_scen;
          confi = 1 - para.quantile;
          confi_scenario = max(round(confi * no_scen),1);
          hd_vec  = get_quantile_estimator(para.quantile_estimator, no_scen, ...
                                    tt,confi,para.quantile_bandwidth);

          
          %  i.) sort arrays
          pnl_relative = pnl_abs ./ base_value;
          [pnl_abs_sorted scen_order_shock] = sort(pnl_abs);

          % ii.) Get Value of confidence scenario
          confi_scenarionumber_shock = scen_order_shock(confi_scenario);
          skewness_shock           = skewness(pnl_relative);
          kurtosis_shock           = kurtosis(pnl_relative);
          fprintf('Scenarionumber according to confidence intervall: %d\n',confi_scenarionumber_shock);
          fprintf('MC scenarios portfolio skewness: %2.2f\n',skewness_shock);
          fprintf('MC scenarios portfolio kurtosis: %2.2f\n',kurtosis_shock);

          % iii.) Extract confidence scenarionumbers around quantile scenario
          confi_scenarionumber_shock_p1 = scen_order_shock(confi_scenario + 1);
          confi_scenarionumber_shock_p2 = scen_order_shock(confi_scenario + 2);
          confi_scenarionumber_shock_m1 = scen_order_shock(confi_scenario - 1);
          confi_scenarionumber_shock_m2 = scen_order_shock(confi_scenario - 2);
          scenario_numbers = [confi_scenarionumber_shock_m2, ...
                            confi_scenarionumber_shock_m1, ...
                            confi_scenarionumber_shock, ...
                            confi_scenarionumber_shock_p1, ...
                            confi_scenarionumber_shock_p2]
          
          % iv.) make vector with Harrel-Davis Weights
          varhd_abs     = - dot(hd_vec,pnl_abs_sorted);
          varhd_rel     = dot(hd_vec,sort(pnl_relative));
          var_abs       = - pnl_abs_sorted(confi_scenario);
          var_diff_hd   = abs(var_abs - varhd_abs);

          % d) Calculate Expected Shortfall as average of losses in sorted profit and loss vector from [1:confi_scenario-1]:
          expshortfall_abs      = - mean(pnl_abs_sorted(1:confi_scenario-1))
          expshortfall_rel      = - expshortfall_abs ./ base_value
          % var_positionsum       = 
          % diversification_ratio = 

          % % sum up position standalone VaRs
          % for (ii=1:1:length(obj.positions))
            % pos_obj = obj.positions(ii).object;
            % pos_id = obj.positions(ii).id
            % if (isobject(pos_obj))
                % pos_value = pos_obj.getValue(scen_set);
                % pos_currency = pos_obj.get('currency');
            % end
          % end
        elseif ( strcmpi(obj.type,'POSITION'))
          tmp_id = obj.id;
          tmp_quantity = obj.quantity;
          try
            [tmp_instr_object object_ret_code]  = get_sub_object(instrument_struct, tmp_id);
            if ( object_ret_code == 0 )
                error('octarisk: WARNING: No instrument_struct object found for id >>%s<<\n',tmp_id);
            end 
            tmp_value = tmp_instr_object.getValue('base');
            tmp_currency = tmp_instr_object.get('currency');        
            
            % Get FX rate:
            if ( strcmp(obj.currency,tmp_currency) == 1 )
                tmp_fx_value_shock   = 1;
                tmp_fx_rate_base = 1;
            else
                tmp_fx_index        = strcat('FX_', obj.currency, tmp_currency);
                [tmp_fx_struct_obj object_ret_code]  = get_sub_object(index_struct, tmp_fx_index);
                if ( object_ret_code == 0 )
                    error('WARNING: No index_struct object found for FX id >>%s<<\n',tmp_fx_index);
                end 
                tmp_fx_rate_base    = tmp_fx_struct_obj.getValue('base');
                tmp_fx_value_shock  = tmp_fx_struct_obj.getValue(scen_set);   
            end
            
            % Fill base and scenario values
            if (strcmpi(scen_set,'base'))       
                theo_value = tmp_value .* tmp_quantity ./ tmp_fx_rate_base;
            elseif (strcmpi(scen_set,'stress'))  % Stress scenario set
                % Store new Values in Position's struct
                theo_value  = tmp_instr_object.getValue(scen_set) .*  tmp_quantity ./ tmp_fx_value_shock;
            else    % MC scenario set
                % Store new MC Values in Position's struct
                theo_value   = tmp_instr_object.getValue(scen_set) .* tmp_quantity ./ tmp_fx_value_shock; % convert position PnL into fund currency
            end
             
          catch   % if instrument not found raise warning and populate cell
            fprintf('Instrument ID %s not found for position. There was an error: %s\n',tmp_id,lasterr);
          end
        
      else
        fprintf('Unknown type >>%s<<. Neither position nor portfolio\n',any2str(obj.type));
      end
    end
    
    % store theo_value vector
    if ( regexp(scen_set,'stress'))
        % obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(scen_set,'base'))
        % obj = obj.set('value_base',theo_value(1)); 
        % if ( strcmpi(obj.type,'PORTFOLIO'))
            % obj.tpt_5 = theo_value; 
        % elseif ( strcmpi(obj.type,'POSITION'))
            % obj.tpt_22 = theo_value; 
        % end  
    else
        obj = obj.set('varhd_abs',varhd_abs);
        obj = obj.set('var_confidence',para.quantile);
        obj = obj.set('var_abs',var_abs);
        obj = obj.set('varhd_rel',varhd_rel);
        obj = obj.set('expshortfall_abs',expshortfall_abs);
        obj = obj.set('scenario_numbers',scenario_numbers);
    end
    
    % TODO:
    % calculate VaR(HD) based on para set
    % calculate sum of standalones
    % calculate diversification effect
end
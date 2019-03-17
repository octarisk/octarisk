% @Position/aggregate.m: Aggregate all positions (to portfolio) or instruments to position
function obj = aggregate (obj, scen_set, instrument_struct, index_struct)
    if ~(nargin == 4)
        print_usage ();
    end
      
    if ( strcmpi(obj.type,'PORTFOLIO'))
        theo_value = 0.0;
        for (ii=1:1:length(obj.positions))
            pos_obj = obj.positions(ii).object;
            pos_id = obj.positions(ii).id
            if (isobject(pos_obj))
                % Preaggregate position object
                pos_obj_new = pos_obj.aggregate(scen_set, instrument_struct, index_struct);
                pos_value = pos_obj_new.getValue(scen_set);
                pos_currency = pos_obj_new.get('currency');
                % Get FX rate:
                if ( strcmp(obj.currency,pos_currency) == 1 )
                    tmp_fx_rate = 1;
                else
                    tmp_fx_index        = strcat('FX_', obj.currency, pos_currency);
                    [tmp_fx_struct_obj object_ret_code]  = get_sub_object(index_struct, tmp_fx_index);
                    if ( object_ret_code == 0 )
                        error('WARNING: No index_struct object found for FX id >>%s<<\n',tmp_fx_index);
                    end 
                    tmp_fx_rate  = tmp_fx_struct_obj.getValue(scen_set);   
                end
                % Fill base and scenario values    
                theo_value = theo_value + pos_value ./ tmp_fx_rate;
            end
        end
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
            
            % Fill Tripartite template
            if (strcmpi(scen_set,'base')) 
                % Duration
                if (tmp_instr_object.isProp('mod_duration'))
                    obj.TPT_90 = tmp_instr_object.get('mod_duration');
                elseif (tmp_instr_object.isProp('duration'))
                    obj.TPT_90 = tmp_instr_object.get('duration');
                end
            end   
        catch   % if instrument not found raise warning and populate cell
            fprintf('Instrument ID %s not found for position. There was an error: %s\n',tmp_id,lasterr);
        end
        
    else
        fprintf('Unknown type >>%s<<. Neither position nor portfolio\n',any2str(obj.type));
    end

    % store theo_value vector
    if ( regexp(scen_set,'stress'))
        obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(scen_set,'base'))
        obj = obj.set('value_base',theo_value(1)); 
        if ( strcmpi(obj.type,'PORTFOLIO'))
            obj.TPT_5 = theo_value; 
        elseif ( strcmpi(obj.type,'POSITION'))
            obj.TPT_22 = theo_value; 
        end  
    else
        obj = obj.set('timestep_mc',scen_set);
        obj = obj.set('value_mc',theo_value);
    end
    
    % TODO:
    % calculate VaR(HD) based on para set
    % calculate sum of standalones
    % calculate diversification effect
end
% @Synthetic method calc_value
function obj = calc_value(synthetic,valuation_date,value_type,instrument_struct,index_struct)
obj = synthetic;
if ( nargin < 4)
    error('Error: No  instrument_struct with underlying instrument and index_struct for FX rates given. Aborting.');
end
   
% get values of underlying instrument and weigh them by their sensitivity
tmp_value_base      = 0;
tmp_value           = 0;
tmp_weights         = obj.get('weights');
tmp_instruments     = obj.get('instruments');
tmp_currency        = obj.get('currency');
% summing up values over all underlying instruments
for jj = 1 : 1 : length(tmp_weights)
    % get underlying instrument:
    tmp_underlying              = tmp_instruments{jj};
    % 1st try: find underlying in instrument_struct
    [und_obj  object_ret_code]  = get_sub_object(instrument_struct, tmp_underlying);
    if ( object_ret_code == 0 )
        % 2nd try: find underlying in index struct
        [und_obj  object_ret_code_new]  = get_sub_object(index_struct, tmp_underlying);
        if ( object_ret_code_new == 0 )
            fprintf('octarisk: WARNING: No instrument_struct object found for id >>%s<<\n',tmp_underlying);
        end
    end
    % Get instrument Value from full valuation instrument_struct:
    % absolute values from full valuation
    underlying_value_base       = und_obj.getValue('base');                 
    underlying_value_vec        = und_obj.getValue(value_type);  
    % Get FX rate:
    tmp_underlying_currency = und_obj.get('currency'); 
    if ( strcmp(tmp_underlying_currency,tmp_currency) == 1 )
        tmp_fx_rate_base    = 1;
        tmp_fx_value        = 1; %ones(scen_number,1);
    else
        %Conversion of currency:;
        tmp_fx_index = strcat('FX_', tmp_currency, tmp_underlying_currency);
        tmp_fx_struct_obj = get_sub_object(index_struct, tmp_fx_index);
        tmp_fx_rate_base  = tmp_fx_struct_obj.getValue('base');
        tmp_fx_value      = tmp_fx_struct_obj.getValue(value_type);
    end
    tmp_value_base      = tmp_value_base    + tmp_weights(jj) .* underlying_value_base ./ tmp_fx_rate_base;
    tmp_value           = tmp_value      + tmp_weights(jj) .* underlying_value_vec ./ tmp_fx_value;
end

% store values in sensitivity object:
if ( strcmpi(value_type,'base'))
    obj = obj.set('value_base',tmp_value_base);
elseif ( strcmpi(value_type,'stress'))
    obj = obj.set('value_stress',tmp_value);
else                    
    obj = obj.set('value_mc',tmp_value,'timestep_mc',value_type);
end
    
   
end



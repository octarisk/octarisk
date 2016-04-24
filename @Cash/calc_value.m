% @Cash/calc_value.m
function obj = calc_value (cash,value_type,scen_number)
  obj = cash;
  if ( nargin < 3 )
    error('No scenario number provided. Aborting.');
  end

    value_type = tolower(value_type);
    % Get base value
        theo_value_base = obj.get('value_base');    
        theo_value      = theo_value_base .* ones(scen_number,1);      
    % store theo_value vector in appropriate class property
    if ( regexp(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(value_type,'base'))
        obj = obj.set('value_base',theo_value_base);
    else
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
   
end



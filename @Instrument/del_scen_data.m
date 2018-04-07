% Instrument Class @Instrument
function obj = del_scen_data (obj)
    obj.timestep_mc = {};
    obj.value_mc = [];
    obj.value_stress = [];
    if ( obj.isProp('cf_values_stress'))
        obj = obj.set('cf_values_stress',[]);
    end
    if ( obj.isProp('cf_values_mc'))
        obj = obj.set('cf_values_mc',[]);
    end
    if ( obj.isProp('timestep_mc_cf'))
        obj = obj.set('timestep_mc_cf',{});
    end
end
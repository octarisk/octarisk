% Instrument Class method .valuate: valuation of instruments according to type 
function obj = valuate (instrument, valuation_date, scenario, ...
                    instrument_struct, surface_struct, matrix_struct, ...
                    curve_struct, index_struct, riskfactor_struct, para_struct)
 
if (nargin < 9)
    print_usage();
end

if (nargin < 10)
    % set default parameter   
    % Fallback: get scenario number from first curve object
    para_struct = struct();
    tmp_curve_object = curve_struct(1).object;
    scen_number = length(tmp_curve_object.getValue(scenario));
    para_struct.scen_number = scen_number;
    
    para_struct.path_static = '';
    para_struct.timestep = 1;
    para_struct.first_eval = 1; 
end

% call instrument_valuation script

[obj] = instrument_valuation(instrument, valuation_date, scenario, ...
                    instrument_struct, surface_struct, matrix_struct, ...
                    curve_struct, index_struct, riskfactor_struct, para_struct);
                                    
end
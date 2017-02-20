% Instrument Class method .valuate: valuation of instruments according to type 
function obj = valuate (instrument, valuation_date, scenario, ...
                    instrument_struct, surface_struct, matrix_struct, ...
                    curve_struct, index_struct, riskfactor_struct, para_struct)
 
if (nargin < 9)
    print_usage();
end

if (nargin < 10)
    % set default parameter   
    % Fallback: get scenario number from first curve, riskfactor or index object
    para_struct = struct();
	if ~(isempty(curve_struct))
		tmp_object = curve_struct(1).object;
	elseif ~(isempty(riskfactor_struct))
		tmp_object = riskfactor_struct(1).object;
	elseif ~(isempty(index_struct))
		tmp_object = index_struct(1).object;
	else
		error('instrument.valuate: Provide para_struct.\n');
	end

	scen_number = length(tmp_object.getValue(scenario));
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
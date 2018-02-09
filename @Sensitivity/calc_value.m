% @Sensitivity method calc_value
function obj = calc_value(sensi,valuation_date,scenario,riskfactor_struct,instrument_struct,index_struct,curve_struct,surface_struct,scen_number)
obj = sensi;
if ( nargin < 8) && strcmpi(obj.sub_type,'SENSI')
    error('Error: Sensitivity valuation requires valuation_date,scenario,riskfactor_struct,instrument_struct,index_struct,curve_struct,surface_struct');
elseif ( nargin < 4) &&  sum(strcmpi(sub_type,{'EQU','RET','COM','STK','ALT'}) > 0)
	error('Error: Sensitivity valuation requires valuation_date,scenario,riskfactor_struct');
end
 

%=============================================================================== 
% valuation for 'EQU','RET','COM','STK','ALT' (linear combinations of risk factor shocks)
if ( sum(strcmpi(sensi.sub_type,{'EQU','RET','COM','STK','ALT'}) > 0))
	tmp_delta = 0;
	tmp_shift = 0;
    tmp_sensitivities   = sensi.sensitivities;
    tmp_riskfactors     = sensi.riskfactors;
	% get timestep from scenarios
	if ~( strcmpi(scenario,{'base','stress'}))
		if ( strcmpi(scenario(end),'d') )
			tmp_ts = str2num(scenario(1:end-1));  % get timestep days
		elseif ( strcmp(to_lower(scenario(end)),'y'))
			tmp_ts = 365 * str2num(scenario(1:end-1));  % get timestep days
		else
			error('Unknown number of days in timestep: %s\n',scenario);
		end
	end
	% loop through all risk factor and combine linear shocks
    for jj = 1 : 1 : length(tmp_sensitivities)
        % get riskfactor:
        tmp_riskfactor = tmp_riskfactors{jj};
        % get idiosyncratic risk: normal distributed random variable with stddev 
		% speficied in special_num
        if ( strcmpi(tmp_riskfactor,'IDIO') == 1 )
            if ( strcmpi(scenario,'stress'))
                tmp_shift;
			elseif ( strcmpi(scenario,'base'))
				tmp_shift;
            else    % append idiosyncratic term only if not a stress risk factor
                tmp_idio_vola_p_a = sensi.get('idio_vola');
                tmp_idio_vec = ones(scen_number,1) .* tmp_idio_vola_p_a;
                tmp_shift = tmp_shift + tmp_sensitivities(jj) .* ...
								normrnd(0,tmp_idio_vec ./ sqrt(250/tmp_ts));
            end
        % get sensitivity approach shift from underlying riskfactors
        else
            [tmp_rf_struct_obj object_ret_code]  = get_sub_object(riskfactor_struct, tmp_riskfactor);	
            if ( object_ret_code == 0 )
                error('Sensitivity.calc_value: No riskfactor_struct object found for id >>%s<<\n',tmp_riskfactor);
            end
            tmp_delta   = tmp_rf_struct_obj.getValue(scenario);
            tmp_shift   = tmp_shift + ( tmp_sensitivities(jj) .* tmp_delta );
        end
    end

    % Calculate new absolute scenario values from Riskfactor PnL depending on riskfactor model
    %   calling static method located in Riskfactor class:
    theo_value   = Riskfactor.get_abs_values(sensi.model, tmp_shift, sensi.getValue('base'));

%=============================================================================== 
% valuation for 'SENSI' instruments (linear and quadratic combination of underlyings)
else
  if ( strcmpi(scenario,'base') &&  sensi.use_value_base == true )
	theo_value = sensi.value_base;
  else
	theo_value = 0.0;
	underlyings   = sensi.underlyings;
    x_coord       = sensi.x_coord;
	y_coord       = sensi.y_coord;
	z_coord       = sensi.z_coord;
	shock_type	  = sensi.shock_type;
	sensi_prefactor  = sensi.sensi_prefactor;
	sensi_exponent  = sensi.sensi_exponent;
	sensi_cross   = sensi.sensi_cross;
    cols_cross_matrix  = max(sensi_cross);
	% input check
	if ~( length(sensi_prefactor) == length(sensi_exponent)) || ~( length(sensi_prefactor) == length(sensi_cross))  ...
		|| ~( length(sensi_prefactor) == length(x_coord)) || ~( length(sensi_prefactor) == length(y_coord)) || ~( length(sensi_prefactor) == length(z_coord)) ...
		|| ~( length(sensi_prefactor) == length(shock_type)) || ~( length(sensi_prefactor) == length(underlyings))
		error('Sensitivity.calc_value: Sensi >>%s<<: Length of underlying definitions does not match.\n',sensi.id);
	end
	% valuation: each scenario value of all underlyings (either value, relative 
	%			 or absolute shocks are evaluated with the equation
	%		     a * x^b and added to total value, if sensi_cross == 0 or multiplied 
	%			 with all cross terms (sensi_cross integers > 0)
	% loop through all underlyings
    for jj = 1 : 1 : length(underlyings)
		tmp_undr = underlyings{jj};
		% get underlying scenario value
		% first try: risk factor
		[undr_obj object_ret_code]  = get_sub_object(riskfactor_struct, tmp_undr);	
		if ( object_ret_code == 0 )
			% second try: instrument factor
			[undr_obj object_ret_code]  = get_sub_object(instrument_struct, tmp_undr);	
			if ( object_ret_code == 0 )
				% third try: curve 
				[undr_obj object_ret_code]  = get_sub_object(curve_struct, tmp_undr);	
				if ( object_ret_code == 0 )
					% fourth try: index
					[undr_obj object_ret_code]  = get_sub_object(index_struct, tmp_undr);	
					if ( object_ret_code == 0 )
						% firth try: surface
						[undr_obj object_ret_code]  = get_sub_object(surface_struct, tmp_undr);	
						if ( object_ret_code == 0 )
							error('Sensitivity.calc_value: No underlying object found for id >>%s<<\n',tmp_undr);
						end
					end
				end
			end
		end
		% distinguish between type and get Value:
		if (strcmpi(class(undr_obj),'Curve'))
			undr_value = undr_obj.getRate(scenario,x_coord(jj));
			undr_value_base = undr_obj.getRate('base',x_coord(jj));
		elseif (strcmpi(class(undr_obj),'Surface'))
			if (strcmpi(undr_obj.type,'IndexVol')) 
				undr_value = undr_obj.getValue(scenario,x_coord(jj),y_coord(jj));
				undr_value_base = undr_obj.getValue('base',x_coord(jj),y_coord(jj));
			elseif (strcmpi(undr_obj.type,'IRVol'))
				undr_value = undr_obj.getValue(scenario,x_coord(jj),y_coord(jj),z_coord(jj));
				undr_value_base = undr_obj.getValue('base',x_coord(jj),y_coord(jj),z_coord(jj));
			end
		else
			undr_value = undr_obj.getValue(scenario);
			undr_value_base = undr_obj.getValue('base');
		end
		% distinguish shock type
		if ( strcmpi(shock_type{jj},'absolute'))
			undr_value = undr_value - undr_value_base;	% get absolute shock
		elseif ( strcmpi(shock_type{jj},'relative'))
			if ~(undr_value_base == 0.0)
				undr_value = undr_value ./ undr_value_base - 1;	% get relative shock
			else
				undr_value = 0.0;
				fprintf('Sensitivity.calc_value: Underlying >>%s<< has shock_type relative and zero base value. Skipping underlying.\n',tmp_undr);
			end
		end
		% calculate polynomial value (distinguish flag taylor expansion)
		if ( sensi.get('use_taylor_exp') == true )
			tmp_poly_value = (sensi_prefactor(jj) / (sensi_exponent(jj))) ...
										.* undr_value .^ (sensi_exponent(jj));
		else
			tmp_poly_value = sensi_prefactor(jj) .* undr_value .^ (sensi_exponent(jj));
		end
		% store in sensi_cross matrix (rows = scenario values, columns = cross terms)
		if ( jj == 1)	% firt initialization of cross_matrix
			cross_matrix = ones(rows(tmp_poly_value),cols_cross_matrix);
			single_vec   = zeros(rows(tmp_poly_value),1);
		end
		% build matrix and vectors to have same dimensions
		if ( rows(tmp_poly_value) > rows(cross_matrix) ) && (rows(cross_matrix) == 1)
			cross_matrix = repmat(cross_matrix,rows(tmp_poly_value),1);
			single_vec   = repmat(single_vec,rows(tmp_poly_value),1);
		elseif (rows(tmp_poly_value) == 1) && (rows(cross_matrix) > 1)
			tmp_poly_value = repmat(tmp_poly_value,rows(cross_matrix),1);
		end
		% distinguish between single and cross terms
		if (sensi_cross(jj) > 0) % cross term
			cross_matrix(:,sensi_cross(jj)) = cross_matrix(:,sensi_cross(jj)) .* tmp_poly_value;
		else
			single_vec = single_vec .+ tmp_poly_value;
		end
		% calculate sensi value as sum of all single and cross terms across columns
		theo_value = sum(cross_matrix,2) + single_vec;
		
		% distinguish flag for use value base
		if ( sensi.get('use_value_base') == true )	% add scenario value to base value
			theo_value = theo_value + sensi.get('value_base');
		end
	end
  end	% end value base condition
end		% end sensi valuation
   
   
% store values in sensitivity object:
if ( strcmpi(scenario,'base'))
    obj = obj.set('value_base',theo_value);
elseif ( strcmpi(scenario,'stress'))
    obj = obj.set('value_stress',theo_value);
else                    
    obj = obj.set('value_mc',theo_value,'timestep_mc',scenario);
end
    
   
end



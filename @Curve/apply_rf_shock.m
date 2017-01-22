% method of class @Curve
function curve = apply_rf_shock (curve, value_type, rf)
  
% input checks
    if ( nargin < 2 )
        error ('Curve.apply_rf_shock requires value_type and shock curve.');
    end
    
% Curve variables
    nodes       = curve.get('nodes');
  
% apply rf shock if given
if ~(strcmpi(value_type,'Base'))
	if ( nargin == 3)
	    if (strcmpi(class(rf),'Curve'))
			% get shocktype
			if ( strcmpi(value_type,'Stress'))
				shocktype = rf.get('shocktype_stress');
				
			else % MC scenarios
				shocktype = rf.get('shocktype_mc');
			end
			rates_shock = zeros(rows(rf.getRate(value_type, 1)),length(nodes));
			% loop via all nodes
			for kk = 1 : 1 : length(nodes)
				node = nodes(kk);
				% get shock
				shock = rf.getRate(value_type, node);
				rate_base = curve.getRate(value_type, node);
				% apply shock to curve
				if ( strcmpi(shocktype,'absolute'))
					rates_shock(:,kk) = shock + rate_base;
				elseif ( strcmpi(shocktype,'absolute'))
					rates_shock(:,kk) = shock * rate_base;
				else
					error ('Curve.getRate: Unknown shocktype >>%s<<',any2str(shocktype));
				end
				
			end
			% set cf values
			if ( strcmpi(value_type,'Stress'))
				curve = curve.set('rates_stress',rates_shock); 
			else % MC scenarios
				curve = curve.set('rates_mc',rates_shock,'timestep_mc',value_type); 
			end
	    else
			error ('Curve.getRate: No valid Shock Curve given.');
		end
	end
end
	
end
% @Stochastic method calc_value
function obj = calc_value(stochastic,valuation_date,value_type,rf_obj,surf_obj)
obj = stochastic;
if ( nargin < 5)
    error('Error: Not enough arguments. Need valuation date, value type, riskfactor and surface objects. Aborting.');
end
   
% rf_obj: riskfactor random variable -> cashflows drawn from surface
% surf_obj: 1D surface containing all values per scenario 
rvec = rf_obj.getValue(value_type); 
% distinguish between uniform and normal distributed risk factor values
if ( strcmpi(obj.stochastic_rf_type,'normal') )
    rvec = normcdf(rvec);   % convert normal(0,1) distributed random number
                            % to [0,1] uniform distributed number
                            
elseif ( strcmpi(obj.stochastic_rf_type,'t') )
    df = obj.t_degree_freedom; % degree of freedom for t distributed risk factor
    rvec = tcdf(rvec,df);   % convert t(df) distributed random number
                            % to [0,1] uniform distributed number
                            
% else:uniform distribution of riskfactor -> do nothing
end 

% map stochastic risk factor to 1D curve values (x axis: 0), return value
tmp_value = surf_obj.interpolate(0,rvec);

% store values in sensitivity object:
if ( strcmpi(value_type,'base'))
    obj = obj.set('value_base',tmp_value);
elseif ( strcmpi(value_type,'stress'))
    obj = obj.set('value_stress',tmp_value);
else                    
    obj = obj.set('value_mc',tmp_value,'timestep_mc',value_type);
end
    
   
end



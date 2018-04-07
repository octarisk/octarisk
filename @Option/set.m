% setting attribute values
function obj = set(obj, varargin)
  % A) Specify fieldnames <-> types key/value pairs
  typestruct = struct(...
                'type', 'char' , ...
                'basis', 'numeric' , ...
                'vola_spread', 'numeric' , ...
                'value_mc', 'special' , ...
                'timestep_mc', 'special' , ...
                'value_stress', 'special' , ...
                'value_base', 'numeric' , ...
                'id', 'char' , ...
                'name', 'char' , ...
                'currency', 'char' , ...
                'maturity_date', 'date' , ...
                'discount_curve', 'char' , ...
                'sub_type', 'char' , ...
                'underlying', 'char' , ...
                'vola_surface', 'char' , ...
                'description', 'char' , ...
                'asset_class', 'char' , ...
                'pricing_function_american', 'char' , ...
                'upordown', 'char' , ...
                'outorin', 'char' , ...
                'multiplier', 'numeric' , ...
                'spread', 'numeric' , ...
                'div_yield', 'numeric' , ...
                'strike', 'numeric' , ...
                'payoff_strike', 'numeric' , ...
                'spot', 'numeric' , ...
                'theo_delta', 'numeric' , ...
                'theo_gamma', 'numeric' , ...
                'theo_vega', 'numeric' , ...
                'theo_theta', 'numeric' , ...
                'theo_rho', 'numeric' , ...
                'theo_omega', 'numeric' , ...
                'timesteps_size', 'numeric' , ...
                'willowtree_nodes', 'numeric' , ...
                'rebate', 'numeric' , ...
                'compounding_freq', 'charvnumber' , ...
                'day_count_convention', 'char' , ...
                'compounding_type', 'char' , ...
                'barrierlevel', 'numeric' , ...
                'vola_sensi', 'numeric', ...
                'call_flag', 'boolean', ...
                'cf_values', 'numeric' , ...
                'cf_dates', 'numeric' , ...
                'option_type', 'char', ...
                'calibration_flag', 'boolean', ...
                'averaging_type', 'char', ...
                'averaging_rule', 'char', ...
                'lookback_type', 'char', ...
                'binary_type', 'char', ...
                'averaging_monitoring', 'char'...
               );
  % B) store values in object
  if (length (varargin) < 2 || rem (length (varargin), 2) ~= 0)
    error ('set: expecting property/value pairs');
  end
  
  while (length (varargin) > 1)
    prop = varargin{1};
    prop = lower(prop);
    val = varargin{2};
    varargin(1:2) = [];
    % check, if property is an existing field
    if (sum(strcmpi(prop,fieldnames(typestruct)))==0)
        fprintf('set: not an allowed fieldname >>%s<< with value >>%s<< :\n',prop,any2str(val));
        fieldnames(typestruct)
        error ('set: invalid property of %s class: >>%s<<\n',class(obj),prop);
    end
    % get property type:
    type = typestruct.(prop);
    % input checks and validation
    retval = return_checked_input(obj,val,prop,type);
    % store property in object
    obj.(prop) = retval;
  end
end   

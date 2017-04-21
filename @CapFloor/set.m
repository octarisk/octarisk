% setting attribute values
function obj = set(obj, varargin)
  % A) Specify fieldnames <-> types key/value pairs
  typestruct = struct(...
                'value_mc', 'special' , ...
                'timestep_mc', 'special' , ...
                'timestep_mc_cf', 'special' , ...
                'value_stress', 'special' , ...
                'value_base', 'numeric' , ...
                'cf_values_stress', 'numeric' , ...
                'cf_values_mc', 'special' , ...
                'cf_values', 'numeric' , ...
                'cf_dates', 'numeric' , ...
                'name', 'char' , ...
                'id', 'char' , ...
                'sub_type', 'char' , ...
                'asset_class', 'char' , ...
                'currency', 'char' , ...
                'description', 'char' , ...
                'maturity_date', 'date' , ...
                'issue_date', 'date' , ...
                'discount_curve', 'char' , ...
                'reference_curve', 'char' , ...
                'model', 'char' , ...
                'vola_surface', 'char' , ...
                'spread', 'numeric' , ...
                'strike', 'numeric' , ...
                'compounding_freq', 'charvnumber' , ...
                'day_count_convention', 'char' , ...
                'compounding_type', 'char' , ...
				'calibration_flag', 'boolean', ...
                'coupon_generation_method', 'char' , ...
                'notional', 'numeric' , ...
                'business_day_rule', 'numeric' , ...
                'business_day_direction', 'numeric' , ...
                'enable_business_day_rule', 'boolean' , ...
                'convex_adj', 'boolean' , ...
                'long_first_period', 'boolean' , ...
                'long_last_period', 'boolean' , ...
                'last_reset_rate', 'numeric' , ...
				'vola_spread', 'numeric' , ...
                'mod_duration', 'numeric' , ...
                'mac_duration', 'numeric' , ...
                'eff_duration', 'numeric' , ...
                'eff_convexity', 'numeric' , ...
                'dv01', 'numeric' , ...
                'pv01', 'numeric' , ...
                'dollar_duration', 'numeric' , ...
                'spread_duration', 'numeric' , ...
                'in_arrears', 'boolean' , ...
                'notional_at_start', 'boolean' , ...
                'notional_at_end', 'boolean' , ...
                'prorated', 'boolean', ...
                'term', 'numeric' , ...
                'ir_shock', 'numeric' , ...
                'coupon_rate', 'numeric' , ...
                'type', 'char' , ...
                'basis', 'numeric', ...
                'cms_model', 'char', ...
                'cms_sliding_term', 'numeric', ...
                'cms_term', 'numeric', ...
                'cms_spread', 'numeric', ...
                'cms_comp_type', 'char', ...
				'cpi_index', 'char', ...
				'infl_exp_curve', 'char', ...
				'cpi_historical_curve', 'char', ...
				'infl_exp_lag', 'numeric', ...	
				'use_indexation_lag', 'boolean', ...
                'cms_convex_model', 'char'...
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

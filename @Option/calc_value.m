function obj = calc_value(option,valuation_date,value_type,underlying,discount_curve,tmp_vola_surf_obj,path_static)
    obj = option;
    if ( nargin < 5)
        error('Error: No  discount curve, vola surface or underlying set. Aborting.');
    end
    if ( nargin < 6)
        valuation_date = today;
    end
    if (ischar(valuation_date))
        valuation_date = datenum(valuation_date);
    end
    if ( nargin < 7)
        path_static = pwd;
    end
    % Get discount curve nodes and rate
        tmp_nodes        	= discount_curve.nodes;
        tmp_rates        	= discount_curve.getValue(value_type);
        comp_type_curve 	= discount_curve.compounding_type;
        comp_freq_curve 	= discount_curve.compounding_freq;
        basis_curve     	= discount_curve.basis;
        
    % get further option attributes
    option_type = obj.option_type;
    call_flag = obj.call_flag;
    if ( call_flag == 1 )
        moneyness_exponent = 1;
    else
        moneyness_exponent = -1;
    end
     
    % Get input variables
    tmp_dtm                  = (datenum(obj.maturity_date,1) - valuation_date); 
    tmp_rf_rate              = interpolate_curve(tmp_nodes,tmp_rates,tmp_dtm ) + obj.spread;

    % Get underlying absolute scenario value 
    if ( strfind(underlying.get('id'),'RF_') )   % underlying instrument is a risk factor
        S_delta      = underlying.getValue(value_type); 
        S            = Riskfactor.get_abs_values('GBM', S_delta, obj.spot);
        S_base       = underlying.getValue('base'); 
    else    % underlying is a Index
        S            = underlying.getValue(value_type); 
        S_base       = underlying.getValue('base');
    end
    mc = length(S);

    if ( tmp_dtm < 0 )
        theo_value_base         = 0;
        theo_value              = zeros(mc,1);
    else
        X              = obj.strike;
        tmp_value      = obj.value_base;
        multi          = obj.multiplier;
        tmp_moneyness  = (S ./ X).^ moneyness_exponent;
        sigma = tmp_vola_surf_obj.getValue(value_type, ...
                                    tmp_dtm,tmp_moneyness) + obj.vola_spread;
	  % sigma needs to be positive
	    sigma(sigma<=0) = sqrt(eps);
      % Convert interest rates into act/365 continuous (used by pricing)     
        r = convert_curve_rates(	valuation_date, ...
									tmp_dtm, ...
									tmp_rf_rate, ...
									comp_type_curve, ...
									comp_freq_curve, ...
									basis_curve, ...
									'cont','annual',3);
        q = obj.get('div_yield');
        
      % Convert timefactor from Instrument basis to pricing basis (act/365)
        T  = timefactor (	valuation_date, ...
							valuation_date + tmp_dtm, ...
							obj.basis) .* 365;
      
      % Valuation for: European plain vanilla options
        if ( strcmpi(option_type,'European')  )     % calling Black-Scholes option pricing model
            theo_value	= option_bs(call_flag,S,X,T,r, sigma,q) .* multi;
			% % Calling cpp function to increase performance:
			% theo_value	= pricing_option_cpp(1,logical(call_flag),S, ...
                                % X,T,r, ...
                                % sigma,q);
			% theo_value = theo_value.* multi;
                                
      % Valuation for: (European) Asian options
        elseif ( strcmpi(option_type,'Asian')  ) % calling Kemna-Vorst or Levy option pricing model
            avg_rule = option.averaging_rule;
            avg_monitoring = option.averaging_monitoring;
            % distinguish Asian options:
            if ( strcmpi(avg_rule,'geometric') && strcmpi(avg_monitoring,'continuous') )
                % Call Kemna-Vorst90 pricing model
                theo_value	= option_asian_vorst90(call_flag,S,X,T,r,sigma,q) .* multi;
				
            elseif ( strcmpi(avg_rule,'arithmetic') && strcmpi(avg_monitoring,'continuous') )
                % Call Levy pricing model
                theo_value	= option_asian_levy(call_flag,S,X,T,r,sigma,q) .* multi;
				
            else
                error('Unknown Asian averaging rule >>%s<< or monitoring >>%s<<',avg_rule,avg_monitoring);
            end
                             
      % Valuation for: American plain vanilla options
        elseif ( strcmpi(option_type,'American'))   % calling Willow tree option pricing model
            if ( strcmpi(obj.pricing_function_american,'Willowtree') )
                theo_value	= option_willowtree(call_flag,1,S,X,T,r,sigma, ...
									0.0,option.timesteps_size, ...
                                    option.willowtree_nodes,path_static) .* multi;
									
			elseif ( strcmpi(obj.pricing_function_american,'CRR') )
				%---------------------- end ------------------------------------
				% TODO: consider using parallel package (only Linux supported, 
				% wont compile under Windows)
				% pkg load parallel;
				% number_cores = 3; % call function three time with 1/3 of input vectors as inputs
				% pararrayfun(cores,@func,var1,var2,...,var3,"Vectorized",true,"ChunksPerProc",1);
				% theo_value  = pararrayfun(number_cores,@pricing_option_cpp, ...)
				%					 2,logical(call_flag),S, ...
                %                    X,T,r,sigma,q,treenodes, ...
				%					"Vectorized",true,"ChunksPerProc",1);	
				%---------------------- end ------------------------------------

				treenodes 	= round(T/option.timesteps_size);
                theo_value	= pricing_option_cpp(2,logical(call_flag),S, ...
                                    X,T,r,sigma,q,treenodes);
				theo_value = theo_value .* multi;
				
            else % fallback: Bjerksund Stensland
                theo_value  = option_bjsten(call_flag,S,X,T,r,sigma,q) .* multi;
            end
                     
       % Valuation for: European Barrier Options:
        elseif ( strcmpi(option_type,'Barrier'))   % calling Barrier option pricing model
            theo_value	= option_barrier(call_flag,obj.upordown,obj.outorin,...
                                S, X, obj.barrierlevel,T,r,sigma,q,obj.rebate) .* multi; 
								
	   % Valuation for: European Binary Options:
        elseif ( strcmpi(option_type,'Binary'))   % calling Binary option pricing model
            theo_value	= option_binary(call_flag, obj.binary_type, S, ...
                            X, obj.payoff_strike, T, r, sigma, q) .* multi;
			
	   % Valuation for: European Lookback Options:
        elseif ( strcmpi(option_type,'Lookback'))   % calling Lookback option pricing model
             theo_value	= option_lookback(call_flag, obj.lookback_type, S, ...
                            X, obj.payoff_strike, T, r, sigma, q) .* multi;
		end						
    end   % close loop if tmp_dtm < 0
    
      
    % store theo_value vector in appropriate class property   
    if ( strcmpi(value_type,'stress'))
        obj = obj.set('value_stress',theo_value);  
    elseif ( strcmpi(value_type,'base'))
        obj = obj.set('value_base',theo_value);  
    else  
        obj = obj.set('timestep_mc',value_type);
        obj = obj.set('value_mc',theo_value);
    end
    
end



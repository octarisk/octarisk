%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
%#
%# This program is free software; you can redistribute it and/or modify it under
%# the terms of the GNU General Public License as published by the Free Software
%# Foundation; either version 3 of the License, or (at your option) any later
%# version.
%#
%# This program is distributed in the hope that it will be useful, but WITHOUT
%# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
%# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
%# details.

%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{ret_instr_obj}] =} instrument_valuation (@var{instr_obj}, @var{valuation_date}, @var{scenario}, @var{instrument_struct}, @var{surface_struct}, @var{matrix_struct}, @var{curve_struct}, @var{index_struct}, @var{riskfactor_struct}, @var{path_static}, @var{scen_number}, @var{tmp_ts}, @var{first_eval})
%#
%# Valuation of instruments according to instrument type.
%# The last four variables can be empty in case of base scenario valuation.
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{instr_obj}: instrument, which has to be valuated
%# @item @var{valuation_date}: valuation date
%# @item @var{scenario}: scenario ['base','stress', MC timestep: e.g. '250d'] 
%# @item @var{instrument_struct}: structure with all instruments in session
%# @item @var{surface_struct}: structure with all surfaces in session
%# @item @var{matrix_struct}: structure with all matrizes in session
%# @item @var{curve_struct}: structure with all curves in session
%# @item @var{index_struct}: structure with all indizes in session
%# @item @var{riskfactor_struct}: structure with all riskfactors in session
%# @item @var{para_struct}: structure with required parameters
%# @itemize @bullet
%# @item @var{para_struct.path_static}: OPTIONAL: path to folder with static files
%# @item @var{para_struct.scen_number}: OPTIONAL: number of scenarios
%# @item @var{para_struct.scenario}: OPTIONAL: timestep number of days for MC scenarios
%# @item @var{para_struct.first_eval}: OPTIONAL: boolean, first_eval == 1 means calibration
%# @end itemize
%# @item @var{ret_instr_obj}: RETURN: evaluated instrument object
%# @end itemize
%# @end deftypefn

function [ret_instr_obj] = instrument_valuation(instr_obj, valuation_date, scenario, ...
                                    instrument_struct, surface_struct, matrix_struct, ...
                                    curve_struct, index_struct, riskfactor_struct, para_struct)

% set default parameter                                 
if ( nargin < 10 )
    scen_number = 1;
    path_static = '';
    tmp_ts = 1;
    first_eval = 1;
end
% get parameter from provided struct
if ( isfield(para_struct,'scen_number'))
    scen_number = para_struct.scen_number;
else
    % Fallback: get scenario number from first curve object
    tmp_curve_object = curve_struct(1).object;
    scen_number = length(tmp_curve_object.getValue(scenario));
end
if ( isfield(para_struct,'path_static'))
    path_static = para_struct.path_static;
else
    path_static = '';
end
if ( isfield(para_struct,'timestep'))
    tmp_ts = para_struct.timestep;
else
    tmp_ts = 1;
end
if ( isfield(para_struct,'first_eval'))
    first_eval = para_struct.first_eval;
else
    first_eval = 1;
end



ret_instr_obj = instr_obj;
tmp_type = instr_obj.type;
tmp_sub_type = instr_obj.sub_type;
% Full Valuation depending on Type:
% ETF Debt Valuation:
if ( strcmpi(tmp_type,'debt') == 1 )
    % Using debt class
    debt = instr_obj;
    % get discount curve
    tmp_discount_curve  = debt.get('discount_curve');
    tmp_discount_object = get_sub_object(curve_struct, tmp_discount_curve);

    % Calc value
    debt = debt.calc_value(tmp_discount_object,scenario);

    % store debt object:
    ret_instr_obj = debt;

% European Option Valuation according to Back-Scholes Model 
elseif ( strfind(tmp_type,'option') > 0 )    
    % Valuation of Options: depending of underlying type (single underlying like
    % index or instruments OR basket underlying (synthetic)) 
    % Using Option class
    option = instr_obj;
    
    tmp_rf_curve_obj  = get_sub_object(curve_struct, option.get('discount_curve'));
    
    % 1st try: find underlying in instrument_struct
    [tmp_underlying_obj  object_ret_code]  = get_sub_object(instrument_struct, option.get('underlying'));
    if ( object_ret_code == 0 )
        % 2nd try: find underlying in instrument_struct
        [tmp_underlying_obj]  = get_sub_object(index_struct, option.get('underlying'));
    end

    % 1st Case: Option on Basket (=Synthetic Instrument) calculate diversified 
    %           vola and underlying value store values in generic objects 
    %           used for further calculation
    if ( strcmpi(class(tmp_underlying_obj),'Synthetic') && tmp_underlying_obj.is_basket )
        % valuation of Synthetic Basket
        tmp_underlying_obj = tmp_underlying_obj.calc_value(valuation_date,scenario,instrument_struct,index_struct);
        
        % calculate diversified vola for base scenario
        basket_vola_base = get_basket_volatility(valuation_date,'base', ...
                  tmp_underlying_obj,option,instrument_struct,index_struct, ...
                  curve_struct, riskfactor_struct,matrix_struct,surface_struct);
                  
        % calculate diversified vola for scenario type
        basket_vola = get_basket_volatility(valuation_date,scenario, ...
                  tmp_underlying_obj,option,instrument_struct,index_struct, ...
                  curve_struct, riskfactor_struct,matrix_struct,surface_struct);
                  
        % generate Vola object with base vola
        tmp_vola_surf_obj = Surface();
        tmp_vola_surf_obj = tmp_vola_surf_obj.set('id','Basket Vola','axis_x',365, ...
                   'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
        tmp_vola_surf_obj = tmp_vola_surf_obj.set('values_base',basket_vola_base);
        tmp_vola_surf_obj = tmp_vola_surf_obj.set('type','INDEX');
        
        % generate risk factor object with vola shocks
        basket_vola_shocks = log(basket_vola ./ basket_vola_base);% assuming GBM
        tmp_rf_vola_obj = Riskfactor();
        tmp_rf_vola_obj = tmp_rf_vola_obj.set('id','Basket Vola RF','model','GBM');
        if ( strcmpi(scenario,'base'))
            tmp_rf_vola_obj = tmp_rf_vola_obj.set('value_base',1);
        elseif ( strcmpi(scenario,'stress'))
            tmp_rf_vola_obj = tmp_rf_vola_obj.set('scenario_stress',basket_vola_shocks);
        else                    
            tmp_rf_vola_obj = tmp_rf_vola_obj.set('scenario_mc',basket_vola_shocks, ...
                                                    'timestep_mc',scenario);
        end
    else
    % 2nd Case: Option on single underlying, take real objects
        tmp_vola_surf_obj = get_sub_object(surface_struct, option.get('vola_surface'));
        tmp_rf_vola_obj   = get_sub_object(riskfactor_struct, option.get('vola_surface'));
    end

    % Calibration of Option vola spread 
    if ( option.get('vola_spread') == 0 )
        option = option.calc_vola_spread(valuation_date,tmp_underlying_obj,tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,path_static);
    end
    % calculate value
    option = option.calc_value(valuation_date,scenario,tmp_underlying_obj,tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,path_static);

    % store option object:
    ret_instr_obj = option;
    % Debug Mode:
    if ( regexp(option.name,'DEBUG') )
        fprintf('DEBUG for Instrument name %s of type %s \n',option.name,tmp_type);
        fprintf('\t Underyling Instrument %s \n',tmp_underlying_obj.id);
        tmp_underlying_obj
        fprintf('\t Underyling Vola Surface %s \n',tmp_vola_surf_obj.id);
        tmp_vola_surf_obj
        fprintf('\t Discount Curve %s \n',tmp_rf_curve_obj.id);
        tmp_rf_curve_obj
        fprintf('\t Underyling Vola Risk factor %s \n',tmp_rf_vola_obj.id);
        tmp_rf_vola_obj
        fprintf('\t Option %s \n',option.id);
        option
    end
% European Swaption Valuation according to Back76 or Bachelier Model 
elseif ( strfind(tmp_type,'swaption') > 0 )    
    % Using Swaption class
    swaption = instr_obj;
    % Get relevant objects
    tmp_rf_vola_obj          = get_sub_object(riskfactor_struct, 'RF_VOLA_EQ_DE'); %swaption.get('vola_surface'));
    tmp_rf_curve_obj         = get_sub_object(curve_struct, swaption.get('discount_curve'));
    tmp_vola_surf_obj        = get_sub_object(surface_struct, swaption.get('vola_surface'));
    % Calibration of swaption vola spread            
    if ( swaption.get('vola_spread') == 0 )
        swaption = swaption.calc_vola_spread(valuation_date,tmp_rf_curve_obj,tmp_vola_surf_obj,tmp_rf_vola_obj);
    end
    % calculate value
    swaption = swaption.calc_value(valuation_date,scenario,tmp_rf_curve_obj,tmp_vola_surf_obj,tmp_rf_vola_obj);
    % store swaption object:
    ret_instr_obj = swaption;
        
%Equity Forward valuation
elseif (strcmpi(tmp_type,'forward') )
    % Using forward class
        forward = instr_obj;
     % Get underlying Index / instrument    
        tmp_underlying = forward.get('underlying_id');
        [tmp_underlying_object object_ret_code]  = get_sub_object(index_struct, tmp_underlying);
        if ( object_ret_code == 0 )
            fprintf('octarisk: WARNING: No index_struct object found for id >>%s<<\n',tmp_underlying_object);
        end
    % Get discount curve
        tmp_discount_curve          = forward.get('discount_curve');            
        tmp_curve_object            = get_sub_object(curve_struct, tmp_discount_curve);	

    %Calculate values of equity forward
    if ( first_eval == 0)
    % Base value
        forward = forward.calc_value(valuation_date,'base',tmp_curve_object,tmp_underlying_object);
    end
    % calculation of value for scenario               
        forward = forward.calc_value(valuation_date,scenario,tmp_curve_object,tmp_underlying_object);

    % store bond object:
    ret_instr_obj = forward;
    % Debug Mode:
    if ( regexp(forward.name,'DEBUG') )
        fprintf('DEBUG for Instrument name %s of type %s \n',forward.name,tmp_type);
        fprintf('\t Underyling Instrument %s \n',tmp_underlying_object.id);
        tmp_underlying_object
        fprintf('\t Discount Curve %s \n',tmp_curve_object.id);
        tmp_curve_object
        fprintf('\t Forward %s \n',forward.id);
        forward
    end    
% Equity Valuation: Sensitivity based Approach       
elseif ( strcmpi(tmp_type,'sensitivity'))
tmp_delta = 0;
tmp_shift = 0;
% Using sensitivity class
    sensi               = instr_obj;
    tmp_sensitivities   = sensi.get('sensitivities');
    tmp_riskfactors     = sensi.get('riskfactors');
    for jj = 1 : 1 : length(tmp_sensitivities)
        % get riskfactor:
        tmp_riskfactor = tmp_riskfactors{jj};
        % get idiosyncratic risk: normal distributed random variable with stddev speficied in special_num
        if ( strcmpi(tmp_riskfactor,'IDIO') == 1 )
            if ( strcmpi(scenario,'stress'))
                tmp_shift;
            else    % append idiosyncratic term only if not a stress risk factor
                tmp_idio_vola_p_a = sensi.get('idio_vola');
                tmp_idio_vec = ones(scen_number,1) .* tmp_idio_vola_p_a;
                tmp_shift = tmp_shift + tmp_sensitivities(jj) .* normrnd(0,tmp_idio_vec ./ sqrt(250/tmp_ts));
            end
        % get sensitivity approach shift from underlying riskfactors
        else
            tmp_rf_struct_obj    = get_sub_object(riskfactor_struct, tmp_riskfactor);
            tmp_delta   = tmp_rf_struct_obj.getValue(scenario);
            tmp_shift   = tmp_shift + ( tmp_sensitivities(jj) .* tmp_delta );
        end
    end

    % Calculate new absolute scenario values from Riskfactor PnL depending on riskfactor model
    %   calling static method located in Riskfactor class:
    theo_value   = Riskfactor.get_abs_values('GBM', tmp_shift, sensi.getValue('base'));

    % store values in sensitivity object:
    if ( strcmpi(scenario,'stress'))
        sensi = sensi.set('value_stress',theo_value);
    else            
        sensi = sensi.set('value_mc',theo_value,'timestep_mc',scenario);           
    end
    % store sensi object:
    ret_instr_obj = sensi;

% Synthetic Instrument Valuation: synthetic value is linear combination of underlying instrument values      
elseif ( strcmpi(tmp_type,'synthetic'))
    % Using Synthetic class
    synth = instr_obj;
        
    synth = synth.calc_value(valuation_date,scenario,instrument_struct,index_struct);
    % store bond object:
    ret_instr_obj = synth;
        
% Cashflow Valuation: summing net present value of all cashflows according to cashflowdates
elseif ( sum(strcmpi(tmp_type,'bond')) > 0 ) 
    % Using Bond class
        bond = instr_obj;
    % a) Get curve parameters    
      % get discount curve
        tmp_discount_curve  = bond.get('discount_curve');
        [tmp_curve_object object_ret_code]    = get_sub_object(curve_struct, tmp_discount_curve); 
        if ( object_ret_code == 0 )
            fprintf('octarisk: WARNING: No curve_struct object found for id >>%s<<\n',tmp_discount_curve);
        end
     
    % b) Get Cashflow dates and values of instrument depending on type (cash settlement):
        if( sum(strcmpi(tmp_sub_type,{'FRB','SWAP_FIXED','ZCB','CASHFLOW'})) > 0 )       % Fixed Rate Bond instruments (incl. swap fixed leg)
            % rollout cash flows for all scenarios
            if ( first_eval == 0)
                bond = bond.rollout('base',valuation_date);
            end
            bond = bond.rollout(scenario,valuation_date);
        elseif( strcmpi(tmp_sub_type,'FRN') || strcmpi(tmp_sub_type,'SWAP_FLOAT'))       % Floating Rate Notes (incl. swap floating leg)
             %get reference curve object used for calculating floating rates:
                tmp_ref_curve   = bond.get('reference_curve');
                tmp_ref_object 	= get_sub_object(curve_struct, tmp_ref_curve);
            % rollout cash flows for all scenarios
                if ( first_eval == 0)
                    bond = bond.rollout('base',tmp_ref_object,valuation_date);
                end
                bond = bond.rollout(scenario,tmp_ref_object,valuation_date);  
        elseif( strcmpi(tmp_sub_type,'STOCHASTIC') )       % Stochastic CF instrument
             %get riskfactor object and surface object:
                tmp_riskfactor   = bond.get('stochastic_riskfactor');
                tmp_rf_obj 	     = get_sub_object(curve_struct, tmp_riskfactor);
                tmp_surface      = bond.get('stochastic_surface');
                tmp_surf_obj 	 = get_sub_object(riskfactor_struct, tmp_surface);
            % rollout cash flows for all scenarios
                if ( first_eval == 0)
                    bond = bond.rollout('base',tmp_rf_obj,tmp_surf_obj);
                end
                bond = bond.rollout(scenario,tmp_rf_obj,tmp_surf_obj); 
        end 
    % c) Calculate spread over yield (if not already run...)
        if ( bond.get('calibration_flag') == 0 )
            bond = bond.calc_spread_over_yield(valuation_date,tmp_curve_object);
        end
    % d) get net present value of all Cashflows (discounting of all cash flows)
        if ( first_eval == 0)
            bond = bond.calc_value (valuation_date,'base',tmp_curve_object);
            % calculate sensitivities
            if( strcmpi(tmp_sub_type,'FRN') || strcmpi(tmp_sub_type,'SWAP_FLOAT'))
                bond = bond.calc_sensitivities(valuation_date,tmp_curve_object,tmp_ref_object);
            else
                bond = bond.calc_sensitivities(valuation_date,tmp_curve_object);
            end                       
        end
        bond = bond.calc_value (valuation_date,scenario,tmp_curve_object);  
    % e) store bond object:
    ret_instr_obj = bond;

elseif ( strcmpi(tmp_type,'stochastic'))
    % Using Stochastic class
    stoch = instr_obj;
    %get riskfactor object and surface object:
    tmp_riskfactor   = bond.get('stochastic_riskfactor');
    tmp_rf_obj 	     = get_sub_object(curve_struct, tmp_riskfactor);
    tmp_surface      = bond.get('stochastic_curve');
    tmp_surf_obj 	 = get_sub_object(riskfactor_struct, tmp_surface);
        
    stoch = stoch.calc_value(valuation_date,scenario,tmp_rf_obj,tmp_surf_obj);
    % store Stochastic object:
    ret_instr_obj = stoch;
    
% Cash  Valuation: Cash is riskless
elseif ( strcmpi(tmp_type,'cash')) 
    % Using cash class
    cash = instr_obj;
    cash = cash.calc_value(scenario,scen_number);
    % store cash object:
    ret_instr_obj = cash;
else
    error('instrument_valuation: unknown instrument type >>%s<<',any2str(tmp_type));
end


end
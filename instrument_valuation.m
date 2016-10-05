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
%# @item @var{path_static}: OPTIONAL: path to folder with static files
%# @item @var{scen_number}: OPTIONAL: number of scenarios
%# @item @var{tmp_ts}: OPTIONAL: timestep number of days for MC scenarios
%# @item @var{first_eval}: OPTIONAL: boolean, first_eval == 1 means calibration
%# @item @var{ret_instr_obj}: RETURN: evaluated instrument object
%# @end itemize
%# @end deftypefn

function [ret_instr_obj] = instrument_valuation(instr_obj, valuation_date, scenario, ...
                                    instrument_struct, surface_struct, matrix_struct, ...
                                    curve_struct, index_struct, riskfactor_struct, path_static, scen_number, tmp_ts, first_eval)

if ( nargin < 12)
    path_static = pwd;
    scen_number = 1;
    tmp_ts = 1; % number of timestep in days for MC scenarios
    first_eval = 0;  
end
if ( nargin < 13)
    scen_number = 1;
    tmp_ts = 1; % number of timestep in days for MC scenarios
    first_eval = 0;  
end
if ( nargin < 12)
    tmp_ts = 1; % number of timestep in days for MC scenarios
    first_eval = 0;
end
if ( nargin < 13)
    first_eval = 0;
end


ret_instr_obj = instr_obj;
tmp_type = instr_obj.type;
tmp_sub_type = instr_obj.sub_type;
% Full Valuation depending on Type:
% ETF Debt Valuation:
if ( strcmp(tmp_type,'debt') == 1 )
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
    % Using Option class
    option = instr_obj;
    
    % Get relevant objects
    tmp_rf_vola_obj          = get_sub_object(riskfactor_struct, option.get('vola_surface'));
    tmp_underlying_obj   = get_sub_object(index_struct, option.get('underlying'));

    tmp_rf_curve_obj         = get_sub_object(curve_struct, option.get('discount_curve'));
    tmp_vola_surf_obj        = get_sub_object(surface_struct, option.get('vola_surface'));
    % Calibration of Option vola spread 
    if ( option.get('vola_spread') == 0 )
        option = option.calc_vola_spread(tmp_underlying_obj,tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,valuation_date,path_static);
    end
    % calculate value
    option = option.calc_value(scenario,tmp_underlying_obj,tmp_rf_vola_obj,tmp_rf_curve_obj,tmp_vola_surf_obj,valuation_date,path_static);

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
    swaption = swaption.calc_value(scenario,valuation_date,tmp_rf_curve_obj,tmp_vola_surf_obj,tmp_rf_vola_obj);
    % store swaption object:
    ret_instr_obj = swaption;
        
%Equity Forward valuation
elseif (strcmp(tmp_type,'forward') )
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
elseif ( strcmp(tmp_type,'sensitivity') == 1 )
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
        if ( strcmp(tmp_riskfactor,'IDIO') == 1 )
            if ( strcmp(scenario,'stress'))
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
    theo_value   = Riskfactor.get_abs_values('GBM', tmp_shift, sensi.getValue('base'));

    % store values in sensitivity object:
    if ( strcmp(scenario,'stress'))
        sensi = sensi.set('value_stress',theo_value);
    else            
        sensi = sensi.set('value_mc',theo_value,'timestep_mc',scenario);           
    end
    % store sensi object:
    ret_instr_obj = sensi;

% Synthetic Instrument Valuation: synthetic value is linear combination of underlying instrument values      
elseif ( strcmp(tmp_type,'synthetic') == 1 )
    % get values of underlying instrument and weigh them by their sensitivity
    tmp_value_base      = 0;
    tmp_value           = 0;
    % Using sensitivity class
    synth               = instr_obj;
    tmp_weights         = synth.get('weights');
    tmp_instruments     = synth.get('instruments');
    tmp_currency        = synth.get('currency');
    % summing values over all underlying instruments
    for jj = 1 : 1 : length(tmp_weights)
        % get underlying instrument:
        tmp_underlying              = tmp_instruments{jj};
        [und_obj  object_ret_code]  = get_sub_object(instrument_struct, tmp_underlying);
        if ( object_ret_code == 0 )
            fprintf('octarisk: WARNING: No instrument_struct object found for id >>%s<<\n',tmp_underlying);
        end
        % Get instrument Value from full valuation instrument_struct:
        % absolute values from full valuation
        underlying_value_base       = und_obj.getValue('base');                 
        underlying_value_vec        = und_obj.getValue(scenario);  
        % Get FX rate:
        tmp_underlying_currency = und_obj.get('currency'); 
        if ( strcmp(tmp_underlying_currency,tmp_currency) == 1 )
            tmp_fx_rate_base    = 1;
            tmp_fx_value        = 1; %ones(scen_number,1);
        else
            %Conversion of currency:;
            tmp_fx_index = strcat('FX_', tmp_currency, tmp_underlying_currency);
            tmp_fx_struct_obj = get_sub_object(index_struct, tmp_fx_index);
            tmp_fx_rate_base  = tmp_fx_struct_obj.getValue('base');
            tmp_fx_value      = tmp_fx_struct_obj.getValue(scenario);
        end
        tmp_value_base      = tmp_value_base    + tmp_weights(jj) .* underlying_value_base ./ tmp_fx_rate_base;
        tmp_value           = tmp_value      + tmp_weights(jj) .* underlying_value_vec ./ tmp_fx_value;
    end

    % store values in sensitivity object:
    if ( first_eval == 0)
        synth = synth.set('value_base',tmp_value_base);
    end
    if ( strcmp(scenario,'stress'))
        synth = synth.set('value_stress',tmp_value);
    else                    
        synth = synth.set('value_mc',tmp_value,'timestep_mc',scenario);
    end
    % store bond object:
    ret_instr_obj = synth;
        
% Cashflow Valuation: summing net present value of all cashflows according to cashflowdates
elseif ( sum(strcmp(tmp_type,'bond')) > 0 ) 
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
        if( sum(strcmp(tmp_sub_type,{'FRB','SWAP_FIXED','ZCB','CASHFLOW'})) > 0 )       % Fixed Rate Bond instruments (incl. swap fixed leg)
            % rollout cash flows for all scenarios
            if ( first_eval == 0)
                bond = bond.rollout('base',valuation_date);
            end
            bond = bond.rollout(scenario,valuation_date);
        elseif( strcmp(tmp_sub_type,'FRN') || strcmp(tmp_sub_type,'SWAP_FLOAT'))       % Floating Rate Notes (incl. swap floating leg)
             %get reference curve object used for calculating floating rates:
                tmp_ref_curve   = bond.get('reference_curve');
                tmp_ref_object 	= get_sub_object(curve_struct, tmp_ref_curve);
            % rollout cash flows for all scenarios
                if ( first_eval == 0)
                    bond = bond.rollout('base',tmp_ref_object,valuation_date);
                end
                bond = bond.rollout(scenario,tmp_ref_object,valuation_date);         
        end 
    % c) Calculate spread over yield (if not already run...)
        if ( bond.get('calibration_flag') == 0 )
            bond = bond.calc_spread_over_yield(tmp_curve_object,valuation_date);
        end
    % d) get net present value of all Cashflows (discounting of all cash flows)
        if ( first_eval == 0)
            bond = bond.calc_value (valuation_date,tmp_curve_object,'base');
            % calculate sensitivities
            if( strcmp(tmp_sub_type,'FRN') || strcmp(tmp_sub_type,'SWAP_FLOAT'))
                bond = bond.calc_sensitivities(valuation_date,tmp_curve_object,tmp_ref_object);
            else
                bond = bond.calc_sensitivities(valuation_date,tmp_curve_object);
            end                       
        end
        bond = bond.calc_value (valuation_date,tmp_curve_object,scenario);  
    % e) store bond object:
    ret_instr_obj = bond;
    
% Cash  Valuation: Cash is riskless
elseif ( strcmp(tmp_type,'cash') == 1 ) 
    % Using cash class
    cash = instr_obj;
    cash = cash.calc_value(scenario,scen_number);
    % store cash object:
    ret_instr_obj = cash;
else
    error('instrument_valuation: unknown instrument type >>%s<<',any2str(tmp_type));
end


end
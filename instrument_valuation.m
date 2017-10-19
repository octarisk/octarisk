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
%# @item @var{para_struct.first_eval}: OPTIONAL: boolean, first_eval == 1 means first evaluation
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
    [tmp_discount_object object_ret_code] = get_sub_object(curve_struct, tmp_discount_curve);
    if ( object_ret_code == 0 )
        fprintf('WARNING: instrument_valuation: No curve_struct object found for id >>%s<<\n',tmp_discount_curve);
    end
    
    % Calc value
    debt = debt.calc_value(tmp_discount_object,scenario);

    % store debt object:
    ret_instr_obj = debt;

% ==============================================================================
% European Option Valuation according to Back-Scholes Model 
elseif ( strfind(tmp_type,'option') > 0 )    
    % Valuation of Options: depending of underlying type (single underlying like
    % index or instruments OR basket underlying (synthetic)) 
    % Using Option class
    option = instr_obj;
    
    [tmp_rf_curve_obj object_ret_code] = get_sub_object(curve_struct, option.get('discount_curve'));
    if ( object_ret_code == 0 )
        fprintf('WARNING: instrument_valuation: No curve_struct object found for id >>%s<<\n',option.get('discount_curve'));
    end
    
    % 1st try: find underlying in instrument_struct
    [tmp_underlying_obj  object_ret_code]  = get_sub_object(instrument_struct, option.get('underlying'));
    if ( object_ret_code == 0 )
        % 2nd try: find underlying in index
        [tmp_underlying_obj]  = get_sub_object(index_struct, option.get('underlying'));
    end

    % 1st Case: Option on Basket (=Synthetic Instrument) calculate diversified 
    %           vola and underlying value store values in generic objects 
    %           used for further calculation
    if ( strcmpi(class(tmp_underlying_obj),'Synthetic') && tmp_underlying_obj.is_basket )
		% for Options on Baskets, valuation have to be distinguished between
		% Levy, VCV and Beisser valuation methods. For Levy and VCV, a volatility
		% for the whole basket is calculated. Afterwards, option pricing takes
		% place viewing the basket as one underlying.
		% In contrast to that, valuation with Beisser method is different:
		% Each underlying of the basket gets his own volatility and a new strike
		% for all underlyings and scenarios is calculated. This breaks somehow
		% octarisk's pricing algorithm and requires an additional valuation method
		% option.calc_value_basket_beisser. Please see the referenced paper
		% for background to Beisser's method.
		
        % valuation of Synthetic Basket
        tmp_underlying_obj = tmp_underlying_obj.calc_value(valuation_date,scenario,instrument_struct,index_struct);
        
        % calculate diversified vola for base scenario
        [basket_vola_base basket_dict_base] = get_basket_volatility(valuation_date,'base', ...
                  tmp_underlying_obj,option,instrument_struct,index_struct, ...
                  curve_struct, riskfactor_struct,matrix_struct,surface_struct);
        
        % calculate diversified vola for scenario type
        [basket_vola basket_dict] = get_basket_volatility(valuation_date,scenario, ...
                  tmp_underlying_obj,option,instrument_struct,index_struct, ...
                  curve_struct, riskfactor_struct,matrix_struct,surface_struct);
        % generate Vola object with base vola
        tmp_vola_surf_obj = Surface();
        tmp_vola_surf_obj = tmp_vola_surf_obj.set('id','instrument_valuation:Basket Vola','axis_x',365, ...
                   'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
        tmp_vola_surf_obj = tmp_vola_surf_obj.set('values_base',basket_vola_base);
        tmp_vola_surf_obj = tmp_vola_surf_obj.set('type','INDEXVol', ...
                                                'riskfactors',{'BasketVolaRF'});
		
		% For Levy of VCV, the basket has his own volatility. Therefore a new
		% vola object is generated:
		if (any(strcmpi(tmp_underlying_obj.basket_vola_type,{'Levy','VCV'})))
			% generate risk factor object with vola shocks
			tmp_rf_vola_obj = Riskfactor();
			tmp_rf_vola_obj = tmp_rf_vola_obj.set('id','BasketVolaRF','model','GBM');
			if ( strcmpi(scenario,'base'))
				tmp_rf_vola_obj = tmp_rf_vola_obj.set('value_base',1);
			elseif ( strcmpi(scenario,'stress'))
				basket_vola_shocks = (basket_vola ./ basket_vola_base);% assuming relative shock factors
				% update basket volatilty for STRESS basket vola shock
				% set up stress struct and apply stress shocks
				basket_stress_struct = struct();
				for pp = 1:1:length(basket_vola_shocks)
					basket_stress_struct(pp).id = 'STRESS';
					basket_stress_struct(pp).objects(1).id = tmp_vola_surf_obj.id;
					basket_stress_struct(pp).objects(1).type = 'surface';
					basket_stress_struct(pp).objects(1).shock_type = 'relative';
					basket_stress_struct(pp).objects(1).shock_value = basket_vola_shocks(pp);
				end
				tmp_vola_surf_obj = tmp_vola_surf_obj.apply_stress_shocks(basket_stress_struct);
			else     
				basket_vola_shocks = log(basket_vola ./ basket_vola_base);% assuming GBM
				tmp_rf_vola_obj = tmp_rf_vola_obj.set('scenario_mc',basket_vola_shocks, ...
														'timestep_mc',scenario);
				% update basket volatilty for MC basket vola shock
				tmp_rf_struct(1).id = tmp_rf_vola_obj.id;
				tmp_rf_struct(1).object = tmp_rf_vola_obj;
				tmp_vola_surf_obj = tmp_vola_surf_obj.apply_rf_shocks(tmp_rf_struct);
			end
		end
    else
    % 2nd Case: Option on single underlying, take real objects
        if ~( strcmpi(class(tmp_underlying_obj),'Index'))   % valuate instruments only
            tmp_underlying_obj = tmp_underlying_obj.valuate(valuation_date, scenario, ...
                                instrument_struct, surface_struct, ...
                                matrix_struct, curve_struct, index_struct, ...
                                riskfactor_struct, para_struct);
        end
        tmp_vola_surf_obj = get_sub_object(surface_struct, option.get('vola_surface'));
    end

    % Calibration of Option vola spread 
    if ( option.get('calibration_flag') == false ) 
		if (strcmpi(class(tmp_underlying_obj),'Synthetic') ...
						&& tmp_underlying_obj.is_basket ...
						&& strcmpi(tmp_underlying_obj.basket_vola_type,'Beisser'))
			%option = option.calc_value_basket_beisser(valuation_date,'base',basket_vola_base,basket_dict_base);
			%TODO: implement vola spread calculation for Beisser basket options
		else	% basket option types Levy or VCV
			option = option.calc_vola_spread(valuation_date,tmp_underlying_obj, ...
								tmp_rf_curve_obj,tmp_vola_surf_obj,path_static);
		end
    end
    % calculate value
    if (~strcmpi(scenario,'base') )
        % calculate greeks
		
		% different pricing methods for Beisser Basket instruments or all other 
		% options on baskets / underlyings
		if (strcmpi(class(tmp_underlying_obj),'Synthetic') ...
						&& tmp_underlying_obj.is_basket ...
						&& strcmpi(tmp_underlying_obj.basket_vola_type,'Beisser'))
			option = option.calc_greeks_basket_beisser(valuation_date,'base', ...
													basket_vola_base,basket_dict_base);

		else	% basket option types Levy or VCV
			option = option.calc_value(valuation_date,'base',tmp_underlying_obj, ...
								tmp_rf_curve_obj,tmp_vola_surf_obj,path_static);
			option = option.calc_greeks(valuation_date,'base',tmp_underlying_obj, ...
								tmp_rf_curve_obj,tmp_vola_surf_obj,path_static);
		end
		
    end
	% different pricing methods for Beisser Basket instruments or all other 
	% options on baskets / underlyings
	if (strcmpi(class(tmp_underlying_obj),'Synthetic') ...
					&& tmp_underlying_obj.is_basket ...
					&& strcmpi(tmp_underlying_obj.basket_vola_type,'Beisser'))
		option = option.calc_value_basket_beisser(valuation_date,scenario, ...
														basket_vola,basket_dict);
		
	else	% basket option types Levy or VCV
		option = option.calc_value(valuation_date,scenario,tmp_underlying_obj, ...
								tmp_rf_curve_obj,tmp_vola_surf_obj,path_static);
	end
	
    % store option object:
    ret_instr_obj = option;

% ==============================================================================
% European Swaption Valuation according to Back76 or Bachelier Model 
elseif ( strfind(tmp_type,'swaption') > 0 )    
    % Using Swaption class
    swaption = instr_obj;
    % Get relevant objects
    [tmp_rf_curve_obj object_ret_code] = get_sub_object(curve_struct, swaption.get('discount_curve'));
    if ( object_ret_code == 0 )
        fprintf('WARNING: instrument_valuation: No curve_struct object found for id >>%s<<\n',swaption.get('discount_curve'));
    end
          
    [tmp_vola_surf_obj object_ret_code] = get_sub_object(surface_struct, swaption.get('vola_surface'));
    if ( object_ret_code == 0 )
        fprintf('WARNING: instrument_valuation: No surface_struct object found for id >>%s<<\n',swaption.get('vola_surface'));
    end
    
    % Calibration of swaption vola spread            
    if ( swaption.get('calibration_flag') == false )
        swaption = swaption.calc_vola_spread(valuation_date,tmp_rf_curve_obj,tmp_vola_surf_obj);
    end
    % calculate value
    if ( swaption.use_underlyings == true)      % use underlying fixed and floating legs
        % get underlying fixed and floating legs
        [fixed_leg object_ret_code] = get_sub_object(instrument_struct, swaption.get('und_fixed_leg'));
        if ( object_ret_code == 0 )
            fprintf('WARNING: instrument_valuation: No instrument_struct fixed leg object found for id >>%s<<\n',swaption.get('und_fixed_leg'));
        end
        % TODO: cashflow rollout of fixed leg and floating leg
        [float_leg object_ret_code] = get_sub_object(instrument_struct, swaption.get('und_floating_leg'));
        if ( object_ret_code == 0 )
            fprintf('WARNING: instrument_valuation: No instrument_struct floating leg object found for id >>%s<<\n',swaption.get('und_floating_leg'));
        end
        % calculate underlying values
        if ( sum(strcmp(scenario,fixed_leg.timestep_mc))==0)
            fixed_leg = fixed_leg.valuate(valuation_date, scenario, ...
                                instrument_struct, surface_struct, ...
                                matrix_struct, curve_struct, index_struct, ...
                                riskfactor_struct, para_struct);
        end
        if ( sum(strcmp(scenario,float_leg.timestep_mc))==0)
            float_leg = float_leg.valuate(valuation_date, scenario, ...
                                instrument_struct, surface_struct, ...
                                matrix_struct, curve_struct, index_struct, ...
                                riskfactor_struct, para_struct);
        end
        %Calculate base values of swaption
        if (~strcmpi(scenario,'base') )
            swaption = swaption.calc_value(valuation_date,'base',tmp_rf_curve_obj,tmp_vola_surf_obj,fixed_leg,float_leg);
        end
        swaption = swaption.calc_value(valuation_date,scenario,tmp_rf_curve_obj,tmp_vola_surf_obj,fixed_leg,float_leg);
    else     % use reference curve for extracting forward rates
        %Calculate base values of swaption
        if (~strcmpi(scenario,'base') )
            swaption = swaption.calc_value(valuation_date,'base',tmp_rf_curve_obj,tmp_vola_surf_obj);
        end
        swaption = swaption.calc_value(valuation_date,scenario,tmp_rf_curve_obj,tmp_vola_surf_obj);
    end
    
    % store swaption object:
    ret_instr_obj = swaption;
    % if ( strcmpi(scenario,'stress'))
        % swaption
    % end

% ==============================================================================
% European CapFloor Valuation according to Back76 or Bachelier Model 
elseif ( strfind(tmp_type,'capfloor') > 0 )    
    % Using CapFloor class
    capfloor = instr_obj;
    % Get relevant objects
    [tmp_disc_curve_obj object_ret_code]  = get_sub_object(curve_struct, capfloor.get('discount_curve'));
    if ( object_ret_code == 0 )
        fprintf('WARNING: instrument_valuation: No curve_struct object found for id >>%s<<\n',capfloor.get('discount_curve'));
    end
              
    [tmp_rf_curve_obj object_ret_code] = get_sub_object(curve_struct, capfloor.get('reference_curve'));
    if ( object_ret_code == 0 )
        fprintf('WARNING: instrument_valuation: No curve_struct object found for id >>%s<<\n',capfloor.get('reference_curve'));
    end
          
    [tmp_vola_surf_obj object_ret_code] = get_sub_object(surface_struct, capfloor.get('vola_surface'));
    if ( object_ret_code == 0 )
        fprintf('WARNING: instrument_valuation: No surface_struct object found for id >>%s<<\n',capfloor.get('vola_surface'));
    end
    
    % Calibration of capfloor vola spread            
    if ( capfloor.get('calibration_flag') == false ) 
        capfloor = capfloor.calc_vola_spread(valuation_date,tmp_rf_curve_obj,tmp_vola_surf_obj);
    end
    capfloor = capfloor.rollout(valuation_date,scenario,tmp_rf_curve_obj,tmp_vola_surf_obj);
    if (~strcmpi(scenario,'base') )
        capfloor = capfloor.calc_sensitivities(valuation_date,scenario,tmp_rf_curve_obj,tmp_vola_surf_obj,tmp_disc_curve_obj);
    end
    capfloor = capfloor.calc_value(valuation_date,scenario,tmp_disc_curve_obj);
    % store capfloor object:
    ret_instr_obj = capfloor;

% ==============================================================================    
%Equity Forward valuation
elseif (strcmpi(tmp_type,'forward') )
    % Using forward class
        forward = instr_obj;
     % Get underlying Index / instrument    
        tmp_underlying = forward.get('underlying_id');
        [tmp_underlying_object object_ret_code]  = get_sub_object(index_struct, tmp_underlying);
        if ( object_ret_code == 0 )
			% assuming underlying is instrument
			[tmp_underlying_object object_ret_code]  = get_sub_object(instrument_struct, tmp_underlying);
			if ( object_ret_code == 0 )
				fprintf('WARNING: instrument_valuation of id >>%s<<: No index_struct object found for id >>%s<<\n',forward.id,any2str(tmp_underlying));
				fprintf('WARNING: instrument_valuation of id >>%s<<: No instrument_struct object found for id >>%s<<\n',forward.id,any2str(tmp_underlying));
			else
			% calculate underlying values
				if ~( strcmpi(class(tmp_underlying_object),'Index'))   % valuate instruments only
					tmp_underlying_object = tmp_underlying_object.valuate(valuation_date, scenario, ...
										instrument_struct, surface_struct, ...
										matrix_struct, curve_struct, index_struct, ...
										riskfactor_struct, para_struct); 
				end
			end
		end
    % Get discount curve
        tmp_discount_curve                  = forward.get('discount_curve');            
        [tmp_curve_object object_ret_code]  = get_sub_object(curve_struct, tmp_discount_curve);	
        if ( object_ret_code == 0 )
            fprintf('WARNING: instrument_valuation: No curve_struct object found for id >>%s<<\n',tmp_discount_curve);
        end

    %Calculate values of equity forward
    if (~strcmpi(scenario,'base') )
    % Base value
        forward = forward.calc_value(valuation_date,'base',tmp_curve_object,tmp_underlying_object);
    end
    % calculation of value for scenario               
        forward = forward.calc_value(valuation_date,scenario,tmp_curve_object,tmp_underlying_object);

    % store bond object:
    ret_instr_obj = forward;
	
% ==============================================================================   
% Equity Valuation: Sensitivity based Approach       
elseif ( strcmpi(tmp_type,'sensitivity'))
	 % Using Synthetic class
    sensi = instr_obj;
        
    sensi = sensi.calc_value(valuation_date,scenario,riskfactor_struct,instrument_struct,index_struct,curve_struct,surface_struct,scen_number);
    % store sensi object:
    ret_instr_obj = sensi;

	% ==============================================================================
% Synthetic Instrument Valuation: synthetic value is linear combination of underlying instrument values      
elseif ( strcmpi(tmp_type,'synthetic'))
    % Using Synthetic class
    synth = instr_obj;
    
	% valuate all underlying instruments
	undr_instr_cell = synth.get('instruments');
	for kk=1:1:length(undr_instr_cell)
		tmp_undr_id = undr_instr_cell{kk};
		% assuming underlying is instrument
		[tmp_underlying_object object_ret_code]  = get_sub_object(instrument_struct, tmp_undr_id);
		if ( object_ret_code == 0 )
				fprintf('WARNING: instrument_valuation of id >>%s<<: No instrument_struct object found for id >>%s<<\n',synth.id,any2str(tmp_undr_id));
		else
			% delete scenario values (in any case)
			tmp_underlying_object = tmp_underlying_object.del_scen_data;
			% calculate underlying values
			if ( ~strcmpi(scenario,'base'))
				tmp_underlying_object = tmp_underlying_object.valuate(valuation_date, 'base', ...
										instrument_struct, surface_struct, ...
										matrix_struct, curve_struct, index_struct, ...
										riskfactor_struct, para_struct);
			end
			tmp_underlying_object = tmp_underlying_object.valuate(valuation_date, scenario, ...
										instrument_struct, surface_struct, ...
										matrix_struct, curve_struct, index_struct, ...
										riskfactor_struct, para_struct);
			% overwrite object in instrument_struct
			instrument_struct = replace_sub_object(instrument_struct,tmp_underlying_object);
		end
	end
	% valuate synthetic instrument
	if ( ~strcmpi(scenario,'base'))
		synth = synth.calc_value(valuation_date,'base',instrument_struct,index_struct);
	end
    synth = synth.calc_value(valuation_date,scenario,instrument_struct,index_struct);
    % store bond object:
    ret_instr_obj = synth;

% ==============================================================================	
% Cashflow Valuation: summing net present value of all cashflows according to cashflowdates
elseif ( sum(strcmpi(tmp_type,'bond')) > 0 ) 
    % Using Bond class
        bond = instr_obj;
		
	% check, whether instrument already valuated for current scenario --> delete properties
       if ~(strcmpi(scenario,'base') || strcmpi(scenario,'stress'))
           if ( sum(strcmpi(bond.timestep_mc_cf,scenario))>0)   % scenario already exists
               bond = bond.set('timestep_mc_cf',{});
               bond = bond.set('cf_values_mc',[]);
           end
       end

    % a) Get curve parameters    
      % get discount curve
        tmp_discount_curve  = bond.get('discount_curve');
        [tmp_curve_object object_ret_code]    = get_sub_object(curve_struct, tmp_discount_curve); 
        if ( object_ret_code == 0 )
            fprintf('WARNING: instrument_valuation: No curve_struct object found for id >>%s<<\n',tmp_discount_curve);
        end
     
    % b) Get Cashflow dates and values of instrument depending on type (cash settlement):
        if( sum(strcmpi(tmp_sub_type,{'FRB','SWAP_FIXED','ZCB','CASHFLOW'})) > 0 )       % Fixed Rate Bond instruments (incl. swap fixed leg)
            % rollout cash flows for all scenarios
            bond = bond.rollout('base',valuation_date);
            % cash flow values are equal for base and all scenarios -> copy values without new rollout
            if ( strcmpi(scenario,'stress') && ~strcmpi(scenario,'base'))
               bond = bond.set('cf_values_stress',bond.get('cf_values'));
            elseif ~(strcmpi(scenario,'stress') && strcmpi(scenario,'base'))
               bond = bond.set('cf_values_mc',bond.get('cf_values'),'timestep_mc_cf',scenario);
            end

		elseif (strcmpi(tmp_sub_type,'ILB') )
			% get inflation expectation curve
			iec_id  = bond.get('infl_exp_curve');
			[iec_curve object_ret_code]    = get_sub_object(curve_struct, iec_id); 
			if ( object_ret_code == 0 )
				fprintf('WARNING: instrument_valuation: No inflation expectation curve_struct object found for id >>%s<<\n',iec_curve);
			end
			% get historical inflation curve
			hist_id  = bond.get('cpi_historical_curve');
			[hist_curve object_ret_code]    = get_sub_object(curve_struct, hist_id); 
			if ( object_ret_code == 0 )
				fprintf('WARNING: instrument_valuation: No historical inflation curve_struct object found for id >>%s<<\n',hist_id);
			end
			% get consumer price index
			cpi_id  = bond.get('cpi_index');
			[cpi_index object_ret_code]    = get_sub_object(index_struct, cpi_id); 
			if ( object_ret_code == 0 )
				fprintf('WARNING: instrument_valuation: No consumer price index_struct object found for id >>%s<<\n',cpi_id);
			end
			% cashflow rollout		
			if (~strcmpi(scenario,'base') )
                bond = bond.rollout('base',valuation_date,iec_curve,hist_curve,cpi_index);
            end
            bond = bond.rollout(scenario,valuation_date,iec_curve,hist_curve,cpi_index);

			
        elseif ( strcmpi(tmp_sub_type,'FAB') )
            % cash flow rollout
            if ( bond.prepayment_flag == true  ) % fixed amortizing bond with prepayment
                if ( strcmpi(bond.prepayment_source,'curve'))
                    psa_curve_id  = bond.get('prepayment_curve');
                    [psa_curve object_ret_code]    = get_sub_object(curve_struct, psa_curve_id); 
                    if ( object_ret_code == 0 )
                        fprintf('WARNING: instrument_valuation: No psa curve_struct object found for id >>%s<<\n',psa_curve_id);
                    end
                else
                    psa_curve = Curve();
                end
                % get prepayment procedure (if any)
                pp_surface_id = bond.get('prepayment_procedure');
                if ( isempty(pp_surface_id))
                    pp_surface = [];
                else
                    [pp_surface object_ret_code]    = get_sub_object(surface_struct, pp_surface_id); 
                    if ( object_ret_code == 0 )
                        fprintf('WARNING: instrument_valuation: No prepayment procedure surface_struct object found for id >>%s<<\n',pp_surface_id);
                    end
                end
                % get ir curve
                tmp_ir_curve  = bond.get('discount_curve');
                [tmp_curve_object object_ret_code]    = get_sub_object(curve_struct, tmp_ir_curve); 
                if ( object_ret_code == 0 )
                    fprintf('WARNING: instrument_valuation: No discount curve_struct object found for id >>%s<<\n',tmp_ir_curve);
                end
            
                if (~strcmpi(scenario,'base') )
                    bond = bond.rollout('base',valuation_date,psa_curve,pp_surface,tmp_curve_object);
                end
                bond = bond.rollout(scenario,valuation_date,psa_curve,pp_surface,tmp_curve_object);
            else % fixed amortizing bond without prepayment
                bond = bond.rollout('base',valuation_date);
				% cash flow values are equal for base and all scenarios -> copy values without new rollout
				if ( strcmpi(scenario,'stress') && ~strcmpi(scenario,'base'))
				   bond = bond.set('cf_values_stress',bond.get('cf_values'));
				elseif ~(strcmpi(scenario,'stress') && strcmpi(scenario,'base'))
				   bond = bond.set('cf_values_mc',bond.get('cf_values'),'timestep_mc_cf',scenario);
				end
			end
        elseif( strcmpi(tmp_sub_type,'FRN') || strcmpi(tmp_sub_type,'SWAP_FLOATING'))       % Floating Rate Notes (incl. swap floating leg)
             %get reference curve object used for calculating floating rates:
                tmp_ref_curve   = bond.get('reference_curve');
                tmp_ref_object 	= get_sub_object(curve_struct, tmp_ref_curve);
            % rollout cash flows for all scenarios
                if (~strcmpi(scenario,'base') )
                    bond = bond.rollout('base',tmp_ref_object,valuation_date);
                end
                bond = bond.rollout(scenario,tmp_ref_object,valuation_date);
        elseif( strcmpi(tmp_sub_type,'FRN_SPECIAL') || regexpi(tmp_sub_type,'CMS') )     % FRN_SPECIAL, CMS Swaplets
            %get reference curve object used for calculating floating rates:
                tmp_ref_curve   = bond.get('reference_curve');
                tmp_ref_object 	= get_sub_object(curve_struct, tmp_ref_curve);
                tmp_surface     = bond.get('vola_surface');
                tmp_surf_object = get_sub_object(surface_struct, tmp_surface);
            % rollout cash flows for all scenarios 
				if (~strcmpi(scenario,'base') )
                    bond = bond.rollout('base', valuation_date,tmp_ref_object,tmp_surf_object);
                end
                bond = bond.rollout(scenario, valuation_date,tmp_ref_object,tmp_surf_object);

        elseif( strcmpi(tmp_sub_type,'STOCHASTIC') )       % Stochastic CF instrument
             %get riskfactor object and surface object:
                tmp_riskfactor   = bond.get('stochastic_riskfactor');
                tmp_rf_obj 	     = get_sub_object(curve_struct, tmp_riskfactor);
                tmp_surface      = bond.get('stochastic_surface');
                tmp_surf_obj 	 = get_sub_object(riskfactor_struct, tmp_surface);
            % rollout cash flows for all scenarios
                if (~strcmpi(scenario,'base') )
                    bond = bond.rollout('base',tmp_rf_obj,tmp_surf_obj);
                end
                bond = bond.rollout(scenario,tmp_rf_obj,tmp_surf_obj); 
        else
            fprintf('WARNING: instrument_valuation: unknown BOND sub_type >>%s<< for id >>%s<<\n',bond.id,tmp_sub_type);
        end 
    % c) Calculate spread over yield (if not already run...)
        if ( bond.get('calibration_flag') == 0 )
            bond = bond.calc_spread_over_yield(valuation_date,tmp_curve_object);
        end
    % d) get net present value of all Cashflows (discounting of all cash flows)
       if (~strcmpi(scenario,'base') )
            bond = bond.calc_value (valuation_date,'base',tmp_curve_object);
            % calculate sensitivities
            if( strcmpi(tmp_sub_type,'FRN') || strcmpi(tmp_sub_type,'SWAP_FLOATING'))
                bond = bond.calc_sensitivities(valuation_date,tmp_curve_object,tmp_ref_object);
            else
                bond = bond.calc_sensitivities(valuation_date,tmp_curve_object);
            end
            % calculate key rate durations and convexities - computationally very expensive!
            bond = bond.calc_key_rates(valuation_date,tmp_curve_object);
		else
			% calculate sensitivities
            if( strcmpi(tmp_sub_type,'FRN') || strcmpi(tmp_sub_type,'SWAP_FLOATING'))
                bond = bond.calc_sensitivities(valuation_date,tmp_curve_object,tmp_ref_object);
            else
                bond = bond.calc_sensitivities(valuation_date,tmp_curve_object);
            end
            % calculate key rate durations and convexities - computationally very expensive!
            bond = bond.calc_key_rates(valuation_date,tmp_curve_object);
        end
        % final valuation of bond
        bond = bond.calc_value (valuation_date,scenario,tmp_curve_object);


    % e) store bond object:
    ret_instr_obj = bond;
	
% ==============================================================================
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
 
% ============================================================================== 
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

% helper function
function instrument_struct = replace_sub_object(instrument_struct,object)
	a = {instrument_struct.id};
	b = 1:1:length(a);
	c = strcmpi(a, object.id);
	% instrument_struct contains object
	if sum(c) > 0
		idx = b * c';
	else % append object to instrument_struct
		idx = length(instrument_struct) + 1;
	end
	instrument_struct(idx).id = object.id;
	instrument_struct(idx).object = object;
end
%# Copyright (C) 2017 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{position_struct} @var{position_failed_cell} @var{portfolio_value} @var{portfolio_shock}] =} aggregate_positions (@var{position_struct}, @var{position_failed_cell}, @var{instrument_struct}, @var{index_struct}, @var{scennumber},  @var{scen_set}, @var{fund_currency}, @var{port_id}, @var{printflag})
%#
%# Aggregate position and portfolio base, stress and MC scenarios shocks.
%# Instrument MC values are aggregated and converted to fund currency based
%# on position information (quantity and position ID referencing instrument ID).@*
%# Return total portfolio base, stress or MC values and position struct with new keys 
%# \'basevalue\', \'stresstests\' or \'mc_scenarios\' according to provided scenario set.
%# @*
%# Input:
%# @itemize @bullet
%# @item @var{position_struct}: structure with position definitions (quantity and ID)
%# @item @var{position_failed_cell}: failing position ids are stored in this cell
%# @item @var{instrument_struct}: structure with instrument objects
%# @item @var{index_struct}: structure with FX objects
%# @item @var{scennumber}: number of stress or MC scenarios
%# @item @var{scen_set}: Scenario set used for aggregation (e.g. base, stress, 250d or 1d) 
%# @item @var{fund_currency}: FX conversion of instrument values into fund currency
%# @item @var{port_id}: Portfolio ID
%# @item @var{printflag}: Boolean flag: true = print information about aggregation to stdout
%# @end itemize
%# @seealso{aggregate_position_base}
%# @end deftypefn

function [position_struct position_failed_cell retvec] = aggregate_positions(position_struct,position_failed_cell,instrument_struct,index_struct,scennumber,scen_set,fund_currency,port_id,printflag)

% Loop through all positions and calculate portfolio MC shock and position MC constributions
portfolio_shock      = zeros(scennumber,1);
portfolio_value		 = 0.0;
portfolio_stress    = zeros(scennumber,1);
if (printflag == true && strcmpi(scen_set,'base'))
	fprintf('=== Aggregation for Portfolio >>%s<< ===\n',port_id);
    fprintf('ID,BaseValue,Quantity,FX_Rate,Portfoliovalue\n');
end	

% loop through all positions and aggregate instruments
for ii = 1 : 1 : length( position_struct )
	tmp_id = position_struct( ii ).id;
	tmp_quantity = position_struct( ii ).quantity;
	try
		[tmp_instr_object object_ret_code]  = get_sub_object(instrument_struct, tmp_id);
		if ( object_ret_code == 0 )
			error('octarisk: WARNING: No instrument_struct object found for id >>%s<<\n',tmp_id);
		end	
		tmp_value = tmp_instr_object.getValue('base');
		tmp_currency = tmp_instr_object.get('currency');

		% Get instrument Value from full valuation instrument_struct:
		% absolute values from full valuation
		new_value_vec_shock      = tmp_instr_object.getValue(scen_set);              
	   
		% Get FX rate:
		if ( strcmp(fund_currency,tmp_currency) == 1 )
			tmp_fx_value_shock   = 1;
			tmp_fx_rate_base = 1;
		else
			%disp( ' Conversion of currency: ');
			tmp_fx_index   		= strcat('FX_', fund_currency, tmp_currency);
			[tmp_fx_struct_obj object_ret_code]  = get_sub_object(index_struct, tmp_fx_index);
			if ( object_ret_code == 0 )
				error('octarisk: WARNING: No index_struct object found for FX id >>%s<<\n',tmp_fx_index);
			end	
			tmp_fx_rate_base    = tmp_fx_struct_obj.getValue('base');
			tmp_fx_value_shock  = tmp_fx_struct_obj.getValue(scen_set);   
		end
		
		if (strcmpi(scen_set,'base'))		
			position_struct( ii ).basevalue = tmp_value .* tmp_quantity ./ tmp_fx_rate_base;
			portfolio_value = portfolio_value + tmp_value .* tmp_quantity  ./ tmp_fx_rate_base;
			if (printflag == true)
				fprintf('%s,%9.8f,%9.8f,%9.8f,%9.8f\n',tmp_id,tmp_value,tmp_quantity,tmp_fx_rate_base,portfolio_value);
			end	
		elseif (strcmpi(scen_set,'stress'))	 % Stress scenario set
			% Store new Values in Position's struct
			pos_vec_stress  = new_value_vec_shock .*  sign(tmp_quantity) ./ tmp_fx_value_shock;
			%octamat = [  pos_vec_stress ] ;
			position_struct( ii ).stresstests = pos_vec_stress;
			portfolio_stress = portfolio_stress + new_value_vec_shock .*  tmp_quantity ./ tmp_fx_value_shock;
		else	% MC scenario set
			% Store new MC Values in Position's struct
			pos_vec_shock 	= new_value_vec_shock .* sign(tmp_quantity) ./ tmp_fx_value_shock; % convert position PnL into fund currency
			octamat = [  pos_vec_shock ] ;
			position_struct( ii ).mc_scenarios.octamat = octamat; 
			portfolio_shock = portfolio_shock +  tmp_quantity .* new_value_vec_shock ./ tmp_fx_value_shock;
		end
	catch	% if instrument not found raise warning and populate cell
		fprintf('Instrument ID %s not found for position. There was an error: %s\n',tmp_id,lasterr);
		position_failed_cell{ length(position_failed_cell) + 1 } =  tmp_id;
	end
	
end % end position loop

% prepare return vector
if (strcmpi(scen_set,'base'))
	retvec = portfolio_value;
elseif (strcmpi(scen_set,'stress'))	% Stress scenario set
	retvec = portfolio_stress;
else	% MC scenario set
	retvec = portfolio_shock;
end

end	% end function
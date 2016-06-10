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
%# @deftypefn {Function File} { @var{object} =} Instrument (@var{name}, @var{id}, 
%# @var{description}, @var{type}, @var{currency}, @var{base_value}, 
%# @var{asset_class}, @var{valuation_date})
%# Instrument Superclass Inputs:
%# @itemize @bullet
%# @item @var{name} (string): Name of object
%# @item @var{id} (string): Id of object
%# @item @var{description} (string): Description of object
%# @item @var{type} (string): instrument type in list [cash, bond, debt, forward, 
%# option, sensitivity, synthetic]
%# @item @var{currency} (string): ISO code of currency
%# @item @var{base_value} (float): Actual base (spot) value of object
%# @item @var{asset_class} (sring): Instrument asset class
%# @item @var{valuation_date} (datenum): serial day number from Jan 1, 0000 
%# defined as day 1. 
%# @end itemize
%# @*
%# The constructor of the instrument class constructs an object with the 
%# following properties and inherits them to all sub classes: @*
%# @itemize @bullet
%# @item name: Name of object
%# @item id: Id of object
%# @item description: Description of object
%# @item value_base: Actual base (spot) value of object
%# @item currency: ISO code of currency
%# @item asset_class: Instrument asset class
%# @item type: Type of Instrument class (Bond,Forward,...) 
%# @item valuation_date: date format DD-MMM-YYYY 
%# @item value_stress: Vector with values under stress scenarios
%# @item value_mc: Matrix with values under MC scenarios (values per timestep 
%# per column)
%# @item timestep_mc: MC timestep per column (cell string)
%# @end itemize
%# 
%# @var{value} = Instrument.getValue (@var{base}, @var{stress}, @var{mc_timestep})
%# Superclass Method getValue 
%# @*
%# Return the scenario (shock) value for an instrument object. Specify the 
%# desired return values with a property parameter.
%# If the second argument abs is set, the absolut scenario value is calculated 
%# from scenario shocks and the risk factor start value.
%# @*
%# Timestep properties:
%# @itemize @bullet
%# @item base: return base value
%# @item stress: return stress values
%# @item 1d: return MC timestep
%# @end itemize
%# @*
%# @var{boolean} = Instrument.isProp (@var{property}) 
%# Instrument Method isProp
%# @*
%# Query all properties from the Instrument Superclass and sub classes and 
%# returns 1 in case of a valid property.
%# @*
%# @*
%# @seealso{Instrument}
%# @end deftypefn


function a = doc_instrument()
    % this is only a dummy function for containing all the documentation.
end

%!test 
%! fprintf('HOLD ON...\n');
%! fprintf('\tdoc_instrument:\tPricing Fixed Rate Bond Object\n');
%! b = Bond();
%! b = b.set('Name','Test_FRB','coupon_rate',0.035,'value_base',101.25);
%! b = b.rollout('base');
%! b = b.calc_yield_to_mat('31-Mar-2016');
%! assert(b.ytm,0.0349760324228150,0.000001)
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650],'rates_base',[0.01,0.04],'method_interpolation','monotone-convex');
%! c = c.set('rates_stress',[0.02,0.05;0.005,0.014]);
%! b = b.calc_spread_over_yield(c,'31-Mar-2016');
%! assert(b.soy,-0.00195601583956151,0.000000001);
%! b = b.calc_value('31-Mar-2016',c,'base');
%! assert(b.getValue('base'),101.249998584740,0.000000001);
%! b = b.rollout('stress');
%! b = b.calc_value('31-Mar-2016',c,'stress');
%! assert(b.getValue('stress'),[93.8990094561457;120.8670123921738],0.000000001); 

%!test
%! fprintf('\tdoc_instrument:\tPricing EQ Forward Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650,7300],'rates_base',[0.0001002070,0.0045624391,0.009346842],'method_interpolation','linear');
%! i = Index();
%! i = i.set('value_base',326.900);
%! f = Forward();
%! f = f.set('name','EQ_Forward_Index_Test','maturity_date','26-Mar-2036','strike_price',0.00,'valuation_date','31-Mar-2016');
%! f = f.calc_value(c,'base',i);
%! assert(f.getValue('base'),326.9,0.1);
%! f = f.set('strike_price',426.900);
%! f = f.calc_value(c,'base',i);
%! assert(f.getValue('base'),-27.2118960639903,0.00000001);
%! i = i.set('scenario_stress',[350.00;300.00]);
%! f = f.calc_value(c,'stress',i);
%! assert(f.getValue('stress'),[-4.1118960639903;-54.1118960639903],0.00000001);


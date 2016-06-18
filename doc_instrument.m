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
%! b = b.set('Name','Test_FRB','coupon_rate',0.035,'value_base',101.25,'coupon_generation_method','forward');
%! b = b.set('maturity_date','01-Feb-2025','notional',100,'compounding_type','simple','issue_date','01-Feb-2011');
%! b = b.rollout('base','31-Mar-2016');
%! b = b.calc_yield_to_mat('31-Mar-2016');
%! assert(b.ytm,0.0340800096184803,0.000001)
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650],'rates_base',[0.01,0.04],'method_interpolation','monotone-convex');
%! c = c.set('rates_stress',[0.02,0.05;0.005,0.014]);
%! b = b.calc_spread_over_yield(c,'31-Mar-2016');
%! assert(b.soy,-0.00368829585440858,0.00001);
%! b = b.set('soy',0.00);
%! b = b.calc_value('31-Mar-2016',c,'base');
%! assert(b.getValue('base'),99.1420775289364,0.00001);
%! b = b.rollout('stress','31-Mar-2016');
%! b = b.calc_value('31-Mar-2016',c,'stress');
%! assert(b.getValue('stress'),[91.8547937772494;118.8336876898364],0.0000001); 

%!test
%! fprintf('\tdoc_instrument:\tPricing EQ Forward Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650,7300],'rates_base',[0.0001002070,0.0045624391,0.009346842],'method_interpolation','linear');
%! i = Index();
%! i = i.set('value_base',326.900);
%! f = Forward();
%! f = f.set('name','EQ_Forward_Index_Test','maturity_date','26-Mar-2036','strike_price',0.00,'valuation_date','31-Mar-2016');
%! f = f.set('compounding_freq','annual');
%! f = f.calc_value('base',c,i);
%! assert(f.getValue('base'),326.9,0.1);
%! f = f.set('strike_price',426.900);
%! f = f.calc_value('base',c,i);
%! assert(f.getValue('base'),-27.2118960639903,0.00000001);
%! i = i.set('scenario_stress',[350.00;300.00]);
%! f = f.calc_value('stress',c,i);
%! assert(f.getValue('stress'),[-4.1118960639903;-54.1118960639903],0.00000001);

%!test
%! fprintf('\tdoc_instrument:\tPricing FX Forward Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650,7300],'rates_base',[0.0001002070,0.0045624391,0.009346842],'method_interpolation','linear');
%! fc = Curve();
%! fc = fc.set('id','IR_USD','nodes',[365,3650],'rates_base',[0.0063995279,0.01557504],'method_interpolation','linear');
%! i = Index();
%! i = i.set('value_base',1.139549999,'name','FX_USDEUR','id','FX_USDEUR');
%! f = Forward();
%! f = f.set('name','FX_Forward_Domestic_EUR_Foreign_USD','maturity_date','29-Mar-2026','strike_price',0.00,'valuation_date','31-Mar-2016','sub_type','FX');
%! f = f.set('compounding_freq','annual');
%! f = f.calc_value('base',c,i,fc);
%! assert(f.getValue('base'),0.8384017838301,0.00001);
%! f = f.set('strike_price',0.9);
%! f = f.calc_value('base',c,i,fc);
%! assert(f.getValue('base'),-0.021458892902570,0.000001);

%!test
%! fprintf('\tdoc_instrument:\tPricing Swaption Object\n');
%! r = Riskfactor();
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[730,4380],'rates_base',[0.0001001034,0.0062559362],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',30,'axis_x_name','TENOR','axis_y',45,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.659802);
%! v = v.set('type','IR');
%! s = Swaption();
%! s = s.set('maturity_date','31-Mar-2018');
%! s = s.set('strike',0.0175,'multiplier',100);
%! s = s.calc_value('base',r,c,v,'31-Mar-2016');
%! assert(s.getValue('base'),0.89117199789300,0.0000001);
%! s = s.set('value_base',0.9069751298);
%! s = s.calc_vola_spread(r,c,v,'31-Mar-2016');
%! s = s.calc_value('base',r,c,v,'31-Mar-2016');
%! assert(s.getValue('base'),0.906975102470711,0.00001);

%!test
%! fprintf('\tdoc_instrument:\tPricing European Option Object\n');
%! r = Riskfactor();
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[730,3650,4380],'rates_base',[0.0001001034,0.0045624391,0.0062559362],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',3650,'axis_x_name','TERM','axis_y',1.1,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.210360082233);
%! v = v.set('type','INDEX');
%! i = Index();
%! i = i.set('value_base',326.9);
%! o = Option();
%! o = o.set('maturity_date','29-Mar-2026');
%! o = o.set('strike',384.7481,'multiplier',1);
%! o = o.calc_value('base',i,r,c,v,'31-Mar-2016');
%! assert(o.getValue('base'),71.4875735979,0.0000001);
%! o = o.set('value_base',70.00);
%! o = o.calc_vola_spread(i,r,c,v,'31-Mar-2016');
%! assert(o.getValue('base'),70.000,0.001);
%! o = o.calc_greeks('base',i,r,c,v,'31-Mar-2016');

%!test
%! fprintf('\tdoc_instrument:\tPricing American Option Object\n');
%! r = Riskfactor();
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[730,3650,4380],'rates_base',[0.0001001034,0.0045624391,0.0062559362],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',3650,'axis_x_name','TERM','axis_y',1.1,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.210360082233);
%! v = v.set('type','INDEX');
%! i = Index();
%! i = i.set('value_base',286.867623322,'currency','USD');
%! o = Option();
%! o = o.set('maturity_date','29-Mar-2026','currency','USD','timesteps_size',5,'willowtree_nodes',30);
%! o = o.set('strike',368.7362,'multiplier',1,'sub_Type','OPT_AM_P');
%! o = o.calc_value('base',i,r,c,v,'31-Mar-2016');
%! assert(o.getValue('base'),123.043,0.001);
%! o = o.set('value_base',100);
%! o = o.calc_vola_spread(i,r,c,v,'31-Mar-2016');
%! assert(o.getValue('base'),100.000,0.001);

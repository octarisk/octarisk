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
%# @deftypefn {Function File} { @var{object} =} Instrument (@var{name}, @var{id}, @var{description}, @var{type}, @var{currency}, @var{base_value}, @var{asset_class}, @var{valuation_date})
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
    % this is only a dummy function for containing all the documentation
    % and unittests for instrument classes.
end

%!test 
%! fprintf('HOLD ON...\n');
%! fprintf('\tdoc_instrument:\tPricing 1st Fixed Rate Bond Object\n');
%! b = Bond();
%! b = b.set('Name','Test_FRB','coupon_rate',0.035,'value_base',101.25,'coupon_generation_method','forward');
%! b = b.set('maturity_date','01-Feb-2025','notional',100,'compounding_type','simple','issue_date','01-Feb-2011');
%! b = b.rollout('base','31-Mar-2016');
%! assert(b.get('last_coupon_date'),-59);
%! b = b.calc_yield_to_mat('31-Mar-2016');
%! assert(b.ytm,0.0340800096184803,0.000001);
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650],'rates_base',[0.01,0.04],'method_interpolation','monotone-convex');
%! c = c.set('rates_stress',[0.02,0.05;0.005,0.014]);
%! b = b.calc_spread_over_yield(c,'31-Mar-2016');
%! assert(b.soy,-0.00368829585440858,0.00001);
%! b = b.set('soy',0.00);
%! b = b.calc_value('31-Mar-2016',c,'base');
%! b = b.calc_sensitivities('31-Mar-2016',c);
%! assert(b.getValue('base'),99.1420775289364,0.00001);
%! assert(b.get('convexity'),67.9346351630012,0.00001);
%! assert(b.get('mod_duration'),5.63642375918384,0.00001);
%! assert(b.get('eff_duration'),5.65744733575198,0.00001);
%! assert(b.get('mac_duration'),7.66223670737639,0.00001);
%! b = b.rollout('stress','31-Mar-2016');
%! b = b.calc_value('31-Mar-2016',c,'stress');
%! assert(b.getValue('stress'),[91.8547937772494;118.8336876898364],0.0000001); 

%!test 
%! fprintf('\tdoc_instrument:\tPricing 2nd Fixed Rate Bond Object\n');
%! b = Bond();
%! b = b.set('Name','Test_FRB','coupon_rate',0.015,'value_base',101.25,'coupon_generation_method','backward');
%! b = b.set('maturity_date','09-Nov-2026','notional',100,'compounding_type','simple','issue_date','22-Nov-2011');
%! b = b.rollout('base','31-Dec-2015');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015],'rates_base',[0.00010026,0.00010027,0.00010027,0.00010014,0.00010009,0.00096236,0.00231387,0.00376975,0.005217,0.00660956,0.00791501,0.00910955,0.01018287],'method_interpolation','linear');
%! b = b.calc_value('31-Dec-2015',c,'base');
%! assert(b.getValue('base'),105.619895060083,0.0000001)
%! b = b.calc_sensitivities('31-Mar-2016',c);
%! assert(b.get('last_coupon_date'),-52);
%! assert(b.get('convexity'),172.588468050282,0.0000001)
%! assert(b.get('mod_duration'),9.09611845785009,0.0000001)
%! assert(b.get('mac_duration'),10.0933391311049,0.0000001)
%! assert(b.get('eff_duration'),9.17981338892828,0.0000001)
%! assert(b.get('dollar_duration'),960.731076972209,0.0000001)
%! assert(b.get('eff_convexity'),174.205420287148,0.0000001)
%! assert(b.get('dv01'),0.096073195268687,0.0000001)
%! assert(b.get('pv01'),-0.0959820513046878,0.0000001)
%! assert(b.get('spread_duration'),9.17981338892828,0.0000001)
%!test 
%! fprintf('HOLD ON...\n');
%! fprintf('\tdoc_instrument:\tPricing Floating Rate Bond Object\n');
%! b = Bond();
%! b = b.set('Name','Test_FRN','coupon_rate',0.00,'value_base',99.7527,'coupon_generation_method','backward','compounding_type','simple');
%! b = b.set('maturity_date','30-Mar-2017','notional',100,'compounding_type','simple','issue_date','21-Apr-2011');
%! b = b.set('term',3,'last_reset_rate',-0.0024,'sub_Type','FRN','spread',0.003);
%! r = Curve();
%! r = r.set('id','REF_IR_EUR','nodes',[30,91,365,730],'rates_base',[0.0001002740,0.0001002740,0.0001001390,0.0001000690],'method_interpolation','linear');
%! b = b.rollout('base',r,'30-Jun-2016');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[30,90,180,365,730],'rates_base',[0.0019002740,0.0019002740,0.0019002301,0.0019001390,0.001900069],'method_interpolation','linear');
%! b = b.set('clean_value_base',99.7527,'spread',0.003);
%! b = b.calc_spread_over_yield(c,'30-Jun-2016');
%! assert(b.get('soy'), 0.00399948418269946,0.0000001); 
%! b = b.calc_value('30-Jun-2016',c,'base');
%! assert(b.getValue('base'),99.7917725092950,0.0000001);
%! b = b.calc_sensitivities('30-Jun-2016',c,r);
%! assert(b.get('convexity'),1.10779411816050,0.0000001);
%! assert(b.get('eff_convexity'),0.551778553743564,0.0000001);
%! assert(b.get('eff_duration'),-0.00321909293737049,0.0000001);
%! assert(b.get('mac_duration'),0.747367047335932,0.0000001);
%! r = r.set('floor',0.0);
%! b = b.calc_sensitivities('30-Jun-2016',c,r);
%! assert(b.get('eff_convexity'),74.8118222412937,0.0000001);
%! assert(b.get('eff_duration'),0.368081125500380,0.0000001);
%! assert(b.get('mac_duration'),0.747367047335932,0.0000001);
%! assert(b.get('spread_duration'),0.744125307965525,0.0000001)

%!test
%! fprintf('\tdoc_instrument:\tPricing EQ Forward Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650,7300],'rates_base',[0.0001002070,0.0045624391,0.009346842],'method_interpolation','linear');
%! i = Index();
%! i = i.set('value_base',326.900);
%! f = Forward();
%! f = f.set('name','EQ_Forward_Index_Test','maturity_date','26-Mar-2036','strike_price',0.00);
%! f = f.set('compounding_freq','annual');
%! f = f.calc_value('31-Mar-2016','base',c,i);
%! assert(f.getValue('base'),326.9,0.1);
%! f = f.set('strike_price',426.900);
%! f = f.calc_value('31-Mar-2016','base',c,i);
%! assert(f.getValue('base'),-27.2118960639903,0.00000001);
%! i = i.set('scenario_stress',[350.00;300.00]);
%! f = f.calc_value('31-Mar-2016','stress',c,i);
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
%! f = f.set('name','FX_Forward_Domestic_EUR_Foreign_USD','maturity_date','29-Mar-2026','strike_price',0.00,'sub_type','FX');
%! f = f.set('compounding_freq','annual');
%! f = f.calc_value('31-Mar-2016','base',c,i,fc);
%! assert(f.getValue('base'),0.7509742754,0.00001);
%! f = f.set('strike_price',0.9);
%! f = f.calc_value('31-Mar-2016','base',c,i,fc);
%! assert(f.getValue('base'),-0.1088864014,0.000001);

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
%! fprintf('\tdoc_instrument:\tPricing European Barrier Option Object\n');
%! r = Riskfactor();
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[180],'rates_base',[0.08],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.2500);
%! v = v.set('type','INDEX');
%! i = Index();
%! i = i.set('value_base',100);
%! o = Option();
%! o = o.set('maturity_date','30-Sep-2016','sub_Type','OPT_BAR_C');
%! o = o.set('strike',90,'multiplier',1,'div_yield',0.04,'upordown','D','outorin','in');
%! o = o.set('barrierlevel',95,'rebate',3);
%! o = o.calc_value('base',i,r,c,v,'31-Mar-2016');
%! assert(o.getValue('base'),7.77203592837206,0.0000001);
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.2200);
%! v = v.set('type','INDEX');
%! o = o.calc_vola_spread(i,r,c,v,'31-Mar-2016');
%! assert(o.get('vola_spread'),0.030000,0.00001);
%! o = o.calc_greeks('base',i,r,c,v,'31-Mar-2016');

%!test
%! fprintf('\tdoc_instrument:\tPricing American Option Object (Willowtree and Bjerksund and Stensland)\n');
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
%! o = o.set('pricing_function_american','Willowtree');
%! o = o.calc_value('base',i,r,c,v,'31-Mar-2016');
%! assert(o.getValue('base'),123.043,0.001);
%! o = o.set('value_base',100);
%! o = o.calc_vola_spread(i,r,c,v,'31-Mar-2016');
%! assert(o.getValue('base'),100.000,0.001);
%! o = Option();
%! o = o.set('maturity_date','29-Mar-2026','currency','USD');
%! o = o.set('strike',368.7362,'multiplier',1,'sub_Type','OPT_AM_P');
%! o = o.set('pricing_function_american','Bjsten');
%! o = o.calc_value('base',i,r,c,v,'31-Mar-2016');
%! assert(o.getValue('base'),122.2909543913,0.0000001);
%! o = o.set('value_base',100);
%! o = o.calc_vola_spread(i,r,c,v,'31-Mar-2016');
%! assert(o.getValue('base'),100.000,0.0001);
%! o = o.calc_greeks('base',i,r,c,v,'31-Mar-2016');

%!test
%! fprintf('\tdoc_instrument:\tPricing Debt Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[730,3650,4380],'rates_base',[0.0001001034,0.0045624391,0.0062559362],'method_interpolation','linear');
%! c = c.set('rates_stress',[0.0101001034,0.0145624391,0.0162559362;0.0201001034,0.0245624391,0.0262559362],'method_interpolation','linear');
%! d = Debt();
%! d = d.set('duration',8.35,'convexity',18);
%! d = d.calc_value(c,'stress');
%! assert(d.getValue('stress'),[91.83;84.02],0.01);

%!test
%! fprintf('\tdoc_instrument:\tPricing Cap Object with Black Model\n');
%! cap = CapFloor();
%! cap = cap.set('id','TEST_CAP','name','TEST_CAP','issue_date','30-Dec-2018','maturity_date','29-Dec-2020','compounding_type','simple');
%! cap = cap.set('term',365,'notional',10000,'coupon_generation_method','forward','notional_at_start',0,'notional_at_end',0);
%! cap = cap.set('strike',0.005,'model','Black','last_reset_rate',0.0,'day_count_convention','act/365','sub_type','CAP');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[30,1095,1460],'rates_base',[0.01,0.01,0.01],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.8);
%! v = v.set('type','IR');
%! r = Riskfactor();
%! cap = cap.rollout('31-Dec-2015','base',c,v,r);
%! cap = cap.calc_value('31-Dec-2015','base',c);
%! assert(cap.getValue('base'),137.0063959386,0.0000001);

%!test
%! fprintf('\tdoc_instrument:\tPricing Floor Object with Normal Model\n');
%! floor = CapFloor();
%! floor = floor.set('id','TEST_FLOOR','name','TEST_FLOOR','issue_date','30-Dec-2018','maturity_date','29-Dec-2020','compounding_type','simple');
%! floor = floor.set('term',365,'notional',10000,'coupon_generation_method','forward','notional_at_start',0,'notional_at_end',0);
%! floor = floor.set('strike',0.005,'model','Normal','last_reset_rate',0.0,'day_count_convention','act/365','sub_type','FLOOR','convex_adj',false);
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[30,1095,1460,1825],'rates_base',[0.01,0.01,0.01,0.01],'method_interpolation','linear');
%! c = c.set('id','IR_EUR','nodes',[30,1095,1460,1825],'rates_stress',[-0.02,-0.02,-0.01,-0.005;0.02,0.02,0.02,0.02;0.03,0.03,0.03,0.03]);
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.00555);
%! v = v.set('type','IR');
%! r = Riskfactor();
%! floor = floor.rollout('31-Dec-2015','base',c,v,r);
%! floor = floor.calc_value('31-Dec-2015','base',c);
%! assert(floor.getValue('base'),39.9458733223202,0.0000001);
%! floor = floor.rollout('31-Dec-2015','stress',c,v,r);
%! floor = floor.calc_value('31-Dec-2015','stress',c);
%! stress_values = floor.getValue('stress');
%! assert(stress_values,[13.629274436848439;6.092263070602667;0.463877763957439],0.0000001);

%!test 
%! fprintf('\tdoc_instrument:\tTesting get_sub_object function\n');
%! b = Bond();
%! r = Riskfactor();
%! s(1).object = b;
%! s(1).id = b.id;
%! s(2).object = r;
%! s(2).id = r.id;
%! [retstruct retcode] = get_sub_object(s,'BOND_TEST');
%! assert(isequal(retstruct,b),true);
%! assert(retcode,1);
%! s(3).object = b;
%! s(3).id = b.id;
%! [retstruct retcode] = get_sub_object(s,'BOND_TEST');
%! assert(isequal(retstruct,b),true);
%! assert(retcode,1);
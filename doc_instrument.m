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
%! fprintf('\tdoc_instrument:\tPricing Zero Coupon Bond Bond Object\n');
%! b = Bond();
%! b = b.set('Name','Bundesrep.Deutschland Bundesobl.Ser.171 v.2015(20)', 'id','114171','coupon_rate',0.00,'value_base',101.1190,'coupon_generation_method','backward');
%! b = b.set('maturity_date','21-Apr-2020','notional',100,'compounding_type','disc','issue_date','21-Apr-2015','term',12,'compounding_freq',365,'sub_type','ZCB');
%! [ret_dates ret_values ret_int ret_principal accr_int last_coupon_date] = rollout_structured_cashflows('31-Dec-2015','base',b);
%! b = b.rollout('base','31-Dec-2015');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,1095,1825],'rates_base',[-0.00519251,-0.00508595,-0.00367762],'method_interpolation','linear');
%! c = c.set('rates_stress',[-0.00519251,-0.00508595,-0.00367762;-0.00519251,-0.00508595,-0.00367762;-0.00519251,-0.00508595,-0.00367762]);
%! b = b.calc_value('31-Dec-2015','base',c);
%! b = b.rollout('stress','31-Dec-2015');
%! b = b.calc_value('31-Dec-2015','stress',c);
%! assert(b.getValue('stress'),[101.810615897273;101.810615897273;101.810615897273],0.0000001); 
                                                                                                                      
%!test 
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
%! b = b.calc_spread_over_yield('31-Mar-2016',c);
%! assert(b.soy,-0.00274310399175057,0.00001);
%! b = b.set('soy',0.00);
%! b = b.calc_value('31-Mar-2016','base',c);
%! b = b.calc_sensitivities('31-Mar-2016',c);
%! assert(b.getValue('base'),99.1420775289364,0.00001);
%! assert(b.get('convexity'),64.1806456611515,0.00001);
%! assert(b.get('mod_duration'),5.63642375918384,0.00001);
%! assert(b.get('eff_duration'),7.67144764167465,0.00001);
%! assert(b.get('mac_duration'),7.66223670737639,0.00001);
%! b = b.rollout('stress','31-Mar-2016');
%! b = b.calc_value('31-Mar-2016','stress',c);
%! assert(b.getValue('stress'),[91.8547937772494;118.8336876898364],0.0000001); 

%!test 
%! fprintf('\tdoc_instrument:\tPricing 2nd Fixed Rate Bond Object\n');
%! b = Bond();
%! b = b.set('Name','Test_FRB','coupon_rate',0.015,'value_base',101.25,'coupon_generation_method','backward');
%! b = b.set('maturity_date','09-Nov-2026','notional',100,'compounding_type','simple','issue_date','22-Nov-2011');
%! b = b.rollout('base','31-Dec-2015');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015],'rates_base',[0.00010026,0.00010027,0.00010027,0.00010014,0.00010009,0.00096236,0.00231387,0.00376975,0.005217,0.00660956,0.00791501,0.00910955,0.01018287],'method_interpolation','linear');
%! b = b.calc_value('31-Dec-2015','base',c);
%! assert(b.getValue('base'),105.619895060083,0.0000001)
%! b = b.calc_sensitivities('31-Mar-2016',c);
%! assert(b.get('last_coupon_date'),-52);
%! assert(b.get('convexity'),106.724246965278,0.0000001)
%! assert(b.get('mod_duration'),9.09611845785009,0.0000001)
%! assert(b.get('mac_duration'),10.0933391311049,0.0000001)
%! assert(b.get('eff_duration'),10.1124142671261,0.0000001)
%! assert(b.get('dollar_duration'),960.731076972209,0.0000001)
%! assert(b.get('eff_convexity'),106.827013628121,0.0000001)
%! assert(b.get('dv01'),0.106605762118726,0.0000001)
%! assert(b.get('pv01'),-0.106549401094469,0.0000001)
%! assert(b.get('spread_duration'),10.1124142671261,0.0000001)

%!test 
%! fprintf('\tdoc_instrument:\tPricing 3rd Fixed Rate Bond Object\n');
%! b = Bond();
%! b = b.set('Name','Test_FRB','coupon_rate',0.025,'value_base',118.1823,'clean_value_base',0,'coupon_generation_method','backward','term',0);
%! b = b.set('maturity_date','30-Nov-2016','notional',100,'compounding_type','simple','issue_date','30-Nov-2009');
%! b = b.rollout('base','30-Sep-2016');
%! assert(b.get('accrued_interest'),17.0958904109588,0.000000001);
%! assert(b.get('cf_dates'),61);
%! assert(b.getCF('base'),117.513698630137,0.000000001);
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650],'rates_base',[0.01,0.04],'method_interpolation','monotone-convex');
%! c = c.set('rates_stress',[0.02,0.05;0.005,0.014]);
%! b = b.calc_value('30-Sep-2016','base',c);
%! b = b.calc_sensitivities('30-Sep-2016',c);
%! assert(b.getValue('base'),117.317469891155,0.000000001);
%! assert(b.get('eff_duration'),0.167123365467675,0.000000001);
%! assert(b.get('mac_duration'),0.167123287671233,0.000000001);
%! assert(b.get('eff_convexity'),0.0279301997816818,0.000000001);
%! b = b.rollout('stress','30-Sep-2016');
%! b = b.calc_value('30-Sep-2016','stress',c);
%! assert(b.getValue('stress'),[117.121568822210;117.415543267658],0.000000001);

%!test 
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
%! b = b.calc_spread_over_yield('30-Jun-2016',c);
%! assert(b.get('soy'), 0.00398785481397732,0.0000001); 
%! b = b.calc_value('30-Jun-2016','base',c);
%! assert(b.getValue('base'),99.7917725092950,0.0000001);
%! b = b.calc_sensitivities('30-Jun-2016',c,r);
%! assert(b.get('convexity'),0.558796396962633,0.0000001);
%! assert(b.get('eff_convexity'),1.98938819865058e-004,0.0000001);
%! assert(b.get('eff_duration'),3.93109370316470e-005,0.0000001);
%! assert(b.get('mac_duration'),0.747367046218197,0.0000001);
%! r = r.set('floor',0.0);
%! b = b.calc_sensitivities('30-Jun-2016',c,r);
%! assert(b.get('eff_convexity'),74.2605311454306,0.0000001);
%! assert(b.get('eff_duration'),0.371340971970093,0.0000001);
%! assert(b.get('mac_duration'),0.747367046218197,0.0000001);
%! assert(b.get('spread_duration'),0.747374010847449,0.0000001)

%!test 
%! fprintf('\tdoc_instrument:\tPricing Stochastic Cash Flow Object\n');
%! b = Bond();
%! b = b.set('cf_dates',[365,730],'stochastic_riskfactor','RF_TEST','stochastic_surface','SURF_TEST');
%! b = b.set('sub_type','STOCHASTICCF','stochastic_rf_type','uniform');
%! r = Riskfactor();
%! r = r.set('value_base',0.5,'scenario_stress',[0.05;0.50;0.95],'model','BM');
%! value_dates = [365,730];
%! value_quantile = [0.1,0.5,0.9];
%! value_matrix = [90,91;100,100;110,111];
%! v = Surface();
%! v = v.set('axis_x',value_dates,'axis_x_name','DATE','axis_y',value_quantile,'axis_y_name','QUANTILE');
%! v = v.set('values_base',value_matrix);
%! v = v.set('type','STOCHASTIC');
%! b = b.rollout('base',r,v);
%! b = b.rollout('stress',r,v);
%! assert(b.getCF('base'),[100,100]);
%! c = Curve();
%! c = c.set('id','EUR-SWAP','nodes',[365,730], 'rates_base',[0.01,0.02], 'rates_stress',[0.03,0.04;0.01,0.02;0.005,0.01],'method_interpolation','linear');
%! b = b.calc_value('31-Mar-2016','base',c);
%! assert(b.getValue('base'),195.083927290149,0.0000001);


%!test 
%! fprintf('\tdoc_instrument:\tPricing Stochastic Value Object\n');
%! r = Riskfactor();
%! r = r.set('value_base',0.5,'scenario_stress',[0.3;0.50;0.7],'model','BM');
%! value_x = 0;
%! value_quantile = [0.1,0.5,0.9];
%! value_matrix = [90;100;110];
%! v = Surface();
%! v = v.set('axis_x',value_x,'axis_x_name','DATE','axis_y',value_quantile,'axis_y_name','QUANTILE');
%! v = v.set('values_base',value_matrix);
%! v = v.set('type','STOCHASTIC');
%! s = Stochastic();
%! s = s.set('sub_type','STOCHASTIC','stochastic_rf_type','uniform','t_degree_freedom',10);
%! s = s.calc_value('31-Mar-2016','base',r,v);
%! s = s.calc_value('31-Mar-2016','stress',r,v);
%! assert(s.getValue('stress'),[95;100;105]);

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
%! r = Curve();
%! r = r.set('id','IR_EUR','nodes',[3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300], 'rates_base',[0.00368798,0.00452473,0.00526155,0.0059015,0.00644622,0.00689842,0.00726228,0.00754714,0.00776385,0.00792458,0.00804138],'rates_stress',[0.00368798,0.00452473,0.00526155,0.0059015,0.00644622,0.00689842,0.00726228,0.00754714,0.00776385,0.00792458,0.00804138],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',30,'axis_x_name','TENOR','axis_y',45,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.007814230);
%! v = v.set('type','IR');
%! s = Swaption();
%! s = s.set('maturity_date','28-Mar-2026','effective_date','28-Mar-2026');
%! s = s.set('strike',0.0153,'multiplier',100,'sub_type','SWAPT_PAY','model','normal','tenor',10);
%! s = s.set('use_underlyings',false);    
%! s = s.calc_value('31-Mar-2016','base',r,v);
%! s = s.calc_value('31-Mar-2016','stress',r,v);
%! assert(s.getValue('base'),7.66316612096985,0.0000001);
%! assert(s.getValue('stress'),7.66316612096985,0.0000001);
% %! s = s.set('value_base',8.000);
% %! s = s.calc_vola_spread('31-Mar-2016',r,v);
% %! s = s.calc_value('base','31-Mar-2016',r,v);
% %! assert(s.getValue('base'),8.000,0.001);

% %! fprintf('\tdoc_instrument:\tPricing Swaption Object\n');
% %! c = Curve();
% %! c = c.set('id','IR_EUR','nodes',[730,4380],'rates_base',[0.0001001034,0.0062559362],'method_interpolation','linear');
% %! v = Surface();
% %! v = v.set('axis_x',30,'axis_x_name','TENOR','axis_y',45,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
% %! v = v.set('values_base',0.659802);
% %! v = v.set('type','IR');
% %! s = Swaption();
% %! s = s.set('maturity_date','31-Mar-2018');
% %! s = s.set('strike',0.0175,'multiplier',100);
% %! s = s.calc_value('31-Mar-2016','base',c,v);
% %! assert(s.getValue('base'),0.89117199789300,0.0000001);
% %! s = s.set('value_base',0.9069751298);
% %! s = s.calc_vola_spread('31-Mar-2016',c,v);
% %! s = s.calc_value('31-Mar-2016','base',c,v);
% %! assert(s.getValue('base'),0.906975102470711,0.00001);

%!test
%! fprintf('\tdoc_instrument:\tPricing European Option Object\n');
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
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
%! assert(o.getValue('base'),71.4875735979,0.0000001);
%! o = o.set('value_base',70.00);
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.getValue('base'),70.000,0.001);
%! o = o.calc_greeks('31-Mar-2016','base',i,c,v);

%!test
%! fprintf('\tdoc_instrument:\tPricing European Barrier Option Object\n');
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
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
%! assert(o.getValue('base'),7.77203592837206,0.0000001);
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.2200);
%! v = v.set('type','INDEX');
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.get('vola_spread'),0.030000,0.00001);
%! o = o.calc_greeks('31-Mar-2016','base',i,c,v);

%!test
%! fprintf('\tdoc_instrument:\tPricing Asian Geometric Continuous Averaging Option Object\n');
%! r = Riskfactor();
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[180],'rates_base',[0.05],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.200);
%! v = v.set('type','INDEX');
%! i = Index();
%! i = i.set('value_base',80);
%! o = Option();
%! o = o.set('id','Asian_Geometric_Continuous','maturity_date','30-Jun-2016','sub_Type','OPT_ASN_P');
%! o = o.set('strike',85,'multiplier',1,'div_yield',0.03,'averaging_type','rate','averaging_rule','geometric');
%! o = o.set('averaging_monitoring','continuous');
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
%! assert(o.getValue('base'),4.69226159911852,0.000001);
%! o = o.set('value_base',4.900);
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.get('vola_spread'),0.0288927625504014,0.00001);

%!test
%! fprintf('\tdoc_instrument:\tPricing Asian Arithmetic Continuous Averaging Option Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[180],'rates_base',[0.05],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.200);
%! v = v.set('type','INDEX');
%! i = Index();
%! i = i.set('value_base',80);
%! o = Option();
%! o = o.set('id','Asian_Arithmetic_Continuous','maturity_date','30-Jun-2016','sub_Type','OPT_ASN_P');
%! o = o.set('strike',85,'multiplier',1,'div_yield',0.03,'averaging_type','rate','averaging_rule','arithmetic');
%! o = o.set('averaging_monitoring','continuous');
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
%! assert(o.getValue('base'),5.12741689918977,0.000001);
%! o = o.set('value_base',5.00);
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.get('vola_spread'),-0.0241361316761741,0.00001);
%! o = o.calc_greeks('31-Mar-2016','base',i,c,v);
%! assert(o.get('theo_delta'),-0.857787632035219,0.00001);
%! assert(o.get('theo_gamma'),0.0519774521673497,0.00001);
%! assert(o.get('theo_vega'),0.0486623709116500,0.00001);
%! assert(o.get('theo_theta'),-0.00214199425543171,0.00001);
%! assert(o.get('theo_rho'),0.0980383964370191,0.00001);
%! assert(o.get('theo_omega'),-13.7246022124715,0.00001);

%!test
%! fprintf('\tdoc_instrument:\tPricing American Option Object (Willowtree and Bjerksund and Stensland)\n');
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
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
%! assert(o.getValue('base'),123.043,0.001);
%! o = o.set('value_base',100);
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.getValue('base'),100.000,0.001);
%! o = Option();
%! o = o.set('maturity_date','29-Mar-2026','currency','USD');
%! o = o.set('strike',368.7362,'multiplier',1,'sub_Type','OPT_AM_P');
%! o = o.set('pricing_function_american','Bjsten');
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
%! assert(o.getValue('base'),122.2909543913,0.0000001);
%! o = o.set('value_base',100);
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.getValue('base'),100.000,0.0001);
%! o = o.calc_greeks('31-Mar-2016','base',i,c,v);

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
%! cap = cap.rollout('31-Dec-2015','base',c,v);
%! cap = cap.calc_value('31-Dec-2015','base',c);
%! assert(cap.getValue('base'),137.0063959386,0.0000001);


%!test
%! fprintf('\tdoc_instrument:\tPricing CMS Cap Object with Black Model\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[30,1095,1460],'rates_base',[0.01,0.01,0.01],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.8);
%! v = v.set('type','IR');
%! cap_cms = CapFloor();
%! cap_cms = cap_cms.set('id','TEST_CAP','name','TEST_CAP','issue_date','30-Dec-2018','maturity_date','29-Dec-2020','compounding_type','simple');
%! cap_cms = cap_cms.set('term',365,'notional',10000,'coupon_generation_method','forward','notional_at_start',0,'notional_at_end',0);
%! cap_cms = cap_cms.set('strike',0.005,'model','Black','last_reset_rate',0.0,'day_count_convention','act/365','sub_type','CAP_CMS');
%! cap_cms = cap_cms.set('cms_model','Black','cms_sliding_term',365,'cms_term',365,'cms_spread',0.0,'cms_comp_type','simple');
%! cap_cms = cap_cms.rollout( '31-Dec-2015', 'base', c, v);
%! cap_cms = cap_cms.calc_value('31-Dec-2015','base',c);
%! assert(cap_cms.getValue('base'),137.006395938592,0.0000001);

%!test
%! fprintf('\tdoc_instrument:\tPricing 1st Floor Object with Normal Model\n');
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
%! floor = floor.rollout('31-Dec-2015','base',c,v);
%! floor = floor.calc_value('31-Dec-2015','base',c);
%! assert(floor.getValue('base'),39.9458733223202,0.0000001);
%! floor = floor.rollout('31-Dec-2015','stress',c,v);
%! floor = floor.calc_value('31-Dec-2015','stress',c);
%! stress_values = floor.getValue('stress');
%! assert(stress_values,[13.629274436848439;6.092263070602667;0.463877763957439],0.0000001);

%!test
%! fprintf('\tdoc_instrument:\tPricing 2nd Floor Object with Normal Model\n');
%! floor = CapFloor();
%! floor = floor.set('id','TEST_FLOOR','name','TEST_FLOOR','issue_date','30-Jun-2017','maturity_date','30-Jun-2018','compounding_type','simple');
%! floor = floor.set('term',365,'notional',100,'coupon_generation_method','forward','notional_at_start',0,'notional_at_end',0);
%! floor = floor.set('strike',0.05,'model','Normal','last_reset_rate',0.0,'day_count_convention','act/365','sub_type','FLOOR','convex_adj',false);
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,730,1095],'rates_base',[-0.0001756810,-0.0003231590,-0.0002455850],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.00059707);
%! v = v.set('type','IR');
%! floor = floor.rollout('30-Jun-2016','base',c,v);
%! floor = floor.calc_value('30-Dec-2016','base',c);
%! assert(floor.getValue('base'),5.0503156821,0.0000001);


%!test
%! fprintf('\tdoc_instrument:\tPricing CMS Floor Object with Normal Model without CA\n');
%! floor = CapFloor();
%! floor = floor.set('id','TEST_FLOOR','name','TEST_FLOOR','issue_date','29-Jun-2021','maturity_date','29-Jun-2022','compounding_type','simple');
%! floor = floor.set('term',365,'notional',100,'coupon_generation_method','forward','notional_at_start',0,'notional_at_end',0,'ir_shock',0.005);
%! floor = floor.set('strike',0.02,'model','Normal','last_reset_rate',0.0,'day_count_convention','act/365','sub_type','FLOOR_CMS','convex_adj',false);
%! floor = floor.set('cms_model','Normal','cms_sliding_term',365,'cms_term',365,'cms_spread',0.0,'cms_comp_type','simple','cms_convex_model','Hull');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[1460,1825,2190,2555],'rates_base',[-0.0007102520,-0.0000300010,0.0008896040,0.0018981976],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',1825,'axis_x_name','TENOR','axis_y',365,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.0014240366);
%! v = v.set('type','IR');
%! floor = floor.rollout('30-Jun-2016','base',c,v);
%! floor = floor.calc_value('30-Dec-2016','base',c);
%! floor = floor.calc_sensitivities('30-Jun-2016','base',c,v,c);
%! assert(floor.getValue('base'),1.44201131641819,0.000000001);
%! assert(floor.get('eff_duration'),75.3761329917373,0.000000001);
%! assert(floor.get('eff_convexity'),802.649265026805,0.000000001);

%!test
%! fprintf('\tdoc_instrument:\tPricing Bond Future and underlying FRB\n');
%! b = Bond();
%! b = b.set('Name','FRB_TEST','coupon_rate',0.025,'value_base',113.781,'clean_value_base',1,'coupon_generation_method','backward','term',12);
%! b = b.set('maturity_date','04-Jan-2021','notional',100,'compounding_type','simple','issue_date','26-Nov-2010','day_count_convention','act/365');
%! b = b.rollout('base','31-Mar-2016');
%! b = b.rollout('stress','31-Mar-2016');
%! c = Curve();
%! c = c.set('id','EUR-SWAPRAW','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300], ...
%!         'rates_base',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!                     0.004576856,0.005563194,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526], ...
%!         'rates_stress',[-1.38934530e-002,-1.2903390e-002,-1.14941980e-002,-1.15051680e-002,-1.11371070e-002,-1.048215300e-002, ...
%!                     -9.6472220e-003,-8.6925630e-003,-7.6181070e-003,-6.5144340e-003,-5.423144e-003,-4.4368060e-003, ...
%!                     -3.54135400000000e-003,-2.73938000000000e-003,-2.04319200000000e-003,-1.45285700000000e-003, ...
%!                     -9.61179000000000e-004,-5.60903000000000e-004,-2.40827000000001e-004,8.75499999999918e-006,2.00842999999999e-004,3.47525999999999e-004], ...
%!         'method_interpolation','linear');
%! b = b.calc_spread_over_yield('31-Mar-2016',c);
%! assert(b.get('accrued_interest'),0.595890411,0.000001);
%! assert(b.get('soy'),-0.003716422004,0.000001);
%! b = b.calc_value('31-Mar-2016','base',c);
%! b = b.calc_value('31-Mar-2016','stress',c);
%! assert(b.getValue('base'),114.376890411,0.00001);
%! assert(b.getValue('stress'),119.70024104,0.00001);
%! f = Forward();
%! f = f.set('name','BOND_FUTURE_TEST','maturity_date','08-Jun-2016','strike_price',131.13);
%! f = f.set('component_weight',0.863493,'net_basis',-0.009362442,'sub_type','BondFuture');
%! f = f.set('compounding_type','cont','underlying_id','FRB_TEST');
%! f = f.calc_value('31-Mar-2016','base',c,b);
%! f = f.calc_value('31-Mar-2016','stress',c,b);
%! assert(f.getValue('base'),0.0,0.00001);
%! assert(f.getValue('stress'),5.8994582871,0.00001);

%!test 
%! fprintf('\tdoc_instrument:\tPricing Bond Forward and underlying FRB\n');
%! b = Bond();
%! b = b.set('Name','FRB_TEST','coupon_rate',0.0475,'value_base',172.008,'clean_value_base',1,'coupon_generation_method','backward','term',12);
%! b = b.set('maturity_date','04-Jul-2034','notional',100,'compounding_type','simple','issue_date','31-Jan-2003','day_count_convention','act/365');
%! b = b.rollout('base','31-Mar-2016');
%! b = b.rollout('stress','31-Mar-2016');
%! c = Curve();
%! c = c.set('id','EUR-SWAPRAW','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300], ...
%!         'rates_base',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!                     0.004576856,0.005563194,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526], ...
%!         'rates_stress',[-1.38934530e-002,-1.2903390e-002,-1.14941980e-002,-1.15051680e-002,-1.11371070e-002,-1.048215300e-002, ...
%!                     -9.6472220e-003,-8.6925630e-003,-7.6181070e-003,-6.5144340e-003,-5.423144e-003,-4.4368060e-003, ...
%!                     -3.54135400000000e-003,-2.73938000000000e-003,-2.04319200000000e-003,-1.45285700000000e-003, ...
%!                     -9.61179000000000e-004,-5.60903000000000e-004,-2.40827000000001e-004,8.75499999999918e-006,2.00842999999999e-004,3.47525999999999e-004], ...
%!         'method_interpolation','linear');
%! b = b.calc_spread_over_yield('31-Mar-2016',c);
%! assert(b.get('accrued_interest'),3.5267123288,0.0000001);
%! assert(b.get('soy'),-0.003158478713,0.00001);
%! b = b.calc_value('31-Mar-2016','base',c);
%! b = b.calc_value('31-Mar-2016','stress',c);
%! assert(b.getValue('base'),175.53471232881,0.00005);
%! assert(b.getValue('stress'),201.6005801229,0.00005);
%! f = Forward();
%! f = f.set('name','BOND_FORWARD_TEST','maturity_date','17-Oct-2019','strike_price',132.68);
%! f = f.set('sub_type','Bond');
%! f = f.set('compounding_type','cont','underlying_id','FRB_TEST');
%! f = f.calc_value('31-Mar-2016','base',c,b,c);
%! f = f.calc_value('31-Mar-2016','stress',c,b,c);
%! assert(f.getValue('base'),21.9555751042,0.00005);
%! assert(f.getValue('stress'),42.8245029271,0.00005);

%!test 
%! fprintf('\tdoc_instrument:\tPricing Equity Future\n');
%! i = Index();
%! i = i.set('id','EURO_STOXX_50','value_base',3004.93,'scenario_stress',2403.944);
%! c = Curve();
%! c = c.set('id','EUR-SWAPRAW','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300], ...
%!         'rates_base',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!                     0.004576856,0.005563194,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526], ...
%!        'rates_stress',[-1.38934530e-002,-1.2903390e-002,-1.14941980e-002,-1.15051680e-002,-1.11371070e-002,-1.048215300e-002, ...
%!                     -9.6472220e-003,-8.6925630e-003,-7.6181070e-003,-6.5144340e-003,-5.423144e-003,-4.4368060e-003, ...
%!                     -3.54135400000000e-003,-2.73938000000000e-003,-2.04319200000000e-003,-1.45285700000000e-003, ...
%!                     -9.61179000000000e-004,-5.60903000000000e-004,-2.40827000000001e-004,8.75499999999918e-006,2.00842999999999e-004,3.47525999999999e-004], ...
%!         'method_interpolation','linear');
%! f = Forward();
%! f = f.set('name','EQUITY_FUTURE_TEST','maturity_date','17-Jun-2016','strike_price',2925.0);
%! f = f.set('sub_type','EquityFuture','calc_price_from_netbasis',0);
%! f = f.set('compounding_type','cont','underlying_id','EURO_STOXX_50');
%! f = f.calc_value('31-Mar-2016','base',c,i);
%! assert(f.getValue('base'),0.0,0.00001);
%! assert(f.get('net_basis'),-77.930763505,0.00001);
%! f = f.calc_value('31-Mar-2016','stress',c,i);
%! assert(f.getValue('stress'),-605.714448748,0.00001);

%!test 
%! fprintf('\tdoc_instrument:\tPricing Fixed Amortizing Bond with given principal payments\n');
%! b = Bond();
%! b = b.set('Name','FAB_TEST','coupon_rate',0.02147,'value_base',34714367.9145355225,'clean_value_base',1,'coupon_generation_method','backward','term',3,'sub_type','FAB');
%! b = b.set('maturity_date','12-Feb-2020','notional',34300000,'compounding_type','simple','issue_date','12-Mar-2016','day_count_convention','act/act');
%! b = b.set('fixed_annuity',0,'prepayment_flag',false,'principal_payment',147000,'use_principal_pmt',1,'in_arrears',0,'long_first_period',false,'long_last_period',false);
%! b = b.rollout('base','31-Mar-2016');
%! b = b.rollout('stress','31-Mar-2016');
%! c = Curve();
%! c = c.set('id','EUR-SWAPRAW','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300], ...
%!         'rates_base',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!                     0.004576856,0.005563194,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526], ...
%!        'rates_stress',[-1.38934530e-002,-1.2903390e-002,-1.14941980e-002,-1.15051680e-002,-1.11371070e-002,-1.048215300e-002, ...
%!                     -9.6472220e-003,-8.6925630e-003,-7.6181070e-003,-6.5144340e-003,-5.423144e-003,-4.4368060e-003, ...
%!                     -3.54135400000000e-003,-2.73938000000000e-003,-2.04319200000000e-003,-1.45285700000000e-003, ...
%!                     -9.61179000000000e-004,-5.60903000000000e-004,-2.40827000000001e-004,8.75499999999918e-006,2.00842999999999e-004,3.47525999999999e-004], ...
%!         'method_interpolation','linear');
%! b = b.calc_spread_over_yield('31-Mar-2016',c);
%! assert(b.get('accrued_interest'),38229.5054644799,0.00001);
%! assert(b.get('soy'),0.018682087543,0.00001);
%! b = b.calc_value('31-Mar-2016','base',c);
%! assert(b.getValue('base'),34752597.42,10);
%! b = b.calc_value('31-Mar-2016','stress',c);
%! assert(b.getValue('stress'),36027871.49,10);

%!test 
%! fprintf('\tdoc_instrument:\tPricing Agency MBS with given outstanding balance\n');
%! c = Curve();
%! c = c.set('id','EUR-SWAPRAW','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300], ...
%!         'rates_base',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!                     0.004576856,0.005563194,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526], ...
%!         'rates_stress',[-1.38934530e-002,-1.2903390e-002,-1.14941980e-002,-1.15051680e-002,-1.11371070e-002,-1.048215300e-002, ...
%!                     -9.6472220e-003,-8.6925630e-003,-7.6181070e-003,-6.5144340e-003,-5.423144e-003,-4.4368060e-003, ...
%!                     -3.54135400000000e-003,-2.73938000000000e-003,-2.04319200000000e-003,-1.45285700000000e-003, ...
%!                     -9.61179000000000e-004,-5.60903000000000e-004,-2.40827000000001e-004,8.75499999999918e-006,2.00842999999999e-004,3.47525999999999e-004], ...
%!         'method_interpolation','linear');
%! psa = Curve();
%! psa = psa.set('id','PSA Standard','nodes',[0,900],'rates_base',[0,0.06]);
%! v = Surface();
%! v = v.set('axis_x',[0.055,0.06,0.065],'axis_x_name','coupon_rate','axis_y',[-0.01,0.0,0.01],'axis_y_name','ir_shock','values_base',[3.73,4.3,3.8;3,3.6,3.36;3.8252,3.36255,2.789],'type','PREPAYMENT');
%! r = Curve();
%! r = r.set('id','EUR-SWAPRAW','nodes',[365,730],'rates_base',[0.01,0.02], ...
%!             'rates_stress',[0.01,0.02;0.005,0.01;0.03,0.04;0.05,0.06],'method_interpolation','linear');
%! b = Bond();
%! b = b.set('Name','AG_MBS','coupon_rate',0.065,'value_base',0.005660288,'clean_value_base',1,'coupon_generation_method','backward','term',1,'use_outstanding_balance',1);
%! b = b.set('maturity_date','01-May-2021','notional',1,'compounding_type','simple','issue_date','01-May-2001','day_count_convention','act/365','outstanding_balance',0.00503653);
%! b = b.set('sub_type','FAB','fixed_annuity',1,'prepayment_type','full','prepayment_source','curve','prepayment_flag',1,'prepayment_rate',0.06);
%! b = b.rollout('base','31-Mar-2016',psa,v,r);
%! b = b.calc_value('31-Mar-2016','base',c);
%! b = b.rollout('stress','31-Mar-2016',psa,v,r);
%! b = b.calc_value('31-Mar-2016','stress',c);
%! base_value = b.getValue('base');
%! assert(b.getValue('base'),0.00570177978722126,0.000000001);
%! stress_value = b.getValue('stress');
%! assert(b.getValue('stress'),[0.00580964094701875;0.00579449560542397;0.00585112970654451;0.00585112970654451],0.000000001); 
   

%!test 
%! fprintf('\tdoc_instrument:\tPricing Payer Swaption\n');
%! r = Curve();
%! r = r.set('id','EUR-SWAP-NOFLOOR','nodes',[7300,7665,8030,8395,8760,9125,9490,9855,10220,10585,10900], ...
%!         'rates_base',[0.02,0.01,0.0075,0.005,0.0025,-0.001,-0.002,-0.003,-0.005,-0.0075,-0.01], ...
%!         'rates_stress',[0.02,0.01,0.0075,0.005,0.0025,-0.001,-0.002,-0.003,-0.005,-0.0075,-0.01;0.01,0.00,-0.0025,-0.005,-0.0075,-0.011,-0.012,-0.013,-0.015,-0.0175,-0.02;0.03,0.00,-0.0025,-0.005,-0.0075,-0.011,-0.012,-0.013,-0.015,-0.0175,-0.02],...
%!         'method_interpolation','linear');
%! fix = Bond();
%! fix = fix.set('Name','SWAP_FIXED','coupon_rate',0.045,'value_base',100,'coupon_generation_method','forward','sub_type','SWAP_FIXED');
%! fix = fix.set('maturity_date','24-Mar-2046','notional',100,'compounding_type','simple','issue_date','26-Mar-2036','term',365,'notional_at_end',0);
%! fix = fix.rollout('base','31-Mar-2016');
%! fix = fix.rollout('stress','31-Mar-2016');
%! float = Bond();
%! float = float.set('Name','SWAP_FLOAT','coupon_rate',0.00,'value_base',100,'coupon_generation_method','forward','last_reset_rate',-0.000,'sub_type','SWAP_FLOATING','spread',0.00);
%! float = float.set('maturity_date','24-Mar-2046','notional',100,'compounding_type','simple','issue_date','26-Mar-2036','term',365,'notional_at_end',0);
%! float = float.rollout('base',r,'31-Mar-2016');
%! float = float.rollout('stress',r,'31-Mar-2016');
%! v = Surface();
%! v = v.set('axis_x',30,'axis_x_name','TENOR','axis_y',45,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.376563388);
%! v = v.set('type','IR');
%! s = Swaption();
%! s = s.set('maturity_date','26-Mar-2036','effective_date','31-Mar-2016');
%! s = s.set('strike',0.045,'multiplier',1,'sub_type','SWAPT_PAY','model','normal','tenor',10);
%! s = s.set('und_fixed_leg','SWAP_FIXED','und_floating_leg','SWAP_FLOAT','use_underlyings',true);  
%! s = s.calc_value('31-Mar-2016','base',r,v,fix,float);
%! assert(s.getValue('base'),642.6867193851,0.00001);
%! s = s.calc_value('31-Mar-2016','stress',r,v,fix,float);
%! stressed_value = s.getValue('stress');
%! assert(stressed_value(2),827.6726713515,0.00001);
%! s = s.set('value_base',650.0);
%! s = s.calc_vola_spread('31-Mar-2016',r,v,fix,float);
%! s = s.calc_value('31-Mar-2016','base',r,v,fix,float);
%! assert(s.getValue('base'),650.000,0.0001);

%!test 
%! fprintf('\tdoc_instrument:\tPricing Synthetic Instrument\n');
%! s = Synthetic();
%! s = s.set('id','TestSynthetic','instruments',{'EURO_STOXX_50','MSCIWORLD'},'weights',[1,1],'currency','EUR');
%! i1 = Index();
%! i1 = i1.set('id','EURO_STOXX_50','value_base',1000,'scenario_stress',2000);
%! i2 = Index();
%! i2 = i2.set('id','MSCIWORLD','value_base',1000,'scenario_stress',2000,'currency','USD');
%! fx = Index();
%! fx = fx.set('id','FX_EURUSD','value_base',1.1,'scenario_stress',1.2);
%! instrument_struct = struct();
%! instrument_struct(1).id = i1.id;
%! instrument_struct(1).object = i1;
%! instrument_struct(2).id = i2.id;
%! instrument_struct(2).object = i2;
%! index_struct = struct();
%! index_struct(1).id = fx.id;
%! index_struct(1).object = fx;
%! valuation_date = datenum('31-Mar-2016');
%! s = s.calc_value(valuation_date,'base',instrument_struct,index_struct);
%! s = s.calc_value(valuation_date,'stress',instrument_struct,index_struct);
%! assert(s.getValue('base'),1909.090909,0.0001);
%! assert(s.getValue('stress'),3666.666667,0.0001);


%!test 
%! fprintf('\tdoc_instrument:\tPricing CMS Floating Leg with Hull Convexity Adjustment\n');
%! valuation_date = datenum('31-Mar-2016');
%! cms_float = Bond();
%! cms_float = cms_float.set('Name','CMS_FLOAT','coupon_rate',0.00,'value_base',100,'coupon_generation_method','forward','last_reset_rate',-0.000,'sub_type','CMS_FLOATING','spread',0.00);
%! cms_float = cms_float.set('maturity_date','26-Mar-2036','notional',100,'compounding_type','simple','issue_date','29-Mar-2026','term',365,'notional_at_end',0);
%! cms_float = cms_float.set('cms_model','Black','cms_sliding_term',1825,'cms_term',365,'cms_spread',0.0,'cms_comp_type','simple','cms_convex_model','Hull');
%! ref_curve = Curve();
%! ref_curve = ref_curve.set('id','IR_EUR','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300,7665,8030,8395,8760,9125], ...
%!       'rates_base',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!       0.004576856,0.0055631942,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526, ...
%!       0.0104597123,0.0105410279,0.0105966494,0.010630943,0.0106483277], ...
%!       'rates_stress',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!       0.004576856,0.0055631942,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526, ...
%!       0.0104597123,0.0105410279,0.0105966494,0.010630943,0.0106483277; ...
%!       -0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!       0.004576856,0.0055631942,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526, ...
%!       0.0104597123,0.0105410279,0.0105966494,0.010630943,0.0106483277], ...
%!       'method_interpolation','linear','compounding_type','continuous');    
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.8);
%! v = v.set('type','IR');
%! value_type = 'base'; 
%! cms_float = cms_float.rollout(value_type, valuation_date, ref_curve, v);
%! cms_float = cms_float.calc_value(valuation_date,value_type,ref_curve);
%! assert(cms_float.getValue(value_type),20.2751684618757,0.00000001);
%! value_type = 'stress'; 
%! cms_float = cms_float.rollout(value_type, valuation_date, ref_curve, v);
%! cms_float = cms_float.calc_value(valuation_date,value_type,ref_curve);
%! assert(cms_float.getValue(value_type),[20.2751684618757;20.2751684618757],0.00000001);

%!test 
%! fprintf('\tdoc_instrument:\tPricing CMS Cap with Normal Model and Hagan Convexity Adjustment\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300,7665,8030,8395,8760,9125], ...
%!       'rates_base',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!       0.004576856,0.0055631942,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526, ...
%!       0.0104597123,0.0105410279,0.0105966494,0.010630943,0.0106483277], ...
%!       'rates_stress',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!       0.004576856,0.0055631942,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526, ...
%!       0.0104597123,0.0105410279,0.0105966494,0.010630943,0.0106483277; ...
%!       -0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!       0.004576856,0.0055631942,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526, ...
%!       0.0104597123,0.0105410279,0.0105966494,0.010630943,0.0106483277], ...
%!       'method_interpolation','linear','compounding_type','continuous');    
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.009988);
%! v = v.set('type','IR');
%! value_type = 'base'; 
%! cap_cms = CapFloor();
%! cap_cms = cap_cms.set('id','TEST_CAP','name','TEST_CAP','issue_date','31-Mar-2018','maturity_date','31-Mar-2019','compounding_type','simple');
%! cap_cms = cap_cms.set('term',365,'notional',100,'coupon_generation_method','forward','notional_at_start',0,'notional_at_end',0);
%! cap_cms = cap_cms.set('strike',0.005,'model','Normal','last_reset_rate',0.0,'day_count_convention','act/365','sub_type','CAP_CMS');
%! cap_cms = cap_cms.set('cms_model','Normal','cms_sliding_term',1825,'cms_term',365,'cms_spread',0.0,'cms_comp_type','simple','cms_convex_model','Hagan');
%! cap_cms = cap_cms.rollout( '31-Mar-2016', 'base', c, v);
%! cap_cms = cap_cms.calc_value('31-Mar-2016','base',c);
%! cap_cms = cap_cms.rollout( '31-Mar-2016', 'stress', c, v);
%! cap_cms = cap_cms.calc_value('31-Mar-2016','stress',c);
%! assert(cap_cms.getValue('base'),0.531866524532582,0.00000001);
%! assert(cap_cms.getValue('stress'),[0.531866524532582;0.531866524532582],0.00000001);


   
%!test 
%! fprintf('\tdoc_instrument:\tPricing Floating Leg (in Arrears with Timing Adjustment)\n');
%! valuation_date = datenum('31-Mar-2016');
%! float = Bond();
%! float = float.set('Name','FLOAT','coupon_rate',0.00,'value_base',100,'coupon_generation_method','forward','last_reset_rate',-0.000,'sub_type','SWAP_FLOATING','spread',0.00);
%! float = float.set('maturity_date','29-Mar-2026','notional',100,'compounding_type','simple','issue_date','31-Mar-2016','term',365,'notional_at_end',1);
%! float = float.set('in_arrears',1);
%! ref_curve = Curve();
%! ref_curve = ref_curve.set('id','IR_EUR','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300,7665,8030,8395,8760,9125], ...
%!      'rates_base',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!       0.004576856,0.0055631942,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526, ...
%!       0.0104597123,0.0105410279,0.0105966494,0.010630943,0.0106483277], ...
%!       'rates_stress',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!       0.004576856,0.0055631942,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526, ...
%!       0.0104597123,0.0105410279,0.0105966494,0.010630943,0.0106483277; ...
%!       -0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!       0.004576856,0.0055631942,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526, ...
%!       0.0104597123,0.0105410279,0.0105966494,0.010630943,0.0106483277], ...
%!       'method_interpolation','linear','compounding_type','continuous');    
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.8);
%! v = v.set('type','IR');
%! value_type = 'base';
%! float = float.rollout(value_type, ref_curve , valuation_date, v);
%! float = float.calc_value(valuation_date,value_type,ref_curve);
%! assert(float.getValue('base'),102.129818647705,0.00000001);

%!test 
%! fprintf('\tdoc_instrument:\tPricing Fixed Rate Bond with embedded European Put Option\n');
%! valuation_date = datenum('01-Jan-2016');
%! rates_base = [0.0501772,0.0498284,0.0497234,0.0496157,0.0499058,0.0509389,0.0579733,0.0630595,0.0673464,0.0694816,0.0708807,0.0727527,0.0730852,0.0739790,0.0749015];
%! rates_stress = repmat(rates_base,2,1);
%! curve = Curve();
%! curve = curve.set('id','IR_EUR','nodes',[3,31,62,94,185,367,731,1096,1461,1826,2194,2558,2922,3287,3653], ...
%!       'rates_base',rates_base, 'rates_stress',rates_stress, 'method_interpolation','linear','compounding_type','continuous');   
%! b = Bond();
%! b = b.set('Name','FRB_TEST','coupon_rate',0.00,'coupon_generation_method','backward','term',12,'sub_type','ZCB');
%! b = b.set('maturity_date','29-Dec-2024','notional',100,'compounding_type','simple','issue_date','01-Jan-2016','day_count_convention','30/360E');
%! b = b.set('treenodes',30,'put_schedule','PUT_SCHEDULE','embedded_option_flag',true);
%! call_schedule = Curve();
%! call_schedule = call_schedule.set('id','CALL_SCHEDULE','nodes',[],'rates_base',[],'type','Call Schedule','american_flag',false);
%! put_schedule = Curve();
%! put_schedule = put_schedule.set('id','PUT_SCHEDULE','nodes',[1095],'rates_base',[0.63],'type','Put Schedule','american_flag',false);
%! value_type = 'base';
%! b = b.rollout(value_type,valuation_date);
%! b = b.calc_value(valuation_date,value_type,curve,call_schedule,put_schedule);
%! base_value = b.getValue(value_type);
%! option_value = b.get('embedded_option_value');
%! assert(base_value,53.1857840724563,0.00000001);
% John c. Hull, Option Future and Derivatives gives an put option value of 1.8093 (for 500 steps)
%! assert(option_value,1.7978,0.0001);
%! value_type = 'stress';
%! b = b.rollout(value_type,valuation_date);
%! b = b.calc_value(valuation_date,value_type,curve,call_schedule,put_schedule);
%! assert(b.getValue(value_type),[53.1857;53.1857],0.0001);


%!test 
%! fprintf('\tdoc_instrument:\tPricing European Call Option on Basket\n');
%! % Set up Synthetic Basket instrument
%! s = Synthetic();
%! s = s.set('id','TestSynthetic','instruments',{'EURO_STOXX_50','MSCIWORLD'},'weights',[0.4,0.6],'currency','EUR');
%! s = s.set('discount_curve','IR_EUR','instr_vol_surfaces',{'V1','V2'},'correlation_matrix','BASKET_CORR','sub_type','Basket');
%! % Set up structure with Instrument and index objects
%! i1 = Index();
%! i1 = i1.set('id','EURO_STOXX_50','value_base',1000,'scenario_stress',[900;1100]);
%! i2 = Index();
%! i2 = i2.set('id','MSCIWORLD','value_base',1000,'scenario_stress',[900;1100],'currency','USD');
%! fx = Index();
%! fx = fx.set('id','FX_EURUSD','value_base',1.0,'scenario_stress',[1.0;1.0]);
%! instrument_struct = struct();
%! instrument_struct(1).id = s.id;
%! instrument_struct(1).object = s;
%! index_struct = struct();
%! index_struct(1).id = fx.id;
%! index_struct(1).object = fx;
%! index_struct(2).id = i1.id;
%! index_struct(2).object = i1;
%! index_struct(3).id = i2.id;
%! index_struct(3).object = i2;
%! valuation_date = datenum('30-Jun-2016');
%! s = s.calc_value(valuation_date,'base',instrument_struct,index_struct);
%! % Set up structure with Riskfactor objects
%! r1 = Riskfactor();
%! r1 = r1.set('id','V1','scenario_stress',[0.2;-0.1],'model','GBM','shift_type',[1;1], 'node',730,'node2',1);
%! r2 = Riskfactor();
%! r2 = r1.set('id','V2');
%! riskfactor_struct(1).id = r1.id;
%! riskfactor_struct(1).object = r1;
%! riskfactor_struct(2).id = r2.id;
%! riskfactor_struct(2).object = r2;
%! % Set up structure with discount curve object
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300], ...
%!      'rates_base',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!                     0.004576856,0.0036879820,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526],'method_interpolation','linear');
%! curve_struct = struct();
%! curve_struct(1).id = c.id;
%! curve_struct(1).object = c;
%! % Set up structure with volatlity surface objects
%! v1 = Surface();
%! v1 = v1.set('id','V1','axis_x',3650,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v1 = v1.set('values_base',0.269944411);
%! v1 = v1.set('type','INDEX','riskfactors',{'V1'});
%! v1 = v1.apply_rf_shocks(riskfactor_struct);
%! v2 = Surface();
%! v2 = v2.set('id','V2','axis_x',3650,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v2 = v2.set('values_base',0.1586683369);
%! v2 = v2.set('type','INDEX');
%! v2 = v2.apply_rf_shocks(riskfactor_struct);
%! surface_struct = struct();
%! surface_struct(1).id = v1.id;
%! surface_struct(1).object = v1;
%! surface_struct(2).id = v2.id;
%! surface_struct(2).object = v2;
%! % Set up structure with matrix object
%! m = Matrix();
%! m = m.set('id','BASKET_CORR','components',{'EURO_STOXX_50','MSCIWORLD'});
%! m = m.set('matrix',[1.0,0.3;0.3,1]);
%! matrix_struct = struct();
%! matrix_struct(1).id = m.id;
%! matrix_struct(1).object = m;
%! % Set up basket option objects to evaluate
%! o = Option();
%! o = o.set('maturity_date','28-Jun-2026','sub_type','OPT_EUR_C','discount_curve','IR_EUR');
%! o = o.set('strike',1000,'multiplier',1,'underlying','TestSynthetic','value_base',250,'vola_spread',0.0000000001);
%! % Base valuation
%! value_type = 'base';
%! o = o.valuate (valuation_date, value_type, ...
%!                     instrument_struct, surface_struct, matrix_struct, ...
%!                     curve_struct, index_struct, riskfactor_struct);
%! assert(o.getValue('base'),228.057832164390,0.00000001);
%! % Stress valuation
%! value_type = 'stress';
%! % valuation with instrument function
%! o = o.valuate (valuation_date, value_type, ...
%!                     instrument_struct, surface_struct, matrix_struct, ...
%!                     curve_struct, index_struct, riskfactor_struct);      
%! assert(o.getValue('stress'),[198.460087766560;280.691637148358],0.00000001);

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


%!test 
%! fprintf('\tdoc_instrument:\t Volatility Cube Interpolation Tests\n');
%! vola_surf_minus005 = [ ...
%! 0.001968429,0.0017428,0.001311511,0.004702532,0.007026123,0.0074883; ...
%! 0.002911447,0.002222287,0.00136014,0.005312886,0.007230571,0.007506757; ...
%! 0.003200375,0.002309486,0.001774034,0.006048428,0.007496817,0.007311334; ...
%! 0.003343985,0.002277401,0.002624133,0.006534006,0.007638817,0.006959764; ...
%! 0.00341244,0.002509242,0.003817461,0.006919183,0.007604446,0.006658314; ...
%! 0.003798452,0.001386771,0.00539543,0.007573473,0.007200431,0.006511632; ...
%! 0.003942024,0.004218292,0.006737531,0.007539643,0.007166079,0.007250861];
%! vola_surf_zero = [ ...
%! 0.001857681,0.001749135,0.001424037,0.006035208,0.00838982,0.008765125; ...
%! 0.001825865,0.001737651,0.00142048,0.006687646,0.008596403,0.008798223; ...
%! 0.001810343,0.001725368,0.003100484,0.007446542,0.008868049,0.008624259; ...
%! 0.001801517,0.001712521,0.004359574,0.007964143,0.009019804,0.008293595; ...
%! 0.001795011,0.001699645,0.005495466,0.00838631,0.009000132,0.008005407; ...
%! 0.002930435,0.003854417,0.007090749,0.009091211,0.008635699,0.007853442; ...
%! 0.00592089,0.006514063,0.008442151,0.009124168,0.008597978,0.008534497];
%! vola_surf_plus005 = [ ...
%! 0.003660266,0.003269423,0.002660958,0.007164493,0.009578057,0.009895262; ...
%! 0.00354086,0.003278768,0.002648997,0.007854409,0.00978959,0.009936447; ...
%! 0.003465088,0.00326751,0.004300348,0.008649796,0.010073298,0.009769035; ...
%! 0.003412295,0.003252856,0.005576494,0.009201713,0.010230055,0.009450571; ...
%! 0.00341241,0.003231013,0.00674905,0.009646626,0.010211273,0.009171246; ...
%! 0.00468953,0.005519382,0.008427574,0.010387063,0.009860383,0.009011674; ...
%! 0.00767873,0.008232315,0.009830075,0.010443848,0.009821374,0.009637615];
%! vola_cube = cat(3,vola_surf_minus005,vola_surf_zero,vola_surf_plus005);
%! vv = Surface();
%! vv = vv.set('id','TEST_CUBE','axis_x',[365,730,1825,2555,3650,4380],'axis_x_name','TENOR','axis_y',[365,730,1095,1460,1825,2555,3650],'axis_y_name','TERM','axis_z',[-0.005,0.0,0.005],'axis_z_name','MONEYNESS');
%! vv = vv.set('values_base',vola_cube,'method_interpolation','linear');
%! vv = vv.set('type','IR');
%! assert(vv.interpolate(1095,1700,0.000),0.00283819035616438,0.000001)
%! assert(vv.interpolate(1460,1700,0.002),0.00450785873150685,0.000001)
%! assert(vv.interpolate(1825,1700,-0.001),0.00476692691780822,0.000001)
%! assert(vv.interpolate(2000,1700,-0.0025),0.00503838293282042,0.000001)
%! vv = vv.set('method_interpolation','nearest');
%! assert(vv.interpolate(3650,730,0.0025),0.00978959,0.000001)

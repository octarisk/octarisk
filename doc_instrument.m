%# Copyright (C) 2016,2017 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} { @var{} =} doc_instrument ()
%# This script contains all integration test cases for Octarisk's instruments.
%# This script if part of the integration test suite.
%# @end deftypefn


function a = doc_instrument()
    % this is only a dummy function for containing all the documentation
    % and unittests for instrument classes.
end

%!test 
%! fprintf('\tdoc_instrument:\tPricing Zero Coupon Bond Bond Object\n');
%! b = Bond();
%! b = b.set('Name','Bundesrep.Deutschland Bundesobl.Ser.171 v.2015(20)', 'id','114171','coupon_rate',0.00,'value_base',101.1190,'coupon_generation_method','backward');
%! b = b.set('maturity_date','21-Apr-2020','notional',100,'compounding_type','disc','issue_date','21-Apr-2015','term',12,'compounding_freq','annual','sub_type','ZCB');
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
%! assert(b.ytm,0.0340800096184803,0.00001);
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650],'rates_base',[0.01,0.04],'method_interpolation','monotone-convex');
%! c = c.set('rates_stress',[0.02,0.05;0.005,0.014]);
%! b = b.calc_spread_over_yield('31-Mar-2016',c);
%! assert(b.soy,-0.00274310399175057,0.0001);
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
%! fprintf('\tdoc_instrument:\tCalculating Key Rate Durations and Convexity\n');
%! b = Bond();
%! b = b.set('Name','Test_FRB','coupon_rate',0.01,'value_base',100,'clean_value_base',0,'coupon_generation_method','backward','term',365);
%! b = b.set('maturity_date','30-Dec-2019','notional',100,'compounding_type','simple','issue_date','30-Dec-2016');
%! b = b.set('key_term',[365,730,1095],'key_rate_shock',0.01,'key_rate_width',365);
%! b = b.rollout('base','30-Dec-2016');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650],'rates_base',[0.01,0.01],'method_interpolation','linear');
%! b = b.calc_value('30-Dec-2016','base',c);
%! b = b.calc_key_rates('30-Dec-2016',c);
%! b = b.calc_sensitivities('30-Dec-2016',c);
%! assert(sum(b.get('key_rate_eff_dur')),b.get('eff_duration'),sqrt(eps));
%! assert(sum(b.get('key_rate_eff_convex')),b.get('eff_convexity'),sqrt(eps));

%!test 
%! fprintf('\tdoc_instrument:\tPricing Inflation Linked Bond Object\n');
%! valuation_date = '30-Dec-2016';
%! cpi = Index();
%! cpi = cpi.set('value_base',100.700,'name','CPI','id','CPI','currency','EUR');
%! hist = Curve();
%! hist = hist.set('id','HIST_CURVE', 'type', 'Historical Curve', 'nodes',[0, -91, -183, -274, -365, -730],'rates_base',[100.7,100.54,100.63,100.07,117.21,117.23],'method_interpolation','next');
%! iec = Curve();
%! iec = iec.set('id','IEC_CURVE', 'type', 'Inflation Expectation Curve', 'nodes',[365,730,1095,1460,1825,2190,2555,2920,3285,3650],'rates_base',[0.012167,0.01173,0.01168,0.01181,0.011965,0.01245,0.01292,0.01340,0.01391,0.01470],'method_interpolation','linear','compounding_type','continuous','day_count_convention','act/365');
%! ref_curve = Curve();
%! ref_curve = ref_curve.set('id','DISCOUNT','nodes',[365,3650], 'rates_base',[0.01,0.03],...
%!       'method_interpolation','linear','compounding_type','continuous','day_count_convention','act/365');   
%! % setup inflation linked bond
%! % without indexation lag
%! b = Bond();
%! b = b.set('Name','Test_ILB','coupon_rate',0.01,'value_base',118.55231149,'clean_value_base',0,'coupon_generation_method','forward','day_count_convention','act/365');
%! b = b.set('maturity_date','28-Dec-2026','notional',100,'compounding_type','simple','issue_date','30-Dec-2016','prorated',true);
%! b = b.set('term',12,'last_reset_rate',-0.000,'sub_Type','ILB','spread',0.000,'cpi_index','CPI','infl_exp_curve','IEQ_CURVE','cpi_historical_curve','HIST_CURVE','infl_exp_lag',3,'use_indexation_lag',false);
%! b = b.rollout('base',valuation_date,iec,hist,cpi);
%! assert(b.get('cf_values')',[1.01224131905195;1.02373735043361;1.03566113441648;1.05128164675109;1.06169260131516;1.07760591930570;1.09470465600357;1.11631354182220;1.13349434479673;116.98740312101249],0.0000001);
%! b = b.calc_value(valuation_date,'base',ref_curve);
%! assert(b.getValue('base'),95.2798495349485,0.0000001);
%! % wit indexation lag
%! b = b.set('use_indexation_lag',true);
%! b = b.rollout('base',valuation_date,iec,hist,cpi);
%! assert(b.get('cf_values')',[1.01078143024810;1.02256728792277;1.03432850716808;1.04973080092635;1.06001514473101;1.07522746216490;1.09205553349275;1.11332488953232;1.13009251947925;116.52093880689021],0.0000001);
%! b = b.calc_value(valuation_date,'base',ref_curve);
%! assert(b.getValue('base'),94.9180150148461,0.0000001);

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
%! assert(b.get('soy'), 0.00398785481397732,0.00001); 
%! b = b.calc_value('30-Jun-2016','base',c);
%! assert(b.getValue('base'),99.7917725092950,0.00001);
%! b = b.calc_sensitivities('30-Jun-2016',c,r);
%! assert(b.get('convexity'),0.558796396962633,0.00001);
%! assert(b.get('eff_convexity'),1.98938819865058e-004,0.00001);
%! assert(b.get('eff_duration'),3.93109370316470e-005,0.00001);
%! assert(b.get('mac_duration'),0.747367046218197,0.00001);
%! r = r.set('floor',0.0);
%! b = b.calc_sensitivities('30-Jun-2016',c,r);
%! assert(b.get('eff_convexity'),74.2605311454306,0.00001);
%! assert(b.get('eff_duration'),0.371340971970093,0.00001);
%! assert(b.get('mac_duration'),0.747367046218197,0.00001);
%! assert(b.get('spread_duration'),0.747374010847449,0.00001)

%!test 
%! fprintf('\tdoc_instrument:\tPricing Stochastic Cash Flow Object\n');
%! b = Bond();
%! b = b.set('cf_dates',[365,730],'stochastic_riskfactor','RF_TEST','stochastic_surface','SURF_TEST');
%! b = b.set('sub_type','STOCHASTICCF','stochastic_rf_type','uniform','stochastic_zero_base',false);
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
%! f = f.calc_sensitivities('31-Mar-2016',c,i);
%! assert(f.get('theo_delta'),1.00000000000000,sqrt(eps));
%! assert(f.get('theo_theta'),-0.0137092477359975,sqrt(eps))
%! assert(f.get('theo_rho'),70.8224264276957,sqrt(eps))

%!test
%! fprintf('\tdoc_instrument:\tPricing FX Forward Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,3650,7300],'rates_base',[0.0001002070,0.0045624391,0.009346842],'method_interpolation','linear');
%! fc = Curve();
%! fc = fc.set('id','IR_USD','nodes',[365,3650],'rates_base',[0.0063995279,0.01557504],'method_interpolation','linear');
%! i = Index();
%! i = i.set('value_base',0.877539380349734,'name','FX_EURUSD','id','FX_EURUSD');
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
%! v = v.set('type','IRVol');
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
% %! v = v.set('type','IRVol');
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
%! v = v.set('type','INDEXVol');
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
%! assert(o.get('theo_theta'),-0.0129592907697752,sqrt(eps));
%! assert(o.get('theo_rho'),11.2600772731753,sqrt(eps));
%! assert(o.get('theo_vega'),4.07951486908950,sqrt(eps));
%! assert(o.get('theo_omega'),2.60858246740055,sqrt(eps));

%!test
%! fprintf('\tdoc_instrument:\tPricing European Barrier Option Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[180],'rates_base',[0.08],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.2500);
%! v = v.set('type','INDEXVol');
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
%! v = v.set('type','INDEXVol');
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.get('vola_spread'),0.030000,0.00001);
%! o = o.calc_greeks('31-Mar-2016','base',i,c,v);
%! assert(o.get('theo_theta'),-0.0187217581366794,sqrt(eps));
%! assert(o.get('theo_rho'),0.119110865994094,sqrt(eps));
%! assert(o.get('theo_vega'),0.248425358720136,sqrt(eps));
%! assert(o.get('theo_omega'),-5.24021547490609,sqrt(eps));

%!test
%! fprintf('\tdoc_instrument:\tPricing Asian Geometric Continuous Averaging Option Object\n');
%! r = Riskfactor();
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[180],'rates_base',[0.05],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.200);
%! v = v.set('type','INDEXVol');
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
%! o = o.calc_greeks('31-Mar-2016','base',i,c,v);
%! assert(o.get('theo_theta'),-0.00200313644853622,sqrt(eps));
%! assert(o.get('theo_rho'),-0.0890992274042119,sqrt(eps));
%! assert(o.get('theo_vega'),0.0749765679629277,sqrt(eps));
%! assert(o.get('theo_omega'),-12.5669199489962,sqrt(eps));

%!test
%! fprintf('\tdoc_instrument:\tPricing Asian Arithmetic Continuous Averaging Option Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[180],'rates_base',[0.05],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.200);
%! v = v.set('type','INDEXVol');
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
%! assert(o.get('theo_rho'),-0.0980383964370191,0.00001);
%! assert(o.get('theo_omega'),-13.7246022124715,0.0001);

%!test
%! fprintf('\tdoc_instrument:\tPricing European Binary Gap Option Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365],'rates_base',[0.09],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.2000);
%! v = v.set('type','INDEXVol');
%! i = Index();
%! i = i.set('value_base',50);
%! o = Option();
%! o = o.set('maturity_date','31-Mar-2017','sub_type','OPT_BIN_C');
%! o = o.set('strike',50,'payoff_strike',57,'multiplier',1,'div_yield',0.00,'binary_type','gap');
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
%! assert(o.getValue('base'),2.26691032536174,sqrt(eps))
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.1700);
%! v = v.set('type','INDEXVol');
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.get('vola_spread'),0.030000,0.00001);
%! o = o.calc_greeks('31-Mar-2016','base',i,c,v);
%! assert(o.get('theo_delta'),0.4685867,0.00001);

%!test
%! fprintf('\tdoc_instrument:\tPricing European Binary Asset Option Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365],'rates_base',[0.08],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.5000);
%! v = v.set('type','INDEXVol');
%! i = Index();
%! i = i.set('value_base',100);
%! o = Option();
%! o = o.set('maturity_date','19-Apr-2004','sub_type','OPT_BIN_C');
%! o = o.set('strike',95,'payoff_strike',95,'multiplier',1,'div_yield',0.05,'binary_type','asset');
%! o = o.calc_value('20-Mar-2004','base',i,c,v);
%! assert(o.getValue('base'),66.9697738223540,sqrt(eps))
%! o = o.calc_greeks('20-Mar-2004','base',i,c,v);
%! assert(o.get('theo_delta'),3.17650731294174,0.00001);

%!test
%! fprintf('\tdoc_instrument:\tPricing European Lookback fixed strike Option Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365],'rates_base',[0.1],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.3000);
%! v = v.set('type','INDEXVol');
%! i = Index();
%! i = i.set('value_base',100);
%! o = Option();
%! o = o.set('maturity_date','31-Mar-2017','sub_type','OPT_LBK_C');
%! o = o.set('strike',100,'payoff_strike',95,'multiplier',1,'div_yield',0.00,'lookback_type','fixed_strike');
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
%! assert(o.getValue('base'),34.7116183413683,sqrt(eps))
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.2700);
%! v = v.set('type','INDEXVol');
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.get('vola_spread'),0.030000,0.00001);
%! o = o.calc_greeks('31-Mar-2016','base',i,c,v);
%! assert(o.get('theo_delta'),1.20661004,0.00001);

%!test 
%! fprintf('\tdoc_instrument:\tPricing European Lookback floating strike Option Object\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365],'rates_base',[0.1],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.3000);
%! v = v.set('type','INDEXVol');
%! i = Index();
%! i = i.set('value_base',120);
%! o = Option();
%! o = o.set('maturity_date','31-Mar-2017','sub_type','OPT_LBK_P');
%! o = o.set('strike',100,'payoff_strike',[],'multiplier',1,'div_yield',0.06,'lookback_type','floating_strike');
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
%! assert(o.getValue('base'),31.2215211726344,sqrt(eps))
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.2700);
%! v = v.set('type','INDEXVol');
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.get('vola_spread'),0.030000,0.00001);
%! o = o.calc_greeks('31-Mar-2016','base',i,c,v);
%! assert(o.get('theo_delta'),0.615703060831976,0.00001);
 
%!test
%! fprintf('\tdoc_instrument:\tPricing American Option Object (CRR, Willowtree and Bjerksund and Stensland)\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[730,3650,4380],'rates_base',[0.0001001034,0.0045624391,0.0062559362],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',3650,'axis_x_name','TERM','axis_y',1.1,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.210360082233);
%! v = v.set('type','INDEXVol');
%! i = Index();
%! i = i.set('value_base',286.867623322,'currency','USD');
%! o = Option();
%! o = o.set('maturity_date','29-Mar-2026','currency','USD','timesteps_size',5,'willowtree_nodes',30);
%! o = o.set('strike',368.7362,'multiplier',1,'sub_Type','OPT_AM_P');
%! o = o.set('pricing_function_american','CRR');
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
%! assert(o.getValue('base'),122.976377187361,sqrt(eps));
%! o = o.set('value_base',100);
%! o = o.calc_vola_spread('31-Mar-2016',i,c,v);
%! assert(o.getValue('base'),100.000,0.001);
%! o = o.calc_greeks('31-Mar-2016','base',i,c,v);
%! assert(o.get('theo_delta'),-0.624297868987391,sqrt(eps));
%! assert(o.get('theo_vega'),3.31289415079807,sqrt(eps));
%! o = Option();
%! o = o.set('maturity_date','29-Mar-2026','currency','USD','timesteps_size',5,'willowtree_nodes',30);
%! o = o.set('strike',368.7362,'multiplier',1,'sub_Type','OPT_AM_P');
%! o = o.calc_value('31-Mar-2016','base',i,c,v);
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
%! d = d.set('duration',8.35,'convexity',18,'term',8.35);
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
%! v = v.set('type','IRVol');
%! cap = cap.rollout('31-Dec-2015','base',c,v);
%! cap = cap.calc_value('31-Dec-2015','base',c);
%! assert(cap.getValue('base'),137.0063959386,0.0000001);
%! cap = cap.set('value_base',135.000);
%! cap = cap.calc_vola_spread('31-Dec-2015',c,v);
%! cap = cap.rollout('31-Dec-2015','base',c,v);
%! cap = cap.calc_value('31-Dec-2015','base',c);
%! assert(cap.vola_spread, -0.0256826614604929,0.00001)
%! assert(cap.getValue('base'),135.00,0.00001)

%!test
%! fprintf('\tdoc_instrument:\tPricing Inflation Linked Floor Object\n');
%! valuation_date = '31-Mar-2016';
%! cpi = Index();
%! cpi = cpi.set('value_base',99,'name','CPI','id','CPI','currency','EUR');
%! hist = Curve();
%! hist = hist.set('id','HIST_CURVE', 'type', 'Historical Curve', 'nodes',[0,-91, -183, -275, -366],'rates_base',[99,98.5,98.35,98.23,98.12],'method_interpolation','next');
%! iec = Curve();
%! iec = iec.set('id','IEC_CURVE', 'type', 'Inflation Expectation Curve', 'nodes',[365,730,1095],'rates_base',[0.0025,0.004,0.005],'rates_stress',[0.0025,0.004,0.005;0.0025,0.004,0.005],'method_interpolation','linear','compounding_type','continuous','day_count_convention','act/365');
%! cap = CapFloor();
%! cap = cap.set('id','TEST_CAP','name','TEST_CAP','issue_date',valuation_date,'maturity_date','31-Mar-2017','compounding_type','simple');
%! cap = cap.set('term',365,'notional',100,'coupon_generation_method','forward','notional_at_start',0,'notional_at_end',0,'prorated',true);
%! cap = cap.set('strike',0.01,'model','Black','last_reset_rate',0.0,'day_count_convention','act/365','sub_type','FLOOR_INFL','in_arrears',0);
%! cap = cap.set('cpi_index','CPI','infl_exp_curve','IEC_CURVE','cpi_historical_curve','HIST_CURVE','infl_exp_lag',12,'use_indexation_lag',false);
%! cap = cap.rollout(valuation_date,'base',iec,hist,cpi);
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[0,365,730],'rates_base',[0.002,0.003,0.004],'method_interpolation','linear', ...
%! 		'compounding_type','continuous','day_count_convention','act/365');
%! cap = cap.calc_value(valuation_date,'base',c);
%! assert(cap.getValue('base'),0.747441547923734,0.000000001);
%! cap = cap.set('use_indexation_lag',true);
%! cap = cap.rollout(valuation_date,'base',iec,hist,cpi);
%! cap = cap.calc_value(valuation_date,'base',c);
%! assert(cap.getValue('base'),0.102830060074336,0.000000001);

%!test
%! fprintf('\tdoc_instrument:\tPricing CMS Cap Object with Black Model\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[30,1095,1460],'rates_base',[0.01,0.01,0.01],'method_interpolation','linear');
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.8);
%! v = v.set('type','IRVol');
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
%! v = v.set('type','IRVol');
%! floor = floor.rollout('31-Dec-2015','base',c,v);
%! floor = floor.calc_value('31-Dec-2015','base',c);
%! assert(floor.getValue('base'),39.9458733223202,0.0000001);
%! floor = floor.rollout('31-Dec-2015','stress',c,v);
%! floor = floor.calc_value('31-Dec-2015','stress',c);
%! stress_values = floor.getValue('stress');
%! assert(stress_values,[13.629274436848439;6.092263070602667;0.463877763957439],0.0000001);
%! floor = floor.set('value_base',45.00);
%! floor = floor.calc_vola_spread('31-Dec-2015',c,v);
%! floor = floor.rollout('31-Dec-2015','base',c,v);
%! floor = floor.calc_value('31-Dec-2015','base',c);
%! assert(floor.vola_spread, 0.000397094400016290,0.000001);
%! assert(floor.getValue('base'),45.00,0.00001);

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
%! v = v.set('type','IRVol');
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
%! v = v.set('type','IRVol');
%! floor = floor.rollout('30-Jun-2016','base',c,v);
%! floor = floor.calc_value('30-Dec-2016','base',c);
%! floor = floor.calc_sensitivities('30-Jun-2016','base',c,v,c);
%! assert(floor.getValue('base'),1.44201131641819,0.000000001);
%! assert(floor.get('eff_duration'),75.3761329917373,0.000000001);
%! assert(floor.get('eff_convexity'),802.649265026805,0.000000001);
%! assert(floor.get('vega'),0.00254896021660968,0.000000001);
%! assert(floor.get('theta'),0.00327523346664615,0.000000001);

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
%! assert(b.get('accrued_interest'),0.595890411,0.0001);
%! assert(b.get('soy'),-0.003716422004,0.000001);
%! b = b.calc_value('31-Mar-2016','base',c);
%! b = b.calc_value('31-Mar-2016','stress',c);
%! assert(b.getValue('base'),114.376890411,0.0001);
%! assert(b.getValue('stress'),119.70024104,0.0001);
%! f = Forward();
%! f = f.set('name','BOND_FUTURE_TEST','maturity_date','08-Jun-2016','strike_price',131.13);
%! f = f.set('component_weight',0.863493,'net_basis',-0.009362442,'sub_type','BondFuture');
%! f = f.set('compounding_type','cont','underlying_id','FRB_TEST');
%! f = f.calc_value('31-Mar-2016','base',c,b);
%! f = f.calc_value('31-Mar-2016','stress',c,b);
%! assert(f.getValue('base'),0.0,0.0001);
%! assert(f.getValue('stress'),5.8994582871,0.0001);

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
%! assert(b.get('accrued_interest'),3.5267123288,0.0001);
%! assert(b.get('soy'),-0.003158478713,0.00001);
%! b = b.calc_value('31-Mar-2016','base',c);
%! b = b.calc_value('31-Mar-2016','stress',c);
%! assert(b.getValue('base'),175.53471232881,0.0005);
%! assert(b.getValue('stress'),201.6005801229,0.0005);
%! f = Forward();
%! f = f.set('name','BOND_FORWARD_TEST','maturity_date','17-Oct-2019','strike_price',132.68);
%! f = f.set('sub_type','Bond');
%! f = f.set('compounding_type','cont','underlying_id','FRB_TEST');
%! f = f.calc_value('31-Mar-2016','base',c,b,c);
%! f = f.calc_value('31-Mar-2016','stress',c,b,c);
%! assert(f.getValue('base'),21.9555751042,0.0005);
%! assert(f.getValue('stress'),42.8245029271,0.0005);
%! f = f.calc_sensitivities('31-Mar-2016',c,b,c);
%! assert(f.get('theo_delta'),1.00000000000001,sqrt(eps));
%! assert(f.get('theo_theta'),0.0124805207610592,sqrt(eps));
%! assert(f.get('theo_domestic_rho'),4.76904397839206,sqrt(eps));
%! assert(f.get('theo_foreign_rho'),0.338068744694908,sqrt(eps));

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
%! fprintf('\tdoc_instrument:\tPricing Agency MBS with outstanding balance\n');
%! c = Curve();
%! c = c.set('id','SWAP','nodes',[365,3650],'rates_base',[0.01,0.03], ...
%!         'method_interpolation','linear');
%! psa = Curve();
%! psa = psa.set('id','PSA Standard','nodes',[0,900],'rates_base',[0,0.06],'method_interpolation','linear','compounding_type','simple','day_count_convention','30/360');
%! v = Surface();
%! v = v.set('axis_x',[0.055,0.06,0.065],'axis_x_name','coupon_rate','axis_y',[-0.01,0.0,0.01],'axis_y_name','ir_shock','values_base',[3,4,3;3,4.5,3.3;3.5,3.0,2.8],'type','PREPAYMENT');
%! b = Bond();
%! b = b.set('Name','MBS','coupon_rate',0.06,'value_base',550,'clean_value_base',0,'coupon_generation_method','backward','term',1,'use_outstanding_balance',1);
%! b = b.set('maturity_date','01-May-2025','notional',1000,'compounding_type','simple','issue_date','01-May-2005','day_count_convention','act/365','outstanding_balance',500);
%! b = b.set('sub_type','FAB','fixed_annuity',1,'prepayment_type','full','prepayment_source','curve','prepayment_flag',1,'prepayment_rate',0.06);
%! b = b.rollout('base','31-Dec-2016',psa,v,c);
%! b = b.calc_spread_over_yield('31-Dec-2016',c);
%! b = b.calc_value('31-Dec-2016','base',c);
%! assert(b.get('accrued_interest'),2.46575342465753,sqrt(eps));
%! assert(b.get('soy'),0.00114029719465653,sqrt(eps));
%! assert(b.getValue('base') ,550.000001572877,sqrt(eps));

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
%! assert(b.get('accrued_interest'),38065.6647,0.001);
%! assert(b.get('soy'),0.018753,0.0001);
%! b = b.calc_value('31-Mar-2016','base',c);
%! assert(b.getValue('base'),34752433.5843,100);
%! b = b.calc_value('31-Mar-2016','stress',c);
%! assert(b.getValue('stress'),36065573.593,100);

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
%! fix = fix.calc_value('31-Mar-2016','base',r);  
%! fix = fix.calc_value('31-Mar-2016','stress',r);
%! float = Bond();
%! float = float.set('Name','SWAP_FLOAT','coupon_rate',0.00,'value_base',100,'coupon_generation_method','forward','last_reset_rate',-0.000,'sub_type','SWAP_FLOATING','spread',0.00);
%! float = float.set('maturity_date','24-Mar-2046','notional',100,'compounding_type','simple','issue_date','26-Mar-2036','term',365,'notional_at_end',0);
%! float = float.rollout('base',r,'31-Mar-2016');
%! float = float.rollout('stress',r,'31-Mar-2016');
%! float = float.calc_value('30-Sep-2016','base',r);  
%! float = float.calc_value('30-Sep-2016','stress',r);
%! v = Surface();
%! v = v.set('axis_x',30,'axis_x_name','TENOR','axis_y',45,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.376563388);
%! v = v.set('type','IRVol');
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
%! fprintf('\tdoc_instrument:\tPricing Averaging Floating Leg (no CMS rates!)\n');
%! valuation_date = datenum('31-Mar-2016');
%! neg_curve = Curve();
%! neg_curve = neg_curve.set('id','SWAP_DISCOUNT','nodes',[0,1,2,3,4,5,6,7,8,9,10,11] .* 365, ...
%!       'rates_base',[0.04,0.03,0.02,0.01,0,-0.01,-0.02,-0.03,-0.04,-0.05,-0.06,-0.07],...
%!      'method_interpolation','linear','compounding_type','continuous','day_count_convention','act/365'); 
%! hist = Curve();
%! hist = hist.set('id','HIST_CURVE', 'type', 'Historical Curve', 'nodes',[0,-365, -730, -1095, -1460, -1825, -2190],'rates_base',[0.0001,0.00064,0.00278,0.00177,0.01291,0.01042,0.01046],'method_interpolation','next');
%! float = Bond();
%! float = float.set('Name','SWAP_FLOATING_AVG_TEST','coupon_rate',0.00,'value_base',100,'coupon_generation_method','forward','last_reset_rate',-0.000,'sub_type','SWAP_FLOATING_FWD_SPECIAL','spread',0.00);
%! float = float.set('maturity_date',datestr(valuation_date + 4015),'notional',100,'compounding_type','simple','issue_date',datestr(valuation_date + 365),'term',365,'notional_at_end',0);
%! float = float.set('cms_model','Normal','cms_sliding_term',1825,'cms_term',365,'in_arrears',0,'rate_composition','average');
%! value_type = 'base'; 
%! float = float.rollout(value_type, valuation_date, neg_curve, hist);
%! float = float.calc_value(valuation_date,value_type,neg_curve);
%! assert(float.getValue('base'),-76.5598162194818,0.000001);


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
%! v = v.set('type','IRVol');
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
%! v = v.set('type','IRVol');
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
%! cap_cms = cap_cms.set('value_base',0.60);
%! cap_cms = cap_cms.calc_vola_spread('31-Mar-2016',c,v);
%! cap_cms = cap_cms.rollout('31-Mar-2016','base',c,v);
%! cap_cms = cap_cms.calc_value('31-Mar-2016','base',c);
%! assert(cap_cms.vola_spread, 0.00120662817963940,0.000001);
%! assert(cap_cms.getValue('base'),0.600000004884487,0.00001);

%!test    
%! fprintf('\tdoc_instrument:\tPricing CMS Accumulating Floater with Hagan Convexity Adjustment\n');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[30,91,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300,7665,8030,8395,8760,9125], ...
%!        'rates_base',[-0.003893453,-0.00290339,-0.001494198,-0.001505168,-0.001137107,-0.000482153,0.000352778,0.001307437,0.002381893,0.003485566, ...
%!        0.004576856,0.0055631942,0.006458646,0.00726062,0.007956808,0.008547143,0.009038821,0.009439097,0.009759173,0.010008755,0.010200843,0.010347526, ...
%!        0.0104597123,0.0105410279,0.0105966494,0.010630943,0.0106483277],'method_interpolation','linear','compounding_type','continuous');    
%! vv = Surface();
%! vv = vv.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! vv = vv.set('values_base',0.009988);
%! vv = vv.set('type','IRVol');
%! value_type = 'base'; 
%! valuation_date = '30-Jun-2017';
%! cap_float = Bond();
%! cap_float = cap_float.set('Name','TEST_FRN_SPECIAL','coupon_rate',0.00,'value_base',100,'coupon_generation_method','forward','last_reset_rate',-0.000,'sub_type','FRN_SPECIAL','spread',0.00);
%! cap_float = cap_float.set('maturity_date','30-Jun-2023','notional',100,'compounding_type','simple','compounding_freq','semi-annual','issue_date','30-Jun-2017','term',365,'notional_at_end',1,'convex_adj',true);
%! cap_float = cap_float.set('rate_composition','capitalized','day_count_convention','act/365');
%! cap_float = cap_float.set('cms_model','Normal','cms_sliding_term',3650,'cms_term',365,'cms_spread',0.0,'cms_comp_type','simple','cms_convex_model','Hagan','in_arrears',0);
%! value_type = 'base'; 
%! cap_float = cap_float.rollout(value_type, valuation_date, c, vv);
%! cap_float = cap_float.calc_value(valuation_date,value_type,c);
%! assert(cap_float.getValue('base'),104.640739631675,0.00000001);

 
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
%! v = v.set('type','IRVol');
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
%! fprintf('\tdoc_instrument:\tPricing Forward Rate Agreement\n');
%! b = Bond();
%! b = b.set('Name','Test_FRA','coupon_rate',0.01,'value_base',100,'clean_value_base',0,'coupon_generation_method','backward','term',365);
%! b = b.set('maturity_date','30-Dec-2017','notional',100,'compounding_type','simple','issue_date','30-Dec-2016','sub_type','FRA','day_count_convention','act/365');
%! b = b.set('strike_rate',0.0000,'underlying_maturity_date','30-Dec-2018','coupon_prepay','Discount');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,730],'rates_base',[-0.00302461,-0.00261397],'method_interpolation','linear','compounding_type','continuous','day_count_convention','act/365');
%! b = b.rollout('base',c,'30-Dec-2016');
%! b = b.calc_value('30-Dec-2016','base',c);
%! assert(b.getValue('base'),-0.2210007876,0.000001)

%!test 
%! fprintf('\tdoc_instrument:\tPricing Forward Volatility Agreement\n');
%! b = Bond();
%! b = b.set('Name','Test_FVA','value_base',100,'coupon_generation_method','backward','term',365);
%! b = b.set('maturity_date','21-Jun-2013','notional',1000,'compounding_type','simple','issue_date','22-Jun-2010','sub_type','FVA','day_count_convention','act/365');
%! b = b.set('strike_rate',0.12,'underlying_maturity_date','21-Jun-2014','fva_type','volatility');
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[365,730],'rates_base',[0,0],'method_interpolation','linear','compounding_type','continuous','day_count_convention','act/365');
%! v2 = Surface();
%! v2 = v2.set('id','V2','axis_x',[730,1095,1460],'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v2 = v2.set('values_base',[0.1,0.02,0.1]);
%! v2 = v2.set('type','INDEXVol');
%! b = b.rollout('base',c,'22-Jun-2010',v2);
%! b = b.calc_value('22-Jun-2010','base',c);
%! assert(b.getValue('base'),76.9771560359221,sqrt(eps))

%!test 
%! fprintf('\tdoc_instrument:\tPricing Sensitivity Instrument\n');
%! % Set up Sensitivity Instrument
%! r1 = Riskfactor();
%! r1 = r1.set('id','MSCI_WORLD','scenario_stress',[0.2;-0.1], ...
%! 					'model','GBM','shift_type',[1;1]);
%! r2 = Riskfactor();
%! r2 = r2.set('id','MSCI_EM','scenario_stress',[0.1;-0.2], ...
%! 					'model','GBM','shift_type',[1;1] );
%! riskfactor_struct = struct();
%! riskfactor_struct(1).id = r1.id;
%! riskfactor_struct(1).object = r1;
%! riskfactor_struct(2).id = r2.id;
%! riskfactor_struct(2).object = r2;
%! s = Sensitivity();
%! s = s.set('id','MSCI_ACWI_ETF','sub_type','EQU', ...
%! 					'asset_class','Equity', 'model', 'GBM', ...
%! 					'riskfactors',cellstr(['MSCI_WORLD';'MSCI_EM']), ...
%! 					'sensitivities',[0.8,0.2],'value_base',100.00);
%! instrument_struct = struct();
%! instrument_struct(1).id = s.id;
%! instrument_struct(1).object = s;
%! s = s.valuate('31-Dec-2016', 'stress', ...
%! 					instrument_struct, [], [], ...
%! 					[], [], riskfactor_struct);
%! assert(s.getValue('stress'),[119.7217363121810;88.6920436717158],0.00000001);
%! s = s.calc_value('31-Dec-2016', 'stress',riskfactor_struct);
%! assert(s.getValue('stress'),[119.7217363121810;88.6920436717158],0.00000001);


%!test 
%! fprintf('\tdoc_instrument:\tPricing European Call Option on Basket with Levy method\n');
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
%! % Set up stress struct with shocks to volatility objects
%! stress_struct(1).id = 'STRESS01';
%! stress_struct(2).id = 'STRESS02';
%! stress_struct(1).objects(1).id = 'V1';
%! stress_struct(1).objects(1).type = 'surface';
%! stress_struct(1).objects(1).shock_type = 'relative';
%! stress_struct(1).objects(1).shock_value = 1.2;
%! stress_struct(2).objects(1).id = 'V1';
%! stress_struct(2).objects(1).type = 'surface';
%! stress_struct(2).objects(1).shock_type = 'relative';
%! stress_struct(2).objects(1).shock_value = 0.9;
%! stress_struct(1).objects(2).id = 'V2';
%! stress_struct(1).objects(2).type = 'surface';
%! stress_struct(1).objects(2).shock_type = 'relative';
%! stress_struct(1).objects(2).shock_value = 1.2;
%! stress_struct(2).objects(2).id = 'V2';
%! stress_struct(2).objects(2).type = 'surface';
%! stress_struct(2).objects(2).shock_type = 'relative';
%! stress_struct(2).objects(2).shock_value = 0.9;
%! % Set up structure with volatlity surface objects
%! v1 = Surface();
%! v1 = v1.set('id','V1','axis_x',3650,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v1 = v1.set('values_base',0.269944411);
%! v1 = v1.set('type','INDEXVol','riskfactors',{'V1'});
%! v1 = v1.apply_stress_shocks(stress_struct);
%! v2 = Surface();
%! v2 = v2.set('id','V2','axis_x',3650,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v2 = v2.set('values_base',0.1586683369);
%! v2 = v2.set('type','INDEXVol');
%! v2 = v2.apply_stress_shocks(stress_struct);
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
%! assert(o.getValue('base'),228.057832283511,sqrt(eps));
%! % Stress valuation
%! value_type = 'stress';
%! % valuation with instrument function
%! o = o.valuate (valuation_date, value_type, ...
%!                     instrument_struct, surface_struct, matrix_struct, ...
%!                     curve_struct, index_struct, riskfactor_struct);   
%! assert(o.getValue('stress'),[211.348256702480;272.213027434707],sqrt(eps));
   
%!test 
%! fprintf('\tdoc_instrument:\tPricing European Call Option on Basket with Beisser method\n');
%! a = [0.0004404901,0.11092258,0.038288027,0.3535180391,0.1075458489,0.3892850084]; % a = vector with weights
%! S = [1000,1000,1000,817.51125859,1000,1000]; % s = Pricevector
%! riskfree = 0.0123943401; % riskfree
%! sigma = [0.5776204542,0.1732356803,0.2914372376,0.3733887173,0.1020327196,0.2889940433]; % sigma = vector with standard deviations
%! maturity = 20; % maturity = mat in years
%! K = 1359.7849; % K = strike
%! correlation = [1.0000000000,0.8202264316,0.5472385032,0.7662997782,0.0345582159,0.8297024419;
%! 0.8202264316,1.0000000000,0.4548504630,0.6816778843,0.0452805859,0.8202264316;
%! 0.5472385032,0.4548504630,1.0000000000,0.4213455468,0.4356861070,0.5472385032;
%! 0.7662997782,0.6816778843,0.4213455468,1.0000000000,-0.0420931614,0.7662997782;
%! 0.0345582159,0.0452805859,0.4356861070,-0.0420931614,1.0000000000,0.0345582159;
%! 0.8297024419,0.8202264316,0.5472385032,0.7662997782,0.0345582159,1
%! ]; 
%! % Set up Synthetic Basket instrument
%! s = Synthetic();
%! s = s.set('id','TestSynthetic','instruments',{'1','2','3','4','5','6'},'weights',a,'currency','EUR','basket_vola_type','Beisser');
%! s = s.set('discount_curve','IR_EUR','instr_vol_surfaces',{'V1','V2','V3','V4','V5','V6'},'correlation_matrix','BASKET_CORR','sub_type','Basket');
%! % Set up structure with Instrument and index objects
%! i1 = Index();
%! i1 = i1.set('id','1','value_base',S(1,1),'scenario_stress',S(:,1));
%! i2 = Index();
%! i2 = i2.set('id','2','value_base',S(1,2),'scenario_stress',S(:,2));
%! i3 = Index();
%! i3 = i3.set('id','3','value_base',S(1,3),'scenario_stress',S(:,3));
%! i4 = Index();
%! i4 = i4.set('id','4','value_base',S(1,4),'scenario_stress',S(:,4));
%! i5 = Index();
%! i5 = i5.set('id','5','value_base',S(1,5),'scenario_stress',S(:,5));
%! i6 = Index();
%! i6 = i6.set('id','6','value_base',S(1,6),'scenario_stress',S(:,6));
%! fx = Index();
%! fx = fx.set('id','FX_EURUSD','value_base',1.0);%,'scenario_stress',[1.0;1;1;1;1;1;1;1]);
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
%! index_struct(4).id = i3.id;
%! index_struct(4).object = i3;
%! index_struct(5).id = i4.id;
%! index_struct(5).object = i4;
%! index_struct(6).id = i5.id;
%! index_struct(6).object = i5;
%! index_struct(7).id = i6.id;
%! index_struct(7).object = i6;
%! valuation_date = datenum('30-Dec-2016');
%! s = s.calc_value(valuation_date,'base',instrument_struct,index_struct);
%! % Set up stress struct with volatility shocks
%! stress_struct = struct();
%! id_cell = {'V1','V2','V3','V4','V5','V6'};
%! vola_shock_vec = [1;2;6;41;101];
%! for kk=1:1:length(vola_shock_vec)
%!      for jj=1:1:length(id_cell)
%! 		   stress_struct(kk).id = 'STRESS';	
%!         stress_struct(kk).objects(jj).id = id_cell{jj};
%!         stress_struct(kk).objects(jj).type = 'surface';
%!         stress_struct(kk).objects(jj).shock_type = 'relative';
%!         stress_struct(kk).objects(jj).shock_value = vola_shock_vec(kk);
%!      end
%!  end
%! % Set up structure with Riskfactor objects
%! riskfactor_struct = struct();
%! % Set up structure with discount curve object
%! c = Curve();
%! c = c.set('id','IR_EUR','nodes',[7300], ...
%!      'rates_base',[riskfree],'method_interpolation','linear');				
%! curve_struct = struct();
%! curve_struct(1).id = c.id;
%! curve_struct(1).object = c;
%! % Set up structure with volatlity surface objects
%! v1 = Surface();
%! v1 = v1.set('id','V1','axis_x',3650,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v1 = v1.set('values_base',sigma(1));
%! v1 = v1.set('type','INDEXVol','riskfactors',{'V1'});
%! v1 = v1.apply_stress_shocks(stress_struct);
%! v2 = Surface();
%! v2 = v2.set('id','V2','axis_x',3650,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v2 = v2.set('values_base',sigma(2));
%! v2 = v2.set('type','INDEXVol','riskfactors',{'V2'});
%! v2 = v2.apply_stress_shocks(stress_struct);
%! v3 = Surface();
%! v3 = v3.set('id','V3','axis_x',3650,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v3 = v3.set('values_base',sigma(3));
%! v3 = v3.set('type','INDEXVol','riskfactors',{'V3'});
%! v3 = v3.apply_stress_shocks(stress_struct);
%! v4 = Surface();
%! v4 = v4.set('id','V4','axis_x',3650,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v4 = v4.set('values_base',sigma(4));
%! v4 = v4.set('type','INDEXVol','riskfactors',{'V4'});
%! v4 = v4.apply_stress_shocks(stress_struct);
%! v5 = Surface();
%! v5 = v5.set('id','V5','axis_x',3650,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v5 = v5.set('values_base',sigma(5));
%! v5 = v5.set('type','INDEXVol','riskfactors',{'V5'});
%! v5 = v5.apply_stress_shocks(stress_struct);
%! v6 = Surface();
%! v6 = v6.set('id','V6','axis_x',3650,'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v6 = v6.set('values_base',sigma(6));
%! v6 = v6.set('type','INDEXVol','riskfactors',{'V6'});
%! v6 = v6.apply_stress_shocks(stress_struct);
%! surface_struct = struct();
%! surface_struct(1).id = v1.id;
%! surface_struct(1).object = v1;
%! surface_struct(2).id = v2.id;
%! surface_struct(2).object = v2;
%! surface_struct(3).id = v3.id;
%! surface_struct(3).object = v3;
%! surface_struct(4).id = v4.id;
%! surface_struct(4).object = v4;
%! surface_struct(5).id = v5.id;
%! surface_struct(5).object = v5;
%! surface_struct(6).id = v6.id;
%! surface_struct(6).object = v6;
%! % Set up structure with matrix object
%! m = Matrix();
%! m = m.set('id','BASKET_CORR','components',{'1','2','3','4','5','6'});
%! m = m.set('matrix',correlation);
%! matrix_struct = struct();
%! matrix_struct(1).id = m.id;
%! matrix_struct(1).object = m;
%! % Set up basket option objects to evaluate
%! o = Option();
%! o = o.set('maturity_date','25-Dec-2036','sub_type','OPT_EUR_C','discount_curve','IR_EUR');
%! o = o.set('strike',K,'multiplier',1,'underlying','TestSynthetic','value_base',250,'vola_spread',0.0000000001);
%! % Base valuation
%! value_type = 'base';
%! o = o.valuate (valuation_date, value_type, ...
%!                     instrument_struct, surface_struct, matrix_struct, ...
%!                     curve_struct, index_struct, riskfactor_struct);
%! assert(o.getValue('base'),347.238282599760,sqrt(eps));
%! % Stress valuation
%! value_type = 'stress';
%! o = o.valuate (valuation_date, value_type, ...
%!                     instrument_struct, surface_struct, matrix_struct, ...
%!                     curve_struct, index_struct, riskfactor_struct);
%! assert(o.getValue('stress'),[347.238282599760;602.767484376531;811.214622007268;830.423521024289;889.507588641300],sqrt(eps));

%!test 
%! fprintf('\tdoc_instrument:\tPricing Sensitivity Instrument (Taylor Expansion) \n');
%! c = Curve();
%! c = c.set('id','EUR-SWAP','nodes',[11315,11680],'rates_base',[0.0180057,0.018596],'rates_stress',[0.0180057,0.018596;0.0080057,0.008596;0.0280057,0.028596],'method_interpolation','linear','compounding_type','continuous','day_count_convention','act/365');
%! v1 = Surface();
%! v1 = v1.set('id','V1','axis_x',[730,1095,1460],'axis_x_name','TERM','axis_y',1.0,'axis_y_name','MONEYNESS');
%! v1 = v1.set('values_base',[0.1,0.02,0.1]);
%! v1 = v1.set('type','INDEXVol');
%! s = Sensitivity();
%! s = s.set('id','SENSI_INSTRUMENT','sub_type','SENSI', ...
%! 					'asset_class','Sensi',  'value_base', -150367508.00 , ...
%! 					'underlyings',cellstr(['EUR-SWAP';'EUR-SWAP']), ...
%!					'x_coord',[11501.2261098,11501.2261098], ...
%!					'y_coord',[0,0.0], ...
%!					'z_coord',[0,0], ...
%!					'shock_type', cellstr(['absolute';'absolute']), 					
%!					'sensi_prefactor', [5.215133647E9,1.07E11], 'sensi_exponent', [1,2], ...
%!					'sensi_cross', [0,0], 'use_value_base',true,'use_taylor_exp',true);
%! surface_struct = struct();
%! surface_struct(1).id = v1.id;
%! surface_struct(1).object = v1;
%! curve_struct = struct();
%! curve_struct(1).id = c.id;
%! curve_struct(1).object = c;					
%! riskfactor_struct = struct();
%! index_struct = struct();
%! instrument_struct = struct();
%! s = s.calc_value('31-Dec-2016', 'base',riskfactor_struct,instrument_struct,index_struct,curve_struct,surface_struct);
%! assert(s.getValue('base'),-150367508.00,0.01);
%! s = s.calc_value('31-Dec-2016', 'stress',riskfactor_struct,instrument_struct,index_struct,curve_struct,surface_struct);
%! assert(s.getValue('stress'),[-150367508.00;-197168844.47;-92866171.53],0.01);

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
%! fprintf('\tdoc_instrument:\tTesting Credit Default Swaps (Fixed and Floating, (no) default)\n');
%! valuation_date = datenum('30-Jun-2017');
%! value_type = 'base';
%! % reference asset:
%! a = Bond();
%! a = a.set('id','REFBOND','credit_state','AA','issue_date','30-Jun-2017','maturity_date','29-Jun-2020');
%! a = a.set('coupon_rate',0.02,'sub_type','FRB','notional',100,'coupon_generation_method','forward','term',365);
%! a = a.rollout(value_type, valuation_date);
%! % reference curve
%! c = Curve();
%! c = c.set('id','REFCURVE','nodes',[0,365,730,1095,1460,1825], ...
%!       'rates_base',[0.01,0.01,0.01,0.01,0.01,0.01], 'method_interpolation','linear', ...
%! 	  'compounding_type','continuous','day_count_convention','act/365'); 
%! % hazard curve
%! h = Curve();
%! h = h.set('type','Hazard Curve','id','HAZARDCURVE','nodes',[0,365,730,1095,1460,1825], ...
%!       'rates_base',[0.01,0.01,0.02,0.03,0.04,0.05], 'method_interpolation','linear', ...
%! 	  'compounding_type','continuous','day_count_convention','act/365'); 	  
%! % CDS Floating
%! b = Bond();
%! b = b.set('sub_type','CDS_FLOATING','coupon_rate',0.04,'notional',100, ...
%! 		'issue_date','30-Jun-2017','maturity_date','29-Jun-2020' , ...
%! 		'loss_given_default',0.8,'cds_use_initial_premium',false, 'cds_initial_premium', 4.0, ...
%! 		'reference_asset','REFBOND','hazard_curve','HAZARDCURVE', 'coupon_generation_method','forward', ...
%! 		'compounding_type','simple','day_count_convention','act/365','cds_receive_protection',true);
%! c = c.set('rates_stress',[	0.01,0.01,0.01,0.01,0.01,0.01; ...
%! 						0.01,0.02,0.032,0.021,0.031,0.023; ...
%! 						0.01,-0.01,0.03,0.04,0.03,-0.01]); 
%! % CDS Floating
%! b = b.set('sub_type','CDS_FLOATING');
%! b = b.rollout('base',valuation_date,h, a,c);
%! b = b.rollout('stress',valuation_date,h, a,c);	
%! assert(b.getCF('base'),[0.199003325016637,-0.593030040228064,-1.347990905494223],sqrt(eps))
%! assert(b.getCF('stress'),[0.199003325016637,-0.593030040228064,-1.347990905494223; ...
%! 							1.204020033433450,2.796948522945633,-2.388609377964669; ...
%! 							-1.781129344307817,5.468180048335224,3.529066644434367],sqrt(eps));
%! b = b.calc_value(valuation_date,'base',c);
%! assert(b.getValue('base'),-1.69241580331523,sqrt(eps));
%! b = b.calc_value(valuation_date,'stress',c);
%! assert(b.getValue('stress'),[-1.69241580331523;1.56096135072673;6.48070937044417],sqrt(eps));
%! % CDS FIXED premium leg
%! b = b.set('sub_type','CDS_FIXED');
%! b = b.rollout('base',valuation_date,h, a);
%! b = b.rollout('stress',valuation_date,h, a);
%! assert(b.getCF('base'),[3.16418603493013,2.31343811814125,1.47257813719623],sqrt(eps));	
%! assert(b.getCF('stress'),[3.16418603493013,2.31343811814125,1.47257813719623],sqrt(eps));
%! b = b.calc_value(valuation_date,'base',c);
%! assert(b.getValue('base'),6.82938770805661,sqrt(eps));
%! b = b.calc_value(valuation_date,'stress',c);
%! assert(b.getValue('stress'),[6.82938770805661;6.65421510587343;6.68076024811611],sqrt(eps));
%! % CDS FIXED: reference asset in default
%! a = a.set('credit_state','D');
%! b = b.rollout('base',valuation_date,h, a);	
%! b = b.rollout('stress',valuation_date,h, a);				
%! assert(b.getCF('base'),80.0,sqrt(eps))	
%! assert(b.getCF('stress'),80.0,sqrt(eps))
%! b = b.calc_value(valuation_date,'base',c);
%! assert(b.getValue('base'),79.9978082492022,sqrt(eps));
%! b = b.calc_value(valuation_date,'stress',c);
%! assert(b.getValue('stress'), [79.9978082492022;79.9978022444880;79.9978202586320],sqrt(eps));

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
%! vv = vv.set('type','IRVol');
%! assert(vv.interpolate(1095,1700,0.000),0.00283819035616438,0.000001)
%! assert(vv.interpolate(1460,1700,0.002),0.00450785873150685,0.000001)
%! assert(vv.interpolate(1825,1700,-0.001),0.00476692691780822,0.000001)
%! assert(vv.interpolate(2000,1700,-0.0025),0.00503838293282042,0.000001)
%! vv = vv.set('method_interpolation','nearest');
%! assert(vv.interpolate(3650,730,0.0025),0.00978959,0.000001)

%!test
%! fprintf('\tdoc_instrument:\t Sobol generator tests\n');
%! direction_file = strcat(pwd,'/static/joe-kuo-old.1111');
%! a = calc_sobol_cpp(50001,10,direction_file);
%! a(1,:) = []; % remove first line (contains 0.0)
%! normdist_a = norminv(a);
%! % scaling to get normal 0,1 distributed random variables
%! normdist_a = normdist_a ./ std(normdist_a);
%! mean_std_a = mean(std(normdist_a));
%! assert(mean_std_a,1,sqrt(eps));
%! % testing 0.995 quantile
%! len_tail = length(normdist_a(abs(normdist_a)>=2.57582930354890))/2;
%! assert(len_tail,2500,sqrt(eps))
%! % testing 0.9999 quantile
%! len_tail = length(normdist_a(abs(normdist_a)>=3.71901648545568))/2;
%! assert(len_tail,45.5,sqrt(eps))
%! % testing different Sobol direction numbers
%! direction_file = strcat(pwd,'/static/new-joe-kuo-6.21201')
%! a = calc_sobol_cpp(50001,10,direction_file);
%! a(1,:) = []; % remove first line (contains 0.0)
%! normdist_a = norminv(a);
%! % scaling to get normal 0,1 distributed random variables
%! normdist_a = normdist_a ./ std(normdist_a);
%! mean_std_a = mean(std(normdist_a));
%! assert(mean_std_a,1,sqrt(eps));
%! % testing 0.995 quantile
%! len_tail = length(normdist_a(abs(normdist_a)>=2.57582930354890))/2;
%! assert(len_tail,2499.5,sqrt(eps))
%! % testing 0.9999 quantile
%! len_tail = length(normdist_a(abs(normdist_a)>=3.71901648545568))/2;
%! assert(len_tail,46,sqrt(eps))


%!test
%! fprintf('\tdoc_instrument:\t Interpolation and Extrapolation tests\n');
%! assert(interpolate_curve_vectorized_mc([1,5,10,20,50],[0.01,0.02,0.03,0.04,0.05],-30),0.010000000000,eps)
%! assert(interpolate_curve_vectorized_mc([1,5,10,20,50],[0.01,0.02,0.03,0.04,0.05],30),0.04333333333333333,eps)
%! assert(interpolate_curve_vectorized_mc([1,5,10,20,50],[0.01,0.02,0.03,0.04,0.05],80),0.050000000000,eps)
%! assert(interpolate_curve_vectorized_mc([-1,-5,-10,-20,-50],[0.01,0.02,0.03,0.04,0.05],-80),0.050000000000,eps)
%! assert(interpolate_curve_vectorized_mc([-1,-5,-10,-20,-50],[0.01,0.02,0.03,0.04,0.05],-30),0.04333333333333333,eps)
%! assert(interpolate_curve_vectorized_mc([-1,-5,-10,-20,-50],[0.01,0.02,0.03,0.04,0.05],30),0.010000000000,eps)
%! assert(interpolate_curve_vectorized([1,5,10,20,50],[0.01,0.02,0.03,0.04,0.05],-30),0.010000000000,eps)
%! assert(interpolate_curve_vectorized([1,5,10,20,50],[0.01,0.02,0.03,0.04,0.05],30),0.04333333333333333,eps)
%! assert(interpolate_curve_vectorized([1,5,10,20,50],[0.01,0.02,0.03,0.04,0.05],80),0.050000000000,eps)
%! assert(interpolate_curve_vectorized([-1,-5,-10,-20,-50],[0.01,0.02,0.03,0.04,0.05],-80),0.050000000000,eps)
%! assert(interpolate_curve_vectorized([-1,-5,-10,-20,-50],[0.01,0.02,0.03,0.04,0.05],-30),0.04333333333333333,eps)
%! assert(interpolate_curve_vectorized([-1,-5,-10,-20,-50],[0.01,0.02,0.03,0.04,0.05],30),0.010000000000,eps)
%! assert(interpolate_curve([1,5,10,20,50],[0.01,0.02,0.03,0.04,0.05],-30),0.010000000000,eps)
%! assert(interpolate_curve([1,5,10,20,50],[0.01,0.02,0.03,0.04,0.05],30),0.04333333333333333,eps)
%! assert(interpolate_curve([1,5,10,20,50],[0.01,0.02,0.03,0.04,0.05],80),0.050000000000,eps)
%! assert(interpolate_curve([-1,-5,-10,-20,-50],[0.01,0.02,0.03,0.04,0.05],-80),0.050000000000,eps)
%! assert(interpolate_curve([-1,-5,-10,-20,-50],[0.01,0.02,0.03,0.04,0.05],-30),0.04333333333333333,eps)
%! assert(interpolate_curve([-1,-5,-10,-20,-50],[0.01,0.02,0.03,0.04,0.05],30),0.010000000000,eps)

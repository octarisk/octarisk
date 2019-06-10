function testriskfree()
 
fprintf('\tdoc_instrument:\tPricing Savings Plan\n');

rates_base = 0.01*[-0.577008,-0.594517,-0.610788,-0.625215,-0.658149,-0.648486,-0.603025,-0.532882,-0.448536,-0.358186,-0.267574,-0.180361,-0.098635,-0.023387,0.04511,0.107023,0.162766,0.212872,0.257913,0.298448,0.335004,0.368056,0.398029,0.425294,0.450177,0.472958,0.49388,0.513155,0.530964,0.547465,0.562794,0.57707,0.590398];
rates_stress = rates_base + [-0.05;-0.03;0.0;0.03;0.05];
valuation_date = '31-May-2019';
r = Retail();
r = r.set('Name','Test_SAVPLAN','sub_type','SAVPLAN','coupon_rate',0.0155,'coupon_generation_method','backward','term',1,'term_unit','months');
r = r.set('maturity_date','05-May-2024','compounding_type','simple','savings_rate',500);
r = r.set('savings_startdate','05-May-2014','savings_enddate','05-May-2021');
r = r.set('extra_payment_values',[17500],'extra_payment_dates',{'17-May-2019'},'bonus_value_current',0.5,'bonus_value_redemption',0.15);
r = r.set('notice_period',3,'notice_period_unit','months');
r = r.rollout('base',valuation_date);
r = r.rollout('stress',valuation_date);
c = Curve();
c = c.set('id','IR_EUR','nodes',[90,180,270,365,730,1095,1460,1825,2190,2555,2920,3285,3650,4015,4380,4745,5110,5475,5840,6205,6570,6935,7300,7665,8030,8395,8760,9125,9490,9855,10220,10585,10950], ...
'rates_base',rates_base,'rates_stress',rates_stress,'method_interpolation','linear');
r = r.calc_value(valuation_date,'base',c);
r = r.calc_value(valuation_date,'stress',c);
%r.getValue('base')
%r.getValue('stress')

r = r.calc_sensitivities(valuation_date,c);
r = r.calc_key_rates(valuation_date,c);
assert(r.getValue('base'),56832.026205,0.00001);
assert(r.getValue('stress')(1),72734.246324,0.00001);

fprintf('\tdoc_instrument:\tPricing Defined Contribution Plan A\n');
r = Retail();
r = r.set('Name','Test_DCP_A','sub_type','DCP','coupon_rate',0.00,'coupon_generation_method','forward','term',1,'term_unit','months');
r = r.set('maturity_date','01-Jun-2050','compounding_type','simple','savings_rate',192);
r = r.set('savings_startdate','01-Apr-2019','savings_enddate','01-May-2050');
r = r.set('redemption_values',[328.65,2603.40,25343.14],'redemption_dates',{'31-May-2019','31-May-2020','31-May-2030'});
r = r.set('notice_period',1,'notice_period_unit','years');
r = r.rollout('base',valuation_date,c);
r = r.rollout('stress',valuation_date,c);
r = r.calc_value(valuation_date,'base',c);
r = r.calc_value(valuation_date,'stress',c);
r = r.calc_sensitivities(valuation_date,c);
r = r.calc_key_rates(valuation_date,c);
assert(r.getValue('base'),319.728947,0.00001);
assert(r.getValue('stress')(1),1508.251741,0.00001)


fprintf('\tdoc_instrument:\tPricing Defined Contribution Plan P\n');
r = Retail();
r = r.set('Name','Test_DCP_B','sub_type','DCP','coupon_rate',0.006442,'coupon_generation_method','forward','term',1,'term_unit','months');
r = r.set('maturity_date','01-Jan-2048','compounding_type','simple','savings_rate',240);
r = r.set('savings_startdate','01-Apr-2012','savings_enddate','01-Dec-2047');
r = r.set('redemption_values',[15583,18631,25343.14],'redemption_dates',{'31-Dec-2018','31-Dec-2019','31-May-2030'});
r = r.set('notice_period',1,'notice_period_unit','years');
r = r.set('savings_change_values',[224,232,238,242,248,254,0,254],'savings_change_dates',{'01-Apr-2012','01-Jan-2013','01-Jan-2014','01-Jan-2015','01-Jan-2016','01-Jan-2017','01-Aug-2017','01-Dec-2018'});
r = r.rollout('base',valuation_date,c);
r = r.rollout('stress',valuation_date,c);
r = r.calc_value(valuation_date,'base',c);
r = r.calc_value(valuation_date,'stress',c);
r = r.calc_sensitivities(valuation_date,c);
r = r.calc_key_rates(valuation_date,c);
r
% toco: append instrument to private portfolio and use these tests for doc_instrument integration tests


end

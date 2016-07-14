function testcontainer()

ret = 0;
% Manual compilation of all unittests in functions:
ret = ret + assert_octave(calibrate_option_bjsten(0,10000,11000,365,0.01,0.2,0.0,2,2600),-0.0172916909133740,0.001)
ret = ret + assert_octave(calibrate_option_bjsten(0,286.867623322,368.7362,3650,0.0045624391,0.210360082233,0.00,1,120),-0.00654341488084162,0.001)
ret = ret + assert_octave(calibrate_option_bs(0,10000,11000,365,0.01,0.2,2,2600),-0.0137199,0.002)
ret = ret + assert_octave(calibrate_soy_sqp(datenum('31-Dec-2015'),[182,547,912],[3,3,103],99.9,[90,365,730,1095],[0.01,0.02,0.025,0.028],3,'discrete','annual','monotone-convex'),0.010435195167,0.0001)
ret = ret + assert_octave(convert_curve_rates(datenum('31-Dec-2015'),643,0.0060519888,'cont','daily',3,'simple','daily',3),0.006084365,0.0000001)
ret = ret + assert_octave(convert_curve_rates(datenum('31-Mar-2016'),2190,0.0003066350,'cont','daily',3,'disc','annual',11),0.0003066820,0.000000001)
ret = ret + assert_octave(convert_curve_rates(datenum('31-Mar-2016'),2190,0.0003066350,'cont','daily',3,'disc','daily',0),0.0003068805,0.000000001)
ret = ret + assert_octave(convert_curve_rates(datenum('31-Mar-2016'),2190,0.0003066350,'cont','daily',3,'simple','daily',0),0.0003071629,0.000000001)

ret = ret + assert_octave(discount_factor ('31-Mar-2016', '30-Mar-2021', 0.00010010120979, 'disc', 'act/365', 'annual'),0.999499644219733,0.000001)
ret = ret + assert_octave(get_forward_rate([365,1825,3650],[0.05,0.06,0.065],1825,1095,'disc','linear',2),0.0691669,0.00001)
ret = ret + assert_octave(get_forward_rate([365,1825,3650],[0.05,0.06,0.065],1825,1095,'disc','linear',2,3),0.0691669,0.00001)
ret = ret + assert_octave(get_forward_rate([365,1825,3650],[0.05,0.06,0.065],1825,1095,'disc','linear',2,0),0.0691636237,0.00001)
ret = ret + assert_octave(get_forward_rate([730,4380],[0.0023001034,0.0084599362],'31-Mar-2018','28-Mar-2028','disc','linear',1,3,'31-Mar-2016'),0.0094902,0.00001)
ret = ret + assert_octave(get_forward_rate([365,1095,1825,3650,7300,10950,21900],[-0.0051925,-0.0050859,-0.0036776,0.0018569,0.0077625,0.0099999,0.0012300],155,365,'disc','monotone-convex', 'daily', 'act/365', 736329, 'cont', 'act/365', 'annual'),0.000001)
ret = ret + assert_octave(interpolate_curve ([365,730,1095], [0.01,0.02,0.025;0.015,-0.02,0.04], 433, 'monotone-convex' ),[0.012116882;0.007318077],0.000001)
ret = ret + assert_octave(interpolate_curve ([365,730,1095], [0.01,0.02,0.025;0.015,-0.02,0.04], 433, 'linear'),[0.01186301;0.00847945],0.000001)
ret = ret + assert_octave(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'linear'),0.004927301319,0.0000000001)
ret = ret + assert_octave(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'mm'),0.00494794483,0.0000000001)
ret = ret + assert_octave(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'exponential'),0.004927396730,0.0000000001)
ret = ret + assert_octave(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'constant'),0.0045624391,0.0000000001)
ret = ret + assert_octave(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'previous'),0.0045624391,0.0000000001)
ret = ret + assert_octave(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'next'),0.0054502705,0.0000000001)
ret = ret + assert_octave(option_barrier(1,'D','in',100,90,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [7.762670;9.009344],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','in',100,100,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [4.010942;5.137039],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','in',100,110,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.057613;2.851683],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','in',100,90,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [13.833287;14.881621],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','in',100,100,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [7.849428;9.204497],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','in',100,110,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.979520;5.304301],0.000001)
ret = ret + assert_octave(option_barrier(1,'U','in',100,90,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [14.111173;15.209846],0.000001)
ret = ret + assert_octave(option_barrier(1,'U','in',100,100,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [8.448206;9.727822],0.000001)
ret = ret + assert_octave(option_barrier(1,'U','in',100,110,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [4.590969;5.835036],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','out',100,90,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [9.024568;8.833358],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','out',100,100,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [6.792437;7.028540],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','out',100,110,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [4.875858;5.413700],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','out',100,90,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','out',100,100,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','out',100,110,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
ret = ret + assert_octave(option_barrier(1,'U','out',100,90,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.678913;2.634042],0.000001)
ret = ret + assert_octave(option_barrier(1,'U','out',100,100,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.358020;2.438942],0.000001)
ret = ret + assert_octave(option_barrier(1,'U','out',100,110,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.345349;2.431533],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','out',100,90,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.279838;2.416990],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','out',100,100,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.294750;2.425810],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','out',100,110,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.625214;2.624607],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','out',100,90,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','out',100,100,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','out',100,110,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.000000;3.000000],0.000001)
ret = ret + assert_octave(option_barrier(0,'U','out',100,90,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.775955;4.229237],0.000001)
ret = ret + assert_octave(option_barrier(0,'U','out',100,100,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [5.493228;5.803252],0.000001)
ret = ret + assert_octave(option_barrier(0,'U','out',100,110,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [7.518722;7.564957],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','in',100,90,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.958582;3.876894],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','in',100,100,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [6.567705;7.798846],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','in',100,110,95,365*0.5,0.08,[0.25;0.3],0.04,3) , [11.975228;13.307747],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','in',100,90,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [2.284469;3.332803],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','in',100,100,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [5.908504;7.263574],0.000001)
ret = ret + assert_octave(option_barrier(0,'D','in',100,110,100,365*0.5,0.08,[0.25;0.3],0.04,3) , [11.646491;12.971272],0.000001)
ret = ret + assert_octave(option_barrier(0,'U','in',100,90,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [1.465313;2.065833],0.000001)
ret = ret + assert_octave(option_barrier(0,'U','in',100,100,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [3.372075;4.422589],0.000001)
ret = ret + assert_octave(option_barrier(0,'U','in',100,110,105,365*0.5,0.08,[0.25;0.3],0.04,3) , [7.084567;8.368582],0.000001)
ret = ret + assert_octave(option_barrier(1,'D','out',100,[90;100;110;90;100;110],[95;95;95;100;100;100],365*0.5,0.08,0.25,0.04,3),[9.0246;6.7924;4.8759;3.0000;3.0000;3.0000],0.0001)
ret = ret + assert_octave(option_barrier(1,'D','in',100,[90;100;110;90;100;110],[95;95;95;100;100;100],365*0.5,0.08,0.25,0.04,3),[7.7627;4.0109;2.0576;13.8333;7.8494;3.9795],0.0001)
ret = ret + assert_octave(option_barrier(1,'U','out',100,[90;100;110],[105;105;105],365*0.5,0.08,0.25,0.04,3),[2.6789;2.3580;2.3453],0.0001)
ret = ret + assert_octave(option_barrier(1,'U','in',100,[90;100;110],[105;105;105],365*0.5,0.08,0.25,0.04,3),[14.1112;8.4482;4.5910],0.0001)
ret = ret + assert_octave(option_barrier(0,'U','in',100,[90;100;110],[105;105;105],365*0.5,0.08,0.25,0.04,3),[1.4653;3.3721;7.0846],0.0001)
ret = ret + assert_octave(option_barrier(0,'U','out',100,[90;100;110],[105;105;105],365*0.5,0.08,0.25,0.04,3),[3.7760;5.4932;7.5187],0.0001)
ret = ret + assert_octave(option_barrier(0,'D','in',100,[90;100;110;90;100;110],[95;95;95;100;100;100],365*0.5,0.08,0.25,0.04,3),[2.9586;6.5677;11.9752;2.2845;5.9085;11.6465 ],0.0001)
ret = ret + assert_octave(option_barrier(0,'D','out',100,[90;100;110;90;100;110],[95;95;95;100;100;100],365*0.5,0.08,0.25,0.04,3),[2.2798;2.2947;2.6252;3.0000;3.0000;3.0000],0.0001)
ret = ret + assert_octave(option_bjsten(1,42,40,0.75*365,0.04,0.35,0.08),5.27040387879757,0.00000001);
ret = ret + assert_octave(option_bjsten(0,286.867623322,368.7362,3650,0.0045624391,0.210360082233,0.00),122.290954391343,0.00000001);
ret = ret + assert_octave(option_bs(0,[10000;9000;11000],11000,365,0.01,[0.2;0.025;0.03]),[1351.5596289;1890.5481719;83.4751769],0.000002)
ret = ret + assert_octave(option_bs(1,[10000;9000;11000],11000,365,0.01,[0.2;0.025;0.03]),[461.0114579;3.0875e-013;192.9270059],0.000002)
ret = ret + assert_octave(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028;0.005,0.015,0.019,0.024;-0.04,0.03,-0.02,0.05],11,'cont','annual','monotone-convex'),[101.0136109;102.2586319;104.6563569],0.000002)
ret = ret + assert_octave(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028],0,'discrete','annual','smith-wilson'),101.1471149,0.000001)
ret = ret + assert_octave(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028],3,'discrete','annual','monotone-convex'),101.1365279,0.000001)
ret = ret + assert_octave(pricing_npv(datenum('31-Dec-2015'),[182,547,912],[3,3,103],0.005,[90,365,730,1095],[0.01,0.02,0.025,0.028],3,'discrete','annual','linear'),101.1740699,0.000001)
 
 ret = ret + assert_octave(swaption_bachelier(1,0.0262,0.062,1825,0.06,0.01219,2,3),0.002561702287606,0.00001);
 ret = ret + assert_octave(swaption_black76(1,0.0262,0.062,1825,0.06,0.2,2,3),3.877466091026955e-04,0.00001);

ret = ret + assert_octave(timefactor('31-Dec-2015','29-Feb-2024',0),8.16393410,0.00001)
ret = ret + assert_octave(timefactor('31-Dec-2015','29-Feb-2024',3),8.16986310,0.00001)
ret = ret + assert_octave(timefactor('31-Dec-2015','29-Feb-2024',11),8.16388910,0.00001)
ret = ret + assert_octave(yeardays(2000), 366)
ret = ret + assert_octave(yeardays(2001), 365)
ret = ret + assert_octave(yeardays(2000:2004), [366 365 365 365 366])
ret = ret + assert_octave(yeardays(2000, 0), 366)
ret = ret + assert_octave(yeardays(2000, 1), 360)
ret = ret + assert_octave(yeardays(2000, 2), 360)
ret = ret + assert_octave(yeardays(2000, 3), 365)
ret = ret + assert_octave(yeardays(2000, 4), 360)
ret = ret + assert_octave(yeardays(2000, 5), 360)
ret = ret + assert_octave(yeardays(2000, 6), 360)
ret = ret + assert_octave(yeardays(2000, 7), 365)
ret = ret + assert_octave(yeardays(2000, 8), 366)
ret = ret + assert_octave(yeardays(2000, 9), 360)
ret = ret + assert_octave(yeardays(2000, 10), 365)
ret = ret + assert_octave(yeardays(2000, 11), 360)
ret = ret + assert_octave(interpolate_curve ([365,730,1095], [0.01,0.02,0.025;0.015,-0.02,0.04], 433, 'smith-wilson',0.05,0.12),[0.012023083;0.0015458739299],0.000001)

% print test statistics
if ret > 0
    fprintf('ERROR: %d tests failed.\n',ret);
else
    fprintf('SUCCESS: All tests passed.\n');
end
end


% helper function
function ret = assert_octave(a,b,c)
if nargin < 3
    c = 0.0001;
end
    res = a - b;
    if ( res < c )
        ret = 0;
    else
        fprintf('ERROR: test failed: %f not equal to %f\n',a,b);
        ret = 1;
    end
end
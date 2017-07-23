%# Copyright (C) 2015 Stefan Schlögl <schinzilord@octarisk.com>
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
%#
%# You should have received a copy of the GNU General Public License along with
%# this program; if not, see <http://www.gnu.org/licenses/>.
 
%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{tf} @var{dip} @var{dib}] =} timefactor(@var{d1}, @var{d2}, @var{basis})
%#
%# Compute the time factor for a specific time period and day count basis.@*
%# Depending on day count basis, the time factor is evaluated as 
%# (days in period) / (days in year)
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{d1}: 			number of days until first date (scalar)
%# @item @var{d2}: 			number of days until second date (scalar)
%# @item @var{basis}: 		day-count basis (scalar or string)
%# @item @var{df}: 		OUTPUT: discount factor (scalar)
%# @item @var{dip}: 	OUTPUT: days in period (nominator of time factor) (scalar)
%# @item @var{dib}: 	OUTPUT: days in base (denominator of time factor) (scalar)
%# @end itemize
%# @seealso{discount_factor, yeardays, get_basis}
%# @end deftypefn

function [tf dip dib] = timefactor (d1, d2, basis)

% Error check

if nargin < 2
   error('Needed at least date1 and date2')
end
if ischar(d1)
   d1 = datenum(d1,1);
end
if ischar(d2)
   d2 = datenum(d2,1);
end

if nargin < 3
   basis = 3;   % defaulting to act/365
end
% convert basis string into basis value in [0...11]
if ischar(basis)
    basis = get_basis(basis);
elseif ~(any(basis == [0:1:15]))
   fprintf('timefactor:no valid basis defined. >>%d<< has to be between 0 and 15. Setting to default value 3 -> act/365. \n',basis)
   basis = 3;
end

% no negative timefactor
if d1 > d2
    error('timefactor: d1 >>%s<< is greater than d2 >>%s<<.',any2str(d1),any2str(d2))
end

% calculate nominator: days in period (dip)
if (any(basis == [0,2,3,7,8,9,10,15]))     % act/XXX
    %actual days in period
    dip = d2 - d1;
elseif (basis == 1)                    % 30/360 SIA
    dvec1 = datevec(d1);
    dvec2 = datevec(d2);
    days1 = dvec1(:,3);
    months1 = dvec1(:,2);
    years1 = dvec1(:,1);
    days2 = dvec2(:,3);
    months2 = dvec2(:,2);
    years2 = dvec2(:,1);
    % adjustments
   % 1. If the last date of the accrual period is the last day of February 
    %    and the first date of the period is the last day of February, then the 
    %    last date of the period will be changed to the 30th.
    days2(d2 == eomdate(years2,2) & d1 == eomdate(years1,2)) = 30;

    % 2. If the first date of the accrual period falls on the 31st of a month 
    %    or is the last day of February, that date will be changed to the 
    %    30th of the month.   
    days1_orig = days1;
    days1(31 == days1 & d1 == eomdate(years1,2)) = 30;
    step2_adjusted = ~(days1_orig == days1);
    
    % 3. If the first date of the accrual period falls on the 30th of a month 
    %    after applying (2) above, and the last date of the period falls on 
    %    the 31st of a month, the last date will be changed to the 30th of 
    %    the month.
    days2(days1 == 30 & days2 == 31 & step2_adjusted) = 30;
    
    % calculation
    dip = (years2 - years1) .* 360 + ( months2 - months1 ) .* 30 + ( days2 - days1 );

elseif (basis == 13)                    % 30/360
    dvec1 = datevec(d1);
    dvec2 = datevec(d2);
    days1 = dvec1(:,3);
    months1 = dvec1(:,2);
    years1 = dvec1(:,1);
    days2 = dvec2(:,3);
    months2 = dvec2(:,2);
    years2 = dvec2(:,1);
    % adjustments

    % 1. If the last date of the accrual period is the last day of February 
    %    and the first date of the period is the last day of February, then the 
    %    last date of the period will be changed to the 30th.
    days2(d2 == eomdate(years2,2) .* ( d1 == eomdate(years1,2))) = 30;

     % 2. If days1 is the last day of February, change days1 to 30. 
    days1_step2_unadjusted = days1;
    days1(d1 == eomdate(years1,2)) = 30;

    % 3. If days2 is 31, change it to 30 only if days1 (after the possible 
    %    adjustment at step (ii)) is 30 or 31.
    days2(days2 == 31 .* any(days1 == [30,31]) .* (~(days1_step2_unadjusted == days1))) = 30;

    % 4. If days1 is 31, change it to 30.
    days1(days1 == 31) = 30;

    % calculation
    dip = (years2 - years1) .* 360 + ( months2 - months1 ) .* 30 + ( days2 - days1 );
    
% 30 days per month    
elseif (any(basis == [4,5,6,11]))     % 30/XXX             
        dvec1 = datevec(d1);
        dvec2 = datevec(d2);
        days1 = dvec1(:,3);
        months1 = dvec1(:,2);
        years1 = dvec1(:,1);
        days2 = dvec2(:,3);
        months2 = dvec2(:,2);
        years2 = dvec2(:,1);
        % special case 30/360E or 30/360 European: adjust days in month to 30
        if ( any(basis == [6,11]) )  
            days1 = min(days1,30);
            days2 = min(days2,30);
        end
        dip = (years2 - years1) .* 360 + ( months2 - months1 ) .* 30 + ( days2 - days1 );
elseif(basis == 14)                     % business/252
    % vectorized code not possible because of holiday function
    if ~( length(d1) == length(d2))
        if ( length(d1) < length(d2))
            d1 = repmat(d1,length(d2),1);
        else
            d2 = repmat(d2,length(d1),1);
        end
    end
    dip = zeros(length(d2),1);
    % for each accrual period calculate business days
    for ii = 1:1:length(d2)
        dip(ii) = length(busdays(d1(ii),d2(ii)));
    end
end

% calculate days in base (dib)
if (any(basis == [1,2,4,5,6,9,11,13]))  % YYY/360
    dib = 360;
elseif (any(basis == [3,7,10]))         % YYY/365
    dib = 365;
elseif (basis == 14)                    % business/252
    dib = 252;
elseif (basis == 15)                    % YYY/364
    dib = 364;
elseif (any(basis == [0,8]))            % YYY/actual
        dvec1 = datevec(d1);
        dvec2 = datevec(d2);
        days1 = dvec1(:,3);
        months1 = dvec1(:,2);
        years1 = dvec1(:,1);
        days2 = dvec2(:,3);
        months2 = dvec2(:,2);
        years2 = dvec2(:,1);
        % if years1 == years2 
        y1_eq_y2 = years1 == years2;
            dip_y1_eq_y2 = d2 - d1;
            dib_y1_eq_y2 = yeardays_actual(years1);
        % elseif  years2 > years1
        y2_gt_y1 = years2 > years1;
            y1_ymonth_day_matrix = repmat([12,31,0,0,0],length(years1),1);
            y2_ymonth_day_matrix = repmat([01,01,0,0,0],length(years2),1);
            end_of_year_period1 = horzcat(years1,y1_ymonth_day_matrix);
            begin_of_year_period2 = horzcat(years2,y2_ymonth_day_matrix);
            days_period1 = datenum(end_of_year_period1) - d1;
            days_period2 = d2 - datenum(begin_of_year_period2) + 1;
            dib_y2_gt_y1 = 1;
            dip_y2_gt_y1 = (days_period1 ./ yeardays_actual(years1)) + ...
                (days_period2 ./ yeardays_actual(years2)) + (years2 - years1 - 1);           
        % else
        y1_gt_y2 = years1 > years2;
            dip_y1_gt_y2 = 0;
            dib_y1_gt_y2 = 1;
            
        % concatenate all cases
        dip = y1_gt_y2 .* dip_y1_gt_y2 + y2_gt_y1 .* dip_y2_gt_y1 + y1_eq_y2 .* dip_y1_eq_y2;
        dib = y1_gt_y2 .* dib_y1_gt_y2 + y2_gt_y1 .* dib_y2_gt_y1 + y1_eq_y2 .* dib_y1_eq_y2;        
end

% calculate timefactor
tf = dip ./ dib;
 
end
 
% helper function yeardays_actual()
function days = yeardays_actual(year)
    days = 365 + (eomday(year, 2) == 29);
end


% testing
%!assert(timefactor('31-Dec-2015','29-Feb-2024',0),8.16393410,0.000001) 
%!assert(timefactor('31-Dec-2015','29-Feb-2024',3),8.16986310,0.000001) 
%!assert(timefactor('31-Dec-2015','29-Feb-2024',22),8.16986310,0.000001) 
%!assert(timefactor('31-Dec-2015','29-Feb-2024'),8.16986310,0.000001) 
%!assert(timefactor('31-Dec-2015','29-Feb-2024',11),8.16388910,0.000001) 
%!assert(timefactor('31-Dec-2015','29-Feb-2024','act/act'),8.16393410,0.000001) 
%!assert(timefactor('31-Dec-2015','29-Feb-2024','act/365'),8.16986310,0.000001) 
%!assert(timefactor('31-Dec-2015','29-Feb-2024','30/360E'),8.16388910,0.000001) 
%!assert(timefactor('31-Dec-2015','29-Feb-2024','nonsensedefaultsto3'),8.16986310,0.00001) 
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],0),[0.259562841530055;0.669398907103825;0.997267759562842;1.997260273972603;9.991780821917809],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],1),[0.258333333333333;0.666666666666667;0.997222222222222;1.997222222222222;9.991666666666667],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],2),[0.263888888888889;0.680555555555556;1.013888888888889;2.027777777777778;10.138888888888889],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],3),[0.260273972602740;0.671232876712329;1.000000000000000;2.000000000000000;10.000000000000000],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],4),[0.258333333333333;0.666666666666667;0.997222222222222;1.997222222222222;9.991666666666667],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],5),[0.258333333333333;0.666666666666667;0.997222222222222;1.997222222222222;9.991666666666667],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],6),[0.261111111111111;0.669444444444444;1.000000000000000;2.000000000000000;9.994444444444444],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],7),[0.260273972602740;0.671232876712329;1.000000000000000;2.000000000000000;10.000000000000000],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],8),[0.259562841530055;0.669398907103825;0.997267759562842;1.997260273972603;9.991780821917809],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],9),[0.263888888888889;0.680555555555556;1.013888888888889;2.027777777777778;10.138888888888889],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],11),[0.261111111111111;0.669444444444444;1.000000000000000;2.000000000000000;9.994444444444444],0.00000001)
%!assert(timefactor('31-Dec-2015',736329 .+ [95;245;365;730;3650],10),[0.260273972602740;0.671232876712329;1.000000000000000;2.000000000000000;10.000000000000000],0.00000001)
%!assert(timefactor(736329 .+ [95;245;365;730;3650],736329 .+ [95;245;365;730;3650],8),[0;0;0;0;0])
%!assert(timefactor(736329 .+ [94;243;362;731;3651],736329 .+ [95;245;365;730;3650],0),[0.00273224043715847;0.00546448087431694;0.00819672131147541;-0.00273972602739726;-0.00273972602739726],0.00000001)
%!error(timefactor('31-Dec-2025','29-Feb-2000',8)) 
%!error(timefactor('31-Dec-2025','29-Feb-2024',3))


%!assert(timefactor ('29-Feb-2016', 736389 + [95; 245; 364; 365; 366; 730; 3650], '30/360 European'),[0.261111111111111;0.669444444444444;0.994444444444444;0.997222222222222;1.005555555555556;1.997222222222222;9.991666666666667],0.000000001)
%!assert(timefactor ('29-Feb-2016', 736389 + [95; 245; 364; 365; 366; 730; 3650], '30/360 GERMAN'),[0.258333333333333;0.666666666666667;0.991666666666667;1.000000000000000;1.002777777777778;2.000000000000000;9.988888888888889],0.000000001)
%!assert(timefactor ('29-Feb-2016', 736389 + [95; 245; 364; 365; 366; 730; 3650], '30/360'),[0.258333333333333;0.666666666666667;0.991666666666667;1.000000000000000;1.002777777777778;2.000000000000000;9.988888888888889],0.0000000001)
%!assert(timefactor ('29-Feb-2016', '27-Feb-2017', 'act/364'),1.00000000000,0.00000001)
%!assert(timefactor ('29-Feb-2016', '27-Feb-2017', 15),1.00000000000,0.00000001)

% The following examples are taken from FINCAD "http://docs.fincad.com/support/developerfunc/mathref/Daycount.htm"
% 30/360 (SIA)
%!assert(timefactor(datenum('25-Oct-1996'),datenum('31-Dec-1996'),1),0.183333333333333,0.0000000001)
%!assert(timefactor(datenum('27-Jan-1998'),datenum('01-Feb-1999'),1),1.01111111111111,0.0000000001)
% 30E/360
%!assert(timefactor(datenum('25-Oct-1996'),datenum('31-Dec-1996'),11),0.180555556,0.0000001)
%!assert(timefactor(datenum('27-Jan-1998'),datenum('01-Feb-1999'),11),1.01111111111111,0.00000001)
% act/365:
%!assert(timefactor(datenum('25-Oct-1996'),datenum('31-Dec-1996'),3),0.183561644,0.00000001)
%!assert(timefactor(datenum('27-Jan-1998'),datenum('01-Feb-1999'),3),1.01369863,0.00000001)
% act/360
%!assert(timefactor(datenum('25-Oct-1996'),datenum('31-Dec-1996'),2),0.186111111,0.00000001)
%!assert(timefactor(datenum('27-Jan-1998'),datenum('01-Feb-1999'),2),1.027777778,0.00000001)
% act/act
%!assert(timefactor(datenum('25-Oct-1996'),datenum('31-Dec-1996'),0),0.183060109,0.00000001)
%!assert(timefactor(datenum('27-Jan-1998'),datenum('01-Feb-1999'),0),1.01369863,0.00000001)


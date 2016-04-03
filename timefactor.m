## Copyright (C) 2015 Stefan Schlögl <schinzilord@octarisk.com>
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.
 
## -*- texinfo -*-
## @deftypefn {Function File} {[@var{tf} @var{dip} @var{dib}] =} timefactor (@var{d1}, @var{d2}, @var{basis})
##
## Compute the time factor for a specific time period and day count basis.@*
## Depending on day count basis, the time factor is evaluated as (days in period)/(days in year)
##
## Input and output variables:
## @itemize @bullet
## @item @var{d1}: 			number of days until first date (scalar)
## @item @var{d2}: 			number of days until second date (scalar)
## @item @var{basis}: 		day-count basis (scalar)
##		@itemize @bullet
## 			@item @var{0} = actual/actual 
## 			@item @var{1} = 30/360 SIA (default)
## 			@item @var{2} = act/360
## 			@item @var{3} = act/365
## 			@item @var{4} = 30/360 PSA
## 			@item @var{5} = 30/360 ISDA
## 			@item @var{6} = 30/360 European
## 			@item @var{7} = act/365 Japanese
## 			@item @var{8} = act/act ISMA
## 			@item @var{9} = act/360 ISMA
## 			@item @var{10} = act/365 ISMA
## 			@item @var{11} = 30/360E (ISMA)
##      @end itemize
## @item @var{df}: 		OUTPUT: discount factor (scalar)
## @item @var{dip}: 	OUTPUT: days in period (nominator of time factor) (scalar)
## @item @var{dib}: 	OUTPUT: days in base (denominator of time factor) (scalar)
## @end itemize
## @seealso{discount_factor, daysact, yeardays}
## @end deftypefn

function [tf dip dib] = timefactor (d1, d2, basis)

% Error check

if nargin < 2
   error('Needed at least date1 and date2')
end
if ischar(d1) || ischar(d2)
   d1 = datenum(d1);
   d2 = datenum(d2);
end
if nargin < 3
   basis = 3.*ones(size(d1));
end
if ischar(basis)
    dcc_cell = cellstr( ['act/act';'30/360 SIA';'act/360';'act/365';'30/360 PSA';'30/360 ISDA';'30/360 European';'act/365 Japanese';'act/act ISMA';'act/360 ISMA';'act/365 ISMA';'30/360E']);
    findvec = strcmp(basis,dcc_cell);
    tt = 1:1:length(dcc_cell);
    tt = (tt .- 1)';
    basis = dot(single(findvec),tt);
elseif (isempty(find([0:1:11] == basis)))
   error('no valid basis defined. ')
end

% calculate nominator: days in period (dip)
if ( basis == 0 || basis == 2 || basis == 3 || basis == 7 || basis == 8 || basis == 9 || basis == 10)   %actual days in period
    dip = d2 .- d1;
elseif ( basis == 1 || basis == 4 || basis == 5 || basis == 6 || basis == 11 )              % 30 days per month
        dvec1 = datevec(d1);
        dvec2 = datevec(d2);
        days1 = dvec1(:,3);
        months1 = dvec1(:,2);
        years1 = dvec1(:,1);
        days2 = dvec2(:,3);
        months2 = dvec2(:,2);
        years2 = dvec2(:,1);
        if ( basis == 11 )
            days1 = min(days1,30);
            days2 = min(days2,30);
        endif
        dip = (years2 .- years1) .* 360 + ( months2 .- months1 ) .* 30 + ( days2 .- days1 );
endif

% calculate days in base (dib)
if ( basis == 1 || basis == 2 || basis == 4 || basis == 5 || basis == 6 || basis == 9 || basis == 11)
    dib = 360;
elseif ( basis == 3 || basis == 7 || basis == 10 )
    dib = 365;
elseif ( basis == 0 || basis == 8 ) % actual/actual
        dvec1 = datevec(d1);
        dvec2 = datevec(d2);
        days1 = dvec1(:,3);
        months1 = dvec1(:,2);
        years1 = dvec1(:,1);
        days2 = dvec2(:,3);
        months2 = dvec2(:,2);
        years2 = dvec2(:,1);
        if  years1 == years2  %coupon period in between one year
            dip = daysact(dvec1,dvec2);
            dib = yeardays(years1,basis);
        endif 
        
        if  years2 > years1
            end_of_year_period1 = [years1,12,31,0,0,0];
            yeardays(years1,basis);
            begin_of_year_period2 = [years2,01,01,0,0,0];
            yeardays(years2,basis);
            days_period1 = daysact(dvec1,end_of_year_period1) ;
            days_period2 = daysact(begin_of_year_period2,dvec2) + 1;
            dib = 1;
            dip = (days_period1 ./ yeardays(years1,basis)) .+ (days_period2 ./ yeardays(years2,basis)) + (years2 .- years1 .- 1);          
        endif
        
endif

% calculate timefactor
tf = dip ./ dib;
 
endfunction
 
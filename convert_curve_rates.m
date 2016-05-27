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
%#
%# You should have received a copy of the GNU General Public License along with
%# this program; if not, see <http://www.gnu.org/licenses/>.

%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{rate_target} @var{conversion_type}] =} convert_curve_rates (@var{valuation_date}, @var{node}, @var{rate_origin}, @var{comp_type_origin}, @var{comp_freq_origin}, @var{dcc_basis_origin}, @var{comp_type_target}, @var{comp_freq_target}, @var{dcc_basis_target})
%# Convert a given interest rate from one compounding type, frequency and day count convention (dcc) into another type, frequency and dcc. @*
%#
%#  The following conversion formulas are applied:  (the timefactor is depending on 
%#  day count convention and days between valuation_date and valuation_date + node)). Convert
%#  @example
%#  from CONT ->   SMP:    (exp(rate_origin .* timefactor_origin) -1) ./ timefactor_target
%#  from SMP ->    CONT:   ln(1 + rate_origin .* timefactor_origin) ./ timefactor_target
%#  from DISC ->   CONT:   ln(1 + rate_origin./ comp_freq_origin) .* (timefactor_origin .* comp_freq_origin) ./ timefactor_target
%#  from CONT ->   DISC:   (exp(rate_origin .* timefactor_origin ./ (comp_freq_target .* timefactor_target)) - 1 ) .* comp_freq_target
%#  from SMP ->    DISC:   ( (1 + rate_origin .* timefactor_origin).^(1./( comp_freq_target .* timefactor_target)) -1 ) .* comp_freq_target
%#  from DISC ->   SMP:    ( (1 + rate_origin ./ comp_freq_origin ).^(comp_freq_origin .* timefactor_origin) -1 ) ./ timefactor_target
%#  from CONT ->   CONT:   rate_origin .* timefactor_origin ./ timefactor_target 
%#  from SMP ->    SMP:    rate_origin .* timefactor_origin ./ timefactor_target 
%#  from DISC ->   DISC:   ( (1 + rate_origin ./ comp_freq_origin).^((comp_freq_origin .* timefactor_origin) ./ ( comp_freq_target .* timefactor_target)) -1 ) .* comp_freq_target
%#  @end example
%#  Please note: compounding_freq is only relevant for compounding type DISCRETE. Otherwise it will be neglected. During object invocation, a default
%#  value for compounding_freq is set, even it is not required. Example call: @*
%#  @example
%#  0.006084365 = convert_curve_rates(datenum('31-Dec-2015'),643,0.0060519888,'cont','daily',3,'simple','daily',3)
%#  @end example
%# Input and output variables:
%# @itemize @bullet
%# @item @var{valuation_date}: 	base date used in timefactor calculation (datestr or datenum)
%# @item @var{node}: 			number of days until second date used in timefactor calculation (scalar)
%# @item @var{rate_origin}:     interest rate between first and second date (scalar)
%# @item @var{comp_type_origin}: compounding type of target rate: [simple, simp, disc, discrete, cont, continuous] (string)
%# @item @var{comp_freq_origin}: compounding frequency of target rate: 1,2,4,12,52,365 or [daily,weekly,monthly,quarter,semi-annual,annual] (scalar or string)
%# @item @var{dcc_basis_origin}: day-count basis of target rate(scalar)
%#		@itemize @bullet
%# 			@item @var{0} = actual/actual 
%# 			@item @var{1} = 30/360 SIA (default)
%# 			@item @var{2} = act/360
%# 			@item @var{3} = act/365
%# 			@item @var{4} = 30/360 PSA
%# 			@item @var{5} = 30/360 ISDA
%# 			@item @var{6} = 30/360 European
%# 			@item @var{7} = act/365 Japanese
%# 			@item @var{8} = act/act ISMA
%# 			@item @var{9} = act/360 ISMA
%# 			@item @var{10} = act/365 ISMA
%# 			@item @var{11} = 30/360E (ISMA)
%#      @end itemize
%# @item @var{comp_type_target}: compounding type of target rate: [simple, simp, disc, discrete, cont, continuous] (string)
%# @item @var{comp_freq_target}: compounding frequency of target rate: 1,2,4,12,52,365 or [daily,weekly,monthly,quarter,semi-annual,annual] (scalar or string)
%# @item @var{dcc_basis_target}: day-count basis of target rate(scalar)
%# @item @var{rate_target}: 	OUTPUT: converted interest rate
%# @item @var{conversion_type}: OUTPUT: conversion type from x to y
%# @end itemize
%# @seealso{timefactor}
%# @end deftypefn

function [rate_target conversion_type] = convert_curve_rates(valuation_date,node,rate_origin,comp_type_origin,comp_freq_origin,dcc_basis_origin, ...
                                            comp_type_target,comp_freq_target,dcc_basis_target)
                      
% Input checks
if nargin < 9
   error('Not enough input parameter provided')
end
if ~isnumeric(rate_origin)
    error('rate_origin is not a valid number')
end
if ischar(valuation_date) 
   valuation_date = datenum(valuation_date);
end

% convert SIMP -> SIMPLE etc.
if ( strcmp(toupper(comp_type_origin),'SIMP') )
    comp_type_origin = 'SIMPLE';
elseif ( strcmp(toupper(comp_type_origin),'DISC') )
    comp_type_origin = 'DISCRETE';
elseif ( strcmp(toupper(comp_type_origin),'CONT') )
    comp_type_origin = 'CONTINUOUS';
end
if ( strcmp(toupper(comp_type_target),'SIMP') )
    comp_type_target = 'SIMPLE';
elseif ( strcmp(toupper(comp_type_target),'DISC') )
    comp_type_target = 'DISCRETE';
elseif ( strcmp(toupper(comp_type_target),'CONT') )
    comp_type_target = 'CONTINUOUS';
end



conversion_type = '';
% abbreviation: origin and target types and dcc are the same -> return input rate
if ( strcmp(comp_type_origin,comp_type_target) && strcmp(num2str(comp_freq_origin),num2str(comp_freq_target)) && (dcc_basis_origin == dcc_basis_target))
    rate_target = rate_origin;
    conversion_type = 'No conversion';  
    return
end

% calculate timefactor:
% validation date as datenum or char
if ischar(valuation_date)
   valuation_date = datenum(valuation_date);
end
term_datenum = valuation_date + node;
timefactor_origin = timefactor(valuation_date,term_datenum,dcc_basis_origin);
timefactor_target = timefactor(valuation_date,term_datenum,dcc_basis_target);

% error check compounding frequency
if ischar(comp_freq_origin)
    if ( strcmp(comp_freq_origin,'daily') == 1 || strcmp(comp_freq_origin,'day') == 1)
        comp_freq_origin = 365;
    elseif ( strcmp(comp_freq_origin,'weekly') == 1 || strcmp(comp_freq_origin,'week') == 1)
        comp_freq_origin = 52;
    elseif ( strcmp(comp_freq_origin,'monthly') == 1 || strcmp(comp_freq_origin,'month') == 1)
        comp_freq_origin = 12;
    elseif ( strcmp(comp_freq_origin,'quarterly') == 1 ||  strcmp(comp_freq_origin,'quarter') == 1)
        comp_freq_origin = 4;
    elseif ( strcmp(comp_freq_origin,'semi-annual') == 1)
        comp_freq_origin = 2;
    elseif ( strcmp(comp_freq_origin,'annual') == 1 )
        comp_freq_origin = 1;       
    else
        error('convert_curve_rates: Need valid compounding frequency')
    end
end
if ischar(comp_freq_target)
    if ( strcmp(comp_freq_target,'daily') == 1 || strcmp(comp_freq_target,'day') == 1)
        comp_freq_target = 365;
    elseif ( strcmp(comp_freq_target,'weekly') == 1 || strcmp(comp_freq_target,'week') == 1)
        comp_freq_target = 52;
    elseif ( strcmp(comp_freq_target,'monthly') == 1 || strcmp(comp_freq_target,'month') == 1)
        comp_freq_target = 12;
    elseif ( strcmp(comp_freq_target,'quarterly') == 1 ||  strcmp(comp_freq_target,'quarter') == 1)
        comp_freq_target = 4;
    elseif ( strcmp(comp_freq_target,'semi-annual') == 1)
        comp_freq_target = 2;
    elseif ( strcmp(comp_freq_target,'annual') == 1 )
        comp_freq_target = 1;       
    else
        error('Need valid compounding frequency')
    end
end

% now  get one of the following cases:

%#  from CONT ->   SMP:    exp(rate_origin * timefactor_origin)-1)/ timefactor_target
if ( strcmp(toupper(comp_type_origin),'CONTINUOUS') && strcmp('SIMPLE',toupper(comp_type_target) )) 
    rate_target = (exp(rate_origin .* timefactor_origin) -1) ./ timefactor_target;
    conversion_type = 'CONT -> SMP';
%#  from SMP ->    CONT:   ln(1 + rate_origin * timefactor_origin) / timefactor_target
elseif ( strcmp(toupper(comp_type_origin),'SIMPLE') && strcmp('CONTINUOUS',toupper(comp_type_target)) ) 
    rate_target =  log(1 + rate_origin .* timefactor_origin) ./ timefactor_target;
    conversion_type = 'SMP -> CONT';
%#  from DISC ->   CONT:   ln(1 + rate_origin / comp_freq_origin) * (timefactor_origin * comp_freq_origin) ./ timefactor_target
elseif ( strcmp(toupper(comp_type_origin),'DISCRETE') && strcmp('CONTINUOUS',toupper(comp_type_target) ) )
    rate_target =  log(1 + rate_origin./ comp_freq_origin) .* (timefactor_origin .* comp_freq_origin) ./ timefactor_target;
    conversion_type = 'DISC -> CONT';
%#  from CONT ->   DISC:   (exp(rate_origin .* timefactor_origin ./ (comp_freq_target .* timefactor_target)) - 1 ) * comp_freq_target
elseif ( strcmp(toupper(comp_type_origin),'CONTINUOUS') && strcmp('DISCRETE',toupper(comp_type_target) ) )
    rate_target =  (exp(rate_origin .* timefactor_origin ./ (comp_freq_target .* timefactor_target)) - 1 ) .* comp_freq_target;
    conversion_type = 'CONT -> SMP';
%#  from SMP ->    DISC:   ( (1 + rate_origin * timefactor_origin)^(1/( comp_freq_target * timefactor_target)) ) * comp_freq_target
elseif ( strcmp(toupper(comp_type_origin),'SIMPLE') && strcmp('DISCRETE',toupper(comp_type_target) ) )
    rate_target =  ( (1 + rate_origin .* timefactor_origin).^(1./( comp_freq_target .* timefactor_target)) -1 ) .* comp_freq_target;
    conversion_type = 'SMP -> DISC';
%#  from DISC ->   SMP:    ( (1 + rate_origin / comp_freq_origin )^(comp_freq_origin * timefactor_origin) -1 ) / timefactor_target 
elseif ( strcmp(toupper(comp_type_origin),'DISCRETE') && strcmp('SIMPLE',toupper(comp_type_target) ) )
    rate_target =   ( (1 + rate_origin ./ comp_freq_origin ).^(comp_freq_origin .* timefactor_origin) -1 ) ./ timefactor_target;
    conversion_type = 'DISC -> SMP';
%#  from CONT ->   CONT:   rate_origin .* timefactor_origin ./ timefactor_target
elseif ( strcmp(toupper(comp_type_origin),'CONTINUOUS') && strcmp('CONTINUOUS',toupper(comp_type_target) ) )
    rate_target =   rate_origin .* timefactor_origin ./ timefactor_target;
    conversion_type = 'CONT -> CONT';
%#  from SMP ->   SMP:   rate_origin .* timefactor_origin ./ timefactor_target
elseif ( strcmp(toupper(comp_type_origin),'SIMPLE') && strcmp('SIMPLE',toupper(comp_type_target) ) )
    rate_target =   rate_origin .* timefactor_origin ./ timefactor_target;
    conversion_type = 'SMP -> SMP';
%#  from DISC ->   DISC:   rate_origin .* timefactor_origin ./ timefactor_target
elseif ( strcmp(toupper(comp_type_origin),'DISCRETE') && strcmp('DISCRETE',toupper(comp_type_target) ) )
    rate_target =   ( (1 + rate_origin ./ comp_freq_origin).^((comp_freq_origin .* timefactor_origin) ./ ( comp_freq_target .* timefactor_target)) -1 ) .* comp_freq_target;
    conversion_type = 'DISC -> DISC';    
else
    fprintf('Unknown compounding type origin >>%s<< or target >>%s<<. \n',comp_type_origin,toupper(comp_type_target));
    rate_target = rate_origin;
    conversion_type = 'No conversion';
end
% rate_origin(1:min(10,rows(rate_origin)))
% rate_target(1:min(10,rows(rate_target))) 
% conversion_type                  
end % end of function
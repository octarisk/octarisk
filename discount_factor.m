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
%# @deftypefn {Function File} {@var{df} =} discount_factor (@var{d1}, @var{d2}, @var{rate}, @var{comp_type}, @var{basis}, @var{comp_freq})
%#
%# Compute the discount factor for a specific time period, compounding type, day count basis and compounding frequency.@*
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{d1}: 			number of days until first date (scalar)
%# @item @var{d2}: 			number of days until second date (scalar)
%# @item @var{rate}: 		interest rate between first and second date (scalar)
%# @item @var{comp_type}: 	compounding type: [simple, simp, disc, discrete, cont, continuous] (string)
%# @item @var{basis}: 		day-count basis (scalar)
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
%# @item @var{comp_freq}: 	1,2,4,12,52,365 or [daily,weekly,monthly,quarter,semi-annual,annual] (scalar or string)
%# @item @var{df}: 			OUTPUT: discount factor (scalar)
%# @end itemize
%# @seealso{timefactor}
%# @end deftypefn

function df = discount_factor (d1, d2, rate, comp_type, basis, comp_freq)
% Error check
if nargin < 3
   error('Needed at least date1 and date2 and rate')
end
if ! isnumeric(rate)
    error('Rate is not a valid number')
end
if ischar(d1) || ischar(d2)
   d1 = datenum(d1);
   d2 = datenum(d2);
end
if nargin < 4
   compounding_type = 1;
   comp_type = 1;
   basis = ones(size(d1)).*3;
end
if nargin < 5
   basis = ones(size(d1)).*3;
end

if ischar(basis)
    dcc_cell = cellstr( ['act/act';'30/360 SIA';'act/360';'act/365';'30/360 PSA';'30/360 ISDA';'30/360 European';'act/365 Japanese';'act/act ISMA';'act/360 ISMA';'act/365 ISMA';'30/360E']);
    findvec = strcmp(basis,dcc_cell);
    tt = 1:1:length(dcc_cell);
    tt = (tt - 1)';
    basis = dot(single(findvec),tt);
end
if (isempty(find([0:1:11] == basis)))
   error('no valid basis defined. ')
end
if nargin < 6
    comp_freq = 1;
end
if ischar(comp_type)
    if ( strcmp(comp_type,'simple') == 1 || strcmp(comp_type,'Simple') == 1 || strcmp(comp_type,'simp') == 1 )
        compounding_type = 1;
    elseif ( strcmp(comp_type,'disc') == 1 || strcmp(comp_type,'Disc') == 1 || strcmp(comp_type,'discrete') == 1)
        compounding_type = 2;
    elseif ( strcmp(comp_type,'cont') == 1 || strcmp(comp_type,'Cont') == 1 || strcmp(comp_type,'continuous') == 1)
        compounding_type = 3;
    else
        error('Need valid compounding_type type')
    end
end

% error check compounding frequency
if ischar(comp_freq)
    if ( strcmp(comp_freq,'daily') == 1 || strcmp(comp_freq,'day') == 1)
        compounding = 365;
    elseif ( strcmp(comp_freq,'weekly') == 1 || strcmp(comp_freq,'week') == 1)
        compounding = 52;
    elseif ( strcmp(comp_freq,'monthly') == 1 || strcmp(comp_freq,'month') == 1)
        compounding = 12;
    elseif ( strcmp(comp_freq,'quarterly') == 1 ||  strcmp(comp_freq,'quarter') == 1)
        compounding = 4;
    elseif ( strcmp(comp_freq,'semi-annual') == 1)
        compounding = 2;
    elseif ( strcmp(comp_freq,'annual') == 1 )
        compounding = 1;       
    else
        error('Need valid compounding frequency')
    end
else
    compounding = comp_freq;
end

% get timefactor
tf = timefactor(d1,d2,basis);

% calculate discount factor
% 3 cases
if ( compounding_type == 1)      % simple
    df = 1 ./ ( 1 + rate .* tf );
elseif ( compounding_type == 2)      % discrete
    df = 1 ./ (( 1 + ( rate ./ compounding) ).^( compounding .* tf));
elseif ( compounding_type == 3)      % continuous
    df = exp(-rate .* tf );
end

 
end
 

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
%# @deftypefn {Function File} {[@var{basis} ] =} get_basis(@var{dcc_string})
%#
%# Map the basis for value according to a day count convention string.
%# In order to introduce new day count conventions, add the basis to the cell
%# and include the calculation method for the day count convention into the
%# function timefactor(). 
%#
%# The following mapping will be done for the input strings:
%# @itemize @bullet
%# @item @var{basis}:       day-count basis (scalar)
%#      @itemize @bullet
%#          @item @var{0} = actual/actual or act/act (1/1 mapped to act/act)
%#          @item @var{1} = 30/360 SIA
%#          @item @var{2} = act/360 or actual/360 or actual/360 Full
%#          @item @var{3} = act/365 or actual/365 or actual/365 Full
%#          @item @var{4} = 30/360 PSA
%#          @item @var{5} = 30/360 ISDA
%#          @item @var{6} = 30/360 European
%#          @item @var{7} = act/365 Japanese
%#          @item @var{8} = act/act ISMA
%#          @item @var{9} = act/360 ISMA
%#          @item @var{10} = act/365 ISMA
%#          @item @var{11} = 30/360E
%#          @item @var{13} = 30/360 or 30/360 German
%#          @item @var{14} = business/252
%#          @item @var{15} = act/364
%#      @end itemize
%# @end itemize
%# @seealso{timefactor}
%# @end deftypefn

function basis = get_basis(dcc_string)

if nargin < 1
    fprintf('get_basis: no day count convention provided. Setting to default value act/365.\n');
    basis = 3;
    return;
end

if nargin > 1
    fprintf('get_basis: ignoring further argument(s).\n');
end
if ~(ischar(dcc_string))
    fprintf('get_basis: day count convention not a string >>%s<<. Setting to default value act/365.\n',num2str(dcc_string));
    basis = 3;
    return;
end

% dictionary with all day count conventions and their mapping to the basis:

dcc = struct(   ...
                'ACT/ACT',0, ...
                '30/360 SIA',1, ...
                'ACT/360',2, ...
                'ACTUAL/360',2, ...
                'ACTUAL/360 FULL',2, ...
                'ACT/360 FULL',2, ...
                'ACT/365',3, ...
                'ACTUAL/365',3, ...
                'ACTUAL/365 FULL',3, ...
                'ACT/365 FULL',3, ...
                'ACTUAL/365 CANADIAN',3, ...
                'ACT/365 CANADIAN',3, ...
                '30/360 PSA',4, ...
                '30/360 ISDA',5, ...
                '30/360 EUROPEAN',6, ...
                'ACT/365 JAPANESE',7, ...
                'ACT/ACT ISMA',8, ...
                'ACT/360 ISMA',9, ...
                'ACT/365 ISMA',10, ...
                '30/360E',11, ...
                'ACTUAL/ACTUAL',0, ...
                '30/360 ISMA',1, ...
                '30/360',13, ...
                '30/360 GERMAN',13, ...
                'BUSINESS/252',14, ...
                'BUSINESS/BUSINESS',14, ...
                'BUS/252',14, ...
                'BUS/BUS',14, ...
                'ACT/364',15, ...
                'ACTUAL/364',15, ...
                '1/1', 0 ...
            );
                       
if ~(isfield(dcc,upper(dcc_string)))
    fprintf('get_basis: no valid day count convention >>%s<< provided. Setting to default value act/365.\n',dcc_string);
    basis = 3;
    return;
end                       
% map the string to the number 1:length(dcc_cell):
basis = getfield(dcc,upper(dcc_string));
end 

%!assert(get_basis('act/act'),0)
%!assert(get_basis('Act/act'),0)
%!assert(get_basis('ACT/act'),0)
%!assert(get_basis('ACT/ACT'),0)
%!assert(get_basis('30/360 SIA'),1)
%!assert(get_basis('act/360'),2)
%!assert(get_basis('act/365'),3)
%!assert(get_basis('actual/365 Full'),3)
%!assert(get_basis('act/365 Canadian'),3)
%!assert(get_basis('actual/365 Canadian'),3)
%!assert(get_basis('30/360 PSA'),4)
%!assert(get_basis('30/360 ISDA'),5)
%!assert(get_basis('30/360 European'),6)
%!assert(get_basis('act/365 Japanese' ),7)
%!assert(get_basis('Act/act ISMA'),8)
%!assert(get_basis('act/360 ISMA'),9)
%!assert(get_basis('act/365 ISMA'),10)
%!assert(get_basis('30/360E'),11)
%!assert(get_basis('30/360 German'),13)
%!assert(get_basis('30/360'),13)
%!assert(get_basis('30/360 ISMA'),1)
%!assert(get_basis('bus/252'),14)
%!assert(get_basis('act/364'),15)
%!assert(get_basis('dummy'),3)
%!assert(get_basis(),3)
%!assert(get_basis(888),3)
%!assert(get_basis('act/act','act/365'),0)

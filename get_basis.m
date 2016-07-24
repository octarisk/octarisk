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
%# 			@item @var{11} = 30/360E
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

if ~(ischar(dcc_string))
    fprintf('get_basis: no day count convention provided. Setting to default value act/365.\n');
    basis = 3;
    return;
end
% hard coded cell with all day count convention strings:
dcc_cell = {'act/act' '30/360 SIA' 'act/360' 'act/365' ...
                        '30/360 PSA' '30/360 ISDA' '30/360 European' ...
                        'act/365 Japanese' 'act/act ISMA' 'act/360 ISMA' ...
                        'act/365 ISMA' '30/360E'};
if ~(any(strcmp(dcc_string,dcc_cell)))
    fprintf('get_basis: no valid day count convention >>%s<< provided. Setting to default value act/365.\n',dcc_string);
    basis = 3;
    return;
end                       
% map the string to the number 1:length(dcc_cell):
findvec = strcmp(dcc_string,dcc_cell);
tt = 1:1:length(dcc_cell);
tt = (tt - 1)';
basis = dot(double(findvec),tt);

end 

%!assert(get_basis('act/act'),0)
%!assert(get_basis('30/360 SIA'),1)
%!assert(get_basis('act/360'),2)
%!assert(get_basis('act/365'),3)
%!assert(get_basis('30/360 PSA'),4)
%!assert(get_basis('30/360 ISDA'),5)
%!assert(get_basis('30/360 European'),6)
%!assert(get_basis('act/365 Japanese' ),7)
%!assert(get_basis('act/act ISMA'),8)
%!assert(get_basis('act/360 ISMA'),9)
%!assert(get_basis('act/365 ISMA'),10)
%!assert(get_basis('30/360E'),11)
%!assert(get_basis('dummy'),3)
%!assert(get_basis(),3)
%!assert(get_basis(888),3)
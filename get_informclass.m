%# Copyright (C) 2019 Stefan Schlögl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{class} ] =} get_informclass(@var{score})
%#
%# Map the INFORM score to risk class very low ... very high.
%# See http://www.inform-index.org/ for further information.
%# 
%# @end deftypefn

function class = get_informclass(score)

if nargin < 1
    error('get_informclass: no score provided.\n');
end

if nargin > 1
    fprintf('get_informclass: ignoring further argument(s).\n');
end
if ~(isnumeric(score))
    error('get_informclass: score not numeric >>%s<<..\n',any2str(score));
end
if isnan(score)
	class = 'n/a';
else
	if ( score < 0)
		error('get_informclass: not a valid score 0 < score <= 10: >>%s<<.\n',any2str(score));
	elseif (score <= 1.9)
		class = 'very low';
	elseif (score <= 3.4)
		class = 'low';
	elseif (score <= 4.9)
		class = 'medium';
	elseif (score <= 6.4)
		class = 'high';
	elseif (score <= 10)
		class = 'very high';
	else
		error('get_informclass: not a valid score  0 < score <= 10: >>%s<<.\n',any2str(score));
	end
end
end 
%!assert(get_informclass(2.1),'low')
%!error(get_informclass(11))
%!error(get_informclass(-2))
%!error(get_informclass('DE'))
%!assert(get_informclass(1),'very low')
%!assert(get_informclass(4.8),'medium')
%!assert(get_informclass(6.4),'high')
%!assert(get_informclass(9),'very high')

%~ CLASSES THRESHOLDS IN INFORM
%~ Dimension
%~ CLASS MAX MIN RISK
%~ very high 10 6.5
%~ high	6.4	5.0
%~ medium	4.9	3.5
%~ low	3.4	2.0
%~ very low	1.9	0.0


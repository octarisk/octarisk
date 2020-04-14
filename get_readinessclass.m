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
%# @deftypefn {Function File} {[@var{class} ] =} get_readinessclass(@var{score})
%#
%# Map the ND-GAIN readiness score to risk class very low ... very high.
%# 
%# @end deftypefn

function class = get_readinessclass(score)

if nargin < 1
    error('get_readinessclass: no score provided.\n');
end

if nargin > 1
    fprintf('get_readinessclass: ignoring further argument(s).\n');
end
if ~(isnumeric(score))
    error('get_readinessclass: score not numeric >>%s<<..\n',any2str(score));
end

if isnan(score)
	class = 'n/a';
else
	if ( score < 0)
		error('get_readinessclass: not a valid score 0 < score <= 1: >>%s<<.\n',any2str(score));
	elseif (score <= 0.2)
		class = 'very high';
	elseif (score <= 0.4)
		class = 'high';
	elseif (score <= 0.6)
		class = 'medium';
	elseif (score <= 0.8)
		class = 'low';
	elseif (score <= 1)
		class = 'very low';
	else
		error('get_readinessclass: not a valid score  0 < score <= 1: >>%s<<.\n',any2str(score));
	end
end
end 

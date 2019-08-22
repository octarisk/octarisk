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
%# @deftypefn {Function File} {[@var{rating} ] =} get_esg_rating(@var{score})
%#
%# Map the MSCI ESG score to rating class.
%# See https://www.msci.com/esg-ratings for further information.
%# 
%# @end deftypefn

function rating = get_esg_rating(score)

if nargin < 1
    error('get_esg_rating: no score provided.\n');
end

if nargin > 1
    fprintf('get_esg_rating: ignoring further argument(s).\n');
end
if ~(isnumeric(score))
    error('get_esg_rating: score not numeric >>%s<<..\n',any2str(score));
end

if ( score < 0)
	error('get_esg_rating: not a valid score 0 < score <= 10: >>%s<<.\n',any2str(score));
elseif (score < 10/7)
	rating = 'CCC';
elseif (score < 20/7)
	rating = 'B';
elseif (score < 30/7)
	rating = 'BB';
elseif (score < 40/7)
	rating = 'BBB';
elseif (score < 50/7)
	rating = 'A';
elseif (score < 60/7)
	rating = 'AA';
elseif (score <= 70/7)
	rating = 'AAA';
else
	error('get_esg_rating: not a valid score  0 < score <= 10: >>%s<<.\n',any2str(score));
end

end 
%!assert(get_esg_rating(9.9),'AAA')
%!error(get_esg_rating(11))
%!error(get_esg_rating(-2))
%!error(get_esg_rating('DE'))
%!assert(get_esg_rating(3),'BB')
%!assert(get_esg_rating(7.2),'AA')
%!assert(get_esg_rating(6.4),'A')
%!assert(get_esg_rating(60/7),'AAA')

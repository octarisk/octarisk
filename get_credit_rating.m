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
%# @deftypefn {Function File} {[@var{rating} ] =} get_credit_rating(@var{entity})
%#
%# Map the entity id to credit rating (AAA-D). Input from various sources. 
%# @end deftypefn

function rating = get_credit_rating(entity)

if nargin < 1
    error('get_credit_rating: no entity id provided.\n');
end

if nargin > 1
    fprintf('get_credit_rating: ignoring further argument(s).\n');
end
if ~(ischar(entity))
    error('get_credit_rating: entity id not a string >>%s<<..\n',any2str(entity));
end


% last update 20190904
credit = struct(   ...
                'commerzbank','BBB', ...
                'comdirect','BBB', ...
                'barclays','A', ...
                'bnp paribas','A', ...
                'dkb','A', ...
                'ubs','A', ...
                'societe general','A', ...
                'blackrock','AA', ...
                'allianz','AA', ...
                'usa','AA', ...
                'us','AA', ...
                'state street','AAA', ...
                'debeka','BBB', ...
                'ireland','A', ...
                'luxemburg','AAA', ...
                'germany','AAA', ...
                'deutsche rentenversicherung','AAA', ...
				'deutsche bank','BBB' ...
            );
                       
if (isfield(credit,lower(entity)))
	rating = getfield(credit,lower(entity));
else
    rating = 'NR';
end                       

end 


%!assert(get_credit_rating('Germany'),'AAA')
%!assert(get_credit_rating('Commerzbank'),'BBB')

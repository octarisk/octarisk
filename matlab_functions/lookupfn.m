%# Copyright (C) 2000 Paul Kienzle
%#
%# This program is free software; you can redistribute it and/or modify
%# it under the terms of the GNU General Public License as published by
%# the Free Software Foundation; either version 2 of the License, or
%# (at your option) any later version.
%#
%# This program is distributed in the hope that it will be useful,
%# but WITHOUT ANY WARRANTY; without even the implied warranty of
%# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%# GNU General Public License for more details.
%#
%# You should have received a copy of the GNU General Public License
%# along with this program; if not, write to the Free Software
%# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

%# usage: idx = lookupfn(table, y)
%#
%# Lookup values in a sorted table.  Usually used as a prelude to
%# interpolation.
%#
%# If table is strictly increasing and idx=lookupfn(table, y), then
%#    table(idx(i)) <= y(i) < table(idx(i+1))
%# for all y(i) within the table.  If y(i) is before the table, then
%# idx(i) is 0. If y(i) is after the table then idx(i) is table(n).
%# If the table is strictly decreasing, then the tests are reversed.
%# No guarantees for tables which are non-monotonic or are not strictly
%# monotonic.
%#
%# To get an index value which lies within an interval of the table
%# use:
%#      idx = lookupfn(table(2:length(table)-1), y) - 1
%# This puts values before the table into the first interval, and values
%# after the table into the last interval.

function idx=lookupfn(table,xi)
if isempty (table)
idx = zeros(size(xi));
elseif isvector(table)
[nr, nc] = size(xi);
lt=length(table);
if ( table(1) > table(lt) )
%# decreasing table
[v, p] = sort ([xi(:) ; table(:)]);
idx (p) = cumsum (p > nr*nc);
idx = lt - idx (1 : nr*nc);
else
%# increasing table
[v, p] = sort ([table(:) ; xi(:) ]);
idx (p) = cumsum (p <= lt);
idx = idx (lt+1 : lt+nr*nc);
end
idx = reshape (idx, nr, nc);
else
error ('lookup: table must be a vector');
end
end


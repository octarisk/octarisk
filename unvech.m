%# Copyright (C) 2006  Michael Creel <michael.creel@uab.es>
%# Copyright (C) 2009  Jaroslav Hajek <highegg@gmail.com>
%# Copyright (c) 2011 Juan Pablo Carbajal <carbajal@ifi.uzh.ch>
%# Copyright (c) 2011 Carnë Draug <carandraug+dev@gmail.com>
%#
%# This program is free software; you can redistribute it and/or modify
%# it under the terms of the GNU General Public License as published by
%# the Free Software Foundation; either version 3 of the License, or
%# (at your option) any later version.
%#
%# This program is distributed in the hope that it will be useful,
%# but WITHOUT ANY WARRANTY; without even the implied warranty of
%# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%# GNU General Public License for more details.
%#
%# You should have received a copy of the GNU General Public License
%# along with this program; If not, see <http://www.gnu.org/licenses/>.

%# -*- texinfo -*-
%# @deftypefn {Function File} {@var{m} =} unvech (@var{v}, @var{scale})
%# Performs the reverse of @code{vech} on the vector @var{v}.
%#
%# Given a Nx1 array @var{v} describing the lower triangular part of a
%# matrix (as obtained from @code{vech}), it returns the full matrix.
%#
%# The upper triangular part of the matrix will be multiplied by @var{scale} such
%# that 1 and -1 can be used for symmetric and antisymmetric matrix respectively.
%# @var{scale} must be a scalar and defaults to 1.
%#
%# @seealso{vech, ind2sub, sub2ind_tril}
%# @end deftypefn

function M = unvech (v, scale = 1)

  if ( nargin < 1 || nargin > 2 )
    print_usage;
  elseif ( ~ismatrix (v) && any (size (v) ~= 1) )
    error ('V must be a row orcolumn matrix')
  elseif ( ~isnumeric (scale) || ~isscalar (scale) )
    error ('SCALE must be a scalar')
  end

  N      = length (v);
  dim    = (sqrt ( 1 + 8*N ) - 1)/2;
  [r, c] = ind2sub_tril (dim, 1:N);
  M      = accumarray ([r; c].', v);
  M     += scale * tril (M, -1).';

end


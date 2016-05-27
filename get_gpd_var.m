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

%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{VAR} @var{ES}] =} get_gpd_var(@var{chi}, @var{sigma}, @var{u}, @var{q}, @var{n}, @var{nu})
%# Return Value-at-risk (VAR) and expected shortfall (ES) according to a generalized Pareto distribution.
%# @*
%# Implementation according to @i{Risk Management and Financial Institutions} by John C. Hull, 4th edition, Wiley 2015, 
%#  section 13.6, page 292ff.
%# @*
%# Input and output variables:
%# @itemize @bullet
%#  @item @var{chi}: 	GPD shape parameter one (float)
%#  @item @var{sigma}: 	GPD shape parameter two (float)
%#  @item @var{u}:      offset level (float)
%#  @item @var{q}:      quantile (float in [0:1])
%#  @item @var{n}:      Number of scenarios in total distribution (integer)
%#  @item @var{nu}:     number of tail scenarios (in doubt set to 0.025 * n) (integer)
%#  @item @var{VAR}: 	OUTPUT: Value-at-Risk according to the GPD
%#  @item @var{ES}:     OUTPUT: Expected shortfall according to the GPD
%# @end itemize
%# Example call for calculation of VAR and ES for several confidence levels: 
%#  @example
%#      [VAR ES] = get_gpd_var(0.00001,1632.9,5930.8,[0.99;0.995;0.999],50000,1250)
%#  @end example
%# @end deftypefn

function [VAR ES] = get_gpd_var(chi, sigma, u, q, n, nu) 
    % Input checks
    if nargin < 6
       error('Not enough input parameter provided')
    end
    % Calculate VAR and ES
    VAR = u + sigma./chi.*(( n./nu .*( 1- q ) ).^(-chi) -1);
    ES = (VAR + sigma - chi .* u) ./ ( 1 - chi );
end

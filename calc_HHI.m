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
%# @deftypefn {Function File} {[@var{HHI} @var{concentration} ] =} calc_HHI(@var{exposure})
%#
%# Calculate the normalized Herfindahl-Hirschmann Index and classify
%# the concentration risk according to US DoJ & FTC classification (see
%# https://www.justice.gov/atr/herfindahl-hirschman-index).
%#
%# @seealso{timefactor}
%# @end deftypefn

function [HHI_norm concentration] = calc_HHI(exposure)

if ~isnumeric(exposure)
	error('get_HHI: exposure input has to be numeric');
end

HHI_norm = sum((100.*exposure).^2) / (sum(exposure)^2);

if isnan(HHI_norm)
	HHI_norm = 0;
end

if HHI_norm < 100
	concentration = "very low";
elseif HHI_norm < 1500
	concentration = "low";
elseif HHI_norm < 2500
	concentration = "mid";
elseif HHI_norm < 6400
	concentration = "high";
else
	concentration = "very high";
end

end 

%!assert(calc_HHI([1,0]),10000)
%!assert(calc_HHI(1),10000)
%!assert(calc_HHI(0.6),10000)
%!assert(calc_HHI([3 4 NaN 6]),0)
%!assert(calc_HHI([0.8,0.10,0.10]),6600)

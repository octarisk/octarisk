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
%# @deftypefn {Function File} {[@var{fx_rate} ] =} get_FX_rate(@var{index_struct},@var{curA},@var{curB},@var{scen_set})
%#
%#
%# Return the FX rate for a given pair of currencies and scenario set.
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{fx_rate}: FX rate (either scalar or vector) [output] 
%# @item @var{index_struct}: structure containing FX index objects [required] 
%# @item @var{curA}: base currency [required] 
%# @item @var{curB}: foreign currency [required] 
%# @item @var{scen_set}: scenario set (e.g. base, stress or 250d) [required] 
%# @end itemize
%# @seealso{timefactor}
%# @end deftypefn

function fx_rate = get_FX_rate(index_struct,curA,curB,scen_set);
	if ( strcmpi(curA,curB) == 1 )
		fx_rate = 1.0;
	else
		fx_index = strcat('FX_', curA, curB);
		[fx_struct_obj object_ret_code]  = get_sub_object(index_struct, fx_index);
		if ( object_ret_code == 0 )
			error('WARNING: No index_struct object found for FX id >>%s<<\n',fx_index);
		end 
		fx_rate = fx_struct_obj.getValue(scen_set);     
	end
end

%!shared index, fx
%! index = struct();
%! fx = Index();
%! fx = fx.set('id','FX_EURUSD','value_base',1.111);
%! index(1).object = fx;
%! index(1).id = fx.id;
%!test
%! fx_rate = get_FX_rate(index,'EUR','USD','base');
%! assert(fx_rate,1.111,sqrt(eps));
%! fx_rate = get_FX_rate(index,'EUR','USD','stress');
%! assert(fx_rate,1.111,sqrt(eps))
%! fx_rate = get_FX_rate(index,'EUR','EUR','base');
%! assert(fx_rate,1.0,sqrt(eps));
%!error(get_FX_rate(index,'EUR','KRW','base'))

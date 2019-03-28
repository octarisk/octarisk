%# Copyright (C) 2019 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {} solvency2_reporting (@var{path_working_folder})
%#
%# Solvency 2 reporting for assets according to the Tripartite v4.0 standard.
%# Analytics section (Outputs 90-94) and SCR contribution sections 
%# (Output 97-105) are calculated and accordingly filled.
%#
%# Further fields with mandatory / conditional information can be set in
%# asset input in positions.csv (see example files in 
%# /octarisk/sii_stdmodel_folder/input)
%#
%# SII SCR stress definitions can be adjusted under 
%# /octarisk/sii_stdmodel_folder/input/stresstests.csv
%#
%# See www.octarisk.com for further information.
%#
%# @end deftypefn

function solvency2_reporting(path_working_folder)

% call calculation modulewith settings from path_working_folder/parameter.csv:
[instrument_struct, curve_struct, index_struct, surface_struct, para_object, matrix_struct, riskfactor_struct, ...
portfolio_struct, stresstest_struct, mc_var_shock_pct, port_obj_struct] = octarisk(path_working_folder);

% aggregate and print SII Tripartite reports for all portfolios
for ( ii=1:1:length(port_obj_struct))
    if (isobject(port_obj_struct(ii).object))
		portobj = port_obj_struct(ii).object;
		% aggregate for base and SII SCR stress scenarios
		portobj = portobj.aggregate('base', instrument_struct, index_struct, para_object);
		portobj = portobj.aggregate('stress', instrument_struct, index_struct, para_object);
		% print Portfolioobject to stdout
		portobj
		% print Tripartite reports
		portobj.print_report(para_object);
	end
end

end

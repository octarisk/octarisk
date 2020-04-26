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
%# @deftypefn {Function File} {@var{m} =} get_srri_level (@var{vola}, @var{horizon}, @var{quantile})
%# Calculate current SRRI level per given vola, time horizon and quantile.
%#
%# @seealso{}
%# @end deftypefn
function [srri vola_limit] = get_srri_level(vola,horizon,quantile)
% SRRI is specified on 250day horizon for standard deviation = 1
% vola = 0.15855 --> norminv(vola) = 1
	if ~(nargin == 3)
		error('Invalid nargin');
	end
	if ( vola < 0)
		error('Negative volatility not allowed');
	end
	srri = 1;
	levels =  [1,2,3,4,5,6,7];
	vola_limit = [0,0.005,0.02,0.05,0.1,0.15,0.25];

	% scale vola_limit
	days_in_year = 250;
	time_scale = sqrt(horizon)/sqrt(days_in_year);
	quantile_scale = abs(norminv(quantile));

	vola_limit = vola_limit .* time_scale.* quantile_scale;

	for ii=1:1:length(vola_limit)
		if vola >= vola_limit(ii)
			srri = levels(ii);
		else
			return;
		end
	end

end

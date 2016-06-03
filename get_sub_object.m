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
%# @deftypefn {Function File} {[@var{match_obj} @var{ret_code}] =} get_sub_object(@var{input_struct}, @var{input_id})
%# Return the objectcontained in a structure  matching a given ID. Return code 1 (success) and 0 (fail).
%# @end deftypefn

% function for extracting sub-structure object from struct object according to id
function  [match_obj ret_code] = get_sub_object(input_struct, input_id)
 	matches = 0;	
	a = {input_struct.id};
	b = 1:1:length(a);
	c = strcmp(a, input_id);	
    % correct for multiple matches:
    if ( sum(c) > 1 )
        summe = 0;
        for ii=1:1:length(c)
            if ( c(ii) == 1)
                match_struct = input_struct(ii);
                ii;
                return;
            end            
            summe = summe + 1;
        end       
    end
    matches = b * c';
	if (matches > 0)
	    	match_obj = input_struct(matches).object;
	    	ret_code = 1;
		return;
	else
	    %fprintf('octarisk::get_sub_object: WARNING: No object found for input_id: >>%s<<\n',input_id);
	    match_obj = '';
	    ret_code = 0;
		return;
	end
end
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
%# @deftypefn {Function File} {[@var{match_struct} @var{ret_code}] =} get_sub_object(@var{input_struct}, @var{input_id})
%# Return the sub-structure contained in a structure matching a given ID. 
%# Return code 1 (success) and 0 (fail).
%# @end deftypefn

% III) %#%#%%#         HELPER FUNCTIONS              %#%#
% function for extracting sub-structure from struct object according to id
function  [match_struct ret_code matches] = get_sub_struct(input_struct, input_id)
 	matches = 0;	
	ret_code = 0;
	% check whether input struct is not empty
    if ~( isfield(input_struct,'id'))
        match_struct = '';
	    ret_code = 0;
		return;
    end
	a = {input_struct.id};
	b = 1:1:length(a);
	c = strcmpi(a, input_id);	
    % correct for multiple matches:
    if ( sum(c) > 1 )
        summe = 0;
        for ii=1:1:length(c)
            if ( c(ii) == 1)
                match_struct = input_struct(ii);
                ii;
				ret_code = 1;
                return;
            end            
            summe = summe + 1;
        end       
    end
    matches = b * c';
	if (matches > 0)
	    	match_struct = input_struct(matches);
			ret_code = 1;
		return;
	else
	    %fprintf('octarisk::get_sub_struct: WARNING: No struct found for input_id: >>%s<<\n',input_id);
		match_struct = '';
	    ret_code = 0;
		return;
	end
end


%!shared s,r
%! s = struct();
%! s(1).id = 'bla';
%! s(1).shock = [1,2,3];
%! s(2).id = 'blup';
%! s(2).shock = [1,2,3];
%! r = struct();
%! r.id = 'bla';
%! r.shock = [1,2,3];
%!test
%! [retstruct retcode] = get_sub_struct(s,'bla');
%! assert(isequal(retstruct,r),true);
%! assert(retcode,1);
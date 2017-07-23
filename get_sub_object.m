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
%# Return the object contained in a structure  matching a given ID. 
%# Return code 1 (success) and 0 (fail).
%# @end deftypefn

% function for extracting sub-structure object from struct object according to id
function  [match_obj ret_code matches] = get_sub_object(input_struct, input_id)	
    matches = 0;
    % check whether input struct is not empty
    if ~( isfield(input_struct,'id'))
        match_obj = '';
	    ret_code = 0;
		return;
    end
	a = {input_struct.id};
	b = 1:1:length(a);
	c = strcmpi(a, input_id);	
    % correct for multiple matches:
    if ( sum(c) > 1 )
        sprintf('WARNING: %d ids matching in struct. Returning first object.\n',sum(c));
        summe = 0;
        for ii=1:1:length(c)
            if ( c(ii) == 1)
                % return object if possible
                if ( isfield(input_struct(ii),'object'))
                    match_obj = input_struct(ii).object;      
                    ret_code = 1;
                    return;
                else
                    match_obj = '';
                    ret_code = 0;
                    return;
                end
            end            
            summe = summe + 1;
        end       
    end
    matches = b * c';
	if (matches > 0)
        % return object if possible
        if ( isfield(input_struct(matches),'object'))
	    	match_obj = input_struct(matches).object;
	    	ret_code = 1;
            return;
        else
            match_obj = '';
	    	ret_code = 0;
            return;
        end
	else
	    %fprintf('octarisk::get_sub_object: WARNING: No object found for input_id: >>%s<<\n',input_id);
	    match_obj = '';
	    ret_code = 0;
		return;
	end
end


%!shared s,r,c
%! s = struct();
%! r = struct();
%! r.id = 'R-TEST';
%! r.aa = 'aa';
%! r.bb = 3;
%! c = struct();
%! c.id = 'C-TEST';
%! c.cc = 'bb';
%! c.dd = 55;
%! s(1).object = r;
%! s(1).id = r.id;
%! s(2).object = c;
%! s(2).id = c.id;
%!test
%! [retobj retcode] = get_sub_object(s,'C-TEST');
%! assert(isequal(retobj,c),true);
%! assert(retcode,1);
%!test
%! s(3).object = c;
%! s(3).id = c.id;
%! [retobj retcode] = get_sub_object(s,'C-TEST');
%! assert(isequal(retobj,c),true);
%! assert(retcode,1);
%!test
%! p = struct();
%! [retobj retcode] = get_sub_object(p,'AAA');
%! assert(retcode,0);
%!test
%! k = struct();
%! k.id = 'AAA';
%! [retobj retcode] = get_sub_object(k,'AAA');
%! assert(retcode,0);

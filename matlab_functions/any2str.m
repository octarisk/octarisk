%# Copyright (C) 2016 Stefan Schloegl <schinzilord@octarisk.com>
%# Copyright (C) 2016 IRRer-Zins <IRRer-Zins@t-online.de>
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
%# @deftypefn {Function File} { [@var{output} @var{type}] =} any2str(@var{value})
%# Convert input value into string. Therefore a type dependent conversion is
%# performed. One output string ( a one-liner!) and the input type is returned.
%# Conversion is supported for scalars, matrizes up to three dimensions, cells,
%# boolean values and structs.
%# @end deftypefn

function [output] = any2str(value)
if nargin > 1
    fprintf('WARNING: Only one argument is allowed.\n');
end

% get type of input value
type=whos('value');
type=type.class;

% convert input value depending on value type
if ( any(strcmp(type,{'single','double'})))
    if isscalar (value)==1
        if isfloat(value)       % single or double, real or complex
            output = num2str(value);
        elseif isinteger(value) % integer
            output = int2str(value);
        end
    else
        % check for 2 dimensions
        [aa bb cc] = size(value);
        if (cc == 1)
            output = mat2str(value);
        else
            % matrix is three-dimensional
            output = '';
            for ii = 1 : 1 : cc
                output = strcat(output,',',mat2str(value(:,:,ii)));
            end
            output = output(2:end);
        end
    end
elseif ( any(strcmp(type,{'string','char'})))
    output = value;
elseif ( regexp(type,'cell'))
    if isempty(value)
        output = '{}';
    else
        output = '{';
        for ii = 1:1:length(value)
            output = strcat(output,';',any2str(value{ii}));
        end
        output = output(3:end);
        output = strcat('{',output,'}');
    end
elseif ( regexp(type,'logical'))
    if value == true
        output = 'true';
    else
        output = 'false';
    end
elseif ( strcmp(type,'struct'))
    tmp_fields = fieldnames(value);
    output = '';
    if size(value,2)==1
        for jj = 1:1:length(tmp_fields)
            output = strcat(output,' |',tmp_fields{jj},'->',any2str(getfield(value,tmp_fields{jj})));
        end
        output = output(3:end);
    else
        output = '';
        for jj = 1:1:length(value)
            output = strcat(output,' (',int2str(jj),')',any2str(value(jj)));
        end
        output = output(2:end);
    end
else
    fprintf('WARNING: Unknown type: >>%s<<. It was not possible to convert value into string. Return input value.\n',type);
    output = value;
end

end % endfunction

%!assert(any2str(2048),'2048')
%!assert(any2str(23.23400),'23.234')
%!assert(any2str(23.234),'23.234')
%!assert(any2str(3.02300+4i),'3.023+4i')
%!assert(any2str(false),'false')
%!assert(any2str(true),'true')
%!assert(any2str('true'),'true')
%!assert(any2str(1),'1')
%!assert(any2str(-3),'-3')
%!assert(any2str([1,2;3,4]),'[1 2;3 4]')
%!assert(any2str([1,2]),'[1 2]')
%!assert(any2str([1;2]),'[1;2]')
%!assert(any2str(cat(3,[1,2;3,4],[5,6;7,8])),'[1 2;3 4],[5 6;7 8]')
%!assert(any2str({'250d'}),'{250d}')
%!assert(any2str({'1d','250d'}),'{1d;250d}')
%!assert(any2str({'1d','250d',34.45,3}),'{1d;250d;34.45;3}')
%!assert(any2str({[1,2;3,4],'250d',{'1D','2S',23.34},[1;2;3;4;5]}),'{[1 2;3 4];250d;{1D;2S;23.34};[1;2;3;4;5]}')
%!assert(any2str(struct('id','ABC','value',123.34)),'id->ABC |value->123.34')
%!test
%! s = struct();
%! s(1).id = 'ABC';
%! s(1).value = 0.0;
%! s(2).id = 'ABC';
%! s(2).value = [1,2;3,4];
%! s(2).date = datenum('31-Dec-2015');
%! assert(any2str(s),'(1)id->ABC |value->0 |date->[] (2)id->ABC |value->[1 2;3 4] |date->736329')

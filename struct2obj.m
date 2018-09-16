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
%# @deftypefn {Function File} {[@var{obj}] =} struct2obj(@var{s},@var{verbose})
%# Converting structs into objects. Therefore the constructors of hard-coded 
%# classes are used to invoke objects and to set all structures attributes. 
%# The final object @var{obj} is returned. The optional @var{verbose} parameter 
%# sets the logging level.
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{s}: input struct containing field type and class specific fields
%# @item @var{verbose}: flag for providing additional information 
%# about conversion (default: false)
%# @item @var{obj}: OUTPUT: objects
%# @end itemize
%# @end deftypefn

function obj = struct2obj(s,verbose)

if nargin == 1
    verbose = 0;
end
if ~(isstruct(s))
    error('Provided input type is not a struct. Exiting.');
end

% cellarray of fieldnames
fields = fieldnames(s);

% construct object according to fieldname 'type'
if ~(isfield(s,'type'))
    error('Provided input struct has no type field. Exiting.');
end

object_class = lower(getfield(s,'type'));
switch object_class
case 'option'
    obj = Option();
case 'bond'
    obj = Bond();
case 'instrument'
    obj = Instrument();
case 'curve'
    obj = Curve();
case 'riskfactor'
    obj = Riskfactor();
case 'forward'
    obj = Forward();
case 'index'
    obj = Index();
case 'cash'
    obj = Cash();
case 'capfloor'
    obj = CapFloor();    
case 'debt'
    obj = Debt();
case 'surface'
    obj = Surface();
case 'sensitivity'
    obj = Sensitivity();
case 'synthetic'
    obj = Synthetic();
case 'swaption'
    obj = Swaption();
case 'discount curve'
    obj = Curve();
case 'spread curve'
    obj = Curve();
case 'cpi'
    obj = Index();
case 'irvol'
    obj = Surface();
case 'indexvol'
    obj = Surface();
case 'parameter'
    obj = Parameter();
otherwise
    fprintf('No constructor found for class >>%s<<. Returning struct.\n',object_class);
    obj = s;
    return;
end

% iterate through fieldnames and set object attributes
for ii = 1 : 1 : length(fields)
    tmp_field = fields{ii};
    tmp_value = getfield(s,tmp_field);
    value_string = any2str(tmp_value);
    % convert integer into datenum if field is date
    if ( regexpi(tmp_field,'date')) 
        try
            if ~ischar(value_string)
                tmp_value = datestr(str2num(value_string));
                value_string = char(datestr(str2num(value_string)));
            end
        end
    end
    if (verbose == 1)
        fprintf('Storing Field >>%s<< | Value: >>%s<<\n',tmp_field,value_string);
    end
    % set attribute in object property
    if obj.isProp(tmp_field)         % field is property of class
        try % really try to set value. If attribute cannot be set (e.g. empty)
            % an error is thrown and the next attribute will be set.
            obj = obj.set(tmp_field,tmp_value);
        catch
            if (verbose == 1)
                fprintf('WARNING: %s\n',lasterr);
            end
        end
    else
        if (verbose == 1)
            fprintf('WARNING: field is not an attribute of class\n');
        end
    end
end

end



%!test
%! warning('off', 'Octave:classdef-to-struct');
%! o = Option();
%! o = o.set('name','TEST Barrier','id','ERO938');
%! o = o.set('maturity_date','30-Sep-2016','sub_Type','OPT_BAR_C');
%! o = o.set('strike',90,'multiplier',1,'div_yield',0.04,'upordown','D','outorin','in');
%! o = o.set('barrierlevel',95,'rebate',3);
%! o = o.set('timestep_mc',{'1d'},'value_mc',[223;334;223;135;126]);
%! o = o.set('timestep_mc',{'250d'},'value_mc',[23;34;23;15;16]);
%! s = struct(o);
%! obj = struct2obj(s,0);
%! assert(isequal(obj,o),true);


%!test
%! warning('off', 'Octave:classdef-to-struct');
%! b = Bond();
%! b = b.set('Name','Test_FRB','coupon_rate',0.035,'value_base',101.25,'coupon_generation_method','forward');
%! b = b.set('maturity_date','01-Feb-2025','notional',100,'compounding_type','simple','issue_date','01-Feb-2011');
%! s = struct(b);
%! obj = struct2obj(s,0);
%! assert(isequal(obj,b),true);
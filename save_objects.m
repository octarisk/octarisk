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
%# @deftypefn {Function File} {[@var{riskfactor_struct} @var{rf_failed_cell}] =} save_objects(@var{path_output}, @var{riskfactor_struct}, @var{instrument_struct}, @var{portfolio_struct}, @var{stresstest_struct})
%# Save provided structs for riskfactors, instruments, positions and stresstests.
%# @end deftypefn

function [save_cell] = save_objects(path_output,riskfactor_struct, ...
                            instrument_struct,portfolio_struct,stresstest_struct)

save_cell = {};
number_saves = 0;

% Save structs to file
    endung = '.mat';
try
% Saving riskfactors: loop via all objects in structs and convert
    tmp_riskfactor_struct = riskfactor_struct;
    for ii = 1 : 1 : length( tmp_riskfactor_struct )
        tmp_riskfactor_struct(ii).object = struct(tmp_riskfactor_struct(ii).object);
    end
    savename = 'tmp_riskfactor_struct';
	fullpath = [path_output, savename, endung];
	save ('-text', fullpath, savename);
    number_saves = number_saves + 1;
    save_cell{ length(save_cell) + 1 } =  'riskfactors';
 
% Saving instruments: loop via all objects in structs and convert
    tmp_instrument_struct = instrument_struct;
    for ii = 1 : 1 : length( tmp_instrument_struct )
        tmp_instrument_struct(ii).object = struct(tmp_instrument_struct(ii).object);
    end 
    savename = 'tmp_instrument_struct';
	fullpath = [path_output, savename, endung];
	save ('-text', fullpath, savename);
    number_saves = number_saves + 1;
    save_cell{ length(save_cell) + 1 } =  'instruments';
    
% save portfolio
    savename = 'portfolio_struct';
	fullpath = [path_output, savename, endung];
	save ('-text', fullpath, savename);
    number_saves = number_saves + 1;
    save_cell{ length(save_cell) + 1 } =  'portfolio';
    
% save stresstests
    savename = 'stresstest_struct';
	fullpath = [path_output, savename, endung];
	save ('-text', fullpath, savename);
    number_saves = number_saves + 1;
    save_cell{ length(save_cell) + 1 } =  'stresstests';
catch
    fprintf('WARNING: There has been an error. Aborting: >>%s<<\n',lasterr);
end

% returning statistics
fprintf('SUCCESS: Saved >>%d<< structures.\n',number_saves);


end

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
%# @deftypefn {Function File} {[@var{surface_struct} @var{vola_failed_cell}] =} load_volacubes(@var{surface_struct}, @var{path_mktdata}, @var{input_filename_vola_index}, @var{input_filename_vola_ir})
%# Load data from mktdata volatility surfaces / cubes specification files and 
%# generate a struct with parsed data. Store all stresstests in provided struct 
%# and return the final struct and a cell containing the failed volatility ids.
%# @end deftypefn

function [surface_struct vola_failed_cell] = load_volacubes(surface_struct, ...
                  path_mktdata,input_filename_vola_index,input_filename_vola_ir)

% Get list of all files in mktdata folder
tmp_list_files = dir(path_mktdata);

% Set dummy surface for VOLA_INDEX
tmp_surface_object = Surface('RF_VOLA_INDEX_DUMMY');
tmp_surface_object = tmp_surface_object.set('type','INDEX','description','Generic');                                 
tmp_surface_object = tmp_surface_object.set('axis_x_name','TERM','axis_y_name', ...
                    'MONEYNESS','axis_x',[365],'axis_y',[1],'values_base',[0.0]);
surface_struct(1).id = 'RF_VOLA_INDEX_DUMMY';
surface_struct(1).object = tmp_surface_object;
% Set dummy surface for VOLA_IR
tmp_surface_object = Surface('RF_VOLA_IR_DUMMY');
 tmp_surface_object = tmp_surface_object.set('type','IR','description','Generic'); 
tmp_surface_object = tmp_surface_object.set('axis_x_name','TENOR','axis_y_name', ...
                                'TERM','axis_z_name','MONEYNESS','axis_x',[365], ...
                                'axis_y',[365],'axis_z',[1],'values_base',[0.0]);
surface_struct(2).id = 'RF_VOLA_IR_DUMMY';
surface_struct(2).object = tmp_surface_object;
vola_failed_cell = {};
% Store marketdata in surface_struct
for ii = 1 : 1 : length(tmp_list_files)
    tmp_filename = tmp_list_files( ii ).name;
    try % try to find a match between file in mktdata folder and provided string 
      % for INDEX and IR volatilities
      % vola for index found  
        if ( regexp(tmp_filename,input_filename_vola_index) == 1)      
            tmp_len_struct = length(surface_struct);
            M = load(strcat(path_mktdata,'/',tmp_filename));
            % Get axis values and matrix: 
            % Format: 3 columns: xx yy value [moneyness term impl_vola]
            xx_structure = unique(M(:,1))';
            yy_structure = unique(M(:,2))';
            % dimensionality of matrix has to be swapped XX <-> YY
            vola_matrix = zeros(length(yy_structure),length(xx_structure));   
            % loop through all rows and store values in vola_matrix
            for ii = 1 : 1 : rows(M)
                index_xx = find(xx_structure==M(ii,1));
                index_yy = find(yy_structure==M(ii,2));
                vola_matrix(index_yy,index_xx) = M(ii,3);
            end
            % Generate object and store data
            % remove first string identifying file
            tmp_id = strrep(tmp_filename,input_filename_vola_index,''); 
            tmp_id = strrep(tmp_id,'.dat',''); % remove file ending
            tmp_surface_object = Surface(tmp_id);
            tmp_surface_object = tmp_surface_object.set('type','INDEX', ...
                                            'description','INDEX Vola Surface');     
            tmp_surface_object = tmp_surface_object.set('axis_x_name','TERM', ...
                                'axis_y_name','MONEYNESS','axis_x',xx_structure, ...
                                'axis_y',yy_structure,'values_base',vola_matrix);
            surface_struct( tmp_len_struct + 1).id = tmp_id;
            surface_struct( tmp_len_struct + 1).object = tmp_surface_object;
      % vola for ir found  
        elseif ( regexp(tmp_filename,input_filename_vola_ir) == 1)       
            tmp_len_struct = length(surface_struct);
            M = load(strcat(path_mktdata,'/',tmp_filename));
            % Get axis values and matrix: 
            % Format: 4 columns: xx yy zz value 
            % [underlying_tenor  swaption_term  moneyness  impl_cola]
            xx_structure = unique(M(:,1))';
            yy_structure = unique(M(:,2))';
            zz_structure = unique(M(:,3))';
            % dimensionality of matrix has to be swapped XX <-> YY
            vola_cube = zeros(length(xx_structure),length(yy_structure), ...
                                length(zz_structure));    
            % loop through all rows and store values in vola_cube
            for ii = 1 : 1 : rows(M)
                index_xx = find(xx_structure==M(ii,1));
                index_yy = find(yy_structure==M(ii,2));
                index_zz = find(zz_structure==M(ii,3));
                vola_cube(index_xx,index_yy,index_zz) = M(ii,4);
            end
            % Generate object and store data
            % remove first string identifying file
            tmp_id = strrep(tmp_filename,input_filename_vola_ir,''); 
            tmp_id = strrep(tmp_id,'.dat',''); % remove file ending
            tmp_surface_object =  Surface(tmp_id);
            tmp_surface_object = tmp_surface_object.set('type','IR', ...
                                            'description','IR Vola Surface'); 
            tmp_surface_object = tmp_surface_object.set('axis_x_name','TENOR', ...
                                'axis_y_name','TERM','axis_z_name','MONEYNESS', ...
                                'axis_x',xx_structure,'axis_y',yy_structure, ...
                                'axis_z',zz_structure,'values_base',vola_cube);
            surface_struct( tmp_len_struct + 1).id = tmp_id;
            surface_struct( tmp_len_struct + 1).object = tmp_surface_object;
        else    % if there is no match do nothing
            tmp_id = 'Nothing found';
        end 
    catch
        fprintf('WARNING: There has been an error for file: >>%s<<',tmp_filename);
        fprintf('and vola object id: >>%s<<. Aborting: >>%s<<\n',tmp_id,lasterr);
        vola_failed_cell{ length(vola_failed_cell) + 1 } =  tmp_filename;
    end  % end try catch
end % end of for loop of all files

end % end of function

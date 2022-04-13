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
%# @deftypefn {Function File} {[@var{success_tests} @var{total_tests}] =} test_io(@var{path_testing_folder})
%# Perform integration tests for all functions which rely on input and output 
%# data. The functions have to be hard coded in this script and rely on validated
%# output data. The storage and parsing process of objects is a little bit tricky.
%# At first, all objects have to converted into structed and stored to a file.
%# After the structs from the file have been parsed, all structe have to
%# converted back again into objects using constructor and set methods.
%# See section B.2 for an example.
%# @end deftypefn

function [success_tests,total_tests] = test_io(path_testing_folder);
if nargin == 0
    error('Please provide the path to the testing folder! Aborting.');
end
success_tests = 0;
total_tests = 0;

% Disabling warnings for converting class def objects to structs:
if ( exist('OCTAVE_VERSION') > 0 )  % variable returns 5 for Octave, 0 for Matlab
    warning('off', 'Octave:load-file-in-path');
    warning('off', 'Octave:classdef-to-struct');
end
% starting main functions
fprintf('\n');
fprintf('=== Perform integration tests on input-output functions === \n');
fprintf('\n');

% A) Set variables
    % A.1) Set variables to testing folder
    path = path_testing_folder;   % general load and save path for all input and output files

    path_output = strcat(path,'/output');
    path_output_instruments = strcat(path_output,'/instruments');
    path_output_riskfactors = strcat(path_output,'/riskfactors');
    path_output_stresstests = strcat(path_output,'/stresstests');
    path_output_positions   = strcat(path_output,'/positions');
    path_output_mktdata     = strcat(path_output,'/mktdata');
    path_reports = strcat(path,'/output/reports');
    path_archive = strcat(path,'/archive');
    path_input = strcat(path,'/input');
    path_static = strcat(path,'/static');
    path_mktdata = strcat(path,'/mktdata');
    mkdir(path_output);
    mkdir(path_output_instruments);
    mkdir(path_output_riskfactors);
    mkdir(path_output_stresstests);
    mkdir(path_output_positions);
    mkdir(path_output_mktdata);
    mkdir(path_archive);
    mkdir(path_input);
    mkdir(path_mktdata);
    mkdir(path_reports);
    mkdir(path_static);
    % A.2) Set current working directory to path
    chdir(path);
    act_pwd = strrep(pwd,'\','/');
    if ~( strcmp(path,act_pwd) )
        error('Path could not be set to working folder');
    end

    % A.3) Clean up reporting directory: delete all old files in path_output
    oldfiles = dir(path_reports);
    try
        for ii = 1 : 1 : length(oldfiles)
                tmp_file = oldfiles(ii).name;
                if ( length(tmp_file) > 3 )
                    delete(strcat(path_reports,'/',tmp_file));
                end
        end
    end    


    % % A.4) set filenames for input:
    input_filename_instruments  = 'instruments.csv';
    input_filename_corr_matrix  = 'corr.csv';
    input_filename_stresstests  = 'stresstests.csv';
    input_filename_riskfactors  = 'riskfactors.csv';
    input_filename_positions    = 'positions.csv';
    input_filename_mktdata      = 'mktdata.csv';
    input_filename_seed         = 'random_seed.dat';

    % A.5) set filenames for vola surfaces
    input_filename_vola_index = 'vol_index_';
    input_filename_vola_ir = 'vol_ir_';

    % A.6) set global parameter
    archive_flag = 0;       % switch for archiving input files to the archive
    stable_seed = 1;        % switch for using stored or drawing new random 

    % A.7) specify unique runcode and timestamp:
    runcode = 'INTEGRATION_TEST';
    timestamp = strftime ('%Y%m%d_%H%M%S', localtime (time ()));
    valuation_date = datenum('31-Dec-2015'); % valuation date
    first_eval      = 0;
    para_object = Parameter();

    % A.8) set seed of random number generator
    if ( stable_seed == 1)
        fid = fopen(strcat(path_static,'/',input_filename_seed)); % open file
        random_seed = fread(fid,Inf,'uint32');      % convert binary file into integers
        fclose(fid);                                % close file 
        rand('state',random_seed);                  % set seed
        randn('state',random_seed);
    end

% B) ####################     Perform tests     ################################

% B.1) ===   Test correlation matrix parsing   ===
total_tests_start = total_tests;
fprintf('\n### Testing function load_correlation_matrix ...\n');
try
    
    [corr_matrix riskfactor_cell] = load_correlation_matrix(path_mktdata, ...
            input_filename_corr_matrix,path_archive,timestamp,archive_flag);
    % load correct data
    filename_corr_correct               = strcat(path_mktdata,'/corr_correct.dat');
    filename_riskfactor_cell_correct    = strcat(path_mktdata,'/riskfactor_cell_correct.dat');

    corr_correct = load(filename_corr_correct);
    corr_correct = corr_correct.corr_matrix;

    riskfactor_cell_correct = load(filename_riskfactor_cell_correct);
    riskfactor_cell_correct = riskfactor_cell_correct.riskfactor_cell;

    % compare input data
    if (isequal(riskfactor_cell_correct,riskfactor_cell))
        success_tests = success_tests + 1;
        total_tests = total_tests + 1;
        fprintf('SUCCESS: load_correlation_matrix: Parsing riskfactor cell is correct.\n');
    else
        fprintf('WARNING: load_correlation_matrix: Parsing riskfactor cell not successful. Cells differ:\n');
        riskfactor_cell_correct
        riskfactor_cell
        total_tests = total_tests + 1;
    end
    
    if (corr_matrix == corr_correct)
        success_tests = success_tests + 1;
        total_tests = total_tests + 1;
        fprintf('SUCCESS: load_correlation_matrix: Parsing correlations is correct.\n');
    else
        fprintf('WARNING: load_correlation_matrix: Parsing correlations not successful. Matrizes differ:\n');
        corr_matrix
        corr_correct
        total_tests = total_tests + 1;
    end
catch
    fprintf('ERROR: load_correlation_matrix integration tests failed. Aborting: >>%s<< \n',lasterr);
    total_tests = total_tests_start + 2;
end      

% B.2) ===   Test instrument objects parsing   ===
total_tests_start = total_tests;
fprintf('\n### Testing function load_instruments ...\n');
try
    instrument_struct=struct();
    [instrument_struct id_failed_cell] = load_instruments(instrument_struct, ...
                    valuation_date,path_input,input_filename_instruments, ...
                    path_output_instruments,path_archive,timestamp,archive_flag,para_object);

    % Converting classdef objects to ordinary structure in order to compare data
    tmp_instrument_struct = instrument_struct;
    for ii = 1 : 1 : length( tmp_instrument_struct )
        tmp_instrument_struct(ii).object = struct(tmp_instrument_struct(ii).object);
    end 
    tmp_filename = strcat(path_input,'/instruments_correct.dat');
    % in case of changed objects or input data, uncomment next line to 
    % save new struct:
    %   save ('-text', tmp_filename, 'tmp_instrument_struct');
 
    % Load correct verified data from file
    instrument_struct_correct = load(tmp_filename);
    instrument_struct_correct = instrument_struct_correct.tmp_instrument_struct;
    % Compare struct data
    if (isequal(tmp_instrument_struct,instrument_struct_correct))
        success_tests = success_tests + 1;
        total_tests = total_tests + 1;
        fprintf('SUCCESS: load_instruments: Parsing of instruments is correct.\n');
    else
        % in order to see which instrument failed, make detailed comparison test of all key - value pairs
        % sometimes there is also a false positive -> catch with retcode
        % compare, if information is stored which is not contained in struct
        retcode = compare_struct(instrument_struct_correct,tmp_instrument_struct);
        % also compare other case (information contained in struct which is not stored
        %retcode2 = compare_struct(tmp_instrument_struct,instrument_struct_correct);
        %retcode = retcode + retcode2;
        if retcode > 0
            fprintf('WARNING: load_instruments: Parsing of instruments not successful. Structs differ:\n'); 
            total_tests = total_tests + 1;
        else
            fprintf('INFO: Comparison of both structs gave a false positive. Element by element comparison yielded no differences.\n');
            success_tests = success_tests + 1;
            total_tests = total_tests + 1;
            fprintf('SUCCESS: load_instruments: Parsing of instruments is correct.\n');
        end 
    end
    % convert struct data into object data and compare
    object_struct = struct();
    total_objects = length( tmp_instrument_struct );
    equal_objects = 0;
    for ii = 1 : 1 : length( tmp_instrument_struct )
        fprintf('=== Processing object >>%s<< \n',tmp_instrument_struct(ii).id);
        object_struct(ii).id     = tmp_instrument_struct(ii).id;
        object_struct(ii).name   = tmp_instrument_struct(ii).name;
        tmp_obj = struct2obj(tmp_instrument_struct(ii).object,0);
        object_struct(ii).object = tmp_obj;
        % compare new object with original object
        if (isequal(tmp_obj,instrument_struct(ii).object))
            fprintf('SUCCESS: Objects are equal.\n');
            equal_objects = equal_objects + 1;
        else
            tmp_obj
            instrument_struct(ii).object
            error('ERROR: Objects are not equal:');
        end
    end
    % compare number of equal objects
    if ( equal_objects == total_objects )
        fprintf('SUCCESS: All >>%d<< Objects are equal.\n',equal_objects);
    else
        error('ERROR: >>%d<< Objects are not equal. \n',total_objects - equal_objects);
    end
    % compare new struct with original struct
    if (isequal(object_struct,instrument_struct))
        fprintf('SUCCESS: Structs are equal.\n');
    else
        error('ERROR: Structs are not equal.');
    end
catch
    fprintf('ERROR: load_instruments integration tests failed. Aborting: >>%s<< \n',lasterr);
    total_tests = total_tests_start + 2;
end   

% B.3) ===   Test riskfactor objects parsing   ===
total_tests_start = total_tests;
fprintf('\n### Testing function load_riskfactors ...\n');
try
    riskfactor_struct=struct();
    [riskfactor_struct id_failed_cell] = load_riskfactors(riskfactor_struct, ...
                path_input,input_filename_riskfactors,path_output_riskfactors, ...
                path_archive,timestamp,archive_flag);

    % Converting classdef objects to ordinary structure in order to compare data
    tmp_riskfactor_struct = riskfactor_struct;
    for ii = 1 : 1 : length( tmp_riskfactor_struct )
        tmp_riskfactor_struct(ii).object = struct(tmp_riskfactor_struct(ii).object);
    end 
    tmp_filename = strcat(path_input,'/riskfactors_correct.dat');
    % in case of changed objects or input data, save new struct:
    %    save ('-text', tmp_filename, 'tmp_riskfactor_struct');
        
    % Load correct verified data from file
    riskfactor_struct_correct = load(tmp_filename);
    riskfactor_struct_correct = riskfactor_struct_correct.tmp_riskfactor_struct;
    % Compare data
    if (isequal(tmp_riskfactor_struct,riskfactor_struct_correct))
        success_tests = success_tests + 1;
        total_tests = total_tests + 1;
        fprintf('SUCCESS: load_riskfactors: Parsing of risk factors is correct.\n');
    else
        % in order to see which object attribute failed, make detailed comparison test of all key - value pairs
        % sometimes there is also a false positive -> catch with retcode
        % compare, if information is stored which is not contained in struct
        retcode = compare_struct(riskfactor_struct_correct,tmp_riskfactor_struct);
        % also compare other case (information contained in struct which is not stored
        %retcode2 = compare_struct(tmp_riskfactor_struct,riskfactor_struct_correct);
        %retcode = retcode + retcode2;
        if retcode > 0
            fprintf('WARNING: load_riskfactors: Parsing of risk factors not successful. Structs differ:\n');    
            total_tests = total_tests + 1;
        else
            fprintf('INFO: Comparison of both structs gave a false positive. Element by element comparison yielded no differences.\n');
            success_tests = success_tests + 1;
            total_tests = total_tests + 1;
            fprintf('SUCCESS: load_riskfactors: Parsing of risk factors is correct.\n');
        end 
    end
catch
    fprintf('ERROR: load_riskfactors integration tests failed. Aborting: >>%s<< \n',lasterr);
    total_tests = total_tests_start + 2;
end


% B.4) ===   Test positions objects parsing   ===
total_tests_start = total_tests;
fprintf('\n### Testing function load_positions ...\n');
try
    portfolio_struct=struct();
    [portfolio_struct id_failed_cell] = load_positions(portfolio_struct, ...
                path_input,input_filename_positions,path_output_positions, ...
                path_archive,timestamp,archive_flag);


    tmp_portfolio_struct = portfolio_struct;

    tmp_filename = strcat(path_input,'/positions_correct.dat');
    % in case of changed objects or input data, save new struct:
    %    save ('-text', tmp_filename, 'tmp_portfolio_struct');
        
    % Load correct verified data from file
    portfolio_struct_correct = load(tmp_filename);
    portfolio_struct_correct = portfolio_struct_correct.tmp_portfolio_struct;
    % Compare data
    if (isequal(tmp_portfolio_struct,portfolio_struct_correct))
        success_tests = success_tests + 1;
        total_tests = total_tests + 1;
        fprintf('SUCCESS: load_positions: Parsing of portfolios is correct.\n');
    else
        fprintf('WARNING: load_positions: Parsing of portfolios not successful. Structs differ:\n');    
        total_tests = total_tests + 1;
    end
catch
    fprintf('ERROR: load_positions integration tests failed. Aborting: >>%s<< \n',lasterr);
    total_tests = total_tests_start + 2;
end


% B.5) ===   Test stresstests objects parsing   ===
total_tests_start = total_tests;
fprintf('\n### Testing function load_stresstests ...\n');
try
    stresstest_struct=struct();
    [stresstest_struct id_failed_cell] = load_stresstests(stresstest_struct, ...
                    path_input,input_filename_stresstests, ...
                    path_output_stresstests,path_archive,timestamp,archive_flag);

    tmp_stresstest_struct = stresstest_struct;

    tmp_filename = strcat(path_input,'/stresstests_correct.dat');
    % in case of changed objects or input data, save new struct:
    %    save ('-text', tmp_filename, 'tmp_stresstest_struct');
        
    % Load correct verified data from file
    stresstest_struct_correct = load(tmp_filename);
    stresstest_struct_correct = stresstest_struct_correct.tmp_stresstest_struct;
    % Compare data
    if (isequal(tmp_stresstest_struct,stresstest_struct_correct))
        success_tests = success_tests + 1;
        total_tests = total_tests + 1;
        fprintf('SUCCESS: load_stresstests: Parsing of stresstests is correct.\n');
    else
        fprintf('WARNING: load_stresstests: Parsing of stresstests not successful. Structs differ:\n'); 
        total_tests = total_tests + 1;
    end
catch
    fprintf('ERROR: load_stresstests integration tests failed. Aborting: >>%s<< \n',lasterr);
    total_tests = total_tests_start + 2;
end


% B.6) ===   Test marketdata objects parsing   ===
total_tests_start = total_tests;
fprintf('\n### Testing function load_mktdata_objects ...\n');
try
    mktdata_struct=struct();
    [mktdata_struct id_failed_cell] = load_mktdata_objects(mktdata_struct, ...
                    path_mktdata,input_filename_mktdata,path_output_mktdata, ...
                    path_archive,timestamp,archive_flag,para_object);

    % Converting classdef objects to ordinary structure in order to compare data
    tmp_mktdata_struct = mktdata_struct;
    for ii = 1 : 1 : length( tmp_mktdata_struct )
        tmp_mktdata_struct(ii).object = struct(tmp_mktdata_struct(ii).object);
    end 
    tmp_filename = strcat(path_mktdata,'/mktdata_objects_correct.dat');
    % in case of changed objects or input data, save new struct:
    %   save ('-text', tmp_filename, 'tmp_mktdata_struct');
        
    % Load correct verified data from file
    mktdata_struct_correct = load(tmp_filename);
    mktdata_struct_correct = mktdata_struct_correct.tmp_mktdata_struct;
    % Compare data
    if (isequal(tmp_mktdata_struct,mktdata_struct_correct))
        success_tests = success_tests + 1;
        total_tests = total_tests + 1;
        fprintf('SUCCESS: load_mktdata_objects: Parsing of marketdata objects is correct.\n');
    else
        % in order to see which object attribute failed, make detailed comparison test of all key - value pairs
        % sometimes there is also a false positive -> catch with retcode
        % compare, if information is stored which is not contained in struct
        retcode = compare_struct(mktdata_struct_correct,tmp_mktdata_struct);
        % also compare other case (information contained in struct which is not stored
        %retcode2 = compare_struct(tmp_mktdata_struct,mktdata_struct_correct);
        %retcode = retcode + retcode2;
        if retcode > 0
            fprintf('WARNING: load_mktdata_objects: Parsing of marketdata objects not successful. Structs differ:\n');  
            total_tests = total_tests + 1;
        else
            fprintf('INFO: Comparison of both structs gave a false positive. Element by element comparison yielded no differences.\n');
            success_tests = success_tests + 1;
            total_tests = total_tests + 1;
            fprintf('SUCCESS: load_mktdata_objects: Parsing of marketdata objects is correct.\n');
        end 
    end
catch
    fprintf('ERROR: load_mktdata_objects integration tests failed. Aborting: >>%s<< \n',lasterr);
    total_tests = total_tests_start + 2;
end
fprintf('\n'); 
% Enabling warnings again
if ( exist('OCTAVE_VERSION') > 0 )  % variable returns 5 for Octave, 0 for Matlab
    warning('on', 'Octave:load-file-in-path');
    warning('on', 'Octave:classdef-to-struct');
end

end % end function

% ------------------------------------------------------------------------------
%                               Helper Function
% ------------------------------------------------------------------------------
function retcode = compare_struct(a,b)
    % Compare all elements of two structures.
    % a needs to be the validated structure. 
    % Returns retcode > 0 -> number of fails
    retcode = 0;
    % loop through all objects
    for ii = 1 : 1 : length(a)
        tmp_id = a(ii).id;
        b_obj = get_sub_object(b, tmp_id);
        %fprintf('Comparing object >>%s<< with >>%s<<\n',tmp_id,b_obj.id);
        for [ a_val, key ] = a(ii).object
            b_val = getfield(b_obj, key);
            if ( isequal(a_val,b_val) )
                %fprintf('Values are identical for key >>%s<<.\n',key);
            else
                fprintf('Values are not identical for object >>%s<< and key >>%s<<.\n',b_obj.id,key);
                fprintf('Correct value:\n');
                a_val
                fprintf('Actual value:\n');
                b_val
                retcode = retcode + 1;
            end
        end
    end
end

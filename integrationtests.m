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
%# @deftypefn {Function File} {} integrationtests(@var{path_folder})
%# Call integrationtests of specified functions and return test statistics. @*
%# Input parameter: path to folder with testdata. All integration test scripts
%# have to be hard coded in this script.
%# @end deftypefn

function integrationtests(path_folder)
old_dir = pwd;
% change directory
chdir(path_folder);

% load packages
pkg load financial;     % load financial packages (needed throughout all scripts)
pkg load statistics;    % load statistics packages (needed throughout all scripts)

% 0) check for required oct files
if ~( exist('pricing_callable_bond_cpp') == 3)
    error('ERROR: pricing_callable_bond_cpp.oct does not exist in path. Compilation required.');
end

% 1) Specify all functions, which have embedded tests:
function_cell = {'doc_instrument'};
path_testing_folder = path_folder;

fprintf('=== Running integration tests === \n'); 
% 2) Run tests of unit test framework
tests_total = 0;
tests_fail = 0; 
M = zeros(length(function_cell),2);
for ii = 1 : 1 : length(function_cell)
    tmp_func = function_cell{ii};
    [tmp_success,tmp_tests] = test(tmp_func,'normal');
    tmp_failed_tests = tmp_tests - tmp_success;
    M(ii,1) = tmp_success;
    M(ii,2) = tmp_failed_tests;
    tests_fail = tests_fail + tmp_failed_tests;
    tests_total = tests_total + tmp_tests;
    if ( tmp_failed_tests > 0)
        fprintf('WARNING: %d failed tests for function >>%s<< \n',tmp_failed_tests,tmp_func);
        fprintf('Message:\n');
        test(tmp_func,'verbose'); 
    else
        fprintf('SUCCESS: >>%s<< \n',tmp_func);
    end
    
end

% 3) Run custom integration tests
% 3.1) Test of input and output behaviour
    function_cell(end + 1) = 'test_io';
    [tmp_success,tmp_tests] = test_io(path_testing_folder);
    tmp_failed_tests = tmp_tests - tmp_success;
    M(end + 1,1) = tmp_success;
    M(end,2) = tmp_failed_tests;
    tests_fail = tests_fail + tmp_failed_tests;
    tests_total = tests_total + tmp_tests;
    if ( tmp_failed_tests > 0)
        fprintf('WARNING: %d failed tests for function >>test_io<< \n',tmp_failed_tests);
    else
        fprintf('SUCCESS: >>test_io<< \n');
    end

% 4) Run a full octarisk script in batch mode
    fprintf('\nCall Octarisk in batch mode:\n');
    % call octarisk script
    function_cell(end + 1) = 'octarisk';
    [instrument_struct, curve_struct, index_struct, surface_struct, para_object, matrix_struct, riskfactor_struct, portfolio_struct, stresstest_struct, mc_var_shock_pct, port_obj_struct] = octarisk(path_testing_folder);
    
    fund_aaa = get_sub_object(port_obj_struct,'FUND_AAA');
    fund_bbb = get_sub_object(port_obj_struct,'FUND_BBB');
	
    if ( abs(fund_aaa.varhd_abs - 34055.07012)<0.0001 && abs(fund_bbb.varhd_abs-10562.32652)<0.0001 )
        tests_total = tests_total + 1;
        fprintf('SUCCESS: >>octarisk<<. All Fund VaR figures are correct.\n');
        M(end + 1,1) = 2;
        M(end,2) = 0;
    else
        tests_fail = tests_fail + 1;
        fprintf('WARNING: failed tests for function >>octarisk<<. Fund VaR figures not as expected (VaR Fund AAA 34055.07 EUR and VaR Fund BBB 10562.33 EUR.\n');
        M(end + 1,1) = 0;
        M(end,2) = 2;
    end

% 5) Run comparison of octarisk reports:
	fprintf('\nCompare generated reports:\n');
	[tmp_success_tests,tmp_total_tests] = test_report_files(path_folder);
	tests_total = tests_total + tmp_success_tests + tmp_total_tests;
	tests_fail = tests_fail + tmp_total_tests - tmp_success_tests;
	function_cell(end + 1) = 'test_report_files';
	M(end + 1,1) = tmp_success_tests;
    M(end,2) = tmp_total_tests - tmp_success_tests;
    
% 6) Print statistics
fprintf('\nVisualization:\n');
for ii = 1 : 1 : rows(M)
    success_string = '';
    fail_string = '';
    for jj = 1 : 1 : M(ii,1)
        success_string = strcat(success_string,'+');
    end
    for jj = 1 : 1 : M(ii,2)
        fail_string = strcat(fail_string,'-');
    end
    fprintf(' %s %s \t%s\n',fail_string,success_string,function_cell{ii});
end

fprintf('\nSummary:\n');
fprintf('\tFUNCTIONS\t%d \n',length(function_cell));
fprintf('\tPASS\t\t%d \n',tests_total - tests_fail);
fprintf('\tFAIL\t\t%d \n',tests_fail);
if tests_fail > 0
	fprintf('\n');
	fprintf('##############   ACTION REQUIRED: failed tests detected ##############');
	fprintf('\n');
else
	fprintf('\n');
	fprintf('##############          ALL TESTS SUCCESSFULL          ##############');
	fprintf('\n');
end
chdir(old_dir);
end

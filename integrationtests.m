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
	octarisk(path_testing_folder);
	% get hash of report files and compare with known hash:
	hash_fund_aaa = hash('SHA256',strcat(path_testing_folder,'/output/reports/VaR_report_2016Q3_FUND_AAA.txt'));
	hash_fund_bbb = hash('SHA256',strcat(path_testing_folder,'/output/reports/VaR_report_2016Q3_FUND_BBB.txt'));
	known_hash_aaa = '3406e4cf61fb54baa1d8df810c4d680d450426e4041530183d27d94c8b8ad846';
	known_hash_bbb = '21bbce9ab7d7556b7c37329e24bb9e7d19d9d5d6f45764e23e21661b61c8ddcd';
	
	if ~( strcmpi(hash_fund_aaa,known_hash_aaa) || strcmpi(hash_fund_bbb,known_hash_bbb) )
		tests_fail = tests_fail + 1;
        fprintf('WARNING: failed tests for function >>octave<< \n');
		M(end + 1,1) = 0;
		M(end,2) = 2;
    else
		tests_total = tests_total + 1;
        fprintf('SUCCESS: >>octave<<. All reports are correct.\n');
		M(end + 1,1) = 2;
		M(end,2) = 0;
    end
	
% 5) Print statistics
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
    fprintf('%s %s \t%s\n',fail_string,success_string,function_cell{ii});
end

fprintf('\nSummary:\n');
fprintf('\tFUNCTIONS\t%d \n',length(function_cell));
fprintf('\tPASS\t\t%d \n',tests_total - tests_fail);
fprintf('\tFAIL\t\t%d \n',tests_fail);

end

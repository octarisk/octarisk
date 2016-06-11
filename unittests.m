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
%# @deftypefn {Function File} {} unittests()
%# Call unittests of specified functions and return test statistics.
%# @end deftypefn

function unittests()

% 1) Specify all functions, which have embedded tests:
function_cell= {'pricing_npv','option_bs','option_willowtree', ...
                'calibrate_option_bs','calibrate_option_willowtree', ...
                'calibrate_evt_gpd','get_gpd_var','calibrate_soy_sqp', ...
                'swaption_black76','swaption_bachelier','get_forward_rate', ...
                'timefactor','convert_curve_rates','doc_instrument', ...
                'discount_factor','option_bjsten'};
 
% 2) Run tests
tests_total = 0;
tests_fail = 0; 
for ii = 1 : 1 : length(function_cell)
    tmp_func = function_cell{ii};
    [tmp_success,tmp_tests] = test(tmp_func,'normal');
    tmp_failed_tests = tmp_tests - tmp_success;
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

% 3) Print statistics
fprintf('\nSummary:\n');
fprintf('\tFUNCTIONS\t%d \n',length(function_cell));
fprintf('\tPASS\t\t%d \n',tests_total - tests_fail);
fprintf('\tFAIL\t\t%d \n',tests_fail);

end

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

pkg load statistics;
pkg load financial;

% 1) Specify all functions which have embedded tests:
function_cell= {'pricing_npv','option_bs','option_willowtree', ...
                'calibrate_generic', 'any2str', 'struct2obj', ...
                'calibrate_evt_gpd', 'get_gpd_var', ...
                'swaption_black76','swaption_bachelier','get_forward_rate', ...
                'timefactor', 'convert_curve_rates', 'discount_factor', ...
                'option_bjsten', 'interpolate_curve', ...
                'scenario_generation_MC', 'option_barrier', ...
                'get_sub_object', 'get_basis', 'rollout_structured_cashflows',  ...
                'getCapFloorRate', 'calcConvexityAdjustment', ...
                'generate_willowtree', 'return_checked_input', 'option_lookback', ...
                'option_asian_vorst90', 'option_asian_levy', 'option_binary', ...
                'get_cms_rate_hull', 'harrell_davis_weight', 'get_sub_struct', ...
                'addtodatefinancial','epanechnikov_weight','get_quantile_estimator', ...
                'get_informclass','get_informscore','get_esg_rating','calc_HHI', ...
                'get_credit_rating','map_country_isocodes','get_readinessclass', ...
                'test_oct_files','get_sri_level','get_srri_level'};
fprintf('=== Running unit tests for %d functions=== \n',length(function_cell)); 
% 2) Run tests
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
    
    % description documentation check
    errorcode = check_description_consistency(tmp_func);
    if ( errorcode > 0)
        fprintf('WARNING: %d failed documentation tests for function >>%s<< \n',errorcode,tmp_func);
    else
        fprintf('SUCCESS Documentation test: >>%s<< \n',tmp_func);
    end
    
end

% 3) Print statistics
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


% ##############################################################################
%                       Helper function
% ##############################################################################
function errorcode = check_description_consistency(functionname)

% 0. get input data for new function
errorcode = 0; 
narg = nargin(functionname);

% get help string and try to get infos about arguments
s = help(functionname);

% check for ( and )
if (findstr(s,'(') && findstr(s,')'))

	% get all arguments between description of function call
	functionstring = strsplit(s,')'){1}; % get string until first ')'
	argumentstring = strsplit(functionstring,'('){2}; % get string after first '('

	arguments_cell = strsplit(argumentstring,',');
	arguments_cell = strtrim(arguments_cell);
	lencell = numel(arguments_cell);
	% 1. function call arguments consistency check
	if lencell != narg
		fprintf('WARN: function %s: unequal number of arguments (%s in call vs. %s in description)\n',functionname,any2str(narg),any2str(lencell));
		errorcode = errorcode + 1;
	end

	% 2get variables description:
	strpos = regexpi(s,'variables:');
	if isempty(strpos)
		fprintf('WARN: function %s has no Variables description at all.\n',functionname);
	else 
		% account for case sensitivity
		if isempty(strfind(s,'variables:'))
			varstring = strsplit(s,'Variables:'){2}; % get all variables
		else
			varstring = strsplit(s,'variables:'){2}; % get all variables
		end
		% consistency check description
		for jj=1:1:length(arguments_cell)
			tmp_arg = arguments_cell{jj};
			strpos = regexpi(varstring,tmp_arg);
			if isempty(strpos)
				fprintf('WARN: function %s has no Variables description for argument %s.\n',functionname,any2str(tmp_arg));
				errorcode = errorcode + 1;
			end
		end
	end

else
	fprintf('WARN: function %s has no function classification at all.\n',functionname);
	errorcode = errorcode + 1;
end
end

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
%# @deftypefn {Function File} {} profiler_analysis(@var{script_name},@var{argument},@var{depth})
%# Call profiler for specified script and argument and return detailed statistics.
%# Input variables:
%# @itemize @bullet
%# @item @var{script_name}: name of script as string [required] 
%# @item @var{argument}: first and only argument of script [required] 
%# @item @var{depth}: number of sub-functions to analyse [optional, default = 10]
%# @end itemize
%# @end deftypefn


function profiler_analysis(script_name,argument,depth,arg2,arg3)


if (nargin < 3)
    depth = 10;
end

% call script with activated profiler
profile clear;
profile on;
try
    if nargin < 3
        feval(script_name,argument);
    elseif nargin == 4
        feval(script_name,argument,arg2);
    elseif nargin == 5
        feval(script_name,argument,arg2,arg3);
    end
    profile off;
catch
    profile off;
end
% get statistics
T = profile ("info");
% print profiler data
print_profiler_struct(T,depth)
end

% ##################    Helper Function    ################

function print_profiler_struct(T,max_depth)

% input data checks
if ~(isstruct(T))
    error('Input data is not a struct. Ending Function.');
end

if (nargin < 2)
    max_depth = 10;
end

% get maximum length of profile struct
n = min(max_depth,length(T.FunctionTable));
fprintf('\n========   Profile Overview of %s Functions   ========\n',any2str(n));
profshow (T,n);

total_time_vec = [T.FunctionTable.TotalTime];
[total_time_vec_sorted, index_sorted] = sort(total_time_vec);
% take last n entries of sorted index and make analysis
function_vec = index_sorted(end-n:end);
fprintf('\n========   Detailed Analysis of %s Functions   ========\n',any2str(n));
% loop through most time intensive function and get all children (up to 3rd level)
for ii = length(function_vec) : -1 : 1
    tmp_idx = function_vec(ii);
    tmp_struct = T.FunctionTable(tmp_idx);
    tmp_name = tmp_struct.FunctionName;
    tmp_time = tmp_struct.TotalTime;
    tmp_children = tmp_struct.Children;
    fprintf('========   New Function   ========\n');
    fprintf('FunctionName: \t %s \t Time: %s s\n',tmp_name,any2str(tmp_time));
    if ( length(tmp_children) > 0 )
        for jj = 1 : 1 : length(tmp_children)
            tmp_child_idx = tmp_children(jj);
            tmp_struct_child = T.FunctionTable(tmp_child_idx);
            tmp_name_child = tmp_struct_child.FunctionName;
            tmp_time_child = tmp_struct_child.TotalTime;
            tmp_children_child = tmp_struct_child.Children;
            fprintf('|--- Child Function: \t %s \t Time: %s s\n',tmp_name_child,any2str(tmp_time_child));
            if ( length(tmp_children_child) > 0 )
                for jj = 1 : 1 : length(tmp_children_child)
                    tmp_child_child_idx = tmp_children_child(jj);
                    tmp_struct_child_child = T.FunctionTable(tmp_child_child_idx);
                    tmp_name_child_child = tmp_struct_child_child.FunctionName;
                    tmp_time_child_child = tmp_struct_child_child.TotalTime;
                    tmp_children_child_child = tmp_struct_child_child.Children;
                    fprintf('     |--- Childs Child Function: \t %s \t Time: %s s\n',tmp_name_child_child,any2str(tmp_time_child_child));
                end
            end
        end
    end
end
fprintf('\n');
end
%# -*- texinfo -*-
%# @deftypefn {Function File} {} test_oct_files()
%# Call unittests for compiled oct files.
%# @end deftypefn

function test_oct_files()
    % this is only a dummy function for containing all the oct file testing 
    % suites.
end
%!test 
%! fprintf('HOLD ON...\n');
%! fprintf('\ttest_oct_files:\tcalculate_npv_cpp\n');
%! assert(calculate_npv_cpp ([0.9,0.95,0.99;0.9,0.95,0.99],[3,3,103]),[ 107.52;107.52],0.01)




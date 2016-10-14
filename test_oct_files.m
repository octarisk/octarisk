function test_oct_files()
    % this is only a dummy function for containing all the oct file testing 
    % suites.
end
%!test 
%! fprintf('HOLD ON...\n');
%! fprintf('\ttest_oct_files:\tTesting discount_factor_cpp\n');

%!assert(discount_factor_cpp (736420, 738245, 0.00010010120979, 'discrete', 3, 'annual'),0.999499644219733,0.000001)
%!assert(discount_factor_cpp (736420, 738245, 0.00010010120979, 'disc', 3, 'annual'),0.999499644219733,0.000001)
%!assert(discount_factor_cpp (736420, 738245, 0.00010010120979, 'simple', 3, 'annual'),0.999499744332038,0.000001)
%!assert(discount_factor_cpp (736420, 738245, 0.00010010120979, 'simp', 3, 'annual'),0.999499744332038,0.000001)
%!assert(discount_factor_cpp (736420, 738245, 0.00010010120979, 'cont', 3, 'annual'),0.999499619183308,0.000001)
%!assert(discount_factor_cpp (736420, 738245, 0.00010010120979, 'continuous', 3, 'annual'),0.999499619183308,0.000001)
%!assert(discount_factor_cpp (736420, 738245, 0.00010010120979, 'disc', 3', 'weekly'),0.999499619664798,0.000001)
%!assert(discount_factor_cpp (736420, 738245, 0.00010010120979, 'disc', 3, 'monthly'),0.999499621269802,0.000001)
%!assert(discount_factor_cpp (736420, 738245, 0.00010010120979, 'disc', 3, 'quarter'),0.999499625442730,0.000001)
%!assert(discount_factor_cpp (736420, 738245, 0.00010010120979, 'disc', 3, 'semi-annual'),0.999499631701938,0.000001)
%!error(discount_factor_cpp (736420, 738245, 0.00010010120979, 'disc', 'act/365', 'montly'))
%!error(discount_factor_cpp (736420, 738245, 0.00010010120979, 'disc', 'act/365', 'montly'))



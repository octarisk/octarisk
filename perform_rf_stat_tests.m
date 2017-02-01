%# Copyright (C) 2017 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} { [@var{retcode}] =} perform_rf_stat_tests(@var{riskfactor_cell},@var{riskfactor_struct},@var{RndMat},@var{distr_type})
%# Perform statistical tests on risk factor shock vector. Return 1 if all tests
%# pass, return 255 if at least one test fails.
%# @end deftypefn

function retcode = perform_rf_stat_tests(riskfactor_cell,riskfactor_struct,RndMat,distr_type)
retcode = 1;
% Perform statistical tests on MC risk factor distributions:
for ii = 1 : 1 : length(riskfactor_cell)  
	rf_id = riskfactor_cell{ii};
	rf_object = get_sub_object(riskfactor_struct, rf_id);    
	fprintf('=== Distribution function for riskfactor %s ===\n',rf_object.id);
	fprintf('Pearson_type: >>%d<<\n',distr_type(ii));  
	
	% calculate 4 moments of distribution
	mean_target = rf_object.mean;   % mean
	mean_act = mean(RndMat(:,ii));
	sigma_target = rf_object.std;   % sigma
	sigma_act = std(RndMat(:,ii));
	skew_target = rf_object.skew;   % skew
	skew_act = skewness(RndMat(:,ii));
	kurt_target = rf_object.kurt;   % kurt    
	kurt_act = kurtosis(RndMat(:,ii));
	
	% print overview
	fprintf('Stat. parameter:  \t| Target | Actual \n');
	fprintf('Mean comparison: \t| %0.4f |  %0.4f \n',mean_target,mean_act);
	fprintf('Vola comparison: \t| %0.4f |  %0.4f \n',sigma_target,sigma_act);
	fprintf('Skewness comparison: \t| %0.4f |  %0.4f \n',skew_target,skew_act);
	fprintf('Kurtosis comparison: \t| %0.4f |  %0.4f \n',kurt_target,kurt_act);
	
	% perform JB Test for normal distributed random numbers (dist_type == 0)
	if ( distr_type(ii) == 0)
		[JB_p_value,JBstatistic] = JarqueBeraTest(RndMat(:,ii));
		fprintf('Jarque-Bera p-Value: \t| %0.4f |  [0.1..0.9 for normal distribution] \n',JB_p_value);
		if ( JB_p_value > 0.9 || JB_p_value < 0.1)
			retcode = 255;
		end
	end
	% test for bimodality -> fit polynomial and calculate sign of parabola opening parameter
	[xx yy] = hist(RndMat(:,ii),80);
	p = polyfit(yy,xx,2);
	if ( p(1) > 0 )
		fprintf('Warning: octarisk: Distribution type >>%d<< for riskfactor >>%s<< might be bimodal.\n',distr_type(ii),rf_id);
		retcode = 255;
	end
end

end

%-------------------------------------------------------------------------------
%							Helper Functions
%-------------------------------------------------------------------------------

% perform a Jarque-Bera test on a sample vector z
function [JB_p_value,JBstatistic] = JarqueBeraTest(z)
    meanJB  = mean(z);
    sdJB    = std(z);
    bar_z   = z-meanJB;
    sdJB    = std(bar_z);
    n       = length(z);
    bar_z_3 = bar_z.^3;
    bar_z_4 = bar_z.^4;
    % calculate empirical skewness
    S = mean(bar_z_3) / ( sdJB.^3 );
    % calculate empirical kurtosis
    K = mean(bar_z_4) / ( sdJB.^4 );
    JBstatistic = (n/6) .* (S^2 + 0.25.*(K-3).^2);
    % the Jarque-Bera test statistic follows a chi-square distribution with 2 degrees of freedom
    JB_p_value = 1-chi2pdf(JBstatistic,2);
end
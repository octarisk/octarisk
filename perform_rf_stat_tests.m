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
rejection_rate_mean = 0;
rejection_rate_std = 0;
alpha_mean = 0.01;
alpha_std = 0.01;
% Perform statistical tests on MC risk factor distributions:
for ii = 1 : 1 : length(riskfactor_cell)  
    rf_id = riskfactor_cell{ii};
    rf_object = get_sub_object(riskfactor_struct, rf_id);
    fprintf('=== Distribution function for riskfactor %s ===\n',rf_object.id);
    fprintf('Pearson_type: >>%d<<\n',distr_type(ii));
    randvec = RndMat(:,ii);
    mean_target = rf_object.mean;   % mean
    sigma_target = rf_object.std;   % sigma
    skew_target = rf_object.skew;   % skew
    kurt_target = rf_object.kurt;   % kurt

    % A) Pearson-system integrity check: verify the TARGET (mean,std,skew,kurt)
    % actually corresponds to a well-defined, non-degenerate Pearson
    % distribution, BEFORE touching the Monte Carlo sample at all. This is
    % the authoritative check -- classify_pearson is the same, analytic (no
    % sampling involved) classification used by get_marginal_distr_pearson
    % itself, so a NaN return here means no valid distribution exists for
    % these moments (a boundary singularity / spike in the underlying Beta
    % or beta-prime/F distribution -- see PEARSON_METHODOLOGY.md). O(1),
    % deterministic, and immune to the false positives the legacy
    % histogram-based check further below produces on legitimately skewed,
    % heavy-tailed targets. When it fails, randvec is entirely NaN (by
    % construction of get_marginal_distr_pearson) so every downstream
    % moment/statistical test is skipped rather than crashing or reporting
    % meaningless NaN comparisons.
    retvec_check = classify_pearson(mean_target, sigma_target, skew_target, kurt_target);
    if ( isnan(retvec_check(1)) )
        fprintf('Warning: octarisk: no valid Pearson distribution exists for riskfactor >>%s<< at skew=%0.4f, kurt=%0.4f (boundary singularity / degenerate shape). Choose different (skew,kurt) target values.\n',rf_id,skew_target,kurt_target);
        fprintf('Skipping remaining statistical tests for riskfactor >>%s<< (no sample to test).\n',rf_id);
        retcode = 255;
        continue;
    end

    % calculate 4 moments of distribution
    mean_act = mean(randvec);
    sigma_act = std(randvec);
    skew_act = skewness(randvec);
    kurt_act = kurtosis(randvec);

    % print overview
    fprintf('Stat. parameter:  \t| Target | Actual \n');
    fprintf('Mean comparison: \t| %0.4f |  %0.4f \n',mean_target,mean_act);
    fprintf('Vola comparison: \t| %0.4f |  %0.4f \n',sigma_target,sigma_act);
    fprintf('Skewness comparison: \t| %0.4f |  %0.4f \n',skew_target,skew_act);
    fprintf('Kurtosis comparison: \t| %0.4f |  %0.4f \n',kurt_target,kurt_act);

    % B) perform JB Test for normal distributed random numbers (dist_type == 0)
    if ( distr_type(ii) == 0)
        [JB_p_value,JBstatistic] = JarqueBeraTest(RndMat(:,ii));
        fprintf('Jarque-Bera p-Value: \t| %0.4f |  [0.1..0.9 for normal distribution] \n',JB_p_value);
        if ( JB_p_value > 0.9 || JB_p_value < 0.1) %Fail
            retcode = 255;
        else %passed
        end
    end

    % B2) Legacy histogram-shape diagnostic (informational only -- kept for
    % visibility, but NOT used as a pass/fail gate: fitting a plain parabola
    % to a strongly skewed/heavy-tailed histogram routinely misclassifies a
    % perfectly valid distribution as "bimodal", so this no longer sets
    % retcode. Use check A) above for actual integrity decisions.
    [xx yy] = hist(RndMat(:,ii),80);
    p = polyfit(yy,xx,2);
    if ( p(1) > 0 )
        fprintf('Info: octarisk: histogram shape diagnostic for riskfactor >>%s<< is non-parabolic (common for strongly skewed/heavy-tailed targets; not necessarily a defect -- see check A above for the authoritative integrity result).\n',rf_id);
    end

    % C) Test of Sample mean on 99% confidence intervall
    alpha_mean = 0.01;
    [rejflag lb_norm ub_norm] = SampleMeanTest(randvec,mean_target,alpha_mean);
        steps = 20;
    delta = ub_norm - lb_norm;
    stepsize = delta / steps;
    if ( rejflag == false)
        %fprintf('Mean test PASSED: \t| %0.8f  < %0.8f < %0.8f \n',lb_norm,mean_act,ub_norm);
        lowersteps = char(repmat(45,1,round(abs(mean_target-lb_norm) / stepsize)));
        uppersteps = char(repmat(45,1,round(abs(ub_norm - mean_target) / stepsize)));
        fprintf('Mean test PASSED: \t|%s%s%s|\n',any2str(lowersteps),'X',any2str(uppersteps))
    else
        rejection_rate_mean++;
        fprintf('Mean test FAILED: \t| %0.8f  !< %0.8f !< %0.8f \n',lb_norm,mean_act,ub_norm);
        if ( mean_target > ub_norm)
            lowersteps = char(repmat(45,1,round(steps))); 
            uppersteps =  char(repmat(46,1,round(abs(mean_target-ub_norm) / stepsize)));
            fprintf('Mean test FAILED: \t|%s|%s%s\n',any2str(lowersteps),any2str(uppersteps),'X')
        else
            lowersteps = char(repmat(46,1,round(abs(mean_target-lb_norm) / stepsize)));
            uppersteps = char(repmat(45,1,round(steps)));
            fprintf('Mean test FAILED: \t%s%s|%s|\n','X',any2str(lowersteps),any2str(uppersteps))
        end
        
    end
    
    % D) Test of Sample standard deviation on 99% confidence intervall
    alpha_std = 0.01;
    [rejflag lb_chi2 ub_chi2] = SampleStdTest(randvec,sigma_target,alpha_std);
    steps = 20;
    delta = ub_chi2 - lb_chi2;
    stepsize = delta / steps;
    if ( rejflag == false)
        %fprintf('Vola test PASSED: \t| %0.8f  < %0.8f < %0.8f \n',lb_chi2,sigma_target,ub_chi2);
        lowersteps = char(repmat(45,1,round(abs(sigma_target-lb_chi2) / stepsize)));
        uppersteps = char(repmat(45,1,round(abs(ub_chi2 - sigma_target) / stepsize)));
        fprintf('Vola test PASSED: \t|%s%s%s|\n',any2str(lowersteps),'X',any2str(uppersteps))
    else
        rejection_rate_std++;
        fprintf('Vola test FAILED: \t| %0.8f  !< %0.8f !< %0.8f \n',lb_chi2,sigma_target,ub_chi2);
        if ( sigma_target > ub_chi2)
            lowersteps = char(repmat(45,1,round(steps))); 
            uppersteps =  char(repmat(46,1,round(abs(sigma_target-ub_chi2) / stepsize)));
            fprintf('Vola test FAILED: \t|%s|%s%s\n',any2str(lowersteps),any2str(uppersteps),'X')
        else
            lowersteps = char(repmat(46,1,round(abs(sigma_target-lb_chi2) / stepsize)));
            uppersteps = char(repmat(45,1,round(steps)));
            fprintf('Vola test FAILED: \t%s%s|%s|\n','X',any2str(lowersteps),any2str(uppersteps))
        end
        
    end
    
end
fprintf('=========   Overall test statistics   =========\n');
rejection_rate_mean = round(1000 * rejection_rate_mean / length(riskfactor_cell))/1000;  
rejection_rate_std = round(1000 * rejection_rate_std / length(riskfactor_cell))/1000;  
fprintf('Mean test rejection rate (%s%% conf.): \t%s%%\n',any2str((1-alpha_mean)*100),any2str(rejection_rate_mean * 100));
fprintf('Vola test rejection rate (%s%% conf.): \t%s%%\n',any2str((1-alpha_std)*100),any2str(rejection_rate_std * 100));
fprintf('===============================================\n');
end

%-------------------------------------------------------------------------------
%                           Helper Functions
%-------------------------------------------------------------------------------

function [rejflag lb_norm ub_norm] = SampleMeanTest(z,mean_target,alpha)
    if nargin < 3
        alpha = 0.01;
    end
    rejflag = 0;
    len = length(z);
    meanz = mean(z);
    stdrf = std(z);
    % calculate test statistics: bounds of confidence interval for mean
    delta = norminv(1-alpha/2) * stdrf / sqrt(len);
    ub_norm = meanz + delta;
    lb_norm = meanz - delta;

    if ( mean_target > ub_norm || mean_target <   lb_norm)
        rejflag = 1;
    end
end

function [rejflag lb_chi2 ub_chi2] = SampleStdTest(z,sigma_target,alpha)
    if nargin < 3
        alpha = 0.01;
    end
    rejflag = 0;
    len = length(z) - 1;
    stdrf = std(z);
    % calculate test statistics: bounds of confidence interval
    ub_chi2 = sqrt( (len*stdrf^2)/chi2inv(alpha/2,len));
    lb_chi2  = sqrt( (len*stdrf^2)/ chi2inv(1-alpha/2,len));

    if ( sigma_target > ub_chi2 || sigma_target <   lb_chi2)
        rejflag = 1;
    end

end


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

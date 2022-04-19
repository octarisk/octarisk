%# Copyright (C) 2022 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {@var{repstruct} =} plot_gini (@var{obj}, @var{para})
%# Plot Lorentz curve for portfolio distribution. 
%#
%# @seealso{}
%# @end deftypefn

function repstruct = calc_gini(obj,repstruct,para,path_reports)

or_blue  = [0.085938   0.449219   0.761719]; 

#y = obj.getValue(para.mc_timestep) - obj.getValue('base'); % Portfolio Values
y = obj.getValue(para.mc_timestep); % Portfolio Values
                      % equal distribution across all scenarios
y = sort(y);

x = ones(numel(y),1); 
% Calculation
[g,l,a] = gini(x,y,false);
repstruct.gini = g;

if para.plotting
    % Plotting
    hf = figure(1);
    clf; 
    area(l(:,1),l(:,2),'FaceColor',or_blue);    % the Lorentz curve
    hold on;
    plot([0,1],[0,1],'--k');                        % 45 degree line
    axis tight      % ranges of abscissa and ordinate are by definition exactly [0,1]
    axis square     % both axes should be equally long
    set(gca,'XTick',get(gca,'YTick'))   % ensure equal ticking
    set(gca,'Layer','top');             % grid above the shaded area
    grid on;
    title(['\bfGini coefficient = ',num2str(g)],'fontsize',9);
    xlabel('RW Scenarios','fontsize',9);
    ylabel('Portfolio Value','fontsize',9);

    % save plotting
    filename_plot_aa = strcat(path_reports,'/',obj.id,'_lorentz.png');
    print (hf,filename_plot_aa, "-dpng", "-S400,400");
    filename_plot_aa = strcat(path_reports,'/',obj.id,'_lorentz.pdf');
    print (hf,filename_plot_aa, "-dpdf", "-S400,400");
end

error("stop script")
end

%# Copyright (C) 2016 Schinzilord <schinzilord@octarisk.com>
%# Copyright (C) 2016 IRRer-Zins <IRRer-Zins@t-online.de>
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
%# @deftypefn {Function File} { [@var{y}] =} interpolate_curve (@var{nodes}, @var{rates}, @var{timestep}, @var{interp_method}, @var{ufr}, @var{alpha}, @var{method_extrapolation})
%#
%# Calculate an interpolated rate on a curve for a given timestep.@*
%# Supported methods are: linear (default), moneymarket, exponential, loglinear, 
%# spline, smith-wilson, monotone-convex, constant (mapped to previous),
%# previous and next.
%# 
%# A constant extrapolation is assumed, except for smith-wilson, where the 
%# ultimate forward rate will be reached proportional to reversion speed alpha.
%# For all methods except splines a fast taylormade algorithm is used. For 
%# splines see Octave function interp1 for more details. 
%# Explanation of Input Parameters of the interpolation curve function:
%# @*
%# Variables:
%# @itemize @bullet
%# @item @var{nodes}: is a 1xN vector with all timesteps of the given curve
%# @item @var{rates}: is MxN matrix with curve rates per timestep defined in
%#                      columns. Each row contains a specific scenario with 
%#                      different curve structure
%# @item @var{timestep}: is a scalar, specifiying the interpolated timestep on 
%#                      vector nodes
%# @item @var{interp_method}: OPTIONAL: interpolation method
%# @item @var{ufr}:   OPTIONAL: (only used for smith-wilson): ultimate forward 
%#                              rate (default: last liquid point)
%# @item @var{alpha}: OPTIONAL: (only used for smith-wilson): reversion speed 
%#                              to ultimate forward rate (default: 0.1)
%# @item @var{method_extrapolation}: OPTIONAL: extrapolation method
%# @item @var{y}: OUTPUT: inter/extrapolated rate
%# @end itemize
%# @seealso{interp1, interp2, interp3, interpn}
%# @end deftypefn

function y = interpolate_curve(nodes,rates,timestep,method,ufr,alpha,method_extrapolation)

  if (nargin < 3 || nargin > 7)
    print_usage ();
  end
  
  if ( nargin < 4)
    method = 'linear';
  elseif (nargin >= 4)
    method_cell = {'linear','mm','exponential','loglinear','spline', ...
                    'smith-wilson','monotone-convex','constant','next','previous'};
    findvec = strcmpi(method,method_cell);
    if ( findvec == 0)
         error('Error: interpolate_curve: Interpolation method must be either linear, mm (money market), exponential, loglinear, spline (experimental support only), smith-wilson, monotone-convex or constant, next or previous');
    end
  end
  if ( nargin < 7)
    method_extrapolation = 'none';
  end
  
  if (strcmpi(method,'smith-wilson'))
    if (nargin == 4)
        %disp('Warning: neither ufr nor reversion speed are specified. 
        % Setting ufr to EIOPA ufr and alpha = 0.19');
        alpha = 0.19;
        ufr = 0.042;
    elseif (nargin == 5)
        disp('Warning: interpolate_curve: no reversion speed provided. Setting alpha = 0.1');
        alpha = 0.19;
    elseif (nargin == 6)  
        if (alpha <= 0.0)
            error('Error: interpolate_curve: A positive reversion speed rate must be provided.');    
        end
    end
    if isempty(alpha)
        alpha = 0.19;
    end
    if isempty(ufr)
        ufr = 0.042;
    end
  end
% dimension time -> columnwise
% dimension scenarios -> rowwise
% Checks:
no_scen_nodes = columns(nodes);
no_scen_rates = columns(rates);
if ~( no_scen_nodes == no_scen_rates )
    error('Error: interpolate_curve: Number of columns must be equivalent');
end

if ~( issorted(abs(nodes)))
    error('Error: interpolate_curve: Nodes have to be sorted')
end


% short-cut: if timestep equals node, return rates at this node
eq_vec = (timestep == nodes);
if ( sum(eq_vec) > 0 )
    tmp_idx = 1:1:length(eq_vec);
    idx_node = tmp_idx * eq_vec';
    y = rates(:,idx_node);
    return
end

dnodes = abs(diff(nodes));

if ~(strcmpi(method,{'smith-wilson','monotone-convex'}))  % constant 
        % extrapolation only for methods except smith-wilson and monotone-convex
    if ( timestep <= min(nodes) ) % constant or linear extrapolation
        if ( strcmpi(method_extrapolation,'linear'))
            y = interp1(nodes',rates',timestep,'linear','extrap')';
            return
        else
            [minval tmp_idx] = min(nodes);
            y = rates(:,tmp_idx);
            return
        end
    elseif ( timestep >= max(nodes) ) % constant or linear extrapolation
        if ( strcmpi(method_extrapolation,'linear'))
            y = interp1(nodes',rates',timestep,'linear','extrap')';
            return
        else
            [maxval tmp_idx] = max(nodes);
            y = rates(:,tmp_idx);
            return
        end
    else
        % linear interpolation
        if (strcmpi(method,'linear'))          % linear interpolation
            for ii = 1 : 1 : (no_scen_nodes - 1)
                if ( abs(timestep) >= abs(nodes(ii)) && abs(timestep) <= abs(nodes(ii+1 )) )
                     w1 = 1 - abs(timestep - nodes(ii)) ./ dnodes(ii);
                     w2 = 1 - w1;
                     y = w1.* rates(:,ii) + w2.* rates(:,ii+1); 
                     return;           
                end
            end
            
        elseif (strcmpi(method,'mm'))          % money market interpolation
            for ii = 1 : 1 : (no_scen_nodes - 1)
                if ( abs(timestep) >= abs(nodes(ii)) && abs(timestep) <= abs(nodes(ii+1 )) )
                    alpha = (nodes(ii+1) - timestep) / ...
                            ( nodes(ii+1 ) - nodes(ii) );
                    y = (alpha .* nodes(ii) .* rates(:,ii) ...
                     + (1 - alpha) .* nodes(ii+1) .* rates(:,ii+1)) ./ timestep;
                     return;
                end
            end
            
        elseif (strcmpi(method,'constant'))          % constant interpolation 
            % -> next neighbour for compatiblity reasons (used for hist rates)
            if ( all(nodes(2:end) < 0)) % previous method
                for ii = 1 : 1 : (no_scen_nodes - 1)
                    if ( abs(timestep) >= abs(nodes(ii)) && abs(timestep) <= abs(nodes(ii+1 )) )
                         y = rates(:,ii+1); 
                         return;           
                    end
                end 
            else    % next method
                for ii = 1 : 1 : (no_scen_nodes - 1)
                    if ( abs(timestep) >= abs(nodes(ii)) && abs(timestep) <= abs(nodes(ii+1 )) )
                         y = rates(:,ii); 
                         return;           
                    end
                end
            end
        elseif (strcmpi(method,'previous'))      % mapping to previous neighbour 
            for ii = 1 : 1 : (no_scen_nodes - 1)
                if ( abs(timestep) >= abs(nodes(ii)) && abs(timestep) <= abs(nodes(ii+1 )) )
                     y = rates(:,ii); 
                     return;           
                end
            end
        elseif (strcmpi(method,'next'))          % mapping to next neighbour 
            for ii = 1 : 1 : (no_scen_nodes - 1)
                if ( abs(timestep) >= abs(nodes(ii)) && abs(timestep) <= abs(nodes(ii+1 )) )
                     y = rates(:,ii+1); 
                     return;           
                end
            end   
            
        elseif (strcmpi(method,'loglinear'))
            for ii = 1 : 1 : (no_scen_nodes - 1)
                if ( timestep >= nodes(ii) && timestep <= nodes(ii+1 ) )
                    alpha = (timestep - nodes(ii) ) ...
                            / ( nodes(ii+1 ) - nodes(ii) );
                    y = rates(:,ii) .* exp(alpha .* log(rates(ii+1) ...
                        ./ rates(ii)));
                end
            end    
            
        elseif (strcmpi(method,'exponential'))        % exponential interpolation
            for ii = 1 : 1 : (no_scen_nodes - 1)
                if ( timestep >= nodes(ii) && timestep <= nodes(ii+1 ) )
                    alpha = (nodes(ii+1) - timestep) / ( nodes(ii+1 ) ...
                            - nodes(ii) );
                    y = log(exp(rates(:,ii)) .* alpha + exp(rates(ii+1)) ...
                        .* (1 - alpha));
                end
            end 
            
        elseif (strcmpi(method,'spline'))             % spline interpolation
            % use octave's built in function spline
            y = spline(nodes',rates',timestep);
        end
    end
elseif (strcmpi(method,'smith-wilson'))               % smith-wilson method
    ufrc = log(1+ufr);
    [P, y] = interpolate_smith_wilson(timestep,rates,nodes,ufrc,alpha);
    
elseif (strcmpi(method,'monotone-convex'))
    if ( timestep <= nodes(1) ) % constant extrapolation
       y = rates(:,1);
       return
    elseif ( timestep >= nodes(end) ) % constant extrapolation
       y = rates(:,end);
       return
    else
        % due to unknown reasons, monotone convex doesn't like nice numbers, 
        % e.g. 0.01 or 0.02. So we add a small number to all rates and 
        % subtract it from results
        rates = rates + 0.000001;
        InputsareForwards = 0;
        Negative_Forwards_Allowed = 1;
        % 0. prepare values
        nodes = [0,nodes];
        ZZ = zeros(rows(rates),1);
        rates = [ZZ,rates];
        % 1. Call fi_estimates
        [f, fdiscrete, dInterpolantatNode] = fi_estimates(nodes, rates, ...
                            InputsareForwards,Negative_Forwards_Allowed);
        
        % 2. Interpolate values
        y = CalcInterpolant(timestep,nodes,f,fdiscrete,dInterpolantatNode);
        y = y - 0.000001;
    end
else
    error('ERROR: interpolation method not implemented'); 
end


end % end of Main function


% ----------------------------------------------------------------------
%          Main functions for Monotone Convex Interpolation
% ----------------------------------------------------------------------
% This implementation refers to the Wilmott paper 'Methods for Constructing 
% a Yield Curve' by P. Hagan and G. West, 2008 and the proposed VBA Algorithm.
% the basic non-vectorized code was taken from G. West's Excel Spreadsheet 
% (www.finmod.co.za) and adapted to Octave.
% The example calculation in West's spreadsheet could not be validated 
% (e.g. Forward calculation), but this implementation looks promising
  
function Interpolant_Value = CalcInterpolant(Term,Terms,f,fdiscrete, ...
                                                dInterpolantatNode)
  if Term <= 0 
    Interpolant_Value = f(:,1);
  elseif Term > max(Terms) 
    Interpolant_Value = CalcInterpolant((max(Terms)),Terms,f,fdiscrete, ...
                        dInterpolantatNode) * (max(Terms))  / Term ...
                        + CalcForward(max(Terms),Terms,f,fdiscrete) ...
                        * (1 - (max(Terms)) / Term);
  else
    if ( Term == max(Terms))
        i = length(Terms) -1;
    else
        i = lookup(Terms,Term);
    end
    x = (Term - Terms(i)) ./ (Terms(i + 1) - Terms(i));
    g0 = f(:,i) - fdiscrete(:,i + 1);
    g1 = f(:,i + 1) - fdiscrete(:,i + 1);
    ZZ = zeros(length(g0),1);
    V_g0st0 = zeros(length(g0),1);
    V_g1st0 = zeros(length(g0),1);
    V_g0st0 = g0<ZZ;
    V_g0gt0 = g0>ZZ;
    V_g1st0 = g1<ZZ;
    V_g1gt0 = g1>ZZ;
    % conditions for zone 1:
      % the following three conditions have all to be fulfilled:
        V_g1geg0m05 = g1 >= (-0.5 .* g0);        %  0.5 .* g0 <= g1
        V_g1seg0m2 = g1 <= (-2 .* g0);           % g1 <= -2 .* g0
        %V_g0st0;                        % g0 < 0
        V_zone1_a = V_g1geg0m05 + V_g1seg0m2 + V_g0st0;
        V_zone1_a = V_zone1_a == 3;
        % then
        G = g0 .* (x - 2 * x .^ 2 + x .^ 3) + g1 .* (-x .^ 2 + x .^ 3);
      % or the following three conditions have all to be fulfilled:
        V_g1seg0m05 = g1 <= (-0.5 .* g0);        % -0.5 .* g0 >= g1 &&
        V_g1geg0m2 = g1 >= (-2 .* g0);           % g1 >= -2 .* g0
        % g0 > 0 && -0.5 .* g0 >= g1 && g1 >= -2 .* g0
        V_zone1_b = V_g1seg0m05 + V_g1geg0m2 + V_g0gt0;   
        V_zone1_b = V_zone1_b == 3;
        V_zone1 = V_zone1_a + V_zone1_b;
    % conditions for zone 2:
        % the following two conditions have all to be fulfilled:
        V_g1gtg0m2 = g1 > (-2 .* g0);            % g1 > -2 .* g0 && g0 < 0
        V_zone2_a = V_g0st0 + V_g1gtg0m2;
        V_zone2_a = V_zone2_a == 2;
        % or the following two conditions have all to be fulfilled:
        V_g0gt0;                                % g0 > 0
        V_g1stg0m2 = g1 < (-2 .* g0);           % g1 < -2 .* g0 && g0 > 0
        V_zone2_b = V_g0gt0 + V_g1stg0m2;
        V_zone2_b = V_zone2_b == 2;
        V_zone2 = V_zone2_a + V_zone2_b;
    % conditions for zone 3:   
        % a)
        % g1 > -0.5 .* g0  &&  g0 > 0 &&  0 > g1
        V_g1gtg0m05 = g1 > (-0.5 .* g0);        
        V_zone3_a = V_g0gt0 + V_g1st0 + V_g1gtg0m05;
        V_zone3_a = V_zone3_a == 3;
        % b)
        % V_g0st0                               % g0 < 0
        % V_g1gt0                               % 0 < g1
        V_g1stg0m05 = g1 < (-0.5 .* g0);   % g1 < -0.5 .* g0 && g0 < 0 && 0 < g1
        V_zone3_b = V_g0st0 + V_g1gt0 + V_g1stg0m05;
        V_zone3_b = V_zone3_b == 3; 
        V_zone3 = V_zone3_a + V_zone3_b;
        V_zone1_3 = V_zone1 + V_zone2 + V_zone3; 
        V_zone4 = V_zone1_3 == 0;
       % V_komplett = [ V_zone1 , V_zone2 , V_zone3 , V_zone4 ]

      %zone (i)
          G_1 = g0 .* (x - 2 * x .^ 2 + x ^ 3) + g1 .* (-x .^ 2 + x .^ 3);

      %zone (ii)   
          eta_2 = (g1 + 2 .* g0) ./ (g1 - g0);
          V_G_2 = eta_2  >= x;
            G_2_a = g0 .* x;
            G_2_b = g0 .* x + (g1 - g0) .* (x - eta_2) .^ 3 ./ (1 - eta_2) ...
                    .^ 2 ./ 3;
          G_2 = V_G_2 .* G_2_a + ~V_G_2 .* G_2_b;         

      %zone (iii)
          eta_3 = 3 .* g1 ./ (g1 - g0);
          V_G_3 = eta_3  > x;
            G_3_a = g1 .* x - 1 ./ 3 .* (g0 - g1) .* ((eta_3 - x) .^ 3 ...
                    ./ eta_3 .^ 2 - eta_3);
            G_3_b = (2 ./ 3 .* g1 + 1 ./ 3 .* g0) .* eta_3 + g1 .* (x - eta_3);
          G_3 = V_G_3 .* G_3_a + ~V_G_3 .* G_3_b;

      %zone (iv)
          eta_4 = g1 ./ (g1 + g0);
          A = -g0 .* g1 ./ (g0 + g1);
          V_G_4 = eta_4  >=  x;
            G_4_a = A .* x - 1 ./ 3 .* (g0 - A) .* ((eta_4 - x) .^ 3 ...
                    ./ eta_4 .^ 2 - eta_4);
            G_4_b = (2 ./ 3 .* A + 1 ./ 3 .* g0) .* eta_4 + A .* (x - eta_4) ...
                    + (g1 - A) ./ 3 .* (x - eta_4) .^ 3 ./ (1 - eta_4) .^ 2;
          G_4 = V_G_4 .* G_4_a + ~V_G_4 .* G_4_b;
          G_4(isnan(G_4)) = 0; 
          
    G = G_1 .* V_zone1 + G_2 .* V_zone2 + G_3 .* V_zone3 + G_4 .* V_zone4;
    % replace values with 0 where g0 or g1 == 0
    G(g0==0) = 0;
    G(g1==0) = 0;
    
    if x == 0 || x == 1 
      G = 0;
    end
    %(12)
    Interpolant_Value = 1 ./ Term .* (Terms(i) .* dInterpolantatNode(:,i) ...
                        + (Term - Terms(i)) .* fdiscrete(:,i + 1) ...
                        + (Terms(i + 1) - Terms(i)) .* G);
  end
end

function Forward = CalcForward(Term,Terms,f,fdiscrete)
  %numbering refers to Wilmott paper
  if Term <= 0 
    Forward = f(:,1);
  elseif Term > max(Terms) 
    Forward = CalcForward(max(Terms),Terms,f,fdiscrete);
  else
    if ( Term == max(Terms))
        i = length(Terms) -1 ;
    else
        i = lookup(Terms,Term);
    end
    %the x in (25)
    x = (Term - Terms(i)) / (Terms(i + 1) - Terms(i));
    g0 = f(i) - fdiscrete(i + 1);
    g1 = f(i + 1) - fdiscrete(i + 1);
    ZZ = zeros(length(g0),1);
    V_g0st0 = zeros(length(g0),1);
    V_g1st0 = zeros(length(g0),1);
    V_g0st0 = g0<ZZ;
    V_g0gt0 = g0>ZZ;
    V_g1st0 = g1<ZZ;
    V_g1gt0 = g1>ZZ;
    % conditions for zone 1:
      % the following three conditions have all to be fulfilled:
        V_g1geg0m05 = g1 >= (-0.5 .* g0);        %  0.5 .* g0 <= g1
        V_g1seg0m2 = g1 <= (-2 .* g0);           % g1 <= -2 .* g0
        %V_g0st0;                        % g0 < 0
        V_zone1_a = V_g1geg0m05 + V_g1seg0m2 + V_g0st0;
        V_zone1_a = V_zone1_a == 3;
        % then
        G = g0 .* (x - 2 * x .^ 2 + x ^ 3) + g1 .* (-x .^ 2 + x .^ 3);
      % or the following three conditions have all to be fulfilled:
        %V_g0gt0 ;                                % g0 > 0
        V_g1seg0m05 = g1 <= (-0.5 .* g0);        % -0.5 .* g0 >= g1
        V_g1geg0m2 = g1 >= (-2 .* g0);           % g1 >= -2 .* g0
        V_zone1_b = V_g1seg0m05 + V_g1geg0m2 + V_g0gt0;
        V_zone1_b = V_zone1_b == 3;
        V_zone1 = V_zone1_a + V_zone1_b;
    % conditions for zone 2:
        % the following two conditions have all to be fulfilled:
        V_g0st0;                                 % g0 < 0
        V_g1gtg0m2 = g1 > (-2 .* g0);            % g1 > -2 .* g0
        V_zone2_a = V_g0st0 + V_g1gtg0m2;
        V_zone2_a = V_zone2_a == 2;
        % or the following two conditions have all to be fulfilled:
        V_g0gt0;                                % g0 > 0
        V_g1stg0m2 = g1 < (-2 .* g0);           % g1 < -2 .* g0
        V_zone2_b = V_g0gt0 + V_g1stg0m2;
        V_zone2_b = V_zone2_b == 2;
        V_zone2 = V_zone2_a + V_zone2_b;
    % conditions for zone 3:   
        % a)
        %V_g0gt0                                 g0 > 0
        %V_g1st0                                 0 > g1
        V_g1gtg0m05 = g1 > (-0.5 .* g0);        % g1 > -0.5 .* g0   
        V_zone3_a = V_g0gt0 + V_g1st0 + V_g1gtg0m05;
        V_zone3_a = V_zone3_a == 3;
        % b)
        % V_g0st0                               % g0 < 0
        % V_g1gt0                               % 0 < g1
        V_g1stg0m05 = g1 < (-0.5 .* g0);       % g1 < -0.5 .* g0
        V_zone3_b = V_g0st0 + V_g1gt0 + V_g1stg0m05;
        V_zone3_b = V_zone3_b == 3; 
        V_zone3 = V_zone3_a + V_zone3_b;
        V_zone1_3 = V_zone1 + V_zone2 + V_zone3; 
        V_zone4 = V_zone1_3 == 0;
        
    if x == 0 
      G = g0;
    elseif x == 1 
      G = g1;
    else
      %zone (i)
         G_1 = g0 .* (1 - 4 .* x + 3 .* x .^ 2) + g1 .* (-2 .* x + 3 .* x .^ 2);

      %zone (ii)   
          eta_2 = (g1 + 2 .* g0) ./ (g1 - g0);
          V_G_2 = eta_2  >= x;
            G_2_a = g0;
            G_2_b = g0 + (g1 - g0) .* ((x - eta_2) ./ (1 - eta_2)) .^ 2;
          G_2 = V_G_2 .* G_2_a + ~V_G_2 .* G_2_b;         

      %zone (iii)
          eta_3 = 3 .* g1 ./ (g1 - g0);
          V_G_3 = eta_3  > x;
            G_3_a = g1 + (g0 - g1) .* ((eta_3 - x) ./ eta_3) .^ 2;
            G_3_b =  g1;
          G_3 = V_G_3 .* G_3_a + ~V_G_3 .* G_3_b;

      %zone (iv)
          eta_4 = g1 ./ (g1 + g0);
          A = -g0 .* g1 ./ (g0 + g1);
          V_G_4 = eta_4  >=  x;
            G_4_a = A + (g0 - A) .* ((eta_4 - x) ./ eta_4) .^ 2;
            G_4_b = A + (g1 - A) .* ((eta_4 - x) ./ (1 - eta_4)) .^ 2;
          G_4 = V_G_4 .* G_4_a + ~V_G_4 .* G_4_b;
       
       G = G_1 .* V_zone1 + G_2 .* V_zone2 + G_3 .* V_zone3 + G_4 .* V_zone4;
    end
    % replace NaN values with 0
    
    G(g0==0) = 0;
    G(g1==0) = 0;
    %(26)
    Forward = G + fdiscrete(i + 1);
  end
end

function [f, fdiscrete, dInterpolantatNode] = fi_estimates(Terms, Values, ...
                                    InputsareForwards,Negative_Forwards_Allowed)
  %extend the curve to time 0, for the purpose of calculating forward at time 1

  %step 1: equation 14
  N = columns(Terms);
  ZZ = zeros(rows(Values),1);
  
  % Providing Matlab Compatibility (no automatic broadcasting in Matlab)
  % uncomment the following line:
  % Terms = repmat(Terms,rows(Values),1);
  
  if InputsareForwards == 0
    fdiscrete = ( Terms(:,2:end) .* Values(:,2:end) - Terms(:,1:end-1) ...
                .* Values(:,1:end-1) ) ./ ( Terms(:,2:end) - Terms(:,1:end-1));
    dInterpolantatNode = Values;
    fdiscrete = [ZZ,fdiscrete];
  else
    termrate = 0
    for j = 2 : 1 :  columns(Terms) - 1
      fdiscrete(:,j) = Values(:,j);
      termrate = termrate + fdiscrete(:,j) .* (Terms(:,j) - Terms(:,j - 1));
      dInterpolantatNode(:,j) = termrate ./ Terms(:,j);
    end
  end
    %f_i estimation under the unameliorated method
    %numbering refers to Wilmott paper
    f = zeros(rows(Values),columns(Values));
    %step 2
    %(22)
    for j = 2 : 1 :  columns(Terms) - 1
        f(:,j) = (Terms(:,j) - Terms(:,j - 1)) ./ (Terms(:,j + 1) ...
                - Terms(:,j - 1)) .* fdiscrete(:,j + 1) + (Terms(:,j + 1) ...
                - Terms(:,j)) ./ (Terms(:,j + 1) - Terms(:,j - 1)) ...
                .* fdiscrete(:,j);
    end
    %(23)
    f(:,1) = fdiscrete(:,2) - 0.5 .*( f(:,2) - fdiscrete(:,2));
    %(24)
    f(:,end) = fdiscrete(:,end) - 0.5 .* (f(:,end-1) - fdiscrete(:,end));
    %step 3
    if Negative_Forwards_Allowed == 0 
      f(:,1) = bound(0, f(:,1), 2 * fdiscrete(:,1));
      for j = 2 : 1 :  columns(Terms) - 1
        f(:,j) = bound(0, f(:,j), 2 * min(fdiscrete(:,j), fdiscrete(:,j + 1)));
      end
      f(:,end) = bound(0, f(:,end), 2 * fdiscrete(:,end));
    end
    
end

% Helper Function Bound
function ret = bound(Minimum,Variable,Maximum)
  if Variable < Minimum 
    ret = Minimum;
  elseif Variable > Maximum 
    ret = Maximum;
  else
    ret = Variable;
  end
end

% ----------------------------------------------------------------------
%          Main functions for Smith-Wilson Interpolation
% ----------------------------------------------------------------------
% This implementation is based on the explanations in the Paper: FINANSTILSYNET,
% 'A Technical Note on the Smith-Wilson Method' by 'The Financial Supervisory 
% Authority of Norway', 2010 and 'QIS 5 Risk-free interest rates – 
% Extrapolation method', published by CEIOPS (now EIOPA).
% The values from CEIOPS Excel sheet have been validated.
% (ceiops-tool-extrapolation-risk-free-rates2_en)
%
% Be aware of singularities in extreme events. Take into account of increasing 
% alpha in that cases.
% See http://staff.math.su.se/andreas/smith_wilson_final.pdf: 
% 'Issues with the Smith-Wilson method' by Andreas Lager and Mathias Lindholm

% Wilson function
function W = Wilson_function(t,u,ufrc,alpha)
    ma = max(t,u);
    mi = min(t,u);
    tmp_a_mi = alpha .* mi;
    W = exp(-ufrc .* (t + u)) .* ( tmp_a_mi - 0.5 .* exp(-alpha.*ma) ...
        .* ( 2*sinh(tmp_a_mi) ) );
end

% function for calculating new discount rates 
function [P, R] = interpolate_smith_wilson(tt,rates_input,nodes_input_y, ...
                                            ufrc,alpha)
    % transpose input vectors if necessary
        if rows(tt) < columns(tt)
            tt = tt';
        end
        if rows(nodes_input_y) < columns(nodes_input_y)
            nodes_input_y = nodes_input_y';
        end
    % transpose rates input matrix (each vector rates(nodes) per scenario has 
    % to be in columns)
            rates_input = rates_input';        
    % checking for nodes_input to be in years instead of days
        if ( max(nodes_input_y) > 120)
            %disp('WARNING: Nodes_input seems to be defined in days, 
            % converting to years...')
            nodes_input_y = nodes_input_y ./365;
            tt = tt ./ 365;
        end
        
    % Calculate chi via solving linear equations  
        % 1. calculate vector mu and m
        mu = exp(- ufrc .* nodes_input_y);
        % fast implementation of: m  = exp(-log(1+rates_input) .* nodes_input_y) 
        m = (1+rates_input).^(-nodes_input_y);
        
        % 2. calculate matrix W (size length(rates)^2)
        [X,Y] = meshgrid(nodes_input_y,nodes_input_y);
        W = Wilson_function(X,Y,ufrc,alpha);
        d_vec = (m - mu);
        
        % 3. calculate vector chi: solving set of linear equaitons: 
        chi = W\d_vec;  % solve equation system
        
    % calculate discount rate and discount factor
        [X,Y] = meshgrid(nodes_input_y,tt);     % set up meshgrid
        WW = Wilson_function(X,Y,ufrc,alpha); 
        M = chi' .* WW;
        S = sum(M,2);

    % Return discount factor and discount rates
        P = exp(-ufrc*tt) + S;
        % set discount factors to positive values, 
        % anyway there will be singularities...
        P(P<0) = eps;
        R = -log(P) ./tt;
        if ~(isreal(R))
           error('interpolate_smith_wilson: R vector not real. Singularities detected.');    
        end
    % Return continuous compounded rates
        R = exp(R)-1;
end


%!assert(interpolate_curve ([365,730,1095], [0.01,0.02,0.025;0.015,-0.02,0.04], 433, 'monotone-convex' ),[0.012116882;0.007318077],0.000001)
%!assert(interpolate_curve ([365,730,1095], [0.01,0.02,0.025;0.015,-0.02,0.04], 433, 'smith-wilson',0.05,0.12),[0.01201874447087881;0.00145313313347883],0.000000001)
%!assert(interpolate_curve ([365,730,1095], [0.01,0.02,0.025;0.015,-0.02,0.04], 433, 'linear'),[0.01186301;0.00847945],0.000001)
%!assert(interpolate_curve ([-365,-730,-1095], [0.01,0.02,0.025;0.015,-0.02,0.04], -433, 'linear'),[0.0118630;0.0084795],0.000001)
%!assert(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'linear'),0.004927301319,0.0000000001)
%!assert(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'mm'),0.00494794483,0.0000000001)
%!assert(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'exponential'),0.004927396730,0.0000000001)
%!assert(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'constant'),0.0045624391,0.0000000001)
%!assert(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'previous'),0.0045624391,0.0000000001)
%!assert(interpolate_curve ([365,730,1825,3650,4015], [0.0001002070,0.0001001034,0.0001000962,0.0045624391,0.0054502705], 3800, 'next'),0.0054502705,0.0000000001)



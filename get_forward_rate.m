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
%# @deftypefn {Function File} {@var{forward_rate}=} 
%# get_forward_rate(@var{nodes}, @var{rates}, @var{days_to_t1}, 
%# @var{days_to_t2}, @var{comp_type}, @var{interp_method}, @var{comp_freq})
%# Compute the forward rate calculated from interpolated rates from a zero 
%# coupon yield curve. CAUTION: the forward rate is floored to 0.000001.
%# Explanation of Input Parameters:
%# @*
%# @itemize @bullet
%# @item @var{nodes}: is a 1xN vector with all timesteps of the given curve
%# @item @var{rates}: is MxN matrix with curve rates defined in columns. Each 
%# row contains a specific scenario with different curve structure
%# @item @var{days_to_t1}: is a scalar, specifiying term1 in days
%# @item @var{days_to_t2}: is a scalar, specifiying term2 in days after term1
%# @item @var{comp_type}: (optional) specifies compounding rule (simple, 
%# discrete, continuous (defaults to 'cont')).
%# @item @var{interp_method}: (optional) specifies interpolation method for 
%# retrieving interest rates (defaults to 'linear').
%# @end itemize
%# @seealso{interpolate_curve}
%# @end deftypefn

function forward_rate = get_forward_rate(nodes,rates,days_to_t1,days_to_t2, ...
                                            comp_type,interp_method,comp_freq)
 
 if nargin < 4 || nargin > 7
    print_usage ();
 end
 
% default continuous compounding and interpolation method
if nargin < 5
   comp_type = 'cont';
   interp_method = 'linear';
   comp_freq = 1;
end
if nargin < 6
   interp_method = 'linear';
   comp_freq = 1;
end
if nargin < 7
   comp_freq = 1;
end

% Checks:
if ~isnumeric (days_to_t1)
    error ('days_to_t1 must be numeric ')
elseif ~isnumeric (days_to_t2)
    error ('days_to_t2 must be numeric ')
elseif days_to_t1 <= 0
    error ('days_to_t1 must be positive ')
elseif days_to_t2 <= 0
    error ('days_to_t2 must be positive ')        
end
no_scen_nodes = columns(nodes);
no_scen_rates = columns(rates); 
if ( no_scen_nodes ~= no_scen_rates )
    disp('Number of columns of nodes and rates must be equivalent');
end

if ( issorted(nodes) ~= 1)
    disp('Nodes have to be sorted')
end 

% Get compounding type:
if ischar(comp_type)
    if ( strcmp(lower(comp_type),'simple') == 1 )
        compounding_type = 1;
    elseif ( strcmp(lower(comp_type),'disc') == 1 )
        compounding_type = 2;
    elseif ( strcmp(lower(comp_type),'cont') == 1 )
        compounding_type = 3;
    else
        error('Need valid comp_type type [disc, simple, cont]')
    end
end
% Start Calculation
% Get rates at timesteps1 / 2
r1 = interpolate_curve(nodes,rates,days_to_t1,interp_method);
r2 = interpolate_curve(nodes,rates,(days_to_t2 + days_to_t1),interp_method);
% Get time length between today and timesteps (in years)
d1 = days_to_t1 ./ 365 ;
d2 = (days_to_t2 + days_to_t1 ) ./ 365;

% 3 cases
if ( compounding_type == 1)      % simple
    tmp_rate = ((( 1 + (r2 .* d2)) ./ ( 1 + (r1 .* d1) ) ) - 1 ) ./ ( d2 - d1 );
elseif ( compounding_type == 2)      % discrete
    tmp_rate = (  ( 1 + (r2 ./ comp_freq) ).^(comp_freq * d2) ...
                ./ ( 1 + (r1 ./ comp_freq) ).^(comp_freq * d1) ) ...
                .^(1 ./ (d2 - d1)) - 1;
elseif ( compounding_type == 3)      % continuous
    tmp_rate = ( r2 .* d2 - r1 .* d1  ) ./ (  d2 - d1 );
end

% Return forward rate:	% flooring rate!!!
forward_rate = max(tmp_rate,0.000001);
end

%!assert(get_forward_rate([365,1825,3650],[0.05,0.06,0.065],1825,1095,'disc','linear',2),0.0691669,0.00001)
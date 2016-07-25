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
%# @deftypefn {Function File} {@var{forward_rate}=} get_forward_rate(@var{nodes}, @var{rates}, @var{days_to_t1}, @var{days_to_t2}, @var{comp_type}, @var{interp_method}, @var{comp_freq},, @var{basis}, @var{valuation_date}, @var{comp_type_curve}, @var{basis_curve}, @var{comp_freq_curve} )
%#
%# Compute the forward rate calculated from interpolated rates from a  
%# yield curve. CAUTION: the forward rate is floored to 0.000001.
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
%# @item @var{comp_freq}: (optional) compounding frequency (default: annual)
%# @item @var{basis}: (optional) day count convention of instrument (default: act/365)
%# @item @var{valuation_date}: (optional) valuation date (default: today)
%# @item @var{comp_type_curve}: (optional) compounding type of curve
%# @item @var{basis_curve}: (optional) day count convention of curve
%# @item @var{comp_freq_curve}: (optional) compounding frequency of curve
%# @end itemize
%# @seealso{interpolate_curve, convert_curve_rates,timefactor}
%# @end deftypefn

function forward_rate = get_forward_rate(nodes, rates, days_to_t1, days_to_t2, ...
                       comp_type, interp_method, comp_freq, basis, valuation_date, ...
                       comp_type_curve, basis_curve, comp_freq_curve)
 
 if nargin < 4 || nargin > 12
    print_usage ();
 end


 
% default continuous compounding and interpolation method
if nargin < 5
   comp_type = 'cont';
   interp_method = 'linear';
   comp_freq = 1;
   valuation_date = today;
   basis = 3;   %act/365
   comp_type_curve  = comp_type;
   basis_curve      = basis; 
   comp_freq_curve  = comp_freq;
elseif nargin == 5
   interp_method = 'linear';
   comp_freq = 1;
   valuation_date = today;
   basis = 3;   %act/365
   comp_type_curve  = comp_type;
   basis_curve      = basis; 
   comp_freq_curve  = comp_freq;
elseif nargin == 6
   comp_freq = 1;
   valuation_date = today;
   basis = 3;   %act/365
   comp_type_curve  = comp_type;
   basis_curve      = basis; 
   comp_freq_curve  = comp_freq;
elseif nargin == 7
   valuation_date = today;
   basis = 3;   %act/365
   comp_type_curve  = comp_type;
   basis_curve      = basis; 
   comp_freq_curve  = comp_freq;
elseif nargin == 8
   valuation_date = today;
   comp_type_curve  = comp_type;
   basis_curve      = basis; 
   comp_freq_curve  = comp_freq;
elseif nargin == 9
   comp_type_curve  = comp_type;
   basis_curve      = basis; 
   comp_freq_curve  = comp_freq;
elseif nargin == 10
   basis_curve      = basis; 
   comp_freq_curve  = comp_freq;
elseif nargin == 11
   comp_freq_curve  = comp_freq;   
end

% convert valuation date to datenum
if ischar(valuation_date) || (length(valuation_date) > 1)
   valuation_date = datenum(valuation_date);
end

if ischar(days_to_t1) || (length(days_to_t1) > 1)
   days_to_t1 = datenum(days_to_t1) - valuation_date;
end

if ischar(days_to_t2) || (length(days_to_t2) > 1)
   days_to_t2 = datenum(days_to_t2) - valuation_date;
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
    if ( strcmpi(comp_type,'simple') )
        compounding_type = 1;
    elseif ( strcmpi(comp_type,'disc'))
        compounding_type = 2;
    elseif ( strcmpi(comp_type,'cont')  || strcmpi(comp_type,'continuous') )
        compounding_type = 3;
    else
        error('Need valid comp_type type [disc, simple, cont]')
    end
end

% error check compounding frequency
if ischar(comp_freq)
    if ( strcmpi(comp_freq,'daily') || strcmpi(comp_freq,'day'))
        compounding = 365;
    elseif ( strcmpi(comp_freq,'weekly') || strcmpi(comp_freq,'week'))
        compounding = 52;
    elseif ( strcmpi(comp_freq,'monthly') || strcmpi(comp_freq,'month'))
        compounding = 12;
    elseif ( strcmpi(comp_freq,'quarterly')  ||  strcmpi(comp_freq,'quarter'))
        compounding = 4;
    elseif ( strcmpi(comp_freq,'semi-annual'))
        compounding = 2;
    elseif ( strcmpi(comp_freq,'annual') )
        compounding = 1;       
    else
        error('Need valid compounding frequency')
    end
else
    compounding = comp_freq;
end
% Start Calculation
% Get rates at timesteps1 / 2
r1_curve = interpolate_curve(nodes,rates,days_to_t1,interp_method);
r2_curve = interpolate_curve(nodes,rates,(days_to_t2 + days_to_t1),interp_method);
% convert interpolated rates from curve convention to instrument convention
% Get time length between valuation date and timesteps (in years)
r1 = convert_curve_rates(valuation_date,days_to_t1,r1_curve, ...
                        comp_type_curve,comp_freq_curve,basis_curve, ...
                        comp_type,compounding,basis);
r2 = convert_curve_rates(valuation_date,(days_to_t2 + days_to_t1),r2_curve, ...
                        comp_type_curve,comp_freq_curve,basis_curve, ...
                        comp_type,compounding,basis);                     
% calculate timefactor   
d1 = timefactor (valuation_date,(days_to_t1 + valuation_date),basis);
d2 = timefactor (valuation_date,(days_to_t1 + days_to_t2 + valuation_date),basis);

% 3 cases
if ( compounding_type == 1)      % simple
    tmp_rate = ((( 1 + (r2 .* d2)) ./ ( 1 + (r1 .* d1) ) ) - 1 ) ./ ( d2 - d1 );
elseif ( compounding_type == 2)      % discrete
    tmp_rate = (  ( 1 + (r2 ./ compounding) ).^(compounding * d2) ...
                ./ ( 1 + (r1 ./ compounding) ).^(compounding * d1) ) ...
                .^(1 ./ (d2 - d1)) - 1;
elseif ( compounding_type == 3)      % continuous
    tmp_rate = ( r2 .* d2 - r1 .* d1  ) ./ (  d2 - d1 );
end

% Return forward rate:	% flooring rate!!!
forward_rate = max(tmp_rate,0.000001);
end

%!assert(get_forward_rate([365,1825,3650],[0.05,0.06,0.065],1825,1095,'disc','linear',2),0.0691669,0.00001)
%!assert(get_forward_rate([365,1825,3650],[0.06,0.06,0.06],1825,1095,'cont','linear'),0.060000,0.00001)
%!assert(get_forward_rate([365,1825,3650],[0.05,0.06,0.065],1825,1095,'disc','linear',2,3),0.0691669,0.00001)
%!assert(get_forward_rate([365,1825,3650],[0.05,0.06,0.065],1825,1095,'disc','linear',2,0),0.0691636237,0.00001)
%!assert(get_forward_rate([730,4380],[0.0023001034,0.0084599362],'31-Mar-2018','28-Mar-2028','disc','linear',1,3,'31-Mar-2016'),0.0094902,0.00001)
%!assert(get_forward_rate([365,1095,1825,3650,7300,10950,21900],[-0.0051925,-0.0050859,-0.0036776,0.0018569,0.0077625,0.0099999,0.0012300],155,365,'disc','monotone-convex', 'daily', 'act/365', 736329, 'cont', 'act/365', 'annual'),0.000001)

%# Copyright (C) 2016 Schinzilord <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{rate}] =} getCapFloorRate (@var{CapFlag}, @var{F}, @var{X}, @var{tf}, @var{sigma}, @var{model})
%#
%# Compute the forward rate of caplets or floorlets according to Black, Normal or
%# analytical calculation formulas.
%#
%# Input and output variables:
%# @itemize @bullet
%# @item @var{CapFlag}: model (Black, Normal) [required] 
%# @item @var{F}: forward rate (annualized) [required] 
%# @item @var{X}: strike rate (annualized) [required] 
%# @item @var{tf}: time factor until forward start date (in days) [required] 
%# @item @var{sigma}: swap volatility according to tenor, term and moneyness (act/365 continuous)[required] 
%# @item @var{model}: model (Black, Normal, Analytical) [required]
%# @item @var{rate}: OUTPUT: adjusted forward rate
%# @end itemize
%#
%# For Black model, the following formulas are applied:
%# @example
%# @group
%# Caplet_rate = (F*N( d1) - X*N( d2))
%# Floorlet_rate = (X*N(-d2) - F*N(-d1))
%# d1 = (log(F/X) + (0.5*sigma^2)*T)/(sigma*sqrt(tf))
%# d2 = d1 - sigma*sqrt(tf)
%# @end group
%# @end example
%# @*
%# For Normal model, the following formulas are applied:
%# @example
%# @group
%# Caplet_rate = (F - X) * normcdf(d)  + sigma*sqrt(tf) * normpdf(d)
%# Floorlet_rate = (X - F) * normcdf(-d) + sigma*sqrt(tf) * normpdf(d)
%# d = (F - X) / (sigma*sqrt(tf));
%# @end group
%# @end example
%# @*
%# For analytical model, the following formulas are applied:
%# @example
%# @group
%# Caplet_rate = max(0, F - X);
%# Floorlet_rate = max(0, X - F);
%# @end group
%# @end example
%# @*
%# @seealso{swaption_bachelier, swaption_black76}
%# @end deftypefn

function rate = getCapFloorRate(CapFlag, F, X, tf, sigma, model)

% Error and input checks
 if nargin < 6 || nargin > 6
    print_usage ();
 end
 
if ~isnumeric(F)
    error('getCapFloorRate: Forward rate F is not a valid number')
end
if ~isnumeric(X)
    error('getCapFloorRate: Strike rate X is not a valid number')
end
if ~isnumeric(sigma) || sigma < 0
    error('getCapFloorRate: Volatility sigma is not a valid number')
end

% model dependent calculation
if (strcmpi(model,'Black') && X > 0.0 && sigma > 0.0)  % Black model only if X positive
    if ( F < 0 )
        error ('getCapFloorRate: forward rate in Black model is negative. Use normal model instead.');
    end
    d1 = (log(F./X) + 0.5.*(sigma.^2).*tf)./(sigma.*sqrt(tf));
    d2 = d1 - sigma.*sqrt(tf);
    if (CapFlag == true)
        N1 = 0.5.*(1+erf(d1./sqrt(2)));
        N2 = 0.5.*(1+erf(d2./sqrt(2)));
        rate = (F.*N1 - X.*N2);
    else
        N1 = 0.5.*(1+erf(-d1./sqrt(2)));
        N2 = 0.5.*(1+erf(-d2./sqrt(2)));
        rate = (X.*N2 - F.*N1);
    end
elseif (strcmpi(model,'Normal'))
    d = (F - X) ./ (sigma*sqrt(tf));
    const = 1 / sqrt(2*pi);
    pdf_d = const*exp(-d.^2 /2);
    if (CapFlag == true)
        rate = (F - X) .* 0.5.*(1+erf(d./sqrt(2)))  + sigma*sqrt(tf) .* pdf_d;
    else
        rate = (X - F) .* 0.5.*(1+erf(-d./sqrt(2))) + sigma*sqrt(tf) .* pdf_d;
    end
% analytical model: just compare forward rates with strike rate
else
    if  (CapFlag == true)
        rate = max(0, F - X);
    else
        rate = max(0, X - F);
    end
end

end

%!assert(getCapFloorRate(true, 0.07, 0.08, 1, 0.2, 'Black'),0.00225173676171655,0.000000001);
%!assert(getCapFloorRate(true, 0.0100501671, 0.0, 4, 0.0, 'Black'),0.0100501671,0.000000001);
%!assert(getCapFloorRate(true, 0.0100501671, 0.005, 4, 0.0, 'Black'),0.00505016710000000,0.000000001);
%!assert(getCapFloorRate(true, 0.0102421687, 0.005, 3, 0.8, 'Black'),0.00693193486314,0.000000001);
%!assert(getCapFloorRate(true, 0.0103061692, 0.005, 4, 0.8, 'Black'),0.00740148444016,0.000000001);
%!assert(getCapFloorRate(true, 0.0103061692, 0.005, 4, 0.8, 'Black'),0.0074015,0.00001);
%!assert(getCapFloorRate(true, 0.0103061692, 0.005, 4, 0.8, 'Normal'),0.64096,0.00001);
%!assert(getCapFloorRate(true, 0.0103061692, 0.005, 4, 0.0026, 'Normal'),0.0057228,0.00001);
%!assert(getCapFloorRate(true, 0.0103061692, 0.005, 4, 0.003, 'Normal'),0.0059262,0.00001);
%!assert(getCapFloorRate(false, 0.0103061692, 0.005, 4, 0.003, 'Normal'),6.2005e-004,0.00001);
%!assert(getCapFloorRate(false, 0.0103061692, 0.02, 4, 0.003, 'Normal'),0.0098282,0.00001);
%!assert(getCapFloorRate(false, 0.0103061692, 0.02, 4, 0.003, 'Analytic'),0.0096938,0.00001);
%!assert(getCapFloorRate(true, 0.0103061692, 0.02, 4, 0.003, 'Analytic'),0.0,0.00001);
%!assert(getCapFloorRate(true, 0.0103061692, 0.01, 4, 0.003, 'Analytic'),3.0617e-004,0.00001);
%!assert(getCapFloorRate(true, [0.01;0.015], 0.01, 4, 0.003, 'Normal'),[0.0023937;0.0056798],0.00001);
%!assert(getCapFloorRate(true, [0.01;0.015], 0.01, 4, 0.003, 'Black'),[2.3937e-005;5.0000e-003],0.00001);
  
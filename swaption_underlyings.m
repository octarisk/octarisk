%# Copyright (C) 2015 Schinzilord <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{SwaptionValue}] =} swaption_underlyings (@var{PayerReceiverFlag}, @var{F}, @var{X}, @var{T}, @var{r}, @var{sigma}, @var{m}, @var{tau})
%#
%# Compute the price of european interest rate swaptions according to Black76 
%# or Normal pricing functions using underlying fixed and floating legs.
%# @seealso{swaption_bachelier, swaption_black76}
%# @end deftypefn

function value = swaption_underlyings(PayerReceiverFlag,K,V_fix,V_float,T,sigma,model)

 if nargin < 7 || nargin > 7
    print_usage ();
 end
   
% yearly fraction of days to maturity
T = T ./ 365;

% calculate Y
if (V_fix == 0.0 | K == 0.0)
    value = 0.0;
    fprintf('swaption_underlyings: WARNING: V_fix or Strike K is zero. Returning value of 0.0.\n');
    return
end
Y = K .* V_float ./ V_fix;

% distinguish swaption models Black and Bachelier (normal)
if regexpi(model,'black')
    d1 = (log(Y./K) + (0.5.*sigma.^2).*T)./(sigma.*sqrt(T));
    d2 = d1 - sigma.*sqrt(T);
    % Calculation of Black Value
    if ( PayerReceiverFlag == 1 ) % Call / Payer swaption 'p'
        % cdf(d1) and cdf(d2):
        cdf_d1 = 0.5.*(1+erf(d1./sqrt(2)));
        cdf_d2 = 0.5.*(1+erf(d2./sqrt(2)));
        value = V_float .* cdf_d1 - V_fix .* cdf_d2;
    else   % Put / Receiver swaption 'r'  
        cdf_d1 = 0.5.*(1+erf(-d1./sqrt(2)));
        cdf_d2 = 0.5.*(1+erf(-d2./sqrt(2)));
        value = V_fix .* cdf_d2 - V_float .* cdf_d1;
    end
    
% normal (Bachelier) model
else
    % calculate h
    h = ( Y - K ) ./ (sigma.*sqrt(T));
    % cdf(h) and pdf(d2):
    cdf_h = 0.5.*(1+erf(h./sqrt(2)));
    const = 1 / sqrt(2*pi);
    pdf_h = const*exp(-h.^2 /2);
    % Calculation of Normal Value
    if ( PayerReceiverFlag == 1 ) % Call / Payer swaption 'p' 
        value = ((Y - K) .* cdf_h + sigma.*sqrt(T) .* pdf_h).* V_fix ./ K;
    else   % Put / Receiver swaption 'r'  
        value = ((K - Y) .* (1 - cdf_h) + sigma.*sqrt(T) .* pdf_h).* V_fix ./ K;
    end
end
  
end

%!assert(swaption_underlyings(1,0.045,46.7899579,-67.9538761,20*365,0.37656339,'normal'),642.686719385,0.00001);
%!assert(swaption_underlyings(0,0.045,46.7899579,-67.9538761,20*365,0.37656339,'normal'),757.4305534431,0.00001);
%!assert(swaption_underlyings(0,0.045,32.3765833727,20.9384249669,20*365,0.37656339,'Black76'),22.129888312,0.00001);
%!assert(swaption_underlyings(1,0.045,32.3765833727,20.9384249669,20*365,0.37656339,'Black76'),10.6917298255,0.00001);
%!assert(swaption_underlyings(1,0.045,60.67807934,-100.3388047,20*365,0.37656339,'normal'),827.6726714,0.00001);
%!assert(swaption_underlyings(1,0.045,[46.7899579039261;60.6780793433123;60.6780793433123],[-67.9538761540364;-100.3388047;-127.3307164296483],20*365,[0.37656339;0.37656339;0.37656339],'normal'),[642.686721676861;827.672674337209;815.003458189566],0.00001);
%!assert(swaption_underlyings(0,0.045,[46.7899579039261;60.6780793433123;60.6780793433123],[-67.9538761540364;-100.3388047;-127.3307164296483],20*365,[0.37656339;0.37656339;0.37656339],'normal'),[757.430552032598;988.689553597680;1003.012249167557],0.00001);

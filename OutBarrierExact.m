function [optionValue] = OutBarrierExact(S0, H, X, Rebate, T, sigma, r, q, PutOrCall, UpOrDown)

% function [optionValue] = OutBarrierExact(S0, H, X, Rebate, T, sigma, r, q, PutOrCall, UpOrDown)
%
% inputs:
% S0 - spot
% H - barrier
% X - strike
% Rebate - payout received on knockout
% T - time to maturity
% sigma - volatility
% r - risk-free interest rate
% q - dividend rate
% PutOrCall - 0 for call, 1 for put
% UpOrDown - 'U' or 'D'
%
% output:
% optionValue

b = r - q;

%

mu = (b-sigma^2/2)/(sigma^2);

lambda = sqrt(mu^2+2*r/(sigma^2));

%

x1 = log(S0./X)./(sigma*sqrt(T)) + (1+mu)*sigma*sqrt(T);

x2 = log(S0./H)./(sigma*sqrt(T)) + (1+mu)*sigma*sqrt(T);

%

y1 = log((H^2)./(S0.*X))./(sigma*sqrt(T)) + (1+mu)*sigma*sqrt(T);

y2 = log(H./S0)./(sigma*sqrt(T)) + (1+mu)*sigma*sqrt(T);

%

z = log(H./S0)./(sigma*sqrt(T)) + lambda*sigma*sqrt(T);

%

%Put

%

if UpOrDown == 'D'

   if (X > H)

      eta = +1;

      phi = -1;

      A = phi*S0.*exp((b-r)*T).*normcdf(phi*x1)                        - phi*X.*exp(-r*T).*normcdf(phi*x1-phi*sigma*sqrt(T));

      B = phi*S0.*exp((b-r)*T).*normcdf(phi*x2)                        - phi*X.*exp(-r*T).*normcdf(phi*x2-phi*sigma*sqrt(T));

      C = phi*S0.*exp((b-r)*T).*normcdf(eta*y1).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y1-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      D = phi*S0.*exp((b-r)*T).*normcdf(eta*y2).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y2-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      E = Rebate*exp(-r*T)*[ normcdf(eta*x2-eta*sigma*sqrt(T)) - ((H./S0).^(2*mu)).*normcdf(eta*y2-eta*sigma*sqrt(T)) ];

      F = Rebate*[((H./S0).^(mu+lambda)).*normcdf(eta*z)+((H./S0).^(mu-lambda)).*normcdf(eta*z-2*eta*lambda*sigma*sqrt(T))];

      %

      put = A - B + C - D + F;

   else

      eta = +1;

      phi = -1;

      A = phi*S0.*exp((b-r)*T).*normcdf(phi*x1)                        - phi*X.*exp(-r*T).*normcdf(phi*x1-phi*sigma*sqrt(T));

      B = phi*S0.*exp((b-r)*T).*normcdf(phi*x2)                        - phi*X.*exp(-r*T).*normcdf(phi*x2-phi*sigma*sqrt(T));

      C = phi*S0.*exp((b-r)*T).*normcdf(eta*y1).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y1-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      D = phi*S0.*exp((b-r)*T).*normcdf(eta*y2).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y2-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      E = Rebate*exp(-r*T)*[ normcdf(eta*x2-eta*sigma*sqrt(T)) - ((H./S0).^(2*mu)).*normcdf(eta*y2-eta*sigma*sqrt(T)) ];

      F = Rebate*[((H./S0).^(mu+lambda)).*normcdf(eta*z)+((H./S0).^(mu-lambda)).*normcdf(eta*z-2*eta*lambda*sigma*sqrt(T))];

      %

      put = F;

   end

elseif UpOrDown == 'U' 

   if (X > H)

      eta = -1;

      phi = -1;

      A = phi*S0.*exp((b-r)*T).*normcdf(phi*x1)                        - phi*X.*exp(-r*T).*normcdf(phi*x1-phi*sigma*sqrt(T));

      B = phi*S0.*exp((b-r)*T).*normcdf(phi*x2)                        - phi*X.*exp(-r*T).*normcdf(phi*x2-phi*sigma*sqrt(T));

      C = phi*S0.*exp((b-r)*T).*normcdf(eta*y1).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y1-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      D = phi*S0.*exp((b-r)*T).*normcdf(eta*y2).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y2-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      E = Rebate*exp(-r*T)*[ normcdf(eta*x2-eta*sigma*sqrt(T)) - ((H./S0).^(2*mu)).*normcdf(eta*y2-eta*sigma*sqrt(T)) ];

      F = Rebate*[((H./S0).^(mu+lambda)).*normcdf(eta*z)+((H./S0).^(mu-lambda)).*normcdf(eta*z-2*eta*lambda*sigma*sqrt(T))];

      %

      put = B - D + F;

   else

      eta = -1;

      phi = -1;

      A = phi*S0.*exp((b-r)*T).*normcdf(phi*x1)                        - phi*X.*exp(-r*T).*normcdf(phi*x1-phi*sigma*sqrt(T));

      B = phi*S0.*exp((b-r)*T).*normcdf(phi*x2)                        - phi*X.*exp(-r*T).*normcdf(phi*x2-phi*sigma*sqrt(T));

      C = phi*S0.*exp((b-r)*T).*normcdf(eta*y1).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y1-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      D = phi*S0.*exp((b-r)*T).*normcdf(eta*y2).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y2-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      E = Rebate*exp(-r*T)*[ normcdf(eta*x2-eta*sigma*sqrt(T)) - ((H./S0).^(2*mu)).*normcdf(eta*y2-eta*sigma*sqrt(T)) ];

      F = Rebate*[((H./S0).^(mu+lambda)).*normcdf(eta*z)+((H./S0).^(mu-lambda)).*normcdf(eta*z-2*eta*lambda*sigma*sqrt(T))];

      %

      put = A - C + F;

   end

end



%

%Call

%

if UpOrDown == 'D'

   if (X > H)

      eta = +1;

      phi = +1;

      A = phi*S0.*exp((b-r)*T).*normcdf(phi*x1)                        - phi*X.*exp(-r*T).*normcdf(phi*x1-phi*sigma*sqrt(T));

      B = phi*S0.*exp((b-r)*T).*normcdf(phi*x2)                        - phi*X.*exp(-r*T).*normcdf(phi*x2-phi*sigma*sqrt(T));

      C = phi*S0.*exp((b-r)*T).*normcdf(eta*y1).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y1-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      D = phi*S0.*exp((b-r)*T).*normcdf(eta*y2).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y2-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      E = Rebate*exp(-r*T)*[ normcdf(eta*x2-eta*sigma*sqrt(T)) - ((H./S0).^(2*mu)).*normcdf(eta*y2-eta*sigma*sqrt(T)) ];

      F = Rebate*[((H./S0).^(mu+lambda)).*normcdf(eta*z)+((H./S0).^(mu-lambda)).*normcdf(eta*z-2*eta*lambda*sigma*sqrt(T))];

      %

      call = A - C + F;

   else

      eta = +1;

      phi = +1;

      A = phi*S0.*exp((b-r)*T).*normcdf(phi*x1)                        - phi*X.*exp(-r*T).*normcdf(phi*x1-phi*sigma*sqrt(T));

      B = phi*S0.*exp((b-r)*T).*normcdf(phi*x2)                        - phi*X.*exp(-r*T).*normcdf(phi*x2-phi*sigma*sqrt(T));

      C = phi*S0.*exp((b-r)*T).*normcdf(eta*y1).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y1-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      D = phi*S0.*exp((b-r)*T).*normcdf(eta*y2).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y2-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      E = Rebate*exp(-r*T)*[ normcdf(eta*x2-eta*sigma*sqrt(T)) - ((H./S0).^(2*mu)).*normcdf(eta*y2-eta*sigma*sqrt(T)) ];

      F = Rebate*[((H./S0).^(mu+lambda)).*normcdf(eta*z)+((H./S0).^(mu-lambda)).*normcdf(eta*z-2*eta*lambda*sigma*sqrt(T))];

      %

      call = B - D + F;

   end

elseif UpOrDown == 'U'

   if (X > H)

      eta = -1;

      phi = +1;

      A = phi*S0.*exp((b-r)*T).*normcdf(phi*x1)                        - phi*X.*exp(-r*T).*normcdf(phi*x1-phi*sigma*sqrt(T));

      B = phi*S0.*exp((b-r)*T).*normcdf(phi*x2)                        - phi*X.*exp(-r*T).*normcdf(phi*x2-phi*sigma*sqrt(T));

      C = phi*S0.*exp((b-r)*T).*normcdf(eta*y1).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y1-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      D = phi*S0.*exp((b-r)*T).*normcdf(eta*y2).*((H./S0).^(2*(mu+1))) - phi*X.*exp(-r*T).*normcdf(eta*y2-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      E = Rebate*exp(-r*T)*[ normcdf(eta*x2-eta*sigma*sqrt(T)) - ((H./S0).^(2*mu)).*normcdf(eta*y2-eta*sigma*sqrt(T)) ];

      F = Rebate*[((H./S0).^(mu+lambda)).*normcdf(eta*z)+((H./S0).^(mu-lambda)).*normcdf(eta*z-2*eta*lambda*sigma*sqrt(T))];

      %

      call = F;

   else

      eta = -1;

      phi = +1;

      A = phi*S0.*exp((b-r)*T).*normcdf(phi*x1)                         - phi*X.*exp(-r*T).*normcdf(phi*x1-phi*sigma*sqrt(T));

      B = phi*S0.*exp((b-r)*T).*normcdf(phi*x2)                         - phi*X.*exp(-r*T).*normcdf(phi*x2-phi*sigma*sqrt(T));

      C = phi*S0.*exp((b-r)*T).*normcdf(eta*y1).*((H./S0).^(2*(mu+1)))  - phi*X.*exp(-r*T).*normcdf(eta*y1-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      D = phi*S0.*exp((b-r)*T).*normcdf(eta*y2).*((H./S0).^(2*(mu+1)))  - phi*X.*exp(-r*T).*normcdf(eta*y2-eta*sigma*sqrt(T)).*((H./S0).^(2*mu));

      E = Rebate*exp(-r*T)*[ normcdf(eta*x2-eta*sigma*sqrt(T)) - ((H./S0).^(2*mu)).*normcdf(eta*y2-eta*sigma*sqrt(T)) ];

      F = Rebate*[((H./S0).^(mu+lambda)).*normcdf(eta*z)+((H./S0).^(mu-lambda)).*normcdf(eta*z-2*eta*lambda*sigma*sqrt(T))];

      %

      call = A - B + C - D + F;

   end

end

if PutOrCall == 0

   optionValue = call;

elseif PutOrCall == 1

   optionValue = put;

end







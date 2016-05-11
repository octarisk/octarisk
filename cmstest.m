1;

clear all;

% Alternative calculation

y = 0.016738
q = 10
sigma_y = 0.12
n = 10
SR0 = y
notional = 1

    % get exponents for all cash flows
    G_exp = 1:1:n;
    Gd_exp = 2:1:n+1;
    Gdd_exp = 3:1:n+2;
    G_nominator = (SR0/q) .* ones(1,n) .* notional;
    G_nominator(end) = G_nominator(end) + notional;	% in case of cash flow notional at end
    G_denominator = (1 + y/q) .* ones(1,n);
    G_denominator_exp = G_denominator .^ G_exp;
    Gd_nominator = G_nominator .* (-G_exp)  ./ q;	% G_exp serves also as multiplikator, since it is just 1,2,3,...,n
    Gd_denominator = G_denominator .^ Gd_exp;
    Gdd_nominator = Gd_nominator .* (-Gd_exp)  ./ q;		% G_exp serves also as multiplikator, since it is just 1,2,3,...,n
    Gdd_denominator = G_denominator .^ Gdd_exp;
    fprintf('===new round ===\n');
    G = G_nominator ./ G_denominator_exp;
    G = sum(G)
    Gd = Gd_nominator ./ Gd_denominator;
    Gd = sum(Gd)
    Gdd = Gdd_nominator ./ Gdd_denominator;
    Gdd = sum(Gdd)
    
E_y = y - 0.5 * y^2 * sigma_y^2 * n * Gdd / Gd  
Conv_adj = abs(E_y - y)  
    


% df=[1
% 0.984983
% 0.969519
% 0.95354
% 0.936853
% 0.921526
% 0.905611
% 0.889113
% 0.873099
% 0.857868
% 0.842766
% 0.827796
% 0.812962
% 0.798719
% 0.784668
% 0.770808
% 0.756987
% 0.743572
% 0.730349
% 0.717174
% 0.70419
% 0.691754
% 0.679367
% 0.667035
% 0.654891
% 0.643062
% 0.631276
% 0.6195369
% 0.6077242
% 0.596931
% 0.5859388
% 0.5747628
% 0.5641142
% 0.5537612
% 0.5435752
% 0.533554
% 0.523588
% 0.5138211
% 0.5041004
% 0.4944292
% 0.4849133
% 0.4759845
% 0.4671065];

% sigmaSR=0.15;
% sigmaR=0.2;
% rho=0.7;
% n=20; %no of time periods for underlying swap
% di=0.25; %time period size 
% deli=0.25; %swap leg tenor of underlying swap
% notional = 1

% %result values mentined in paper, for comparision purpose
% paperadj=[0 
% 0.000189277
% 0.000288678
% 0.000387751
% 0.000488867
% 0.000591245
% 0.000693628
% 0.000798625
% 0.000906515 
% 0.00101622
% 0.001134238
% 0.001242719];

% calcadj=paperadj*0;

% alphai=0.5; %swap leg tenor of CMS swap
% counter=1;
% for i=2:2:24, %time peg for CMS payment date

    % counter=floor(i/2);
    % ti=(i-2)*deli;
    % a0vec=df(i:n+i-1);
    % A0=deli*sum(a0vec);
    % p1=df(i-1);
    % p2=df(n+i-1);
    % SR0=(p1-p2)/A0;
    % df1=df(i-1);
    % df2=df(i-1+2);
    % R0=(1/alphai)*(df1/df2-1);	% yearly forward rate

    % %calculate convexity correction using Hull's adjustment
    % y=SR0;
    % q=1/di;
   
    % % Alternative calculation
    % % get exponents for all cash flows
    % G_exp = 1:1:n;
    % Gd_exp = 2:1:n+1;
    % Gdd_exp = 3:1:n+2;
    % G_nominator = (SR0/q) .* ones(1,n) .* notional;
    % G_nominator(end) = G_nominator(end) + notional;	% in case of cash flow notional at end
    % G_denominator = (1 + y/q) .* ones(1,n);
    % G_denominator_exp = G_denominator .^ G_exp;
    % Gd_nominator = G_nominator .* (-G_exp) ./ q;			% G_exp serves also as multiplikator, since it is just 1,2,3,...,n
    % Gd_denominator = G_denominator .^ Gd_exp;
    % Gdd_nominator = Gd_nominator .* (-Gd_exp) ./ q;		% I do not know where the q comes from. But literature uses it without stating the factor...
    % Gdd_denominator = G_denominator .^ Gdd_exp;
    % fprintf('===new round ===\n');
    % G = sum(G_nominator ./ G_denominator_exp)
    % Gd = sum(Gd_nominator ./ Gd_denominator)
    % Gdd = sum(Gdd_nominator ./ Gdd_denominator)
    
    % % end alternative

    % cadj1= (Gdd/(2*Gd))*SR0*SR0*sigmaSR*sigmaSR*ti
    % alt_cadjl = ( R0^2 * sigmaSR^2 * alphai * ti ) / (1 + R0 * alphai  )
    % %calculate timing adjustment
    % cadj2= alphai*R0*SR0*rho*sigmaR*sigmaSR*ti/(1+alphai*R0);
    % calcadj(counter)=cadj1+cadj2;
% end

% results=[-calcadj paperadj]

% This function adjusts the forward_bond_yield to be like a real swap rate
function calc_adjustments(forward_bond_yield,sigma_bond_yield,ti,underlying_tenor,underlying_term,tau)

SR = forward_bond_yield;
sigmaSR = sigma_bond_yield;
q = 12 / underlying_term;		% number of payments per year
n = underlying_tenor * q;		% number of payments of underlying swap
ti = ti;						% year fraction, when forward_bond_yield is observed from valuation date (1,1.5,2,2.5,...,maturity_cms)
tau = tau;						% tenor of swap

    % Alternative calculation
    % get exponents for all cash flows
    G_exp = 1:1:n;
    Gd_exp = 2:1:n+1;
    Gdd_exp = 3:1:n+2;
    G_nominator = (SR/q) .* ones(1,n) .* notional;
    G_nominator(end) = G_nominator(end) + notional;	% in case of cash flow notional at end
    G_denominator = (1 + y/q) .* ones(1,n);
    G_denominator_exp = G_denominator .^ G_exp;
    Gd_nominator = G_nominator .* (-G_exp) ./ q;			% G_exp serves also as multiplikator, since it is just 1,2,3,...,n
    Gd_denominator = G_denominator .^ Gd_exp;
    Gdd_nominator = Gd_nominator .* (-Gd_exp) ./ q;		% I do not know where the q comes from. But literature uses it without stating the factor...
    Gdd_denominator = G_denominator .^ Gdd_exp;
    fprintf('===new round ===\n');
    G = sum(G_nominator ./ G_denominator_exp)
    Gd = sum(Gd_nominator ./ Gd_denominator)
    Gdd = sum(Gdd_nominator ./ Gdd_denominator)

    cadj1= (Gdd/(2*Gd))* SR.^2 .* sigmaSR^2 .* ti
    alt_cadjl = ( R0^2 * sigmaSR^2 * alphai * ti ) / (1 + R0 * alphai  )
    %calculate timing adjustment
    
end

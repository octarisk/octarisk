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
%# @deftypefn {Function File} {[@var{basket_vola} ] =} get_basket_volatility (@var{valuation_date}, @var{value_type}, @var{option}, @var{instrument_struct}, @var{index_struct}, @var{curve_struct}, @var{riskfactor_struct}, @var{matrix_struct}, @var{surface_struct})
%#
%# Return diversified volatilities for synthetic basket instruments.
%# The diversified volatility is dependent on the option maturity and strike,
%# so the volatility has to be calculated during each basket option valuation.
%#
%# @end deftypefn

function basket_vola = get_basket_volatility(valuation_date,value_type,basket,option,instrument_struct,index_struct,curve_struct,riskfactor_struct,matrix_struct,surface_struct)

if ( nargin < 9)
    error('Error: instrument_struct, curve_struct, matrix_struct, surface_struct and riskfactor_struct required. Aborting.');
end
   
% 0. get Option and Basket related parameters
dtm         = datenum(option.get('maturity_date')) - valuation_date;
basis_option = option.get('basis');
tf          = timefactor(valuation_date,option.maturity_date,basis_option);
option_type = option.option_type;
strike      = option.strike;
call_flag = option.call_flag;
if ( call_flag == 1 )
    moneyness_exponent = 1;
else
    moneyness_exponent = -1;
end
 
% 1. get vector with underlying values
underlying_weights  = basket.get('weights');
tmp_instruments     = basket.get('instruments');
tmp_currency        = basket.get('currency');
% summing up values over all underlying instruments
for jj = 1 : 1 : length(tmp_instruments)
    % get underlying instrument:
    tmp_underlying              = tmp_instruments{jj};
    % 1st try: find underlying in instrument_struct
    [und_obj  object_ret_code]  = get_sub_object(instrument_struct, tmp_underlying);
    if ( object_ret_code == 0 )
        % 2nd try: find underlying in instrument_struct
        [und_obj  object_ret_code_new]  = get_sub_object(index_struct, tmp_underlying);
        if ( object_ret_code_new == 0 )
            fprintf('WARNING: get_basket_volatility:  No instrument_struct object found for id >>%s<<\n',tmp_underlying);
        end
    end
    % Get Value from full valuated underlying:
    % absolute values from full valuation              
    underlying_value_vec        = und_obj.getValue(value_type);
    % Get FX rate:
    tmp_underlying_currency = und_obj.get('currency'); 
    if ( strcmp(tmp_underlying_currency,tmp_currency) == 1 )
        tmp_fx_value      = 1; 
    else
        %Conversion of currency:;
        tmp_fx_index = strcat('FX_', tmp_currency, tmp_underlying_currency);
        tmp_fx_struct_obj = get_sub_object(index_struct, tmp_fx_index);
        tmp_fx_value      = tmp_fx_struct_obj.getValue(value_type);
    end
    underlying_values(:,jj) = underlying_value_vec ./ tmp_fx_value;
end
basket_value = (underlying_weights * underlying_values')';

% 2. get correlation matrix object
tmp_corr_matrix = basket.get('correlation_matrix');
[corr_matrix  object_ret_code]  = get_sub_object(matrix_struct, tmp_corr_matrix);
if ( object_ret_code == 0 )
    fprintf('WARNING: get_basket_volatility:  No matrix_struct object found for id >>%s<<\n',tmp_corr_matrix);
end

% 3. get discount curve of synthetic instrument
tmp_discount = basket.get('discount_curve');
[discount_curve  object_ret_code]  = get_sub_object(curve_struct, tmp_discount);
if ( object_ret_code == 0 )
    fprintf('WARNING: get_basket_volatility: No curve_struct object found for id >>%s<<\n',tmp_discount);
end
rf_rate          = discount_curve.getRate(value_type,dtm);
    

% 4. get underlying volatility surfaces
tmp_vol_surfaces  = basket.get('instr_vol_surfaces');

tmp_moneyness   = (basket_value ./ strike).^ moneyness_exponent;                      
for jj = 1 : 1 : length(tmp_vol_surfaces)
    % get underlying volatility surface:
    tmp_vol_surface             = tmp_vol_surfaces{jj};
    [vol_obj  object_ret_code]  = get_sub_object(surface_struct, tmp_vol_surface);
    if ( object_ret_code == 0 )
        fprintf('WARNING: get_basket_volatility: No surface_struct object found for id >>%s<<\n',tmp_vol_surface);
    end    
    % Get implied vola scenario value (based on volatility surface object and
    %   vola risk factor
    underlying_volas(:,jj) = vol_obj.getValue(value_type,dtm,tmp_moneyness);                       
end

% 5. calculate diversified volatility:
basket_vola = getvola(underlying_weights',underlying_values,tmp_instruments,...
                                        underlying_volas,corr_matrix,tf,rf_rate);
end


%######################    Helper Function    ##################################

function vola = getvola(w,S,underlying_ids,sigma,corr_matrix,TF,r_basket)
% Calculate Basket underlying forward price
F = S .* exp(r_basket .* TF); % Forwardprice of underlying
M1 = (w' * F')';               % weighted Forwardprice of Basket
% Loop via all elements of matrix and vola / forward price vector
% Loop is easier to maintain than complex vectorizing in third dimension
% and fast enough (there wont be more than a dozen underlyings)
% all intermediate results are stored in matrizes
% subsequently, a C++ script is called (long double precision is used to prevent
% a precision overflow in extreme volatility shock cases for large time factors)
M2 = 0.0;
dimension 	     = length(underlying_ids);
exp_matrix       = zeros(max(rows(F),rows(sigma)),dimension^2);
prefactor_matrix = zeros(max(rows(F),rows(sigma)),dimension^2);

step = 0;
for ii = 1 : 1 : dimension
    id_ii = underlying_ids{ii};
    for jj = 1 : 1 : dimension
		step = step + 1;
        id_jj = underlying_ids{jj};
        tmp_exponent = corr_matrix.getValue(id_ii,id_jj) .* sigma(:,ii) .* sigma(:,jj) .* TF;
        tmp_prefactor =  w(ii) .* F(:,ii) .* w(jj) .* F(:,jj);
		% store prefactors
		exp_matrix(:,step) = tmp_exponent;
		prefactor_matrix(:,step) = tmp_prefactor;

    end
end

% calculating final Basket Vola with c++ code (using long double precision)
vola = calc_vola_basket_cpp(M1,TF,exp_matrix,prefactor_matrix);

end



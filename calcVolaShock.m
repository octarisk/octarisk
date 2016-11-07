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
%# @deftypefn {Function File} {[@var{imp_vola_shock} ] =} calcVolaShock (@var{value_type}, @var{instrument}, @var{vola_surf_obj}, @var{vola_riskfactor}, @var{xx}, @var{yy})
%# @deftypefnx {Function File} {[@var{imp_vola_shock} ] =} calcVolaShock (@var{value_type}, @var{instrument}, @var{vola_surf_obj}, @var{vola_riskfactor}, @var{xx}, @var{yy}, @var{zz})
%#
%# Return volatilities according to a vola surface and risk factor shocks for IR 
%# and INDEX types.
%#
%# @end deftypefn

function imp_vola_shock = calcVolaShock(value_type,instrument,vola_surf_obj,vola_riskfactor,xx,yy,zz)

if nargin < 6 || nargin > 7
    print_usage ();
end
 
% determine base vola according to surface type
if ( strcmpi(vola_surf_obj.type,'IR'))
    if nargin < 7
        error('calcVolaShock: Surface type IR needs tenor,term and moneyness as input variables.');
    end
    indexvol_base       = vola_surf_obj.getValue(xx,yy,zz);
elseif ( strcmpi(vola_surf_obj.type,'INDEX'))
    if nargin < 6
        error('calcVolaShock: Surface type INDEX needs term and moneyness as input variables.');
    end
    indexvol_base       = vola_surf_obj.getValue(xx,yy);
else
    error('calcVolaShock: Only vola surface types IR and INDEX are supported.');
end

% get implied volatility spread 
impl_vola_spread     = instrument.vola_spread;
% get atm vola shock from vola riskfactor
impl_vola_atm       = max(vola_riskfactor.getValue(value_type), ...
                                        -indexvol_base);

% Get Volatility according to volatility smile given by vola surface
% Calculate Volatility depending on model
model_vola = vola_riskfactor.model;
if ( strcmpi(model_vola,'GBM') || strcmpi(model_vola,'BKM') ) % Log-normal Motion
    if ( strcmpi(value_type,'stress'))
        imp_vola_shock  = impl_vola_spread + indexvol_base .* exp(vola_riskfactor.getValue(value_type));
    elseif ( strcmpi(value_type,'base'))
        imp_vola_shock  = impl_vola_spread + indexvol_base;
    else    % all MC scenarios use max condition
        imp_vola_shock  = indexvol_base .* exp(impl_vola_atm) + impl_vola_spread;
    end
else        % Normal Model
    if ( strcmpi(value_type,'stress'))
        imp_vola_shock  = impl_vola_spread + indexvol_base ...
                             .* (vola_riskfactor.getValue(value_type) + 1);
    elseif ( strcmpi(value_type,'base'))
        imp_vola_shock  = impl_vola_spread + indexvol_base;
    else     % all MC scenarios use max condition
        imp_vola_shock  = indexvol_base .+ impl_vola_atm + impl_vola_spread;  
    end
end
        

end

%!test 
%! instrument = struct();
%! instrument.vola_spread = 0.0;
%! v = Surface();
%! v = v.set('axis_x',365,'axis_x_name','TENOR','axis_y',90,'axis_y_name','TERM','axis_z',1.0,'axis_z_name','MONEYNESS');
%! v = v.set('values_base',0.2);
%! v = v.set('type','IR');
%! r = Riskfactor();
%! imp_vola_shock = calcVolaShock('base',instrument,v,r,365,90,1);
%! assert(imp_vola_shock,0.2)
%! imp_vola_shock = calcVolaShock('base',instrument,v,r,365,90,-0.5);
%! assert(imp_vola_shock,0.2)

%!test 
%! r = Riskfactor();
%! r = r.set('scenario_stress',0.1,'model','BM');
%! v = Surface();
%! v = v.set('axis_x',730,'axis_x_name','TERM','axis_y',1.1,'axis_y_name','MONEYNESS');
%! v = v.set('values_base',0.1798665419);
%! v = v.set('type','INDEX');
%! o = Option();
%! o = o.set('maturity_date','31-Mar-2018','compounding_type','cont','sub_type','OPT_EUR_P');
%! o = o.set('strike',136.9847,'multiplier',1);
%! tmp_imp_vola_shock_base = calcVolaShock('base',o,v,r,730,1.2);
%! assert(tmp_imp_vola_shock_base,0.179866541900000,0.00000001);
%! tmp_imp_vola_shock_stress = calcVolaShock('stress',o,v,r,730,1.5);
%! assert(tmp_imp_vola_shock_stress,0.19785319609,0.00000001);

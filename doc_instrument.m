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
%# @deftypefn {Function File} { @var{object} =} Instrument (@var{name},@var{id},@var{description},@var{type},@var{currency},@var{base_value},@var{asset_class},@var{valuation_date})
%# Instrument Superclass Inputs:
%# @itemize @bullet
%# @item @var{name} (string): Name of object
%# @item @var{id} (string): Id of object
%# @item @var{description} (string): Description of object
%# @item @var{type} (string): instrument type in list [cash, bond, debt, forward, option, sensitivity, synthetic]
%# @item @var{currency} (string): ISO code of currency
%# @item @var{base_value} (float): Actual base (spot) value of object
%# @item @var{asset_class} (sring): Instrument asset class
%# @item @var{valuation_date} (datenum): serial day number from Jan 1, 0000 defined as day 1. 
%# @end itemize
%# @*
%# The constructor of the instrument class constructs an object with the following properties and inherits them to all sub classes: @*
%# @itemize @bullet
%# @item name: Name of object
%# @item id: Id of object
%# @item description: Description of object
%# @item value_base: Actual base (spot) value of object
%# @item currency: ISO code of currency
%# @item asset_class: Instrument asset class
%# @item type: Type of Instrument class (Bond,Forward,...) 
%# @item valuation_date: date format DD-MMM-YYYY 
%# @item value_stress: Vector with values under stress scenarios
%# @item value_mc: Matrix with values under MC scenarios (values per timestep per column)
%# @item timestep_mc: MC timestep per column (cell string)
%# @end itemize
%# 
%# @deftypefnx {Function File} {} @var{value} = Instrument.getValue ({base,stress,mc_timestep})
%# Superclass Method getValue 
%# @*
%# Return the scenario (shock) value for an instrument object. Specify the desired return values with a property parameter.
%# If the second argument abs is set, the absolut scenario value is calculated from scenario shocks and the risk factor start value.
%# @*
%# Timestep properties:
%# @itemize @bullet
%# @item base: return base value
%# @item stress: return stress values
%# @item 1d: return MC timestep
%# @end itemize
%# @*
%# @deftypefnx {Function File} {} @var{boolean} = Instrument.isProp (property) 
%# Instrument Method isProp
%# @*
%# Query all properties from the Instrument Superclass and sub classes and returns 1 in case of a valid property.
%# @*
%# @*
%# @seealso{Instrument}
%# @end deftypefn


function a = doc_instrument()
    % this is only a dummy function for containing all the documentation.
end

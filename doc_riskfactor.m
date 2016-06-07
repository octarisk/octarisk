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
%# @deftypefn  {Function File} { @var{object} =} Riskfactor ()
%# @deftypefnx  {Function File} { @var{object} =} Riskfactor (@var{name}, 
%# @var{id}, @var{type}, @var{description}, @var{model}, @var{parameters})
%# 
%# Construct risk factor object. Riskfactor Class Inputs:
%# @itemize @bullet
%# @item @var{name} (string): Name of object
%# @item @var{id} (string): Id of object
%# @item @var{type} (string): risk factor type
%# @item @var{description} (string): Description of object
%# @item @var{model} (string): statistical model in list [GBM,BM,SRD,OU]
%# @item @var{parameters} (vector): vector with values [mean,std,skew,kurt, ...
%# start_value,mr_level,mr_rate,node,rate]
%# @end itemize
%# If no input arguments are provided, a dummy IR risk factor object is generated.
%# @*
%# The constructor of the risk factor class constructs an object with the 
%# following properties: @*
%# Class properties:
%# @itemize @bullet
%# @item name: Name of object
%# @item id: Id of object
%# @item description: Description of object
%# @item type: risk factor type
%# @item model: risk factor model
%# @item mean: first moment of risk factor distribution
%# @item std: second  moment of risk factor distribution
%# @item skew: third  moment of risk factor distribution
%# @item kurt: fourth moment of risk factor distribution
%# @item start_value: Actual spot value of object 
%# @item mr_level: In case of mean reverting model this is the mean reversion 
%# level
%# @item mr_rate: In case of mean reverting model this is the mean reversion rate 
%# @item node: In case of a interest rate or spread risk factor this is the term node
%# @item rate:  In case of a interest rate or spread risk factor this is the term 
%# rate at the node
%# @item scenario_stress: Vector with values of stress scenarios
%# @item scenario_mc: Matrix with risk factor scenario values (values per 
%# timestep per column)
%# @item timestep_mc: MC timestep per column (cell string)
%# @end itemize
%# 
%# @var{property_value} = Riskfactor.getValue((@var{base,stress,mc_timestep}),'abs')
%# Riskfactor Method getValue 
%# @*
%# Return the value for a risk factor object. Specify the desired return values 
%# with a property parameter.
%# If the second argument abs is set, the absolut scenario value is calculated 
%# from scenario shocks and the risk factor start value.
%# @*
%# Timestep properties:
%# @itemize @bullet
%# @item base: return base value
%# @item stress: return stress values
%# @item any regular MC timestep (e.g. '1d'): return scenario (shock) values at 
%# MC timestep
%# @end itemize
%# @*
%# @var{property_value} = Riskfactor.get (property)
%# @var{object} = Riskfactor.set (property, value)
%# Riskfactor Methods get / set
%# @*
%# Get / set methods for retrieving or setting risk factor properties.
%# @*
%# @*
%# @seealso{Instrument}
%# @end deftypefn

function a = doc_riskfactor()
    % this is only a dummy function for containing all the documentation.
end

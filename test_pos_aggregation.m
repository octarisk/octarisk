function test_pos_aggregation()

[instrument_struct, curve_struct, index_struct, surface_struct, para_object, matrix_struct, riskfactor_struct, ...
portfolio_struct, stresstest_struct, mc_var_shock_pct, port_obj_struct] = octarisk('C:/Dokumente/Work/octarisk/working_folder');


portobj = port_obj_struct(1).object;
posobj = portobj.positions(2).object;
posobj = posobj.aggregate('base', instrument_struct, index_struct);
posobj = posobj.aggregate('stress', instrument_struct, index_struct);
posobj = posobj.aggregate('250d', instrument_struct, index_struct);
posobj


portobj = portobj.aggregate('base', instrument_struct, index_struct);
portobj = portobj.aggregate('stress', instrument_struct, index_struct);
portobj = portobj.aggregate('250d', instrument_struct, index_struct);
portobj


end
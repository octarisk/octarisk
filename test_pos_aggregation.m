function test_pos_aggregation()

%[instrument_struct, curve_struct, index_struct, surface_struct, para_object, matrix_struct, riskfactor_struct, ...
%portfolio_struct, stresstest_struct, mc_var_shock_pct, port_obj_struct] = octarisk('/home/schinzilord/Dokumente/Programmierung/octarisk/working_folder');

[instrument_struct, curve_struct, index_struct, surface_struct, para_object, matrix_struct, riskfactor_struct, ...
portfolio_struct, stresstest_struct, mc_var_shock_pct, port_obj_struct] = octarisk('~/Dokumente/Programmierung/octarisk/sii_stdmodel_folder');

portobj = port_obj_struct(1).object;

portobj = portobj.aggregate('base', instrument_struct, index_struct, para_object);
portobj = portobj.aggregate('stress', instrument_struct, index_struct, para_object);
%~ portobj = portobj.aggregate('250d', instrument_struct, index_struct, para_object);
%~ portobj = portobj.calc_risk('stress', instrument_struct, index_struct, para_object);
%~ portobj = portobj.calc_risk('250d', instrument_struct, index_struct, para_object);
portobj

portobj.print_report(para_object);

%~ portobj2 = port_obj_struct(2).object;

%~ portobj2 = portobj2.aggregate('base', instrument_struct, index_struct, para_object);
%~ portobj2 = portobj2.aggregate('stress', instrument_struct, index_struct, para_object);
%~ portobj2 = portobj2.aggregate('250d', instrument_struct, index_struct, para_object);
%~ portobj2 = portobj2.calc_risk('stress', instrument_struct, index_struct, para_object);
%~ portobj2 = portobj2.calc_risk('250d', instrument_struct, index_struct, para_object);
%~ portobj2

%~ portobj2.print_report(para_object);

end

function generate_curves_mktdata()

c = Curve()

c = c.set('id','IR_EUR','name','EUR-SWAP','nodes',[365,730,3650,7300,21900]);
c = c.set('rates_base',[0.023,0.03,0.035,0.041,0.042]);

interp_method = 'monotone-convex'

curve_nodes = c.get('nodes')
curve_rates_base = c.get('rates_base')
 
% get shock from underlying RF_curve 
rf_ir_shock_values = [1,1.2,1.3;0.9,0.8,1.2;0.9,0.5,1.5]
rf_ir_shock_nodes =  [365,1825,4000]

% loop through all IR Curve nodes and get interpolated shock value from risk factor
tmp_ir_shock_matrix = [];
for ii = 1 : 1 : length(curve_nodes)
    tmp_node = curve_nodes(ii)
    % get interpolated shock vector at node
    tmp_shock = interpolate_curve(rf_ir_shock_nodes,rf_ir_shock_values,tmp_node,interp_method)
    % generate total shock matrix
    tmp_ir_shock_matrix = horzcat(tmp_ir_shock_matrix,tmp_shock);
end
tmp_ir_shock_matrix
shock_type = 'absolute'
if ( strcmp(shock_type,'relative'))
    curve_rates_mc = curve_rates_base .* tmp_ir_shock_matrix
elseif ( strcmp(shock_type,'absolute'))
    curve_rates_mc = curve_rates_base + tmp_ir_shock_matrix
else
    fprintf('No valid shock type defined [relative,absolut]: >>%s<< \n',shock_type);
end
c = c.set('rates_mc',curve_rates_mc);
clear tmp_ir_shock_matrix;
end
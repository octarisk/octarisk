%# Copyright (C) 2017 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {} get_dependencies(@var{path_octarisk}, @var{path_out})
%# Print a GraphViz .dot file containing all dependencies between
%# Class methods and function names. All information is directly retrieved
%# from all scriptnames and script source code. Comments and test cases
%# are neglected.
%# Final dot files are printed separately for all Classes and for an overall overview
%# directly into the provided output folder. Compile .dot files with graphviz command: 
%# @example
%# @group
%# dot -Tpdf Classname.dot -o Classname.pdf
%# dot -Tpng octarisk_dependencies.dot -o octarisk_dependencies.png
%# @end group
%# @end example
%# @end deftypefn

function get_dependencies(path_octarisk,path_out)


% get all files in folder
% get names of all scripts
cc = dir(path_octarisk);
cell_scriptnames = {cc.name};
c = {};
namecell = {};
% add *.m files
for i = 1 : 1 : length(cell_scriptnames)
    if ( regexp(cell_scriptnames{i},'.m$') && isempty(strfind(cell_scriptnames{i},'unittest')) && isempty(strfind(cell_scriptnames{i},'any2str')) ...
		&& isempty(strfind(cell_scriptnames{i},'get_sub_object')) && isempty(strfind(cell_scriptnames{i},'get_sub_struct')) ...
		&& isempty(strfind(cell_scriptnames{i},'instrument_valuation')))
        c{ length(c) + 1 } = strcat(path_octarisk,'\',cell_scriptnames{i}(1:end-2),'.m');
	    namecell{ length(namecell) + 1 } =  cell_scriptnames{i}(1:end-2);
    end
end
% add *.cc files
cc_filepath = strcat(path_octarisk,'\oct_files');
cc_cc = dir(cc_filepath);
cell_scriptnames_cc = {cc_cc.name};
for i = 1 : 1 : length(cell_scriptnames_cc)
    if ( regexp(cell_scriptnames_cc{i},'.cc$') )
        c{ length(c) + 1 } = strcat(path_octarisk,'\oct_files\',cell_scriptnames_cc{i}(1:end-3),'.cc');
	    namecell{ length(namecell) + 1 } =  cell_scriptnames_cc{i}(1:end-3);
    end
end

% loop through all class definitions and append methods
% set up cell with commands to Classes where help text is specified
classes = {'Instrument', 'Matrix','Curve','Forward','Option', ...
		'Cash','Debt','Sensitivity','Riskfactor', 'Index', ...
		'Synthetic', 'Surface', 'Swaption', 'Stochastic', ...
		'CapFloor', 'Bond'};

for kk = 1:1:length(classes)
	tmp_class = classes{kk};
	tmp_folder = strcat(path_octarisk,'\@',tmp_class);
	cc = dir(tmp_folder);
	class_methods = {cc.name};
	for i = 1 : 1 : length(class_methods)
		if ( regexp(class_methods{i},'.m$') )
			c{ length(c) + 1 } = strcat(tmp_folder,'\',class_methods{i}(1:end-2),'.m');
			namecell{ length(namecell) + 1 } =  strcat('@',tmp_class,'::',class_methods{i}(1:end-2));
		end
	end
end

result_struct = struct();

% nested loop: look for each script whether it has dependencies on other scripts
for kk=1:1:length(c)
	tmp_script = c{kk};
	str = fileread(tmp_script);
	% remove everything before '@end deftype' (we do not want to take comments into account)
	deftype_position = strfind(str,'@end deftypef');
	if ~isempty(deftype_position)
		str = str(deftype_position+14:end);
	end
	% remove all testcases
	testcase_position = strfind(str,'%!test');
	if ~isempty(testcase_position)
		str = str(1:testcase_position(1));
	end
	script_name = namecell{kk};
	dependency_cell = {};
	result_struct(kk).script = script_name;
	% apply regexp to this str for all other scripts
	for jj =1:1:length(namecell)
		func_name = namecell{jj};
		func_name_orig = func_name;
		if ~(strcmpi(func_name,script_name) || strcmpi('octarisk',func_name))
			% function calls can be "func_name ", "func_name "(, "func_name(", 
			if (strfind(str,strcat(func_name,' ')) ||
						   strfind(str,strcat(func_name,'(')) ||
						   strfind(str,strcat(func_name,' (')) )
			    printf('Script %s contains call to function %s \n',namecell{kk},func_name_orig);
				dependency_cell{ length(dependency_cell) + 1 } = func_name_orig;
			end
		
		end
	end
    result_struct(kk).dependency_cell = dependency_cell;
end


% Special treatment instrument_valuation
instr_val_script = strcat(path_octarisk,'\instrument_valuation.m');
str = fileread(instr_val_script);
script_name = 'instrument_valuation';
dependency_cell = {};
kk = length(result_struct) + 1;
result_struct(kk).script = script_name;
for jj =1:1:length(namecell)
	func_name = namecell{jj};
	% replace @Class::method with class.method string
	if ~(isempty(strfind(func_name,'@')))
	    func_name = strrep(func_name,'::','.');
		func_name = strrep(func_name,'@','');
		func_name = lower(func_name);
		func_name = strrep(func_name,'stochastic','stoch');
		func_name = strrep(func_name,'synthetic','synth');
		func_name = strrep(func_name,'sensitivity','sensi');
	end
	if ~(strcmpi(func_name,script_name) || strcmpi('octarisk',func_name))
		if ~(isempty(strfind(str,strcat(func_name,' '))) || isempty(strfind(str,strcat(func_name,'('))) )
			dependency_cell{ length(dependency_cell) + 1 } = namecell{jj};
		end
	
	end
end
result_struct(kk).dependency_cell = dependency_cell;
%-------------------------------------------------------------------------------

%###############################################################################
%                Printing of octarisk_dependencies.dot (overall view)
%
file_out = strcat(path_out,'\octarisk_dependencies.dot')
fprintf('Printing all class methods and properties to one files in path: %s \n',file_out);
% open file
fid = fopen (file_out, 'w');
% A) print header
fprintf(fid, 'digraph G {\n');
fprintf(fid, '\tfontname = "Bitstream Vera Sans"\n');
fprintf(fid, '\tfontsize = 8\n');
fprintf(fid, '\tnode [\n');
fprintf(fid, '\t\tfontname = "Bitstream Vera Sans"\n');
fprintf(fid, '\t\tfontsize = 8\n');
fprintf(fid, '\t\tshape = "record"\n');
fprintf(fid, '\t]\n');
fprintf(fid, '\tedge [\n');
fprintf(fid, '\t\tfontname = "Bitstream Vera Sans"\n');
fprintf(fid, '\t\tfontsize = 8\n');
fprintf(fid, '\t]\n');
fprintf(fid, '\tgraph [splines=ortho];\n');
fprintf(fid, '\trankdir=LR;\n');
% hard coded dependencies for instrument valuate method
fprintf(fid, '"octarisk" \t -> \t "@Instrument::valuate" [weight=3.]\n');
fprintf(fid, '"@Instrument::valuate" \t -> \t "instrument_valuation" [weight=3.]\n');
% highlight certain nodes
fprintf(fid, '"octarisk"  [shape=octagon, style=filled, fillcolor=skyblue]\n');	
fprintf(fid, '"@Instrument::valuate"  [shape=hexagon, style=filled, fillcolor=lightsteelblue2]\n');	
fprintf(fid, '"instrument_valuation"  [shape=rectangle, style=filled, fillcolor=lightyellow2]\n');	

% make legend
fprintf(fid, 'subgraph cluster_legend {\n');
fprintf(fid, 'label="Legend";\n');
fprintf(fid, 'kc1[label="Function Name", shape=box];\n');
fprintf(fid, 'k1[shape=plaintext, style=solid, label="Octave function"] \n');
fprintf(fid, 'kc2[label="Method Name", shape=box, style=filled, fillcolor=lightgrey];\n');
fprintf(fid, 'k2[shape=plaintext, style=solid, label="Method of Octarisk Class"] \n');
fprintf(fid, 'kc3[label="Octarisk", shape=octagon, style=filled, fillcolor=skyblue];\n');
fprintf(fid, 'k3[shape=plaintext, style=solid, label="Main Script"]\n');
fprintf(fid, 'kc4[label="@Instrument::valuate", shape=hexagon, style=filled, fillcolor=lightsteelblue2];\n');
fprintf(fid, 'k4[shape=plaintext, style=solid, label="Main method of instrument super class"]\n');
fprintf(fid, 'kc5[label="instrument_valuation", shape=rectangle, style=filled, fillcolor=lightyellow2];\n');
fprintf(fid, 'k5[shape=plaintext, style=solid, label="Main script for instrument valuation"]\n');
fprintf(fid, '{ rank=source;k1 k2 k3 k4 k5}\n');
fprintf(fid, '}\n');
	
depcell_full = {};	
% print results in one big dot file
for kk=1:1:length(result_struct)
	sub_struct = result_struct( kk );
	script = sub_struct.script;
	depcell = sub_struct.dependency_cell;
	%if isempty((strfind(script,'@')))	% Class entry found
	for jj=1:1:length(depcell) 
		depcell_full{ length(depcell_full) + 1 } = depcell{jj};
		depcell_full{ length(depcell_full) + 1 } = script;
		fprintf(fid, '"%s" \t -> \t "%s"\n',script,depcell{jj});
	end
end


% highlight class methods
depcell_full = unique(depcell_full);
for kk=1:1:length(depcell_full)
	tmp_script = depcell_full{kk};
	if ~isempty(strfind(tmp_script,'@'))	% Class entry found
		fprintf(fid, '"%s"  [shape=box, style=filled, fillcolor=lightgrey]\n',tmp_script);	
	end
end
		
% print title
fprintf(fid, '// title\n');
fprintf(fid, 'labelloc="t";\n');
fprintf(fid, 'fontsize = 30\n');
fprintf(fid, 'label="Octarisk  0.4.0 Function and Method Hierarchy";\n');
	
% E) print end of file
fprintf(fid, '}\n');
fclose(fid);

%###############################################################################

% print separate dot files for all classes
fprintf('Printing all class methods and properties to separate file: %s \n',path_out);

for kk = 1:1:length(classes)
	tmp_class = classes{kk};
	filename = strcat(path_out,'\',tmp_class,'.dot')
	% open file
	fid = fopen (filename, 'w');
	% A) print header
	fprintf(fid, 'digraph G {\n');
	fprintf(fid, '\tfontname = "Bitstream Vera Sans"\n');
	fprintf(fid, '\tfontsize = 8\n');
	fprintf(fid, '\tnode [\n');
	fprintf(fid, '\t\tfontname = "Bitstream Vera Sans"\n');
	fprintf(fid, '\t\tfontsize = 8\n');
	fprintf(fid, '\t\tshape = "record"\n');
	fprintf(fid, '\t]\n');
	fprintf(fid, '\tedge [\n');
	fprintf(fid, '\t\tfontname = "Bitstream Vera Sans"\n');
	fprintf(fid, '\t\tfontsize = 8\n');
	fprintf(fid, '\t]\n');
	fprintf(fid, '\tgraph [splines=ortho];\n');
	fprintf(fid, '\trankdir=LR;\n');
	
	% print Classes as clusters
	str_class = strcat('@',tmp_class,'::',tmp_class);
	fprintf(fid, '\tsubgraph class_%s {\n',tmp_class);
	fprintf(fid, '\t\tstyle=filled;\n');
	fprintf(fid, '\t\tnode [style=filled,color=lightgrey];\n');
	
	% print dependencies
	for kk=1:1:length(result_struct)
		sub_struct = result_struct( kk );
		script = sub_struct.script;
		pattern = strcat('@',tmp_class);
		if (regexpi(script,pattern))	% Class entry found
			if ~(strcmpi(script,str_class)) % but not Constructor itself
				fprintf(fid, '\t\t"%s" -> "%s"\n',str_class,script);
			end
		end
	end
	fprintf(fid, '\t\tlabel = "@%s";\n',tmp_class);
	fprintf(fid, '\t}\n');

	% print dependencies
	for kk=1:1:length(result_struct)
		sub_struct = result_struct( kk );
		script = sub_struct.script;
		pattern = strcat('@',tmp_class);
		if (regexpi(script,pattern))
			depcell = sub_struct.dependency_cell;
			for jj=1:1:length(depcell) 
				fprintf(fid, '"%s" \t -> \t "%s"\n',script,depcell{jj});
			end
		end
	end
	
	% E) print end of file
	fprintf(fid, '}\n');
	fclose(fid);
	
end % end for

end % end function
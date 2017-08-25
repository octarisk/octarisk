function get_dependencies(path_octarisk,path_out)


% get all files in folder
% get names of all scripts
cc = dir(path_octarisk);
cell_scriptnames = {cc.name};
c = {};
namecell = {};
% add *.m files
for i = 1 : 1 : length(cell_scriptnames)
    if ( regexp(cell_scriptnames{i},'.m$') )
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
	    namecell{ length(namecell) + 1 } =  cell_scriptnames_cc{i}(1:end-2);
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
	script_name = namecell{kk};
	dependency_cell = {};
	result_struct(kk).script = script_name;
	% apply regexp to this str for all other scripts
	for jj =1:1:length(namecell)
		func_name = namecell{jj};
		if ~(strcmpi(func_name,script_name) || strcmpi('octarisk',func_name))
			if ~(isempty(regexpi(str,func_name)))
			    %printf('Script %s contains call to function %s \n',namecell{kk},func_name);
				dependency_cell{ length(dependency_cell) + 1 } = func_name;
			end
		
		end
	end
    result_struct(kk).dependency_cell = dependency_cell;
end


%###############################################################################
%                    Printing
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

	
% print results
for kk=1:1:length(result_struct)
	sub_struct = result_struct( kk );
	script = sub_struct.script;
	depcell = sub_struct.dependency_cell;
	for jj=1:1:length(depcell) 
	    fprintf(fid, '"%s" \t -> \t "%s"\n',script,depcell{jj});
	end
end

% E) print end of file
fprintf(fid, '}\n');
fclose(fid);

%###############################################################################

% print separate charts for all classes
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
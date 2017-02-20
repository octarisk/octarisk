function print_class2dot(folder_in,file_out)

% get all classes in folder and extract all Instrument classes
filenames = readdir(folder_in);
if (length(filenames) < 2)
	error('print_class2dot: no files in folder found.');
end

superclasses = {};
instrument_classes = {};
% TODO: generic storage with hierarchy of all classes: classes_struct = struct();

% Loop through all class definitions and distinguish superclasses from subclasses
for kk = 1:1:length(filenames)
	% get all Classes: '@XXYY'
	superclass_found_flag = false;
	tmp_file = filenames{kk};
	if ( regexpi(tmp_file,'^@'))
		tmp_class = substr(tmp_file,2);
		%fprintf('Class found: %s \n',tmp_class);
		% check for superclass or subclass
		% open classdefinition
		path_to_classfile = strcat(folder_in,'@',tmp_class,'/',tmp_class,'.m');
		fid = fopen(path_to_classfile);
		file_data = fileread(path_to_classfile);
		file_data_split = strsplit(file_data,'\n');
		
		for ii = 1:1:length(file_data_split)
			tmp_line = file_data_split{ii};
			if ( regexpi(tmp_line,'^classdef'))
				tmp_split = strsplit(tmp_line,'<');
				if (length(tmp_split) > 1 && ~isempty(tmp_split{2}))
					tmp_superclass =  strtrim(tmp_split{2});
					fprintf('Superclass found: %s\n',tmp_superclass);
					superclass_found_flag = true;
					% store in appropriate classcell (assume only Instrument has subclasses)
					if (strcmpi('Instrument',tmp_superclass))
						instrument_classes{ length(instrument_classes) + 1 } = tmp_class;
					end
					break;
				end
			end
		end
		fclose(fid);
		if ( superclass_found_flag == false)
			% must be superclass by itself
			% store in superclass cell
			superclasses{ length(superclasses) + 1 } = tmp_class;
		end
	end
end
fprintf('Extracted Superclasses: \n');
superclasses
fprintf('Extracted Instrument Subclasses: \n');
instrument_classes

fprintf('Printing all class methods and properties to file: %s \n',file_out);
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

% B) loop through all super classes
for ii = 1:1:length(superclasses)
	tmp_class = superclasses{ii};
	% get methods
	tmp_method_cell = methods(tmp_class);
	% get fieldnames
	% unfortunately one has to invoke objects before retrieving fieldnames...
	if ( strcmpi(tmp_class,'Instrument'))
		Object = Instrument;
	elseif ( strcmpi(tmp_class,'Riskfactor'))
		Object = Riskfactor;
	elseif ( strcmpi(tmp_class,'Matrix'))
		Object = Matrix;
	elseif ( strcmpi(tmp_class,'Surface'))
		Object = Surface;
	elseif ( strcmpi(tmp_class,'Curve'))
		Object = Curve;
	elseif ( strcmpi(tmp_class,'Index'))
		Object = Index;
	elseif ( strcmpi(tmp_class,'Parameter'))
		Object = Parameter;
	else
		error('Unknown class %s',tmp_class);
	end
	tmp_fieldnames = fieldnames(Object);
	% print header
	fprintf(fid, '\t%s [ \n',tmp_class);
	fprintf(fid, '\t\tlabel = "{ %s | \n',tmp_class);
	
	% concatenate to strings
	method_string = '';
	property_string = '';
	fprintf(fid, '\t\t\tProperties \\l \n');
	for kk = 1:1:length(tmp_fieldnames)
		% get typeinfo of field
		tmp_type = typeinfo(Object.(tmp_fieldnames{kk}));
		if ( regexpi(tmp_type,'string') )
			type = 'string';
		elseif ( regexpi(tmp_type,'scalar') || regexpi(tmp_type,'matrix') )
			type = 'numeric';
		elseif ( regexpi(tmp_type,'cell') )
			type = 'cell';
		elseif ( regexpi(tmp_type,'bool') )
			type = 'bool';
		else
			type = 'undefined';
		end
		fprintf(fid, '\t\t\t%s : %s \\l \n',tmp_fieldnames{kk},type);
		
	end
	fprintf(fid, '\t\t\t | \n');
	fprintf(fid, '\t\t\tMethods \\l \n');
	for kk = 1:1:length(tmp_method_cell)
		fprintf(fid, '\t\t\t%s \\l \n',tmp_method_cell{kk});
	end
	% print final line
	fprintf(fid, '\t\t}"\n\t]\n');

end

% C) loop through all instrument_classes
for ii = 1:1:length(instrument_classes)
	tmp_class = instrument_classes{ii};
	% get methods
	tmp_method_cell = methods(tmp_class);
	% get fieldnames
	% unfortunately one has to invoke objects before retrieving fieldnames...
	if ( strcmpi(tmp_class,'Bond'))
		Object = Bond;
	elseif ( strcmpi(tmp_class,'Option'))
		Object = Option;
	elseif ( strcmpi(tmp_class,'Forward'))
		Object = Forward;
	elseif ( strcmpi(tmp_class,'Debt'))
		Object = Debt;
	elseif ( strcmpi(tmp_class,'CapFloor'))
		Object = CapFloor;
	elseif ( strcmpi(tmp_class,'Cash'))
		Object = Cash;
	elseif ( strcmpi(tmp_class,'Sensitivity'))
		Object = Sensitivity;
	elseif ( strcmpi(tmp_class,'Stochastic'))
		Object = Stochastic;
	elseif ( strcmpi(tmp_class,'Swaption'))
		Object = Swaption;
	elseif ( strcmpi(tmp_class,'Synthetic'))
		Object = Synthetic;
	else
		error('Unknown class %s',tmp_class);
	end
	
	tmp_fieldnames = fieldnames(Object);
	% print header
	fprintf(fid, '\t%s [ \n',tmp_class);
	fprintf(fid, '\t\tlabel = "{ %s | \n',tmp_class);
	
	% concatenate to strings
	method_string = '';
	property_string = '';
	fprintf(fid, '\t\t\tProperties \\l \n');
	for kk = 1:1:length(tmp_fieldnames)
		% get typeinfo of field
		tmp_type = typeinfo(Object.(tmp_fieldnames{kk}));
		if ( regexpi(tmp_type,'string') )
			type = 'string';
		elseif ( regexpi(tmp_type,'scalar') || regexpi(tmp_type,'matrix') )
			type = 'numeric';
		elseif ( regexpi(tmp_type,'cell') )
			type = 'cell';
		elseif ( regexpi(tmp_type,'bool') )
			type = 'bool';
		else
			type = 'undefined';
		end
		fprintf(fid, '\t\t\t%s : %s \\l \n',tmp_fieldnames{kk},type);
		
	end
	fprintf(fid, '\t\t\t | \n');
	fprintf(fid, '\t\t\tMethods \\l \n');
	for kk = 1:1:length(tmp_method_cell)
		fprintf(fid, '\t\t\t%s \\l \n',tmp_method_cell{kk});
	end
	% print final line
	fprintf(fid, '\t\t}"\n]\t\n');

end

% D) print class hierarchy for instruments
fprintf(fid, 'edge [\n');
fprintf(fid, '\tarrowhead = "empty"\n');
fprintf(fid, ']\n');

for ii = 1:1:length(instrument_classes)
	tmp_class = instrument_classes{ii};
	fprintf(fid, 'Instrument -> %s \n',tmp_class);
end	
	
% E) print end of file
fprintf(fid, '}\n');
fclose(fid);
end
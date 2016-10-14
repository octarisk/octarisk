function compile_oct_files(path_octarisk)
% it is assumed that all oct files are in subfolder /oct_files
current_dir = pwd;
path_to_oct_files = strcat(path_octarisk,'/oct_files');

% get all files from directory 
oct_file_list = dir(path_to_oct_files);
counter_cc = 0;
counter_compiled = 0;
% changing directory
chdir(path_to_oct_files);
for ii = 1 : 1 : length(oct_file_list)
    tmp_filename = oct_file_list( ii ).name;
    if ( regexpi(tmp_filename,'.cc') )    % cc source code file found -> compile
        counter_cc += 1;
        try
            fprintf('File >>%s<< found. Trying to compile... \n',tmp_filename);
            link_to_file = strcat(path_to_oct_files,'/',tmp_filename);
            
            % compile .cc file
            [outfile, status] = mkoctfile(link_to_file);
            if ( status == 0 )
                fprintf('----> File >>%s<< succesfully compiled\n',tmp_filename);
                counter_compiled += 1;
            end
            
            % move file
            tmp_oct_file = strrep(tmp_filename,'.cc','.oct');
            link_to_source_file = strcat(path_to_oct_files,'/',tmp_oct_file);
            link_to_dest_file = strcat(path_octarisk,'/',tmp_oct_file);
            retcode = movefile(link_to_source_file,link_to_dest_file);
            if ( retcode == 1 )
                fprintf('File >>%s<< moved successfully to octarisk folder.\n',tmp_oct_file);
            else
                fprintf('WARNING: File >>%s<< could not be copied to octarisk folder.\n',tmp_oct_file);
            end
            
            % remove .o files
            tmp_o_file = strrep(tmp_filename,'.cc','.o');
            link_to_o_file = strcat(path_to_oct_files,'/',tmp_o_file);
            delete(link_to_o_file);
            
        catch
            fprintf('WARNING: There has been an error for file: >>%s<<\n',tmp_filename);
            fprintf('Aborting with error message: >>%s<<\n',lasterr);
            chdir(current_dir);
        end
    end

end

chdir(current_dir);
fprintf('\nResult: Compiled >>%d<< files out of total >>%d<< files.\n',counter_compiled,counter_cc);

end
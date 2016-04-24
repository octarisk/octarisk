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
%# @deftypefn {Function File} {} = get_documentation(@var{type},@var{path_documentation}))
%# Print documentation for all specified Octave functions. 
%# This script allows you to choose functions, for which the documentation is extracted from the function headers
%# and printed to a file "functions.texi", "functionname.html" or to standard output if a specific format (texinfo,  html, txt) is set.
%# The path to all files has to be set in the variable path_documentation.
%# @end deftypefn

function get_documentation(type,path_documentation)

% Definition of Cellstring with all relevant scripts
scripts = ["octarisk"; "option_bs"; "option_willowtree"; "interpolate_curve"; "pricing_npv"; "harrell_davis_weight"];
c = cellstr(scripts)


% printing functions:
if ( strcmp("html",type) == 1)
    % Loop via all function names in cellstring, convert texinfo to html and print it to functionname.html
    for ii = 1:length(c)
        [retval status] = __makeinfo__(get_help_text(c{ii}),"html");
        
        if ( status == 0 )
            %replace html title
            repstring = strcat("<title>", c{ii} ,"</title>");
            retval = strrep( retval, "<title>Untitled</title>", repstring);
            %print html string to file
            filename = strcat(path_documentation,c{ii},".html");
            fid = fopen (filename, "w");
            fprintf(fid, retval);
            fprintf(fid, "\n");
            fclose (fid);
            disp("Documentation printed for");
            c{ii}
        else
            disp("There was a problem")
        endif
    endfor
elseif  ( strcmp("txt",type) == 1)  
    % Loop via all function names in cellstring, convert texinfo to plain text and print it to documentation.txt
    %filename = strcat(path,"documentation.txt");
    %fid = fopen (filename, "w");
    for ii = 1:length(c)
        [retval status] = __makeinfo__(get_help_text(c{ii}),"plain text");
        
        if ( status == 0 )
            %replace html title
            %repstring = strcat("<title>", c{ii} ,"</title>");
            %retval = strrep( retval, "<title>Untitled</title>", repstring);
            %print html string to file
            %sectionstring = strcat("Function ", c{ii},)
            fprintf(fid, "Function: %s \n", c{ii}); 
            %fprintf(fid, sectionstring);
            fprintf(fid, retval); 
            fprintf(fid, "\n");
            disp("Documentation printed for");
            c{ii}
        else
            disp("There was a problem")
        endif
    endfor
    fclose (fid);
elseif  ( strcmp("texinfo",type) == 1)  
    % Loop via all function names in cellstring, print texinfo directly to functions.texi
    filename = strcat(path_documentation,"functions.texi");
    fid = fopen (filename, "w");
    fprintf(fid,"\@menu\n");
    for ii = 1:length(c)
        tmpstring = strcat("* \t", c{ii},"::\n");
        fprintf(fid, tmpstring);
    endfor
    fprintf(fid,"\@end menu \n");
    for ii = 1:length(c)
        [retval status] = __makeinfo__(get_help_text(c{ii}),"texinfo");
        
        if ( status == 0 )
            %replace html title
            % Problem: all \ have to be escaped:
            %repstring = strcat("<title>", c{ii} ,"</title>");
            retval = strrep( retval, '\', '\\');
            nodestring = strcat("\@node \t", c{ii},"\n")
            fprintf(fid, nodestring);
            %print html string to file
            sectionstring = strcat("\@section \t", c{ii},"\n")
            fprintf(fid, sectionstring); 
            indexstring = strcat("@cindex \t Function \t", c{ii},"\n");
            fprintf(fid, indexstring);
            fprintf(fid, retval); 
            fprintf(fid, "\n");
            disp("Documentation printed for");
            c{ii}
        else
            disp("There was a problem")
        endif
    endfor
    fclose (fid);    
endif


endfunction

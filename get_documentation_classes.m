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
%# @deftypefn {Function File} {} get_documentation_classes(@var{type}, @var{path_octarisk}, @var{path_documentation})
%# Print documentation for all Octave Class definitions in specified path. 
%# The documentation is extracted from the static class methods and printed to a 
%# file 'functions.texi', 'functionname.html' or to standard output if a  
%# specific format (texinfo,  html, txt) is set.
%#
%# The path to all files has to be set in the variable path_documentation.
%# @end deftypefn

function get_documentation_classes(type,path_octarisk,path_documentation)

% set up cell with commands to Classes where help text is specified
c = {'Instrument.help', 'Matrix.help','Curve.help','Forward.help','Option.help', ...
        'Cash.help','Debt.help','Sensitivity.help','Riskfactor.help', 'Index.help', ...
        'Synthetic.help', 'Surface.help', 'Swaption.help', 'Stochastic.help', ...
        'CapFloor.help', 'Bond.help', 'Position.help'}

% printing functions:
if ( strcmp('html',type) == 1)
    % Loop via all function names in cellstring, convert texinfo to html and 
    % print it to functionname.html
    for ii = 1:length(c)
        fprintf('Trying to print documentation for: >>%s<<\n',c{ii});
        command = strcat(c{ii},"('html',1)");
        retval = eval(command);
        if ~( isempty(retval) )
            %replace html title
            repstring = strcat('<title>', c{ii} ,'</title>');
            retval = strrep( retval, '<title>Untitled</title>', repstring);
            %print html string to file
            filename = strcat(path_documentation,'/',c{ii},'.html');
            fid = fopen (filename, 'w');
            fprintf(fid, retval);
            fprintf(fid, '\n');
            fclose (fid);
            fprintf('SUCCESS: Documentation printed for: >>%s<<\n',c{ii}); 
        else
            fprintf('ERROR: >>%s<<. Message: >>%s<<\n',c{ii},lasterr); 
        end
    end
elseif  ( strcmp('txt',type) == 1)  
    % Loop via all function names in cellstring, convert texinfo to plain text 
    % and print it to documentation.txt
    filename = strcat(path_documentation,'/documentation.txt');
    fid = fopen (filename, 'w');
    for ii = 1:length(c)
        fprintf('Trying to print documentation for: >>%s<<\n',c{ii});
        command = strcat(c{ii},"('plain text',1)");
        retval = eval(command);        
        if ~( isempty(retval) )
            %replace html title
            %repstring = strcat('<title>', c{ii} ,'</title>');
            %retval = strrep( retval, '<title>Untitled</title>', repstring);
            %print html string to file
            %sectionstring = strcat('Function ', c{ii},)
            fprintf(fid, 'Function: %s \n', c{ii}); 
            %fprintf(fid, sectionstring);
            fprintf(fid, retval); 
            fprintf(fid, '\n');
            fprintf('SUCCESS: Documentation printed for: >>%s<<\n',c{ii}); 
        else
            fprintf('ERROR: >>%s<<. Message: >>%s<<\n',c{ii},lasterr); 
        end
    end
    fclose (fid);
elseif  ( strcmp('texinfo',type) == 1)  
    % Loop via all function names in cellstring, print texinfo directly to 
    % functions.texi
    filename = strcat(path_documentation,'/classes.texi');
    fid = fopen (filename, 'w');
    fprintf(fid,'\@menu\n');
    for ii = 1:length(c)
        tmpstring = strcat('* \t', c{ii},'::\n');
        fprintf(fid, tmpstring);
    end
    fprintf(fid,'\@end menu \n');
    for ii = 1:length(c)
        fprintf('Trying to print documentation for: >>%s<<\n',c{ii});
        command = strcat(c{ii},"('texinfo',1)");
        retval = eval(command);     
        if ~( isempty(retval) )
            %replace html title
            % Problem: all \ have to be escaped:
            %repstring = strcat('<title>', c{ii} ,'</title>');
            retval = strrep( retval, '\', '\\');
            nodestring = strcat('\@node \t', c{ii},'\n');
            fprintf(fid, nodestring);
            %print html string to file
            sectionstring = strcat('\@section \t', c{ii},'\n');
            fprintf(fid, sectionstring); 
            indexstring = strcat('@cindex \t Function \t', c{ii},'\n');
            fprintf(fid, indexstring);
            fprintf(fid, retval); 
            fprintf(fid, '\nDependencies of class:\n');
            fprintf(fid, '\n @image{%s,15cm}\n',c{ii}(1:end-5));
            fprintf(fid, '\n');
            fprintf('SUCCESS: Documentation printed for: >>%s<<\n',c{ii}); 
        else
            fprintf('ERROR: >>%s<<. Message: >>%s<<\n',c{ii},lasterr); 
        end
    end
    fclose (fid);    
end


end

%# Copyright (C) 2016 IRRer-Zins <IRRer-Zins@t-online.de>
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
%#
%# Matlab Adaption of Octarisk Code
%#
%# Input files phrases to replace:
%# wordlist.csv
%# Input files for replacement:
%# Automatical detection of all m.files in all directories for replacement
%# 
%# Output data:
%# Rewritten m.files

function adapt_matlab(path)

% Delete unneccessary wrapper scripts
delete('fmincon.m');

% Replacement script for main directory
replacement_script('wordlist_matlab.csv');

% Changing directories for replacement
file=dir('@*');
directorylist = {file.name};
main_dir=cd;
addpath(main_dir);

for i=1:size(directorylist,2)
    if isunix==1
        pathchange=strcat(main_dir,'/',directorylist(i));
    else
        pathchange=strcat(main_dir,'\',directorylist(i));
    end
    cd(pathchange{1});
    replacement_script('wordlist_matlab.csv');
end

% Copying neccessary files and functions
cd(main_dir);

%to be coded
%path=strcat(path,'/source directory');
%copyfile(path incl. source,main_dir{1});

rmpath(main_dir);
clear all;
disp('Adaption done!')
end
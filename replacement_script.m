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
%# -*- texinfo -*-
%# @deftypefn {Function File} replacement_script(@var{replacement_list})
%# Matlab Adaption of Octarisk Code 
%# Input files phrases to replace: wordlist_matlab.csv 
%# Format:(String;Replacement String;File)
%# Input files for replacement: Automatical detection of all m.files in directory for replacement
%# Output data: Rewritten m.files
%# @seealso{adapt_matlab}
%# @end deftypefn

function replacement_script(replacement_list)

% Building filelist
file = dir('*.m');
filelist = {file.name};

% Excluding replacement_script.m, adapt_matlab.m
filelist = regexprep(filelist,'replacement_script.m','');
filelist = regexprep(filelist,'adapt_matlab.m','');
filelist=filelist(~cellfun(@isempty, filelist));

% Test function
%filelist={'testit.m'};

% Reading wordlist for phrases
fin = fopen(replacement_list,'rt');
wordlist=textscan(fin,'%s','delimiter',{'\n','§'});
fclose(fin);
wordlist=wordlist{1};
wordlist=reshape(wordlist,3,[]);
wordlist=wordlist(1:2,:)';

% parfor loop possible
for i=1:size(filelist,2)
    % Reading files
    fin = fopen(filelist{i},'rt');
    temp=textscan(fin,'%s','delimiter','\n');
    fclose(fin);
    temp=temp{1};

    % Replacement
    for j=1:size(wordlist,1)
        temp = regexprep(temp, wordlist(j,1), wordlist(j,2));
    end
    
    % Rewriting file
    fin = fopen(filelist{i},'wt');
    fprintf(fin,'%s\n',temp{:});
    fclose(fin);
end

clear all;
disp('Replacement done!')
end

%# Copyright (C) 2024 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {[@var{retcode} @var{prompt} @var{response}]=} export_prompt_for_llm_risk_analysis (@var{obj}, @var{para_objects})
%# Prepare a prompt for an individual risk analysis for the portfolio based on VaR, trends and cash allocations.
%#
%# @seealso{}
%# @end deftypefn


function [retcode prompt_text] = export_prompt_for_llm_risk_analysis(obj, para_object)
	retcode = 0;

	% get path
	if ( strcmpi(para_object.path_working_folder,''))
		path_main = pwd;
	else
		path_main = para_object.path_working_folder;
	end
	path_reports = strcat(path_main,'/', ...
					para_object.folder_output,'/',para_object.folder_output_reports);
		
	
	try				
		prompt_risk_schema = strcat(path_main,'/',para_object.folder_static,'/prompt_yaml.txt');
		yaml_risk_schema = strcat(path_reports,'/risk_schema_port_',obj.id,'.yaml');
		prompt_risk_schema_str = fileread(prompt_risk_schema);
		yaml_risk_schema_str = fileread(yaml_risk_schema);
	catch
		fprintf('export_prompt_for_llm_risk_analysis: >>%s<<  or >>%s<< are not found for Portfolio >>%s<<\n',prompt_risk_schema,yaml_risk_schema,obj.id);
	end
	
	% concatenate full prompt:
	prompt_text = strcat(yaml_risk_schema_str,prompt_risk_schema_str);

	%~ str_begin = strcat("curl http://localhost:11434/api/generate -d '{\"model\": \"",model,"\",\"prompt\": \"");
	%~ prompt = [ ...
	%~ "You are a professional financial risk manager. Write a recommendation for further action based on the following key risk indicators: value-at-risk last month was at ",any2str(round(repstruct.var_last /1000)), " thousand EUR,", ... 
	%~ " this month ",any2str(round(repstruct.var_curr / 1000)) , " thousand EUR.", ...
	 %~ " Overall risk level is ",any2str(repstruct.srri_actual), ...
	 %~ " (out of 7), desired risk level is ",any2str(repstruct.srri_target),". If the overall risk level is above the desired risk level, action to rebalance is required. " ...
	%~ " The Value-at-risk trend is ",any2str(repstruct.var_trend), ". If the trend equals increasing, then across the last three month the Value-at-risk continuously increased. If the trend equals decreasing, then across the last three month the Value-at-Risk was always decreasing. If it is stable, then no specific movement occurred across the last three months. If the trend equals increasing and the overall risk level is above the desired risk level, then immediate action is required. If the trend equals decreasing and the overall risk level is above the desired risk level, close monitoring is required, since the Value-at-Risk could revert back automatically that the desired risk level is matched again. ", ...
	%~ "; Value-at-risk status is: ",any2str(repstruct.var_status), ". in case of status equals on track, no special monitoring action is required. If status is monitor, close observation of further movements are required and risk rebalancing is already recommended. In case of status equals action required, immediate risk rebalancing needs to be performed, otherwise severe risk of realization of higher than desired losses can materialize. ", ...
	%~ "; Current cash allocation: ", any2str(round(repstruct.alloc_cash_actual / 1000)) , " thousand EUR means, that currently this amount is hold in Cash. ", ...
	 %~ " The target cash allocation should be a minimum of: ", any2str(round(repstruct.alloc_cash_target / 1000)) , " thousand EUR. If the current cash allocation is below the minimum cash allocation, then immediate action is required and additional cash reserves have to be built. If the current allocation is significantly higher than the minimum cash allocation, action is recommended, since the unused cash could be used to either reduce risk or to increase expected return. " ...
	 %~ " Give a concise response, provide action items in bullet points and answer in third person, passive and in business english tone. If you do not know the answer to a particular topic, do not provide any misleading information and do not make up an answer."];

	%~ str_end = "\", \"stream\": false}'";

	
	# print risk prompt
	llm_risk_analysis_prompt = strcat(path_reports,'/risk_prompt_',obj.id,'_llm.tex');
	llm_prompt = fopen (llm_risk_analysis_prompt, 'w');
	fprintf(llm_prompt, '%s',prompt_text);
	fclose (llm_prompt);
		
end


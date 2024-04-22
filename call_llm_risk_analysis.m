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
%# @deftypefn {Function File} {[@var{retcode} @var{prompt} @var{response}]=} call_llm_risk_analysis (@var{obj}, @var{repstruct}, @var{path_reports})
%# Call a large language model to prepare an individual risk analysis for the portfolio based on VaR, trends and cash allocations.
%#
%# @seealso{}
%# @end deftypefn


function [retcode prompt response] = call_llm_risk_analysis(obj, repstruct, path_reports)
	retcode = 0;
	response = 'Technical problem occured.';
	% /opt/homebrew/opt/ollama/bin/ollama serve

	% concatenate curl statement:
	model = "mistral"	# latest 7B v0.2 2024/03
	#model ="llama2:13b"
	model ="llama3"

	str_begin = strcat("curl http://localhost:11434/api/generate -d '{\"model\": \"",model,"\",\"prompt\": \"");
	prompt = [ ...
	"You are a professional financial risk manager. Write a recommendation for further action based on the following key risk indicators: value-at-risk last month was at ",any2str(round(repstruct.var_last /1000)), " thousand EUR,", ... 
	" this month ",any2str(round(repstruct.var_curr / 1000)) , " thousand EUR.", ...
	 " Overall risk level is ",any2str(repstruct.srri_actual), ...
	 " (out of 7), desired risk level is ",any2str(repstruct.srri_target),". If the overall risk level is above the desired risk level, action to rebalance is required. " ...
	" The Value-at-risk trend is ",any2str(repstruct.var_trend), ". If the trend equals increasing, then across the last three month the Value-at-risk continuously increased. If the trend equals decreasing, then across the last three month the Value-at-Risk was always decreasing. If it is stable, then no specific movement occurred across the last three months. If the trend equals increasing and the overall risk level is above the desired risk level, then immediate action is required. If the trend equals decreasing and the overall risk level is above the desired risk level, close monitoring is required, since the Value-at-Risk could revert back automatically that the desired risk level is matched again. ", ...
	"; Value-at-risk status is: ",any2str(repstruct.var_status), ". in case of status equals on track, no special monitoring action is required. If status is monitor, close observation of further movements are required and risk rebalancing is already recommended. In case of status equals action required, immediate risk rebalancing needs to be performed, otherwise severe risk of realization of higher than desired losses can materialize. ", ...
	"%; Current cash allocation: ", any2str(round(repstruct.alloc_cash_actual / 1000)) , " thousand EUR means, that currently this amount is hold in Cash. ", ...
	 " The target cash allocation should be a minimum of: ", any2str(round(repstruct.alloc_cash_target / 1000)) , " thousand EUR. If the current cash allocation is below the minimum cash allocation, then immediate action is required and additional cash reserves have to be built. If the current allocation is significantly higher than the minimum cash allocation, action is recommended, since the unused cash could be used to either reduce risk or to increase expected return. " ...
	 ];

	str_end = "\", \"stream\": false}'";

	s = strcat(str_begin,prompt,str_end);
	s
	fprintf('Calling local LLM:\n');
	[status, output]=system(s);
	output
	fprintf('Return status: %s \n', any2str(status));
	if status == 0
		fprintf('Response from LLM model >>%s<< received.\n', model);
		ret = jsondecode(output);
		response = ret.response;
		% print response to file:
		response = strrep(response, 'response =  ', '');
		# print risk prompt
		llm_risk_analysis_recommendation = strcat(path_reports,'/risk_analysis_',obj.id,'_llm.tex');
		llm_response = fopen (llm_risk_analysis_recommendation, 'w');
		fprintf(llm_response, '%s',response);
		fclose (llm_response);
		
		# print risk response
		llm_risk_analysis_prompt = strcat(path_reports,'/risk_prompt_',obj.id,'_llm.tex');
		llm_prompt = fopen (llm_risk_analysis_prompt, 'w');
		fprintf(llm_prompt, '%s',prompt);
		fclose (llm_prompt);
		
	else
		fprintf('Something went wrong with status message: %s. Was the LLM server started?\n', any2str(status))
		retcode = status;
	end

		
end

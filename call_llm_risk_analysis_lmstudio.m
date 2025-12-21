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
%# @deftypefn {Function File} {[@var{retcode} @var{prompt} @var{response}]=} call_llm_risk_analysis (@var{obj}, @var{para_objects})
%# Call a large language model to prepare an individual risk analysis for the portfolio based on VaR, trends and cash allocations.
%# Modified to work with LM Studio API (OpenAI-compatible endpoint)
%# Always writes prompt and response to file, only calls API if server is running
%#
%# @seealso{}
%# @end deftypefn


function [retcode prompt_text response] = call_llm_risk_analysis_lmstudio(obj, para_object)
	retcode = 0;
	response = 'No LLM recommendations available for this report. LM Studio server was not running or could not be reached.';
	prompt_text = '';
	server_running = false;
	model = 'unknown';
	
	% LM Studio Configuration
	lm_studio_url = "http://localhost:1234/v1/chat/completions";
	lm_studio_models_url = "http://localhost:1234/v1/models";
	temperature = 0.3;      % Adjustable: 0.0 (deterministic) to 2.0 (creative)
	max_tokens = 6000;      % Maximum length of response
	
	% get path
	if ( strcmpi(para_object.path_working_folder,''))
		path_main = pwd;
	else
		path_main = para_object.path_working_folder;
	end
	path_reports = strcat(path_main,'/', ...
					para_object.folder_output,'/',para_object.folder_output_reports);
	
	% ========================================================================
	% STEP 1: Generate prompt files (always executed)
	% ========================================================================
	try				
		repstruct = obj.report_struct;
		
		%~ prompt_text = [ ...
			%~ "You are a professional financial risk manager. Write a recommendation for further action based on the following key risk indicators: value-at-risk last month was at ",any2str(round(repstruct.var_last /1000)), " thousand EUR,", ... 
			%~ " this month ",any2str(round(repstruct.var_curr / 1000)) , " thousand EUR.", ...
			%~ " Overall risk level is ",any2str(repstruct.srri_actual), ...
			%~ " (out of 7), desired risk level is ",any2str(repstruct.srri_target),". If the overall risk level is above the desired risk level, action to rebalance is required. " ...
			%~ " The Value-at-risk trend is ",any2str(repstruct.var_trend), ". If the trend equals increasing, then across the last three month the Value-at-risk continuously increased. If the trend equals decreasing, then across the last three month the Value-at-Risk was always decreasing. If it is stable, then no specific movement occurred across the last three months. If the trend equals increasing and the overall risk level is above the desired risk level, then immediate action is required. If the trend equals decreasing and the overall risk level is above the desired risk level, close monitoring is required, since the Value-at-Risk could revert back automatically that the desired risk level is matched again. ", ...
			%~ "; Value-at-risk status is: ",any2str(repstruct.var_status), ". in case of status equals on track, no special monitoring action is required. If status is monitor, close observation of further movements are required and risk rebalancing is already recommended. In case of status equals action required, immediate risk rebalancing needs to be performed, otherwise severe risk of realization of higher than desired losses can materialize. ", ...
			%~ "; Current cash allocation: ", any2str(round(repstruct.alloc_cash_actual / 1000)) , " thousand EUR means, that currently this amount is hold in Cash. ", ...
			%~ " The target cash allocation should be a minimum of: ", any2str(round(repstruct.alloc_cash_target / 1000)) , " thousand EUR. If the current cash allocation is below the minimum cash allocation, then immediate action is required and additional cash reserves have to be built. If the current allocation is significantly higher than the minimum cash allocation, action is recommended, since the unused cash could be used to either reduce risk or to increase expected return. " ...
			%~ " Give a concise response, provide action items in bullet points and answer in third person, passive and in business english tone. If you do not know the answer to a particular topic, do not provide any misleading information and do not make up an answer."]
		prompt_text = generate_risk_analysis_prompt(obj, repstruct);
	catch
		fprintf('call_llm_risk_analysis_lmstudio: Repstruct not found for Portfolio >>%s<<\n',obj.id);
		prompt_text = 'Error: Could not load prompt files.';
		retcode = 1;
	end
	
	% ========================================================================
	% STEP 2: Check if LM Studio server is running and query loaded model
	% ========================================================================
	fprintf('\n=== Checking LM Studio Server Status ===\n');
	[status, output] = system(sprintf('curl -s --connect-timeout 2 %s', lm_studio_models_url));
	
	if status == 0
		try
			output_json = jsondecode(output);
			if isfield(output_json, 'data') && length(output_json.data) > 0
				model = output_json.data(1).id;
				server_running = true;
				fprintf('✓ LM Studio server is running\n');
				fprintf('✓ Model loaded: %s\n', model);
			else
				fprintf('✗ LM Studio server responded but no model is loaded\n');
				fprintf('  Please load a model in LM Studio before running risk analysis\n');
				response = 'No LLM recommendations available. Please load a model in LM Studio (Local Server tab).';
			end
		catch
			fprintf('✗ Could not parse response from LM Studio server\n');
			fprintf('  Raw output: %s\n', output);
			response = 'No LLM recommendations available. LM Studio server returned invalid response.';
		end
	else
		fprintf('✗ LM Studio server is not running or not reachable\n');
		fprintf('  Please start the server in LM Studio: Local Server tab -> Start Server\n');
		fprintf('  Expected URL: %s\n', lm_studio_models_url);
		response = 'No LLM recommendations available. LM Studio server is not running. Please start the Local Server in LM Studio.';
		retcode = 2;
	end
	
	% ========================================================================
	% STEP 3: Call API only if server is running and model is loaded
	% ========================================================================
	if server_running
		fprintf('\n=== Calling LM Studio API ===\n');
		
		% Escape the prompt for JSON (handles nested JSON properly)
		escaped_prompt = escape_json_string(prompt_text);
		
		% Build OpenAI-compatible JSON payload for LM Studio
		json_payload = sprintf(['{' ...
			'"model": "%s",' ...
			'"messages": [' ...
				'{"role": "system", "content": "You are a professional financial risk manager specializing in portfolio analysis and risk assessment."},' ...
				'{"role": "user", "content": "%s"}' ...
			'],' ...
			'"temperature": %f,' ...
			'"max_tokens": %d,' ...
			'"stream": false' ...
		'}'], model, escaped_prompt, temperature, max_tokens);
		
		% Build curl command for LM Studio API
		curl_cmd = sprintf('curl -s -X POST "%s" -H "Content-Type: application/json" -d ''%s''', ...
			lm_studio_url, json_payload);

		fprintf('Submitting prompt to model: %s\n', model);
		fprintf('Temperature: %.2f, Max tokens: %d\n', temperature, max_tokens);
		
		[status, output] = system(curl_cmd);
		
		if status == 0
			fprintf('✓ Response received from LM Studio\n');
			try
				ret = jsondecode(output);
				
				% LM Studio returns OpenAI format:
				% {"choices": [{"message": {"content": "..."}}]}
				if isfield(ret, 'choices') && length(ret.choices) > 0
					response = ret.choices(1).message.content;
					fprintf('✓ Successfully parsed response (length: %d characters)\n', length(response));
				else
					fprintf('✗ Unexpected response format from LM Studio\n');
					response = 'Error: Could not parse LM Studio response. Response format was unexpected.';
					retcode = 3;
				end
				
			catch
				fprintf('✗ Failed to parse JSON response from LM Studio\n');
				fprintf('  Raw output (first 500 chars): %s\n', substr(output, 1, min(500, length(output))));
				response = 'Error: Failed to decode JSON response from LM Studio. The response may be malformed.';
				retcode = 3;
			end
			
		else
			fprintf('✗ API call failed with status: %s\n', any2str(status));
			response = sprintf('Error calling LM Studio API (status code: %d). Check LM Studio console for errors.', status);
			retcode = status;
		end
	else
		fprintf('\n=== Skipping API call (server not ready) ===\n');
	end
	
	% ========================================================================
	% STEP 4: Clean up response for LaTeX (always executed)
	% ========================================================================
	% Remove any leading/trailing whitespace
	response = strtrim(response);
	
	% Properly escape LaTeX special characters (preserves %, not removes!)
	response = escape_latex_response(response);
	response = markdown_to_latex(response);      % Convert markdown
	response = strrep(response, '#', '');
	response = strrep(response, '*', '');
	
	% ========================================================================
	% STEP 5: Write files (always executed, regardless of API success)
	% ========================================================================
	fprintf('\n=== Writing output files ===\n');
	
	% Write risk response to file
	llm_risk_analysis_recommendation = strcat(path_reports,'/risk_analysis_',obj.id,'_llm.tex');
	try
		llm_response = fopen(llm_risk_analysis_recommendation, 'w');
		if llm_response != -1
			fprintf(llm_response, '%s', response);
			fclose(llm_response);
			fprintf('✓ Risk analysis written to: %s\n', llm_risk_analysis_recommendation);
		else
			fprintf('✗ Could not open file for writing: %s\n', llm_risk_analysis_recommendation);
			retcode = 4;
		end
	catch
		fprintf('✗ Error writing risk analysis file: %s\n', llm_risk_analysis_recommendation);
		retcode = 4;
	end
	
	% Write risk prompt to file
	llm_risk_analysis_prompt = strcat(path_reports,'/risk_prompt_simplified_',obj.id,'_llm.tex');
	try
		llm_prompt = fopen(llm_risk_analysis_prompt, 'w');
		if llm_prompt != -1
			fprintf(llm_prompt, '%s', prompt_text);
			fclose(llm_prompt);
			fprintf('✓ Prompt written to: %s\n', llm_risk_analysis_prompt);
		else
			fprintf('✗ Could not open file for writing: %s\n', llm_risk_analysis_prompt);
			retcode = 4;
		end
	catch
		fprintf('✗ Error writing prompt file: %s\n', llm_risk_analysis_prompt);
		retcode = 4;
	end
	
	% ========================================================================
	% STEP 6: Summary
	% ========================================================================
	fprintf('\n=== Summary ===\n');
	fprintf('Portfolio ID: %s\n', obj.id);
	fprintf('Server status: %s\n', ternary(server_running, 'Running', 'Not running'));
	fprintf('Model: %s\n', model);
	fprintf('Return code: %d\n', retcode);
	fprintf('Response length: %d characters\n', length(response));
	if retcode == 0
		fprintf('✓ Risk analysis completed successfully\n');
	else
		fprintf('⚠ Risk analysis completed with warnings/errors (see above)\n');
	end
	fprintf('===================================\n\n');
		
end



#####################################################################################################################################
% Helper Function: Escape JSON strings
function json_str = escape_json_string(str)
    % Properly escape a string for JSON
    json_str = str;
    
    % Order matters! Do backslash first
    json_str = strrep(json_str, '\', '\\');
    json_str = strrep(json_str, '"', '\"');
    json_str = strrep(json_str, sprintf('\n'), '\\n');
    json_str = strrep(json_str, sprintf('\r'), '\\r');
    json_str = strrep(json_str, sprintf('\t'), '\\t');
    json_str = strrep(json_str, sprintf('\b'), '\\b');
    json_str = strrep(json_str, sprintf('\f'), '\\f');
end


% Improved prompt generation for LLM risk analysis
% This function extracts relevant data from portfolio object and report struct
% and creates a structured prompt optimized for 14B parameter models

function prompt_text = generate_risk_analysis_prompt(obj, repstruct)
    
    % ========================================================================
    % SECTION 1: Extract Portfolio Risk Metrics
    % ========================================================================
    port_value = obj.getValue('base');
    var_abs = obj.varhd_abs;
    var_rel = abs(obj.varhd_rel);
    var_after_tax = obj.varhd_abs_at;
    utility_var = obj.utility_var;
    
    % Calculate thresholds and difference
    utility_var_upper = 1.05 * utility_var;
    utility_var_lower = 0.95 * utility_var;
    var_difference = var_after_tax - utility_var;
    var_exceeds_threshold = var_after_tax > utility_var_upper;
    
    % ========================================================================
    % SECTION 2: Extract Asset Class Data
    % ========================================================================
    aa_cell = repstruct.aa_cell;
    aa_exposure = repstruct.aa_exposure;
    aa_decomp = repstruct.aa_decomp;
    
    % Find asset classes with highest decomposition VaR (risk contributors)
    [aa_decomp_sorted, idx_sorted] = sort(abs(aa_decomp), 'descend');
    top_risk_contributors = min(5, length(aa_cell));
    
    % ========================================================================
    % SECTION 3: Extract Position Level Data (Top risky positions)
    % ========================================================================
    pos_decomp_var = [];
    pos_ids = {};
    pos_basevalues = [];
    
    if (length(obj.positions) > 1)
        for ii = 2:1:length(obj.positions)
            tmp_pos_obj = obj.positions(ii).object;
            if (isobject(tmp_pos_obj))
                pos_ids{end+1} = tmp_pos_obj.id;
                pos_decomp_var(end+1) = tmp_pos_obj.decomp_varhd;
                pos_basevalues(end+1) = tmp_pos_obj.value_base;
            end
        end
    end
    
    % Sort positions by marginal VaR (highest risk impact)
    [decompvar_sorted, idx_decompvar] = sort(pos_decomp_var, 'descend');
    top_risk_positions = min(5, length(pos_ids));
    
    % ========================================================================
    % SECTION 4: Extract Historical VaR Trend
    % ========================================================================
    if (isfield(repstruct, 'var_last') && isfield(repstruct, 'var_curr'))
        var_last = repstruct.var_last;
        var_curr = repstruct.var_curr;
        var_change = var_curr - var_last;
        if (var_last > 0)
			var_change_pct = (var_change / var_last) * 100;
		else
			var_change_pct = 0;
		end
    else
        var_last = 0;
        var_curr = var_abs;
        var_change = 0;
        var_change_pct = 0;
    end
    
    % ========================================================================
    % SECTION 5: Build Structured Prompt for 14B Model
    % ========================================================================
    
    prompt_text = sprintf([...
        '# PORTFOLIO RISK ANALYSIS DATA\n\n' ...
        '## Portfolio Overview\n' ...
        'Portfolio Value: %d EUR\n' ...
        'Portfolio VaR (10-day, 99.9%%): %d EUR\n' ...
        'VaR as percentage: %.1f%%\n' ...
        'VaR after tax: %d EUR\n' ...
        'Volatility (annualized): %.1f%%\n\n' ...
        '## Risk Threshold Analysis\n' ...
        'Utility VaR (risk tolerance): %d EUR\n' ...
        'Upper threshold: %d EUR\n' ...
        'Lower threshold: %d EUR\n' ...
        'Current VaR exceeds upper threshold: %s\n' ...
        'Difference to utility VaR: %d EUR (%.0f%%)\n\n' ...
    ], ...
    round(port_value), round(var_abs), var_rel*100, round(var_after_tax), ...
    repstruct.vola_pa, round(utility_var), round(utility_var_upper), ...
    round(utility_var_lower), ternary(var_exceeds_threshold, 'YES', 'NO'), ...
    round(var_difference), (var_difference/utility_var)*100);
    
    % Add VaR trend if available
    if (var_last > 0)
        prompt_text = [prompt_text, sprintf([...
            '## VaR Movement\n' ...
            'Previous month VaR: %d EUR\n' ...
            'Current month VaR: %d EUR\n' ...
            'Change: %d EUR (%+.1f%%)\n' ...
            'Trend: %s\n\n' ...
        ], ...
        round(var_last), round(var_curr), round(var_change), var_change_pct, ...
        ternary(var_change_pct > 5, 'INCREASING', ternary(var_change_pct < -5, 'DECREASING', 'STABLE')))];
    end
    
    % Add asset class contributions
    prompt_text = [prompt_text, sprintf('## Top Risk Contributing Asset Classes\n')];
    for ii = 1:top_risk_contributors
        idx = idx_sorted(ii);
        prompt_text = [prompt_text, sprintf(...
            '%d. %s: Exposure %.0f%%, VaR contribution %d EUR (%.0f%% of total VaR)\n', ...
            ii, aa_cell{idx}, aa_exposure(idx)*100, round(aa_decomp(idx)), ...
            (aa_decomp(idx)/var_abs)*100)];
    end
    prompt_text = [prompt_text, sprintf('\n')];
    
    % Add top risky positions by Decomp VaR
    if (top_risk_positions > 0)
        prompt_text = [prompt_text, sprintf('## Top Positions by Decomposition VaR\n')];
        prompt_text = [prompt_text, sprintf('(Decomposition VaR = VaR contribution of position to total Portfolio VaR)\n')];
        for ii = 1:top_risk_positions
            idx = idx_decompvar(ii);
            prompt_text = [prompt_text, sprintf(...
                '%d. %s: Decomposition VaR %.2f EUR, Position value %d EUR\n', ...
                ii, pos_ids{idx}, pos_decomp_var(idx), round(pos_basevalues(idx)))];
        end
        prompt_text = [prompt_text, sprintf('\n')];
    end
    
    % Add cash allocation if available
    if (isfield(repstruct, 'alloc_cash_actual') && isfield(repstruct, 'alloc_cash_target'))
        cash_actual = repstruct.alloc_cash_actual;
        cash_target = repstruct.alloc_cash_target;
        cash_difference = cash_actual - cash_target;
        
        prompt_text = [prompt_text, sprintf([...
            '## Cash Allocation\n' ...
            'Current cash: %d EUR\n' ...
            'Target minimum cash: %d EUR\n' ...
            'Difference: %d EUR (%s)\n\n' ...
        ], ...
        round(cash_actual), round(cash_target), round(cash_difference), ...
        ternary(cash_difference >= 0, 'SUFFICIENT', 'BELOW TARGET'))];
    end
    
    % ========================================================================
    % SECTION 6: Add Structured Instructions for 14B Model
    % ========================================================================
    
    prompt_text = [prompt_text, sprintf([...
        '# TASK: Generate Risk Assessment Report\n\n' ...
        'Create a brief risk report with these 4 sections:\n\n' ...
        '## SECTION 1: Risk Status Summary\n' ...
        'Write 2-3 sentences summarizing:\n' ...
        '- Whether portfolio VaR after tax is within utility VaR thresholds\n' ...
        '- The magnitude of any breach\n' ...
        '- Current trend direction\n\n' ...
        '## SECTION 2: Risk Contributors\n' ...
        'Write 2 sentences identifying:\n' ...
        '- Which asset classes contribute most to portfolio risk\n' ...
        '- Which specific positions have highest decomposition VaR\n\n' ...
        '## SECTION 3: Action Required\n' ...
        'State YES or NO, then write 1-2 sentences:\n' ...
        '- If VaR after tax exceeds upper threshold: State "YES - Immediate rebalancing required"\n' ...
        '- If VaR after tax  within thresholds: State "NO - Continue monitoring"\n' ...
        '- If VaR after tax  slightly above but trend decreasing: State "MONITOR - Close observation"\n\n' ...
        '## SECTION 4: Specific Recommendations\n' ...
        'Write 2-4 bullet points with concrete actions:\n' ...
        '- If action required: Which positions/asset classes to reduce\n' ...
        '- Cash allocation adjustments if needed\n' ...
        '- Risk mitigation priorities\n\n' ...
        'Use professional financial terminology. Keep responses factual and concise.\n' ...
        'Base recommendations only on the data provided above.\n'...
    ])];
    
end


% Helper Function: Ternary operator simulation
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end


% Add this helper function at end of file:
function clean_response = escape_latex_response(response)
    clean_response = strtrim(response);
    
    % CRITICAL: Escape backslash FIRST to avoid double-escaping
    clean_response = strrep(clean_response, '\', '\textbackslash{}');
    
    % Then escape LaTeX special characters
    clean_response = strrep(clean_response, '%', '\%');
    clean_response = strrep(clean_response, '$', '\$');
    clean_response = strrep(clean_response, '&', '\&');
    clean_response = strrep(clean_response, '_', '\_');
    clean_response = strrep(clean_response, '{', '\{');
    clean_response = strrep(clean_response, '}', '\}');
    clean_response = strrep(clean_response, '~', '\textasciitilde{}');
    clean_response = strrep(clean_response, '^', '\textasciicircum{}');
end

% markdown_to_latex.m
% Convert markdown formatted LLM response to LaTeX
% Handles headers, bold text, bullet lists, and numbered lists
% Error-proof: handles various formats and missing elements gracefully

function latex_output = markdown_to_latex(markdown_text)
    % Convert markdown text to LaTeX format
    % Input: markdown_text - string with markdown formatting
    % Output: latex_output - LaTeX formatted string (fragment, not full document)
    
    % Split into lines for processing
    lines = strsplit(markdown_text, '\n');
    latex_lines = {};
    
    in_bullet_list = false;
    in_numbered_list = false;
    prev_line_empty = true;
    
    for i = 1:length(lines)
        line = strtrim(lines{i});
        
        % Skip completely empty lines at start/end
        if isempty(line)
            % Close any open lists
            if in_bullet_list
                latex_lines{end+1} = '\end{itemize}';
                in_bullet_list = false;
            end
            if in_numbered_list
                latex_lines{end+1} = '\end{enumerate}';
                in_numbered_list = false;
            end
            
            % Add small vertical space between paragraphs (not between list items)
            if ~prev_line_empty && i < length(lines)
                latex_lines{end+1} = '';
                latex_lines{end+1} = '\vspace{0.3em}';
                latex_lines{end+1} = '';
            end
            prev_line_empty = true;
            continue;
        end
        
        prev_line_empty = false;
        
        % Check for headers (##, ###, ####)
        if ~isempty(regexp(line, '^#{1,6}\s+', 'once'))
            % Close any open lists before header
            if in_bullet_list
                latex_lines{end+1} = '\end{itemize}';
                in_bullet_list = false;
            end
            if in_numbered_list
                latex_lines{end+1} = '\end{enumerate}';
                in_numbered_list = false;
            end
            
            % Count hash marks to determine level
            hash_count = 0;
            for j = 1:length(line)
                if line(j) == '#'
                    hash_count = hash_count + 1;
                else
                    break;
                end
            end
            
            % Extract header text (remove # and trim)
            header_text = strtrim(line(hash_count+1:end));
            
            % Convert to LaTeX subsection (limit to 3 levels)
            if hash_count <= 2
                latex_lines{end+1} = '';
                latex_lines{end+1} = sprintf('\\subsection*{%s}', header_text);
                latex_lines{end+1} = '';
            elseif hash_count == 3
                latex_lines{end+1} = '';
                latex_lines{end+1} = sprintf('\\subsubsection*{%s}', header_text);
                latex_lines{end+1} = '';
            else
                % For #### and deeper, use textbf
                latex_lines{end+1} = '';
                latex_lines{end+1} = sprintf('\\textbf{%s}', header_text);
                latex_lines{end+1} = '';
            end
            
        % Check for bullet list items (•, -, *, starting with them)
        elseif ~isempty(regexp(line, '^[•\-\*]\s+', 'once'))
            % Close numbered list if open
            if in_numbered_list
                latex_lines{end+1} = '\end{enumerate}';
                in_numbered_list = false;
            end
            
            % Open bullet list if not open
            if ~in_bullet_list
                latex_lines{end+1} = '\begin{itemize}';
                in_bullet_list = true;
            end
            
            % Extract item text (remove bullet and trim)
            item_text = strtrim(regexprep(line, '^[•\-\*]\s+', ''));
            
            % Convert bold within item
            item_text = convert_bold(item_text);
            
            latex_lines{end+1} = sprintf('  \\item %s', item_text);
            
        % Check for numbered list items (1., 2., etc.)
        elseif ~isempty(regexp(line, '^\d+\.\s+', 'once'))
            % Close bullet list if open
            if in_bullet_list
                latex_lines{end+1} = '\end{itemize}';
                in_bullet_list = false;
            end
            
            % Open numbered list if not open
            if ~in_numbered_list
                latex_lines{end+1} = '\begin{enumerate}';
                in_numbered_list = true;
            end
            
            % Extract item text (remove number and trim)
            item_text = strtrim(regexprep(line, '^\d+\.\s+', ''));
            
            % Convert bold within item
            item_text = convert_bold(item_text);
            
            latex_lines{end+1} = sprintf('  \\item %s', item_text);
            
        % Regular paragraph text
        else
            % Close any open lists
            if in_bullet_list
                latex_lines{end+1} = '\end{itemize}';
                latex_lines{end+1} = '';
                in_bullet_list = false;
            end
            if in_numbered_list
                latex_lines{end+1} = '\end{enumerate}';
                latex_lines{end+1} = '';
                in_numbered_list = false;
            end
            
            % Convert bold text
            line = convert_bold(line);
            
            % Add line
            latex_lines{end+1} = line;
        end
    end
    
    % Close any remaining open lists
    if in_bullet_list
        latex_lines{end+1} = '\end{itemize}';
    end
    if in_numbered_list
        latex_lines{end+1} = '\end{enumerate}';
    end
    
    % Join lines with newlines
    latex_output = strjoin(latex_lines, '\n');
    
    % Clean up excessive blank lines (more than 2 in a row)
    latex_output = regexprep(latex_output, '\n\n\n+', '\n\n');
    
    % Trim leading/trailing whitespace
    latex_output = strtrim(latex_output);
end

% Helper function to convert **bold** to \textbf{}
function text = convert_bold(text)
    % Convert **text** or __text__ to \textbf{text}
    % Handle multiple bold sections in one line
    
    % Replace **text** with \textbf{text}
    while true
        [start_idx, end_idx] = regexp(text, '\*\*[^\*]+\*\*', 'once');
        if isempty(start_idx)
            break;
        end
        
        % Extract bold text (remove **)
        bold_section = text(start_idx:end_idx);
        bold_text = bold_section(3:end-2);  % Remove ** from both ends
        
        % Replace in original text
        text = [text(1:start_idx-1), '\textbf{', bold_text, '}', text(end_idx+1:end)];
    end
    
    % Also handle __text__ format (less common but possible)
    while true
        [start_idx, end_idx] = regexp(text, '__[^_]+__', 'once');
        if isempty(start_idx)
            break;
        end
        
        bold_section = text(start_idx:end_idx);
        bold_text = bold_section(3:end-2);
        text = [text(1:start_idx-1), '\textbf{', bold_text, '}', text(end_idx+1:end)];
    end
end

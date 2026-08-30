%# Copyright (C) 2026 Stefan Schloegl <schinzilord@octarisk.com>
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
%# @deftypefn {Function File} {@var{retcode} =} export_network_exposures_yaml (@var{obj}, @var{instrument_struct}, @var{path_reports})
%# EXPORT_NETWORK_EXPOSURES_YAML Export portfolio network exposure data to YAML
%#
%# This function iterates through portfolio positions and instruments to build
%# a complete network exposure map using a POSITION-BASED MODEL.
%#
%# The position-based model allows the same issuer to have positions at different
%# custodians, capturing the full network topology including:
%#   - Position → Custodian (where this specific position is held)
%#   - Position → Issuer (who issued this instrument)
%#   - Position → SwapCounterparty (if derivative/structured product)
%#   - Position → DesignatedSponsor (market maker for this instrument)
%#   - Position → CustodianUnderlying (sub-custodian for ETF/fund assets)
%#
%# Usage:
%#   retcode = export_network_exposures_yaml(obj, instrument_struct, path_reports)
%#
%# Inputs:
%#   obj              - Portfolio object
%#   instrument_struct - Structure containing all instruments
%#   path_reports     - Output directory path for YAML file
%#
%# Output:
%#   retcode - 1 if successful, 0 if errors occurred
%#   Creates '<portfolio_id>_exposures.yaml' in path_reports directory
%#
%# @seealso{get_entity_country_map}
%# @end deftypefn

function retcode = export_network_exposures_yaml(obj, instrument_struct, path_reports)
    retcode = 1;
    
    % =========================================================================
    % HARD-CODED LGD (Loss Given Default) VALUES
    % =========================================================================
    lgd.Custodian = 0.15;            % 15% LGD - segregated client assets, opportunity costs
    lgd.Issuer = 0.60;               % 60% LGD - typical bond recovery ~40%
    lgd.SwapCounterparty = 0.10;     % 10% LGD - secured ETF swap derivatives
    lgd.CustodianUnderlying = 0.15;  % 15% LGD - sub-custodian assets segregated
    lgd.DesignatedSponsor = 0.05;    % 05% LGD - liquidity impact only
    lgd.MarketMaker = 0.05;          % 05% LGD - same as designated sponsor
    lgd.Sovereign = 0.40;            % 40% LGD - sovereign restructuring
    
    % =========================================================================
    % LOAD ENTITY -> COUNTRY MAPPING
    % =========================================================================
    try
        entity_country_map = get_entity_country_map();
        use_country_map = true;
        fprintf('Loaded entity-country mapping with %d entries\n', length(keys(entity_country_map)));
    catch
        entity_country_map = containers.Map();
        use_country_map = false;
        fprintf('WARNING: Could not load entity-country mapping, using instrument country_of_origin\n');
    end
    
    % =========================================================================
    % INITIALIZE DATA STRUCTURES
    % =========================================================================
    
    % Position-based model: each position is a separate record
    positions_data = struct('instrument', {}, 'issuer', {}, 'custodian', {}, ...
                            'exposure', {}, 'country', {}, ...
                            'swap_counterparty', {}, 'designated_sponsor', {}, ...
                            'custodian_underlying', {}, 'market_maker', {});
    
    % Aggregated entity structures (for summary and entity-level analysis)
    custodians = struct('name', {}, 'exposure', {}, 'country', {});
    issuers = struct('name', {}, 'exposure', {}, 'country', {});
    counterparties = struct('name', {}, 'exposure', {}, 'country', {});
    custodians_underlying = struct('name', {}, 'exposure', {}, 'country', {}, 'serves_positions', {});
    designated_sponsors = struct('name', {}, 'exposure', {}, 'country', {});
    market_makers = struct('name', {}, 'exposure', {}, 'country', {});
    
    % Country exposure aggregation
    country_exposures = struct('code', {}, 'exposure', {});
    
    % Total portfolio value
    total_wealth = 0;
    
    % =========================================================================
    % ITERATE THROUGH POSITIONS
    % =========================================================================
    
    fprintf('Extracting network exposure data from %d positions...\n', length(obj.positions));
    
    for ii = 1:length(obj.positions)
        try
            pos_obj = obj.positions(ii).object;
            
            if ~isobject(pos_obj)
                continue;
            end
            
            pos_id = pos_obj.id;
            pos_value = pos_obj.getValue('base');
            
            % Skip zero or negative exposures
            if pos_value <= 0
                continue;
            end
            
            total_wealth = total_wealth + pos_value;
            
            % Get instrument object
            instr_obj = get_sub_object(instrument_struct, pos_id);
            
            if ~isobject(instr_obj)
                continue;
            end
            
            % -----------------------------------------------------------------
            % EXTRACT POSITION DATA
            % -----------------------------------------------------------------
            
            % Instrument name (position ID)
            instrument_name = pos_id;
            
            % Country of origin (fund domicile)
            instr_country = 'UNKNOWN';
            if instr_obj.isProp('country_of_origin') && ~isnull(instr_obj.country_of_origin)
                instr_country = instr_obj.country_of_origin;
            end
            
            % Issuer
            issuer_name = '';
            if instr_obj.isProp('issuer') && ~isnull(instr_obj.issuer)
                issuer_name = instr_obj.issuer;
                % map instr_country from issuer country
                instr_country = lookup_entity_country(issuer_name, entity_country_map, use_country_map, instr_country);
            end
            
            % Custodian (from position)
            custodian_name = '';
            if pos_obj.isProp('custodian_bank') && ~isnull(pos_obj.custodian_bank)
                custodian_name = pos_obj.custodian_bank;
            end
            
            % Swap counterparty
            cp_name = '';
            if instr_obj.isProp('counterparty') && ~isnull(instr_obj.counterparty)
                cp_name = instr_obj.counterparty;
            end
            
            % Designated sponsor
            ds_name = '';
            if instr_obj.isProp('designated_sponsor') && ~isnull(instr_obj.designated_sponsor)
                ds_name = instr_obj.designated_sponsor;
            end
            
            % Custodian underlying (sub-custodian)
            cu_name = '';
            if instr_obj.isProp('custodian_bank_underlyings') && ~isnull(instr_obj.custodian_bank_underlyings)
                cu_name = instr_obj.custodian_bank_underlyings;
            end
            
            % Market maker
            mm_name = '';
            if instr_obj.isProp('market_maker') && ~isnull(instr_obj.market_maker)
                mm_name = instr_obj.market_maker;
            end
            
            % special cases
            if strcmpi(instrument_name,'ALLIANZ_PEN')
				instr_country = 'DE';
				issuer_name = 'Allianz';
			elseif strcmpi(instrument_name,'CASH_EUR')
				instr_country = 'DE';
				issuer_name = 'Deutsche Bundesbank';
			elseif strcmpi(instrument_name,'DEBEKA_BSV')
				instr_country = 'DE';
				issuer_name = 'DEBEKA';
			elseif strcmpi(instrument_name,'PKDW')
				instr_country = 'DE';
				issuer_name = 'Pensionskasse der Deutschen Wirtschaft';		
			elseif strcmpi(instrument_name,'GOLD_PHYS')
				instr_country = 'DE';
				issuer_name = 'None';
			elseif strcmpi(instrument_name,'SILVER_PHYS')
				instr_country = 'DE';
				issuer_name = 'None';		
            end
            
            if strcmpi(instr_country,'Germany')
				instr_country = 'DE';
            end
            
            % -----------------------------------------------------------------
            % ADD POSITION RECORD
            % -----------------------------------------------------------------
            pos_idx = length(positions_data) + 1;
            positions_data(pos_idx).instrument = instrument_name;
            positions_data(pos_idx).issuer = issuer_name;
            positions_data(pos_idx).custodian = custodian_name;
            positions_data(pos_idx).exposure = pos_value;
            positions_data(pos_idx).country = instr_country;
            positions_data(pos_idx).swap_counterparty = cp_name;
            positions_data(pos_idx).designated_sponsor = ds_name;
            positions_data(pos_idx).custodian_underlying = cu_name;
            positions_data(pos_idx).market_maker = mm_name;
            
            % -----------------------------------------------------------------
            % AGGREGATE ENTITY EXPOSURES
            % -----------------------------------------------------------------
            
            % Custodian
            if ~isempty(custodian_name)
                cust_country = lookup_entity_country(custodian_name, entity_country_map, use_country_map, instr_country);
                custodians = add_or_update_entity(custodians, custodian_name, pos_value, cust_country);
            end
            
            % Issuer
            if ~isempty(issuer_name)
                issuer_country = lookup_entity_country(issuer_name, entity_country_map, use_country_map, instr_country);
                issuers = add_or_update_entity(issuers, issuer_name, pos_value, issuer_country);
            end
            
            % Swap counterparty
            if ~isempty(cp_name)
                cp_country = lookup_entity_country(cp_name, entity_country_map, use_country_map, instr_country);
                counterparties = add_or_update_entity(counterparties, cp_name, pos_value, cp_country);
            end
            
            % Custodian underlying
            if ~isempty(cu_name)
                cu_country = lookup_entity_country(cu_name, entity_country_map, use_country_map, instr_country);
                custodians_underlying = add_or_update_entity_with_list(custodians_underlying, ...
                    cu_name, pos_value, cu_country, 'serves_positions', instrument_name);
            end
            
            % Designated sponsor
            if ~isempty(ds_name)
                ds_country = lookup_entity_country(ds_name, entity_country_map, use_country_map, instr_country);
                designated_sponsors = add_or_update_entity(designated_sponsors, ds_name, pos_value, ds_country);
            end
            
            % Market maker
            if ~isempty(mm_name)
                mm_country = lookup_entity_country(mm_name, entity_country_map, use_country_map, instr_country);
                market_makers = add_or_update_entity(market_makers, mm_name, pos_value, mm_country);
            end
            
            % Country exposure
            if ~strcmpi(instr_country, 'UNKNOWN')
                country_exposures = add_or_update_country(country_exposures, instr_country, pos_value);
            end
            
        catch err
            fprintf('WARNING: Error processing position %s: %s\n', pos_id, err.message);
            retcode = 0;
        end
    end
    
    fprintf('Extraction complete.\n');
    fprintf('  Positions: %d\n', length(positions_data));
    fprintf('  Custodians: %d\n', length(custodians));
    fprintf('  Issuers: %d\n', length(issuers));
    fprintf('  Counterparties: %d\n', length(counterparties));
    fprintf('  Sub-custodians: %d\n', length(custodians_underlying));
    fprintf('  Designated Sponsors: %d\n', length(designated_sponsors));
    fprintf('  Market Makers: %d\n', length(market_makers));
    fprintf('  Countries: %d\n', length(country_exposures));
    fprintf('  Total Wealth: %.2f\n', total_wealth);
    
    % =========================================================================
    % WRITE YAML FILE
    % =========================================================================
    
    yaml_filename = strcat(path_reports, '/', obj.id, '_exposures.yaml');
    fid = fopen(yaml_filename, 'w');
    
    if fid == -1
        error('Could not open file for writing: %s', yaml_filename);
    end
    
    try
        % Header
        fprintf(fid, '# Portfolio Network Exposure Data - Position-Based Model\n');
        fprintf(fid, '# Generated by Octarisk on %s\n', datestr(now));
        fprintf(fid, '# For use with network_risk_analyzer.py\n');
        fprintf(fid, '# All exposures in base currency\n');
        fprintf(fid, '#\n');
        fprintf(fid, '# Network Model: Position-based (each position has its own custodian link)\n');
        fprintf(fid, '# This allows same issuer to have positions at different custodians\n\n');
        
        % Metadata
        fprintf(fid, 'metadata:\n');
        fprintf(fid, '  portfolio_name: "%s"\n', obj.id);
        fprintf(fid, '  portfolio_date: "%s"\n', datestr(now, 'yyyy-mm-dd'));
        fprintf(fid, '  total_wealth: %.2f\n', total_wealth);
        fprintf(fid, '  currency: EUR\n');
        fprintf(fid, '  model_type: "position-based"\n\n');
        
        % LGD defaults
        fprintf(fid, '  # Loss Given Default rates by entity type\n');
        fprintf(fid, '  lgd_defaults:\n');
        fprintf(fid, '    Custodian: %.2f\n', lgd.Custodian);
        fprintf(fid, '    Issuer: %.2f\n', lgd.Issuer);
        fprintf(fid, '    SwapCounterparty: %.2f\n', lgd.SwapCounterparty);
        fprintf(fid, '    CustodianUnderlying: %.2f\n', lgd.CustodianUnderlying);
        fprintf(fid, '    DesignatedSponsor: %.2f\n', lgd.DesignatedSponsor);
        fprintf(fid, '    MarketMaker: %.2f\n', lgd.MarketMaker);
        fprintf(fid, '    Sovereign: %.2f\n\n', lgd.Sovereign);
        
        % -----------------------------------------------------------------
        % CUSTODIAN SECTION (aggregated)
        % -----------------------------------------------------------------
        fprintf(fid, '# Direct custodian banks where portfolio is held (aggregated)\n');
        fprintf(fid, 'Custodian:\n');
        for ii = 1:length(custodians)
            fprintf(fid, '  - name: "%s"\n', sanitize_yaml(custodians(ii).name));
            fprintf(fid, '    country: "%s"\n', custodians(ii).country);
            fprintf(fid, '    exposure: %.2f\n', custodians(ii).exposure);
        end
        fprintf(fid, '\n');
        
        % -----------------------------------------------------------------
        % POSITION SECTION (the core of position-based model)
        % -----------------------------------------------------------------
        fprintf(fid, '# Individual positions with their specific custodian and dependencies\n');
        fprintf(fid, '# This is the primary data source for network analysis\n');
        fprintf(fid, 'Position:\n');
        for ii = 1:length(positions_data)
            pos = positions_data(ii);
            fprintf(fid, '  - instrument: "%s"\n', sanitize_yaml(pos.instrument));
            fprintf(fid, '    issuer: "%s"\n', sanitize_yaml(pos.issuer));
            fprintf(fid, '    custodian: "%s"\n', sanitize_yaml(pos.custodian));
            fprintf(fid, '    exposure: %.2f\n', pos.exposure);
            fprintf(fid, '    country: "%s"\n', pos.country);
            
            % Optional fields - only write if non-empty
            if ~isempty(pos.swap_counterparty)
                fprintf(fid, '    swap_counterparty: "%s"\n', sanitize_yaml(pos.swap_counterparty));
            end
            if ~isempty(pos.custodian_underlying)
                fprintf(fid, '    custodian_underlying: "%s"\n', sanitize_yaml(pos.custodian_underlying));
            end
            if ~isempty(pos.designated_sponsor)
                fprintf(fid, '    designated_sponsor: "%s"\n', sanitize_yaml(pos.designated_sponsor));
            end
            if ~isempty(pos.market_maker)
                fprintf(fid, '    market_maker: "%s"\n', sanitize_yaml(pos.market_maker));
            end
            fprintf(fid, '\n');
        end
        
        % -----------------------------------------------------------------
        % ISSUER SECTION (aggregated from positions)
        % -----------------------------------------------------------------
        fprintf(fid, '# Issuers (aggregated from positions)\n');
        fprintf(fid, 'Issuer:\n');
        for ii = 1:length(issuers)
            fprintf(fid, '  - name: "%s"\n', sanitize_yaml(issuers(ii).name));
            fprintf(fid, '    country: "%s"\n', issuers(ii).country);
            fprintf(fid, '    exposure: %.2f\n', issuers(ii).exposure);
        end
        fprintf(fid, '\n');
        
        % -----------------------------------------------------------------
        % SWAP COUNTERPARTY SECTION
        % -----------------------------------------------------------------
        fprintf(fid, '# Swap/derivative counterparties\n');
        fprintf(fid, 'SwapCounterparty:\n');
        for ii = 1:length(counterparties)
            fprintf(fid, '  - name: "%s"\n', sanitize_yaml(counterparties(ii).name));
            fprintf(fid, '    country: "%s"\n', counterparties(ii).country);
            fprintf(fid, '    exposure: %.2f\n', counterparties(ii).exposure);
        end
        fprintf(fid, '\n');
        
        % -----------------------------------------------------------------
        % CUSTODIAN UNDERLYING SECTION
        % -----------------------------------------------------------------
        fprintf(fid, '# Sub-custodians holding underlying ETF/fund assets\n');
        fprintf(fid, 'CustodianUnderlying:\n');
        for ii = 1:length(custodians_underlying)
            fprintf(fid, '  - name: "%s"\n', sanitize_yaml(custodians_underlying(ii).name));
            fprintf(fid, '    country: "%s"\n', custodians_underlying(ii).country);
            fprintf(fid, '    exposure: %.2f\n', custodians_underlying(ii).exposure);
            
            % Add serves_positions list
            if isfield(custodians_underlying(ii), 'serves_positions') && ~isempty(custodians_underlying(ii).serves_positions)
                pos_list = custodians_underlying(ii).serves_positions;
                fprintf(fid, '    serves_positions: [');
                for jj = 1:length(pos_list)
                    if jj > 1
                        fprintf(fid, ', ');
                    end
                    fprintf(fid, '"%s"', sanitize_yaml(pos_list{jj}));
                end
                fprintf(fid, ']\n');
            end
        end
        fprintf(fid, '\n');
        
        % -----------------------------------------------------------------
        % DESIGNATED SPONSOR SECTION
        % -----------------------------------------------------------------
        fprintf(fid, '# Designated sponsors (liquidity providers)\n');
        fprintf(fid, 'DesignatedSponsor:\n');
        for ii = 1:length(designated_sponsors)
            fprintf(fid, '  - name: "%s"\n', sanitize_yaml(designated_sponsors(ii).name));
            fprintf(fid, '    country: "%s"\n', designated_sponsors(ii).country);
            fprintf(fid, '    exposure: %.2f\n', designated_sponsors(ii).exposure);
        end
        fprintf(fid, '\n');
        
        % -----------------------------------------------------------------
        % MARKET MAKER SECTION
        % -----------------------------------------------------------------
        fprintf(fid, '# Market makers\n');
        fprintf(fid, 'MarketMaker:\n');
        for ii = 1:length(market_makers)
            fprintf(fid, '  - name: "%s"\n', sanitize_yaml(market_makers(ii).name));
            fprintf(fid, '    country: "%s"\n', market_makers(ii).country);
            fprintf(fid, '    exposure: %.2f\n', market_makers(ii).exposure);
        end
        fprintf(fid, '\n');
        
        % -----------------------------------------------------------------
        % COUNTRY EXPOSURE SECTION
        % -----------------------------------------------------------------
        fprintf(fid, '# Aggregated country-level exposure\n');
        fprintf(fid, 'CountryExposure:\n');
        for ii = 1:length(country_exposures)
            fprintf(fid, '  %s: %.2f\n', country_exposures(ii).code, country_exposures(ii).exposure);
        end
        fprintf(fid, '\n');
        
        fclose(fid);
        
        fprintf('\nNetwork exposure data exported to: %s\n', yaml_filename);
        
    catch err
        fclose(fid);
        rethrow(err);
    end
    
end

% =============================================================================
% HELPER FUNCTIONS
% =============================================================================

function country = lookup_entity_country(entity_name, entity_country_map, use_map, fallback_country)
% LOOKUP_ENTITY_COUNTRY Get country for entity from mapping or fallback

    country = fallback_country;
    
    if use_map && isKey(entity_country_map, entity_name)
        country = entity_country_map(entity_name);
    end
    
    if isempty(country)
        country = 'UNKNOWN';
    end
    fprintf('    DEBUG: entity_name: %s mapped country: %s\n', entity_name, country);
end


function entities = add_or_update_entity(entities, name, exposure, country)
% ADD_OR_UPDATE_ENTITY Add new entity or update existing entity's exposure

    if isempty(name)
        return;
    end
    
    % Find existing entity
    idx = 0;
    for ii = 1:length(entities)
        if strcmpi(entities(ii).name, name)
            idx = ii;
            break;
        end
    end
    
    if idx == 0
        % Add new entity
        idx = length(entities) + 1;
        entities(idx).name = name;
        entities(idx).exposure = 0;
        entities(idx).country = 'UNKNOWN';
    end
    
    % Update exposure
    entities(idx).exposure = entities(idx).exposure + exposure;
    
    % Update country (prefer non-UNKNOWN)
    if strcmpi(entities(idx).country, 'UNKNOWN') && ~strcmpi(country, 'UNKNOWN')
        entities(idx).country = country;
    end
    
end


function entities = add_or_update_entity_with_list(entities, name, exposure, country, list_field, list_value)
% ADD_OR_UPDATE_ENTITY_WITH_LIST Add entity with a list field (e.g., serves_positions)

    if isempty(name)
        return;
    end
    
    % Find existing entity
    idx = 0;
    for ii = 1:length(entities)
        if strcmpi(entities(ii).name, name)
            idx = ii;
            break;
        end
    end
    
    if idx == 0
        % Add new entity
        idx = length(entities) + 1;
        entities(idx).name = name;
        entities(idx).exposure = 0;
        entities(idx).country = 'UNKNOWN';
        entities(idx).(list_field) = {};
    end
    
    % Update exposure
    entities(idx).exposure = entities(idx).exposure + exposure;
    
    % Update country (prefer non-UNKNOWN)
    if strcmpi(entities(idx).country, 'UNKNOWN') && ~strcmpi(country, 'UNKNOWN')
        entities(idx).country = country;
    end
    
    % Update list if value provided
    if ~isempty(list_value)
        if ~isfield(entities(idx), list_field)
            entities(idx).(list_field) = {};
        end
        current_list = entities(idx).(list_field);
        if ~any(strcmpi(current_list, list_value))
            entities(idx).(list_field) = [current_list, {list_value}];
        end
    end
    
end


function countries = add_or_update_country(countries, code, exposure)
% ADD_OR_UPDATE_COUNTRY Add or update country exposure

    if isempty(code)
        return;
    end
    
    idx = 0;
    for ii = 1:length(countries)
        if strcmpi(countries(ii).code, code)
            idx = ii;
            break;
        end
    end
    
    if idx == 0
        idx = length(countries) + 1;
        countries(idx).code = code;
        countries(idx).exposure = 0;
    end
    
    countries(idx).exposure = countries(idx).exposure + exposure;
    
end


function clean_str = sanitize_yaml(input_str)
% SANITIZE_YAML Clean string for safe YAML output

    if isempty(input_str)
        clean_str = 'UNKNOWN';
        return;
    end
    
    if iscell(input_str)
        input_str = input_str{1};
    end
    
    clean_str = strtrim(input_str);
    clean_str = strrep(clean_str, '"', '''');
    clean_str = strrep(clean_str, '\', '\\');
    clean_str = strrep(clean_str, ':', ' -');
    
    if isempty(clean_str)
        clean_str = 'UNKNOWN';
    end
    
end


function result = isnull(value)
% ISNULL Check if value is null/empty

    if isempty(value)
        result = true;
    elseif ischar(value) && (strcmpi(value, '') || strcmpi(value, 'NULL'))
        result = true;
    elseif iscell(value) && isempty(value{1})
        result = true;
    else
        result = false;
    end
    
end


function [entity_country_map] = get_entity_country_map()
% GET_ENTITY_COUNTRY_MAP Return mapping of entity names to ISO 3166-1 alpha-2 country codes
%
% Usage:
%   entity_country_map = get_entity_country_map();
%   country = entity_country_map('BlackRock');  % Returns 'US'
%
% This function returns a containers.Map object mapping entity names to their
% country of domicile. Use this to enrich network exposure data with correct
% country codes for DebtRank analysis.
%
% Country codes follow ISO 3166-1 alpha-2 standard:
%   DE = Germany, US = United States, IE = Ireland, LU = Luxembourg,
%   FR = France, NL = Netherlands, GB = United Kingdom, CH = Switzerland
%
% Note: Country of domicile refers to where the entity is legally headquartered,
% NOT where instruments are domiciled (e.g., BlackRock US vs iShares Ireland)

    % =========================================================================
    % ENTITY -> COUNTRY MAPPING
    % =========================================================================
    % Format: {'Entity Name', 'Country Code'}
    %
    % Sources:
    %   - Company registration / headquarters location
    %   - LEI (Legal Entity Identifier) database
    %   - Regulatory filings
    
    mapping_data = {
        % -----------------------------------------------------------------
        % CUSTODIAN BANKS (Direct)
        % -----------------------------------------------------------------
        'comdirect Bank',                       'DE';  % Germany (now part of Commerzbank)
        'Commerzbank',                          'DE';  % Germany
        'Equatex',                              'CH';  % Switzerland (employee equity plans)
        'Pensionskasse der Deutschen Wirtschaft', 'DE';  % Germany
        'Deutsche Beamtenkasse',                'DE';  % Germany
        'Allianz',                              'DE';  % Germany
        'Wallet',                               'XX';  % Crypto/Self-custody (no jurisdiction)
        'Physical',                             'XX';  % Physical assets (no jurisdiction)
        
        % -----------------------------------------------------------------
        % ISSUERS - ETF Providers
        % -----------------------------------------------------------------
        'BlackRock',                            'US';  % United States (parent company)
        'iShares',                              'US';  % United States (BlackRock subsidiary)
        'Vanguard',                             'US';  % United States
        'Amundi',                               'FR';  % France
        'Xtrackers',                            'DE';  % Germany (DWS/Deutsche Bank)
        'DWS',                                  'DE';  % Germany
        'SPDR',                                 'US';  % United States (State Street)
        'Invesco',                              'US';  % United States
        'WisdomTree',                           'US';  % United States
        'VanEck',                               'US';  % United States
        'Lyxor',                                'FR';  % France (now Amundi)
        'UBS ETF',                              'CH';  % Switzerland
        'HSBC ETF',                             'GB';  % United Kingdom
        
        % -----------------------------------------------------------------
        % ISSUERS - Banks / Certificate Issuers
        % -----------------------------------------------------------------
        'Deutsche Bank',                        'DE';  % Germany
        'BNP Paribas',                          'FR';  % France
        'Societe Generale',                     'FR';  % France
        'Societe General',                     'FR';  % France
        'Goldman Sachs',                        'US';  % United States
        'JPMorgan',                             'US';  % United States
        'Morgan Stanley',                       'US';  % United States
        'Citibank',                             'US';  % United States
        'Bank of America',                      'US';  % United States
        'Credit Suisse',                        'CH';  % Switzerland (now UBS)
        'UBS',                                  'CH';  % Switzerland
        'Barclays',                             'GB';  % United Kingdom
        'HSBC',                                 'GB';  % United Kingdom
        'ING',                                  'NL';  % Netherlands
        
        % -----------------------------------------------------------------
        % ISSUERS - Sovereigns / Government
        % -----------------------------------------------------------------
        'Germany',                              'DE';  % German Government
        'German Government',                    'DE';  % German Government
        'Bundesrepublik Deutschland',           'DE';  % German Government
        'France',                               'FR';  % French Government
        'United States',                        'US';  % US Government
        'US Treasury',                          'US';  % US Government
        'Italy',                                'IT';  % Italian Government
        'Spain',                                'ES';  % Spanish Government
        'Netherlands',                          'NL';  % Dutch Government
        'Austria',                              'AT';  % Austrian Government
        'European Union',                       'EU';  % EU Bonds
        'EIB',                                  'LU';  % European Investment Bank
        'KfW',                                  'DE';  % Kreditanstalt für Wiederaufbau
        
        % -----------------------------------------------------------------
        % CUSTODIAN UNDERLYING (Sub-custodians)
        % -----------------------------------------------------------------
        'State Street',                         'US';  % United States
        'Brown Brothers Harriman',              'US';  % United States
        'BNY Mellon',                           'US';  % United States
        'Northern Trust',                       'US';  % United States
        'CACEIS',                               'FR';  % France (Credit Agricole subsidiary)
        'Clearstream',                          'LU';  % Luxembourg (Deutsche Börse)
        'Euroclear',                            'BE';  % Belgium
        'SIX SIS',                              'CH';  % Switzerland
        'Societe Generale Securities Services', 'FR';  % France
        
        % -----------------------------------------------------------------
        % DESIGNATED SPONSORS / MARKET MAKERS
        % -----------------------------------------------------------------
        'Baader Bank',                          'DE';  % Germany
        'Flow Traders',                         'NL';  % Netherlands
        'Optiver',                              'NL';  % Netherlands
        'Jane Street',                          'US';  % United States
        'Virtu Financial',                      'US';  % United States
        'Citadel Securities',                   'US';  % United States
        'IMC',                                  'NL';  % Netherlands
        'Susquehanna',                          'US';  % United States
        'DRW',                                  'US';  % United States
        'XTX Markets',                          'GB';  % United Kingdom
        'Tower Research',                       'US';  % United States
        
        % -----------------------------------------------------------------
        % INSURANCE / PENSION
        % -----------------------------------------------------------------
        'Munich Re',                            'DE';  % Germany
        'Swiss Re',                             'CH';  % Switzerland
        'AXA',                                  'FR';  % France
        'Zurich Insurance',                     'CH';  % Switzerland
        'Generali',                             'IT';  % Italy
        'Aegon',                                'NL';  % Netherlands
        'Aviva',                                'GB';  % United Kingdom
        'MetLife',                              'US';  % United States
    };
    
    % =========================================================================
    % BUILD CONTAINERS.MAP
    % =========================================================================
    
    entity_names = mapping_data(:, 1);
    country_codes = mapping_data(:, 2);
    
    entity_country_map = containers.Map(entity_names, country_codes);
    
end


function country = lookup_country(entity_name, entity_country_map)
% LOOKUP_COUNTRY Get country code for entity, return 'UNKNOWN' if not found
%
% Usage:
%   country = lookup_country('BlackRock', entity_country_map);

    if isKey(entity_country_map, entity_name)
        country = entity_country_map(entity_name);
    else
        country = 'UNKNOWN';
        fprintf('WARNING: No country mapping for entity: %s\n', entity_name);
    end
    
end


function print_entity_country_table()
% PRINT_ENTITY_COUNTRY_TABLE Print formatted table of all entity-country mappings
%
% Usage:
%   print_entity_country_table()

    entity_country_map = get_entity_country_map();
    
    keys_cell = keys(entity_country_map);
    values_cell = values(entity_country_map);
    
    fprintf('\n');
    fprintf('=================================================================\n');
    fprintf('ENTITY -> COUNTRY MAPPING TABLE\n');
    fprintf('=================================================================\n');
    fprintf('%-45s | %s\n', 'Entity Name', 'Country');
    fprintf('-----------------------------------------------------------------\n');
    
    % Sort by country, then by name
    [~, sort_idx] = sortrows([values_cell', keys_cell']);
    
    for ii = 1:length(sort_idx)
        idx = sort_idx(ii);
        fprintf('%-45s | %s\n', keys_cell{idx}, values_cell{idx});
    end
    
    fprintf('=================================================================\n');
    fprintf('Total entities: %d\n', length(keys_cell));
    fprintf('=================================================================\n');
    
end


function entity_country_map = add_entity_country(entity_country_map, entity_name, country_code)
% ADD_ENTITY_COUNTRY Add or update entity-country mapping
%
% Usage:
%   entity_country_map = add_entity_country(entity_country_map, 'New Entity', 'DE');

    entity_country_map(entity_name) = country_code;
    
end


% =========================================================================
% COUNTRY CODE REFERENCE
% =========================================================================
% ISO 3166-1 alpha-2 codes commonly used:
%
%   AT = Austria
%   BE = Belgium
%   CH = Switzerland
%   DE = Germany
%   ES = Spain
%   EU = European Union (supranational)
%   FR = France
%   GB = United Kingdom
%   IE = Ireland
%   IT = Italy
%   JP = Japan
%   LU = Luxembourg
%   NL = Netherlands
%   US = United States
%   XX = No jurisdiction / Self-custody
%
% =========================================================================

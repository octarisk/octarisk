classdef Position
    %TODO: make this Position object, also container for information in position.csv linked to portfolio and instrument ids
    % print method: print to TPT compatible csv file
    % parse method: parse information from positons.csv into this object, also allow for further columns named tpt_x where x stands for tpt number
   % file: @Position/Position.m
    properties % all Tripartite Template Properties are listed here
        id = 'pos_id';  % required for octarisk object id, equal to tpt_14
        name = 'PositionName'; % equal tpt_17
        description = '';
        type = 'Position'; % ['Position', 'Portfolio']
        currency = 'EUR';
        quantity = 0;    % equal tpt_18
        value_base = 0;  % equal tpt_19;
        port_id  = 'PortfolioID';       % equal tpt_1 --> Position/Portfolio contained in this portfolio
        positions = struct(); % struct containing all underlying position objects;
        % risk figures
        var_confidence = 0.995;
        varhd_abs = 0;
        varhd_rel = 0;
        varhd_abs_at = 0; % after tax VaR
        varhd_rel_at = 0; % after tax VaR
        var_abs = 0;
        var_positionsum = 0;
        diversification_ratio = 0; % only filled for Portfolio
        tax_benefit = 0.0;	% portfolio attribute
        tax_rate = 0.0;	% position attribute
        dtl = 0.0;	% deferred tax liability, portfolio attribute
        decomp_varhd = 0.0; % only filled for Positions
        valuation_date = today;
        reporting_date = today;
        scenario_numbers = [];
        aa_target_id = '';	% target asset allocation {'equity','alternative'}
        aa_target_values = []; % target asset allocation values [0.6,0.4]
        equity_target_region_id = ''; % target region allocation {'Europe','NorthAmerica'}
		equity_target_region_values = []; % target asset allocation values [0.6,0.4]
		min_req_cash = 0;
        hist_base_values = [];	% historical base values
        hist_var_abs = []; % historical VaR absolute
        hist_report_dates = ''; % historical reporting dates
        hist_cashflow = [];	% portfolio cash in or outflows per historic report date
        current_cashflow = 0; % cash in or outflow of current reporting date
        srri_target = 4; % portfolio only: target SRRI class
        custodian_bank = '';	% information about where lies security
        mean_shock = 0;
        std_shock = 0;
        skewness_shock = 0;
        kurtosis_shock = 0;   
        expshortfall_rel = 0;
        expshortfall_abs = 0;   
        var50_abs      = 0;
		var70_abs      = 0;
		var84_abs      = 0;
		var90_abs      = 0;
		var95_abs      = 0;
		var975_abs     = 0;
		var99_abs      = 0;
		var999_abs     = 0;
		var9999_abs    = 0;
		marg_var = 0; % only relevant for positions
		incr_var = 0; % only relevant for positions 
        % Tripartite Template attributes:
        % % Portfolio Attributes
        tpt_1 = 'PortfolioID'; % 1_Portfolio_identifying_data Portfolio / PortfolioID / Code
        tpt_2 = '1'; % 2_Type_of_identification_code_for_the_fund_share_or_portfolio Portfolio / PortfolioID / CodificationSystem
        tpt_3 = 'Portfolioname'; % 3_Portfolio_name Portfolio / PorfolioName
        tpt_4 = 'EUR'; % 4_Portfolio_currency_(B) Portfolio / PortfolioCurrency
        tpt_5 = 0; % 5_Net_asset_valuation_of_the_portfolio_or_the_share_class_in_portfolio_currency Portfolio / TotalNetAssets
        tpt_6 = datestr(today,29); % 6_Valuation_date Portfolio / ValuationDate
        tpt_7 = datestr(today,29); % 7_Reporting_date Portfolio / ReportingDate
        tpt_8 = 0; % 8_Share_price Portfolio / ShareClass / SharePrice
        tpt_8b = 0; % 8b_Total_number_of_shares Portfolio / ShareClass / TotalNumberOfShares
        tpt_9 = 0; % 9_Cash_ratio Portfolio / CashPercentage
        tpt_10 = 0; % 10_Portfolio_modified_duration Portfolio / PortfolioModifiedDuration
        tpt_11 = 'Y'; % 11_Complete_SCR_delivery Portfolio / CompleteSCRDelivery
        tpt_115 = ''; % 115_Fund_issuer_code Portfolio / QRTPortfolioInformation / FundIssuer / Code / Code
        tpt_116 = ''; % 116_Fund_issuer_code_type Portfolio / QRTPortfolioInformation / FundIssuer / Code / CodificationSystem
        tpt_117 = ''; % 117_Fund_issuer_name Portfolio / QRTPortfolioInformation / FundIssuer / Name
        tpt_118 = ''; % 118_Fund_issuer_sector Portfolio / QRTPortfolioInformation / FundIssuer / EconomicSector
        tpt_119 = ''; % 119_Fund_issuer_group_code Portfolio / QRTPortfolioInformation / FundIssuerGroup / Code / Code
        tpt_120 = ''; % 120_Fund_issuer_group_code_type Portfolio / QRTPortfolioInformation / FundIssuerGroup / Code / CodificationSystem
        tpt_121 = ''; % 121_Fund_issuer_group_name Portfolio / QRTPortfolioInformation / FundIssuerGroup / Name
        tpt_122 = ''; % 122_Fund_issuer_country Portfolio / QRTPortfolioInformation / FundIssuer / Country
        tpt_123 = ''; % 123_Fund_CIC Portfolio / QRTPortfolioInformation / PortfolioCIC
        tpt_123a = ''; % 123a_Fund_custodian_country Portfolio / QRTPortfolioInformation / FundCustodianCountry
        tpt_124 = 0; % 124_Duration Portfolio / QRTPortfolioInformation / PortfolioModifiedDuration
        tpt_125 = 0; % 125_Accrued_income_(Security Denominated Currency) Portfolio / QRTPortfolioInformation /  AccruedIncomeQC ????
        tpt_126 = 0; % 126_Accrued_income_(Portfolio Denominated Currency) Portfolio / QRTPortfolioInformation / AccruedIncomePC
        % Position attributes
        tpt_12 = ''; % 12_CIC_code_of_the_instrument Position / InstrumentCIC
        tpt_13 = []; % 13_Economic_zone_of_the_quotation_place Position / EconomicArea
        tpt_14 = ''; % 14_Identification_code_of_the_instrument Position / InstrumentCode / Code
        tpt_15 = 1; % 15_Type_of_identification_code_for_the_instrument Position / InstrumentCode / CodificationSystem
        tpt_16 = ''; % 16_Grouping_code_for_multiple_leg_instruments Position / GroupID
        tpt_17 = ''; % 17_Instrument_name Position / InstrumentName
        tpt_17b = ''; % 17b_Asset_liability Position / Valuation / AssetOrLiability
        tpt_18 = []; % 18_Quantity Position / Valuation / Quantity
        tpt_19 = []; % 19_Nominal_amount Position / Valuation / TotalNominalValueQC
        tpt_20 = []; % 20_Contract_size_for_derivatives Position / Valuation / ContractSize
        tpt_21 = ''; % 21_Quotation_currency_(A) Position / Valuation / QuotationCurrency
        tpt_22 = []; % 22_Market_valuation_in_quotation_currency_(A) Position / Valuation / MarketValueQC
        tpt_23 = []; % 23_Clean_market_valuation_in_quotation_currency_(A) Position / Valuation / CleanValueQC
        tpt_24 = []; % 24_Market_valuation_in_portfolio_currency_(B) Position / Valuation / MarketValuePC
        tpt_25 = []; % 25_Clean_market_valuation_in_portfolio_currency_(B) Position / Valuation / CleanValuePC
        tpt_26 = []; % 26_Valuation_weight Position / Valuation / PositionWeight
        tpt_27 = []; % 27_Market_exposure_amount_in_quotation_currency_(A) Position / Valuation / MarketExposureQC
        tpt_28 = []; % 28_Market_exposure_amount_in_portfolio_currency_(B) Position / Valuation / MarketExposurePC
        tpt_29 = []; % 29_Market_exposure_amount_for_the_3rd_quotation_currency_(C) Position / Valuation / MarketExposureLeg2
        tpt_30 = []; % 30_Market_exposure_in_weight Position / Valuation / MarketExposureWeight
        tpt_31 = []; % 31_Market_exposure_for_the_3rd_currency_in_weight_over_NAV Position / Valuation / MarketExposureWeightLeg2
        tpt_32 = ''; % 32_Interest_rate_type Position / BondCharacteristics / RateType
        tpt_33 = []; % 33_Coupon_rate Position / BondCharacteristics / CouponRate
        tpt_34 = ''; % 34_Interest_rate_reference_identification Position / BondCharacteristics / VariableRate / IndexID / Code
        tpt_35 = ''; % 35_Identification_type_for_interest_rate_index Position / BondCharacteristics / VariableRate / IndexID / CodificationSystem
        tpt_36 = ''; % 36_Interest_rate_index_name Position / BondCharacteristics / VariableRate / IndexName
        tpt_37 = ''; % 37_Interest_rate_margin Position / BondCharacteristics / VariableRate / Margin
        tpt_38 = []; % 38_Coupon_payment_frequency Position / BondCharacteristics / CouponFrequency
        tpt_39 = ''; % 39_Maturity_date Position / BondCharacteristics / Redemption / MaturityDate
        tpt_40 = ''; % 40_Redemption_type Position / BondCharacteristics / Redemption /Type
        tpt_41 = []; % 41_Redemption_rate Position / BondCharacteristics / Redemption / Rate
        tpt_42 = ''; % 42_Callable_putable Position / BondCharacteristics / OptionalCallPut / CallPutType
        tpt_43 = ''; % 43_Call_put_date Position / BondCharacteristics / OptionalCallPut / CallPutDate
        tpt_44 = 'B'; % 44_Issuer_bearer_option_exercise Position / BondCharacteristics / OptionalCallPut / OptionDirection
        tpt_45 = []; % 45_Strike_price_for_embedded_(call_put)_options Position / BondCharacteristics / OptionalCallPut / StrikePrice
        tpt_46 = ''; % 46_Issuer_name Position / CreditRiskData / InstrumentIssuer / Name
        tpt_47 = ''; % 47_Issuer_identification_code Position / CreditRiskData / InstrumentIssuer / Code / Code
        tpt_48 = 9; % 48_Type_of_identification_code_for_issuer Position / CreditRiskData / InstrumentIssuer / Code / CodificationSystem
        tpt_49 = ''; % 49_Name_of_the_group_of_the_issuer Position / CreditRiskData / IssuerGroup / Name
        tpt_50 = ''; % 50_Identification_of_the_group Position / CreditRiskData / IssuerGroup / Code / Code
        tpt_51 = 9; % 51_Type_of_identification_code_for_issuer_group Position / CreditRiskData / IssuerGroup / Code / CodificationSystem
        tpt_52 = ''; % 52_Issuer_country Position / CreditRiskData / IssuerCountry
        tpt_53 = 1; % 53_Issuer_economic_area Position / CreditRiskData / EconomicArea
        tpt_54 = ''; % 54_Economic_sector Position / CreditRiskData / EconomicSector
        tpt_55 = ''; % 55_Covered_not_covered Position / CreditRiskData / Covered
        tpt_56 = ''; % 56_Securitisation Position / Securitisation / Securitised
        tpt_57 = ''; % 57_Explicit_guarantee_by_the_country_of_issue Position / CreditRiskData / StateGuarantee
        tpt_58 = ''; % 58_Subordinated_debt Position / SubordinatedDebt
        tpt_58b = ''; % 58b_Nature_of_the_tranche Position / Securitisation / TrancheLevel
        tpt_59 = 9; % 59_Credit_quality_step Position / CreditRiskData / CreditQualitStep
        tpt_60 = ''; % 60_Call_Put_Cap_Floor Position / DerivativeOrConvertible / OptionCharacteristics / CallPutType
        tpt_61 = []; % 61_Strike_price Position / DerivativeOrConvertible / OptionCharacteristics / StrikePrice
        tpt_62 = []; % 62_Conversion_factor_(convertibles)_concordance_factor_parity_(options) Position / DerivativeOrConvertible / OptionCharacteristics / ConversionRatio
        tpt_63 = ''; % 63_Effective_date_of_instrument Position / DerivativeOrConvertible / OptionCharacteristics / Effective Date
        tpt_64 = ''; % 64_Exercise_type Position / DerivativeOrConvertible / OptionCharacteristics / OptionStyle
        tpt_65 = ''; % 65_Hedging_rolling Position / HedgingStrategy
        tpt_67 = ''; % 67_CIC_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / InstrumentCIC
        tpt_68 = '1'; % 68_Identification_code_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / InstrumentCode / Code
        tpt_69 = 1; % 69_Type_of_identification_code_for_the_underlying_asset Position / UnderlyingInstrument / InstrumentCode / CodificationSystem
        tpt_70 = ''; % 70_Name_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / InstrumentName
        tpt_71 = ''; % 71_Quotation_currency_of_the_underlying_asset_(C) Position / DerivativeOrConvertible /  UnderlyingInstrument / Valuation / Currency
        tpt_72 = []; % 72_Last_valuation_price_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / Valuation / MarketPrice
        tpt_73 = ''; % 73_Country_of_quotation_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / Valuation / Country
        tpt_74 = 1; % 74_Economic_area_of_quotation_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / Valuation / EconomicArea
        tpt_75 = []; % 75_Coupon_rate_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / BondCharacteristics / CouponRate
        tpt_76 = 1; % 76_Coupon_payment_frequency_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / BondCharacteristics / CouponFrequency
        tpt_77 = ''; % 77_Maturity_date_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / BondCharacteristics / Redemption / MaturityDate
        tpt_78 = ''; % 78_Redemption_profile_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / BondCharacteristics / Redemption / Type
        tpt_79 = []; % 79_Redemption_rate_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / BondCharacteristics / Redemption / Rate
        tpt_80 = ''; % 80_Issuer_name_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / InstrumentIssuer / Name
        tpt_81 = ''; % 81_Issuer_identification_code_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / InstrumentIssuer / Code / Code
        tpt_82 = 9; % 82_Type_of_issuer_identification_code_of_the_underlying_asset Position / UnderlyingInstrument / Issuer / InstrumentIssuer / Identification / Code
        tpt_83 = ''; % 83_Name_of_the_group_of_the_issuer_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / IssuerGroup / Name
        tpt_84 = ''; % 84_Identification_of_the_group_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / IssuerGroup / Code / Code
        tpt_85 = 9; % 85_Type_of_the_group_identification_code_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / IssuerGroup / Code / CodificationSystem
        tpt_86 = ''; % 86_Issuer_country_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / Country
        tpt_87 = 1; % 87_Issuer_economic_area_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / EconomicArea
        tpt_88 = ''; % 88_Explicit_guarantee_by_the_country_of_issue_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData  / StateGuarantee
        tpt_89 = []; % 89_Credit_quality_step_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData  / CreditQualityStep
        tpt_90 = []; % 90_Modified_duration_to_maturity_date Position / Analytics / ModifiedDurationToMaturity
        tpt_91 = []; % 91_Modified_duration_to_next_option_exercise_date Position / Analytics / ModifiedDurationToCall
        tpt_92 = []; % 92_Credit_sensitivity Position / Analytics / CreditSensitivity
        tpt_93 = []; % 93_Sensitivity_to_underlying_asset_price_(delta) Position / Analytics / Delta
        tpt_94 = []; % 94_Convexity_gamma_for_derivatives Position / Analytics / Convexity
        tpt_94b = []; % 94b_Vega Position / Analytics / Vega
        tpt_95 = ''; % 95_Identification_of_the_original_portfolio_for_positions_embedded_in_a_fund Position / LookThroughISIN
        tpt_97 = []; % 97_SCR_mrkt_IR_up_weight_over_NAV Position / ContributionToSCR / MktIntUp
        tpt_98 = []; % 98_SCR_mrkt_IR_down_weight_over_NAV Position / ContributionToSCR / MktintDown
        tpt_99 = []; % 99_SCR_mrkt_eq_type1_weight_over_NAV Position / ContributionToSCR / MktEqGlobal
        tpt_100 = []; % 100_SCR_mrkt_eq_type2_weight_over_NAV Position / ContributionToSCR / MktEqOther
        tpt_101 = []; % 101_SCR_mrkt_prop_weight_over_NAV Position / ContributionToSCR / MktProp
        tpt_102 = []; % 102_SCR_mrkt_spread_bonds_weight_over_NAV Position / ContributionToSCR / MktSpread / Bonds
        tpt_103 = []; % 103_SCR_mrkt_spread_structured_weight_over_NAV Position / ContributionToSCR / MktSpread / Structured
        tpt_104 = []; % 104_SCR_mrkt_spread_derivatives_up_weight_over_NAV Position / ContributionToSCR / MktSpread / DerivativesUp
        tpt_105 = []; % 105_SCR_mrkt_spread_derivatives_down_weight_over_NAV Position / ContributionToSCR / MktSpread / DerivativesDown
        tpt_105a = []; % 105a_SCR_mrkt_FX_up_weight_over_NAV Position / ContributionToSCR / MktFXUp
        tpt_105b = []; % 105b_SCR_mrkt_FX_down_weight_over_NAV Position / ContributionToSCR / MktFXDown
        tpt_106 = 9; % 106_Asset_pledged_as_collateral Position / QRTPositionInformation / CollateralisedAsset
        tpt_107 = ''; % 107_Place_of_deposit Position / QRTPositionInformation / PlaceOfDeposit
        tpt_108 = 2; % 108_Participation Position / QRTPositionInformation / Participation
        tpt_110 = 1; % 110_Valorisation_method Position / QRTPositionInformation / ValorisationMethod
        tpt_111 = []; % 111_Value_of_acquisition Position / QRTPositionInformation / AverageBuyPrice
        tpt_112 = ''; % 112_Credit_rating Position / QRTPositionInformation / CounterpartyRating / RatingValue
        tpt_113 = ''; % 113_Rating_agency Position / QRTPositionInformation / CounterpartyRating / RatingAgency
        tpt_114 = 1; % 114_Issuer_economic_area Position / QRTPositionInformation / IssuerEconomicArea
        tpt_127 = []; % 127_Bond_floor_(convertible_instrument_only) Position / DerivativeOrConvertible / OptionCharacteristics / Convertible / BondFloor
        tpt_128 = []; % 128_Option_premium_(convertible_instrument_only) Position / DerivativeOrConvertible / OptionCharacteristics / Convertible / OptionPremium
        tpt_129 = []; % 129_Valuation_yield Position / BondCharacteristics / ValuationYieldCurve /  Yield
        tpt_130 = []; % 130_Valuation_z_spread Position / BondCharacteristics / ValuationYieldCurve /  Spread
        tpt_131 = '1'; % 131_Underlying_asset_category Position / Instrument/ UAC
        tpt_132 = []; % 132_Infrastructure_investment To be defined with Fundxml
        tpt_133 = ''; % 133_custodian_name To be defined with Fundxml
        tpt_1000 = 'V4.0'; % 1000_tpt_Version 
        position_failed_cell = {}; 
        aggr_key_struct = struct();
        report_struct = struct();
        region_values = [0,0,0,0]; 
		style_values = [0,0,0,0,0,0,0,0,0];
		rating_values = [0,0,0];
		duration_values = [0,0,0]; 
		country_values = [1,0];
		region_id = {'Europe','NorthAmerica','Pacific','EmergingMarkets'};
		rating_id = {'HighGrade','InvGrade','HighYield'};
		style_id = {'LargeValue','LargeBlend','LargeGrowth','MidValue','MidBlend','MidGrowth','SmallValue','SmallBlend','SmallGrowth'};
		duration_id = {'Low<3','Mid3-7','High>7'};
		country_id = {'US','Other'};
		esg_score = [];
    end
    
    properties (SetAccess = protected )
      value_stress = [];
      value_mc = [];
      value_mc_at = [];
      timestep_mc = {};
      exposure_base = [];
      exposure_mc = [];
      exposure_stress = [];
      cf_dates = [];
      cf_values = [];
      cf_values_mc  = [];
      cf_values_stress = [];
      timestep_mc_cf = {};
    end
 
   % Class methods
   methods
      function a = Position(tmp_name)
       % Position Constructor method
        if nargin < 1
            name        = '';
            tmp_id      = 'pos_id';
        else
            name        = tmp_name;
            tmp_id      = tmp_name;
        end
        tmp_description = 'Octarisk Position Object';
        tmp_type        = 'Position';
        a.name          = name;
        a.id            = tmp_id;
        a.description   = tmp_description;
        a.type          = lower(tmp_type);                             
      end % Position
      
      function disp(a)
         % Display a Position object
         % Get length of Value vector:
         fprintf('name: %s\nid: %s\ndescription: %s\ntype: %s\n', ... 
            a.name,a.id,a.description,a.type);
         fprintf('quantity: %s\n',any2str(a.quantity));
         fprintf('currency: %s\n',any2str(a.currency));
         fprintf('port_id: %s\n',any2str(a.port_id));
         % Get length of Value vector:
         value_stress_rows = min(rows(a.value_stress),5);
         value_mc_rows = min(rows(a.value_mc),5);
         value_mc_cols = min(length(a.timestep_mc),2);
         fprintf('value_base: %12.2f %s\n',a.value_base,a.currency);
         fprintf('varhd_abs@%2.1f%%: %12.2f %s\n',a.var_confidence*100,a.varhd_abs,a.currency);
         fprintf('varhd_rel@%2.1f%%: %2.1f%% \n',a.var_confidence*100,a.varhd_rel*100);
         fprintf('value_stress: %8.6f \n',a.value_stress(1:value_stress_rows));
         fprintf('diversification_ratio: %2.1f%% \n',a.diversification_ratio*100);
         % TODO: print SCR stresses PnL if flag set
         % fprintf('\n');
         % % looping via first 5 MC scenario values
         % for ( ii = 1 : 1 : value_mc_cols)
            % fprintf('MC timestep: %s\n',a.timestep_mc{ii});
            % fprintf('Scenariovalues:\n[ ')
                % for ( jj = 1 : 1 : value_mc_rows)
                    % fprintf('%8.6f,\n',a.value_mc(jj,ii));
                % end
            % fprintf(' ]\n');
         % end
         %props = fieldnames(a);
         if (strcmpi(a.type,'Position'))
            fprintf('Incremental VaR: %s %s\n',any2str(a.incr_var),a.currency);
            fprintf('Marginal VaR: %s %s\n',any2str(a.marg_var),a.currency);
            fprintf('tax_rate: %3.4f\n',a.tax_rate); 
            fprintf('TPT Position data:\n');
            fprintf('1_Portfolio_identifying_data: %s\n',any2str(a.tpt_1));
            fprintf('14_Identification_code_of_the_instrument: %s\n',any2str(a.tpt_14));
            fprintf('17_Instrument_name: %s\n',any2str(a.tpt_17));
            fprintf('17b_Asset_liability: %s\n',any2str(a.tpt_17b));
            fprintf('18_Quantity: %s\n',any2str(a.tpt_18));
            fprintf('21_Quotation_currency_(A): %s\n',any2str(a.tpt_21));
            fprintf('22_Market_valuation_in_quotation_currency_(A): %12.2f\n',a.tpt_22);        
            fprintf('32_Interest_rate_type: %s\n',a.tpt_32);        
            fprintf('90_Modified_duration_to_maturity_date: %s\n',any2str(a.tpt_90));  
         elseif (strcmpi(a.type,'Portfolio'))
            fprintf('TPT Portfolio data:\n');
            fprintf('1_Portfolio_identifying_data: %s\n',any2str(a.tpt_1));
            fprintf('4_Portfolio_currency_(B): %s\n',any2str(a.tpt_4));
            fprintf('5_Net_asset_valuation_of_the_portfolio_or_the_share_class_in_portfolio_currency: %12.2f\n',a.tpt_5);
            fprintf('6_Valuation_date: %s\n',any2str(a.tpt_6));
            fprintf('7_Reporting_date: %s\n',any2str(a.tpt_7)); 
            fprintf('9_Cash_ratio: %3.2f %%\n',a.tpt_9); 
            fprintf('124_Duration Portfolio: %s\n',any2str(a.tpt_124)); 
            fprintf('mean_shock: %3.2f \n',a.mean_shock); 
            fprintf('std_shock: %3.2f \n',a.std_shock); 
            fprintf('skewness_shock: %3.2f \n',a.skewness_shock); 
            fprintf('kurtosis_shock: %3.2f \n',a.kurtosis_shock); 
            fprintf('expshortfall_abs@%2.1f%%: %12.2f \n',a.var_confidence*100,a.expshortfall_abs);
            fprintf('expshortfall_rel@%2.1f%%: %2.1f%% \n',a.var_confidence*100,a.expshortfall_rel*100);
            fprintf('varhd_abs_after_tax@%2.1f%%: %12.2f %s\n',a.var_confidence*100,a.varhd_abs_at,a.currency);
			fprintf('varhd_rel_after_tax@%2.1f%%: %2.1f%% \n',a.var_confidence*100,a.varhd_rel_at*100);
			fprintf('tax_benefit: %12.2f %s\n',a.tax_benefit,a.currency); 
			fprintf('deferred_tax_liability: %12.2f %s\n',a.dtl,a.currency); 
            fprintf('srri_target: %d \n',a.srri_target); 
            
            if ( length(a.aa_target_values) == length(a.aa_target_id) && length(a.aa_target_values) > 0 )
				fprintf('Target Asset Allocation:\n');
				for ii=1:1:length(a.aa_target_values)
					if (length(a.aa_target_id{ii}) <= 25)
						tmp_id = strcat(a.aa_target_id{ii},char(repmat(95,1,25 - length(a.aa_target_id{ii}))) );
					end
					fprintf('\t%s%2.0f%%\n',tmp_id,a.aa_target_values(ii)*100);
				end
            end
            if ( length(a.equity_target_region_values) == length(a.equity_target_region_id) && length(a.equity_target_region_values) > 0 )
				fprintf('Target Equity Region Allocation:\n');
				for ii=1:1:length(a.equity_target_region_values)
					if (length(a.equity_target_region_id{ii}) <= 25)
						tmp_id = strcat(a.equity_target_region_id{ii},char(repmat(95,1,25 - length(a.equity_target_region_id{ii}))) );
					end
					fprintf('\t%s%2.0f%%\n',tmp_id,a.equity_target_region_values(ii)*100);
				end
            end
            if ( iscell(a.hist_report_dates) && ...
					numel(a.hist_report_dates) == length(a.hist_base_values) && ...
					length(a.hist_base_values) == length(a.hist_var_abs))
				fprintf('Historical report values: \n');
				fprintf('\tReport Date | Base Value | VaR abs. | VaR rel.:\n');
				for(kk=1:1:numel(a.hist_base_values))
					fprintf('\t%s | %8.2f | %8.2f | %2.2f%%\n',a.hist_report_dates{kk},a.hist_base_values(kk),a.hist_var_abs(kk),100*a.hist_var_abs(kk)/a.hist_base_values(kk));
				end
				fprintf('\n');
            end
            fprintf('Positions (Instrument ID) | Quantity | Currency | Base Value | Standalone VaR | Decomp VaR | Incr VaR | Marg VaR):\n');
            if ( length(a.positions) > 0)
                for (ii = 2:1:length(a.positions))
                    tmp_pos_obj = a.positions(ii).object;
                    tmp_id = tmp_pos_obj.id;
                    if (length(tmp_id) <= 25)
						tmp_id = strcat(tmp_id,char(repmat(95,1,25 - length(tmp_id))) );
					end
                    fprintf('\t%s | %8.2f | %s | %8.2f | %8.2f | %8.2f | %8.2f | %8.2f\n',tmp_id,tmp_pos_obj.quantity,a.currency,tmp_pos_obj.value_base,tmp_pos_obj.varhd_abs,tmp_pos_obj.decomp_varhd,tmp_pos_obj.incr_var,tmp_pos_obj.marg_var);
                end
            end
         end

		 % display all cash flow dates and values
		 cf_stress_rows = min(rows(a.cf_values_stress),5);
		 [mc_rows mc_cols mc_stack] = size(a.cf_values_mc);
		 % looping via all cf_dates if defined
		 if ( length(a.cf_dates) > 0 )
			fprintf('Next 12 end of month CF dates:\n[ ');
			for (ii = 1 : 1 : length(a.cf_dates))
				fprintf('%d,',a.cf_dates(ii));
			end
			fprintf(' ]\n');
		 end
		 % looping via all cf base values if defined
		 if ( length(a.cf_values) > 0 )
			fprintf('Projected CF Base values:\n[ ');
			for ( kk = 1 : 1 : min(columns(a.cf_values),10))
					fprintf('%f,',a.cf_values(kk));
				end
			fprintf(' ]\n');
		 end   
		  % looping via all stress rates if defined
		 if ( rows(a.cf_values_stress) > 0 )
			tmp_cf_values = a.getCF('stress');
			fprintf('CF Stress values:\n[ ');
			for ( jj = 1 : 1 : min(rows(tmp_cf_values),5))
				for ( kk = 1 : 1 : min(columns(tmp_cf_values),10))
					fprintf('%f,',tmp_cf_values(jj,kk));
				end
				fprintf(' ]\n');
			end
			fprintf('\n');
		 end    
		 % looping via first 3 MC scenario values
		 for ( ii = 1 : 1 : mc_stack)
			if ( length(a.timestep_mc_cf) >= ii )
				tmp_cf_values = a.getCF(a.timestep_mc_cf{ii});
				if (columns(tmp_cf_values)>0)
					fprintf('MC timestep: %s\n',a.timestep_mc_cf{ii});
					fprintf('CF Scenariovalue:\n[ ')
					for ( jj = 1 : 1 : min(rows(tmp_cf_values),5))
						for ( kk = 1 : 1 : min(columns(tmp_cf_values),10))
							fprintf('%f,',tmp_cf_values(jj,kk));
						end
						fprintf(' ]\n');
					end
				fprintf('\n');
				end
			else
				fprintf('MC timestep cf not defined\n');
			end
		 end
         %~ %for (ii=1:1:length(props))
         %~ %   fprintf('%s: %s\n',props{ii},any2str(a.(props{ii})));
         %~ %end
         
      end % disp
           
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'Position') || strcmpi(type,'Portfolio')  )
            error('Type must be Position or Portfolio')
         end
         obj.type = type;
      end % Set.type

      % port_id sets tpt_1 
      function obj = set.port_id(obj,port_id)
         obj.port_id = port_id;
         obj.tpt_1 = port_id;
      end % Set.port_id 

      % quantity sets tpt_18 
      function obj = set.quantity(obj,quantity)
         obj.quantity = quantity;
         obj.tpt_18 = quantity;
      end % Set.quantity 
 
      % currency Position sets tpt_18, Portfolio sets tpt_4
      function obj = set.currency(obj,currency)
         obj.currency = currency;
         if (strcmpi(obj.type,'Position'))
            obj.tpt_21 = currency;
         elseif (strcmpi(obj.type,'Portfolio'))
             obj.tpt_4 = currency;
         end
      end % Set.currency       

      % id Position sets tpt_14, Portfolio sets tpt_1
      function obj = set.id(obj,id)
         obj.id = id;
         if (strcmpi(obj.type,'Position'))
            obj.tpt_14 = id;
         elseif (strcmpi(obj.type,'Portfolio'))
             obj.tpt_1 = id;
         end
      end % Set.id  
      
      % name Position sets tpt_17, Portfolio sets tpt_3
      function obj = set.name(obj,name)
         obj.name = name;
         if (strcmpi(obj.type,'Position'))
            obj.tpt_17 = name;
         elseif (strcmpi(obj.type,'Portfolio'))
             obj.tpt_3 = name;
         end
      end % Set.name
      
      function obj = set.valuation_date(obj,valuation_date) % convert to datenum
         if ischar(valuation_date)
            valuation_date = datenum(valuation_date);
         elseif ( isvector(valuation_date) )
            if ( length(valuation_date) > 1)
                valuation_date = datenum(valuation_date);
            end
         end
         obj.valuation_date = valuation_date;
         obj.tpt_6 = datestr(valuation_date);
      end % Set.valuation_date
      
      function obj = set.reporting_date(obj,reporting_date) % convert to datenum
         if ischar(reporting_date)
            reporting_date = datenum(reporting_date);
         elseif ( isvector(reporting_date) )
            if ( length(reporting_date) > 1)
                reporting_date = datenum(reporting_date);
            end
         end
         obj.reporting_date = reporting_date;
         obj.tpt_7 = datestr(reporting_date);
      end % Set.reporting_date
      
      
   end
   methods (Static = true)

      
       % print Help text
      function retval = help (format,retflag)
        formatcell = {'plain text','html','texinfo'};
        % input checks
        if ( nargin == 0 )
            format = 'plain text';  
        end
        if ( nargin < 2 )
            retflag = 0;    
        end

        % format check
        if ~( strcmpi(format,formatcell))
            fprintf('WARNING: Instrument.help: unknown format >>%s<<. Format must be [plain text, html or texinfo]. Setting format to plain text.\n',any2str(format));
            format = 'plain text';
        end 

% textstring in texinfo format (it is required to start at begin of line)
textstring = "@deftypefn{Octarisk Class} { @var{object} =} Position (@var{id})\n\
\n\
Position and Portfolio class.\n\
\n\
@itemize @bullet\n\
@item @var{id} (string): id of object\n\
@end itemize\n\
@*\n\
\n\
@end deftypefn";

        % format help text
        [retval status] = __makeinfo__(textstring,format);
        % status
        if (status == 0)
            % depending on retflag, return textstring
            if (retflag == 0)
                % print formatted textstring
                fprintf("\'Position\' is a class definition from the file /octarisk/@Instrument/Position.m\n");
                fprintf("\n%s\n",retval);
                retval = [];
            end
        end

      end % end of static method help
    end % end of static methods  
end % classdef

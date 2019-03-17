classdef Position
    %TODO: make this Position object, also container for information in position.csv linked to portfolio and instrument ids
    % print method: print to TPT compatible csv file
    % parse method: parse information from positons.csv into this object, also allow for further columns named TPT_x where x stands for tpt number
   % file: @Position/Position.m
    properties % all Tripartite Template Properties are listed here
        id = 'pos_id';  % required for octarisk object id, equal to TPT_14
        name = 'PositionName'; % equal TPT_17
        description = '';
        type = 'Position'; % ['Position', 'Portfolio']
        currency = 'EUR';
        quantity = 0;    % equal TPT_18
        value_base = 0;  % equal TPT_19;
        port_id  = 'PortfolioID';       % equal TPT_1 --> Position/Portfolio contained in this portfolio
        positions = struct(); % struct containing all underlying position objects;
        % Tripartite Template attributes:
        % % Portfolio Attributes
        TPT_1 = 'PortfolioID'; % 1_Portfolio_identifying_data Portfolio / PortfolioID / Code
        TPT_2 = '1'; % 2_Type_of_identification_code_for_the_fund_share_or_portfolio Portfolio / PortfolioID / CodificationSystem
        TPT_3 = 'Portfolioname'; % 3_Portfolio_name Portfolio / PorfolioName
        TPT_4 = 'EUR'; % 4_Portfolio_currency_(B) Portfolio / PortfolioCurrency
        TPT_5 = 0; % 5_Net_asset_valuation_of_the_portfolio_or_the_share_class_in_portfolio_currency Portfolio / TotalNetAssets
        TPT_6 = '2018-12-31'; % 6_Valuation_date Portfolio / ValuationDate
        TPT_7 = '2018-12-31'; % 7_Reporting_date Portfolio / ReportingDate
        TPT_8 = 0; % 8_Share_price Portfolio / ShareClass / SharePrice
        TPT_8b = 0; % 8b_Total_number_of_shares Portfolio / ShareClass / TotalNumberOfShares
        TPT_9 = 0; % 9_Cash_ratio Portfolio / CashPercentage
        TPT_10 = 0; % 10_Portfolio_modified_duration Portfolio / PortfolioModifiedDuration
        TPT_11 = 'Y'; % 11_Complete_SCR_delivery Portfolio / CompleteSCRDelivery
        TPT_115 = 'XXX'; % 115_Fund_issuer_code Portfolio / QRTPortfolioInformation / FundIssuer / Code / Code
        TPT_116 = 'XXX'; % 116_Fund_issuer_code_type Portfolio / QRTPortfolioInformation / FundIssuer / Code / CodificationSystem
        TPT_117 = 'XXX'; % 117_Fund_issuer_name Portfolio / QRTPortfolioInformation / FundIssuer / Name
        TPT_118 = 'XXX'; % 118_Fund_issuer_sector Portfolio / QRTPortfolioInformation / FundIssuer / EconomicSector
        TPT_119 = 'XXX'; % 119_Fund_issuer_group_code Portfolio / QRTPortfolioInformation / FundIssuerGroup / Code / Code
        TPT_120 = 'XXX'; % 120_Fund_issuer_group_code_type Portfolio / QRTPortfolioInformation / FundIssuerGroup / Code / CodificationSystem
        TPT_121 = 'XXX'; % 121_Fund_issuer_group_name Portfolio / QRTPortfolioInformation / FundIssuerGroup / Name
        TPT_122 = 'XXX'; % 122_Fund_issuer_country Portfolio / QRTPortfolioInformation / FundIssuer / Country
        TPT_123 = 'XXX'; % 123_Fund_CIC Portfolio / QRTPortfolioInformation / PortfolioCIC
        TPT_123a = 'XXX'; % 123a_Fund_custodian_country Portfolio / QRTPortfolioInformation / FundCustodianCountry
        TPT_124 = 0; % 124_Duration Portfolio / QRTPortfolioInformation / PortfolioModifiedDuration
        TPT_125 = 0; % 125_Accrued_income_(Security Denominated Currency) Portfolio / QRTPortfolioInformation /  AccruedIncomeQC ????
        TPT_126 = 0; % 126_Accrued_income_(Portfolio Denominated Currency) Portfolio / QRTPortfolioInformation / AccruedIncomePC
        % Position attributes
        TPT_12 = 'XXX'; % 12_CIC_code_of_the_instrument Position / InstrumentCIC
        TPT_13 = 0; % 13_Economic_zone_of_the_quotation_place Position / EconomicArea
        TPT_14 = 'PositionID'; % 14_Identification_code_of_the_instrument Position / InstrumentCode / Code
        TPT_15 = 1; % 15_Type_of_identification_code_for_the_instrument Position / InstrumentCode / CodificationSystem
        TPT_16 = '123456'; % 16_Grouping_code_for_multiple_leg_instruments Position / GroupID
        TPT_17 = 'InstrumentName'; % 17_Instrument_name Position / InstrumentName
        TPT_17b = 'A'; % 17b_Asset_liability Position / Valuation / AssetOrLiability
        TPT_18 = 0; % 18_Quantity Position / Valuation / Quantity
        TPT_19 = 0; % 19_Nominal_amount Position / Valuation / TotalNominalValueQC
        TPT_20 = 0; % 20_Contract_size_for_derivatives Position / Valuation / ContractSize
        TPT_21 = 'EUR'; % 21_Quotation_currency_(A) Position / Valuation / QuotationCurrency
        TPT_22 = 0; % 22_Market_valuation_in_quotation_currency_(A) Position / Valuation / MarketValueQC
        TPT_23 = 0; % 23_Clean_market_valuation_in_quotation_currency_(A) Position / Valuation / CleanValueQC
        TPT_24 = 0; % 24_Market_valuation_in_portfolio_currency_(B) Position / Valuation / MarketValuePC
        TPT_25 = 0; % 25_Clean_market_valuation_in_portfolio_currency_(B) Position / Valuation / CleanValuePC
        TPT_26 = 0; % 26_Valuation_weight Position / Valuation / PositionWeight
        TPT_27 = 0; % 27_Market_exposure_amount_in_quotation_currency_(A) Position / Valuation / MarketExposureQC
        TPT_28 = 0; % 28_Market_exposure_amount_in_portfolio_currency_(B) Position / Valuation / MarketExposurePC
        TPT_29 = 0; % 29_Market_exposure_amount_for_the_3rd_quotation_currency_(C) Position / Valuation / MarketExposureLeg2
        TPT_30 = 0; % 30_Market_exposure_in_weight Position / Valuation / MarketExposureWeight
        TPT_31 = 0; % 31_Market_exposure_for_the_3rd_currency_in_weight_over_NAV Position / Valuation / MarketExposureWeightLeg2
        TPT_32 = 'Fixed'; % 32_Interest_rate_type Position / BondCharacteristics / RateType
        TPT_33 = 0; % 33_Coupon_rate Position / BondCharacteristics / CouponRate
        TPT_34 = 'ReferenceID'; % 34_Interest_rate_reference_identification Position / BondCharacteristics / VariableRate / IndexID / Code
        TPT_35 = 'XXX'; % 35_Identification_type_for_interest_rate_index Position / BondCharacteristics / VariableRate / IndexID / CodificationSystem
        TPT_36 = 'ReferenceName'; % 36_Interest_rate_index_name Position / BondCharacteristics / VariableRate / IndexName
        TPT_37 = '0'; % 37_Interest_rate_margin Position / BondCharacteristics / VariableRate / Margin
        TPT_38 = 1; % 38_Coupon_payment_frequency Position / BondCharacteristics / CouponFrequency
        TPT_39 = '2018-12-31'; % 39_Maturity_date Position / BondCharacteristics / Redemption / MaturityDate
        TPT_40 = ''; % 40_Redemption_type Position / BondCharacteristics / Redemption /Type
        TPT_41 = 0; % 41_Redemption_rate Position / BondCharacteristics / Redemption / Rate
        TPT_42 = ''; % 42_Callable_putable Position / BondCharacteristics / OptionalCallPut / CallPutType
        TPT_43 = '2018-12-31'; % 43_Call_put_date Position / BondCharacteristics / OptionalCallPut / CallPutDate
        TPT_44 = 'B'; % 44_Issuer_bearer_option_exercise Position / BondCharacteristics / OptionalCallPut / OptionDirection
        TPT_45 = 0; % 45_Strike_price_for_embedded_(call_put)_options Position / BondCharacteristics / OptionalCallPut / StrikePrice
        TPT_46 = 'XXX'; % 46_Issuer_name Position / CreditRiskData / InstrumentIssuer / Name
        TPT_47 = 'XXX'; % 47_Issuer_identification_code Position / CreditRiskData / InstrumentIssuer / Code / Code
        TPT_48 = 9; % 48_Type_of_identification_code_for_issuer Position / CreditRiskData / InstrumentIssuer / Code / CodificationSystem
        TPT_49 = 'XXX'; % 49_Name_of_the_group_of_the_issuer Position / CreditRiskData / IssuerGroup / Name
        TPT_50 = 'XXX'; % 50_Identification_of_the_group Position / CreditRiskData / IssuerGroup / Code / Code
        TPT_51 = 9; % 51_Type_of_identification_code_for_issuer_group Position / CreditRiskData / IssuerGroup / Code / CodificationSystem
        TPT_52 = 'DE'; % 52_Issuer_country Position / CreditRiskData / IssuerCountry
        TPT_53 = 1; % 53_Issuer_economic_area Position / CreditRiskData / EconomicArea
        TPT_54 = 'A'; % 54_Economic_sector Position / CreditRiskData / EconomicSector
        TPT_55 = 'NC'; % 55_Covered_not_covered Position / CreditRiskData / Covered
        TPT_56 = 'N'; % 56_Securitisation Position / Securitisation / Securitised
        TPT_57 = 'N'; % 57_Explicit_guarantee_by_the_country_of_issue Position / CreditRiskData / StateGuarantee
        TPT_58 = 'N'; % 58_Subordinated_debt Position / SubordinatedDebt
        TPT_58b = 'XXX'; % 58b_Nature_of_the_tranche Position / Securitisation / TrancheLevel
        TPT_59 = 9; % 59_Credit_quality_step Position / CreditRiskData / CreditQualitStep
        TPT_60 = ''; % 60_Call_Put_Cap_Floor Position / DerivativeOrConvertible / OptionCharacteristics / CallPutType
        TPT_61 = 0; % 61_Strike_price Position / DerivativeOrConvertible / OptionCharacteristics / StrikePrice
        TPT_62 = 0; % 62_Conversion_factor_(convertibles)_concordance_factor_parity_(options) Position / DerivativeOrConvertible / OptionCharacteristics / ConversionRatio
        TPT_63 = '2018-12-31'; % 63_Effective_date_of_instrument Position / DerivativeOrConvertible / OptionCharacteristics / Effective Date
        TPT_64 = 'EUR'; % 64_Exercise_type Position / DerivativeOrConvertible / OptionCharacteristics / OptionStyle
        TPT_65 = 'N'; % 65_Hedging_rolling Position / HedgingStrategy
        TPT_67 = 'DE11'; % 67_CIC_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / InstrumentCIC
        TPT_68 = '1'; % 68_Identification_code_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / InstrumentCode / Code
        TPT_69 = 1; % 69_Type_of_identification_code_for_the_underlying_asset Position / UnderlyingInstrument / InstrumentCode / CodificationSystem
        TPT_70 = 'XXX'; % 70_Name_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / InstrumentName
        TPT_71 = 'EUR'; % 71_Quotation_currency_of_the_underlying_asset_(C) Position / DerivativeOrConvertible /  UnderlyingInstrument / Valuation / Currency
        TPT_72 = 0; % 72_Last_valuation_price_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / Valuation / MarketPrice
        TPT_73 = 'DE'; % 73_Country_of_quotation_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / Valuation / Country
        TPT_74 = 1; % 74_Economic_area_of_quotation_of_the_underlying_asset Position / DerivativeOrConvertible /  UnderlyingInstrument / Valuation / EconomicArea
        TPT_75 = 0; % 75_Coupon_rate_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / BondCharacteristics / CouponRate
        TPT_76 = 1; % 76_Coupon_payment_frequency_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / BondCharacteristics / CouponFrequency
        TPT_77 = '2018-12-31'; % 77_Maturity_date_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / BondCharacteristics / Redemption / MaturityDate
        TPT_78 = ''; % 78_Redemption_profile_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / BondCharacteristics / Redemption / Type
        TPT_79 = 0; % 79_Redemption_rate_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / BondCharacteristics / Redemption / Rate
        TPT_80 = 'XXX'; % 80_Issuer_name_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / InstrumentIssuer / Name
        TPT_81 = 'XXX'; % 81_Issuer_identification_code_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / InstrumentIssuer / Code / Code
        TPT_82 = 9; % 82_Type_of_issuer_identification_code_of_the_underlying_asset Position / UnderlyingInstrument / Issuer / InstrumentIssuer / Identification / Code
        TPT_83 = 'XXX'; % 83_Name_of_the_group_of_the_issuer_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / IssuerGroup / Name
        TPT_84 = 'XXX'; % 84_Identification_of_the_group_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / IssuerGroup / Code / Code
        TPT_85 = 9; % 85_Type_of_the_group_identification_code_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / IssuerGroup / Code / CodificationSystem
        TPT_86 = 'DE'; % 86_Issuer_country_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / Country
        TPT_87 = 1; % 87_Issuer_economic_area_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData / EconomicArea
        TPT_88 = 'N'; % 88_Explicit_guarantee_by_the_country_of_issue_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData  / StateGuarantee
        TPT_89 = 0; % 89_Credit_quality_step_of_the_underlying_asset Position / DerivativeOrConvertible / UnderlyingInstrument / CreditRiskData  / CreditQualityStep
        TPT_90 = 0; % 90_Modified_duration_to_maturity_date Position / Analytics / ModifiedDurationToMaturity
        TPT_91 = 0; % 91_Modified_duration_to_next_option_exercise_date Position / Analytics / ModifiedDurationToCall
        TPT_92 = 0; % 92_Credit_sensitivity Position / Analytics / CreditSensitivity
        TPT_93 = 0; % 93_Sensitivity_to_underlying_asset_price_(delta) Position / Analytics / Delta
        TPT_94 = 0; % 94_Convexity_gamma_for_derivatives Position / Analytics / Convexity
        TPT_94b = 0; % 94b_Vega Position / Analytics / Vega
        TPT_95 = 'ISIN'; % 95_Identification_of_the_original_portfolio_for_positions_embedded_in_a_fund Position / LookThroughISIN
        TPT_97 = 0; % 97_SCR_mrkt_IR_up_weight_over_NAV Position / ContributionToSCR / MktIntUp
        TPT_98 = 0; % 98_SCR_mrkt_IR_down_weight_over_NAV Position / ContributionToSCR / MktintDown
        TPT_99 = 0; % 99_SCR_mrkt_eq_type1_weight_over_NAV Position / ContributionToSCR / MktEqGlobal
        TPT_100 = 0; % 100_SCR_mrkt_eq_type2_weight_over_NAV Position / ContributionToSCR / MktEqOther
        TPT_101 = 0; % 101_SCR_mrkt_prop_weight_over_NAV Position / ContributionToSCR / MktProp
        TPT_102 = 0; % 102_SCR_mrkt_spread_bonds_weight_over_NAV Position / ContributionToSCR / MktSpread / Bonds
        TPT_103 = 0; % 103_SCR_mrkt_spread_structured_weight_over_NAV Position / ContributionToSCR / MktSpread / Structured
        TPT_104 = 0; % 104_SCR_mrkt_spread_derivatives_up_weight_over_NAV Position / ContributionToSCR / MktSpread / DerivativesUp
        TPT_105 = 0; % 105_SCR_mrkt_spread_derivatives_down_weight_over_NAV Position / ContributionToSCR / MktSpread / DerivativesDown
        TPT_105a = 0; % 105a_SCR_mrkt_FX_up_weight_over_NAV Position / ContributionToSCR / MktFXUp
        TPT_105b = 0; % 105b_SCR_mrkt_FX_down_weight_over_NAV Position / ContributionToSCR / MktFXDown
        TPT_106 = 9; % 106_Asset_pledged_as_collateral Position / QRTPositionInformation / CollateralisedAsset
        TPT_107 = 'XXX'; % 107_Place_of_deposit Position / QRTPositionInformation / PlaceOfDeposit
        TPT_108 = 2; % 108_Participation Position / QRTPositionInformation / Participation
        TPT_110 = 1; % 110_Valorisation_method Position / QRTPositionInformation / ValorisationMethod
        TPT_111 = 0; % 111_Value_of_acquisition Position / QRTPositionInformation / AverageBuyPrice
        TPT_112 = 'XXX'; % 112_Credit_rating Position / QRTPositionInformation / CounterpartyRating / RatingValue
        TPT_113 = 'XXX'; % 113_Rating_agency Position / QRTPositionInformation / CounterpartyRating / RatingAgency
        TPT_114 = 1; % 114_Issuer_economic_area Position / QRTPositionInformation / IssuerEconomicArea
        TPT_127 = 0; % 127_Bond_floor_(convertible_instrument_only) Position / DerivativeOrConvertible / OptionCharacteristics / Convertible / BondFloor
        TPT_128 = 0; % 128_Option_premium_(convertible_instrument_only) Position / DerivativeOrConvertible / OptionCharacteristics / Convertible / OptionPremium
        TPT_129 = 0; % 129_Valuation_yield Position / BondCharacteristics / ValuationYieldCurve /  Yield
        TPT_130 = 0; % 130_Valuation_z_spread Position / BondCharacteristics / ValuationYieldCurve /  Spread
        TPT_131 = '1'; % 131_Underlying_asset_category Position / Instrument/ UAC
        TPT_132 = 0; % 132_Infrastructure_investment To be defined with Fundxml
        TPT_133 = ''; % 133_custodian_name To be defined with Fundxml
        TPT_1000 = 'V4.0'; % 1000_TPT_Version  
    end
    
    properties (SetAccess = protected )
      value_stress = [];
      value_mc = [];
      timestep_mc = {};
      exposure_base = [];
      exposure_mc = [];
      exposure_stress = [];
    end
 
   % Class methods
   methods
      function a = Position(tmp_name)
       % Position Constructor method
        if nargin < 1
            name        = 'Position';
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
         fprintf('value_base: %8.6f \n',a.value_base);
         fprintf('value_stress: %8.6f \n',a.value_stress(1:value_stress_rows));
         fprintf('\n');
         % looping via first 5 MC scenario values
         for ( ii = 1 : 1 : value_mc_cols)
            fprintf('MC timestep: %s\n',a.timestep_mc{ii});
            fprintf('Scenariovalues:\n[ ')
                for ( jj = 1 : 1 : value_mc_rows)
                    fprintf('%8.6f,\n',a.value_mc(jj,ii));
                end
            fprintf(' ]\n');
         end
         %props = fieldnames(a);
         if (strcmpi(a.type,'Position'))
            fprintf('TPT Position data:\n');
            fprintf('1_Portfolio_identifying_data: %s\n',any2str(a.TPT_1));
            fprintf('14_Identification_code_of_the_instrument: %s\n',any2str(a.TPT_14));
            fprintf('17_Instrument_name: %s\n',any2str(a.TPT_17));
            fprintf('17b_Asset_liability: %s\n',any2str(a.TPT_17b));
            fprintf('18_Quantity: %s\n',any2str(a.TPT_18));
            fprintf('21_Quotation_currency_(A): %s\n',any2str(a.TPT_21));
            fprintf('22_Market_valuation_in_quotation_currency_(A): %s\n',any2str(a.TPT_22));        
            fprintf('90_Modified_duration_to_maturity_date: %s\n',any2str(a.TPT_90));        
         elseif (strcmpi(a.type,'Portfolio'))
            fprintf('TPT Portfolio data:\n');
            fprintf('1_Portfolio_identifying_data: %s\n',any2str(a.TPT_1));
            fprintf('4_Portfolio_currency_(B): %s\n',any2str(a.TPT_4));
            fprintf('5_Net_asset_valuation_of_the_portfolio_or_the_share_class_in_portfolio_currency: %s\n',any2str(a.TPT_5));
            fprintf('6_Valuation_date: %s\n',any2str(a.TPT_6));
            fprintf('7_Reporting_date: %s\n',any2str(a.TPT_7)); 
            fprintf('Positions (Instrument ID and Quantity):\n');
            if ( length(a.positions) > 0)
                for (ii = 2:1:length(a.positions))
                    tmp_pos_obj = a.positions(ii).object;
                    fprintf('\t%s\t%s\n',tmp_pos_obj.id,any2str(tmp_pos_obj.quantity));
                end
            end
         end
         %for (ii=1:1:length(props))
         %   fprintf('%s: %s\n',props{ii},any2str(a.(props{ii})));
         %end
         
      end % disp
           
      function obj = set.type(obj,type)
         if ~(strcmpi(type,'Position') || strcmpi(type,'Portfolio')  )
            error('Type must be Position or Portfolio')
         end
         obj.type = type;
      end % Set.type

      % port_id sets TPT_1 
      function obj = set.port_id(obj,port_id)
         obj.port_id = port_id;
         obj.TPT_1 = port_id;
      end % Set.port_id 

      % quantity sets TPT_18 
      function obj = set.quantity(obj,quantity)
         obj.quantity = quantity;
         obj.TPT_18 = quantity;
      end % Set.quantity 
 
      % currency Position sets TPT_18, Portfolio sets TPT_4
      function obj = set.currency(obj,currency)
         obj.currency = currency;
         if (strcmpi(obj.type,'Position'))
            obj.TPT_21 = currency;
         elseif (strcmpi(obj.type,'Portfolio'))
             obj.TPT_4 = currency;
         end
      end % Set.currency       

      % id Position sets TPT_14, Portfolio sets TPT_1
      function obj = set.id(obj,id)
         obj.id = id;
         if (strcmpi(obj.type,'Position'))
            obj.TPT_14 = id;
         elseif (strcmpi(obj.type,'Portfolio'))
             obj.TPT_1 = id;
         end
      end % Set.id  
      
      % function obj = set.valuation_date(obj,valuation_date) % convert to datenum
         % if ischar(valuation_date)
            % valuation_date = datenum(valuation_date);
         % elseif ( isvector(valuation_date) )
            % if ( length(valuation_date) > 1)
                % valuation_date = datenum(valuation_date);
            % end
         % end
         % obj.valuation_date = valuation_date;
      % end % Set.valuation_date
      
      
   end
   
end % classdef

            % European Swaption Valuation according to Back-76 Model 
            elseif ( strcmp(tmp_type,'SWAPT_EUR_REC') == 1 || strcmp(tmp_type,'SWAPT_EUR_PAY') == 1 )
                % Get Call or Putflag
                %fprintf('===============\n');
                %tmp_id
                %tmp_value
                if ( strcmp(tmp_type,'SWAPT_EUR_PAY') == 1 )
                    call_flag = 1;
                    moneyness_exponent = 1;
                else
                    call_flag = 0;
                    moneyness_exponent = -1;
                end
                % Valuation: Black-76 Modell:
                    tmp_strike          = tmp_instr_struct.sensitivities(3);
                    tmp_spot            = tmp_instr_struct.sensitivities(2);
                    tmp_riskfactor_rf   = tmp_instr_struct.riskfactors{4};
                    tmp_rf_spread   	= tmp_instr_struct.sensitivities(4);
                    tmp_swap_tenor      = tmp_instr_struct.sensitivities(5);
                    tmp_swap_no_pmt     = tmp_instr_struct.sensitivities(6);
                    tmp_maturity        = datevec(tmp_instr_struct.special_str{1},1);
                    tmp_multiplikator   = tmp_instr_struct.special_num(1);
                    tmp_rf_vola         = tmp_instr_struct.riskfactors{1};
                    tmp_rf_vola_struct  = get_sub_struct(riskfactor_struct, tmp_rf_vola);
                                    
                  % Get underlying yield rates:
                    tmp_underlying              = tmp_instr_struct.riskfactors{2};
                    tmp_curve_struct            = get_sub_struct(curve_struct, tmp_riskfactor_rf);	
                    tmp_nodes                   = [tmp_curve_struct.nodes];
                    tmp_rates_original          = [tmp_curve_struct.original];
                    tmp_rates_mc_1d             = [tmp_curve_struct.mc_1d];
                    tmp_rates_mc_250d           = [tmp_curve_struct.mc_250d];
                    tmp_rates_mc_stress         = [tmp_curve_struct.stress];
                    tmp_days_to_maturity        = (datenum(tmp_maturity) - today - 1);
                    tmp_maturity_d              = tmp_days_to_maturity;
                    tmp_forward_base            = get_forward_rate(tmp_nodes,tmp_rates_original,tmp_maturity_d,tmp_swap_tenor);
                    tmp_forward_1d              = get_forward_rate(tmp_nodes,tmp_rates_mc_1d,tmp_maturity_d,tmp_swap_tenor);
                    tmp_forward_250d            = get_forward_rate(tmp_nodes,tmp_rates_mc_250d,tmp_maturity_d,tmp_swap_tenor);
                    tmp_forward_stress          = get_forward_rate(tmp_nodes,tmp_rates_mc_stress,tmp_maturity_d,tmp_swap_tenor);
                    tmp_moneyness_base          = (tmp_forward_base ./tmp_strike).^moneyness_exponent;
                    tmp_moneyness_1d            = (tmp_forward_1d ./tmp_strike).^moneyness_exponent; 
                    tmp_moneyness_250d          = (tmp_forward_250d ./tmp_strike).^moneyness_exponent ;
                    tmp_moneyness_stress        = (tmp_forward_stress ./tmp_strike).^moneyness_exponent; 
                   % Get riskfree rate:                    
                    tmp_rf_curve_struct         = get_sub_struct(curve_struct, tmp_riskfactor);	
                    tmp_rf_nodes                = [tmp_curve_struct.nodes];
                    tmp_rf_rates                = [tmp_curve_struct.original];
                    tmp_rf_rate                 = interpolate_curve(tmp_rf_nodes,tmp_rf_rates,tmp_days_to_maturity ) .+ tmp_rf_spread;           
                  % get implied volatility spread (choose offset to vola, that tmp_value == option_bs with input of appropriate vol):
                    tmp_indexvol_base           = get_implvola(tmp_underlying,'index',tmp_maturity_d,tmp_moneyness_base);
                    tmp_impl_vola_atm_1d        = max([tmp_rf_vola_struct.mc_scenarios.delta_1d],-tmp_indexvol_base);
                    tmp_impl_vola_atm_250d      = max([tmp_rf_vola_struct.mc_scenarios.delta_250d],-tmp_indexvol_base);
                    tmp_swaptionvalue_base      = swaption_black76(call_flag,tmp_forward_base,tmp_strike,tmp_maturity_d,tmp_rf_rate,tmp_indexvol_base,tmp_swap_no_pmt,tmp_swap_tenor) .* tmp_multiplikator;
                    tmp_impl_vola_spread        = calibrate_swaption_black76(call_flag,tmp_forward_base,tmp_strike,tmp_maturity_d,tmp_rf_rate,tmp_indexvol_base,tmp_swap_no_pmt,tmp_swap_tenor,tmp_multiplikator,tmp_value);
                    if ( tmp_impl_vola_spread < -98 )
                        disp(' Calibration failed with Retcode 99. Setting market value to THEO/Value');
                        instrument_struct( ii ).value = tmp_swaptionvalue_base; 
                        tmp_impl_vola_spread = 0; 
                    else
                        %disp('Calibration seems to be successful.. checking');
                        tmp_new_val = swaption_black76(call_flag,tmp_forward_base,tmp_strike,tmp_maturity_d,tmp_rf_rate,tmp_indexvol_base .+ tmp_impl_vola_spread,tmp_swap_no_pmt,tmp_swap_tenor) .* tmp_multiplikator;
                        if ( abs(tmp_value - tmp_new_val) < 0.05 )
                            disp('Calibration successful.');
                            %tmp_impl_vola_spread
                            %tmp_new_val
                        else
                            disp(' Calibration failed although it converged. Setting market value to THEO/Value');
                            %tmp_id 
                            %tmp_swaptionvalue_base 
                            instrument_struct( ii ).value = tmp_swaptionvalue_base;                           
                            tmp_impl_vola_spread = 0; 
                        endif
                    endif
                  % Get Volatility according to volatility smile given by vola surface
                    tmp_indexvol_imp_vola_250d  = get_implvola(tmp_underlying,'index',tmp_maturity_d,tmp_moneyness_250d) .+ tmp_impl_vola_atm_250d .+ tmp_impl_vola_spread;
                    tmp_indexvol_imp_vola_1d    = get_implvola(tmp_underlying,'index',tmp_maturity_d,tmp_moneyness_1d) .+ tmp_impl_vola_atm_1d .+ tmp_impl_vola_spread;
                    tmp_stress_imp_vola         = (tmp_impl_vola_spread .+ get_implvola(tmp_underlying,'index',tmp_maturity_d,tmp_moneyness_stress)) .* (tmp_rf_vola_struct.stresstests .+ 1);                 
                  % Get BlackScholes Option Price
                    new_value_1D	        = max(swaption_black76(call_flag,tmp_forward_1d,tmp_strike,tmp_maturity_d,tmp_rf_rate,tmp_indexvol_imp_vola_1d,tmp_swap_no_pmt,tmp_swap_tenor) .* tmp_multiplikator,0.001); 
                    new_value_250D          = max(swaption_black76(call_flag,tmp_forward_250d,tmp_strike,tmp_maturity_d,tmp_rf_rate,tmp_indexvol_imp_vola_250d,tmp_swap_no_pmt,tmp_swap_tenor) .* tmp_multiplikator ,0.001);
                    new_value_stress	    = max(swaption_black76(call_flag,tmp_forward_stress,tmp_strike,tmp_maturity_d,tmp_rf_rate,tmp_stress_imp_vola,tmp_swap_no_pmt,tmp_swap_tenor) .* tmp_multiplikator,0.001); 
    
/*
Copyright (C) 2020 Schinzilord <schinzilord@octarisk.com>

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.
*/


#include <octave/oct.h>
#include <cmath>
#include <float.h>
#include <octave/parse.h>
#include <octave/oct-rand.h>

static bool any_bad_argument(const octave_value_list& args);

double norminv_custom(double x);
double erfinv(double x);

						
DEFUN_DLD (pricing_humancapital_cpp, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{HC}} = pricing_humancapital_cpp(@var{income_fix}, @var{income_bonus}, @var{timefactors}, @var{rf_nodes_yearly}, @var{rf_term_yearly}, @var{mu_risky}, @var{s_risky}, @var{corr}, @var{mu_labor}, @var{s_labor}, @var{mu_act}, @var{bonus_cap}, @var{bonus_floor}, @var{nmc}, @var{surv_probs_yearly}, @var{infl_term_yearly}) \n\
\n\
Compute human capital (HC). HC is the discounted future stream of income.\n\
Basic idea is to divide salary in a fixed income part and an equity like bonus part. Both parts\n\
can evolve over time and the growth is correlated with each other.\n\
Inflation expectations are taken into account in future salary growth.\n\
Human Capital is then the discounted net present value of the future income streanm.\n\
As discount rate a specific term structure (e.g. risk free curve for absolutely safe income\n\
or risk free plus a corporate spread for more risky salary stream) is used.\n\
Bonus payments are highly volatile depending on equity markets of the previous\n\
year and can be capped and floored according to company specificities.\n\
\n\
This function should be called from Retail class\n\
which handles all input and ouput of data.\n\
\n\
Input variables:\n\
@itemize @bullet\n\
@item @var{income_fix}: double: fixed part of the current income\n\
@item @var{income_bonus}: double: bonus part of the current income\n\
@item @var{timefactors}: NDArray: time factors for yearly payments\n\
@item @var{rf_nodes_vec}: NDArray: nodes vector with yearly terms used for ir, infl and survival probabilities\n\
@item @var{rf_term}: Matrix: term structure of interest rates (optional: scenario dependent)\n\
@item @var{mu_risky}: double: long term drift of equity markets\n\
@item @var{s_risky}: double: volatility p.a. of equity market\n\
@item @var{corr}: double: correlation between salary evolution and equity market\n\
@item @var{mu_labor}: double: fixed drift above inflation rate of salary component\n\
@item @var{s_labor}: double: volatility p.a. of salary component\n\
@item @var{mu_act}: NDArray: shock rate to equity markets in year 0 (used for bonus payout in year 1)\n\
@item @var{bonus_cap}: double: maximum payout of bonus\n\
@item @var{bonus_floor}: double: minimum payout of bonus\n\
@item @var{nmc}: octave_idx_type: number of inner MC scenarios used for HC calculation\n\
@item @var{surv_probs_yearly}: NDArray: cumulative survival probabilities (not scenario dependent)\n\
@item @var{infl_term}: Matrix: term structure of inflation expectation rates (used for evolution of salary component)\n\
@end deftypefn")
{
  octave_value retval;
  int nargin = args.length ();

  if (nargin < 16 || nargin > 16 )
  {
    print_usage ();
	error("Expecting 15 input parameters");
  }

	// Input parameter checks
	if (any_bad_argument(args))
	  return octave_value_list();

	// Input parameter
	double income_fix     	= args(0).double_value(); // 
	double income_bonus   	= args(1).double_value(); // 
	NDArray tf_vec			= args(2).array_value(); // 
	NDArray rf_nodes_vec	= args(3).array_value (); // 
	Matrix rf_term			= args(4).matrix_value (); // 
	double mu_risky			= args(5).double_value(); // 
	double s_risky			= args(6).double_value(); // 
	double corr				= args(7).double_value(); // 
	double mu_labor			= args(8).double_value(); // 
	double s_labor			= args(9).double_value(); // 
	NDArray mu_act			= args(10).array_value (); // 
	double bonus_cap		= args(11).double_value(); // 
	double bonus_floor		= args(12).double_value(); // 
	int nmc					= args(13).int_value(); // 
	NDArray surv_probs_yearly	= args(14).array_value(); // 
	Matrix infl_term		= args(15).array_value(); // 
						
	// total number of scenarios: get maximum of length of all vectors
	int len_ir 		= rf_term.rows ();
	int len_infl 	= infl_term.rows ();
	int len_mu 		= mu_act.numel ();
	int len_tf 		= tf_vec.rows ();
	int len 		= std::max(len_ir,len_mu);
	int col_nodes 	= rf_nodes_vec.columns ();
	int col_surv 	= surv_probs_yearly.columns ();
	int col_rates 	= rf_term.columns ();
	int col_infl 	= infl_term.columns ();
	int col_tf 		= tf_vec.columns ();
	
	// input checks
	if (len_ir > 1 && len_ir != len)
		error("pricing_humancapital_cpp: expecting len_ir to be of length 1 or %d",len);
	if (len_mu > 1 && len_mu != len)
		error("pricing_humancapital_cpp: expecting len_mu to be of length 1 or %d",len);
	if (len_infl > 1 && len_infl != len)
		error("pricing_humancapital_cpp: expecting len_infl to be of length 1 or %d",len);
	if (col_nodes != col_rates)
		error("pricing_humancapital_cpp: expecting col_nodes %d to be of length of col_rates %d",col_nodes,col_rates);
	if (col_nodes != col_tf)
		error("pricing_humancapital_cpp: expecting col_nodes %d to be of length of col_tf %d",col_nodes,col_tf);	
	if (col_nodes != col_surv)
		error("pricing_humancapital_cpp: expecting col_nodes %d to be of length of col_survprobs %d",col_nodes,col_surv);	
	if (col_nodes != col_infl)
		error("pricing_humancapital_cpp: expecting col_nodes %d to be of length of col_infl %d",col_nodes,col_infl);	
	if ( s_risky < 0 )
		error("pricing_humancapital_cpp: Volatility s_risky must be positive!");
	if ( s_labor < 0 )
		error("pricing_humancapital_cpp: Volatility s_labor must be positive!");
	if ( corr < -1.0 || corr > 1.0 )
		error("pricing_humancapital_cpp: Correlation corr must be between -1.0 and 1.0");
	if ( nmc % 2 != 0)
        nmc = nmc + 1;
        	
	// initialize scenario dependent output:
	dim_vector dim_scen (len, 1);
	dim_vector dim_mat (len, col_nodes);
	dim_vector dim_rnd (nmc/2, col_nodes);
	ColumnVector HCVec (dim_scen);

	NDArray mu_act_vec (dim_scen);
	Matrix rf_term_mat (dim_mat);
	Matrix infl_term_mat (dim_mat);
	Matrix Z_equity;
	Matrix Z_income;
	double mu_act_scen;
	double mu_act_scen2;
	double mu_act_scen_at;
	double mu_act_scen_at2;
	double drift_risky = (mu_risky - 0.5 * s_risky * s_risky);
	double drift_labor = 0.0;
	double income = 0.0;
	double Z_income_correlation = 0.0;
	double Z_income_correlation2 = 0.0;
	double yield_labor = 0.0;
	double yield_labor2 = 0.0;
	double yield_labor_at = 0.0;
	double yield_labor_at2 = 0.0;
	double income_bonus_tmp = 0.0;
	double income_bonus_tmp2 = 0.0;
	double bonus_payout = 0.0;
	double bonus_payout2 = 0.0;
	double bonus = 0.0;
	double bonus2 = 0.0;
	double rates = 0.0;
	double fix = 0.0;
	double fix2 = 0.0;
	double income_bonus_tmp_at = 0.0;
	double income_bonus_tmp_at2 = 0.0;
	double bonus_payout_at = 0.0;
	double bonus_payout_at2 = 0.0;
	double bonus_at = 0.0;
	double bonus_at2 = 0.0;
	double fix_at = 0.0;
	double fix_at2 = 0.0;
	double df = 0.0;
	double surv_prob = 0.0;
	double inflrate = 0.0;
	
	// initialize scenario dependent input values (idx either 0 or ii)
	if ( len_ir == 1 )
	{
		for (octave_idx_type jj = 0; jj < len; ++jj) 
		{
			for (octave_idx_type gg = 0; gg < col_nodes; ++gg) 
			{
				rf_term_mat(jj,gg) = rf_term(0,gg);
			}
		}	
	}	
	else 
		rf_term_mat = rf_term;
	//
	if ( len_infl == 1 )
	{
		for (octave_idx_type jj = 0; jj < len; ++jj) 
		{
			for (octave_idx_type gg = 0; gg < col_nodes; ++gg) 
			{
				infl_term_mat(jj,gg) = infl_term(0,gg);
			}
		}	
	}	
	else 
		infl_term_mat = infl_term;	
	//		
	if ( len_mu == 1 )
		mu_act_vec.fill(mu_act(0));
	else 
		mu_act_vec = mu_act;
	
	
	// generate random numbers --> make norminv. Same random set for all outer scenarios
	Z_equity = octave_rand::nd_array(dim_rnd);
	Z_income = octave_rand::nd_array(dim_rnd);
	for (octave_idx_type mm = 0; mm < nmc/2; ++mm) 
	{	
		for (octave_idx_type ii = 1; ii <= col_nodes; ++ii) 
		{
			Z_equity(mm,ii-1) = norminv_custom(Z_equity(mm,ii-1));
			Z_income(mm,ii-1) = norminv_custom(Z_income(mm,ii-1));	
		}
	}
	// Calculate Human Capital values
	// loop via all outer MC scenarios
	for (octave_idx_type oo = 0; oo < len; ++oo) 
	{
		// catch ctrl + c
		OCTAVE_QUIT;
		
		income = 0.0;
		// inner loop nested MC	(price 4 scenarios per nested MC loop:
		// each two normal and antithetic paths for scenario mm and mm+1
		// performance increase by >10% compared to only one scenario
		for (octave_idx_type mm = 0; mm < nmc/2; mm=mm+2) 
		{
			fix = income_fix;
			bonus = income_bonus;
			income_bonus_tmp = income_bonus;
			
			fix_at = income_fix;
			bonus_at = income_bonus;
			income_bonus_tmp_at = income_bonus;
			
			fix2 = income_fix;
			bonus2 = income_bonus;
			income_bonus_tmp2 = income_bonus;
			
			fix_at2 = income_fix;
			bonus_at2 = income_bonus;
			income_bonus_tmp_at2 = income_bonus;
			
			// precalculate inner scenario independent terms
			mu_act_scen = exp(mu_act_vec(oo));
			mu_act_scen2 = mu_act_scen;
			mu_act_scen_at = mu_act_scen;
			mu_act_scen_at2 = mu_act_scen;
		
			// inner loops accross timesteps
			for (octave_idx_type ii = 1; ii <= col_nodes; ++ii) 
			{
				Z_income_correlation = corr * Z_equity(mm,ii-1) + (1-corr) * Z_income(mm,ii-1);	
				Z_income_correlation2 = corr * Z_equity(mm+1,ii-1) + (1-corr) * Z_income(mm+1,ii-1);	
				inflrate = infl_term_mat(oo,ii-1);
				drift_labor = (mu_labor + inflrate - 0.5 * s_labor * s_labor);
				
				// normal path
				yield_labor = exp( drift_labor + s_labor * Z_income_correlation);
				fix = fix * yield_labor;
				income_bonus_tmp = income_bonus_tmp * yield_labor;
				bonus_payout = 1.0 + std::max(std::min(log(mu_act_scen),bonus_cap),bonus_floor); 
				bonus = income_bonus_tmp * bonus_payout;
				mu_act_scen = exp( drift_risky + s_risky * Z_equity(mm,ii-1));
				
				// antithetic path
				yield_labor_at = exp( drift_labor + s_labor * -Z_income_correlation);
				fix_at = fix_at * yield_labor_at;
				income_bonus_tmp_at = income_bonus_tmp_at * yield_labor_at;
				bonus_payout_at = 1.0 + std::max(std::min(log(mu_act_scen_at),bonus_cap),bonus_floor);
				bonus_at = income_bonus_tmp_at * bonus_payout_at;
				mu_act_scen_at = exp( drift_risky + s_risky * -Z_equity(mm,ii-1));
				
				// normal path 2
				yield_labor2 = exp( drift_labor + s_labor * Z_income_correlation2);
				fix2 = fix2 * yield_labor2;
				income_bonus_tmp2 = income_bonus_tmp2 * yield_labor2;
				bonus_payout2 = 1.0 + std::max(std::min(log(mu_act_scen2),bonus_cap),bonus_floor); 
				bonus2 = income_bonus_tmp2 * bonus_payout2;
				mu_act_scen2 = exp( drift_risky + s_risky * Z_equity(mm+1,ii-1));
				
				// antithetic path 2
				yield_labor_at2 = exp( drift_labor + s_labor * -Z_income_correlation2);
				fix_at2 = fix_at2 * yield_labor_at2;
				income_bonus_tmp_at2 = income_bonus_tmp_at2 * yield_labor_at2;
				bonus_payout_at2 = 1.0 + std::max(std::min(log(mu_act_scen_at2),bonus_cap),bonus_floor);
				bonus_at2 = income_bonus_tmp_at2 * bonus_payout_at2;
				mu_act_scen_at2 = exp( drift_risky + s_risky * -Z_equity(mm+1,ii-1));
				
				// discount and add income under both paths
				rates = rf_term_mat(oo,ii-1);
				surv_prob = surv_probs_yearly(ii-1);
				df = exp(-rf_nodes_vec(ii-1)/365.0 * rates);
				income = income + (bonus + fix + bonus_at + fix_at + bonus2 + fix2 + bonus_at2 + fix_at2 ) * df * surv_prob * tf_vec(ii-1);
				
			}  // end ts loop

		} // end nested MC loop
		
		// take average of income over all nmc scenarios
		HCVec(oo) = income / nmc;
	}
		
	// return Option price
	octave_value_list option_outargs;
	option_outargs(0) = HCVec;
	
   return octave_value (option_outargs);

} // end of DEFUN_DLD

//#########################    STATIC FUNCTIONS    #############################

// custom inverse of std normal cdf
double norminv_custom(double x)
{
	if ( x == 0.0 ) {
        return DBL_MIN;
    }
	if ( x == 1.0) {
        return DBL_MAX;
    }
	if ( x > 1 || x < 0) {
        return NAN;
    }
	return - sqrt(2.0) * erfinv(1.0 - 2.0*x);
}


//  erfinv function
/*
    libit - Library for basic source and channel coding functions
    Copyright (C) 2005-2005 Vivien Chappelier, Herve Jegou
	http://libit.sourceforge.net/
*/
double erfinv(double x)
    {
		double aa0 = 0.886226899;
		double aa1 = -1.645349621;
		double aa2 = 0.914624893;
		double aa3 = -0.140543331;
		double bb0 = 1.0;
		double bb1 = -2.118377725;
		double bb2 = 1.442710462;
		double bb3 = -0.329097515;
		double bb4 = 0.012229801;
		double cc0 = -1.970840454;
		double cc1 = -1.62490649;
		double cc2 = 3.429567803;
		double cc3 = 1.641345311;
		double dd0 = 1.0;
		double dd1 = 3.543889200;
		double dd2 = 1.637067800;
		double sqrtPI = sqrt(M_PI);
        double  r, y;
        int  sign_x;
			
        if (x < -1 || x > 1) {
            return NAN;
		}
		
        if (x == 0.0) {
            return 0.0;
        }
        if (x > 0) {
            sign_x = 1;
        } else {
            sign_x = -1;
            x = -x;
        }
        if (x <= 0.7)  {
            double x2 = x * x;
            r = x * (((aa3 * x2 + aa2) * x2 + aa1) * x2 + aa0);
            r /= (((bb4 * x2 + bb3) * x2 + bb2) * x2 + bb1) * x2 + bb0;
        } else {
            y = sqrt (-log ((1.0 - x) / 2.0));
            r = (((cc3 * y + cc2) * y + cc1) * y + cc0);
            r /= ((dd2 * y + dd1) * y + dd0);
        }
        r = r * sign_x;
        x = x * sign_x;
        r -= (erf (r) - x) / (2 / sqrtPI * exp (-r * r));
        r -= (erf (r) - x) / (2 / sqrtPI * exp (-r * r));
        return r;
}
				
// static function for input parameter checks 
bool any_bad_argument(const octave_value_list& args)
{
    if (!args(0).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting income_fix to be an numeric");
        return true;
    }
    
    if (!args(1).isnumeric())
    {
        error("pricing_humancapital_cpp: expecting income_bonus to be a bool");
        return true;
    }
    
    if (!args(2).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting timefactors to be a numeric");
        return true;
    }
    
    if (!args(3).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting rf_nodes_vec to be a numeric");
        return true;
    }
    
    if (!args(4).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting rf_term to be a numeric");
        return true;
    }
    
    if (!args(5).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting mu_risky to be a numeric");
        return true;
    }
    
    if (!args(6).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting s_risky to be a numeric");
        return true;
    }
    
    if (!args(7).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting corr to be a numeric");
        return true;
    }
    
    if (!args(8).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting mu_labor to be a numeric");
        return true;
    }
    
    if (!args(9).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting s_labor to be a numeric");
        return true;
    }
    
    if (!args(10).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting mu_act to be a numeric");
        return true;
    }
    
    if (!args(11).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting bonus_cap to be a numeric");
        return true;
    }
    
    if (!args(12).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting bonus_floor to be a numeric");
        return true;
    }
    
    if (!args(13).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting nmc to be a numeric");
        return true;
    }
    
    if (!args(14).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting surv_probs_yearly to be a numeric");
        return true;
    }
    
    if (!args(15).isnumeric ())
    {
        error("pricing_humancapital_cpp: expecting infl_term to be a numeric");
        return true;
    }
        
    return false;
}

/*
%!assert(pricing_humancapital_cpp(80000,20000,[1,1,1], [365,730,1095],[0.005,0.01,0.02],0.02,0.2,0.9,0.005,0.02,-0.2,0.1,-0.5,5000,[0.999,0.99,0.98],[0.01,0.015,0.02]),[293893],5000)
*/



//~ octave_stdout << "\nyear " << ii << "\n";
//~ octave_stdout << "fix " << fix << "\n";
//~ octave_stdout << "yield_labor " << yield_labor << "\n";
//~ octave_stdout << "income_bonus_tmp " << income_bonus_tmp << "\n";
//~ octave_stdout << "bonus_payout " << bonus_payout << "\n";
//~ octave_stdout << "bonus " << bonus << "\n";
//~ octave_stdout << "mu_act_scen " << mu_act_scen << "\n";
//~ octave_stdout << "rates " << rates << "\n";
//~ octave_stdout << "nodes " << rf_nodes_vec(ii-1)/365.0 << "\n";
//~ octave_stdout << "df " << df << "\n";
//~ octave_stdout << "income " << income << "\n\n";
// mkoctfile -v -std=gnu++11 -O3 '/home/schinzilord/Dokumente/Programmierung/octarisk/oct_files/pricing_humancapital_cpp.cc'

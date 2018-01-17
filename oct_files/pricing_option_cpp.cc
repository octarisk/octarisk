/*
Copyright (C) 2016 Schinzilord <schinzilord@octarisk.com>

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
#include <octave/parse.h>
#include <octave/oct-rand.h>


static bool any_bad_argument(const octave_value_list& args);

static ColumnVector get_ASIAN_option_price_MC(const bool& call_flag, const NDArray& S, 
            const NDArray& X, const NDArray& T, const NDArray& r, 
            const NDArray& sigma, const NDArray& q, const octave_idx_type& len, 
			octave_idx_type& n);
			
static ColumnVector get_EU_option_price_BS(const bool& call_flag, const NDArray& S_vec, 
            const NDArray& X_vec, const NDArray& T_vec, const NDArray& r_vec, 
            const NDArray& sigma_vec, const NDArray& divrate_vec, const octave_idx_type& len);

static ColumnVector get_AM_option_price_CRR(const bool& call_flag, const NDArray& S, 
            const NDArray& X, const NDArray& T, const NDArray& r, 
            const NDArray& sigma, const NDArray& q, const octave_idx_type& len, 
			const octave_idx_type& n);
			
DEFUN_DLD (pricing_option_cpp, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{OptionVec}} = pricing_option_cpp(@var{option_type}, @var{call_flag}, @var{S_vec}, @var{X_vec}, @var{T_vec}, @var{r_vec}, @var{sigma_vec}, @var{divrate_vec}, @var{n}) \n\
\n\
Compute the put or call value of different equity options.\n\
\n\
This function should be called from Option class\n\
which handles all input and ouput data.\n\
\n\
Input and output variables:\n\
@itemize @bullet\n\
@item @var{option_type}: Integer: Sets pricing engine (1=EU(BS),2=AM(CRR),3=ASIAN ARITHMETIC(MC))\n\
@item @var{call_flag}: Boolean: (true: call option, false: put option\n\
@item @var{S_vec}: Double: Spot prices (either scalar or vector of length m)\n\
@item @var{X_vec}: Double: Strike prices (either scalar or vector of length m)\n\
@item @var{T_vec}: Double: Time to maturity (days, act/365) (either scalar or vector of length m)\n\
@item @var{r_vec}: Double: riskfree rate (either scalar or vector of length m)\n\
@item @var{sigma_vec}: Double: volatility (annualized,act/365) (either scalar or vector of length m)\n\
@item @var{divrate_vec}: Double: dividend yield (cont,act/365) (either scalar or vector of length m)\n\
@item @var{n}: Integer: number of tree steps (AM) or number of MC scenarios (ASIAN)\n\
@item @var{OptionVec}: Double: OUTPUT: Option prices (columnn vector)\n\
@end itemize\n\
Example Call:\n\
@example\n\
@group\n\
retvec = pricing_option_cpp(1,false,[10000;9000;11000],11000,365,0.01,[0.2;0.025;0.03],0.0)\n\
retvec =\n\
   1351.5596280726359\n\
   1890.5481712408509\n\
     83.4751762658461\n\
@end group\n\
@end example\n\
@end deftypefn")
{
  octave_value retval;
  int nargin = args.length ();

  if (nargin < 8 || nargin > 9 )
  {
    print_usage ();
	error("Expecting either 8 or 9 input parameters");
  }

	// Input parameter checks
	if (any_bad_argument(args))
	  return octave_value_list();

	// Input parameter option_type,call_flag,S,X,T,r,sigma,divrate
	int option_type     = args(0).int_value(); // Option type (1=EU, 2=AM)
	bool call_flag      = args(1).bool_value(); // call or put option
	NDArray S_vec       = args(2).array_value (); // spotpricey
	NDArray X_vec       = args(3).array_value (); // Strike
	NDArray T_vec       = args(4).array_value (); // time to maturity (days)
	NDArray r_vec       = args(5).array_value (); // riskfree rate
	NDArray sigma_vec   = args(6).array_value (); // annualized volatility
	NDArray divrate_vec = args(7).array_value (); // dividend rate
	int n;
	if ( nargin == 8)
	{
		if ( option_type == 2)
			n =  rint(T_vec(0) / 7.0);	// default weekly Tree steps
		else
			n = 1024;	// default value for inner MC scenarios 
	} else {
		n = args(8).int_value ();
	}
	
	// total number of scenarios: get maximum of length of all vectors
	int len_S = S_vec.numel ();
	int len_X = X_vec.numel ();
	int len_T = T_vec.numel ();
	int len_r = r_vec.numel ();
	int len_sigma = sigma_vec.numel ();
	int len_divrate = divrate_vec.numel ();
	int len = std::max(std::max(std::max(std::max(std::max(len_S,len_X), 
									len_T),len_r),len_sigma),len_divrate);

	// input checks
	if (len_S > 1 && len_S != len)
		error("pricing_option_cpp: expecting S to be of length 1 or %d",len);
	if (len_X > 1 && len_X != len)
		error("pricing_option_cpp: expecting X to be of length 1 or %d",len);
	if (len_T > 1 && len_T != len)
		error("pricing_option_cpp: expecting T to be of length 1 or %d",len);
	if (len_r > 1 && len_r != len)
		error("pricing_option_cpp: expecting r to be of length 1 or %d",len);
	if (len_sigma > 1 && len_sigma != len)
		error("pricing_option_cpp: expecting sigma to be of length 1 or %d",len);
	if (len_divrate > 1 && len_divrate != len)
		error("pricing_option_cpp: expecting divrate to be of length 1 or %d",len);
	
	for (octave_idx_type ii = 0; ii < len_sigma; ++ii) 
	{
		if ( sigma_vec(ii) < 0 )
			error("Volatility sigma must be positive!");
	}
	// initialize scenario dependent output:
	dim_vector dim_scen (len, 1);
	ColumnVector OptionVec (dim_scen);

	NDArray S (dim_scen);
	NDArray X (dim_scen);
	NDArray T (dim_scen);
	NDArray r (dim_scen);
	NDArray divrate (dim_scen);
	NDArray sigma (dim_scen);
	// initialize scenario dependent input values (idx either 0 or ii)
	if ( len_S == 1 )
		S.fill(S_vec(0));
	else 
		S = S_vec;
	//		
	if ( len_X == 1 )
		X.fill(X_vec(0));
	else 
		X = X_vec;
	//
	if ( len_T == 1 )
		T.fill(T_vec(0));
	else
		T = T_vec;
	//
	if ( len_r == 1 )
		r.fill(r_vec(0));
	else 
		r = r_vec;
	//		
	if ( len_divrate == 1 )
		divrate.fill(divrate_vec(0));
	else
		divrate = divrate_vec;
	//		
	if ( len_sigma == 1 )
		sigma.fill(sigma_vec(0));
	else
		sigma = sigma_vec;
	
	
	// Calculate Option prices
	switch(option_type) {
		case 1: // European Option
				OptionVec = get_EU_option_price_BS(call_flag, S, 
							 X, T, r, sigma, divrate, len);
				break;
		case 2: // American Option
				OptionVec = get_AM_option_price_CRR(call_flag, S, 
							 X, T, r, sigma, divrate, len, n); 
				break;
		case 3: // Asian Option (arithmetic average)
				OptionVec = get_ASIAN_option_price_MC(call_flag, S, 
							 X, T, r, sigma, divrate, len, n);
				break;
		default: error("pricing_option_cpp: unknown Option type (not in [1,2])");
				break;
	}
		
	// return Option price
	octave_value_list option_outargs;
	option_outargs(0) = OptionVec;
	
   return octave_value (option_outargs);

} // end of DEFUN_DLD

//#########################    STATIC FUNCTIONS    #############################

// #############################################################################
// static function for calculation of American Option Prices with CRR model 
ColumnVector get_ASIAN_option_price_MC(const bool& call_flag, const NDArray& S, 
            const NDArray& X, const NDArray& T, const NDArray& r, 
            const NDArray& sigma, const NDArray& q, const octave_idx_type& len, 
			octave_idx_type& n)
{
	// rework required, placeholder template for Asian style MC valuations
	octave_rand::distribution("normal");// initialize distribution
	dim_vector dim_scen (len, 1);
	ColumnVector OptionVec (dim_scen);
	double  TF_oo, DF, dt, P, S_tt, sqrdt, P_at, S_tt_at;
	double inner_value, no_timesteps;
	// n needs to be even
	n = ((n % 2 == 0) ? n : n + 1);
	double MC_scen = static_cast<double>(n);
	int timesteps;
	double drift;
	double sigmasqrdt;
	Matrix rnd_vec;

	double eta = 1.0;
	if (call_flag == false)   // Option is Put
				eta = -1.0;
				
	// loop via all scenarios
	for (octave_idx_type oo = 0; oo < len; ++oo) 
	{
		// catch ctrl + c
		OCTAVE_QUIT;
		
		inner_value = 0.0;
		timesteps = rint( T(oo) / 7.0 );	// weekly time steps
		no_timesteps = round( T(oo) / 7.0  );
		
		dt = (T(oo) / 365.0) / no_timesteps;
		sqrdt = std::sqrt(dt);

		TF_oo = T(oo) / 365.0;
		DF = exp(-r(oo) * TF_oo);
		// generate random numbers (use antithetic paths)
		dim_vector dim_timesteps(timesteps,n/2);
		rnd_vec = octave_rand::nd_array(dim_timesteps);
		// precalculate inner scenario independent terms
		drift = (r(oo) - q(oo) - 0.5 * sigma(oo) * sigma(oo)) * dt;
		sigmasqrdt = sigma(oo) * sqrdt;

		// loop via all MC scenarios
		for (octave_idx_type ii = 0; ii < n/2; ++ii) 
		{
			P = 0.0;
			P_at = 0.0;
			S_tt = S(oo);	// start value for underlying price
			S_tt_at = S_tt; // start value (antithetic path)
			// calculate price at all time steps and payoff value (assume GBM)
			for (octave_idx_type tt = 0; tt < timesteps; ++tt) 
			{
				// normal path									
				S_tt = S_tt * exp( drift + (rnd_vec(tt,ii) * sigmasqrdt) );
				P = P + S_tt;
				// antithetic path						
				S_tt_at = S_tt_at * exp( drift + (-rnd_vec(tt,ii) * sigmasqrdt) );
				P_at = P_at + S_tt_at;
			}
			// arithmetic average of underlying price
			//if ( asian_average_type == 'arithmetic')
				P = P / no_timesteps; 
				P_at = P_at / no_timesteps;
			// get option payoff
			inner_value = inner_value +  std::max(eta * (P - X(oo)), 0.0) * DF
									  +  std::max(eta * (P_at - X(oo)), 0.0) * DF;
		}
		// get arithmetic average of all MC scenario values
		OptionVec(oo) = inner_value / MC_scen; 
	}
	// Return the option price
	return OptionVec;
}

// #############################################################################
// static function for calculation of American Option Prices with CRR model 
ColumnVector get_AM_option_price_CRR(const bool& call_flag, const NDArray& S, 
            const NDArray& X, const NDArray& T, const NDArray& r, 
            const NDArray& sigma, const NDArray& q, const octave_idx_type& len, 
			const octave_idx_type& n)
{
	
	// Matrices for the stock price evolution and option price
	dim_vector dim_tree (n+1, n+1);
	dim_vector dim_scen (len, 1);
	ColumnVector OptionVec (dim_scen);
	
	NDArray Smat(dim_tree);
	Smat.fill(0.0);
	NDArray Omat(dim_tree);
	Omat.fill(0.0);
	double dt,u,d,p;
	int i,j;
	double DF;
	double timesteps = static_cast<double> ( n );
	double tmp;
	double eta = 1.0;
	if (call_flag == false)   // Option is Put
				eta = -1.0;
				
	// loop via all scenarios
	for (octave_idx_type ii = 0; ii < len; ++ii) 
	{
		// catch ctrl + c
		OCTAVE_QUIT;
		
		// Set up tree parameter
		dt = T(ii) / 365.0 / timesteps;
		u = exp(sigma(ii)*std::sqrt(dt));
		d = 1.0/u;
		p = (exp((r(ii) - q(ii))*dt)-d) / (u-d);
		DF = exp(-r(ii)*dt);
		
		// Build CRR tree
		for (j=0; j<=n; ++j)
			for (i=0; i<=j; ++i)
				 Smat(i,j) = S(ii)*std::pow(u,j-i)*std::pow(d,i);

		// Get final payoffs
		for (i=0; i<=n; ++i) {
			Omat(i,n) = std::max(eta*(Smat(i,n) - X(ii)), 0.0);
		}

		// Backward recursion 
		for (j=n-1; j>=0; --j) 
		{
			for (i=0; i<=j; ++i) 
			{
				tmp = DF*(p*(Omat(i,j+1)) + (1.0-p)*(Omat(i+1,j+1)));
				Omat(i,j) = std::max(eta*(Smat(i,j) - X(ii)), tmp);
			}
		}
		OptionVec(ii) = Omat(0,0); 
	}
	// Return the option price
	return OptionVec;
}

// #############################################################################
// static function for calculation of analytic European option prices 
ColumnVector get_EU_option_price_BS(const bool& call_flag, const NDArray& S, 
            const NDArray& X, const NDArray& T, const NDArray& r, 
            const NDArray& sigma, const NDArray& q, const octave_idx_type& len)
{
	// initialize scenario dependent output:
	dim_vector dim_scen (len, 1);
	ColumnVector OptionVec (dim_scen);
	const double sqr2 = std::sqrt(2);
	double eta = 1.0;
	if (call_flag == false)   // Option is Put
				eta = -1.0;
	
	double 	TF_i, sigma_sqrTF, d1, d2, normcdf_eta_d1, normcdf_eta_d2;
	
	// loop via all scenarios
	for (octave_idx_type ii = 0; ii < len; ii++) 
	{
		// catch ctrl + c
		OCTAVE_QUIT;

		TF_i = T(ii) / 365.0;			// assume act/365 DCC
		sigma_sqrTF = sigma(ii)*std::sqrt(TF_i);
			
		d1 = (std::log(S(ii)/X(ii)) + (r(ii) - q(ii) + 
								0.5*sigma(ii)*sigma(ii))*TF_i) / sigma_sqrTF;
		d2 = d1 - sigma_sqrTF;
		normcdf_eta_d1 = 0.5 *(1+erf(eta * d1/sqr2));
		normcdf_eta_d2 = 0.5 *(1+erf(eta * d2/sqr2));
						 
		// Calculating value: 
		OptionVec(ii) =  eta * (std::exp(-q(ii)*T(ii)) * S(ii) * normcdf_eta_d1 - 
								X(ii) * std::exp(-r(ii) * TF_i) *normcdf_eta_d2); 
	}
	return OptionVec;
}
					
// static function for input parameter checks 
bool any_bad_argument(const octave_value_list& args)
{
    
    if (!args(0).is_numeric_type())
    {
        error("pricing_option_cpp: expecting Option type to be an integer");
        return true;
    }
    
    if (!args(1).is_bool_type())
    {
        error("pricing_option_cpp: expecting callflag to be a bool");
        return true;
    }
    
    if (!args(2).is_numeric_type())
    {
        error("pricing_option_cpp: expecting S to be a numeric");
        return true;
    }
    
    if (!args(3).is_numeric_type())
    {
        error("pricing_option_cpp: expecting X to be a numeric");
        return true;
    }
    
    if (!args(4).is_numeric_type())
    {
        error("pricing_option_cpp: expecting T to be a numeric");
        return true;
    }
    
    if (!args(5).is_numeric_type())
    {
        error("pricing_option_cpp: expecting r to be a numeric");
        return true;
    }
    
    if (!args(6).is_numeric_type())
    {
        error("pricing_option_cpp: expecting sigma to be a numeric");
        return true;
    }
    
    if (!args(7).is_numeric_type())
    {
        error("pricing_option_cpp: expecting divrate to be a numeric");
        return true;
    }
    
    return false;
}

/*

%!assert(pricing_option_cpp(2,true,100,[105;95;100],100,0.01,0.25,0.0,800),[3.3107992079;8.1370498012;5.3458506598],sqrt(eps))
%!assert(pricing_option_cpp(1,true,100,[105;95;100],100,0.01,0.25,0.0),[3.30997203255466;8.13568335943751;5.34747873832626],sqrt(eps))
%!assert(pricing_option_cpp(2,false,100,[105;95;100],100,0.01,0.25,0.0,800),[8.0540226787;2.8849734334;5.0887319016],sqrt(eps))
%!assert(pricing_option_cpp(1,false,100,[105;95;100],100,0.01,0.25,0.0),[8.02269451022488;2.87576560113914;5.07388109801220],sqrt(eps))
*/
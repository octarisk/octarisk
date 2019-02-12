/*
Copyright (C) 2017 Schinzilord <schinzilord@octarisk.com>

Code of inverse error function taken from:
	libit - Library for basic source and channel coding functions
	Copyright (C) 2005-2005 Vivien Chappelier, Herve Jegou
	Licensed under terms of GPL v2 (or later).

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

static bool any_bad_argument(const octave_value_list& args);

static double froot(const double& FSl, const NDArray& a, 
                    const NDArray& S, const double& riskfree, const NDArray& r, 
                    const NDArray& sigma, const double& maturity, const double& K); 

static double bisection(const NDArray& a, 
                    const NDArray& S, const double& riskfree, const NDArray& r, 
                    const NDArray& sigma, const double& maturity, const double& K,
					const double& lbound, const double& ubound, const int& maxiter, 
					const double& limit);

static double abs_double(const double& val);

double norminv_custom(double x);
double erfinv(double x);
					
DEFUN_DLD (optimize_basket_forwardprice, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{FSl}} = optimize_basket_forwardprice(@var{weights}, \n\
@var{S}, @var{riskfree}, @var{r}, @var{sigma}, @var{K}, @var{lbound}, @var{ubound}) \n\
, @var{maxiter})\n\
\n\
Compute the optimized forward price of basket options according to Beisser et al.\n\
\n\
This function is called by the script pricing_basket_options.\n\
\n\
Published in:\n\
\'Pricing of arithmetic basket options by conditioning\',\n\
G. Deelstra et al., Insurance: Mathematics and Economics 34 (2004) Pages 55ff\n\
\n\
This function solves equation (33) of aforementioned paper for FSl(K) \n\
with bisection method for root finding.\n\
\n\
Input and output variables:\n\
@itemize @bullet\n\
@item @var{weights}: weights of instruments in basket (vector)\n\
@item @var{S}: instrument spot prices (matrix: scenarios (rows), instruments (columns))\n\
@item @var{riskfree}: riskfree interest rate (vector)\n\
@item @var{r}: Weighted correlation coefficients (matrix: scenarios (rows), instruments (columns))\n\
@item @var{sigma}: instruments volatilities (matrix: scenarios (rows), instruments (columns))\n\
@item @var{K}: option strike values (vector)\n\
@item @var{lbound}: lower bound for root finding (suggestion: 0) (scalar)\n\
@item @var{ubound}: upper bound for root finding (suggestion: 1) (scalar)\n\
@item @var{maxiter}: maximum iterations in bisection method (set to 100) (scalar)\n\
@item @var{limit}: optimization limit for root finding (scalar)\n\
@item @var{FSl}: OUTPUT: Forward price (vector)\n\
@end itemize\n\
@end deftypefn")
{
  octave_value retval;
  int nargin = args.length ();

  if (nargin < 10 )
    print_usage ();
  else
  {
        // Input parameter checks
        if (any_bad_argument(args))
          return octave_value_list();

        // Input parameter
		// weights,S,riskfree,r,sigma,T,K,lbound,ubound,maxiter,
		NDArray weights 		= args(0).array_value();	// weights
		Matrix S 				= args(1).matrix_value();	// S (columns -> underlyings, rows -> scenarios)
		double riskfree 		= args(2).double_value();	// riskfree
		Matrix r 				= args(3).matrix_value();	// r (corr coeff) (columns -> underlyings, rows -> scenarios)
		Matrix sigma 			= args(4).matrix_value();	// sigma (columns -> underlyings, rows -> scenarios)
		double TF	 			= args(5).double_value();	// time factor
		double K	 			= args(6).double_value();	// Strike K
		double lbound	 		= args(7).double_value();	// lbound
		double ubound	 		= args(8).double_value();	// ubound
		int maxiter	 			= args(9).double_value();	// maxiter
		double limit	 		= args(10).double_value();	// optimization limit
				
		// loop via all scenarios
		int len_weights = weights.numel ();
		int row_S = S.rows ();
		int col_S = S.cols ();
        int len = row_S;	// length of scenarios
		
		// initialize scenario dependent output:
        dim_vector dim_scen (len, 1);
		NDArray FSl (dim_scen);
		FSl.fill(0.0);
		
		int cols_sigma = sigma.cols();
		int cols_r = r.cols();
		int rows_sigma = sigma.rows();
		int rows_r = r.rows();
		// error handling
		if (cols_sigma != cols_r)
			error("optimize_basket_forwardprice: volatility matrix sigma and corr coeff matrix needs to be of same dimension");
		if (rows_sigma != rows_r)
			error("optimize_basket_forwardprice: volatility matrix sigma and corr coeff matrix needs to be of same dimension");
		if (row_S != rows_r)
			error("optimize_basket_forwardprice: number of scenarios does not match for underlying prices and corr coeff matrix");
		if (row_S != rows_sigma)
			error("optimize_basket_forwardprice: number of scenarios does not match for underlying prices and volatility matrix");
		
		// loop via all underlyings and generate temporary arrays
			dim_vector dim_scen_col (col_S, 1);
			NDArray Sii (dim_scen_col);
			Sii.fill(0.0);
			NDArray rii (dim_scen_col);
			rii.fill(0.0);
			NDArray sigmaii (dim_scen_col);
			sigmaii.fill(0.0);
			
		// loop via all scenarios
        for (octave_idx_type ii = 0; ii < len; ii++) 
        {
            // catch ctrl + c
            OCTAVE_QUIT;
            // scenario dependent input:

            for (octave_idx_type zz = 0; zz < cols_sigma; zz++) 
            {
				Sii(zz) = S(ii,zz);
				rii(zz) = r(ii,zz);
				sigmaii(zz) = sigma(ii,zz);
            }
			// call bisection method for calculating FSl
            FSl(ii)  = bisection(weights,Sii,riskfree,rii,sigmaii,TF,K,lbound,ubound,maxiter,limit);
			
		} // scenario loop finished
        
        // return Option price
        octave_value_list option_outargs;
        option_outargs(0) = FSl;
		
        return octave_value (option_outargs);
		
    }
  return retval;
} // end of DEFUN_DLD

//#########################    HELPER FUNCTIONS    #############################


//  function for calculation of roots (equality of forward price and strike)
double bisection(const NDArray& w, 
                    const NDArray& S, const double& riskfree, const NDArray& r, 
                    const NDArray& sigma, const double& maturity, const double& K,
					const double& lbound, const double& ubound, const int& maxiter,
					const double& limit)
{
	
	octave_idx_type j = 0;
	double f_a = froot(lbound,w,S,riskfree,r,sigma,maturity,K);
	double f_b = froot(ubound,w,S,riskfree,r,sigma,maturity,K);
	double err = 0.0;
	double a = lbound;
	double b = ubound;
	double p = 0.0;
	double tmpval = 0.0;
	
	if (f_a*f_b>0 ) {
		error("Method only possible for functions with bound values of opposite sign");
	} else {
		p = (a + b)/2;
		tmpval = froot(p,w,S,riskfree,r,sigma,maturity,K);
		err = abs_double(tmpval);
		while (err > limit && j <= maxiter) {
			f_a = froot(a,w,S,riskfree,r,sigma,maturity,K);
			if (f_a*tmpval<0 ) {
			   b = p;
			} else {
			   a = p;          
			}
		   p = (a + b)/2; 
		   tmpval = froot(p,w,S,riskfree,r,sigma,maturity,K);
		   err = abs_double(tmpval);
		   j++;
		}
	}
	if (j > maxiter) {
		std::cout << "No solution found after " << j << " steps. Returning latest value." << std::endl;
	}
	
    return p;
}

// static function absolute of double precision
double abs_double(const double& val)
{
	if ( val < 0) {
		return -val;
	} else{
		return val;
	}
}	

// static function for calculation of roots (equality of forward price and strike)
double froot(const double& FSl, const NDArray& a, 
                    const NDArray& S, const double& riskfree, const NDArray& r, 
                    const NDArray& sigma, const double& maturity, const double& K)
{
	// loop via underlying components
	double retval = 0.0;
	double normsinv_FSl = norminv_custom(FSl);
	
	for (octave_idx_type zz = 0; zz < S.numel (); zz++) 
	{
		retval = retval + ( a(zz) * S(zz) * exp((riskfree - 0.5 * r(zz) * r(zz) * sigma(zz) * sigma(zz)) * maturity +
					r(zz) * sigma(zz) * sqrt(maturity) * normsinv_FSl));
	}
	// equation has form f(x) = 0, so subtract strike K
	retval = retval - K;
		
    return retval;
}

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
        error("optimize_basket_forwardprice: expecting weights to be numeric");
        return true;
    }
    
    if (!args(1).isnumeric ())
    {
        error("optimize_basket_forwardprice: expecting S to be numeric");
        return true;
    }
    
    if (!args(2).isnumeric ())
    {
        error("optimize_basket_forwardprice: expecting riskfree to be numeric");
        return true;
    }
    
    if (!args(3).isnumeric ())
    {
        error("optimize_basket_forwardprice: expecting r to be numeric");
        return true;
    }
	
	if (!args(4).isnumeric ())
    {
        error("optimize_basket_forwardprice: expecting sigma to be numeric");
        return true;
    }
	
	if (!args(5).isnumeric ())
    {
        error("optimize_basket_forwardprice: expecting T to be numeric");
        return true;
    }
	
	if (!args(6).isnumeric ())
    {
        error("optimize_basket_forwardprice: expecting K to be numeric");
        return true;
    }
	
	if (!args(7).isnumeric ())
    {
        error("optimize_basket_forwardprice: expecting lbound to be numeric");
        return true;
    }
	
	if (!args(8).isnumeric ())
    {
        error("optimize_basket_forwardprice: expecting ubound to be numeric");
        return true;
    }
	
	if (!args(9).isnumeric ())
    {
        error("optimize_basket_forwardprice: expecting maxiter to be numeric");
        return true;
    }
	
	if (!args(10).isnumeric ())
    {
        error("optimize_basket_forwardprice: expecting limit to be numeric");
        return true;
    }
    
    return false;
}

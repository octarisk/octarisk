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

static bool any_bad_argument(const octave_value_list& args);


DEFUN_DLD (calc_vola_basket_cpp, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{Volatility}} = calc_vola_basket_cpp(@var{M1}, \n\
@var{TF}, @var{exponents}, @var{prefactors}) \n\
\n\
Compute the diversified volatility of a basket of securities.\n\
\n\
This function uses long double precision to handle large volatilities.\n\
\n\
Input and output variables:\n\
@itemize @bullet\n\
@item @var{M1}: M1 of basket vola function\n\
@item @var{TF}: time factor in years\n\
@item @var{exponents}: Matrix with exponents (in columns) and different scenarios in rows\n\
@item @var{prefactors}: Matrix with prefactors (in columns) and different scenarios in rows\n\
@item @var{vola}: OUTPUT: basket volatility (vector)\n\
@end itemize\n\
@end deftypefn")
{
  octave_value retval;
  int nargin = args.length ();

  if (nargin < 4 )
    print_usage ();
  else
  {
        // Input parameter checks
        if (any_bad_argument(args))
          return octave_value_list();

        // Input parameter
		// M1,TF,exp_matrix,prefactor_matrix
		NDArray M1_dbl 				= args(0).array_value();	// M1
		double TF_dbl 				= args(1).double_value();	// time factor
		Matrix exp_dbl 			    = args(2).matrix_value();	// Exponents
		Matrix prefactor_dbl 	    = args(3).matrix_value();	// Prefactors
		
		// loop via all scenarios
		int len_M1 = M1_dbl.numel ();
		int len_exp = exp_dbl.rows ();
        int len;
        if ( len_M1 > len_exp )
            len = len_M1;
        else
            len = len_exp;
		
		// initialize scenario dependent output:
        dim_vector dim_scen (len, 1);
		NDArray Volatility (dim_scen);
		Volatility.fill(0.0);
		
		long double TF = static_cast<long double>(TF_dbl);
		int cols_exp_dbl = exp_dbl.cols();
		int cols_prefactor_dbl = prefactor_dbl.cols();
		long double ldmaxexp = static_cast<long double>(4931.0);
		// error handling
		if (cols_exp_dbl != cols_prefactor_dbl)
			error("calc_vola_basket_cpp: exponent matrix and prefactor matrix needs to be of same dimension");
		
		// loop via all scenarios
        for (octave_idx_type ii = 0; ii < len; ii++) 
        {
            // catch ctrl + c
            OCTAVE_QUIT;
            // scenario dependent input:
			// cast to long double
			long double M1;
			if (len_M1 == 1) {
				M1 = static_cast<long double>(M1_dbl(0));
		    } else {
				M1 = static_cast<long double>(M1_dbl(ii));
		    }
            long double M2 = static_cast<long double>(0.0);
            // loop via all exponents and pre factor 
            for (octave_idx_type zz = 0; zz < cols_exp_dbl; zz++) 
            {
				long double tmp_exp = static_cast<long double>(exp_dbl(ii,zz));
				// avoid long double overflow
				if (tmp_exp > ldmaxexp) {
					octave_stdout << "Exponent exceeded long double precision limit of 4931. Limiting exponent " << tmp_exp << " to prevent overflow.\n";
					tmp_exp = ldmaxexp;
				}
				long double tmp_pre = static_cast<long double>(prefactor_dbl(ii,zz));
                M2 = M2 + tmp_pre * std::exp(tmp_exp);
            }
			
			// return scenario volatility
			Volatility(ii) = static_cast<double>(std::sqrt(std::log( M2 / (M1 * M1)) / TF));
			
		} // scenario loop finished
        
        // return Option price
        octave_value_list option_outargs;
        option_outargs(0) = Volatility;

        return octave_value (option_outargs);
		
    }
  return retval;
} // end of DEFUN_DLD

//#########################    STATIC FUNCTIONS    #############################

// static function for input parameter checks
bool any_bad_argument(const octave_value_list& args)
{
    
    if (!args(0).is_numeric_type())
    {
        error("calc_vola_basket_cpp: expecting M1 to be numeric");
        return true;
    }
    
    if (!args(1).is_numeric_type())
    {
        error("calc_vola_basket_cpp: expecting TF to be numeric");
        return true;
    }
    
    if (!args(2).is_numeric_type())
    {
        error("calc_vola_basket_cpp: expecting exponents to be numeric");
        return true;
    }
    
    if (!args(3).is_numeric_type())
    {
        error("calc_vola_basket_cpp: expecting prefactors to be numeric");
        return true;
    }
    
    return false;
}

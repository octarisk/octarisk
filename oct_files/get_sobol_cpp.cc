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
#include "sobol.h"
#include "sobol.cpp"

static bool any_bad_argument(const octave_value_list& args);

			
DEFUN_DLD (get_sobol_cpp, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{retvec}} = get_sobol_cpp(@var{scen}, \n\
@var{dim}, @var{seed}) \n\
Calculate Sobol numers for @var{scen} rows and @var{dim} columns with start seed \n\
@var{seed}.\n\
Implementation uses the C++ implementation of Bennet Fox based on \n\
Netlibs ACM TOMS Algorithm 647 and ACM TOMS Algorithm 659  \n\
from http://people.sc.fsu.edu/~jburkardt/cpp_src/sobol/sobol.html\n\
licensed under GNU LGPL.\n\
\n\
@end deftypefn")
{
  octave_value retval;
  int nargin = args.length ();

  if (nargin < 3 || nargin > 3 )
    print_usage ();
  else
  {
        // Input parameter checks
        if (any_bad_argument(args))
          return octave_value_list();

        // Input parameter option_type,call_flag,S,X,T,r,sigma,divrate
        int scen      				= args(0).int_value(); // scenarios 
		int dim      				= args(1).int_value(); // dimension
		long long int custom_seed  	= args(2).int_value(); // start seed

		if ( dim > 1111)
			error("get_sobol_cpp: maximum dimension 1111");
		
		dim_vector dim_scen (scen, dim);
		NDArray retvec (dim_scen);
		retvec.fill(0.0);
		double r[dim];		
		long long int seed_in;
		long long int seed_out;
		int i,j;
		// call Sobol function for double precision results
		for ( i = 0; i < scen; i++ )
		{
			seed_in = custom_seed;
			i8_sobol ( dim, &custom_seed, r );
			seed_out = custom_seed;
			for ( j = 0; j < dim; j++ )
				retvec(i,j) = r[j];
			
		}
  
        // return Array with Sobol numbers
        octave_value_list option_outargs;
        option_outargs(0) = retvec;
        
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
        error("get_sobol_cpp: expecting scenarios to be an integer");
        return true;
    }
    
    if (!args(1).is_numeric_type())
    {
        error("get_sobol_cpp: expecting dimensions to be an integer");
        return true;
    }
	
	if (!args(2).is_numeric_type())
    {
        error("get_sobol_cpp: expecting start seed to be an integer");
        return true;
    }
    
    return false;
}

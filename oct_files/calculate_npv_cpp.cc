/*
Copyright (C) 2017 Schinzilord <schinzilord@octarisk.com>

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
#include <octave/ov-struct.h>

static bool any_bad_argument(const octave_value_list& args);

DEFUN_DLD (calculate_npv_cpp, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{retvec}} = calculate_npv_cpp(@var{values},@var{df})\n\
\n\
Calculate the sum of product of two matrizes along rows.\n\
\n\
Input and output variables:\n\
@itemize @bullet\n\
@item @var{values}: Matrix or vector of values\n\
@item @var{df}: Matrix of discount factors\n\
@item @var{retvec}: Result: column vector with sums of product of each columns\n\
@end itemize\n\
@end deftypefn")
{
  
  // Input parameter checks
	if (any_bad_argument(args))
	  return octave_value_list();
	
  Matrix values 	= args(0).matrix_value ();   // Matrix with values  
  Matrix df 		= args(1).matrix_value();	// Matrix with discount factors	  

// get input values
	int rows_df    		= df.rows ();
	int cols_df    		= df.cols ();
	int cols_values    	= values.cols ();

	if ( cols_df != cols_values )
		 error ("calculate_npv_cpp.cpp: Columns of values and df have to be equal!\n");
	 
	
  // initialize scenario dependent output:
	dim_vector dim_colvector (rows_df, 1);
	ColumnVector retvec (dim_colvector);
	retvec.fill(0.0);
	ColumnVector df_col (dim_colvector);
	ColumnVector value_col (dim_colvector);
	
  // iterate through all columns: this is faster than 
  // elementwise multiplication of matrizes
  // multiply df column vec and value column vec and add up all cols
  for (octave_idx_type ii = 0; ii < cols_df; ii++) 
	{
		// catch ctrl + c
            OCTAVE_QUIT;
		// get npv of column and sum it up to total npv
			retvec = retvec + product(df.column(ii),values.column(ii));
		
	}	// end iteration over all nodes 
  
  // return value vector
	octave_value_list option_outargs;
	option_outargs(0) = retvec;
	
   return octave_value (option_outargs);
} // end of DEFUN_DLD

// static function for input parameter checks
bool any_bad_argument(const octave_value_list& args)
{
    // octave_value_list:
    // value, df
	
	if (args.length () != 2)
	{
		print_usage ();
		return true;
	}

	if (! args(0).isnumeric ())
	{
		error ("calculate_npv_cpp: ARG0 must be numeric (values)");
		return true;
    }

	if (! args(1).isnumeric ())
	{
		error ("calculate_npv_cpp: ARG1 must be numeric (discount factors)");
		return true;
    }
	
    return false;
}

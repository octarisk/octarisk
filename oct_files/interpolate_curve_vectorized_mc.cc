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


static bool any_bad_argument(const octave_value_list& args);


DEFUN_DLD (interpolate_curve_vectorized_mc, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{retvec}} = interpolate_curve_vectorized_mc(@var{nodes},@var{rates},@var{timestep})\n\
\n\
Linear interpolation of a single timestep for all scenarios of a rate matrix.\n\
\n\
This function should be called from interpolate_curve only\n\
which handles all input and ouput data.\n\
\n\
Input and output variables:\n\
@itemize @bullet\n\
@item @var{nodes}: row vector of nodes\n\
@item @var{rates}: Matrix of column vector with rates (scenario = rows)\n\
@item @var{timestep}: Timestep to interpolate (integer)\n\
@item @var{retvec}: Result: Matrix with interpolated rates (rows) for each timestep (column)\n\
@end itemize\n\
@end deftypefn")
{
  
	// Input parameter checks
	if (any_bad_argument(args))
	  return octave_value_list();
	
	NDArray nodes 	= args(0).array_value ();   // Vector with nodes  
	Matrix  rates 	= args(1).matrix_value();	// Matrix with rates	  
	long timestep 	= args(2).int_value ();   // Timestep (int) 
 
	// calculate discount factor
	octave_idx_type len_nodes     = nodes.numel ();
	octave_idx_type rows_rates    = rates.rows ();
	octave_idx_type cols_rates    = rates.cols ();

	if ( cols_rates != len_nodes )
		 error ("interpolate_curce_vectorized.cpp: Columns of nodes and rates have to be equal!\n");
	 
	// calc diff node
	dim_vector dim_scen_dnode (len_nodes - 1, 1);
	NDArray dnodes (dim_scen_dnode);
	dnodes.fill(0.0);
	long minnode, maxnode;
	octave_idx_type idx_min, idx_max;
	minnode = nodes(0);
	maxnode = nodes(0);
	idx_min = 0;
	idx_max = 0;
	for (octave_idx_type jj = 0; jj < len_nodes - 1; jj++) 
	{
		dnodes(jj) = abs(nodes(jj+1) - nodes(jj));
		if ( nodes(jj) < minnode) 
		{
			minnode = nodes(jj);
			idx_min = jj;
		}
		if ( nodes(jj) > maxnode)
		{
			maxnode = nodes(jj);
			idx_max = jj;
		}
	}
	// check for last node:
	if ( nodes(len_nodes - 1) < minnode) 
	{
		minnode = nodes(len_nodes - 1);
		idx_min = len_nodes - 1;
	}
	if ( nodes(len_nodes - 1) > maxnode) 
	{
		maxnode = nodes(len_nodes - 1);
		idx_max = len_nodes - 1;	
	}
	// initialize scenario dependent output:
	double rate, w1, w2;
	dim_vector dim_scenvector (rows_rates, 1);
	ColumnVector aa (dim_scenvector);
	ColumnVector bb (dim_scenvector);
	ColumnVector tmp1 (dim_scenvector);
	ColumnVector tmp2 (dim_scenvector);
	ColumnVector retval (dim_scenvector);
	
	// constant extrapolation previous
	if (timestep <= minnode)	
		{
			retval = rates.column(idx_min);
		}
	else if (timestep >= maxnode)	// constant extrapolation last
		{
			retval = rates.column(idx_max);
		}
	else  // interpolation
	{
		// loop through all nodes
		for (octave_idx_type kk = 0; kk < len_nodes - 1; kk++) 
		{		
			if ( abs(timestep) >= abs(nodes(kk)) && abs(timestep) <= abs(nodes(kk+1 )) )
			{
				// calculate weights
				w1 = 1.0 - abs(timestep - nodes(kk)) / dnodes(kk);
				w2 = 1.0 - w1;
				tmp1.fill(w1);
				tmp2.fill(w2);
				retval = product(tmp1,rates.column(kk)) + product(tmp2,rates.column(kk + 1));
				break;
			}
		}
	}
  
  // return interpolated value vector
	octave_value_list option_outargs;
	option_outargs(0) = retval;
	
   return octave_value (option_outargs);
} // end of DEFUN_DLD


// static function for input parameter checks
bool any_bad_argument(const octave_value_list& args)
{
    // octave_value_list:
    // struct, xx, yy, zz
	
	if (args.length () != 3)
	{
		print_usage ();
		return true;
	}

	if (! args(0).is_numeric_type ())
	{
		error ("interpolate_curve_vectorized: ARG0 must be numeric (nodes)");
		return true;
    }

	if (! args(1).is_numeric_type())
	{
		error ("interpolate_curve_vectorized: ARG1 must be numeric (rates)");
		return true;
    }
	
	if (! args(2).is_numeric_type())
	{
		error ("interpolate_curve_vectorized: ARG2 must be numeric (timestep)");
		return true;
    }
    
    return false;
}

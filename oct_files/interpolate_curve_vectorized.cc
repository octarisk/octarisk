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
#include <octave/unwind-prot.h>
#include <cmath>
#include <octave/parse.h>
#include <octave/ov-struct.h>

void
my_err_handler (const char *fmt, ...)
{
  // Do nothing!!
}

void
my_err_with_id_handler (const char *id, const char *fmt, ...)
{
  // Do nothing!!
}

static bool any_bad_argument(const octave_value_list& args);
static double previous_neighbour(NDArray axis_values, double coord);
static double next_neighbour(NDArray axis_values, double coord);
static octave_idx_type get_indexvalue(NDArray axis_values, double coord);


DEFUN_DLD (interpolate_curve_vectorized, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{retvec}} = interpolate_curve_vectorized(@var{nodes},@var{rates},,@var{timesteps})\n\
\n\
Linear interpolation of a vector of timesteps for all scenarios of a rate matrix.\n\
\n\
This function should be called from interpolate_curve only\n\
which handles all input and ouput data.\n\
\n\
Input and output variables:\n\
@itemize @bullet\n\
@item @var{nodes}: Column vector of nodes\n\
@item @var{rates}: Matrix of column vector with rates (scenario = rows)\n\
@item @var{timesteps}: Column vector of timesteps to interpolate.\n\
@item @var{retvec}: Result: Matrix with interpolated rates (rows) for each timestep (column)\n\
@end itemize\n\
@end deftypefn")
{
  
  // Input parameter checks
	if (any_bad_argument(args))
	  return octave_value_list();
	
  NDArray nodes 	= args(0).array_value ();   // Vector with nodes  
  Matrix  rates 	= args(1).matrix_value();	// Matrix with rates	  
  NDArray timesteps = args(2).array_value ();   // Vector with timesteps  
 
// calculate discount factor
	int len_nodes     = nodes.numel ();
	int len_timesteps = timesteps.numel ();
	int rows_rates    = rates.rows ();
	int cols_rates    = rates.cols ();

	if ( cols_rates != len_nodes )
		 error ("interpolate_curce_vectorized.cpp: Columns of nodes and rates have to be equal!\n");
	 

  // calc diff node
	dim_vector dim_scen_dnode (len_nodes - 1, 1);
	NDArray dnodes (dim_scen_dnode);
	dnodes.fill(0.0);
	for (octave_idx_type jj = 0; jj < len_nodes - 1; jj++) 
	{
		dnodes(jj) = nodes(jj+1) - nodes(jj);
	}
	
  // initialize scenario dependent output:
	dim_vector dim_scen (rows_rates, len_timesteps);
	Matrix retmat (dim_scen);
	retmat.fill(0.0);
	double rate;
	int timestep, node, firstnode, lastnode;
	firstnode = nodes(0);
	lastnode  = nodes(len_nodes - 1);
    bool foundflag;
	dim_vector dim_scenvector (rows_rates, 1);
	ColumnVector aa (dim_scenvector);
	ColumnVector bb (dim_scenvector);
	ColumnVector tmp1 (dim_scenvector);
	ColumnVector tmp2 (dim_scenvector);
	ColumnVector tmpret (dim_scenvector);
	
  // iterate through all nodes
  //  Only if timesteps lies between nodes, interpolation of all scenarios is performed
  for (octave_idx_type ii = 0; ii < len_timesteps; ii++) 
	{
		// catch ctrl + c
            OCTAVE_QUIT;
		
		// current timestep
		timestep = timesteps(ii);
		foundflag = false;
		// octave_stdout << "Timestep: " << timestep << "\n";
		// constant extrapolation previous
		if (abs(timestep) <= firstnode)	
			{
				aa = rates.column(0);
				retmat.insert(aa, 0, ii); 
			}
		else if (abs(timestep) >= lastnode)	// constant extrapolation last
			{
				aa = rates.column(len_nodes - 1);
				retmat.insert(aa, 0, ii);
			}
		else  // interpolation
		{
			// loop through all nodes
			for (octave_idx_type kk = 0; kk < len_nodes - 1; kk++) 
			{
				if ( foundflag == true)
				{
				    break;	
				}				  
				if ( abs(timestep) >= abs(nodes(kk)) && abs(timestep) <= abs(nodes(kk+1 )) )
				{
					foundflag = true;
					// extract scenariovalues and compute rate
					aa = rates.column(kk); 
					bb = rates.column(kk + 1); 
					tmp1.fill(1 - abs(timestep - nodes(kk)) / dnodes(kk));
					tmp2.fill(1 - abs(nodes(kk + 1) - timestep) / dnodes(kk));
					tmpret = product(tmp1,aa) + product(bb,tmp2);
					retmat.insert(tmpret, 0, ii);
					
				}
			}
		}
		
	}	// end iteration over all nodes 
  
  // return interpolated value vector
	octave_value_list option_outargs;
	option_outargs(0) = retmat;
	
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
		error ("interpolate_cubestruct: ARG0 must be numeric (nodes)");
		return true;
    }

	if (! args(1).is_numeric_type())
	{
		error ("interpolate_cubestruct: ARG1 must be numeric (rates)");
		return true;
    }
	
	if (! args(2).is_numeric_type())
	{
		error ("interpolate_cubestruct: ARG2 must be numeric (timesteps)");
		return true;
    }
    
    return false;
}
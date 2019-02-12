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
static double previous_neighbour(NDArray axis_values, double coord);
static double next_neighbour(NDArray axis_values, double coord);
static octave_idx_type get_indexvalue(NDArray axis_values, double coord);


DEFUN_DLD (interpolate_cubestruct, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{retvec}} = interpolate_cubestruct(@var{struct},@var{xx}, @var{yy}, @var{zz})\n\
\n\
Interpolate cube values from all elements of an structure array of\n\
all cube fieldnames.\n\
\n\
This function should be called from  getValue method of Surface class\n\
which handles all input and ouput data.\n\
Please note that axis values needs to be sorted.\n\
\n\
Input and output variables:\n\
@itemize @bullet\n\
@item @var{struct}: structure with the following fields (struct)\n\
@itemize @bullet\n\
@item @var{id}: scenario ID (string)\n\
@item @var{cube}: volatility cube (one volatility value per x,y,z coordinate) (NDArray)\n\
@item @var{x_axis}: sorted vector of x-axis values (NDArray)\n\
@item @var{y_axis}: sorted vector of y-axis values (NDArray)\n\
@item @var{z_axis}: sorted vector of z-axis values (NDArray)\n\
@end itemize\n\
@item @var{xx}: x coordinate used for interpolation of cube value\n\
@item @var{yy}: y coordinate used for interpolation of cube value\n\
@item @var{zz}: z coordinate used for interpolation of cube value (scalar or vector)\n\
@item @var{retvec}: return vector of scenario dependent interpolated volatility values (NDArray) \n\
@end itemize\n\
@end deftypefn")
{
  
  // Input parameter checks
	if (any_bad_argument(args))
	  return octave_value_list();
	  
  octave_map input_struct = args(0).map_value ();
  double xx            = args(1).double_value ();  // xx coordinates to interpolate
  double yy            = args(2).double_value ();  // yy coordinates to interpolate
  NDArray zz            = args(3).array_value ();  // zz coordinates to interpolate

  // get fieldnames of provided struct
    std::string fieldname_cube = "cube";
    std::string fieldname_id = "id";
	std::string fieldname_xx = "axis_x";
	std::string fieldname_yy = "axis_y";
	std::string fieldname_zz = "axis_z";
  
  // get length of input struct
    int len = input_struct.contents (fieldname_id).numel ();
    // std::cout << "Length of structure array:" << len << "\n";

  // initialize scenario dependent output:
	dim_vector dim_scen (len, 1);
	NDArray retvec (dim_scen);
	retvec.fill(0.0);
	octave_value vola_cube;
	NDArray vola_array;
	octave_value x_axis;
	NDArray xx_values;
	octave_value y_axis;
	NDArray yy_values;
	octave_value z_axis;
	NDArray zz_values;
	
  // check for zz: vector or scalar? check length
    NDArray zz_vec(dim_scen);
    if (zz.numel () == 1) {
		for (octave_idx_type kk = 0; kk < len; kk++) 
		{
		 	zz_vec(kk) = zz(1); 
		}
		
	} else {
		zz_vec = zz;
    }	 
  // iterate over all structure array entries 
  for (octave_idx_type ii = 0; ii < len; ii++) 
	{
		// catch ctrl + c
            OCTAVE_QUIT;
			
		// get vola cube
		vola_cube = input_struct.contents (fieldname_cube)(ii);
		if (! vola_cube.is_defined ())
			error ("interpolate_cubestruct: struct does not have a field named 'cube'\n");
		vola_array    = vola_cube.array_value ();
		
		// get x axis values
		x_axis = input_struct.contents (fieldname_xx)(ii);
		if (! x_axis.is_defined ())
			error ("interpolate_cubestruct: struct does not have a field named '%s'\n", fieldname_xx.c_str ());
		xx_values    = x_axis.array_value ();
		
		// get y axis values
		y_axis = input_struct.contents (fieldname_yy)(ii);
		if (! y_axis.is_defined ())
			error ("interpolate_cubestruct: struct does not have a field named '%s'\n", fieldname_yy.c_str ());
		yy_values    = y_axis.array_value ();
		
		// get z axis values
		z_axis = input_struct.contents (fieldname_zz)(ii);
		if (! z_axis.is_defined ())
			error ("interpolate_cubestruct: struct does not have a field named '%s'\n", fieldname_zz.c_str ());
		zz_values    = z_axis.array_value ();
		
		// interpolate vola cube and return  interpolated values
		
		// get nearest values for xx, yy and zz from axis values
			double x0 = previous_neighbour(xx_values, xx);
			double x1 = next_neighbour(xx_values, xx);
			double y0 = previous_neighbour(yy_values, yy);
			double y1 = next_neighbour(yy_values, yy);
			double z0 = previous_neighbour(zz_values, zz_vec(ii));
			double z1 = next_neighbour(zz_values, zz_vec(ii));
		// get differences
			double xd, yd, zd;
			if ( x0 == x1) { 
				xd = 0;
			} else {
				xd = (xx - x0) / (x1 - x0);
			}
			if ( y0 == y1) { 
				yd = 0;
			} else {
				yd = (yy - y0) / (y1 - y0);
			}
			if ( z0 == z1) { 
				zd = 0;
			} else {
				zd = (zz_vec(ii) - z0) / (z1 - z0);
			}
		// extract volatility value
			octave_idx_type index_x0 = get_indexvalue(xx_values, x0);
			octave_idx_type index_y0 = get_indexvalue(yy_values, y0);
			octave_idx_type index_z0 = get_indexvalue(zz_values, z0);
			octave_idx_type index_x1 = get_indexvalue(xx_values, x1);
			octave_idx_type index_y1 = get_indexvalue(yy_values, y1);
			octave_idx_type index_z1 = get_indexvalue(zz_values, z1);
			double V_x0y0z0 = vola_array(index_y0,index_x0,index_z0);
			double V_x0y0z1 = vola_array(index_y0,index_x0,index_z1);
			double V_x0y1z0 = vola_array(index_y1,index_x0,index_z0);
			double V_x0y1z1 = vola_array(index_y1,index_x0,index_z1);
			double V_x1y0z0 = vola_array(index_y0,index_x1,index_z0);
			double V_x1y0z1 = vola_array(index_y0,index_x1,index_z1);
			double V_x1y1z0 = vola_array(index_y1,index_x1,index_z0);
			double V_x1y1z1 = vola_array(index_y1,index_x1,index_z1);
		// interpolate along x axis
			double c00 = V_x0y0z0 * ( 1 - xd ) + V_x1y0z0 * xd;
			double c01 = V_x0y0z1 * ( 1 - xd ) + V_x1y0z1 * xd;
			double c10 = V_x0y1z0 * ( 1 - xd ) + V_x1y1z0 * xd;
			double c11 = V_x0y1z1 * ( 1 - xd ) + V_x1y1z1 * xd;
		// interpolate along y axis
			double c0 = c00 * (1 - yd ) + c10 * yd;
			double c1 = c01 * (1 - yd ) + c11 * yd;
		// interpolate along x axis and return final value "y"
			double retval = c0 * (1 - zd ) + c1 * zd;     
					
		// save result to return vector
		retvec(ii) = retval;
	}	// end iteration over all structure entries
  
  // return interpolated value vector
	octave_value_list option_outargs;
	option_outargs(0) = retvec;
	
   return octave_value (option_outargs);
} // end of DEFUN_DLD

//#########################    STATIC FUNCTIONS    #############################

// static function get index value of value in array
octave_idx_type get_indexvalue(NDArray axis_values, double coord)
    {
		octave_idx_type retval = 0;
		for (octave_idx_type ii = 0; ii < axis_values.numel(); ii++) 
		{
			if ( axis_values(ii) == coord)
				retval = ii;
		} 
		return retval;
    }

// static function getting axis value previous to input value
double previous_neighbour(NDArray axis_values, double coord)
    {
		if ( axis_values.numel() < 2 )
			return axis_values(0);
		
		double retval = 0.0;
		
		for (octave_idx_type ii = 0; ii < axis_values.numel(); ii++) 
		{
			if ( axis_values(ii) <= coord)
				retval =  axis_values(ii);
		}
		return retval;  
    }
	
// static function getting axis value next to input value
double next_neighbour(NDArray axis_values, double coord)
    {
		if ( axis_values.numel() < 2 )
			return axis_values(0);
		
		double retval = axis_values(axis_values.numel() - 1);
		
		for (octave_idx_type ii = axis_values.numel(); ii >= 0 ; ii--) 
		{
			if ( axis_values(ii) >= coord)
				retval =  axis_values(ii);
		}
		return retval;  
    }


// static function for input parameter checks
bool any_bad_argument(const octave_value_list& args)
{
    // octave_value_list:
    // struct, xx, yy, zz
	
	if (args.length () != 4)
	{
		print_usage ();
		return true;
	}

	if (! args(0).isstruct ())
	{
		error ("interpolate_cubestruct: ARG0 must be a struct");
		return true;
    }

	if (! args(1).isnumeric ())
	{
		error ("interpolate_cubestruct: ARG1 must be numeric (Term)");
		return true;
    }

	if (! args(2).isnumeric ())
	{
		error ("interpolate_cubestruct: ARG2 must be numeric (Tenor)");
		return true;
    }

	if (! args(3).isnumeric ())
	{
		error ("interpolate_cubestruct: ARG3 must be numeric (Moneyness)");
		return true;
    }
    
    return false;
}

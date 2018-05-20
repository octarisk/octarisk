/*
Copyright (C) 2016 Schinzilord <schinzilord@octarisk.com>
Copyright (C) 2008 Frances Y. Kuo <f.kuo@unsw.edu.au>

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

*/ 
// Source code for Sobol number generation downloaded from
// http://web.maths.unsw.edu.au/~fkuo/sobol/
// The following text refers to the function "sobol_points" 
// Frances Y. Kuo
//
// Email: <f.kuo@unsw.edu.au>
// School of Mathematics and Statistics
// University of New South Wales
// Sydney NSW 2052, Australia
// 
// Last updated: 21 October 2008
//
//   You may incorporate this source code into your own program 
//   provided that you
//   1) acknowledge the copyright owner in your program and publication
//   2) notify the copyright owner by email
//   3) offer feedback regarding your experience with different direction numbers
//
//
// -----------------------------------------------------------------------------
// Licence pertaining to sobol.cc and the accompanying sets of direction numbers
// -----------------------------------------------------------------------------
// Copyright (c) 2008, Frances Y. Kuo and Stephen Joe
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
// 
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
// 
//     * Neither the names of the copyright holders nor the names of the
//       University of New South Wales and the University of Waikato
//       and its contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// -----------------------------------------------------------------------------


#include <octave/oct.h>
#include <cmath>
#include <octave/parse.h>
#include <octave/oct-rand.h>

#include <cstdlib>
#include <cmath>
#include <iostream>
#include <iomanip>
#include <fstream>


static bool any_bad_argument(const octave_value_list& args);

double **sobol_points(unsigned N, unsigned D, std::string dir_file)
{
	std::ifstream infile(dir_file,std::ifstream::in);
	if (!infile) {
		error("Input file containing direction numbers cannot be found!");
		exit(1);
	}
	char buffer[1000];
	infile.getline(buffer,1000,'\n');

	// L = max number of bits needed 
	unsigned L = (unsigned)ceil(log((double)N)/log(2.0)); 

	// C[i] = index from the right of the first zero bit of i
	unsigned *C = new unsigned [N];
	C[0] = 1;
	for (unsigned i=1;i<=N-1;i++) {
		C[i] = 1;
		unsigned value = i;
		while (value & 1) {
			value >>= 1;
			C[i]++;
		}
	}

	// POINTS[i][j] = the jth component of the ith point
	//                with i indexed from 0 to N-1 and j indexed from 0 to D-1
	double **POINTS = new double * [N];
	for (unsigned i=0;i<=N-1;i++) POINTS[i] = new double [D];
	for (unsigned j=0;j<=D-1;j++) POINTS[0][j] = 0; 

	// ----- Compute the first dimension -----

	// Compute direction numbers V[1] to V[L], scaled by pow(2,32)
	unsigned *V = new unsigned [L+1]; 
	for (unsigned i=1;i<=L;i++) V[i] = 1 << (32-i); // all m's = 1

	// Evalulate X[0] to X[N-1], scaled by pow(2,32)
	unsigned *X = new unsigned [N];
	X[0] = 0;
	for (unsigned i=1;i<=N-1;i++) {
		X[i] = X[i-1] ^ V[C[i-1]];
		POINTS[i][0] = (double)X[i]/pow(2.0,32); // *** the actual points
		//        ^ 0 for first dimension
	}

	// Clean up
	delete [] V;
	delete [] X;


	// ----- Compute the remaining dimensions -----
	for (unsigned j=1;j<=D-1;j++) {

		// Read in parameters from file 
		unsigned d, s;
		unsigned a;
		infile >> d >> s >> a;
		unsigned *m = new unsigned [s+1];
		for (unsigned i=1;i<=s;i++) infile >> m[i];

		// Compute direction numbers V[1] to V[L], scaled by pow(2,32)
		unsigned *V = new unsigned [L+1];
		if (L <= s) {
			for (unsigned i=1;i<=L;i++) V[i] = m[i] << (32-i); 
		}
		else {
			for (unsigned i=1;i<=s;i++) V[i] = m[i] << (32-i); 
			for (unsigned i=s+1;i<=L;i++) {
				V[i] = V[i-s] ^ (V[i-s] >> s); 
				for (unsigned k=1;k<=s-1;k++) 
					V[i] ^= (((a >> (s-1-k)) & 1) * V[i-k]); 
			}
		}

		// Evalulate X[0] to X[N-1], scaled by pow(2,32)
		unsigned *X = new unsigned [N];
		X[0] = 0;
		for (unsigned i=1;i<=N-1;i++) {
			X[i] = X[i-1] ^ V[C[i-1]];
			POINTS[i][j] = (double)X[i]/pow(2.0,32); // *** the actual points
			//        ^ j for dimension (j+1)
		}

		// Clean up
		delete [] m;
		delete [] V;
		delete [] X;
	}
	delete [] C;

	return POINTS;
}

			
DEFUN_DLD (calc_sobol_cpp, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{retvec}} = calc_sobol_cpp(@var{scen}, \n\
@var{dim}, @var{directionfile}) \n\
Calculate Sobol numbers for @var{scen} rows and @var{dim} columns for a \n\
given file with direction numbers @var{directionfile}.\n\
Implementation uses code of Frances Y. Kuo and Stephen Joe, 2008.\n\
taken from http://web.maths.unsw.edu.au/~fkuo/sobol/\n\
License included in source code.\n\
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

		// Input parameter rows, columns, path to direction file
		int scen      				= args(0).int_value(); // scenarios 
		int dim      				= args(1).int_value(); // dimension
		std::string dir_file     	= args(2).string_value(); // direction file path

		if ( dim > 21201)
			error("get_sobol_cpp: maximum dimension 21201");

		dim_vector dim_scen (scen, dim);
		NDArray retvec (dim_scen);
		retvec.fill(0.0);		

		int i,j;
		// call Sobol function for double precision results
		double **P = sobol_points(scen,dim,dir_file); 

		for (unsigned i=0;i<scen;i++) 
			for (unsigned j=0;j<dim;j++)	
				retvec(i,j) = P[i][j];

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
    
    if (!args(0).is_numeric_type ())
    {
        error("calc_sobol_cpp: expecting scenarios to be an integer");
        return true;
    }
    
    if (!args(1).is_numeric_type ())
    {
        error("calc_sobol_cpp: expecting dimensions to be an integer");
        return true;
    }
	
	if (!args(2).is_string())
    {
        error("calc_sobol_cpp: expecting directions file path to be a string");
        return true;
    }
    
    return false;
}

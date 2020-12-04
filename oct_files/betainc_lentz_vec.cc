// Copyright (C) 2017 Michele Ginesi
// Copyright (C) 2017 Stefan Schloegl
//
//
// Octave is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// Octave is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Octave; see the file COPYING.  If not, see
// <http://www.gnu.org/licenses/>.

#include <octave/oct.h>
#include <cmath>
#include <octave/parse.h>

DEFUN_DLD (betainc_lentz_vec, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{f}} = betainc_lentz_vec(@var{y},@var{a},@var{b})\n\
\n\
Continued fraction for incomplete gamma function (vectorized version).\n\
This function should be called from function batainc_vec.m only.\n\
\n\
Input and output variables:\n\
@itemize @bullet\n\
@item @var{x}: x value to calcluate cumulative beta distribution\n\
@item @var{a}: first shape parameter \n\
@item @var{b}: second shape parameter\n\
@item @var{f}: return value of beta cdf at x for a and b\n\
@end itemize\n\
@end deftypefn")
{
  int nargin = args.length ();
  octave_value_list outargs;
  if (nargin != 3)
    print_usage ();
  else
    {
        NDArray x_arg = args(0).array_value ();
        NDArray a_arg = args(1).array_value ();
        NDArray b_arg = args(2).array_value ();
      
      // total number of scenarios: get maximum of length of all vectors
		int len_x = x_arg.rows ();
		int len_a = a_arg.rows ();
		int len_b = b_arg.rows ();
		int len = std::max(std::max(len_x,len_a),len_b);

	  // input checks
		if (len_x > 1 && len_x != len)
			error("betainc_lentz_vec: expecting S to be of length 1 or %d",len);
		if (len_a > 1 && len_a != len)
			error("betainc_lentz_vec: expecting X to be of length 1 or %d",len);
		if (len_b > 1 && len_b != len)
			error("betainc_lentz_vec: expecting T to be of length 1 or %d",len);

	  // initialize scenario dependent output:
		dim_vector dim_scen (len, 1);
		ColumnVector f (dim_scen);
        
		NDArray x (dim_scen);
		NDArray a (dim_scen);
		NDArray b (dim_scen);
		
	  // initialize scenario dependent input values (idx either 0 or ii)
		if ( len_x == 1 )
			x.fill(x_arg(0));
		else 
			x = x_arg;
		//		
		if ( len_a == 1 )
			a.fill(a_arg(0));
		else 
			a = a_arg;
		//
		if ( len_b == 1 )
			b.fill(b_arg(0));
		else
			b = b_arg;

		static const double tiny = pow (2, -100);
        static const double eps = std::numeric_limits<double>::epsilon();
        double f_tmp, C, D, alpha_m, beta_m, x2, Delta;
        int m, maxit;
        m = 1;
        maxit = 200;
        // loop via all scenarios
		for (octave_idx_type ii = 0; ii < len; ++ii) 
		{
		  // catch ctrl + c
		  OCTAVE_QUIT;
          f_tmp = tiny;
          C = f_tmp;
          D = 0;
          alpha_m = 1;
          beta_m = a(ii) - (a(ii) * (a(ii)+b(ii))) / (a(ii) + 1) * x(ii);
          x2 = x(ii)* x(ii);
          Delta = 0;
          m = 1;
          while((std::abs(Delta - 1) > eps) & (m < maxit))
            {
               D = beta_m + alpha_m * D;
               if (D == 0)
                 D = tiny;
               C = beta_m + alpha_m / C;
               if (C == 0)
                 C = tiny;
               D = 1 / D;
               Delta = C * D;
               f_tmp *= Delta;
               alpha_m = ((a(ii) + m - 1) * (a(ii) + b(ii) + m - 1) * (b(ii) - m) * m) / ((a(ii) + 2 * m - 1) * (a(ii) + 2 * m - 1)) * x2;
               beta_m = a(ii) + 2 * m + ((m * (b(ii) - m)) / (a(ii) + 2 * m - 1) - ((a(ii) + m) * (a(ii) + b(ii) + m)) / (a(ii) + 2 * m + 1)) * x(ii);
               m++;
             }
          f(ii) = f_tmp;
        }
		outargs(0) = f;
      }
  
  return octave_value (outargs);
}
   

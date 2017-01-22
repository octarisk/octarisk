#include <octave/oct.h>
#include <cmath>
#include <octave/parse.h>


static bool any_bad_argument(const octave_value_list& args);

DEFUN_DLD (discount_factor_cpp, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{df}} = discount_factor_cpp(@var{d1}, \n\
@var{d2}, @var{rate}, @var{comp_type}, @var{basis}, @var{comp_freq})\n\
\n\
Compute the discount factor @var{discount_factor} for a specific time period, \n\
compounding type, day count basis and compounding frequency.\n\
\n\
Input and output variables:\n\
@itemize @bullet\n\
@item @var{d1}: number of days until first date (scalar)\n\
@item @var{d2}: number of days until second date (scalar)\n\
@item @var{rate}: interest rate between first and second date (scalar)\n\
@item @var{comp_type}: compounding type: [simple, simp, disc, discrete, \n\
cont, continuous] (string)\n\
@item @var{basis}: day-count basis (scalar)\n\
@item @var{comp_freq}: 1,2,4,12,52,365 or [daily,weekly,monthly,\n\
quarter,semi-annual,annual] (scalar or string)\n\
@item @var{df}: OUTPUT: discount factor (scalar)\n\
@end itemize\n\
@seealso{timefactor, get_basis}\n\
@end deftypefn")
{
  int nargin = args.length ();

  if (nargin < 6)
    print_usage ();
  else
    {
          
	  // Input parameter checks
	  if (any_bad_argument(args))
		  return octave_value_list();
	
	  // d1, d2, rate, comp_type, basis, comp_freq
	  NDArray d1 = args(0).array_value ();
	  NDArray d2 = args(1).array_value ();
	  NDArray rate = args(2).array_value ();
	  std::string comp_type = args(3).string_value ();
	  int basis = args(4).int_value ();
	  int compounding;
	  // evaluate input comp_freq
	  if (args(5).is_string ())  // comp_freq is string
	  {
		  std::string comp_freq = args(5).string_value ();
		  if (comp_freq == "annual") {
			compounding = 1;
		  } else if (comp_freq == "semi-annual") {  
			compounding = 2;
		  } else if (comp_freq == "quarter") {  
			compounding = 3;
		  } else if (comp_freq == "monthly") {  
			compounding = 12;
		  } else if (comp_freq == "weekly") {
			compounding = 365;
		  } else if (comp_freq == "daily") {
			compounding = 365;
		  } else {
			error("discount_factor_cpp: unknown comp_freq");
			compounding = 1;
		  }
	  }
	  else if (args(5).is_scalar_type  ()) // comp_freq is integer
	  {
		  compounding = args(5).int_value ();
	  }
	  // call Octave function timefactor(d1,d2,basis)
		  // set new argument list
		  octave_value_list newargs;
		  newargs(0) = args(0);
		  newargs(1) = args(1);
		  newargs(2) = args(4);
		  // call function
		  std::string fcn = "timefactor";
		  NDArray tf ;
		  tf(0) = 1.0;
		  octave_value_list tf_retval;
		  if (! error_state) {
			tf_retval = feval (fcn, newargs, nargout);
			tf = tf_retval(0).array_value ();
		  }

	  // calculate discount factor
	  int len_tf = tf.numel ();
	  int len_rate = rate.numel ();
	  int len;
	  if ( len_rate > len_tf )
		 len = len_rate;
	  else
		 len = len_tf;
	  
	  // get comp_type
	  int compounding_type;
	  if ( comp_type == "simple" || comp_type == "smp") 
				compounding_type = 1;
	  else if ( comp_type == "discrete" || comp_type == "disc")
				compounding_type = 2;
	  else if ( comp_type == "continuous" || comp_type == "cont")
				compounding_type = 3;
				
	  // declare output variable
	  dim_vector dv (len, 1);
	  NDArray retvec (dv);
	  double tmp_rate;
	  double tmp_tf;
	  
	  for (octave_idx_type ii = 0; ii < len; ii++) 
		{
		  
		  if ( len_rate > 1 )
			tmp_rate = rate(ii);
		  else
			tmp_rate = rate(0);
		   
		  if ( len_tf > 1 )
			tmp_tf = tf(ii);
		  else
			tmp_tf = tf(0);
			
		  if ( compounding_type == 1) 
				retvec(ii) = 1 / ( 1 + tmp_rate * tmp_tf );
		  else if (  compounding_type == 2)
				retvec(ii) = 1 / pow(( 1 + ( tmp_rate / compounding) ),compounding * tmp_tf);
		  else if (  compounding_type == 3)
				retvec(ii) = exp(-tmp_rate * tmp_tf );
		}
	   return octave_value (retvec);
   }
}

// static function for input parameter checks
bool any_bad_argument(const octave_value_list& args)
{
    // octave_value_list:
    // d1, d2, rate, comp_type, basis, comp_freq
          
    if (!args(0).is_numeric_type())
    {
        error("discount_factor_cpp: expecting d1 to be a numeric");
        return true;
    }

    if (!args(1).is_numeric_type())
    {
        error("discount_factor_cpp: expecting d1 to be a numeric");
        return true;
    }

    if (!args(2).is_numeric_type())
    {
        error("discount_factor_cpp: expecting rate to be a numeric");
        return true;
    }

    if (!args(3).is_string ())
    {
        error("discount_factor_cpp: expecting comp_type to be a string");
        return true;
    }
    
    if (!args(4).is_scalar_type ())
    {
        error("discount_factor_cpp: expecting basis to be a scalar");
        return true;
    }
    
    if (!(args(5).is_scalar_type () || args(5).is_string ()))
    {
        error("discount_factor_cpp: expecting comp_freq to be a integer");
        return true;
    }

    return false;
}
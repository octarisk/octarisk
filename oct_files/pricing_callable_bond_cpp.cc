/*
Copyright (C) 2016 Schinzilord <schinzilord@octarisk.com>
Copyright (C) 2011 User Anon from http://www.volopta.com/Matlab.html. 
The code was adopted and extended from his Octave script 
"Hull_White_Trinomial_Tree_Clewlow_Strickland.m".

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

static octave_value_list build_hw_probabilities(const octave_value_list& args); 
static octave_value_list build_hw_tree(const octave_value_list& args); 
static octave_value_list get_bond_price(const octave_value_list& args); 
static octave_value_list get_american_option_price(const octave_value_list& args); 

DEFUN_DLD (pricing_callable_bond_cpp, args, nargout, "-*- texinfo -*-\n\
@deftypefn{Loadable Function} {@var{Put} @var{Call}} = pricing_callable_bond_cpp(@var{T}, \n\
@var{N}, @var{alpha}, @var{sigma_vec}, @var{cf_dates}, @var{cf_matrix}, \n\
@var{R_matrix}, @var{dt}, @var{Timevec}, @var{notional}, @var{Mat}, @var{K}) \n\
\n\
Compute the put and call value of a bondoption based on the Hull-White Tree.\n\
\n\
This function should be called from Octave script option_bond_hw.m\n\
which handles all input and ouput data.\n\
References:\n\
@itemize @bullet\n\
@item Hull, Options, Futures and other derivatives, 6th Edition\n\
@item User Anan from volopta.com references to Clewlow and Strickland,\n\
Implementing Derivatives Models.\n\
@end itemize\n\
\n\
Input and output variables:\n\
@itemize @bullet\n\
@item @var{T}: Bond Maturity in years\n\
@item @var{N}: Number of cash flow dates / call dates\n\
@item @var{alpha}: mean reversion parameter of Hull-White model\n\
@item @var{sigma_vec}: scenario dependent volatility \n\
@item @var{cf_dates}: row vector with cash flow dates (in days)\n\
@item @var{cf_matrix}: scenario dependent cash flow values\n\
@item @var{R_matrix}: scenario dependent discount rates for each cf date)\n\
@item @var{dt}: row vector with time steps between call dates\n\
@item @var{Timevec}: row vector with timesteps of cf_dates and a year after\n\
@item @var{notional}: bond notional)\n\
@item @var{Mat}: cash flow index of options maturity date\n\
@item @var{K}: Strike value\n\
@item @var{Put}: OUTPUT: Putprices (vector)\n\
@item @var{Call}: OUTPUT: Callprices (vector)\n\
@end itemize\n\
@end deftypefn")
{
  octave_value retval;
  int nargin = args.length ();

  if (nargin < 11 )
    print_usage ();
  else
  {
        // Input parameter checks
        if (any_bad_argument(args))
          return octave_value_list();

        // Input parameter
        double T            = args(0).double_value ();  // Timefactor until maturity
        double N_tmp        = args(1).double_value ();  // number of timesteps
        double alpha        = args(2).double_value ();  // mean reversion parameter
        NDArray sigma_vec   = args(3).array_value ();   // volatility of IR
        NDArray cf_dates    = args(4).array_value ();
        Matrix cf_matrix    = args(5).matrix_value ();
        Matrix R_matrix     = args(6).matrix_value ();
        NDArray dt          = args(7).array_value ();
        NDArray Timevec     = args(8).array_value ();
        double notional     = args(9).double_value ();
        int MatIndex        = args(10).int_value();     // Index of Option Maturity
        double K            = args(11).double_value();  // Strike
        bool american       = args(12).bool_value();    // American option
        
        // total number of scenarios:
        int len_sigma = sigma_vec.length ();
        int len_rate  = R_matrix.rows ();
        int len;
        if ( len_sigma > len_rate )
            len = len_sigma;
        else
            len = len_rate;
        
        int cols_R_matrix = R_matrix.cols();
        int cols_cf_matrix = cf_matrix.cols();
        
        // initialize scenario dependent output:
        dim_vector dim_scen (len, 1);
        NDArray PutVec (dim_scen);
        NDArray CallVec (dim_scen);
        for (octave_idx_type ii = 0; ii < len; ii++) 
        {
            PutVec(ii) = 0.0;
            CallVec(ii) = 0.0;
        }
        // std::cout << "Looping via scen:" << len << "\n";  

        // scenario independent parameters
        // Hull White tree parameters
            double step = T/N_tmp;
        // Threshold (M), jMax, and state vector (x)
            // limit alpha and therefore jMax
            double M = -std::max(alpha,0.0002)*step;
            double jMax_tmp = ceil(-0.1835/M);
            int N = static_cast<int>(N_tmp);
            int jMax = static_cast<int>(jMax_tmp);
        // Build the HW probability trees for pu, pm, and pd.
            // set new argument list
            octave_value_list newargs_hwprob;
            newargs_hwprob(0) = jMax;
            newargs_hwprob(1) = N;
            newargs_hwprob(2) = M;
            octave_value_list retval_hwprobs;
            retval_hwprobs = build_hw_probabilities(newargs_hwprob);
            Matrix pu = retval_hwprobs(0).matrix_value ();
            Matrix pm = retval_hwprobs(1).matrix_value ();
            Matrix pd = retval_hwprobs(2).matrix_value ();
            
            // variables for storing trees for first scenario
            Matrix r_first;
            Matrix Q_first;
            Matrix B_first;
            
        // loop via all scenarios
        for (octave_idx_type ii = 0; ii < len; ii++) 
        {
            // scenario dependent input:
            // sigma
            double sigma = sigma_vec(ii);
            
            // Rates R
            dim_vector dim_cols_R (1, cols_R_matrix);
            NDArray R (dim_cols_R);
            for (octave_idx_type zz = 0; zz < cols_R_matrix; zz++) 
            {
                R(zz) = R_matrix(ii,zz);
            }
            // cf_values
            dim_vector dim_cols_cf (1, cols_cf_matrix);
            NDArray cf_values (dim_cols_cf);
            for (octave_idx_type zz = 0; zz < cols_cf_matrix; zz++) 
            {
                cf_values(zz) = cf_matrix(ii,zz);
            }                
            // scenario dependent Hull White tree parameters
            double dr = sigma*sqrt(3*step);
            double dx = dr;

            // x = dr.*[jMax:-1:-jMax];
            dim_vector dim_x (2*jMax+1, 1);
            NDArray x (dim_x);
            octave_idx_type kk = 0;
            for (octave_idx_type mm = jMax; mm >= -jMax; mm--) {
                x(kk) = dr * mm;
                kk++;
            }
            
            // Set Discount Factor vector
            dim_vector dim_P (R.length(), 1);
            NDArray P (dim_P);
            for (octave_idx_type pp = 0; pp < P.length(); pp++) {
                P(pp) = std::exp(-R(pp) * Timevec(pp));
            }

            // Build Hull-White Tree
            octave_value_list newargs_hwtree;
            newargs_hwtree(0) = R;
            newargs_hwtree(1) = P;
            newargs_hwtree(2) = jMax;
            newargs_hwtree(3) = N;
            newargs_hwtree(4) = x;
            newargs_hwtree(5) = dx;
            newargs_hwtree(6) = dt;
            newargs_hwtree(7) = pu;
            newargs_hwtree(8) = pm;
            newargs_hwtree(9) = pd;
            octave_value_list retval_hwtree;
            //  [r d Q] = build_hw_tree(R,P,jMax,N,x,dx,dt,pu,pm,pd);
            retval_hwtree = build_hw_tree(newargs_hwtree);
            Matrix r = retval_hwtree(0).matrix_value ();
            Matrix d = retval_hwtree(1).matrix_value ();
            Matrix Q = retval_hwtree(2).matrix_value ();
        
            // Get Bond prices
            octave_value_list newargs_buildB;
            newargs_buildB(0) = cf_values;
            newargs_buildB(1) = jMax;
            newargs_buildB(2) = N;
            newargs_buildB(3) = d;
            newargs_buildB(4) = pu;
            newargs_buildB(5) = pm;
            newargs_buildB(6) = pd;
            newargs_buildB(7) = notional;
            octave_value_list retval_buildB;
            retval_buildB = get_bond_price(newargs_buildB);
            Matrix B = retval_buildB(0).matrix_value ();
    
            if (american == true)
            {
                 // Get American Option Prices
                octave_value_list newargs_AmOpt;
                newargs_AmOpt(0) = K; 
                newargs_AmOpt(1) = B;
                newargs_AmOpt(2) = jMax;
                newargs_AmOpt(3) = MatIndex;
                newargs_AmOpt(4) = d;  
                newargs_AmOpt(5) = pu;
                newargs_AmOpt(6) = pm;
                newargs_AmOpt(7) = pd;
                octave_value_list retval_AmOpt;
                retval_AmOpt  = get_american_option_price(newargs_AmOpt);
                PutVec(ii)  = retval_AmOpt(0).double_value ();
                CallVec(ii) = retval_AmOpt(1).double_value ();
            } else {
                // Get European Option payoffs and prices
                double Put = 0.0;
                double Call = 0.0;
                dim_vector dcf (2*jMax+1,1);
                NDArray Payoff_Put (dcf);
                NDArray Payoff_Call (dcf);

                // Payoff Put is max(K - B(:,OptionMaturity+1)
                for (octave_idx_type mm = 0; mm < 2*jMax+1; mm++) {
                    double tmp_diff = K - B(mm,MatIndex);
                    Payoff_Put(mm) = std::max(tmp_diff , 0.0);
                }
                
                // Payoff Call is max(K - B(:,OptionMaturity+1)
                for (octave_idx_type mm = 0; mm < 2*jMax+1; mm++) {
                    double tmp_diff = B(mm,MatIndex) - K;
                    Payoff_Call(mm) = std::max(tmp_diff , 0.0);
                }
                
                // Option Price is the payoff times the Arrow Debreu prices
                for (octave_idx_type mm = 0; mm < 2*jMax+1; mm++) {
                    Call += Q(mm,MatIndex) * Payoff_Call(mm);
                    Put  += Q(mm,MatIndex) * Payoff_Put(mm);
                }
                // store scenario value in return Array
                PutVec(ii) = Put;
                CallVec(ii) = Call;
            }

            // store trees for first scenario only
            if ( ii == 0 ) 
            {
                r_first = r;
                Q_first = Q;
                B_first = B;
            }
            
        } // scenario loop finished
        
        // return European Put and Call prices
        octave_value_list option_outargs;
        option_outargs(0) = PutVec;
        option_outargs(1) = CallVec;
        option_outargs(2) = B_first;
        option_outargs(3) = pu;
        option_outargs(4) = pm;
        option_outargs(5) = pd;
        option_outargs(6) = r_first;
        option_outargs(7) = Q_first;
        
       return octave_value (option_outargs);
    }
  return retval;
} // end of DEFUN_DLD

// static function for calculating American Option Prices
octave_value_list get_american_option_price(const octave_value_list& args)
{
    // get input parameter
    double K        = args(0).double_value ();   
    Matrix B        = args(1).matrix_value ();  
    int jMax        = args(2).int_value ();
    int MatIndex    = args(3).int_value (); 
    Matrix d        = args(4).matrix_value ();  
    Matrix pu       = args(5).matrix_value ();
    Matrix pm       = args(6).matrix_value ();
    Matrix pd       = args(7).matrix_value ();
    
    // Initialize the American puts and call trees
    dim_vector dv (2*jMax+1,MatIndex+1);  // span Matrix
    Matrix AP (dv);
    Matrix AC (dv);
    for (octave_idx_type mm = 0; mm < 2*jMax+1; mm++) {
         for (octave_idx_type nn = 0; nn < MatIndex+1; nn++) {
            AP (mm,nn) = 0.0;
            AC (mm,nn) = 0.0;
         }
    }  

    // Intrinsic value at maturity
    for (octave_idx_type mm = 0; mm < 2*jMax+1; mm++) {
        AP(mm,MatIndex) = std::max(K-B(mm,MatIndex),0.0);
        AC(mm,MatIndex) = std::max(B(mm,MatIndex)-K,0.0);
    }
    
    Matrix EP = AP; 
    Matrix EC = AC;

    // Work backwards through the tree
    for (octave_idx_type j=MatIndex; j >= 1; j--) {
        if (j>jMax) {
            for (octave_idx_type i=1; i <= 2*jMax+1; i++) {
                if (i==1) {             // first row.
                    EP(i-1,j-1) = d(i-1,j-1)*(EP(i-1,j)*pu(i-1,j-1) + EP(i,j)*pm(i-1,j-1) + EP(i+1,j)*pd(i-1,j-1));
                    EC(i-1,j-1) = d(i-1,j-1)*(EC(i-1,j)*pu(i-1,j-1) + EC(i,j)*pm(i-1,j-1) + EC(i+1,j)*pd(i-1,j-1));
                } else if (i==2*jMax+1) { // last row.
                    EP(i-1,j-1) = d(i-1,j-1)*(EP(i-1,j)*pd(i-1,j-1) + EP(i-2,j)*pm(i-1,j-1) + EP(i-3,j)*pu(i-1,j-1));
                    EC(i-1,j-1) = d(i-1,j-1)*(EC(i-1,j)*pd(i-1,j-1) + EC(i-2,j)*pm(i-1,j-1) + EC(i-3,j)*pu(i-1,j-1));
                } else {
                    EP(i-1,j-1) = d(i-1,j-1)*(EP(i-2,j)*pu(i-1,j-1) + EP(i-1,j)*pm(i-1,j-1) + EP(i,j)*pd(i-1,j-1));
                    EC(i-1,j-1) = d(i-1,j-1)*(EC(i-2,j)*pu(i-1,j-1) + EC(i-1,j)*pm(i-1,j-1) + EC(i,j)*pd(i-1,j-1));
                }
                AP(i-1,j-1) = std::max(EP(i-1,j-1), K - B(i-1,j-1));
                AC(i-1,j-1) = std::max(EC(i-1,j-1), B(i-1,j-1) - K);
            }
        } else { // Tip of the tree
            for (octave_idx_type i=jMax-(j-2); i <= jMax+j; i++) {
                EP(i-1,j-1) = d(i-1,j-1)*(EP(i-2,j)*pu(i-1,j-1) + EP(i-1,j)*pm(i-1,j-1) + EP(i,j)*pd(i-1,j-1));
                AP(i-1,j-1) = std::max(EP(i-1,j-1), K - B(i-1,j-1));
                EC(i-1,j-1) = d(i-1,j-1)*(EC(i-2,j)*pu(i-1,j-1) + EC(i-1,j)*pm(i-1,j-1) + EC(i,j)*pd(i-1,j-1));
                AC(i-1,j-1) = std::max(EC(i-1,j-1), B(i-1,j-1)-K);
            }
        } 
    }
    
    // return American Option Prices
    octave_value_list outargs;
    outargs(0) = AP(jMax,0);
    outargs(1) = AC(jMax,0);
    return outargs;      
}


// static function for building HW Tree
octave_value_list get_bond_price(const octave_value_list& args) 
{
// get input parameter
    NDArray cf_values    = args(0).array_value ();               
    int jMax        = args(1).int_value ();
    int N           = args(2).int_value (); 
    Matrix d        = args(3).matrix_value ();  
    Matrix pu       = args(4).matrix_value ();
    Matrix pm       = args(5).matrix_value ();
    Matrix pd       = args(6).matrix_value ();
    double notional = args(7).double_value ();
    // Initialize the discount bond matrix B
    dim_vector dv (2*jMax+1,N+1);  // span Matrix
    Matrix B (dv);
    for (octave_idx_type mm = 0; mm < 2*jMax+1; mm++) {
         for (octave_idx_type nn = 0; nn < N+1; nn++) {
            B (mm,nn) = 0.0;
         }
    }

    // Last column of discount bond are final bond payments.
    for (octave_idx_type mm = 0; mm < 2*jMax+1; mm++) {
        B(mm,N) = cf_values(N-1);
    }

    //cf_values(end) = cf_values(end) .- notional;
    dim_vector dcf (N+1,1);
    NDArray cf_values_B (dcf);
    cf_values_B(0) = 0.0;
    for (octave_idx_type nn = 0; nn < N; nn++) {
        cf_values_B(nn+1) = cf_values(nn);
    }
    // get interest cash flows only
    cf_values_B(N) = cf_values_B(N) - notional;
    
    // Work backwards through tree to get remaining discount bond prices
    for (octave_idx_type j=N; j >= 1; j--) {
        if (j>jMax) {
            for (octave_idx_type i=1; i <= 2*jMax+1; i++) {
                if (i==1) {             // first row.
                    B(i-1,j-1) = d(i-1,j-1)*(B(i-1,j)*pu(i-1,j-1) + B(i,j)*pm(i-1,j-1) + B(i+1,j)*pd(i-1,j-1));
                } else if (i==2*jMax+1) { // last row.
                    B(i-1,j-1) = d(i-1,j-1)*(B(i-1,j)*pd(i-1,j-1) + B(i-2,j)*pm(i-1,j-1) + B(i-3,j)*pu(i-1,j-1));
                } else {
                    B(i-1,j-1) = d(i-1,j-1)*(B(i-2,j)*pu(i-1,j-1) + B(i-1,j)*pm(i-1,j-1) + B(i,j)*pd(i-1,j-1));
                }
                // add cash flow values at cash flow date == tree date:
                B(i-1,j-1) = B(i-1,j-1) + cf_values_B(j-1);
            }
        } else {
            for (octave_idx_type i=jMax-(j-2); i <= jMax+j; i++) {
                B(i-1,j-1) = d(i-1,j-1)*(B(i-2,j)*pu(i-1,j-1) + B(i-1,j)*pm(i-1,j-1) + B(i,j)*pd(i-1,j-1));
                // add cash flow values at cash flow date == tree date:
                B(i-1,j-1) = B(i-1,j-1) + cf_values_B(j-1);
            }
        } 
    }
    // return tree
    octave_value_list outargs;
    outargs(0) = B;
    outargs(1) = cf_values_B;
    return outargs;      
}


// static function for building HW Tree
octave_value_list build_hw_tree(const octave_value_list& args) 
{
    // get input parameter
    NDArray Rate    = args(0).array_value (); 
    NDArray P       = args(1).array_value ();                
    int jMax        = args(2).int_value ();
    int N           = args(3).int_value (); 
    NDArray x       = args(4).array_value (); 
    double dx       = args(5).double_value (); 
    NDArray dt      = args(6).array_value ();  
    Matrix pu       = args(7).matrix_value ();
    Matrix pm       = args(8).matrix_value ();
    Matrix pd       = args(9).matrix_value ();
    
    // Initialize the required matrices.
    dim_vector dv (2*jMax+1,N+1);  // span Matrix
    Matrix r (dv);
    Matrix d (dv);
    Matrix Q (dv);
    for (octave_idx_type mm = 0; mm < 2*jMax+1; mm++) {
         for (octave_idx_type nn = 0; nn < N+1; nn++) {
            r (mm,nn) = 0.0;
            d (mm,nn) = 0.0;
            Q (mm,nn) = 0.0;
         }
    }
    // Vector of "J" indices runinng from jMax down to -jMax.
    dim_vector vecdim (2*jMax+1,1); 
    NDArray J (vecdim);
    octave_idx_type kk = 0;
    for (int ll=jMax; ll>=-jMax; ll-- ) 
    { 
        J(kk) = static_cast<double>(ll);
        kk++;
    }
    
    dim_vector vecdim_R (Rate.length(),1);
    NDArray a (vecdim_R);
    NDArray S (vecdim_R);
    for (octave_idx_type nn = 0; nn < S.length(); nn++) {
        S(nn) = 0.0;
        //std::cout << "S(" << nn << ") = " << S(nn) << "\n";
    }
    for (octave_idx_type nn = 0; nn < a.length(); nn++) {
        a(nn) = 0.0;
        //std::cout << "a(" << nn << ") = " << a(nn) << "\n";
    }

    // build tree
    // First Arrow-Debreu price
    Q(jMax+1,1) = 1;

    //  Build the interest rate tree.  Calculate separately:
    //    - the first node (Column 1)
    //    - the "tip" of the tree (Columns 2 through jMax +1)
    //    - the "box" of the tree (Columns Jmax+2 through N)
    for (octave_idx_type j=1;j<=N+1;j++) {
        if (j==1) {
            // First node: column 1
            Q(jMax,0) = 1;
            d(jMax,0) = exp(-Rate(0)*dt(j-1));
            a(0) = -log(P(0))/dt(j-1);
            S(0) = Q(jMax,0) *exp(-x(jMax)*dx*dt(j-1));
            r(jMax,0) = x(jMax) + a(0);
        } else if (j<=jMax+1) {
            // Tip of the tree: columns 2 through jMax+1
            for (octave_idx_type i=jMax-(j-2);i<=jMax+j;i++) {
                if (i==jMax-(j-2)) {       // First row
                    Q(i-1,j-1) = Q(i,j-2)*pu(i,j-2)*d(i,j-2);
                } else if (i==jMax-(j-2)+1) {  // Second row
                    Q(i-1,j-1) = Q(i-1,j-2)*pm(i-1,j-2)*d(i-1,j-2) + Q(i,j-2)*pu(i,j-2)*d(i,j-2);
                } else if (i==jMax+j) {        //Last row
                    Q(i-1,j-1) = Q(i-2,j-2)*pd(i-2,j-2)*d(i-2,j-2);
                } else if (i==jMax+j-1) {       // Second to last row
                    Q(i-1,j-1) = Q(i-1,j-2)*pm(i-1,j-2)*d(i-1,j-2) + Q(i-2,j-2)*pd(i-2,j-2)*d(i-2,j-2);
                } else {                   // Middle rows
                    Q(i-1,j-1) = Q(i-2,j-2)*pd(i-2,j-2)*d(i-2,j-2) + Q(i-1,j-2)*pm(i-1,j-2)*d(i-1,j-2) + Q(i,j-2)*pu(i,j-2)*d(i,j-2);
                }
                S(j-1) = 0;
                for (octave_idx_type k=jMax-(j-2);k<=jMax+j;k++) {
                    S(j-1) = S(j-1) + Q(k-1,j-1)*exp(-J(k-1)*dx*dt(j-1));
                }
                a(j-1) = (log(S(j-1)) - log(P(j-1)))/dt(j-1);
                for (octave_idx_type k=jMax-(j-2);k<=jMax+j;k++) {
                    r(k-1,j-1) = x(k-1) + a(j-1);
                    d(k-1,j-1) = exp(-r(k-1,j-1)*dt(j-1));
                }
            }
        } else {
            // Box of the tree: columns jMax+2 through N
            for (octave_idx_type i=1;i<=2*jMax+1;i++) {
                if (i==1) {            // First row
                    Q(i-1,j-1) = Q(i-1,j-2)*pu(i-1,j-2)*d(i-1,j-2) + Q(i,j-2)*pu(i,j-2)*d(i,j-2);
                } else if (i==2) {        // Second row
                    Q(i-1,j-1) = Q(i-2,j-2)*pm(i-2,j-2)*d(i-2,j-2) + Q(i-1,j-2)*pm(i-1,j-2)*d(i-1,j-2) + Q(i,j-2)*pu(i,j-2)*d(i,j-2);
                } else if (i==3) {        // Third row
                    if (jMax==2) {     // Special case of third row when jMax=2
                        Q(i-1,j-1) = Q(i-3,j-2)*pd(i-3,j-2)*d(i-3,j-2) + Q(i-2,j-2)*pd(i-2,j-2)*d(i-2,j-2) + Q(i-1,j-2)*pm(i-1,j-2)*d(i-1,j-2) + Q(i,j-2)*pu(i,j-2)*d(i,j-2) + Q(i+2-1,j-2)*pu(i+2-1,j-2)*d(i+2-1,j-2);
                    } else {
                        Q(i-1,j-1) = Q(i-3,j-2)*pd(i-3,j-2)*d(i-3,j-2) + Q(i-2,j-2)*pd(i-2,j-2)*d(i-2,j-2) + Q(i-1,j-2)*pm(i-1,j-2)*d(i-1,j-2) + Q(i,j-2)*pu(i,j-2)*d(i,j-2);
                    }
                }  else if (i==2*jMax+1) {  // Last row
                    Q(i-1,j-1) = Q(i-1,j-2)*pd(i-1,j-2)*d(i-1,j-2) + Q(i-2,j-2)*pd(i-2,j-2)*d(i-2,j-2);
                } else if (i==2*jMax) {    // Second to last row
                    Q(i-1,j-1) = Q(i,j-2)*pm(i,j-2)*d(i,j-2) + Q(i-1,j-2)*pm(i-1,j-2)*d(i-1,j-2) + Q(i-2,j-2)*pd(i-2,j-2)*d(i-2,j-2);
                } else  {               // Middle rows
                    Q(i-1,j-1) = Q(i-2,j-2)*pd(i-2,j-2)*d(i-2,j-2) + Q(i-1,j-2)*pm(i-1,j-2)*d(i-1,j-2) + Q(i,j-2)*pu(i,j-2)*d(i,j-2);
                }
                S(j-1) = 0;
                for (octave_idx_type k=1;k<=2*jMax+1;k++) {
                    S(j-1) = S(j-1) + Q(k-1,j-1)*exp(-J(k-1)*dx*dt(j-1));
                }
                a(j-1) = (log(S(j-1)) - log(P(j-1)))/dt(j-1);
                for (octave_idx_type k=1;k<=2*jMax+1;k++) {
                    r(k-1,j-1) = x(k-1) + a(j-1);
                    d(k-1,j-1) = exp(-r(k-1,j-1)*dt(j-1));
                }
            }
        }
    }

    
    // return tree
    octave_value_list outargs;
    outargs(0) = r;
    outargs(1) = d;
    outargs(2) = Q;
      
    return outargs;      
}


// static function for calculation of HW probabilities
octave_value_list build_hw_probabilities(const octave_value_list& args) 
{
    // get input parameter
    int jMax = args(0).int_value ();
    int N    = args(1).int_value ();
    double M    = args(2).double_value ();

    // define new parameter
    dim_vector dv (2*jMax+1,N+1);  // span Matrix
    Matrix pu (dv);
    Matrix pm (dv);
    Matrix pd (dv);
    for (octave_idx_type mm = 0; mm < 2*jMax+1; mm++) {
         for (octave_idx_type nn = 0; nn < N+1; nn++) {
            pu (mm,nn) = 0.0;
            pm (mm,nn) = 0.0;
            pd (mm,nn) = 0.0;
         }
    }

    dim_vector vecdim (2*jMax+1,1); 
    NDArray J (vecdim);
    octave_idx_type kk = 0;
    for (int ll=jMax; ll>=-jMax; ll-- ) 
    { 
        J(kk) = ll;
        kk++;
    }

    // calculate probabilities
    for (int j=1; j<=N+1; j++ ) 
    {
        if (j<=jMax) {
            // Tip of the tree.
            for (int i=jMax+2-j; i<=jMax+j; i++ ) 
            {
                pu(i-1,j-1) = (1.0/6.0) + (J(i-1)*J(i-1)*M*M + J(i-1)*M)/2.0;
                pm(i-1,j-1) = (2.0/3.0) -  (J(i-1)*J(i-1)*M*M);
                pd(i-1,j-1) = (1.0/6.0) + (J(i-1)*J(i-1)*M*M - J(i-1)*M)/2.0;
            }
        } else {
            // Remaining nodes.
            for (int i= 1 ; i<=2*jMax+1; i++ ) 
            {
                if (i==1) {
                    pu(i-1,j-1) =  7.0/6 + (J(i-1)*J(i-1)*M*M + 3*J(i-1)*M)/2.0;
                    pm(i-1,j-1) = -1.0/3 -  J(i-1)*J(i-1)*M*M - 2*J(i-1)*M;
                    pd(i-1,j-1) =  1.0/6 + (J(i-1)*J(i-1)*M*M + J(i-1)*M)/2.0;
                } else if (i==2*jMax+1) {
                    pu(i-1,j-1) =  1.0/6 + (J(i-1)*J(i-1)*M*M - J(i-1)*M)/2.0;
                    pm(i-1,j-1) = -1.0/3 -  J(i-1)*J(i-1)*M*M + 2*J(i-1)*M;
                    pd(i-1,j-1) =  7.0/6 + (J(i-1)*J(i-1)*M*M - 3*J(i-1)*M)/2.0;
                } else {
                    pu(i-1,j-1) = 1.0/6.0 + (J(i-1)*J(i-1)*M*M + J(i-1)*M)/2.0;
                    pm(i-1,j-1) = 2.0/3.0 -  J(i-1)*J(i-1)*M*M;
                    pd(i-1,j-1) = 1.0/6.0 + (J(i-1)*J(i-1)*M*M - J(i-1)*M)/2.0;
                }
            }
        }
    }
    
    // return probabilities
    octave_value_list outargs;
    outargs(0) = pu;
    outargs(1) = pm;
    outargs(2) = pd;
      
    return outargs;      
}

// static function for input parameter checks
bool any_bad_argument(const octave_value_list& args)
{
    // octave_value_list:
    // T,N,alpha,sigma_vec,cf_dates,cf_matrix,R_matrix,dt,Timevec,notional,Mat,K
    
    if (!args(10).is_numeric_type())
    {
        error("pricing_callable_bond_cpp: expecting K to be a numeric");
        return true;
    }
    
    if (!args(9).is_numeric_type())
    {
        error("pricing_callable_bond_cpp: expecting Mat to be a scalar");
        return true;
    }
    
    if (!args(8).is_numeric_type())
    {
        error("pricing_callable_bond_cpp: expecting notional to be a numeric");
        return true;
    }
    
    if (!args(7).is_numeric_type())
    {
        error("pricing_callable_bond_cpp: expecting Timevec to be a numeric");
        return true;
    }
    
    if (!args(6).is_numeric_type())
    {
        error("pricing_callable_bond_cpp: expecting dt to be a numeric");
        return true;
    }
    
    if (!args(5).is_numeric_type())
    {
        error("pricing_callable_bond_cpp: expecting cf_matrix to be a numeric");
        return true;
    }
    
    if (!args(4).is_numeric_type())
    {
        error("pricing_callable_bond_cpp: expecting cf_dates to be a numeric");
        return true;
    }
    
    if (!args(0).is_numeric_type())
    {
        error("pricing_callable_bond_cpp: expecting T to be a numeric");
        return true;
    }

    if (!args(1).is_numeric_type())
    {
        error("pricing_callable_bond_cpp: expecting N to be a numeric");
        return true;
    }

    if (!args(2).is_numeric_type())
    {
        error("pricing_callable_bond_cpp: expecting alpha to be a numeric");
        return true;
    }

    if (!args(3).is_numeric_type ())
    {
        error("pricing_callable_bond_cpp: expecting sigma to be a numeric");
        return true;
    }
    
    return false;
}
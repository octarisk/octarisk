%# Copyright (C) 2018 Stefan Schloegl <schinzilord@octarisk.com>
%#
%# This program is free software; you can redistribute it and/or modify it under
%# the terms of the GNU General Public License as published by the Free Software
%# Foundation; either version 3 of the License, or (at your option) any later
%# version.
%#
%# This program is distributed in the hope that it will be useful, but WITHOUT
%# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
%# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
%# details.

%# -*- texinfo -*-
%# @deftypefn {Function File} { [@var{newdatenum} @var{newdatevec}] =} addtodatefinancial(@var{valdate}, @var{arg1}, @var{arg2}, @var{arg3})
%# Add or subtract given years, months or days to a given input date. 
%# End of month of input date will be preserved if no days are added.
%# Both datenum and datevec format are returned.
%# Explicit specification of years, months, days:
%# @itemize @bullet
%# @item @var{valdate}: start date for date manipulation
%# @item @var{arg1}: years to add or subtract
%# @item @var{arg2}: months to add or subtract (optional)
%# @item @var{arg3}: days to add or subtract (optional)
%# @end itemize
%# Implicit specification of value and unit:
%# @itemize @bullet
%# @item @var{valdate}: start date for date manipulation
%# @item @var{arg1}: value to add or subtract
%# @item @var{arg2}: unit (days, months, years)
%# @end itemize
%# Single date input possible only. Example call:
%# @example
%# @group
%# [newdatenum newdatevec] = addtodatefinancial('31-Mar-2016', 1, 'years')
%# newdatenum =  736785
%# newdatevec = [2017 3 31]
%# [newdatenum newdatevec] = addtodatefinancial('31-Mar-2016', -1, -6, -4)
%# newdatenum =  735869
%# newdatevec = [2014 9 27]
%# @end group
%# @end example
%# @seealso{addtodate}
%# @end deftypefn

function [newdatenum newdatevec] = addtodatefinancial(valdate, arg1, arg2, arg3)

% input checks
if (iscell(valdate) || rows(valdate) > 1)
	fprintf('addtodatefinancial: Input has to be a single date in datenum or datevec format.\n');
	print_usage();
end

if nargin < 2
	print_usage();
end

if nargin == 2
	yy_diff = arg1;
	mm_diff = 0;
	dd_diff = 0;
elseif nargin == 3
	if ischar(arg2)	% special case:arg1 is value, arg2 is unit
		if strcmpi(arg2,"months") || strcmpi(arg2,"month")
			dd_diff = 0;
			mm_diff = arg1;
			yy_diff = 0;
		elseif strcmpi(arg2,"days") || strcmpi(arg2,"day")
			dd_diff = arg1;
			mm_diff = 0;
			yy_diff = 0;
		elseif strcmpi(arg2,"years") || strcmpi(arg2,"year")
			dd_diff = 0;
			mm_diff = 0;
			yy_diff = arg1;
		else
			error('addtodatefinancial: unknown unit >>%s<<. Must be days,months,years.',any2str(arg2));
		end
	else
		yy_diff = arg1;
		mm_diff = arg2;
		dd_diff = 0;
	end
elseif nargin == 4
	yy_diff = arg1;
	mm_diff = arg2;
	dd_diff = arg3;
end

% convert input date
if ischar(valdate)				% datestr format
	[y_val m_val d_val] = datevec_fast(valdate);
	valdatenum = datenum_fast(valdate,1);
elseif (length(valdate) >= 3)	% datevec format
	y_val 	= valdate(:,1);
	m_val 	= valdate(:,2);
	d_val 	= valdate(:,3);
	valdatenum = datenum(valdate);
else							% datenum format
	[y_val m_val d_val] = datevec_fast(valdate);
	valdatenum = valdate;
end

% short cut if only days are added or subtracted:
if ( dd_diff != 0 && mm_diff == 0 && yy_diff == 0)
	newdatenum = valdatenum + dd_diff;
	newdatevec = datevec(newdatenum);
	break;
end
			
% check if valdate is end of month
eom_flag = false;
if (valdatenum == eomdate(y_val,m_val) && dd_diff == 0)
	eom_flag = true;
end

% subtract or add days
if (dd_diff != 0)
	[y_val m_val d_val] = datevec_fast(valdatenum + dd_diff);
end

% prevent roll over, if abs(mm_diff) > 12
if ( abs(mm_diff) > 12 )
	yy_diff += (floor ((abs(mm_diff)-1)/12) * sign(mm_diff));
	mm_diff =( mod (abs(mm_diff)-1, 12) + 1) * sign(mm_diff);
end
% case 1: negative month difference
if ( mm_diff < 0 && -mm_diff >= m_val )	% lag into last year
	yy_diff -= 1;
	mm_diff = mod (m_val + mm_diff - 1, 12) + 1- m_val;
% case 2: positive month difference
elseif ( mm_diff > 0 && mm_diff >= (12 - m_val)) 
	yy_diff += 1;
	mm_diff = mod (m_val + mm_diff - 1, 12) + 1 - m_val;
end    

% final subtracting or adding of years, months, days
if ( eom_flag == true)
	newdatenum = eomdate(y_val + yy_diff, m_val + mm_diff);
	[y_val m_val d_val] = datevec_fast(newdatenum);
	newdatevec = [y_val m_val d_val, 0,0,0];
else
	newdatevec = [y_val + yy_diff, m_val + mm_diff,d_val, 0,0,0];
end
% adjust for leap year
if (  (!is_leap_year(newdatevec(1))) && newdatevec(2) == 2 && newdatevec(3) > 28)
	newdatevec(3) = 28;
end

newdatenum = datenum(newdatevec);
end
% ------------------------------------------------------------------------------


%-------------------------------------------------------------------------------
%            Custom datenum and datevec Functions 
%-------------------------------------------------------------------------------
% Octave's built in functions have been cleaned from unused code. Now only
% date format 'dd-mmm-yyyy' is allowed to improve performance
function [day] = datenum_fast (input1, format = 1)

  ## Days until start of month assuming year starts March 1.
  persistent monthstart = [306; 337; 0; 31; 61; 92; 122; 153; 184; 214; 245; 275];
  persistent monthlength = [31; 28; 31; 30; 31; 30; 31; 31; 30; 31; 30; 31];


  if (ischar (input1) || iscellstr (input1)) % input is 
    [year, month, day, hour, minute, second] = datevec_fast (input1, 1);
  else	% input is vector
      second = 0;
      minute = 0;
      hour   = 0;
      day   = input1(:,3);
      month = input1(:,2);
      year  = input1(:,1);
  end

  month(month < 1) = 1;  # For compatibility.  Otherwise allow negative months.

  % no fractional month possible

  % Set start of year to March by moving Jan. and Feb. to previous year.
  % Correct for months > 12 by moving to subsequent years.
  year += ceil ((month-14)/12);

  % Lookup number of days since start of the current year.
    day += monthstart (mod (month-1,12) + 1) + 60;

  % Add number of days to the start of the current year.  Correct
  % for leap year every 4 years except centuries not divisible by 400.
  day += 365*year + floor (year/4) - floor (year/100) + floor (year/400);

end

function [y, m, d, h, mi, s] = datevec_fast (date, f = 1, p = [])

  if (nargin < 1 || nargin > 3)
    print_usage ();
  end

  if (ischar (date))
    date = cellstr (date);
  end

  if (isnumeric (f))
    p = f;
    f = [];
  end

  if (isempty (f))
    f = -1;
  end

  if (isempty (p))
    p = (localtime (time ())).year + 1900 - 50;
  end

  % datestring input
  if (iscell (date))

    nd = numel (date);

    y = m = d = h = mi = s = zeros (nd, 1);
	% hard coded: format string always dd-mm-yyyy
	f = '%d-%b-%Y';
	rY = 7;
	ry = 0;
	fy = 1;
	fm = 1;
	fd = 1;
	fh = 0;
	fmi = 0;
	fs = 0;
	found = 1;

	for k = 1:nd
		[found y(k) m(k) d(k) h(k) mi(k) s(k)] = ...
			__date_str2vec_custom__ (date{k}, p, f, rY, ry, fy, fm, fd, fh, fmi, fs);
	end

  % datenum input
  else 
    date = date(:);

    % Move day 0 from midnight -0001-12-31 to midnight 0000-3-1
    z = double (floor (date) - 60);
    % Calculate number of centuries; K1 = 0.25 is to avoid rounding problems.
    a = floor ((z - 0.25) / 36524.25);
    % Days within century; K2 = 0.25 is to avoid rounding problems.
    b = z - 0.25 + a - floor (a / 4);
    % Calculate the year (year starts on March 1).
    y = floor (b / 365.25);
    % Calculate day in year.
    c = fix (b - floor (365.25 * y)) + 1;
    % Calculate month in year.
    m = fix ((5 * c + 456) / 153);
    d = c - fix ((153 * m - 457) / 5);
    % Move to Jan 1 as start of year.
    ++y(m > 12);
    m(m > 12) -= 12;

    % no fractional time units
	s = 0;
	h = 0;
	mi = 0;
	

  end

  if (isvector(date) && length(date) > 1)
	if ( rows(date) > columns(date))
		date = date';
	end
	y = date(:,1);
	m = date(:,2);
	d = date(:,3);
	h = date(:,4);
	mi = date(:,5);
	s = date(:,6);
  end
  
  
  if (nargout <= 1)
    y = [y, m, d, h, mi, s];
  end

end
% ------------------------------------------------------------------------------
function [found, y, m, d, h, mi, s] = __date_str2vec_custom__ (ds, p, f, rY, ry, fy, fm, fd, fh, fmi, fs)

  % strptime will always be possible
  [tm, nc] = strptime (ds, f);

  if (nc == columns (ds) + 1)
    found = true;
    y = tm.year + 1900; m = tm.mon + 1; d = tm.mday;
    h = 0; mi = 0; s = 0;
  else
    y = m = d = h = mi = s = 0;
    found = false;
  end

end

%!test
%! valuation_date = '31-May-2017';
%! [newdatenum newdatevec] = addtodatefinancial(datenum(valuation_date), 0, 10, -5);
%! assert(newdatevec,[2018 03 26])
%! valuation_date = '30-Apr-2017';
%! [newdatenum newdatevec] = addtodatefinancial(datenum(valuation_date), 0, 10, 0);
%! assert(newdatevec,[2018 02 28])
%! [newdatenum newdatevec] = addtodatefinancial(datenum(valuation_date), 1, 0, 0);
%! assert(newdatevec,[2018 04 30])
%! [newdatenum newdatevec] = addtodatefinancial(datenum(valuation_date), 1, 'years');
%! assert(newdatevec,[2018 04 30])
%! [newdatenum newdatevec] = addtodatefinancial(datenum(valuation_date), 1, 0, 6);
%! assert(newdatevec,[2018 05 06])
%! [newdatenum newdatevec] = addtodatefinancial(datenum(valuation_date), -1, 0, 6);
%! assert(newdatevec,[2016 05 06])
%! valuation_date = '29-Dec-2017';
%! [newdatenum newdatevec] = addtodatefinancial(datenum(valuation_date), 0, 5, 0);
%! assert(newdatevec,[2018 05 29])
%! [newdatenum newdatevec] = addtodatefinancial(datenum(valuation_date), 0, 13, 0);
%! assert(newdatevec,[2019 01 29])
%! [newdatenum newdatevec] = addtodatefinancial(datevec(valuation_date), 0, 14, 0);
%! assert(newdatevec,[2019 02 28])
%! [newdatenum newdatevec] = addtodatefinancial(datenum(valuation_date), 1, 14, 0);
%! assert(newdatevec,[2020 02 29])
%! [newdatenum newdatevec] = addtodatefinancial(valuation_date, 0, -5, 0);
%! assert(newdatevec,[2017 07 29])
%! [newdatenum newdatevec] = addtodatefinancial(valuation_date, 0, -15, 0);
%! assert(newdatevec,[2016 09 29])
%! [newdatenum newdatevec] = addtodatefinancial(valuation_date, -4, -15, 0);
%! assert(newdatevec,[2012 09 29])
%! [newdatenum newdatevec] = addtodatefinancial(valuation_date, 0, -12, 0);
%! assert(newdatevec,[2016 12 29])
%! valuation_date = '31-Mar-2016';
%! [newdatenum newdatevec] = addtodatefinancial(valuation_date, 0, -12, 0);
%! assert(newdatevec,[2015 03 31])
%! [newdatenum newdatevec] = addtodatefinancial(valuation_date, 0, -11, 0);
%! assert(newdatevec,[2015 04 30])
%! [newdatenum newdatevec] = addtodatefinancial(valuation_date, -11, 'months');
%! assert(newdatevec,[2015 04 30])
%! [newdatenum newdatevec] = addtodatefinancial(valuation_date, -10, 'days');
%! assert(newdatevec,[2016 03 21])
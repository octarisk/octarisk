function d = yeardays (y, basis)

  if (nargin == 1)
	basis = 0;
  elseif (nargin ~= 2)
    print_usage ();
  end

  if isscalar (y)
	d = zeros (size (basis));
  elseif isscalar (basis)
	%the rest of the code is much simpler if you can be sure that
	% basis is a matrix if y is a matrix
	basis = basis * ones (size (y));
	d = zeros (size (y));
  else
	if ndims (y) == ndims (basis)
	  if ~ all (size (y) == size (basis))
		error ('year and basis must be the same size or one must be a scalar');
	  else
		d = zeros (size (y));
	  end
	else
	  error ('year and basis must be the same size or one must be a scalar.')
	end
  end

  bact = ismember (basis(:), [0 8])
  b360 = ismember (basis(:), [1 2 4 5 6 9 11])
  b365 = ismember (basis(:), [3 7 10])

  badbasismask = ~ (bact | b360 | b365);
  if any (badbasismask)
	badbasis = unique (basis(badbasismask));
	error ('Unsupported basis: %g\n', badbasis)
  end

  d(bact) = 365 + (eomday(y(bact), 2) == 29);
  d(b360) = 360;
  d(b365) = 365;

end

%!assert(yeardays(2000), 366)
%!assert(yeardays(2001), 365)
%!assert(yeardays(2000:2004), [366 365 365 365 366])
%!assert(yeardays(2000, 0), 366)
%!assert(yeardays(2000, 1), 360)
%!assert(yeardays(2000, 2), 360)
%!assert(yeardays(2000, 3), 365)
%!assert(yeardays(2000, 4), 360)
%!assert(yeardays(2000, 5), 360)
%!assert(yeardays(2000, 6), 360)
%!assert(yeardays(2000, 7), 365)
%!assert(yeardays(2000, 8), 366)
%!assert(yeardays(2000, 9), 360)
%!assert(yeardays(2000, 10), 365)
%!assert(yeardays(2000, 11), 360)


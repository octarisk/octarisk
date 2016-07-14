function days = daysact (d1, d2)
 if (nargin == 1)
   nr = size (d1, 1);
   if (nr ~= 1)
     days = zeros (nr,1);
     for i = 1 : nr
       days (i) = datenum (d1 (i,:));
     end
   else
     days = datenum(d1);
   end
 elseif (nargin == 2)
   nr1 = size (d1, 1);
   nr2 = size (d2, 1);   
   if (nr1 ~= nr2 && nr1 ~= 1 && nr2 ~= 1)
     error ('daysact: size mismatch');
   end
   if (nr1 == 1 && nr2 == 1)
     days = datenum (d2) - datenum(d1);
   elseif (nr1 == 1)
     days = zeros (nr2, 1);
     for i = 1 : nr2
       days(i) = datenum (d2 (i,:)) - datenum (d1);
     end
   elseif (nr2 == 1)
     days = zeros (nr1, 1);
     for i = 1 : nr1
       days(i) = datenum (d2) - datenum (d1 (i,:));
     end
   else
     days = zeros (nr1, 1);
     for i = 1 : nr1
       days(i) = datenum (d2 (i, :)) - datenum (d1 (i,:));
     end
   end
 else
   print_usage();
  end
end

%~assert (daysact ('01-Jan-2007', ['10-Jan-2007'; '23-Feb-2007'; '23-Jul-2007']),[9;53;203])

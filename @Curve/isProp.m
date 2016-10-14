% Curve Class @Curve
function ret = isProp (Curve, property)
  obj = Curve;
  if (nargin == 1)
    s = obj.name;
    ret = 0;
  elseif (nargin == 2)
    if (ischar(property))
        try
            val = getfield(Curve,property);
            ret = 1;
        catch
            ret = 0;
        end
    else
        error('Please provide a property string');
    end
  else
    print_usage ();
  end
end
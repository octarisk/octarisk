% Instrument Class @Instrument
function ret = isProp (instrument, property)
  obj = instrument;
  if (nargin == 1)
    s = obj.name;
    ret = 0;
  elseif (nargin == 2)
    if (ischar(property))
        try
            val = getfield(instrument,property);
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
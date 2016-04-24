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
        end_try_catch
    else
        error('Please provide a property string');
    endif
  else
    print_usage ();
  endif
endfunction
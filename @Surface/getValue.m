% method of class @Surface
function [y value_base] = getValue (s, value_type, xx,yy,zz)
    % get interpolated market value from Surface/Cube
    if ~(ischar(value_type))
        fprintf('Surface.getValue: >>%s<< needs to be a char.\n',any2str(value_type));
        error('Correct call: Surface.getValue(value_type,xx,[yy,[zz]])');
    end
    if (nargin < 2)
        value_base = 0.0;
        xx = 0;
        yy = 0;
        zz = 0;
    elseif (nargin > 2)
        if (nargin == 3)
            value_base = s.interpolate(xx);
            yy = 0;
            zz = 0;
        elseif (nargin == 4)
            value_base = s.interpolate(xx,yy);
            zz = 0;
        elseif (nargin == 5)
            value_base = s.interpolate(xx,yy,zz);
        end
    else
        print_usage ();
    end
    % get shock value and calculate model dependent shocked base value
    if ~(strcmpi(value_type,'base'))
        shockvalue = 0.0;
        idw_weight = 0.0;
        try
            struct_out = getfield(s.shock_struct,value_type);
            % get risk factor coordinates and values from struct
            tmp_coordinates = [struct_out.coordinates];
            tmp_values = [struct_out.values];
            % get interpolation coordinate matrix
            max_len = max([length(xx);length(yy);length(zz)]);
            if ( length(xx) < max_len)
                xx = repmat(xx,max_len,1);
            end
            if ( length(yy) < max_len)
                yy = repmat(yy,max_len,1);
            end
            if ( length(zz) < max_len)
                zz = repmat(zz,max_len,1);
            end
			% distinguish between surface and cube
			if ( rows(tmp_coordinates) == 3 )
				interpoint = [xx,yy,zz];
            elseif (rows(tmp_coordinates) == 2)
				interpoint = [yy,zz];
			end
            % calculate inverse distance weighted shock
            for ii = 1:1:columns(tmp_coordinates)
                tmp_vektor = tmp_coordinates(:,ii);
                if ( rows(tmp_vektor) > columns(tmp_vektor))
                    tmp_vektor = tmp_vektor';
                end
                distance = calc_distance(interpoint,tmp_vektor,2);
                shockvalue = shockvalue +  tmp_values(:,ii) ./ distance;
                idw_weight = idw_weight + distance.^(-1);
            end
            shockvalue = shockvalue ./ idw_weight;
            % get model dependent shocked values
            if (strcmpi(value_type,'stress'))
                tmp_shift_types = [struct_out.shift_type];
                % distinguish between absolute and relative Stress shock
                % calculate relative stress shocks
                y_rel     =  (1 + shockvalue ) .* value_base;
                % calculate absolute stress shocks
                y_abs     =  shockvalue + value_base;
                % combine both shocks
                y = tmp_shift_types .* y_rel + (1 - tmp_shift_types) .* y_abs;
            else    % all MC scenarios use model information			
                y = Riskfactor.get_abs_values(struct_out.model,shockvalue,value_base);
            end
        catch
            %fprintf('surface.getValue: Object has no risk factor values for >>%s<<.  ID: >>%s<< Message: >>%s<< in line >>%d<< \n',value_type,s.id,lasterr,lasterror.stack.line);
            y = value_base;
        end
    else    % value type 'base'
        y = value_base;
    end


end

%% Helper Functions
function d = calc_distance(x,y,norm)
    % error handling
    if ( nargin < 2)
        error('calc_distance: need at least two points');
    elseif (nargin == 2)
        norm = 2;   %default case Euklidic norm
    end
    if ~isnumeric(norm)
        norm = 2;
    end
    norm = max(norm,0.001);
    if ~( columns(x) == columns(y))
        error('calc_distance: points needs to be of same y dimension');
    end
    % calculate distance
    d = (sum( abs(x .- y).^norm,2)).^(1/norm);
end
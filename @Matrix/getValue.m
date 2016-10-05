% method of class @Matrix
function y = getValue (matrix,xx,yy)
  s = matrix;
  if (nargin == 1)
    y = s.id;
  elseif (nargin == 3)      
    % #################      A) type correlation      ###################################
    if ( strcmpi(s.type,'Correlation'))
        % get matrix
        matrix = s.matrix;
        % get components of matrix
        component_cell_xx = s.components_xx;
        component_cell_yy = s.components_yy;
        len_cell_xx = length(component_cell_xx);
        len_cell_yy = length(component_cell_yy);
        % check size of matrix and component cell
        if ( len_cell_xx > columns(matrix) || len_cell_yy > rows(matrix) )
            error('Matrix.getValue: Matrix size does not match component cell.');
        end 
        if ( ischar(xx) && ischar(yy) ) % get index values from provided IDs
            
            index_cell_xx = 1:1:len_cell_xx;
            index_cell_yy = 1:1:len_cell_yy;
            % find matching index entry:
            index_xx = strcmpi(xx,component_cell_xx) * index_cell_xx';
            index_yy = strcmpi(yy,component_cell_yy) * index_cell_yy';
            if ( index_xx == 0 )
                error('Matrix.getValue: Requested Matrix component x >>%s<< not contained in component cell: >>%s<<', any2str(xx),any2str(component_cell_xx) );
            end
            if ( index_yy == 0 )
                error('Matrix.getValue: Requested Matrix component y >>%s<< not contained in component cell: >>%s<<', any2str(yy),any2str(component_cell_yy) );
            end
        elseif ( isnumeric(xx) && isnumeric(yy) ) % index values are provided
            % convert into integer
            index_xx = int32(xx);
            index_yy = int32(yy);
            if ( index_xx > columns(matrix) )
                error('Matrix.getValue: Requested Matrix index x >>%s<< exceeds number of columns: >>%s<<', any2str(xx),any2str(columns(matrix)) );
            end
            if ( index_yy > rows(matrix) )
                error('Matrix.getValue: Requested Matrix index y >>%s<< exceeds number of rows: >>%s<<', any2str(yy),any2str(columns(matrix)) );
            end
        else
            error('Matrix.getValue: Matrix has unknown component index values x >>%s<< and / or y >>%s<<', any2str(xx),any2str(yy) );
        end
        % return matrix value
        y = s.matrix(index_yy,index_xx);
    else
        error('Matrix.getValue: Matrix Type >>%s<< not defined', s.type );
    end
  else
    print_usage ();
  end
end
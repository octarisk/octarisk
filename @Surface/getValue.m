% method of class @Surface
function y = getValue (surface, xx,yy,zz)
  s = surface;
  if (nargin == 1)
    y = s.name;
  elseif (nargin > 1)
    if ( nargin == 2)
        len = 1;
        y = zeros(rows(xx),1);
    endif
    if ( nargin == 3 )
        y = zeros(rows(xx),1);
        len = 2;
        if (rows(xx) == 1)
            xx = ones(rows(yy),1) .* xx;
        endif    
    endif
    if ( nargin == 4 )
        y = zeros(rows(zz),1);
        len = 3;
        if (rows(xx) == 1)
            xx = ones(rows(zz),1) .* xx;
        endif
        if (rows(yy) == 1)
            yy = ones(rows(zz),1) .* yy;
        endif         
    endif
    
    % type ir
    if ( strcmp(toupper(s.type),'IR'))           
        if (len == 1 && length(s.axis_x) > 0 && length(s.axis_y) == 0 && length(s.axis_z) == 0 )                    %first case: object is curve
          if ( strcmp(toupper(s.axis_x_name),'TERM') )
            y = interpolate_curve(s.axix_x,s.values_base,xx,s.method_interpolation);
          else
            error("ERROR: Assuming curve for IR with term, got: %s",s.axis_x_name);
          end
        elseif (len == 2 && length(s.axis_x) > 0 && length(s.axis_y) > 0 && length(s.axis_z) == 0 )         %second case: object is surface 
          if ( strcmp(toupper(s.axis_x_name),'TENOR') && strcmp(toupper(s.axis_y_name),'TERM'))
            xx_structure = s.axis_x;    
            yy_structure = s.axis_y;    
            vola_matrix = s.values_base;               
            % expand vectors and matrizes for constant extrapolation (add additional tenors and terms, duplicate rows and cols)
            xx_structure = [0,xx_structure,21900];
            yy_structure = [0,yy_structure,21900];
            vola_matrix = cat(2,vola_matrix,vola_matrix(:,end));
            vola_matrix = cat(2,vola_matrix(:,1),vola_matrix);
            vola_matrix = cat(1,vola_matrix,vola_matrix(end,:));
            vola_matrix = cat(1,vola_matrix(1,:),vola_matrix);                   
            % interpolate on surface
            y = interp2(xx_structure,yy_structure,vola_matrix,xx,yy,s.method_interpolation);
          else
            error("ERROR: Assuming surface for IR vol with tenor, term , got: %s, %s",s.axis_x_name,s.axis_y_name);
          end
        elseif (len == 3 && length(s.axis_x) > 0 && length(s.axis_y) > 0 && length(s.axis_z) > 0 )  %second case: object is cube 
          if ( strcmp(toupper(s.axis_x_name),'TENOR') && strcmp(toupper(s.axis_y_name),'TERM')  && strcmp(toupper(s.axis_z_name),'MONEYNESS') )
            xx_structure = s.axis_x;  
            yy_structure = s.axis_y;  
            zz_structure = s.axis_z;  
            vola_cube = s.values_base;
            % expand vectors and matrizes for constant extrapolation (add additional time steps and moneynesses, duplicate rows and cols)
            xx_structure = [0,xx_structure,21900];
            yy_structure = [0,yy_structure,21900];
            zz_structure = [0,zz_structure,100];
            vola_cube = cat(2,vola_cube,vola_cube(:,end,:));
            vola_cube = cat(2,vola_cube(:,1,:),vola_cube);
            vola_cube = cat(1,vola_cube,vola_cube(end,:,:));
            vola_cube = cat(1,vola_cube(1,:,:),vola_cube); 
            vola_cube = cat(3,vola_cube,vola_cube(:,:,end));
            vola_cube = cat(3,vola_cube(:,:,1),vola_cube); 
            % WORKAROUND:
            % interpolating the implied vola for more than 50000 MC scenarios is too memory extensive.
                % therefore one needs to reduce the complexity:
                % since for all MC scenarios the tenor and term is fixed, we make first a nearest neightbor matching of tenor and term
                % and afterwards a linear intepolation of the moneyness. So to say we extract the moneyness dimension from the cube.
                xx_nearest = interp1(xx_structure,xx_structure,xx(1),'nearest');
                yy_nearest = interp1(yy_structure,yy_structure,yy(1),'nearest');
                index_xx = find(xx_structure==xx_nearest);
                index_yy = find(yy_structure==yy_nearest);
            % extract moneyness vector
            moneyness_vec = vola_cube(index_xx,index_yy,:);
            [aa bb cc] = size(moneyness_vec);
            moneyness_vec = reshape(moneyness_vec,cc,1,1);       
            % interpolate on moneyness dimension, hold tenor and term fix (map to nearest)
            y = interp1(zz_structure,moneyness_vec,zz,s.method_interpolation);
          else
            error("ERROR: Assuming cube for IR vol with tenor, term and moneyness, got: %s, %s, %s",s.axis_x_name,s.axis_y_name,s.axis_z_name);
          end
        end
    % type index
    elseif ( strcmp(toupper(s.type),'INDEX'))
        if (len == 2 && length(s.axis_x) > 0 && length(s.axis_y) > 0 && length(s.axis_z) == 0  )         %second case: object is surface
          if ( strcmp(toupper(s.axis_x_name),'TERM') && strcmp(toupper(s.axis_y_name),'MONEYNESS')  )
            xx_structure = s.axis_x;    % first row equals structure of axis xx
            yy_structure = s.axis_y;    % first column equals structure of axis yy

            vola_matrix = s.values_base;                % Matrix without first row and first column contains zz values

            % expand vectors and matrizes for constant extrapolation (add additional time steps and moneynesses, duplicate rows and cols)
            xx_structure = [0,xx_structure,21900];
            yy_structure = [0,yy_structure,10];
            vola_matrix = cat(2,vola_matrix,vola_matrix(:,end));
            vola_matrix = cat(2,vola_matrix(:,1),vola_matrix);
            vola_matrix = cat(1,vola_matrix,vola_matrix(end,:));
            vola_matrix = cat(1,vola_matrix(1,:),vola_matrix);                  
            % interpolate on surface term / moneyness
            y = interp2(xx_structure,yy_structure,vola_matrix,xx,yy,s.method_interpolation);
           else
            error("ERROR: Assuming surface for INDEX vol with term, moneyness, got: %s, %s",s.axis_x_name,s.axis_y_name);
          end  
        else
            error("ERROR: Surface Type Index has no surface defined");
        end
    end
  else
    print_usage ();
  end
  %y(1:min(length(y),10))
endfunction
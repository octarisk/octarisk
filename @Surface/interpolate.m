% method of class @Surface
function y = interpolate (surface, xx,yy,zz)
  s = surface;
  if (nargin == 1)
    y = s.name;
  elseif (nargin > 1)
    if ( nargin == 2)
        len = 1;
        y = zeros(rows(xx),1);
    end
    if ( nargin == 3 )
        y = zeros(rows(xx),1);
        len = 2;
        if (rows(xx) == 1)
            xx = ones(rows(yy),1) .* xx;
        end    
    end
    if ( nargin == 4 )
        y = zeros(rows(zz),1);
        len = 3;
        if (rows(xx) == 1)
            xx = ones(rows(zz),1) .* xx;
        end
        if (rows(yy) == 1)
            yy = ones(rows(zz),1) .* yy;
        end         
    end
    % #################      A) type ir      ###################################
    if ( strcmpi(s.type,'IR'))           
        if (len == 1 && length(s.axis_x) > 0 && length(s.axis_y) == 0 && length(s.axis_z) == 0 )                    %first case: object is curve
          if ( strcmpi(s.axis_x_name,'TERM') )
            y = interpolate_curve(s.axis_x,s.values_base,xx,s.method_interpolation);
          else
            error('ERROR: Assuming curve for IR with term, got: %s',s.axis_x_name);
          end
        elseif (len == 2 && length(s.axis_x) > 0 && length(s.axis_y) > 0 && length(s.axis_z) == 0 )         %second case: object is surface 
          if ( strcmpi(s.axis_x_name,'TENOR') && strcmpi(s.axis_y_name,'TERM'))
            xx_structure = s.axis_x;    
            yy_structure = s.axis_y;    
            vola_matrix = s.values_base;               
            % expand vectors and matrizes for constant extrapolation (add additional tenors and terms, duplicate rows and cols)
            xx_structure = [0,xx_structure,100000];
            yy_structure = [0,yy_structure,100000];
            vola_matrix = cat(2,vola_matrix,vola_matrix(:,end));
            vola_matrix = cat(2,vola_matrix(:,1),vola_matrix);
            vola_matrix = cat(1,vola_matrix,vola_matrix(end,:));
            vola_matrix = cat(1,vola_matrix(1,:),vola_matrix);                   
            % interpolate on surface
            y = interp2(xx_structure,yy_structure,vola_matrix,xx,yy,s.method_interpolation);
          else
            error('ERROR: Assuming surface for IR vol with tenor, term , got: %s, %s',s.axis_x_name,s.axis_y_name);
          end
        elseif (len == 3 && length(s.axis_x) > 0 && length(s.axis_y) > 0 && length(s.axis_z) > 0 )  %second case: object is cube 
          if ( strcmpi(s.axis_x_name,'TENOR') && strcmpi(s.axis_y_name,'TERM')  && strcmpi(s.axis_z_name,'MONEYNESS') )
            xx_structure = s.axis_x;
            yy_structure = s.axis_y;
            zz_structure = s.axis_z;
            vola_cube = s.values_base;
            % expand vectors and matrizes for constant extrapolation (add additional time steps and moneynesses, duplicate rows and cols)
            xx_structure = [0,xx_structure,100000];
            yy_structure = [0,yy_structure,100000];
            zz_structure = [-100000000,zz_structure,100000000];
            vola_cube = cat(2,vola_cube,vola_cube(:,end,:));
            vola_cube = cat(2,vola_cube(:,1,:),vola_cube);
            vola_cube = cat(1,vola_cube,vola_cube(end,:,:));
            vola_cube = cat(1,vola_cube(1,:,:),vola_cube); 
            vola_cube = cat(3,vola_cube,vola_cube(:,:,end));
            vola_cube = cat(3,vola_cube(:,:,1),vola_cube);
            if ( regexpi(s.method_interpolation,'nearest'))
                % map to nearest x,y and z value:
                xx_nearest = interp1(xx_structure,xx_structure,xx(1),'nearest');
                yy_nearest = interp1(yy_structure,yy_structure,yy(1),'nearest');
                index_xx = find(xx_structure==xx_nearest);
                index_yy = find(yy_structure==yy_nearest);
                % extract moneyness vector (x axis -> dimension 2, y axis -> dimension 1)
                moneyness_vec = vola_cube(index_yy,index_xx,:);
                [aa bb cc] = size(moneyness_vec);
                moneyness_vec = reshape(moneyness_vec,cc,1,1);      
                % interpolate on moneyness dimension, hold tenor and term fix (map to nearest)
                y = interp1(zz_structure,moneyness_vec,zz,'nearest');
            else    % default: linear (if( regexpi(s.method_interpolation,'linear')))
                % Trilinear Interpolation:
                x = xx(1);
                y = yy(1);
                z = zz;
                % get index values of 6 previous and next points on all axis
                x0 = interp1(xx_structure,xx_structure,x,'previous');
                x1 = interp1(xx_structure,xx_structure,x,'next');
                y0 = interp1(yy_structure,yy_structure,y,'previous');
                y1 = interp1(yy_structure,yy_structure,y,'next');
                z0 = interp1(zz_structure,zz_structure,z,'previous');
                z1 = interp1(zz_structure,zz_structure,z,'next');
                % get differences
                if ( x0 == x1)
                    xd = 0;
                else
                    xd = (x - x0) / (x1 - x0);
                end
                if ( y0 == y1)
                    yd = 0;
                else
                    yd = (y - y0) / (y1 - y0);
                end
                % if ( z0 == z1)
                    % zd = 0;
                % else
                    % zd = (z - z0) ./ (z1 - z0);
                % end
                % return vector zd
                zd = (1 - ( z0 == z1)) .* (z - z0) ./ (z1 - z0);
                zd(isnan(zd))=0;
                % get indizes   
                index_x0 = find(xx_structure==x0);
                index_x1 = find(xx_structure==x1);
                index_y0 = find(yy_structure==y0);
                index_y1 = find(yy_structure==y1);
                tmp_z0 = (zz_structure==z0);
                index_z0 = sum(tmp_z0 .* [1:1:columns(tmp_z0)],2);
                tmp_z1 = (zz_structure==z1);
                index_z1 = sum(tmp_z1 .* [1:1:columns(tmp_z1)],2);
                % extract volatility value
                V_x0y0z0 = vola_cube(index_y0,index_x0,index_z0);
                V_x0y0z1 = vola_cube(index_y0,index_x0,index_z1);
                V_x0y1z0 = vola_cube(index_y1,index_x0,index_z0);
                V_x0y1z1 = vola_cube(index_y1,index_x0,index_z1);
                V_x1y0z0 = vola_cube(index_y0,index_x1,index_z0);
                V_x1y0z1 = vola_cube(index_y0,index_x1,index_z1);
                V_x1y1z0 = vola_cube(index_y1,index_x1,index_z0);
                V_x1y1z1 = vola_cube(index_y1,index_x1,index_z1);
                % reshaping results
                [rr cc uu] = size(V_x0y0z0);
                V_x0y0z0 = reshape(V_x0y0z0,uu,1,1);
                V_x0y0z1 = reshape(V_x0y0z1,uu,1,1);
                V_x0y1z0 = reshape(V_x0y1z0,uu,1,1);
                V_x0y1z1 = reshape(V_x0y1z1,uu,1,1);
                V_x1y0z0 = reshape(V_x1y0z0,uu,1,1);
                V_x1y0z1 = reshape(V_x1y0z1,uu,1,1);
                V_x1y1z0 = reshape(V_x1y1z0,uu,1,1);
                V_x1y1z1 = reshape(V_x1y1z1,uu,1,1);
                
                % interpolate along x axis
                c00 = V_x0y0z0 .* ( 1 - xd ) + V_x1y0z0 .* xd;
                c01 = V_x0y0z1 .* ( 1 - xd ) + V_x1y0z1 .* xd;
                c10 = V_x0y1z0 .* ( 1 - xd ) + V_x1y1z0 .* xd;
                c11 = V_x0y1z1 .* ( 1 - xd ) + V_x1y1z1 .* xd;
                % interpolate along y axis
                c0 = c00 .* (1 - yd ) + c10 .* yd;
                c1 = c01 .* (1 - yd ) + c11 .* yd;
                % interpolate along x axis and return final value "y"
                y = c0 .* (1 - zd ) + c1 .* zd;           
            end
          else
            error('ERROR: Assuming cube for IR vol with tenor, term and moneyness, got: %s, %s, %s',s.axis_x_name,s.axis_y_name,s.axis_z_name);
          end
        end
        
    % #################      B) type index      ###################################
    elseif ( strcmpi(s.type,'INDEX'))
        if (len == 2 && length(s.axis_x) > 0 && length(s.axis_y) > 0 && length(s.axis_z) == 0  )         %second case: object is surface
          if ( strcmpi(s.axis_x_name,'TERM') && strcmpi(s.axis_y_name,'MONEYNESS')  )
            xx_structure = s.axis_x;    % first row equals structure of axis xx
            yy_structure = s.axis_y;    % first column equals structure of axis yy

            vola_matrix = s.values_base;                % Matrix without first row and first column contains zz values

            % expand vectors and matrizes for constant extrapolation 
            % (add additional time steps and moneynesses, duplicate rows and cols)
            xx_structure = [0,xx_structure,21900];
            yy_structure = [0,yy_structure,1000000];
            vola_matrix = horzcat(vola_matrix,vola_matrix(:,end));
            vola_matrix = horzcat(vola_matrix(:,1),vola_matrix);
            vola_matrix = vertcat(vola_matrix,vola_matrix(end,:));
            vola_matrix = vertcat(vola_matrix(1,:),vola_matrix);                 
            % interpolate on surface term / moneyness
            y = interp2(xx_structure,yy_structure,vola_matrix,xx,yy,s.method_interpolation);
           else
            error('ERROR: Assuming surface for INDEX vol with term, moneyness, got: %s, %s',s.axis_x_name,s.axis_y_name);
          end  
        else
            error('ERROR: Surface Type Index has no surface defined');
        end
        
    % #################      C) type stochastic      ###################################
    elseif ( strcmpi(s.type,'STOCHASTIC'))
        if (len == 2 && length(s.axis_x) > 0 && length(s.axis_y) > 0 && length(s.axis_z) == 0  )         %second case: object is surface
          if ( strcmpi(s.axis_x_name,'DATE') && strcmpi(s.axis_y_name,'QUANTILE')  )
            xx_structure = s.axis_x;    % first row equals structure of axis xx
            % increase x axis value by 1 if value is 0 
            % (xx_structure has to be strictly monotonic)
            if ( length(xx_structure) == 1 && xx_structure == 0) 
                xx_structure = 1;
            end
            yy_structure = s.axis_y;    % first column equals structure of axis yy

            vola_matrix = s.values_base;                % Matrix without first row and first column contains zz values

            % expand vectors and matrizes for constant extrapolation 
            % (add additional time steps and moneynesses, duplicate rows and cols)
            xx_structure = [0,xx_structure,21900];
            yy_structure = [0,yy_structure,1000000];
            vola_matrix = horzcat(vola_matrix,vola_matrix(:,end));
            vola_matrix = horzcat(vola_matrix(:,1),vola_matrix);
            vola_matrix = vertcat(vola_matrix,vola_matrix(end,:));
            vola_matrix = vertcat(vola_matrix(1,:),vola_matrix);                 
            % interpolate on surface term / moneyness
            y = interp2(xx_structure,yy_structure,vola_matrix,xx,yy,s.method_interpolation);
           else
            error('ERROR: Assuming surface for STOCHASTIC values with DATE, QUANTILE, got: %s, %s',s.axis_x_name,s.axis_y_name);
          end  
        else
            error('ERROR: Surface Type Index has no surface defined');
        end
        
    % ###########      D) type prepayment procedure      #######################
    % prepayment procedure: surface coupon rate / absolute ir shock 
    elseif ( strcmpi(s.type,'PREPAYMENT'))
        if (len == 2 && length(s.axis_x) > 0 && length(s.axis_y) > 0 && length(s.axis_z) == 0  )         %second case: object is surface
          if ( strcmpi(s.axis_x_name,'coupon_rate') && strcmpi(s.axis_y_name,'ir_shock')  )
            xx_structure = s.axis_x;    % first row equals structure of axis xx
            yy_structure = s.axis_y;    % first column equals structure of axis yy

            vola_matrix = s.values_base;                % Matrix without first row and first column contains zz values

            % expand vectors and matrizes for constant extrapolation 
            % (add additional time steps and moneynesses, duplicate rows and cols)
            xx_structure = [-100,xx_structure,100];
            yy_structure = [-100,yy_structure,100];
            vola_matrix = horzcat(vola_matrix,vola_matrix(:,end));
            vola_matrix = horzcat(vola_matrix(:,1),vola_matrix);
            vola_matrix = vertcat(vola_matrix,vola_matrix(end,:));
            vola_matrix = vertcat(vola_matrix(1,:),vola_matrix);                 
            % interpolate on surface coupon_rate / ir_shock
            y = interp2(xx_structure,yy_structure,vola_matrix,xx,yy,s.method_interpolation);
           else
            error('ERROR: Assuming surface for PREPAYMENT with coupon_rate, ir_shock, got: %s, %s',s.axis_x_name,s.axis_y_name);
          end  
        else
            error('ERROR: Surface Type Index has no surface defined');
        end
    end
  else
    print_usage ();
  end
end
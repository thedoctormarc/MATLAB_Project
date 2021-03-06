
 function [mouse_in_sph] =  Calculate_M_in_sphere(sph_radius, xmouse, ymouse)
     
    mouse_in_sph = [0,0,0]'; 
    
    if(xmouse*xmouse + ymouse*ymouse < sph_radius*sph_radius*0.5)
        mouse_in_sph(1) = xmouse; 
        mouse_in_sph(2) = ymouse; 
        mouse_in_sph(3) =(sph_radius*sph_radius - xmouse*xmouse - ymouse*ymouse).^0.5; 
    else 
         z = (sph_radius*sph_radius) / 2 * sqrt(xmouse*xmouse + ymouse*ymouse);                       % check this out
         mouse_in_sph = [xmouse, ymouse, z]' / sqrt(xmouse*xmouse + ymouse*ymouse + z*z);  
    end 
 end 

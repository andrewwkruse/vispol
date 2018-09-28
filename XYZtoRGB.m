function RGB = XYZtoRGB(XYZ)
M = [3.2406 -1.5372 -0.4986; -0.9689 1.8758 0.0415; 0.0557 -0.2040 1.0570];
RGB = (M*XYZ')';
lin_region = RGB<=0.0031308;
RGB(lin_region) = RGB(lin_region) .* 12.92;
RGB(~lin_region) = (1.055) * RGB(~lin_region) .^ (1/2.4) - 0.055;
RGB(RGB>1)=1; RGB(RGB<0)=0;
end
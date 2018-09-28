% Calculates XYZ (CIE 1931 2 deg standard observe) from CIECAM02 J, M, h
% arguments:
%       J, M, h: numbers or matrices of CIECAM02 lightness, colorfulness,
%           and hue coordinates
%       xyzw: triplet for the XYZ coordinates of the whitepoint
%       LA : specified luminance of viewing surface in cd/m^2
%           (can be calculated by illuminance)
%       YB : XYZ Y value for background brightness
%       para: set of viewing conditions (F, c, Nc). Defined conditions are:
%                  F      c       Nc
%        Average   1.0    0.69    1.0
%            Dim   0.9    0.59    0.95
%           Dark   0.8    0.525   0.8
% See Advanced Color Image Processing and Analysis, Ch 2: "CIECAM02 and its
%   recent development" pp 52-55 (Part 2: the reverse mode) 
%   by MR Luo and C Li, editor C Fernandez-Maloigne
% Much of this is adapted from Python package "colorspacious"
%   (version 1.1.0+dev) by NJ Smith

function XYZ = CAM02toXYZ(J,M,h,xyzw,LA,YB,para)
% para defines the extra parameters necessary to convert between spaces
%%%% constants that do not depend on J,M,h:
F = para(1); c = para(2); Nc = para(3);
k = 1 / (5 * LA + 1);
F_L = (0.2*(k^4)*5*LA) + (0.1*((1-k^4)^2)*((5*LA)^(1/3))); %Lum adaptation
n = YB / xyzw(2);
Nbb = 0.725 * (n^(-0.2));
Ncb = Nbb;
D = F * (1 - (1/3.6)*exp(-(LA + 42)/92)); % Degree of adaptation
D(D>1)=1;
D(D<0)=0;
z = 1.48 + sqrt(n);

M_CAT02 = [ 0.7328,  0.4296, -0.1624;
           -0.7036,  1.6975,  0.0061; 
            0.0030,  0.0136,  0.9834];

M_HPE = [ 0.38971,  0.68898, -0.07868;
         -0.22981,  1.18340,  0.04641;
          0.00000,   0.00000, 1.00000];
      
M_CAT02_inv = inv(M_CAT02);
M_HPE_M_CAT02_inv = M_HPE * M_CAT02_inv;
M_CAT02_M_HPE_inv = M_CAT02 * inv(M_HPE);

RGBprime_a_mat = [ 460/1403,  451/1403,  288/1403;
                   460/1403, -891/1403, -261/1403;
                   460/1403, -220/1403, -6300/1403;];

RGB_w = M_CAT02 * xyzw';
D_RGB = D * xyzw(2) ./ RGB_w + 1 - D;
RGB_wc = D_RGB .* RGB_w;
RGBprime_w = M_HPE_M_CAT02_inv * RGB_wc;
tmp = (F_L * RGBprime_w / 100) .^ 0.42;
RGBprime_aw = 400 * (tmp ./ (tmp + 27.13)) + 0.1;
A_w = ([2, 1, 1. / 20] * RGBprime_aw - 0.305)* Nbb;
%%%%%%%%%%%%%
sh = size(J);
sh(3) = 3;
J = reshape(J,[],1);
M = reshape(M,[],1);
h = reshape(h,[],1);

t = calct(J,M,F_L,n);
A = calcA(J,A_w,c,z);
et = calcet(h);
[p2,a,b] = calcp2ab(A, Nc, Ncb, Nbb, et, t, h);

XYZ = zeros(length(J),3);
for idx = 1:length(J)
    RGBprime_a = calcRGBprime_a(p2(idx),a(idx),b(idx),RGBprime_a_mat);
    RGBprime = calcRGBprime(RGBprime_a, F_L);
    RGB_c = calcRGB_c(RGBprime, M_CAT02_M_HPE_inv);
    RGB = calcRGB(RGB_c, D_RGB);
    XYZ(idx,:) = calcXYZ(RGB, M_CAT02_inv);
end
XYZ = reshape(XYZ,sh);
end

function t = calct(J,M,F_L,n)
C = M / (F_L^0.25);
t = (C./ (sqrt(J/100)*((1.64 - (0.29^n)).^0.73))).^(1/0.9);
end

function et = calcet(h)
et = 0.25 * (cos(h+2) + 3.8);
end

function [p2, a, b] = calcp2ab(A, Nc, Ncb, Nbb, et, t, h)
p1 = (50000/13 * Nc * Ncb) .* et ./ t;
p2 = A/Nbb + 0.305;
p3 = 21/20;
sinh = sin(h); cosh = cos(h);
numer = p2 .* ((2 + p3) * (460/1403)); %%% ?? the part after p2 equals 1
denom_2 = (2+p3)*(220/1403);
denom_3 = - 27/1403 + p3 * 6300/1403;
b = zeros(size(h),'like',h);
a = zeros(size(h),'like',h);
smallh_ind = abs(sinh) < abs(cosh);

a(smallh_ind) = numer(smallh_ind)./ ((p1(smallh_ind)./cosh(smallh_ind))...
    + denom_2 + denom_3 .* (sinh(smallh_ind)./cosh(smallh_ind)));
b(smallh_ind) = a(smallh_ind) .* (sinh(smallh_ind)./cosh(smallh_ind));

b(~smallh_ind)  = numer(~smallh_ind)./ ((p1(~smallh_ind)./sinh(~smallh_ind))...
    + denom_2 .* (cosh(~smallh_ind)./sinh(~smallh_ind)) + denom_3);
a(~smallh_ind) = b(~smallh_ind) .* (cosh(~smallh_ind)./sinh(~smallh_ind));
end

function A = calcA(J,A_w,c,z)
A = A_w * (J/100).^(1/(c*z));
end

function e = calce(h, Nc, Ncb)
e = ((12500/13)*Nc*Ncb)*(cos(h+2)+3.8);
end

function RGBprime_a = calcRGBprime_a(p2,a,b,RGBprime_a_mat)
RGBprime_a = RGBprime_a_mat * [p2, a, b]';
end

function RGBprime = calcRGBprime(RGBprime_a, F_L)
RGBprime = sign(RGBprime_a - 0.1) ...
            * (100 / F_L) ...
            .* (((27.13 * abs(RGBprime_a - 0.1))  ...
            ./ (400 - abs(RGBprime_a - 0.1)))) .^ (1 / 0.42);
end

function RGB_c = calcRGB_c(RGBprime, M_CAT02_M_HPE_inv)
RGB_c = M_CAT02_M_HPE_inv * RGBprime;
end

function RGB = calcRGB(RGB_c, D_RGB)
RGB = RGB_c ./ D_RGB;
end

function XYZ = calcXYZ(RGB, M_CAT02_inv)
XYZ = M_CAT02_inv * RGB;
end


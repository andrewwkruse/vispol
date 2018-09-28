% Dependencies:
%   CAM02toXYZ.m
%   XYZtoRGB.m
function RGB = UCStosRGB(Jp,Mp,h)
%%%%%%%%%%%%%%%
% Much of this functionality has been modified from "colorspacious"
% Original copyright to "colorspacious" belongs to NJ Smith
xyzw1 = [ .95047, 1, 1.08883];
xyzw100=[ 95.047, 100, 108.883];
%  To compute L_A:
%  illuminance in lux / pi = luminance in cd/m^2
%  luminance in cd/m^2 / 5 = L_A (the "grey world assumption")
%  See Moroney (2000), "Usage guidelines for CIECAM97s".
%  sRGB illuminance is 64 lux.
LA = (64 / pi) / 5;
YB = 20; 
% Average surround parameters. Assumed from sRGB viewing environment where
% ambient has a higher illuminance than the screen
% See: https://en.wikipedia.org/wiki/CIECAM02#Parameter_decision_table
%      https://en.wikipedia.org/wiki/SRGB#Viewing_environment
F = 1.0;
c = 0.69;
Nc = 1.0;
% UCS to CAM02: see Luo et al 2006
% constants for UCS
KL = 1.0;
c1 = 0.007;
c2 = 0.0228;
% solving equations in Luo et al for the CAM02 values
J = - Jp ./ ( c1 * Jp - 100*c1 - 1);
M = (exp(c2 * Mp) - 1) / c2;


para = [F, c, Nc];
XYZ = CAM02toXYZ(J,M,h,xyzw100,LA,YB,para);
sh = size(XYZ);
XYZ = reshape(XYZ,[],3);
RGB = XYZtoRGB(XYZ./100);
RGB = reshape(RGB,sh);
end
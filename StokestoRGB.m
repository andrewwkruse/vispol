%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % author: Andrew W. Kruse            % %
% % email: a.kruse@student.adfa.edu.au % %
% % version: dev                       % %
% % created: 20/02/2018                % %
% % last edited: 20/02/2018 AWK        % %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main function that creates perceptually uniform color 
%   channels (lightness, colorfulness, hue) representing polarization 
%   channels(Intensity, Degree of Linear Polarization, Angle of Linear
%   Polariztaion) from initial Stokes parameters and outputting into sRGB.
% output RGB matrix can be written to a file through imwrite or can be
%   shown in a MATLAB figure window by imshow
% S is the n x m x (3 or 4) array representing the Stokes parameters of 
%   each pixel. S(:,:,1) > 0, and S(:,:,2), S(:,:,3)
%   should be between -1 and 1. However, this function cleans up array
%   automatically. 
% varagins should be in the form of a cell array:
%   {Ibar_params, Pbar_params, Abar_params, delta_params, xspline, yspline}
%   Ibar_params, Pbar_params, Abar_params must be length=0,1, or 2 cell:
%   {} if no processing is done to that polarization channel
%   if there is processing, cell must be in the form of:
%   {function_handle} if function does not have other parameters such that
%       processed_channel = function_handle(pol_channel)
%   {function_handle, {params}} 
%       {params} is a length=n cell such that 
%           processed_channel = function_handle(pol_channel,{params})
%   function_handle references a function that has an n x m matrix
%       as its first argument, although StokestoRGB should not have these
%       matrices as arguments
%   delta_params must be cell with length 0 to 7 where the entries are:
%         delta_on : boolean, true for implementing delta metric mask.
%           default false
%         element : integer > 0, implements delta metric for neighborhood
%         of (element x element). Default is 3
%         thresh : float between 0 and 1. sets threshold for mask (values
%           higher than thresh are masked). default is 0.5
%         morph : boolean, true for binary opening and closing of mask to 
%           remove islands and holes. default is true
%         struct : integer > 0, sets structure to (struct x struct) for 
%           morphological opening/closing. default is 3
%         smooth : boolean, true for implementing gaussian filter over mask 
%           to reduce pixelation. default is false
%         sigma : float > 0, standard deviation for gaussian filter
%           default is 1.0
%   xspline: vector of points along J' axis describing the spline
%       interpolation of the gamut curve c. This defines the J' coordinates
%       of the boundary of the subset of UCS rotationally symmetric about
%       h. Necessary to prevent colors from going outside of the possible
%       colors in sRGB.
%   yspline: vector of points along M' axis describing the spline
%       interpolation of the gamut curve c. See xspline
% Dependencies:
%   CAM02toXYZ.m
%   delta.m
%   dmask.m
%   Jbounds.m
%   UCStosRGB.m
%   XYZtoRGB.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [RGB, color_wheel] = StokestoRGB(S, varargins)
if nargin > 8
    error('myfuns:StokestoRGB:TooManyInputs', ...
        'requires at most 7 optional inputs');
end
    
% Set defaults for varargins
Ibar_default = {};
Pbar_default = {};
Abar_default = {};
delta_default = {};
xspline_default = [0, 5, 20, 40, 73, 77, 100];
yspline_default = [0.0, 6.6, 13.7, 19.4, 26.4, 24.1, 0.0];
optargins = {Ibar_default, Pbar_default, Abar_default, delta_default, ...
    xspline_default, yspline_default};
if nargin ~= 1
    numvarargins = length(varargins);
    optargins(1:numvarargins) = varargins;
end
[Ibar_params, Pbar_params, Abar_params, delta_params, xspline, yspline]...
    = optargins{:};

if length(xspline) ~= length(yspline)
    error('xspline and yspline are not the same size')
end

%%%%%%%%%%%%%%%%%
% clean up Stokes
S0 = S(:,:,1); S1 = S(:,:,2); S2 = S(:,:,3);
S0(S0<0)=0;
count = sum(sum(S1>1)) + sum(sum(S1<-1)) + sum(sum(S2>1)) + sum(sum(S2<-1));
ratio = count / numel(S0);
if (0 < ratio) && (ratio < 0.1)
    fprintf(['Some elements of S1 or S2 outside of range [-1,1].\n'...
        ,'However it seems that S1 and S2 are normalized.\n'...
        ,'Recommended that Stokes is cleaned up prior to calling this'...
        ,' function\n']);
    S1(S1>1) = 1; S1(S1<-1) = -1; S2(S2>1) = 1; S2(S2<-1) = -1;
elseif ratio > 0.1
    fprintf(['S1 or S2 outside of range [-1,1]. It seems that they are'...
        ,' not normalized to S0. If this is incorrect make sure S1 and'...
        ,' S2 are correctly normalized.\n']);
    S1(S0>0) = S1./S0;
    S2(S0>1) = S2./S0;
    S1(S1>1) = 1; S1(S1<-1) = -1; S2(S2>1) = 1; S2(S2<-1) = -1;

end

S(:,:,1) = S0; S(:,:,2) = S1; S(:,:,3) = S2;
%%%%%%%%%%%%%
% convert polarization channels to prepared channels
% I -> Ibar
I = S(:,:,1);
I(isnan(I)) = 0;
if isempty(Ibar_params)
    if any(I(:)>1) % scale I if input S0 array is not set to [0,1]
    I = I./ max(max(I));
    end
    I(I<0) = 0;
    I(I>1) = 1;
    Ibar = I;
else
    func = Ibar_params(1);
    func = func{:};
    if length(Ibar_params) == 1
        Ibar = func(I);
    else
        params = Ibar_params(2);
        params = params{:};
        Ibar = func(I, params);
    end
    if any(Ibar(:) > 1) || any(Ibar(:) < 0)
        warning(['Ibar function is not placing Ibar into range'...
        ,' [0,1].\n Will automatically clip.\n']);
        Ibar(Ibar > 1) = 1;
        Ibar(Ibar < 0) = 0;
    end
end
%%%%%%%%%%
% [P_cw, A_cw] = make_cw_arrays(100);

% P -> Pbar
P = StD(S);
if isempty(Pbar_params)
    Pbar = P;
else
    func = Pbar_params(1);
    func = func{:};
    if length(Pbar_params) == 1
        Pbar = func(P);
%         P_cw = func(P_cw);
    else
        params = Pbar_params(2);
        params = params{:};
        Pbar = func(P, params);
%         P_cw = func(P_cw, params);
    end
    if any(Pbar(:) > 1) || any(Pbar(:) < 0)
        warning(['Pbar function is not placing Pbar into range'...
        ,' [0,1].\n Will automatically clip.\n']);
        Pbar(Pbar > 1) = 1;
        Pbar(Pbar < 0) = 0;
    end
end
%%%%%%%%%%%%%
% A -> Abar
A = StA(S);
if isempty(Abar_params)
    Abar = A;
else
    func = Abar_params(1);
    func = func{:};
    if length(Abar_params) == 1
        Abar = func(A);
%         A_cw = func(A_cw);
    else
        params = Abar_params(2);
        params = params{:};
        Abar = func(A, params);
%         A_cw = func(A_cw, params);
    end
end
%%%%%%%%%%%%%%%%%%%
% create delta mask if delta_params(1) is set to true
if ~isempty(delta_params)
    delta_on = delta_params(1);
    delta_on = delta_on{:};
    if delta_on
        if length(delta_params) == 1 % all defaults
            DM = delta(S);
            Mask = dmask(DM);
        else % element is defined
            element = delta_params(2);
            element = element{:};
            DM = delta(S,element);
            if length(delta_params) >= 3 % some dmask_params specified
                dmask_params = delta_params(3:end);
            else % dmask_params set to default
                dmask_params = {};
            end
            Mask = dmask(DM,dmask_params);
        end           
        Pbar = Pbar .* Mask;      
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%
% % color wheel
% color_wheel = cw_ax(P_cw, A_cw, max(yspline), xspline(yspline == max(yspline)));
%%%%%%%%%%%%%%%%%%%%%%%%%
% Creating perecptual channels
M = PtoM(Pbar,yspline);
Jb = Jbounds(M, xspline, yspline); % Jbounds.m
J = ItoJ(Ibar, Jb);
h = Atoh(Abar);

RGB = UCStosRGB(J,M,h); % convert to sRGB
end

function dolp = StD(S)
dolp = sqrt(S(:,:,2).^2 + S(:,:,3).^2);
dolp(dolp>1)=1;
end

function aolp = StA(S) % calculate aolp in range [-pi/2, pi/2]
aolp = 0.5 * atan2(S(:,:,3),S(:,:,2));
end

function M = PtoM(Pbar, yspline) % convert P to M given the boundary curve
M = Pbar .* max(yspline);
M(isnan(Pbar)) = 0;
end

function J = ItoJ(I,bounds) % convert I to J
J = I .* (bounds(:,:,2) - bounds(:,:,1)) + bounds(:,:,1);
J(isnan(I)) = 0;
end

function h = Atoh(A) % convert A to h
h = A .* 2;
h(isnan(A)) = 0;
end

% function ax = cw_ax(P_array, A_array, scale, lightness)
% figure;
% ax = polaraxes;
% sz = size(P_array);
% radius = round(sz(1) / 2);
% ax.RTick = linspace(0, 1, 5);
% Rslice = P_array(radius,radius:end);
% Rind = round(linspace(1,radius,5));
% ax.RTickLabels = Rslice(Rind);
% thetas = linspace(0,330, 12)
% theta_x = round(radius .* (1 + cos(thetas.* (pi/180))))
% theta_y = round(radius .* (1 + sin(thetas.* (pi/180))))
% theta_x(theta_x == 0) = 1;
% theta_y(theta_y == 0) = 1;
% A_theta = diag(A_array(theta_x, theta_y));
% ax.ThetaTick = thetas;
% ax.ThetaTickLabel = A_theta;
% 
% rgb = ones(sz(1),sz(2), 3);
% figure;
% scatter(theta_x, theta_y);
% for x = 1:sz(1)
%     xdist = x - radius;
%     for y = 1:sz(1)
%         ydist = y - radius;
%         rdist = sqrt(xdist^2 + ydist^2);
% %         hue = atan2(ydist, xdist) * 2;
% %         M = scale .* P_array(x,y);
% %         rgb(x,y,:) = UCStosRGB(lightness, M, hue);
%         if rdist <= radius
% %             hue = atan2(ydist, xdist) * 2;
%             hue = 2 .* A_array;
%             M = scale .* P_array(x,y);
%             rgb(x,y,:) = UCStosRGB(lightness, M, hue);
%         end
%     end
% end
% % imshow(rgb)
% end
% 
% function [P, A] = make_cw_arrays(sz)
% P = zeros(sz, sz);
% A = zeros(sz, sz);
% radius = sz/2;
% for x = 1:sz
%     xdist = x - radius;
%     for y = 1:sz
%         ydist = y - radius;
%         rdist = sqrt(xdist.^2 + ydist.^2) / radius;
%         if rdist <= 1
%             P(x,y) = rdist;
%         end   
% %         A(x,y) = atan2(ydist,xdist)/2;
%         A(x,y) = atan(ydist/xdist)/2;
%     end
% end
% A(A<0) = A(A<0) + pi/2;
% figure;imshow(P);
% end

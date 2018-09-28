%% Create delta mask from the delta metric to mask high variability in aolp
%  Necessary for StokestoRGB.m
%  See "Adapting the HSV polarization-color mapping for regions with low
%       irradiance and high polarization", Tyo et al 2016.
%  arguments:
%         delta : matrix of delta metric values from delta.m
%  varargins:
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

function m = dmask(delta, varargins)
thresh_default = 0.5;
morph_default = true;
struct_default = 3;
smooth_default = false;
sigma_default = 1.0;
optargins = {thresh_default, morph_default, struct_default,...
    smooth_default, sigma_default};

if nargin ~= 1
    numvarargins = length(varargins);
    optargins(1:numvarargins) = varargins;
end
[thresh, morph, struct, smooth, sigma] = optargins{:};

m = delta < thresh; % note, all nan's will be masked by this operation
if morph
    m = imclose(imopen(m,ones(struct,struct)),ones(struct,struct));
end
if smooth
    m = imgaussfilt(double(m),sigma);
end
end
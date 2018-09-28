%% Calculate delta metric from Stokes
%  Necessary for StokestoRGB.m
%  See "Adapting the HSV polarization-color mapping for regions with low
%       irradiance and high polarization", Tyo et al 2016.
%  arguments:
%       S: n x m x (3 or 4) Stokes vector matrix
%  varargin:
%       element: integer > 0, implements delta metric for neighborhood of 
%           (element x element). Default is 3
function d = delta(S,varargin)
element_default = 3;
if nargin == 1
    element = element_default;
elseif isempty(varargin{:})
    element = element_default;
else
    element = varargin{:}(1);
end
sh = size(S(:,:,1));
N = conv2(ones(sh), ones(element,element), 'same');
P = StD(S); %DoP
ca = S(:,:, 2)./ P; % cos AoLP
sa = S(:,:, 3)./ P; % sin AoLP
cam = conv2(ca, ones(element, element), 'same') ./ N; % averaged cosine
sam = conv2(sa, ones(element, element), 'same') ./ N; % averaged sine
d = real(sqrt(1 - (cam .^ 2 + sam .^ 2)));
end

function dolp = StD(S)
dolp = sqrt(S(:,:,2).^2 + S(:,:,3).^2);
dolp(dolp>1)=1;
end
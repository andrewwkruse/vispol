% Stokes vector matrix
Stokes = StokesData(:,:,:,1);

% optional processing arguments
% clips intensity to the 99th percentile using function clipatperc
perc = 99;
ibar = {@clipatperc, perc}; 
% clips DoLP to max value
max_val = 0.4;
pbar_clip = {@clipatmax, max_val};
% nonlinear DoLP
expo = 0.5;
pbar_nl = {@nonlinear, expo};
% fix noisy false polarization
dpar = {true,... % true means do the noise fixing
        3,...    % element size for local neighborhood of aolp.
        0.4,...  % threshold for variability in aolp
        true,... % true means do morphology
        3,...    % structure element for morphology
        true,... % true means gaussian smoothing
        1};      % sigma for gaussian filter
% larger element size means aolp must be steady over larger region
% larger threshold means the local variability can be higher and not be
%   suppressed. below threshold = true polarization, above = false pol
% morphology is a binary opening and closing of the mask. good to fix holes
%   and islands
% larger structure element means larger holes and islands are removed
% gaussian smoothing is to reduce the effect of excessive contrast and
%   pixelation
% larger sigma means smoother edges for polarized regions

% you can use any function for pbar to change how dolp maps into
%   colourfulness. functions must be in the form
%   function arr_out = myfun(arr_in, params)
%       where params is either an individual value or a cell of all the
%       parameters necessary for that function. example:
% function arr_out = add_div(arr_in, params)
% params = cell2mat(params);
% add = params(1);
% div = params(2);
% arr_out = (arr_in + add) ./ div
% end

RGB_norm = StokestoRGB(Stokes, {ibar});
RGB_clip = StokestoRGB(Stokes, {ibar, pbar_clip});
RGB_nonlin = StokestoRGB(Stokes, {ibar, pbar_nl});
RGB_smooth = StokestoRGB(Stokes, {ibar, pbar_clip, {}, dpar}); % note empty cell for abar

for i=1:4
    figure;
    switch i
        case 1
            imshow(RGB_norm);
        case 2
            imshow(RGB_clip);
        case 3
            imshow(RGB_nonlin);
        case 4
            imshow(RGB_smooth);
    end
end

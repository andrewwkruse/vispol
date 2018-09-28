%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % author: Andrew W. Kruse            % %
% % email: a.kruse@student.adfa.edu.au % %
% % version: dev                       % %
% % created: 20/02/2018                % %
% % last edited: 20/02/2018 AWK        % %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% StokestoRGB is the main function that creates perceptually uniform color 
%   channels (lightness, colorfulness, hue) representing polarization 
%   channels (Intensity, Degree of Linear Polarization, Angle of Linear
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
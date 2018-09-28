function RGB = IPAtoRGB(I,P,A,varargin)
Stokes = zeros(size(I),3);
Stokes(:,:,1) = I;
Stokes(:,:,2) = P .* cos(2.*A);
Stokes(:,:,3) = P .* sin(2.*A);
RGB = StokestoRGB(Stokes,varargin);
end
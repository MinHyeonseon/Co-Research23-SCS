function periodCSI = csi2periodogram(magCSI)
%csi2periodogram Creates DC filtered periodogram representation of an image
%   csi2periodogram(rawCSI) takes the magnitude of the CSI image (MAGCSI)
%   as an input 2D-FFT transforms, shifts to the zero frequency, filters
%   the DC components, and returns the periodogram image (PERIODCSI).

%   Copyright 2022-2023 The MathWorks, Inc.

periodCSI = abs(fftshift(fftshift(fft2(magCSI),1),2)); % 2D-FFT and shift to zero
periodCSI = rescale(periodCSI); % Range normalization [0 1]
periodCSI(fix(size(periodCSI,1)/2)+1,:,:) = []; % Filter the DC component in the subcarrier dimension
periodCSI(:,fix(size(periodCSI,2)/2)+1,:) = []; % Filter the DC component in the packet dimension
end
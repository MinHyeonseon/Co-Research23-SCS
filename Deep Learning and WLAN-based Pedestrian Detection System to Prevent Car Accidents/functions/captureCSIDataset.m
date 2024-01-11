function [data,labels,timestamps] = captureCSIDataset(rxsim,captureLabel,visualizeCapture)
%captureCSIDataset Generates CSI dataset based on the SDR captures
%   captureCSIDataset(rxsim,captureLabel,visualizeCapture) captures
%   over-the-air WLAN waveforms using the SDR object (RXSIM) and filters
%   based on the beacon frames. Captured CSIs are visualized if the
%   visualization option is true (VISUALIZECAPTURE). The default is true.
%   The beacon frame CSI (DATA), related timestamps vector (TIMESTAMPS) and
%   categorical labels vector (LABELS) based on the user input
%   (CAPTURELABEL) are returned.

%   Copyright 2022-2023 The MathWorks, Inc.
arguments
    rxsim (1,1) struct;
    captureLabel(1,1) string;
    visualizeCapture (1,1) = true;
end

% Capture, extract and visualize CSI of the beacon frames
visualizeCSIFcn = @(data,timestamps,i) plotCapture(data,rxsim,i);
[data,timestamps] = captureVisualizeCSI(rxsim,rxsim.NumCaptures,visualizeCSIFcn,visualizeCapture);

% Create the labels vector that matches the data and timestamps
labels = categorical(repmat(captureLabel,size(data,ndims(data)),1));

    function plotCapture(data,rxsim,i)
        inputCSI = abs(data(:,:,i)); % Visualize only the magnitude of CSI
        T = tiledlayout(1,2,"TileSpacing","compact");

        % Create plots
        % Plot 1 - CSI Magnitude Response Image
        nexttile
        imagesc(inputCSI.');
        colorbar;
        xlabel('Subcarriers');
        ylabel('Packets');
        title('Raw CSI Magnitude');
        
        % Plot 2 - Normalized CSI Periodogram
        nexttile
        imagesc(csi2periodogram(inputCSI).');
        colorbar;
        clim([0 1]);
        xlabel('Spatial Index');
        ylabel('Temporal Index');
        title('Normalized CSI Periodogram');
        title(T,['Capture ' num2str(i) '/' num2str(rxsim.NumCaptures) ' (' char(captureLabel) ')']);
        set(gcf,'position',[0 0 700 250]);
        drawnow;
    end
end
function [data,timestamps] = captureVisualizeCSI(rxsim,numCaptures,visualizeFcn,visualizeCapture)
%captureVisualizeCSI Captures and visualizes the CSI based on the WLAN waveform captures
%   captureVisualizeCSI(rxsim,numCaptures,visualizeFcn,visualizeCapture)
%   captures NUMCAPTURES over-the-air WLAN waveforms using the SDR object
%   (RXSIM) and filters based on the beacon frames. VISUALIZEFCN is a
%   handle to a function with the following arguments:
%   VISUALIZEFCN(DATA,TIMESTAMPS,CAPTUREINDEX), where DATA is the extracted
%   CSI, TIMESTAMPS is the datetime object that stores the capture
%   timestamps. The captures are visualized based on the VISUALIZECAPTURE
%
%   DATA is a single complex
%   numSubcarriers-by-rxsim.NumPacketsPerCapture-by-rxsim.NumCaptures array
%
%   TIMESTAMP is a rxsim.NumCaptures-by-1 datetime object

%   Copyright 2022-2023 The MathWorks, Inc.
arguments
    rxsim (1,1) struct;
    numCaptures (1,1);
    visualizeFcn (1,1);
    visualizeCapture (1,1) = true;
end

% Capture data for training if the SDR is connected
data = [];
timestamps = [];
numRetry = 3; % Number of tries before terminating the loop in case of unsuccessful captures
idxRetry = 1;
i = 1;
while i <= numCaptures

    % Attempt to capture CSI data
    try
        [csi,t] = captureCSI(i,numCaptures,rxsim.SDRObj,rxsim.CaptureDuration,rxsim.NumPacketsPerCapture,SSIDFilter=rxsim.BeaconSSID);
    catch excp
        if idxRetry < numRetry && contains(excp.identifier, 'sdru:SDRuReceiver') % (Re-)Try captureCSI numRetry times
            idxRetry = idxRetry + 1;
            warning(excp.identifier,'%s',excp.message);
            continue;
        else
            rethrow(excp)
        end
    end

    if isempty(csi)
        warning("wlan:captureCSIData:noBeacons","No beacons detected. Stopping data capture.")
        return;
    elseif size(csi,2) ~= rxsim.NumPacketsPerCapture
        disp("Number of beacons extracted from capture is not equal to number of packets to capture.")
        if idxRetry < numRetry % Try captureCSI numRetry times
            fprintf("Attempting capture %d again...",i)
            idxRetry = idxRetry + 1;
            continue;
        else
            warning("wlan:captureCSIData:notEnoughBeacons", "Number of beacons extracted from capture is not equal to number of packets to capture. Try increasing beacon interval.")
            return;
        end
    end
    idxRetry = 1;
    data = cat(3,data,csi);
    timestamps = cat(1,timestamps,t);

    % Visualize the live capture
    if visualizeCapture
        visualizeFcn(data,timestamps,i);
    end

    % Increment the loop index
    i = i + 1;
end
end
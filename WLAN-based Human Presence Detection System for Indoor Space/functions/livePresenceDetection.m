function sensingResults = livePresenceDetection(rxsim,trainedCNN,numCaptures,visualizeCapture)
%livePresenceDetection Captures and visualizes CSI and make live predictions about human presence
%   livePresenceDetection(rxsim,trainedCNN,numCaptures,visualizeCapture) performs
%   (NUMCAPTURE) over-the-air WLAN waveform captures using SDR object
%   (RXSIM) and extracts CSI from the beacon frames. CSI is used in human
%   presence inferences using the trained network (trainedCNN). Captured
%   CSIs and human presence inference results are visualized if the
%   visualization option is true (VISUALIZECAPTURE). The default is true.
%   The categorical prediction vector and timestamps are returned in a cell
%   array (SENSINGRESULTS).

%   Copyright 2022-2023 The MathWorks, Inc.
arguments
    rxsim (1,1) struct;
    trainedCNN (1,1);
    numCaptures (1,1);
    visualizeCapture (1,1) = true;
end

predictionVector = []; % Initialization of the prediction vector for the CNN inference
plotWindow = 10; % Number of latest CNN inferences that will be plotted

% Capture, extract and visualize CSI of the beacon frames
visualizeCSIFcn = @(data,timestamps,i) plotLiveInference(data,timestamps,i);
[~,timestamps] = captureVisualizeCSI(rxsim,numCaptures,visualizeCSIFcn,visualizeCapture);
sensingResults = {predictionVector timestamps};
    function plotLiveInference(data,timestamps,i)
        inputCSI = abs(data(:,:,i)); % Visualize only the magnitude of CSI
        T = tiledlayout(2,2,"TileSpacing","compact");

        % Plot 1 - CSI Magnitude Response Image
        nexttile
        imagesc(inputCSI.');
        colorbar;
        xlabel('Subcarriers');
        ylabel('Frames');
        xlim tight;

        % Plot 2 - Normalized CSI Periodogram
        nexttile
        imagesc(csi2periodogram(inputCSI).');
        colorbar;
        clim([0 1]);
        xlabel('Spatial Index');
        ylabel('Temporal Index');

        % Plot 3 - Live capture based inference plot
        % Predict live presence using CNN
        predictionVector = cat(1,predictionVector,classify(trainedCNN,csi2periodogram(inputCSI)));

        if size(timestamps,1) < plotWindow
            nexttile([1 2])
            plot(timestamps,predictionVector,'b:o', 'MarkerFaceColor', 'b');
            xticks(timestamps);
            xtickformat('HH:mm:ss');
            xlim tight;
        else
            nexttile([1 2])
            plot(timestamps(size(timestamps,1)-plotWindow+1:size(timestamps,1)),...
                predictionVector(size(timestamps,1)-plotWindow+1:size(timestamps,1)),'b:o', 'MarkerFaceColor', 'b','MarkerSize',4);
            xticks(timestamps);
            xtickformat('HH:mm:ss');
            xlim([timestamps(size(timestamps,1)-plotWindow+1) timestamps(size(timestamps,1))]);
        end
        ylim tight;
        ylabel('Prediction');
        xlabel('Timestamp');
        title(T,['Capture ' num2str(i) ' - Prediction: ' '{\color{red}' upper(char(predictionVector(end))) '}'],'FontWeight','bold');
        set(gcf,'position',[0 0 700 250]);
        drawnow;
    end
end
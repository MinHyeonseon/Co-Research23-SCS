function [data,labels,timestamps] = loadCSIDataset(fileName,label,visualizeData)
%loadCSIDataset Loads and visualizes the pre-recorded CSI dataset
%   loadCSIData(captureLabel,visualizeData) load the dataset that contains
%   the data with the label (LABEL). Pre-recorded CSIs are visualized
%   (VISUALIZEDATA). The pre-recorded beacon frame CSI (DATA), related
%   timestamps (TIMESTAMPS) and categorical labels vector (LABELS) are
%   returned.

%   Copyright 2022-2023 The MathWorks, Inc.
arguments
    fileName {char,string}
    label (1,1) string
    visualizeData = true;
end

% Load the pre-recorded dataset
datasetDir = which(fileName);
loadedData = load(datasetDir);
data = loadedData.data;
labels = categorical(repmat(label,size(data,ndims(data)),1));
timestamps = loadedData.timestamps;
disp(['Dimensions of the ' char(label) ' dataset (numSubcarriers x numPackets x numCaptures): ' '['  num2str(size(data)) ']'])

% Visualize the dataset
if visualizeData
    plotSamplesFromDataset(data,label);
end

%% Plot Samples from Dataset
    function plotSamplesFromDataset(data,mode)
        % Plot at most three random samples of the dataset
        inputData = abs(data); % Visualize only the magnitude of CSI
        numTotalCaptures = size(inputData,ndims(inputData));
        numPlots = min(3,numTotalCaptures);
        idxSelected = sort(randperm(numTotalCaptures,numPlots));

        T = tiledlayout(numPlots,2,"TileSpacing","compact");
        for j = 1:numPlots
            % Create plots
            % Plot 1 - CSI Image
            nexttile
            imagesc(inputData(:,:,idxSelected(j)).');
            colorbar;
            xlabel('Subcarriers');
            ylabel('Packets');
            title(['Raw CSI - Sample # ' num2str(idxSelected(j))]);

            % Plot 2 - Normalized CSI Periodogram
            nexttile
            imagesc(csi2periodogram(inputData(:,:,idxSelected(j))).');
            colorbar;
            clim([0 1]);
            xlabel('Spatial Index');
            ylabel('Temporal Index');
            title(['CSI Periodogram - Sample # ' num2str(idxSelected(j))]);
            title(T,['Random Samples of "', char(mode) '" Data']);
            set(gcf,'position',[0 0 600 500]);
        end
    end
end
clear;
clc;
useSDR = false; % Change it to true and use it
if useSDR
    % User-defined parameters
    rxsim.DeviceName    = "B210";
    rxsim.RadioGain     = 15; % Can be 'AGC Slow Attack', 'AGC Fast Attack', or an integer value. See relevant documentation for selected radio for valid values of radio gain.
    rxsim.ChannelNumber = 44; % Valid values for 5 GHz band are integers in range [1, 200]
    rxsim.FrequencyBand = 5; % in GHz

    % Set up SDR receiver objectda
    rx = hSDRReceiver(rxsim.DeviceName);
    rx.SampleRate = 20e6; % Configured for 20 MHz since this is beacon transmission bandwidth
    rx.Gain = rxsim.RadioGain;
    rx.CenterFrequency = wlanChannelFrequency(rxsim.ChannelNumber,rxsim.FrequencyBand);
    rx.ChannelMapping = 1;
    rx.OutputDataType = 'single';

    rxsim.SDRObj = rx;
end
if useSDR %#ok<*UNRCH>
    % User defined parameters
    rxsim.NumCaptures          = 500;
    rxsim.NumPacketsPerCapture = 8;
    rxsim.BeaconInterval       = 40; % in time units (TUs). The default value in typical APs is 100.
    rxsim.BeaconSSID           = "TP_Link_E3C5_5G"; % Optional

    % Calculated parameters
    rxsim.CaptureDuration = rxsim.BeaconInterval*milliseconds(1.024)*rxsim.NumPacketsPerCapture + milliseconds(5.5); % Add 5.5 ms for beacons located at the end of the waveform

    % SDR setup is complete
    disp(1)
    return % Stop execution
end
%%
if useSDR % Capture CSI with SDR
    [dataNoPresence,labelNoPresence,timestampNoPresence] = captureCSIDataset(rxsim,"no-presence");
else % No SDR hardware, load CSI dataset
    [dataNoPresence,labelNoPresence,timestampNoPresence] = loadCSIDataset("dataset-no-presence.mat","no-presence");
end
%%
if useSDR % Capture CSI with SDR
     [dataNoPresence,labelNoPresence,timestampNoPresence] = captureCSIDataset(rxsim,"presence");
    
else % No SDR hardware, load CSI dataset
    [dataPresence,labelPresence,timestampPresence] = loadCSIDataset("dataset-presence-right.mat","presence");
end
%%
trainingRatio =  0.8;
numEpochs = 10;
sizeMiniBatch = 8;

[trainingData,validationData,testData,imgInputSize,numClasses] = trainValTestSplit(useSDR,trainingRatio,dataNoPresence,labelNoPresence,dataPresence,labelPresence);

cnn = [
    imageInputLayer(imgInputSize,'Normalization','none')
    convolution2dLayer(3,8,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)

    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    dropoutLayer(0.1)
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

cnn = layerGraph(cnn);
disp(cnn.Layers)

% Definition of the training options
options = trainingOptions('adam', ...
    LearnRateSchedule='piecewise', ...
    InitialLearnRate=0.001, ... % learning rate
    MaxEpochs=numEpochs, ...
    MiniBatchSize=sizeMiniBatch, ...
    ValidationData=validationData, ...
    Shuffle='every-epoch', ...
    ExecutionEnvironment='auto',...
    Verbose=true);

% Train the network
trainedCNN = trainNetwork(trainingData,cnn,options);
disp(2)
%%
if useSDR % Predict movement from the live SDR captures
    sensingResults = livePresenceDetection(rxsim,trainedCNN,100);
else % Predict movement by using the test set
    sensingResults = testPresenceDetection(testData,trainedCNN);
end
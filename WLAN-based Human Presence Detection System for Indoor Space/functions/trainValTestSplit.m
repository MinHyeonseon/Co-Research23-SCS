function [trainData,valData,testData,imgInputSize,numClasses] = ...
    trainValTestSplit(useSDR,trainRatio,dataNoPresence,labelNoPresence,dataPresence,labelPresence)
%trainValTestSplit Splits the data into training, validation and test datasets
%   trainValTestSplit(useSDR,trainRatio,dataNoPresence,labelNoPresence,dataPresence,labelPresence)
%   takes the SDR captured or pre-recorded CSI captures (DATANOPRESENCE)
%   and (DATAPRESENCE) and their associated labels (LABELNOPRESENCE) and
%   (LABELPRESENCE) randomly splits them into training (TRAINDATA),
%   validation (VALDATA) and test (TESTDATA) datasets using SDR hardware
%   availability (USESDR) and user-defined training ratio (TRAINRATIO). The
%   retuned datasets are arrayDatastore objects.
%
%   DATANOPRESENCE and DATAPRESENCE are single complex
%   numSubcarriers-by-rxsim.NumPacketsPerCapture-by-rxsim.NumCaptures array
%   that contain the extracted CSI for "no-presence" and "presence"
%   labels.
%
%   LABELNOPRESENCE and LABELPRESENCE are rxsim.NumCaptures-by-1
%   categorical vectors that contain the labels correspond to
%   "no-presence" and "presence" data.

%   Copyright 2022 The MathWorks, Inc.

% Train/test data split
% size xData: numTimeFrames x numSubcarriers x numSnapshots
% size yData: numSnapshots x 1
xData = cat(3,dataNoPresence,dataPresence);
yData = cat(1,labelNoPresence,labelPresence);
numClasses = numel(categories(yData));

% Obtain the CSI periodogram
xData = csi2periodogram(abs(xData));

imgInputSize = size(xData,1:ndims(xData)-1); % the last dimension is batch

if useSDR
    valRatio = 1-trainRatio;
    testRatio = 0; % Cannot test using live captures, if SDR is enabled
else
    valRatio = (1-trainRatio)/2; % If pre-recorded dataset is used. Validation and test set sizes are equal
    testRatio = valRatio;

end

% Generate random train/validation/test set indices
[trainInd,valInd,testInd] = dividerand(size(xData,3),trainRatio,valRatio,testRatio);

% Train/Validation/Test dataset split
xTrain = xData(:,:,trainInd);
xValid = xData(:,:,valInd);
xTest = xData(:,:,testInd);

% Train/Validation/Test label split
yTrain = yData(trainInd);
yValid = yData(valInd);
yTest = yData(testInd);

% Convert training dataset into datastore
arrds = arrayDatastore(xTrain, "IterationDimension", 3);
labelds = arrayDatastore(yTrain, "IterationDimension", 1);
trainData = combine(arrds, labelds);

% Convert validation dataset into datastore
if ~isempty(valInd)
    arrds2 = arrayDatastore(xValid, "IterationDimension", 3);
    labelds2 = arrayDatastore(yValid, "IterationDimension", 1);
    valData = combine(arrds2, labelds2);
else
    valData = []; % No validation data
end

% Convert test dataset into datastore
arrds3 = arrayDatastore(xTest, "IterationDimension", 3);
labelds3 = arrayDatastore(yTest, "IterationDimension", 1);
testData = combine(arrds3, labelds3);

% Display data related information
disp(['CSI image input size: [',num2str(imgInputSize),']'])
disp(['Number of training images: ', num2str(numpartitions(trainData))])
end
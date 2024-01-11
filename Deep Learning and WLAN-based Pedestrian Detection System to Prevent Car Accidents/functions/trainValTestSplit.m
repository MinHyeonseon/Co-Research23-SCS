function [trainData,valData,testData,imgInputSize,numClasses] = ...
    trainValTestSplit_test2(useSDR,trainRatio,dataNoPresence,labelNoPresence,dataPresence,labelPresence, dataPresence2, labelPresence2)
%   trainValTestSplit 함수는 데이터를 훈련 데이터셋 / 테스트 데이터셋 으로 나눠준다.
%   trainValTestSplit(useSDR,trainRatio,dataNoPresence,labelNoPresence,dataPresence,labelPresence)
%   SDR 캡쳐 또는 미리 기록된 CSI 캡처를 가져온다.
%   SDR 캡처 또는 사전 기록된 CSI 캡처(DATAANOPRESENCE) 및 라벨(LABELNOPRESENCE)을 사용하여
%   무작위로 훈련(TREANDATA), 검증(VALDATA) 및 테스트(TESTDATA) 데이터 세트로 나눕니다.

%   복원된 데이터셋은 arrayDatastore 개체입니다.
%   dataPresence 및 dataNoPresence는
%   단일 복소수 numSubcarrier x rxsim.NumPacketsPerCapture x rxsim.NumCaptures 배열로,
%   "no-presence" 및 "presence" 레이블에 대한 추출된 CSI가 들어 있습니다.
%
%   LABELNOPRESENCE and LABELPRESENCE are rxsim.

% Train/test data split
% size xData: numTimeFrames x numSubcarriers x numSnapshots
% size yData: numSnapshots x 1
% cat: 배열 결합 
xData = cat(3,dataNoPresence,dataPresence, dataPresence2);      % 훈련 데이터
yData = cat(1,labelNoPresence,labelPresence, labelPresence2);   % 검증 데이터
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
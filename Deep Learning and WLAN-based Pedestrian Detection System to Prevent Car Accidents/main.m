clear;
clc;
useSDR = false; % You can skip this section if unchecked
if useSDR
    % User-defined parameters
    rxsim.DeviceName    = "B200";
    rxsim.RadioGain     = 15; % Can be 'AG1`C Slow Attack', 'AGC Fast Attack', or an integer value. See relevant documentation for selected radio for valid values of radio gain.
    rxsim.ChannelNumber = 40; % Valid values for 5 GHz band are integers in range [1, 200]
    rxsim.FrequencyBand = 5; % in GHz

    % Set up SDR receiver object
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
    rxsim.BeaconInterval       = 40; % in time unsits (TUs). The default value in typical APs is 100.
    rxsim.BeaconSSID           = "TP-Link_E3C5_5G"; % Optional

    % Calculated parameters
    rxsim.CaptureDuration = rxsim.BeaconInterval*milliseconds(1.024)*rxsim.NumPacketsPerCapture + milliseconds(5.5); % Add 5.5 ms for beacons located at the end of the waveform

    % SDR setup is complete
    disp(1)
    return % Stop execution
end
%%
if useSDR % Capture live CSI with SDR
    [dataNoPresence,labelNoPresence,timestampNoPresence] = captureCSIDataset(rxsim,"no-presence");
       
else % No SDR hardware, load CSI dataset

    [dataNoPresence,labelNoPresence,timestampNoPresence] = loadCSIDataset("no-presence.mat","no-presence");
end
disp(21)
%%
if useSDR % Capture CSI with SDR
    [dataPresence,labelPresence,timestampPresence] = captureCSIDataset(rxsim,"presence");
     
else % No SDR hardware, load CSI dataset
    [dataPresence,labelPresence,timestampPresence] = loadCSIDataset("presence-left.mat","presence-left");
end
disp(22)
%% 2-3.  Create "presence2" Data

if useSDR % SDR로 실시간 캡쳐하기  ->  Presence 데이터셋 만듦
    [dataPresence2,labelPresence2,timestampPresence2] = captureCSIDataset(rxsim,"presence2");
else % SDR 사용하지 않을거면 이미 만들어진 Presence 데이터셋을 로드하기
    [dataPresence2,labelPresence2,timestampPresence2] = loadCSIDataset("presence-right.mat","presence-right");
end


disp('Step 2-3');
%% Step 3: Create and Train CNN

trainingRatio =  0.8;
numEpochs = 10;
sizeMiniBatch = 8;


% classes = ["No-Presence" "Presence1" "Presence2"];


[trainingData,validationData,testData,imgInputSize,numClasses] = ...
    trainValTestSplit(useSDR,trainingRatio,dataNoPresence,labelNoPresence,dataPresence, ...
    labelPresence, dataPresence2,labelPresence2);

% 컨볼루션 신경망 구조 정의
cnn = [
    %% 이미지 입력 레이어
    % 입력 이미지 데이터의 크기와 정규화 방법을 정의.
    % Normalization : 입력 데이터를 정규화 할지 말지. none 이면 정규화되지 않음
    imageInputLayer(imgInputSize,'Normalization','none')

    %% 컨볼루션 레이어
    % 입력 이미지에서 특징을 추출하는 역할
    % 3x3 크기의 컨볼루션 필터를 사용, 출력 채널 수는 8
    % 필터를 이동하면서 입력 이미지에서 특징을 감지, 활성화 맵을 생성
    % padding이 same으로 설정되어 입력과 출력의 크기가 동일하게 유지
    convolution2dLayer(3,8,'Padding','same')


    %% 배치 정규화 레이어
    % 배치 정규화: 훈련 중 네트워크의 안정성을 향상시키고 수렴 속도를 높이는 데 도움이 되는 기술
    % 컨볼루션 레이어의 출력을 정규화하고 스케일링 및 이동을 수행
    batchNormalizationLayer

    %% 활성화 함수 레이어
    % 컨볼루션 레이어의 출력에 비선형성을 추가함
    % ReLU함수가 주로 사용되며 음수 입력을 0으로 변황하고 양수 입력을 그대로 유지
    reluLayer

    %% 맥스 풀링 레이어
    % 주로 컨볼루션 레이어 다음에 배치되는 레이어. 범위 내의 픽셀 중 대표값을 추출하는 방식으로 특징을 추출
    % 이미지를 다운샘플링하여 공간 해상도를 줄이는 데 사용됨
    % 입력 데이터를 격자로 분할하고 각 격자에서 최댓값을 추출하여 출력함
    % stride 매개변수: 풀링 격자가 얼마나 이동할지를 결정
    maxPooling2dLayer(2,'Stride',2)

    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)

    convolution2dLayer(3,256,'Padding','same')
    batchNormalizationLayer
    reluLayer

    convolution2dLayer(3,256,'Padding','same')
    batchNormalizationLayer
    reluLayer

    convolution2dLayer(3,256,'Padding','same')
    batchNormalizationLayer
    reluLayer

    %% 드롭아웃 레이어
    % 과적합을 방지하기 위한 정규화 기법
    % 훈련 중에 임의의 뉴런을 비활성화시켜 모델을 더 견고하게 만듦
    % 10퍼센트 적용됨
    dropoutLayer(0.1)

    %% 완전 연결 레이어
    % 이전 레이어의 출력을 평탄화하고 다음 레이어에 연결함
    % 여기서는 출력 클래스 수에 맞게 뉴런을 구성한 완전 연결 레이어
    fullyConnectedLayer(numClasses)

    %% 소프트맥스 레이어
    % 다중 클래스 분류 문제에서 출력 클래스의 확률 분포를 계산
    % 출력 뉴런의 값은 클래스에 대한 확률을 나타냄
    softmaxLayer
    classificationLayer];
% classificationLayer('Classes', classes)];

cnn = layerGraph(cnn);
disp(cnn.Layers)

% Definition of the training options
% 확률적 경사하강법의 디폴트 설정
options = trainingOptions('adam', ...
    LearnRateSchedule='piecewise', ...
    InitialLearnRate=0.001, ... % 학습률
    MaxEpochs=numEpochs, ...
    MiniBatchSize=sizeMiniBatch, ...
    ValidationData=validationData, ...
    Shuffle='every-epoch', ...
    ExecutionEnvironment='auto',...
    Verbose=true);

% Train the network
% 원문: net = trainNetwork(imdsTrain,layers,options);
trainedCNN = trainNetwork(trainingData,cnn,options);

disp('Step 3');
%%
if useSDR % Predict movement from the live SDR captures
    sensingResults = livePresenceDetection(rxsim,trainedCNN,100);
else % Predict movement by using the test set
    sensingResults = testPresenceDetection(testData,trainedCNN);
end
disp(4)
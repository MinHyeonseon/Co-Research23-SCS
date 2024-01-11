function sensingAccuracy = testPresenceDetection(testData,trainedCNN)
%testPresenceDetection Visualizes the human presence detection performance of the trained network.
%   testPresenceDetection(testData,trainedCNN) predicts the human presence
%   from unseen test data (TESTDATA) using the trained network
%   (TRAINEDCNN). The detection accuracy is calculated and returned in a
%   scalar parameter (SENSINGACCURACY).

%   Copyright 2022 The MathWorks, Inc.

predictionVector = classify(trainedCNN,testData);
groundTruthVector = readall(testData);
groundTruthVector = cat(1,groundTruthVector{:,2});

% Calculate and plot the performance
figure;
cm = confusionchart(groundTruthVector,predictionVector,Normalization="row-normalized");
sensingAccuracy = sum(diag(cm.NormalizedValues))/sum(cm.NormalizedValues(:))*100; % accuracy calculation
cm.Title = ['Sensing Accuracy = ' num2str(sensingAccuracy) '%'];
end
% function dataSetTrainTest = dataSetTrainTestMaker(dataSetIn, separationRatioTraining)
% divide a dataset into train and test set which contain disjoint samples.
% and package them for direct usage in the MLFramework
% - dataSetIn: the base data set
% - separationRatioTraining: e.g. 0.75 for 75 % to training set and
%      25 % in testing set
% Note that this is made per class - so that a fair subdivision is achieved
%

function dataSetTrainTest = dataSetTrainTestMaker(dataSetIn, separationRatioTraining)

[dataSetTrain, dataSetTest] = dataSetTrainTestSeparation(dataSetIn, separationRatioTraining);

dataSetTrainTest = struct;
dataSetTrainTest.dataSetFull = dataSetIn;
dataSetTrainTest.dataSetTrain = dataSetTrain;
dataSetTrainTest.dataSetTest = dataSetTest;
dataSetTrainTest.dataSetName = dataSetIn.dataSetName;
dataSetTrainTest.dataSetNameSuffix = [dataSetIn.dataSetName];
dataSetTrainTest.divisionTrainTest = separationRatioTraining;


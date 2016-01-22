% function dataSetTrainTest = makeTrainTestDataSet(dataSetIn, separationRatioTraining)
% divide a standard dataset into a training set and a test set
%
% - dataSetIn: the base data set
% - separationRatioTraining: e.g. 0.75 for 75 % to training set and
%      25 % in testing set

function dataSetTrainTest = makeTrainTestDataSet(dataSetIn, separationRatioTraining)

    [dataSetTrain, dataSetTest] = dataSetTrainTestSeparation(dataSetIn, separationRatioTraining);
    
    dataSetTrainTest = struct;
    dataSetTrainTest.dataSetFull = dataSetIn;
    dataSetTrainTest.dataSetTrain = dataSetTrain;
    dataSetTrainTest.dataSetTest = dataSetTest;
    dataSetTrainTest.dataSetName = dataSetIn.dataSetName;
    dataSetTrainTest.dataSetNameSuffix = [dataSetIn.dataSetName];
    dataSetTrainTest.divisionTrainTest = separationRatioTraining;

    
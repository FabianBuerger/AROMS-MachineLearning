% function [dataSetTrain, dataSetTest] = dataSetTrainTestSeparation(dataSetIn, separationRatioTraining)
% divide a dataset into train and test set which contain disjoint samples.
% - dataSetIn: the base data set
% - separationRatioTraining: e.g. 0.75 for 75 % to training set and
%      25 % in testing set
% Note that this is made per class - so that a fair subdivision is achieved
%

function [dataSetTrain, dataSetTest] = dataSetTrainTestSeparation(dataSetIn, separationRatioTraining)


dataSetTrain = dataSetIn;
dataSetTrain.targetClasses = [];

featNames = fieldnames(dataSetIn.instanceFeatures);
for iFeat = 1:numel(featNames)
    dataSetTrain.instanceFeatures = setfield(dataSetTrain.instanceFeatures,featNames{iFeat},[]);
end
dataSetTest = dataSetTrain;

nClasses = numel(dataSetIn.classNames);

for iClass = 1:nClasses
    instancesIndizesThatClass = find(dataSetIn.targetClasses==iClass);
    nBefore = numel(instancesIndizesThatClass);
    nSamplesClassTrain = max(1, min(nBefore-1,  round(separationRatioTraining*nBefore)   )   );
    nSamplesClassTest = nBefore-nSamplesClassTrain;

    subsetSelTrain = randsample(numel(instancesIndizesThatClass),nSamplesClassTrain);
    subsetTrain = instancesIndizesThatClass(subsetSelTrain);
    subsetTest = instancesIndizesThatClass;
    subsetTest(subsetSelTrain) = [];
    
    dataSetTrain.targetClasses = [dataSetTrain.targetClasses; iClass*ones(numel(subsetTrain),1)];
    dataSetTest.targetClasses = [dataSetTest.targetClasses; iClass*ones(numel(subsetTest),1)];
    
    featNames = fieldnames(dataSetIn.instanceFeatures);
    for iFeat = 1:numel(featNames)
        cFeat = featNames{iFeat};
        featDataAll = getfield(dataSetIn.instanceFeatures,cFeat);
        featDataSubSetTrain = featDataAll(subsetTrain,:);
        featDataSubSetTest = featDataAll(subsetTest,:);
        
        featReady = getfield(dataSetTrain.instanceFeatures,cFeat);
        featReadyNew = [featReady;featDataSubSetTrain];
        dataSetTrain.instanceFeatures = setfield(dataSetTrain.instanceFeatures,cFeat,featReadyNew);
        
        featReady = getfield(dataSetTest.instanceFeatures,cFeat);
        featReadyNew = [featReady;featDataSubSetTest];
        dataSetTest.instanceFeatures = setfield(dataSetTest.instanceFeatures,cFeat,featReadyNew);        
    end
end









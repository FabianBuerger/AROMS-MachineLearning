% function setOut = makeTrainTestDataSetFeatureSelection(dataSetTrainTest, featureSubSets,suffixNameList)
% make train test datasets with different feature subsets (as cell array of cell
% strings)

function dataSetsOut = makeTrainTestDataSetFeatureSelection(dataSetTrainTest, featureSubSets, suffixNameList)


    dataSetsOut = {};
    
    for ii=1:numel(featureSubSets)
        cDataSetTT = dataSetTrainTest;
        cFeatSubset = featureSubSets{ii};
        
        if numel(suffixNameList) == numel(featureSubSets)
            cDataSetTT.dataSetNameSuffix = suffixNameList{ii};
        end
        cDataSetTT.dataSetFull=applyFeatureSubSet(cDataSetTT.dataSetFull,cFeatSubset);    
        cDataSetTT.dataSetTrain=applyFeatureSubSet(cDataSetTT.dataSetTrain,cFeatSubset);    
        cDataSetTT.dataSetTest=applyFeatureSubSet(cDataSetTT.dataSetTest,cFeatSubset);    
        
        dataSetsOut{end+1} = cDataSetTT;
    end
    
    
    
function dataSet=applyFeatureSubSet(dataSet,featSubSet)    
    allFeatData = dataSet.instanceFeatures;
    dataSet.instanceFeatures = struct;
    for ii=1:numel(featSubSet)
        cFeatName = featSubSet{ii};
        
        cData = getfield(allFeatData,cFeatName);
        dataSet.instanceFeatures = setfield(dataSet.instanceFeatures,cFeatName,cData);
    end
    
        
    
%     [dataSetTrain, dataSetTest] = dataSetTrainTestSeparation(dataSetIn, separationRatioTraining);
%     
%     dataSetTrainTest = struct;
%     dataSetTrainTest.dataSetFull = dataSetIn;
%     dataSetTrainTest.dataSetTrain = dataSetTrain;
%     dataSetTrainTest.dataSetTest = dataSetTest;
%     dataSetTrainTest.dataSetName = dataSetIn.dataSetName;
%     dataSetTrainTest.dataSetNameSuffix = [dataSetIn.dataSetName];
%     dataSetTrainTest.divisionTrainTest = separationRatioTraining;

    


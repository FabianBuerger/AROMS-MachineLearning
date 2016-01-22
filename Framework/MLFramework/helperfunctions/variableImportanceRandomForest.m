% function varImportance = variableImportanceRandomForest(dataSet, nTrees)

% estimate variable importance
% -dataSet: struct with instanceFeatures    
% -nTrees: number of bagged trees (e.g. 100)

function varImportance = variableImportanceRandomForest(dataSet, nTrees)

    peFeatSel = PipelineElemFeatureSelection();
    
    if ~isfield(dataSet,'totalDimensionality')
        dataSet = getTotalDimensionality(dataSet);
    end
    % full set
    featureSubSet = ones(1,dataSet.totalDimensionality);
    featureMatrix = peFeatSel.applySubSetSelection(dataSet.instanceFeatures,featureSubSet);

    treeBagger  = TreeBagger(nTrees, featureMatrix, dataSet.targetClasses,'Method', 'classification','OOBVarImp','on');
    varImportanceIncreasePredError = treeBagger.OOBPermutedVarDeltaError;
    minVal = min(varImportanceIncreasePredError);
    maxVal = max(varImportanceIncreasePredError);
    varImportance = (varImportanceIncreasePredError-minVal)/(maxVal - minVal);
              
end




function dataSet = getTotalDimensionality(dataSet)
    totalDimensionality = 0;
    % convert all fields to double values
    for iFeat = 1:numel(dataSet.featureNames)
       cField = dataSet.featureNames{iFeat};
       cData = double(getfield(dataSet.instanceFeatures,cField));
       dataSet.instanceFeatures = setfield(dataSet.instanceFeatures,cField,cData);
       totalDimensionality = totalDimensionality + size(cData,2);
    end
    dataSet.totalDimensionality = totalDimensionality;
end
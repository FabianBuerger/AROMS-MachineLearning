

% apply the global cross validation index set on the current dataSet
function crossValData = applyCrossValidationIndexSet(dataSet, crossValIndexSet)
    crossValData = struct;
    crossValData.dataTrain = struct;
    crossValData.dataTrain.featureMatrix = dataSet.featureMatrix(crossValIndexSet.indicesTraining,:);
    crossValData.dataTrain.targetClasses = dataSet.targetClasses(crossValIndexSet.indicesTraining);
    
    crossValData.dataTest = struct;
    crossValData.dataTest.featureMatrix = dataSet.featureMatrix(crossValIndexSet.indicesTesting,:);
    crossValData.dataTest.targetClasses = dataSet.targetClasses(crossValIndexSet.indicesTesting);
end


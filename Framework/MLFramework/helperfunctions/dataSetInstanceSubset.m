% select index subset of dataset 
%
function dataSet = dataSetInstanceSubset(dataSet, subsetIndices)

instanceFeatures = fieldnames(dataSet.instanceFeatures);
for ii = 1:numel(instanceFeatures)
    cFeature = instanceFeatures{ii};
    data1 = dataSet.instanceFeatures.(cFeature);
    data1=data1(subsetIndices,:);
    dataSet.instanceFeatures.(cFeature) = data1;
end

dataSet.targetClasses = dataSet.targetClasses(subsetIndices);
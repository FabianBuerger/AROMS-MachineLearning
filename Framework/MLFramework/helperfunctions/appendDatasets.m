% append the data of 2 datasets (must have the same structure/features
%
function dataSetCombined = appendDatasets(dataSet1, dataSet2)
dataSetCombined = dataSet1;

instanceFeatures = fieldnames(dataSet1.instanceFeatures);
for ii = 1:numel(instanceFeatures)
    cFeature = instanceFeatures{ii};
    data1 = dataSet1.instanceFeatures.(cFeature);
    data2 = dataSet2.instanceFeatures.(cFeature);
    dataFused = [data1;data2];
    dataSetCombined.instanceFeatures.(cFeature) = dataFused;
end

dataSetCombined.targetClasses = [dataSet1.targetClasses;dataSet2.targetClasses];
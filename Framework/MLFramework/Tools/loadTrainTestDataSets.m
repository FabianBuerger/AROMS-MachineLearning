% function dataSetList = loadTrainTestDataSets(fileNames)
% load datasets with test train subdivision from file list

function dataSetList = loadTrainTestDataSets(fileNames)

dataSetList = {};

for ii= 1:numel(fileNames)
    cFile = fileNames{ii};
    dsData = load(cFile);
    dataSetList{end+1} = dsData.dataSetTrainTest;
end

% function crossValSets = generateCrossValidationIndexSetsDependency(numberSamples, kFold, crossValidationInstanceDependencyInformation)
% Divide a training set of numberSamples into kFold cross validation sets.
% Note: just the index 
% 
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function crossValSets = generateCrossValidationIndexSetsDependency(numberSamples, kFold, crossValidationInstanceDependencyInformation)

uniqueItems = crossValidationInstanceDependencyInformation.indexInfoUnique;
indexInfo = crossValidationInstanceDependencyInformation.indexInfo;
crossValSets = generateCrossValidationIndexSets(numel(uniqueItems), kFold);

% get real lables
for ii=1:numel(crossValSets)
    division = crossValSets{ii};
    indicesTraining = division.indicesTraining;
    indicesTesting = division.indicesTesting;
    
    division.indicesTraining = findIndicesForIndependentIndices(indexInfo,division.indicesTraining);
    division.indicesTesting = findIndicesForIndependentIndices(indexInfo,division.indicesTesting);
    crossValSets{ii} = division;
end


function indicesDependent = findIndicesForIndependentIndices(indexInfo,indices)
indicesDependent = [];
for ii=1:numel(indices)
    cIndex = indices(ii);
    dependentIdxFind = find(indexInfo==cIndex);
    indicesDependent = [indicesDependent;dependentIdxFind];
end


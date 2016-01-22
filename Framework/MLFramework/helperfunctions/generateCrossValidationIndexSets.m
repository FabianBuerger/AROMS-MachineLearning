% function crossValSets = generateCrossValidationIndexSets(numberSamples, kFold)
% Divide a training set of numberSamples into kFold cross validation sets.
% Note: just the index 
% 
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function crossValSets = generateCrossValidationIndexSets(numberSamples, kFold)
crossValSets = cell(kFold,1);

%shuffle matrix indices
rowIndicesShuffle = randperm(numberSamples);

validationSetIndex = [1:numberSamples]';
validationSetSize = double(numberSamples)/double(kFold);
validationSetIndex = ceil(validationSetIndex/validationSetSize);
validationSetIndex = min(max(1,validationSetIndex),kFold);
for cvIndex = 1:kFold
    cKFoldSelection = validationSetIndex==cvIndex;
    
    % get index lists
    cRandIndicesTraining = rowIndicesShuffle;
    cRandIndicesTraining(cKFoldSelection) = [];
    cRandIndicesTesting = rowIndicesShuffle;
    cRandIndicesTesting(~cKFoldSelection) = [];    
    
    % append to list
    ds = struct;
    ds.indicesTraining = cRandIndicesTraining;
    ds.indicesTesting = cRandIndicesTesting;
    crossValSets{cvIndex} = ds;                         
end
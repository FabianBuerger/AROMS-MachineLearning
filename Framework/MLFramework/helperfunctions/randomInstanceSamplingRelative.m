% function dataSetOut = randomInstanceSamplingRelative(dataSetIn, nSamplesPerClass)
% sub sample from each class such that each class has subSampleRatio
% (between 0 and 1) of its original data instances

function dataSetOut = randomInstanceSamplingRelative(dataSetIn, subSampleRatio)

% 
%             dataSet = struct;
%             dataSet.dataSetName = dataSetName;
%             dataSet.instanceFeatures = struct;
%             dataSet.classNames = classNames; 
%targetClasses


dataSetOut = dataSetIn;
dataSetOut.targetClasses = [];

featNames = fieldnames(dataSetOut.instanceFeatures);
for iFeat = 1:numel(featNames)
    dataSetOut.instanceFeatures = setfield(dataSetOut.instanceFeatures,featNames{iFeat},[]);
end

nClasses = numel(dataSetIn.classNames);

for iClass = 1:nClasses
    instancesIndizesThatClass = find(dataSetIn.targetClasses==iClass);
    nBefore = numel(instancesIndizesThatClass);
    nSamplesClass = max(1, min(nBefore,  round(subSampleRatio*nBefore)   )   );
    if numel(instancesIndizesThatClass) > nSamplesClass
        subsetSel = randsample(numel(instancesIndizesThatClass),nSamplesClass);
        subset = instancesIndizesThatClass(subsetSel);
    else
        % too few: take all
        subset = instancesIndizesThatClass;
    end
    dataSetOut.targetClasses = [dataSetOut.targetClasses; iClass*ones(numel(subset),1)];
    
    featNames = fieldnames(dataSetIn.instanceFeatures);
    for iFeat = 1:numel(featNames)
        cFeat = featNames{iFeat};
        featDataAll = getfield(dataSetIn.instanceFeatures,cFeat);
        featDataSubSet = featDataAll(subset,:);
        
        featReady = getfield(dataSetOut.instanceFeatures,cFeat);
        featReadyNew = [featReady;featDataSubSet];
        dataSetOut.instanceFeatures = setfield(dataSetOut.instanceFeatures,cFeat,featReadyNew);
    end
end










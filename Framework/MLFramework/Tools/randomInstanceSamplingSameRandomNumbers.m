% function randomInstanceSampling(dataSetIn, nSamplesPerClass)
% sub sample from each class such that each class has nSamples
% instances.
% if less samples available, all will be used

function dataSetOut = randomInstanceSamplingSameRandomNumbers(dataSetIn, nSamplesPerClass)

% make predictable random numbers
sd=58445845;
rng(sd);

dataSetOut = dataSetIn;
dataSetOut.targetClasses = [];

featNames = fieldnames(dataSetOut.instanceFeatures);
for iFeat = 1:numel(featNames)
    dataSetOut.instanceFeatures = setfield(dataSetOut.instanceFeatures,featNames{iFeat},[]);
end

nClasses = numel(dataSetIn.classNames);

for iClass = 1:nClasses
    instancesIndizesThatClass = find(dataSetIn.targetClasses==iClass);
    if numel(instancesIndizesThatClass) > nSamplesPerClass
        subsetSel = randsample(numel(instancesIndizesThatClass),nSamplesPerClass);
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

% back to real random numbers
rng('shuffle')









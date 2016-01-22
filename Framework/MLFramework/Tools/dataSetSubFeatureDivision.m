%function dataSetOut = dataSetSubFeatureDivision(dataSetIn, featureNames)
% Divide features with multiple dimensions into single features such as the
% number of feature vectors become the number of concatenated feature
% dimensions. This affects the feature selection.
% Additionally, the string set featureNames defines a subset
% on which the division is applied.
%
%

function dataSetOut = dataSetSubFeatureDivision(dataSetIn, featureNames)

dataSetOut = dataSetIn;

featureSplitInfo = struct;

% if only one arg, use all features for division
if nargin == 1
    featureNames = fieldnames(dataSetIn.instanceFeatures);
end

featureSplitInfo.originalFeatureNames = featureNames;
featureSplitInfo.originalDimensionalities = [];
featureSplitInfo.splitNecessary = 0;
featureSplitMapping = {};

totalFeatureIndex = 0;
for iFeat = 1:numel(featureNames)
    cName = featureNames{iFeat};
    if isfield(dataSetOut.instanceFeatures,cName)
        cData = dataSetOut.instanceFeatures.(cName);
        nDim = size(cData,2);
        featureSplitInfo.originalDimensionalities(end+1) = nDim;
        if nDim > 1
           nzeros = ceil(log(nDim+1)/log(10)); 
           featureSplitInfo.splitNecessary = 1; 
           % only split if more than 1 dimension
           % 1. remove old field
           dataSetOut.instanceFeatures = rmfield(dataSetOut.instanceFeatures,cName);
           % now add single channels
           for iChannel = 1:nDim
               newName = sprintf(['%s_%0' num2str(nzeros) 'd'],cName,iChannel);
               dataSetOut.instanceFeatures = setfield(dataSetOut.instanceFeatures,newName,cData(:,iChannel));     
               totalFeatureIndex = totalFeatureIndex+1;
               item = nameMappingItem(newName,cName,iFeat,iChannel,nDim,totalFeatureIndex);
               featureSplitMapping{end+1} = item;
           end
        else
            totalFeatureIndex = totalFeatureIndex+1;
            item = nameMappingItem(cName,cName,iFeat,1,nDim,totalFeatureIndex);
            featureSplitMapping{end+1} = item;
        end
    else
        warning(sprintf('Dataset division warning: Field %s does not exist. Ignoring.',cName));
    end
end

featureSplitInfo.featureSplitMapping = featureSplitMapping;
dataSetOut.featureSplitInfo = featureSplitInfo;




function item = nameMappingItem(splitName,origName,origFeatureIndex, origSubFeatureIndex, origDim,totalIndex)
    item = struct;
    item.splitName = splitName;
    item.origName = origName;
    item.origSubFeatureIndex = origSubFeatureIndex;
    item.origFeatureIndex = origFeatureIndex;
    item.origDim = origDim;
    item.splitIndex = totalIndex;




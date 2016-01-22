% make a feature matrix from concatenated feature vectors given as struct;
%
function featureMatrix = featureMatrixFromFeatureStruct(instanceFeatures)
    concatenatedDimensions = 0;
    featureSet = fieldnames(instanceFeatures);
    for iFeatSel = 1:numel(featureSet)
        cName = featureSet{iFeatSel};
        cFeatData = instanceFeatures.(cName);
        concatenatedDimensions = concatenatedDimensions + size(cFeatData,2);
        nSamples = size(cFeatData,1);
    end

    featureMatrix = zeros(nSamples,concatenatedDimensions);

    % fill the columns of the feature matrix
    cColIndex = 1;
    for iFeatSel = 1:numel(featureSet)
        cName = featureSet{iFeatSel};
        cFeatData = instanceFeatures.(cName);
        featureMatrix(:,cColIndex: (cColIndex+size(cFeatData,2)-1)) = cFeatData;
        cColIndex = cColIndex + size(cFeatData,2);
    end       

end


% function [featureMatrix] = featurePreProc_transform(featureMatrix, mapping)
% Perform preprocessing according to model

function [featureMatrix] = featurePreProc_transform(featureMatrix, mapping)

    nTotalSamples = size(featureMatrix,1);

    if strcmp(mapping.method,'featureScalingStatistically')
        
        featureMeansRep = repmat(mapping.means,[nTotalSamples,1]);
        featureStdsRep =  repmat(mapping.stds,[nTotalSamples,1]);
        featureMatrix = (featureMatrix-featureMeansRep)./featureStdsRep;     

    elseif strcmp(mapping.method,'featureScaling01')
        featureMinsRep = repmat(mapping.featureMins,[nTotalSamples,1]);
        featureDeltasRep = repmat(mapping.featureDeltas,[nTotalSamples,1]);
        featureMatrix = (featureMatrix-featureMinsRep)./featureDeltasRep;    

    elseif strcmp(mapping.method,'preWhitening')
         featureMatrix = real(whitening_transform(featureMatrix, mapping));
         
    elseif strcmp(mapping.method,'normalization')
        for iRow = 1:nTotalSamples
            cNorm = norm(featureMatrix(iRow,:));
            if cNorm < 10*eps
                cNorm = 1;
            end
            featureMatrix(iRow,:) = featureMatrix(iRow,:)/cNorm;
        end
    else
        % no transform
    end



    
    
    
    
 
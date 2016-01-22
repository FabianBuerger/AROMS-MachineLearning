% function [mapping] = featurePreProc_compute(featureMatrix, featurePreProcessingMethod)
% Compute Feature PreProcessing mapping information

function [mapping] = featurePreProc_compute(featureMatrix, featurePreProcessingMethod)
mapping = struct;

if strcmp(featurePreProcessingMethod,'featureScalingStatistically')
    mapping.method = 'featureScalingStatistically'; 
    
    mapping.means = mean(featureMatrix,1);
    mapping.stds = std(featureMatrix,0,1);
    % too small stds values are bad for division!
    mapping.stds(abs(mapping.stds) <= 10*eps) = 1;
    
elseif strcmp(featurePreProcessingMethod,'featureScaling01')
    mapping.method = 'featureScaling01';    
    mapping.featureMins = min(featureMatrix,[],1);
    mapping.featureMaxs = max(featureMatrix,[],1); 
    mapping.featureDeltas = mapping.featureMaxs-mapping.featureMins;
    % too small stds values are bad for division!
    mapping.featureDeltas(mapping.featureDeltas<10*eps) = 1;   
    
elseif strcmp(featurePreProcessingMethod,'preWhitening')
    [mappedX, mapping] = whitening_compute(featureMatrix);
    mapping.method = 'preWhitening';
    if any(isnan(mapping.W(:)))
        error('prewhitening contains NAN');
    end
    
elseif strcmp(featurePreProcessingMethod,'normalization')
    mapping.method = 'normalization';    
    % nothing to do now as all vectors are scaled individually
    
else
    % no pre precessing
    mapping.method = 'none';
end




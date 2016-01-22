% function subSet = featureSubSetFromBitString(bitString, fullFeatureSet)
% Get feature string from binary bitstring and full feature set. The order
% has to be the same!
%
function subSet = featureSubSetFromBitString(bitString, fullFeatureSet)
    if numel(bitString) == numel(fullFeatureSet) 
        subSet = fullFeatureSet(bitString);
    else
        subSet = {};
        error('Feature Bitstring and Feature list not same length')
    end
end



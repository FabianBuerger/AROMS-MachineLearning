% function bitString = bitStringFromFeatureSubSet(subSet, fullFeatureSet)
% Get a logical bit string from feature subset.

function bitString = bitStringFromFeatureSubSet(subSet, fullFeatureSet)
    bitString = FrequencyCounter.getBinaryItemList(subSet, fullFeatureSet);


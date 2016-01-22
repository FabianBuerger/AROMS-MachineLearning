% function evoOptMutationParams = getStandardMutationParameters()
% get standard values for mutation within the framework
%

function evoOptMutationParams = getStandardMutationParameters()

    evoOptMutationParams = struct;
    
    evoOptMutationParams.probMutationBitStringBitFlip = 0.1;  % probab. for each bit in bit string to flip
    evoOptMutationParams.probMutationSet = 0.2;  % probab. that item of a set will be set to a random item
    
    % numerical variables dynamic adapted sigma
    evoOptMutationParams.probMutationStdAdaptiveRangePercentage = 0.2;  % DYNAMIC percentage of range for std for numerical values
    
    



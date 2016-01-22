% function [mappedX] = whitening_transform(X, mapping)
% Perform (Pre) Whitening

function [mappedX] = whitening_transform(X, mapping)


    mappedX = bsxfun(@minus, X, mapping.mean);
    mappedX = mappedX*mapping.W;
        
        
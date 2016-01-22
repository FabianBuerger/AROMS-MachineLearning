% function [mappedX, mapping] = whitening_compute(X)
% Perform (Pre) Whitening

function [mappedX, mapping] = whitening_compute(X)

    mapping = struct;
    mu_X = mean(X, 1);
    X = bsxfun(@minus, X, mu_X);
    mappedX = X / sqrtm(cov(X));
    W = X \ mappedX;   
    mapping.mean = mu_X;
    mapping.W = W;
        
        
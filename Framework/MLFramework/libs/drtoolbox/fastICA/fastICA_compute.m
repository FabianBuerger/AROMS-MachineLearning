% function [mappedX, mapping] = fastICA_compute(X,no_dims)
% compute mapping of fast ICA

function [mappedX, mapping] = fastICA_compute(X,no_dims)

    mapping = struct;
    mapping.name = 'FastICA';
    mapping.mean = mean(X, 1);
    
    [icasig, A, W] = fastica(X,'numOfIC',no_dims,'verbose','off');
    
    M = icasig';
    
    
    mappedX = bsxfun(@minus, X, mapping.mean) * M;
    
    % Store information for out-of-sample extension
    mapping.M = M;
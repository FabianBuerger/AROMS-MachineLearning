% function values = expRange(base,expRange)
% get an exponential range of values like colon operator:
% exponentialRange(10,[1 2 3]) = [10^1 10^2 10^3]
%
function values = expRange(base,expValues)
    values = zeros(1,numel(expValues));
    for ii=1:numel(expValues)
        exponent = expValues(ii);
        values(ii) = base^exponent;
    end
end


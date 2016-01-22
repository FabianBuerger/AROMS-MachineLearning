% calculate weighted average of values with given weights
%
function result = weightedAverage(values, weights)

result = sum(weights(:).*values(:));
result = result / sum(weights(:));
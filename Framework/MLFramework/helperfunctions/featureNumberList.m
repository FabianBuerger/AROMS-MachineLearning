% cellOut = featureNumberList(featureName, nItems, leadingZeros)
% get a list of feature names with suffix numbers
%
function cellOut = featureNumberList(featureName, nItems, leadingZeros)
cellOut = cell(1,nItems);
for ii=1:nItems
    if leadingZeros > 0
        str = sprintf(['%s%0' num2str(leadingZeros) 'd'],featureName,ii);
    else
        str = sprintf('%s%d',featureName,ii);
    end
    cellOut{ii} = str;
end

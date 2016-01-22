

function [bins,centers] = customHist(values,minVal,maxVal,nBins)
bins = zeros(1,nBins);
centers = linspace(minVal,maxVal,nBins);

for ii=1:numel(values)
    cVal = values(ii);
    indices = find(cVal<=centers);
    if numel(indices) > 0
        binNr = indices(1);
    else
        binNr = nBins;
    end
    bins(binNr) = bins(binNr)+1;
end
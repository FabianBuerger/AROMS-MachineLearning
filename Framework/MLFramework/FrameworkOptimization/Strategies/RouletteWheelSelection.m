% function indexSelection =  RouletteWheelSelection(probabilityValues)
% perform Roulette Wheel Selection. Given array of probabilityValues
% e.g. probabilityValues = [0.1 0.8 0.2] the function draws an index in
% range 1..numel(probabilityValues) according to the weight in 
% probabilityValues.
%
function indexSelection =  RouletteWheelSelection(probabilityValues)

indexSelection = 1;
nItems = numel(probabilityValues);
cumSumValues = cumsum(probabilityValues);
cumSumValuesNormed = cumSumValues/cumSumValues(end);

cRandVal = rand();
tmp = cumSumValuesNormed >= cRandVal;

indexSelection = find(tmp,1,'first');

if numel(indexSelection) == 0
    indexSelection = 1;
end

indexSelection = max(1,min(nItems,indexSelection));
    
    

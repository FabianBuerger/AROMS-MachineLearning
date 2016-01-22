% probabilityValues =  scaleFitnessValues(probabilityValues)
% These weights will be rescaled to [startVal, endVal]
%
function probabilityValues =  scaleFitnessValues(probabilityValues, startVal, endVal)

maxVal = max(probabilityValues);
minVal = min(probabilityValues);

w=endVal-startVal;
deltaFit = (maxVal-minVal);
if abs(deltaFit) < 0.0001
    deltaFit = 1;
end
probabilityValues = (probabilityValues-minVal)/deltaFit;
probabilityValues = startVal + w*probabilityValues;
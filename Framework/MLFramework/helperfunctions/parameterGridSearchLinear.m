% function parameterLoop = parameterGridSearchLinear(parameterRanges)
% 
% Generate a linearly loopable n-dimensional parameter subsampling space
% for grid search
%
% input example 

% parameterRanges={};
% p=struct;
% p.name = 'A';
% p.values = 1:10;
% parameterRanges{end+1} = p;
% 
% p.name = 'B';
% p.values = 0:0.5:1;
% parameterRanges{end+1} = p;
% 
% p.name = 'X';
% p.values = {'a', 'b'}
% parameterRanges{end+1} = p;
%
% parameterGridSearchLinear = parameterGridSearchLinear(parameterRanges)
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function parameterGridSearchLinear = parameterGridSearchLinear(parameterRanges)


parameterGridSearchLinear = {};

rangeSizes = [];
% parameterRanges is (name->String, range->vector )
for iParam = 1:numel(parameterRanges)
    cParam = parameterRanges{iParam};
    numVals = max(1,numel(cParam.values)); % at least one if one method has no parameters
    rangeSizes =[rangeSizes, numVals];
    
end

nParameterCombinationsTotal = prod(rangeSizes);
nRangeDim = numel(rangeSizes);

for iP=1:nParameterCombinationsTotal
    indexVals = zeros(1,nRangeDim);
    [gridCoords{1:nRangeDim}] = ind2sub(rangeSizes,iP);
    parameterSet = struct;
    for ii=1:nRangeDim
        cname = parameterRanges{ii}.name;
        cvalue = parameterRanges{ii}.values(gridCoords{ii});
        try  % convert cells into mat if possible
            if iscell(cvalue)
               cvalue = cell2mat(cvalue); 
            end
        catch 
        end
        parameterSet=setfield(parameterSet,cname,cvalue);
    end
    parameterGridSearchLinear{end+1}=parameterSet;
end

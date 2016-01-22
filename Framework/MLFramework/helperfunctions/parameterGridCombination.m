% function structCell = parameterGridCombination(combinationStruct,baseStruct)
% 
% get parameter combination grid fused with base struct
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function [structCell, stringList]= parameterGridCombination(combinationStruct,baseStruct)


structCell = {};
stringList = {};

combinationFields = fieldnames(combinationStruct);
parameterRanges={};
for iField = 1:numel(combinationFields)
    cField = combinationFields{iField};
    p=struct;
    p.name = cField;
    p.values = getfield(combinationStruct,cField);
    parameterRanges{end+1} = p;
end

parameterGrid = parameterGridSearchLinear(parameterRanges);

for iGrid = 1:numel(parameterGrid)
    cGridStruct = parameterGrid{iGrid};
    cStruct = baseStruct;
    gridFields = fieldnames(cGridStruct);
    for iGridParams = 1:numel(gridFields)
        gField = gridFields{iGridParams};
        gVal = getfield(cGridStruct,gField);
        cStruct = setfield(cStruct,gField,gVal);
    end
    paramDescription = struct2csvext(cGridStruct,'_','=');
    stringList{end+1} = paramDescription;
    cStruct.metaParameterDescription = paramDescription;
    structCell{end+1} = cStruct;
end



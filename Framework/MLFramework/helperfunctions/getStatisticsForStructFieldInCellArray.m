% function value = getStatisticsForStructFieldInCellArray(cellArrayOfStructs, fieldName, statistics)
% Given a cell array of structs with fields, this function returns
% statistical values for a field along the cell array.
% statistics can be 'mean' or 'std'
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function value = getStatisticsForStructFieldInCellArray(cellArrayOfStructs, fieldName, statistics)
valueList = [];
    for ii=1:numel(cellArrayOfStructs)
        cStruct = cellArrayOfStructs{ii};
        val = getfield(cStruct,fieldName);
        valueList = [valueList; val];
    end
if strcmp(statistics, 'mean')
    value = mean(double(valueList),1);
elseif strcmp(statistics, 'std')
    value = std(double(valueList),0,1);
elseif strcmp(statistics, 'min')
    value = min(double(valueList),[],1);
elseif strcmp(statistics, 'max')
    value = max(double(valueList),[],1);
else
    error('field statistics must be mean, std, min or max!');
end
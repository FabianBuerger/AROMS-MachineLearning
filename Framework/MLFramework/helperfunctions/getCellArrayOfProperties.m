% given a datastructure with structs in a cell array, this function returns
% a cell array of sub values from the field fieldName
function cellArray = getCellArrayOfProperties(cellArrayWithStructs,fieldName)
    cellArray = {};
    for ii=1:numel(cellArrayWithStructs)
        cData = getfield(cellArrayWithStructs{ii},fieldName);
        cellArray{end+1} = cData;
    end
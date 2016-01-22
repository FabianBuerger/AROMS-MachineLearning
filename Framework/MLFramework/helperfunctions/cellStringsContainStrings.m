% function found = cellStringsContainStrings(cellArr,searchCellArr)
% looks for strings in the cell array of strings. if any is found it is
% returned true
%       
function found = cellStringsContainStrings(cellArr,searchCellArr)
found = 0;
for ii=1:numel(searchCellArr)
    cSearch = searchCellArr{ii};
    if cellStringsContainString(cellArr,cSearch)
        found = 1;
        break;
    end
end
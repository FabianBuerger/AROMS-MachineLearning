% function flag = stringCellArraysContainSameElements(cellStrings1, cellStrings2)
% Returns true if all items of cellStrings1 are inside of cellStrings2.
% Additionally the number of elements must be the same.
% This is a set tester if no items occur twice in the sets
function flag = stringCellArraysContainSameElements(cellStrings1, cellStrings2)
    flag = 0;
    if numel(cellStrings1) == numel(cellStrings2)
        flagList = zeros(1,numel(cellStrings1));
        for ii=1:numel(cellStrings1)
            cElem1 = cellStrings1{ii};
            foundItem = 0;
            for ij=1:numel(cellStrings2)
                cElem2 = cellStrings2{ij};
                if strcmp(cElem1,cElem2)
                    foundItem = 1;
                end
            end 
            flagList(ii) = foundItem;
        end
        flag = prod(flagList);
    end

end
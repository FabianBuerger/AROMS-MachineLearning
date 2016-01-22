% function found = cellStringsContainString(cellArr,search)
% looks for a string in the cell array of strings
%       
function [found, indices] = cellStringsContainString(cellArr,search)
found = 0;
indices = [];
for ii=1:numel(cellArr)
    if strcmp(cellArr{ii},search)
        found = 1;
        indices(end+1) = ii;
    end
end
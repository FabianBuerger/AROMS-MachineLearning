% function stringVal = cellArrayToCSVString(cellArr,separator)
% makes a comma separated value (CSV) string out of a cellArray of strings
%       
function stringVal = cellArrayToCSVString(cellArr,separator)
    stringVal = [];
    for ii=1:numel(cellArr)
        stringVal = [stringVal cellArr{ii}];
        if ii < numel(cellArr)
           stringVal = [stringVal separator]; 
        end    
    end
end

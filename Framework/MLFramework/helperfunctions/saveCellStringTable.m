% function saveCellStringTable(cellString, outputType, fileName)
% Save a 2d cell array of strings to disk in either tex or csv format
%
% - cellString: cell array of strings
% - outputType: string, either 'csv' or 'tex'
% - fileName: filename to store data
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function saveCellStringTable(cellString, outputType, fileName)
    stringRep = '';
    fieldSeparator1 = ',';
    texMode = 0;
    if strcmp(outputType,'csv')
        fieldSeparator1 = ','; % separate pipeline elements
        fieldSeparator2 = ''; % newline
    end
    if strcmp(outputType,'tex')
        texMode = 1;
        fieldSeparator1 = ' & '; % separate pipeline elements
        fieldSeparator2 = '  \\ \hline'; % newline
    end    

    lineStrings = {};
    
    for iRow = 1:size(cellString,1)
        cRowItems = cellString(iRow,:);
        if texMode 
            for iCol = 1:numel(cRowItems)
                if isempty(cRowItems{iCol}) || numel(strtrim(cRowItems{iCol}))==0
                    cRowItems{iCol} = ' ~ ';
                end
            end
        end
        cLine = cellArrayToCSVString(cRowItems,fieldSeparator1);
        if iRow ~= size(cellString,1)
            cLine = [cLine fieldSeparator2];
        end
        lineStrings{end+1} = cLine;
    end
    
    saveMultilineString2File(lineStrings,fileName);
% get a valid latex table string (as multiline cell array)
% with nice book tabs layout
function tableStrings = latexOuterTableFrom2DStringArrayBookTabs(cellArrayTableCells, tableDescription, options)

nColumns = size(cellArrayTableCells,2);


columnStyle = 'l';


cellHeaders = [''];
for ii=1:nColumns
    cellHeaders = [cellHeaders columnStyle];
    if any(options.indicesLinesVertical == ii)
        cellHeaders = [cellHeaders '|'];
    end
end
stringTop = sprintf('\\begin{table}[h]  \n \\footnotesize \n \\begin{tabular}{%s}   \\toprule',cellHeaders);


texMode = 1;
fieldSeparator1 = ' & '; % separate pipeline elements
fieldSeparator2 = '  \\ '; % newline

lineStrings = {};

for iRow = 1:size(cellArrayTableCells,1)
    cRowItems = cellArrayTableCells(iRow,:);
    if texMode 
        for iCol = 1:numel(cRowItems)
            if isempty(cRowItems{iCol}) || numel(strtrim(cRowItems{iCol}))==0
                cRowItems{iCol} = ' ~ ';
            end
        end
    end
    cLine = cellArrayToCSVString(cRowItems,fieldSeparator1);
    cLine = [cLine fieldSeparator2];
    
    if any(options.indicesLinesHorizontal == iRow)
        cLine = [cLine ' \midrule '];
    end
    
    lineStrings{end+1} = cLine;
end
        

stringBottom = sprintf('\\bottomrule  \\end{tabular} \n	\\caption[%s]{%s} \n	\\label{tableRef} \n \\end{table}',tableDescription,tableDescription);

tableStrings = [ {stringTop}, lineStrings, {stringBottom}];

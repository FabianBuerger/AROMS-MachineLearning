% get a valid latex table string (as multiline cell array)
function tableStrings = latexOuterTableFrom2DStringArray(cellArrayTableCells, tableDescription, columnStyle)

nColumns = size(cellArrayTableCells,2);

if nargin < 3
    columnStyle = 'p{2cm}';
end

cellHeaders = ['|'];
for ii=1:nColumns
    cellHeaders = [cellHeaders columnStyle '|'];
end
stringTop = sprintf('\\begin{table}[h]  \n \\footnotesize \n \\begin{tabular}{%s}  \\hline',cellHeaders);


texMode = 1;
fieldSeparator1 = ' & '; % separate pipeline elements
fieldSeparator2 = '  \\ \hline'; % newline

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

    lineStrings{end+1} = cLine;
end
    
    

stringBottom = sprintf('\\end{tabular} \n	\\caption[%s]{%s} \n	\\label{tableRef} \n \\end{table}',tableDescription,tableDescription);

tableStrings = [ {stringTop}, lineStrings, {stringBottom}];

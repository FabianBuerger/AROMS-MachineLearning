% get a valid latex table string (as multiline cell array)
function tableStrings = latexOuterTable(tableRowStrings, nColumns, tableDescription, columnStyle)

if nargin < 4
    columnStyle = 'p{2cm}';
end

cellHeaders = ['|'];
for ii=1:nColumns
    cellHeaders = [cellHeaders columnStyle '|'];
end
stringTop = sprintf('\\begin{table}[h]  \n \\small \n \\begin{tabular}{%s}  \\hline',cellHeaders);

stringBottom = sprintf('\\end{tabular} \n	\\caption[%s]{%s} \n	\\label{tableRef} \n \\end{table}',tableDescription,tableDescription);

tableStrings = [ {stringTop}, tableRowStrings, {stringBottom}];

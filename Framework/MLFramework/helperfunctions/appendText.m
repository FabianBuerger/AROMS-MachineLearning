% function appendText(textFile, appendLines)
%
% append text (single string or cell array of string lines) to text file. 
% If file not existing it will be created.
%
function appendText(textFile, appendLines)

if ~iscell(appendLines)
    appendLines = {appendLines};
end

fid = fopen(textFile, 'at');
for ii = 1:numel(appendLines)
   fprintf(fid, '%s\n', appendLines{ii});
end
fclose(fid);

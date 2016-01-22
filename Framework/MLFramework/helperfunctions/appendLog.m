% function appendLog(textFile, logLines)
%
% append text logs with time stamp to text file.
%
function appendLog(logFile, logLines)

if ~iscell(logLines)
    logLines = {logLines};
end

timestamp = datestr(now, 'yy-mm-dd HH:MM:SS');

for ii = 1:numel(logLines)
   appendText(logFile,sprintf('%s:  %s',timestamp,logLines{ii}));
end
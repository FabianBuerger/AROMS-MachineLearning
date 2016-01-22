% function pathStr = checkPathDelimiter(pathStr)
% check if last char is path delimiter and add one if needed
%
function pathStr = checkPathDelimiter(pathStr)

% check directory delimiter
if ~ (strcmp(pathStr(end),'/') || strcmp(pathStr(end),'\'))
    pathStr = [pathStr filesep];
end

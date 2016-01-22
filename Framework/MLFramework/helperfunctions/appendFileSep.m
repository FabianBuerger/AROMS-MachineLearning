%function [path]= appendFileSep(path)
% appends a file/folder separator sign / or \ if it is not the case

function [path]= appendFileSep(path)
if numel(path)>0
    if strcmp(path(end),'/') || strcmp(path(end),'\') 
        path=path(1:end-1);
    end
    path = [path filesep];
end


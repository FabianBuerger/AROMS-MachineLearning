%function stringOut = struct2csv(structIn,separator)
% make a struct with fields to a comma separated list
function stringOut = struct2csv(structIn,separator)
stringOut = [];
if nargin==1
   separator = ', '; 
end
fnames = fieldnames(structIn);
for ii=1:numel(fnames)
    cVal = structIn.(fnames{ii});
    if isnumeric(cVal) || islogical(cVal)
        dispVal = num2str(cVal);
    else
        dispVal = cVal;
    end
    stringOut = [stringOut fnames{ii} '=' dispVal];
    if ii<numel(fnames)
        stringOut = [stringOut separator];
    end
end


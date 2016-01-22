%function stringOut = struct2csvext(structIn,separator)
% make a struct with fields to a comma separated list
function stringOut = struct2csvext(structIn,separator1, separator2)
stringOut = [];
if nargin==1
   separator1 = ', '; 
end
fnames = fieldnames(structIn);
for ii=1:numel(fnames)
    cVal = getfield(structIn,fnames{ii});
    if isnumeric(cVal)
        dispVal = num2str(cVal);
    else
        dispVal = cVal;
    end
    stringOut = [stringOut fnames{ii} separator2 dispVal];
    if ii<numel(fnames)
        stringOut = [stringOut separator1];
    end
end


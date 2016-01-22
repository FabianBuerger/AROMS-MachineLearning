%function [val, fieldexists]= queryStruct(dataStruct,key,defaultValue)
%
% query struct with default value if field does not exists

function [val, fieldexists]= queryStruct(dataStruct,key,defaultValue)
val = defaultValue;
fieldexists = 0;
try
    if isfield(dataStruct,key)
        val = getfield(dataStruct,key);
        fieldexists = 1;
    end
catch e

end


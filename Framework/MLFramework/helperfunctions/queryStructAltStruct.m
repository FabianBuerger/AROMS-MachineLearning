%function [val, fieldexists]= queryStructAltStruct(dataStruct,key,alternativeStruct)
%
% query struct with default value taken from other struct if field does not exists

function [val, fieldexists]= queryStructAltStruct(dataStruct,key,alternativeStruct)
val = [];
fieldexists = 0;
try
    if isfield(dataStruct,key)
        val = getfield(dataStruct,key);
        fieldexists = 1;
    else
        val = queryStruct(alternativeStruct,key,[]);
        fieldexists = 0;
    end
catch e

end


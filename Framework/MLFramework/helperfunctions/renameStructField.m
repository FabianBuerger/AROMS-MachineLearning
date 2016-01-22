% function dataStruct= renameStructField(dataStruct,nameOld,nameNew)
%
% rename struct field if it exists
%

function dataStruct= renameStructField(dataStruct,nameOld,nameNew)
if isfield(dataStruct,nameOld)
    value = dataStruct.(nameOld);
    dataStruct = rmfield(dataStruct,nameOld);
    dataStruct.(nameNew) = value;
end

% function parameterStruct = parameterMergeWithStandardStruct(parameterStruct,standardParameterStruct)
%
% merge 2 parameter struct with standard struct

function parameterStruct = parameterMergeWithStandardStruct(parameterStruct,standardParameterStruct)

allFields = fieldnames(standardParameterStruct);
for ii=1:numel(allFields)
    cField = allFields{ii};
    if ~isfield(parameterStruct,cField)
        parameterStruct.(cField) = standardParameterStruct.(cField);
    end
end


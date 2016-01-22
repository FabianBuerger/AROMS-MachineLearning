% function [resultsList, bestConfig, success] = suboptimizerConfigEvolutionaryCV(config, dataStruct)
% config defines feature subset, feature transform, classifier method.
% -> performs calculation of feature selection and feature transform WITH
% grid search for classifier parameters
% this function performs cross validation also on the feature transform

% Note: Early Discarding Ready!
% Note: Feature Preprocessing included in CV: extended CV

function [resultList, bestConfig, success, otherResults] = suboptimizerConfigEvolutionaryCV(config, dataStruct)
 
bestConfig = struct;
success = 1;
resultList = {};


configBase = config; % this includes Feature Subset, Feature Transform and classifer name (not parameters!)

% generate classifier sub parameter sets
classifierName = config.configClassifier.classifierName;
% find classifier id string
classifierIndex = 0;
for ii=1:numel(dataStruct.dynamicComponents.componentsClassifierSelection)
    if strcmp(dataStruct.dynamicComponents.componentsClassifierSelection{ii}.name,classifierName)
        classifierIndex = ii;
        break;
    end
end
if classifierIndex == 0
    %warning('Classifier %s NOT found!!',classifierName);
    return;
end
parameterRangesClassifier = dataStruct.dynamicComponents.componentsClassifierSelection{classifierIndex}.parameterRanges;
paramGridClassifier = parameterGridSearchLinear(parameterRangesClassifier);

% prepare grid
configClassifierList = cell(numel(paramGridClassifier),1);
%fprintf('    classifier grid search...\n');
for iConfig=1:numel(paramGridClassifier)
    cParams = paramGridClassifier{iConfig};
    configClassifier = struct;
    configClassifier.classifierName = classifierName;
    configClassifier.classifierParams = cParams; 
    configClassifierList{iConfig}=configClassifier;
end

% get results
params = struct;
params.processParallel = 0;
params.jobParams = dataStruct.jobParams;
params.dataStruct = dataStruct;
[resultList, bestConfig, otherResults] = dataStruct.classificationPipeline.evaluatePipelineCVFeatureTransformationMultiClassifiers(...
configBase,configClassifierList,  dataStruct.dataSet,dataStruct.crossValidationSets,params);







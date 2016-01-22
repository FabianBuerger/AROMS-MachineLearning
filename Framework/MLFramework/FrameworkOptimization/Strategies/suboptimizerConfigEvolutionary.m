% function [resultsList, bestConfig, success] = suboptimizerConfigEvolutionary(config, dataStruct)
% config defines feature subset, feature transform, classifier method.
% -> performs calculation of feature selection and feature transform WITH
% grid search for classifier parameters

% Note: Early Discarding Ready!
% Note: Feature Preprocessing included in CV

function [resultList, bestConfig, success, otherResults] = suboptimizerConfigEvolutionary(config, dataStruct)

debugParams = 0;
 
bestConfig = struct;
success = 0;
resultList = {};

otherResults = struct;
otherResults.earlyDiscardingPercentages= [];
otherResults.nEvaluationsSaved = [];
otherResults.nRoundsTotal = []; 


% process data -------------------------------------------------------

%fprintf(' Current Config: %s \n',configuration2string(config));

% pipeline elements
pipelineElemFeatureSelection= dataStruct.classificationPipeline.getPElemFeatureSelection();
pipelineElementFeaturePreprocessing = dataStruct.classificationPipeline.getPElemFeaturePreprocessing();
pipelineElemFeatureTransform = dataStruct.classificationPipeline.getPElemFeatureTransform();
%pipelineElemClassifier = dataStruct.classificationPipeline.getPElemClassifier();


% start processing data
dataPipelineIn = struct;
dataPipelineIn.config = config;
dataPipelineIn.dataSet = dataStruct.dataSet;

dataFeatSel= pipelineElemFeatureSelection.prepareElement(dataPipelineIn);
dataFeatPreProc = pipelineElementFeaturePreprocessing.prepareElement(dataFeatSel);
            
% feature transform -------------------------------------------------
nDataDim = size(dataFeatPreProc.dataSet.featureMatrix,2);
if nDataDim < 1
    %disp('NO DATA FOR FEATURE TRANSFORM')
    return; 
end

%check validity (number dimensions too small)
featureTransformMethod = config.configFeatureTransform.featureTransformMethod;
if ~strcmp(featureTransformMethod,'none')
    if nDataDim < 2
        % feature transform ~= none and only 1 dimension -> stop!
        %fprintf('DIM REDUCTION %s not possible with only 1 dimension\n',featureTransformMethod);
        return;
    end
end

% set parameters in conig -> auto dimension estimation
dataFeatPreProc.config.configFeatureTransform.featureTransformMethod = featureTransformMethod;
dataFeatPreProc.config.configFeatureTransform.featureTransformParams = struct;
dataFeatPreProc.config.configFeatureTransform.featureTransformParams.nDimensions = 'auto';
dataFeatPreProc.config.configFeatureTransform.featureTransformParams.estimateDimensionality = 0;
dataFeatPreProc.config.configFeatureTransform.featureTransformParams.dimensionalityPercentage = config.configFeatureTransform.featureTransformParams.dimensionalityPercentage;

if debugParams
    fprintf('   Feature Transform %s  %s\n',featureTransformMethod,...
        struct2csv(dataFeatPreProc.config.configFeatureTransform.featureTransformParams,','));
end

% perform feature transform
dataForClassifier=pipelineElemFeatureTransform.prepareElement(dataFeatPreProc); 

if dataForClassifier.errorProcessing
    %fprintf('Feature Transform %s failed\n',featureTransformMethod);
    return;
end

dataForClassifier.config.configFeatureTransform.featureTransformParams.nDimensions = size(dataForClassifier.dataSet.featureMatrix,2);

% classifier -------------------------------------------------
classifierName = config.configClassifier.classifierName;
% find classifier id string
classifierIndex = 0;
for ii=1:numel(dataStruct.dynamicComponents.componentsClassifierSelection)
    if strcmp(dataStruct.dynamicComponents.componentsClassifierSelection{ii}.name,classifierName)
        classifierIndex = ii;
    end
end
if classifierIndex == 0
    %warning('Classifier %s NOT found!!',classifierName);
    return;
end
parameterRangesClassifier = dataStruct.dynamicComponents.componentsClassifierSelection{classifierIndex}.parameterRanges;
paramGridClassifier = parameterGridSearchLinear(parameterRangesClassifier);

% set cross validation sets
dataForClassifier.crossValidationSets = dataStruct.crossValidationSets;


% grid search
resultList = cell(numel(paramGridClassifier),1);
%fprintf('    classifier grid search...\n');

            
for iConfig=1:numel(paramGridClassifier)
    cParams = paramGridClassifier{iConfig};
    dataForClassifierCopy = dataForClassifier;
    dataForClassifierCopy.config.configClassifier.classifierName = classifierName;
    dataForClassifierCopy.config.configClassifier.classifierParams = cParams; 
    if debugParams  
        fprintf('    Classifier %s %s\n',classifierName,struct2csv(cParams,','));
    end       
    % call pipeline element evaluation method
    % ---
            
    classifierController = ClassifierController(dataStruct.classificationPipeline.generalParams);
    [resultData, otherResults]  = classifierController.evaluateClassifierPerformanceEarlyDiscarding(...
        dataForClassifierCopy.dataSet, dataForClassifierCopy.config, dataForClassifierCopy.crossValidationSets, dataStruct.earlyDiscardingParams, otherResults);
    
    % append to list
    resultList{iConfig} = resultData;    
end


%-------------------------------------------------------------------------
% result check
% find best config
bestConfig = struct;
bestConfig.bestQuality = -1;
bestConfig.bestQualityIndex = 0;

if numel(resultList) > 0
    success = 1;
    for iRes = 1:numel(resultList) 
        cRes = resultList{iRes};
        if cRes.qualityMetric > bestConfig.bestQuality 
            bestConfig.bestQuality = cRes.qualityMetric;
            bestConfig.bestQualityIndex = iRes;
        end
    end
end






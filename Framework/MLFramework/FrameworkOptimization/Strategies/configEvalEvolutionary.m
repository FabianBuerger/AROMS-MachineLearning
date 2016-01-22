% [resultList, bestConfig, success] = configEvalEvolutionary(config, dataStruct)
% config defines feature subset, feature transform, classifier method and
% parameters. No grid search is performed

function [resultList, bestConfig, success, otherResults] = configEvalEvolutionary(config, dataStruct)

debugParams = 0;
 
bestConfig = struct;
success = 0;
resultList = {};
otherResults = struct;
otherResults.earlyDiscardingPercentages= [];
otherResults.nEvaluationsSaved = [];
otherResults.nRoundsTotal = []; 


% whole pipeline in cross validation?
if dataStruct.jobParams.extendedCrossValidation
    % FEATURE TRANSFORM EVALUATION ----------
    % Note: Early Discarding Ready!
    % note: Preprocessing ready
    params = struct;
    params.skipPreProcessing = 1;
    params.processParallel = 0;
    params.jobParams = dataStruct.jobParams;
    params.dataStruct = dataStruct;
    [resultList, bestConfig, otherResults] = dataStruct.classificationPipeline.evaluatePipelineCVFeatureTransformationSingleClassifiers(...
    config,dataStruct.dataSet,dataStruct.crossValidationSets,params);
    success = 1;
    
else
    % Note: Early Discarding Ready!
    % note: Preprocessing ready
    % ONLY CLASSIFIER EVALUATION-------------
    % feature selection -------------------------------------------------------
    
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

    % set parameters in conig -> auto dimension estimation by dimension
    % fraction
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

    % classifier -------------------------------------------------
    dataForClassifier.config.configFeatureTransform.featureTransformParams.nDimensions = size(dataForClassifier.dataSet.featureMatrix,2);
    dataForClassifier.config.configClassifier.classifierName = config.configClassifier.classifierName;
    dataForClassifier.config.configClassifier.classifierParams = config.configClassifier.classifierParams;
    dataForClassifier.crossValidationSets = dataStruct.crossValidationSets;

    classifierController = ClassifierController(dataStruct.classificationPipeline.generalParams);
    [resultData, otherResults]  = classifierController.evaluateClassifierPerformanceEarlyDiscarding(...
        dataForClassifier.dataSet, dataForClassifier.config, dataForClassifier.crossValidationSets, dataStruct.earlyDiscardingParams, otherResults);
    
    % append to list -> just one result here
    resultList{1} = resultData;    

end




%-------------------------------------------------------------------------
% result check
if numel(resultList) > 0
    success = 1;
    % find best config
    bestConfig = struct;
    bestConfig.bestQuality = -1;
    bestConfig.bestQualityIndex = 0;

    for iRes = 1:numel(resultList) 
        cRes = resultList{iRes};
        if cRes.qualityMetric > bestConfig.bestQuality 
            bestConfig.bestQuality = cRes.qualityMetric;
            bestConfig.bestQualityIndex = iRes;
        end
    end
end






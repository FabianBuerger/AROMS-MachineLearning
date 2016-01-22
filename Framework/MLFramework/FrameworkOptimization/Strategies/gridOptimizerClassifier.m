% function results = gridOptimizerClassifier(optimizationStrategyHandle,dataForClassifier,appendToResultList)
% grid optimizer for
% - classifer and corresponding parameters
%

function resultList = gridOptimizerClassifier(optimizationStrategyHandle,featTransJobs, appendToResultList)

paramDebug = optimizationStrategyHandle.paramDebug;

% set of components and parameters
dynamicComponents = optimizationStrategyHandle.job.jobParams.dynamicComponents;

% prepare configuration list
classifierConfigList = {};

% get cross validation sets
%featTransJobs.crossValidationSets = optimizationStrategyHandle.crossValidationSets;

for iFeatTransDataSet = 1:numel(featTransJobs)
    featTransJobs{iFeatTransDataSet}.dataForClassifier.crossValidationSets = optimizationStrategyHandle.crossValidationSets;
    
    for iClassifier = 1:numel(dynamicComponents.componentsClassifierSelection)
        cClassifier = dynamicComponents.componentsClassifierSelection{iClassifier};

        % get linearized grid for each classifier
        paramGridClassifier = parameterGridSearchLinear(cClassifier.parameterRanges);
        for iGrid=1:numel(paramGridClassifier)
            configClassifier = struct;
            configClassifier.iFeatTransDataSets = iFeatTransDataSet; % reference to dataset (not to copy the data
            configClassifier.config = struct;
            configClassifier.config.classifierName = cClassifier.name;
            configClassifier.config.classifierParams = paramGridClassifier{iGrid};
            classifierConfigList{end+1} = configClassifier;
        end
    end
end

nConfigCombinations = numel(classifierConfigList);

if paramDebug
    fprintf('    Grid Search: %d classifier parameter configurations...\n',nConfigCombinations);
end

% results go here
resultList = cell(nConfigCombinations,1);

% get classifier pipeline element
classifierElem = optimizationStrategyHandle.classificationPipeline.getPipelineElementByIndex(4); % get fourth element

%jobParams
jobParams = optimizationStrategyHandle.job.jobParams;


% parallel grid search!
%warning('Here should be PARFOR!');
parfor iConfig = 1:nConfigCombinations
    cConfigClassifier = classifierConfigList{iConfig};
    dataForClassifierCopy = featTransJobs{cConfigClassifier.iFeatTransDataSets}.dataForClassifier;
    dataForClassifierCopy.config.configClassifier = cConfigClassifier.config;
    
    %fprintf('dataset %d with %d dimensions \n',cConfigClassifier.iFeatTransDataSets,size(dataForClassifierCopy.dataSet.featureMatrix,2));
        
    if paramDebug
        fprintf('    Classifier %s %s\n',cConfigClassifier.classifierName,struct2csv(cConfigClassifier.classifierParams,','));
    end
    
    % call pipeline element evaluation method
    evaluationMetrics = classifierElem.evaluateClassifierConfiguration(dataForClassifierCopy);
    
    resultData = struct;
    resultData.configuration = dataForClassifierCopy.config;
    resultData.evaluationMetrics = evaluationMetrics;
    resultData.qualityMetric = getQualityMetricFormEvaluation(evaluationMetrics,jobParams);
    
    % append to list
    resultList{iConfig} = resultData;
end

% append to results
if appendToResultList
    for iConfig = 1:nConfigCombinations
        optimizationStrategyHandle.optimizationResultController.appendResult(resultList{iConfig})
    end
end


% 
%   resultData.configuration = pipelineConfigSearch;
%                 resultData.evaluationMetrics = evaluationMetrics;            
%                 resultData.qualityMetric = this.getQualityMetricFormEvaluation(evaluationMetrics);
%                 resultDataList{iVal} =resultData;
%             end
%             for ii=1:numel(resultDataList)
%                 this.optimizationResultController.appendResult(resultDataList{ii});
%             end                  


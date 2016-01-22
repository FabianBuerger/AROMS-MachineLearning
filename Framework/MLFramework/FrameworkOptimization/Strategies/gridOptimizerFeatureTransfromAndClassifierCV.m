% function results = gridOptimizerFeatureTransfromAndClassifier(optimizationStrategyHandle,featureSet)
% grid optimizer for
% - feature transform and parameters
% - classifer and corresponding parameters
%

function [resultsList, bestConfig] = gridOptimizerFeatureTransfromAndClassifierCV(optimizationStrategyHandle,featureSet, appendToResultList)

resultsList = {};
bestConfig = struct;

warning('This code is not maintained anymore');
return;
% 
% 
% dynamicComponents = optimizationStrategyHandle.job.jobParams.dynamicComponents;
% dataSetPreProcessed = optimizationStrategyHandle.dataPreProcessed.dataSet;
% configBase = optimizationStrategyHandle.dataPreProcessed.config;
% configBase.configFeatureSelection.featureSubSet = featureSet;
% configBase.configFeatureTransform.featureTransformParams.estimateDimensionality = 1; % use PCA to estimate dimensionality as heuristic
% 
% %----- 1) get feature transform configurations
% compFeatTrans = dynamicComponents.componentsFeatureTransSelection;
% nFeatTrans = numel(compFeatTrans);
% 
% featureTransfromConfigs = cell(nFeatTrans,1);
% for iFeatTrans = 1:nFeatTrans
%     cConfig = configBase;
%     cMethodFeatTrans = compFeatTrans{iFeatTrans};
%     cConfig.configFeatureTransform.featureTransformMethod = cMethodFeatTrans.name;
%     featureTransfromConfigs{iFeatTrans} = cConfig;
% end
% 
% 
% %----- 2) get classifier configs
% % loop all classifiers
% configClassifierList = {};
% for iClassifier=1:numel(dynamicComponents.componentsClassifierSelection)
%     cClassifierName = dynamicComponents.componentsClassifierSelection{iClassifier}.name;
%     parameterRangesClassifier = dynamicComponents.componentsClassifierSelection{iClassifier}.parameterRanges;
%     % get parameter grid for this classifier
%     paramGridClassifier = parameterGridSearchLinear(parameterRangesClassifier);
%     for iConfig=1:numel(paramGridClassifier)
%         cParams = paramGridClassifier{iConfig};
%         configClassifier = struct;
%         configClassifier.classifierName = cClassifierName;
%         configClassifier.classifierParams = cParams; 
%         configClassifierList{end+1}=configClassifier;
%     end
% end
% 
% %fprintf('Grid Search: %d feature transforms with %d classifier configurations... \n',nFeatTrans,numel(configClassifierList));
% 
% 
% %----- 3) process combinations
% params = struct;
% params.skipPreProcessing = 1;
% params.processParallel = 1;
% disp('processing feature transform');
% %warning('processParallel !!!!!!!!!')
% params.jobParams = optimizationStrategyHandle.job.jobParams; 
% for iFeatTrans = 1:numel(featureTransfromConfigs)
%     cBaseConfig = featureTransfromConfigs{iFeatTrans}; % contains feature set and feature transform
%     fprintf('Feature Transform %s and classifier parameter optimization...\n',cBaseConfig.configFeatureTransform.featureTransformMethod)
%     [cResultList, cBestConfig] = optimizationStrategyHandle.classificationPipeline.evaluatePipelineCVFeatureTransformationMultiClassifiers(...
%         cBaseConfig,configClassifierList, dataSetPreProcessed, optimizationStrategyHandle.crossValidationSets,params);
%     
%     % append result list
%     resultsList = [resultsList;cResultList];
% end
% 
% 
% % find best config and add to results
% bestConfig = struct;
% bestConfig.bestQuality = 0;
% bestConfig.bestQualityIndex = 0;
% 
% for iRes = 1:numel(resultsList) 
%     cRes = resultsList{iRes};
%     if appendToResultList
%         optimizationStrategyHandle.optimizationResultController.appendResult(cRes);
%     end
%     if cRes.qualityMetric > bestConfig.bestQuality 
%         bestConfig.bestQuality = cRes.qualityMetric;
%         bestConfig.bestQualityIndex = iRes;
%     end
% end
% 




% function results = gridOptimizerFeatureTransfromAndClassifier(optimizationStrategyHandle,featureSet)
% grid optimizer for
% - feature transform and parameters
% - classifer and corresponding parameters
%

function [resultsList, bestConfig] = gridOptimizerFeatureTransfromAndClassifier(optimizationStrategyHandle,featureSet, appendToResultList)

resultsList = {};



% pipeline elements
pipelineElemFeatureSelection= optimizationStrategyHandle.classificationPipeline.getPElemFeatureSelection();
pipelineElementFeaturePreprocessing = optimizationStrategyHandle.classificationPipeline.getPElemFeaturePreprocessing();
pipelineElemFeatureTransform = optimizationStrategyHandle.classificationPipeline.getPElemFeatureTransform();
%pipelineElemClassifier = optimizationStrategyHandle.classificationPipeline.getPElemClassifier();

%
% start processing data
dataPipelineIn = struct;
dataPipelineIn.config = optimizationStrategyHandle.dataStruct.config;
dataPipelineIn.dataSet = optimizationStrategyHandle.dataStruct.dataSet;

% set parameters
dataPipelineIn.config.configFeatureSelection.featureSubSet = featureSet;

dataFeatSel= pipelineElemFeatureSelection.prepareElement(dataPipelineIn);
dataFeatPreProc = pipelineElementFeaturePreprocessing.prepareElement(dataFeatSel);



% set of components and parameters
dynamicComponents = optimizationStrategyHandle.job.jobParams.dynamicComponents;

%1) loop feature transform methods and parameters in parallel
compFeatTrans = dynamicComponents.componentsFeatureTransSelection;
nFeatTrans = numel(compFeatTrans);

featTransJobs = {};
% 1 first find feasible parameter configurations
for iFeatTrans = 1:nFeatTrans
     
    cMethodFeatTrans = compFeatTrans{iFeatTrans};
    featTransMethodName = cMethodFeatTrans.name;
    %limit number of dimensions to maximum number of features
    % to reduce dimensionality
    featTransFeasible = 1;
    numDimMax = size(dataFeatPreProc.dataSet.featureMatrix,2);
    for iParam = 1:numel(cMethodFeatTrans.parameterRanges)
        cParam = cMethodFeatTrans.parameterRanges{iParam};
        if strcmp(cParam.name,'nDimensions')
             if prod(isnumeric(cParam.values))
                 %numeric case (grid search)
                 dimensionalityLimit = cParam.values >= numDimMax;
                 cParam.values(dimensionalityLimit)=[];
             else
                 % auto estimation only for numdim > 1
                 if numDimMax <= 1
                     featTransFeasible = 0;
                 end
             end
             % valid dimension parameters -> do not test this config
             if numel(cParam.values) == 0 
                featTransFeasible = 0;
             end
             cMethodFeatTrans.parameterRanges{iParam} = cParam;
        end
    end
    
    %check if possible (non empty datasets)
    if featTransFeasible
        % get linear list of parmaters of feature transform
        paramGridFeatTrans = parameterGridSearchLinear(cMethodFeatTrans.parameterRanges);
        
        for iFeatSelParam = 1:numel(paramGridFeatTrans)
            cParamsFeatTrans = paramGridFeatTrans{iFeatSelParam};

            featTransJob = struct;
            featTransJob.config = dataFeatPreProc.config;
            featTransJob.config.configFeatureTransform.featureTransformMethod = featTransMethodName;
            featTransJob.config.configFeatureTransform.featureTransformParams = cParamsFeatTrans;
            featTransJob.config.configFeatureTransform.featureTransformParams.estimateDimensionality = 1; % use PCA to estimate dimensionality as heuristic
            % append to list
            featTransJobs{end+1} = featTransJob;
        end
    end
end

% 2) parallel computation of feature transforms
paramDebug = 1;
if paramDebug
    disp('Starting manifold computing')
    tic;
end

dataRemoveIndices = zeros(numel(featTransJobs),1);

%warning('Here should be par for!')
parfor iFeatTrans = 1: numel(featTransJobs)
    featTransJob = featTransJobs{iFeatTrans};
    if paramDebug
        fprintf('   Feature Transform %s  %s\n',featTransJob.config.configFeatureTransform.featureTransformMethod,...
            struct2csv(featTransJob.config.configFeatureTransform.featureTransformParams,','));
    end    
    dataForFeatTransformCopy = dataFeatPreProc;
    dataForFeatTransformCopy.config = featTransJob.config;
    
    % perform feature transform
    featTransJob.dataForClassifier=pipelineElemFeatureTransform.prepareElement(dataForFeatTransformCopy);  
    if ~featTransJob.dataForClassifier.errorProcessing
         featTransJob.config.configFeatureTransform.featureTransformParams.nDimensions = size(featTransJob.dataForClassifier.dataSet.featureMatrix,2);
         featTransJob.dataForClassifier.config.configFeatureTransform.featureTransformParams = struct;
         featTransJob.dataForClassifier.config.configFeatureTransform.featureTransformParams.nDimensions = size(featTransJob.dataForClassifier.dataSet.featureMatrix,2);
    end
    % if something went wrong remove from list
    dataRemoveIndices(iFeatTrans) = featTransJob.dataForClassifier.errorProcessing;    
    featTransJobs{iFeatTrans} = featTransJob;
    
    if paramDebug
        if featTransJob.dataForClassifier.errorProcessing
        fprintf('   FAILED: %s  %s\n',featTransJob.config.configFeatureTransform.featureTransformMethod,...
            struct2csv(featTransJob.config.configFeatureTransform.featureTransformParams,','));            
        end
    end     
end

if paramDebug
    t=toc;
    fprintf('done manifold computing, time needed: %0.2f s \n',t);
end
         
nTransComputed = numel(featTransJobs);
% kick out transforms with errors
removeIndices = find(dataRemoveIndices);
featTransJobs(removeIndices) = [];

fprintf('  Feature Transforms ready for classification %d of %d possible \n',numel(featTransJobs),nTransComputed);


% now loop the feature transforms on one thread while the inside grid is
% parallel
if paramDebug
    disp('Starting classifier parameter tuning...')
    tic;
end
resultsRound = gridOptimizerClassifier(optimizationStrategyHandle,featTransJobs,appendToResultList);
resultsList = [resultsList;resultsRound];
if paramDebug
    t=toc;
    fprintf('done classifier tuning in %0.2f s \n',t);
end


% WARNING: high memory consumption here!
% % copy data to new cell array
% dataList = cell(numel(parallelTransformResults),1);
% for ii=1:numel(parallelTransformResults)
%     dataList{ii} = parallelTransformResults{ii}.dataForClassifier;
% end
% resultsRound = gridOptimizerClassifier(optimizationStrategyHandle,dataList,appendToResultList);
% resultsList = [resultsList;resultsRound];
%     

% perform parallel grid search
% for ii=1:numel(parallelTransformResults)
%     resultsRound = gridOptimizerClassifier(optimizationStrategyHandle,parallelTransformResults{ii}.dataForClassifier,appendToResultList);
%     resultsList = [resultsList;resultsRound];
% end

    



% find best config
bestConfig = struct;
bestConfig.bestQuality = -1;
bestConfig.bestQualityIndex = 0;

for iRes = 1:numel(resultsList) 
    cRes = resultsList{iRes};
    if cRes.qualityMetric > bestConfig.bestQuality 
        bestConfig.bestQuality = cRes.qualityMetric;
        bestConfig.bestQualityIndex = iRes;
    end
end

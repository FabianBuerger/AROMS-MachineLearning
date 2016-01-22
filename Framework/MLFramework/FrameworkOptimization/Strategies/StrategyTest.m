% Class definition StrategyTest
% Test the framework components
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef StrategyTest < OptimizationStrategy
    
    properties 
        
    end
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % start optimization process
        % note: use this.computationStopCriterion() for time limit check!
        function performOptimization(this)
   

            this.testPipeline();
  
        end        
        
        
        
        %__________________________________________________________________
        % testing
        function testPipeline(this)
            disp('+++++ Pipeline Test +++++');
            
%             
%             % get dynamic framework components
%             dynComponents = frameworkComponentLists();
%             
%             cPipeline = ClassificationPipeline();
%             cPipeline.initParams(this.generalParams);
%             
%             % set dataset to pipeline
%             %cPipeline.setDataSet(this.job.dataSet);
% 
%             pipelineConfig = ClassificationPipeline.getEmptyPipelineConfiguration(this.job.jobParams);
%             
%             
%             % ----------------
%             % config preparation
%             
%             % ==============> stage 1) Feature PreProcessing
%             data0 = struct;
%             data0.dataSet = this.job.dataSet;
%             data0.config = pipelineConfig;
%             
%             preProcessingElem = cPipeline.getPipelineElementByIndex(1); % get first element in pipeline
%             data1= preProcessingElem.prepareElement(data0);
% %             % process
% %             dataSetScaled = preProcessingElem.dataSetScaled;
%             
%             
%             % ==============> stage 2) Feature Subset selection
%             %pipelineConfig.configFeatureSelection.featureSubSet = {'feat1','feat2','feat3','noise'};
%             pipelineConfig.configFeatureSelection.featureSubSet = {'feat1','feat2','feat3','feat4','noise'}; 
%             data1.config = pipelineConfig;            
%             
%             featureSelectionElem = cPipeline.getPipelineElementByIndex(2); % get second element in pipeline
%             data2 = featureSelectionElem.prepareElement(data1);
% %             % process
% %             dataSetSubSetFiltered = featureSelectionElem.process(dataSetScaled);
%        
%             % ==============> stage 3) Feature Transform
%             
%             %----- working manifold learning stuff
% %            pipelineConfig.configFeatureTransform.featureTransformMethod = 'none';
% %             pipelineConfig.configFeatureTransform.featureTransformMethod = 'PCA';
%              pipelineConfig.configFeatureTransform.featureTransformMethod = 'KernelPCA';
% %            pipelineConfig.configFeatureTransform.featureTransformMethod = 'AutoEncoder';
% %            pipelineConfig.configFeatureTransform.featureTransformMethod = 'ManifoldChart';
% %            pipelineConfig.configFeatureTransform.featureTransformMethod = 'LandmarkMVU';
% %            pipelineConfig.configFeatureTransform.featureTransformMethod = 'Laplacian';
% %            pipelineConfig.configFeatureTransform.featureTransformMethod = 'LDA';
% %....
% 
%             % ----- problematic
% %            pipelineConfig.configFeatureTransform.featureTransformMethod = 'LLE';
% %            pipelineConfig.configFeatureTransform.featureTransformMethod = 'LMNN';
% 
%             % ---- no easy out of sample extension 
%             %pipelineConfig.configFeatureTransform.featureTransformMethod = 'HessianLLE';            
%             %pipelineConfig.configFeatureTransform.featureTransformMethod = 'LLC';
%             pipelineConfig.configFeatureTransform.featureTransformMethod = 'Isomap';
% %             pipelineConfig.configFeatureTransform.featureTransformMethod = 'LandmarkIsomap';
% %             pipelineConfig.configFeatureTransform.featureTransformMethod = 'GPLVM';
% %             pipelineConfig.configFeatureTransform.featureTransformMethod = 'tSNE';
% 
%             pipelineConfig.configFeatureTransform.featureTransformParams.nDimensions = 3;
%             data2.config = pipelineConfig;  
%             
%             featureTransformElem = cPipeline.getPipelineElementByIndex(3); % get third element
%             
%             %plot results
%             featureTransformElem.plotFeatureTransformedVectors = 0;
%             featureTransformElem.plotFeatureTransformedVectorsNumberDimensions = 3;
%             
%             % train manifold/dimension reduction
%             data3=featureTransformElem.prepareElement(data2);       
%             
%             %process
%             %dataSetFeatureTransform = featureTransformElem.cachedMappedDataSet;
%             % test out of sample extension
%             %dataSetFeatureTransform = featureTransformElem.process(dataSetSubSetFiltered);  
%             
%             
%             % ==============> stage 4) Classifier
%             
%             pipelineConfig.configClassifier.classifierName = 'ClassifierKNN'; %this is equal to the class name
%             pipelineConfig.configClassifier.classifierParams.kNeighbors = 5;
%             pipelineConfig.configClassifier.classifierParams.distanceMetric = 'euclidean';
%             
%             
%             data3.config = pipelineConfig;
%             data3.crossValidationSets = this.crossValidationSets;
%         
%             classifierElem = cPipeline.getPipelineElementByIndex(4); % get fourth element
%             
%             % get evaluation metrics for classifier
%             evaluationResult01 = classifierElem.evaluateClassifierConfiguration(data3);
%             evaluationResult01
%             
%             
%             % training for classifying new elements..
%             classifierElem.prepareElement(data3);  
%             
%             % forward classification (use dataSet from feature transform
%             predictedLabels01 = classifierElem.process(data3.dataSet);
%             
%             
%             %==============================================================
%             % test the whole forward chain
%             disp('----------Test forward classification...')
%             tic;
%             predictedLabels02 = cPipeline.processWholePipeline(this.job.dataSet);
%             toc;
%             
%             deltaProcWholePipeline = sum(abs(predictedLabels01-predictedLabels02) > 0)
%             if deltaProcWholePipeline > 0
%                 warning('Pipeline classification differences from training')
%             end            
%             
%             
%             
% %             % ==============================================================
% %             % test result storage
% %             resultData = struct;
% %             resultData.configuration = pipelineConfig;
% %             resultData.evaluationMetrics = evaluationResult01;
% %             tic;
% %             for ii=1:10000
% %                 resultData.qualityMetric = rand;
% %                 this.optimizationResultController.appendResult(resultData);
% %                 if mod(ii,200) == 0
% %                     configStr = StatisticsTextBased.getConfigurationStringForConsole(resultData.configuration);
% %                     fprintf('%s \n',configStr);
% %                 end
% %             end
% %             toc;
% %             this.optimizationResultController.finalizeList();
%             
%             
%             %==============================================================
%             % test reinit configuration forward direction for evaluation
%             pipelineFromConfigEval = ClassificationPipeline();
%             pipelineFromConfigEval.initParams(this.generalParams);
%             disp('----------Prepare pipeline for evaluation...')
%             tic;
%             evaluationResult02 = pipelineFromConfigEval.evaluatePipelineFromConfiguration(...
%                 pipelineConfig,this.job.dataSet, this.crossValidationSets);
%             toc;            
%             evaluationResult02
%             
%             
%             
%             %==============================================================
%             % grid search test
% %             pipelineGridTest = ClassificationPipeline();
% %             pipelineGridTest.initParams(this.generalParams);
%             generalParams = this.generalParams;
%             resultDataList = cell(100,1);
%             dataSet = this.job.dataSet;
%             crossValidationSets = this.crossValidationSets;
%             parfor iVal = [1:100];
%                 
%                 pipelineConfigSearch=pipelineConfig;
%                 pipelineConfigSearch.configClassifier.classifierParams.kNeighbors=iVal;
%                 
%                 pipelineGridTest = ClassificationPipeline();
%                 pipelineGridTest.initParams(generalParams);
%             
%                 evaluationMetrics = pipelineGridTest.evaluatePipelineFromConfiguration(...
%                 pipelineConfigSearch,dataSet, crossValidationSets);
%                 % store results
%                 resultData = struct;
%                 resultData.configuration = pipelineConfigSearch;
%                 resultData.evaluationMetrics = evaluationMetrics;            
%                 resultData.qualityMetric = this.getQualityMetricFormEvaluation(evaluationMetrics);
%                 resultDataList{iVal} =resultData;
%             end
%             for ii=1:numel(resultDataList)
%                 this.optimizationResultController.appendResult(resultDataList{ii});
%             end                  
%             
%             
%             
%             
%             %==============================================================            
%             % test reinit configuration forward direction for
%             % classification
%             pipelineFromConfigClassification = ClassificationPipeline();
%             pipelineFromConfigClassification.initParams(this.generalParams);
%             disp('----------Prepare pipeline for classification...')
%             tic;
%             pipelineFromConfigClassification.preparePipelineForClassification(pipelineConfig,this.job.dataSet);
%             toc;
%             disp('----------export pipeline state...')
%             pipelineStatePackage = pipelineFromConfigClassification.exportPipelineState();
%             pipelineStatePackage
%             %==============================================================            
%             % load classification ready pipeline from state 
%             
%  
%             
%             
%             disp('----------load from state...')
%             pipelineFromState = ClassificationPipeline();
%             pipelineFromState.initParams(this.generalParams);      
%             pipelineFromState.initFromPipelineState(pipelineStatePackage);
%             
%             tic;
%             predictedLabels03 = pipelineFromState.processWholePipeline(this.job.dataSet);
%             toc;
%             
%             % should be zero
%             deltaFromReloadedPipeline = sum(abs(predictedLabels01-predictedLabels03) > 0)
%             if deltaFromReloadedPipeline > 0
%                 warning('Pipeline classification differences from reloaded states')
%             end
            
        end    
                
        
        
        
        
        
        %__________________________________________________________________
        % start optimization process
        function finishOptimization(this)
            disp('finishing results');
        end    
        
        
      end % end methods public ____________________________________________

      
      

end

        



% ----- helper -------




        

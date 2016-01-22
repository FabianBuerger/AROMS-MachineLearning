% Class definition ClassificationPipeline
% 
% This class is the pipeline for classification tasks. It initializes the
% proposed pipeline element order of 
% 1) Feature Preprocessing
% 2) Feature Selection
% 3) Feature Transform
% 4) Classifier
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef ClassificationPipeline < PipelineClass
    
    properties (Access=public)  
        
        % pipeline configuration (for forward classification)
        pipelineConfiguration = struct;
        
        % data set the pipeline has been trained with
        dataSetBase = [];
        
        %pipeline verbosity
        pipelineVerbose = 0;
        
        % flag if a pipeline is properly configured for classification.
        % To achieve this, the function initPipelineForClassification has t
        % to be called
        consitentState = 0;  
        
        
    end
    
    
    %====================================================================
    methods
         
        % constructor
        function obj = ClassificationPipeline()
        
        end
        
        
        %__________________________________________________________________
        % init the objects for the classification pipeline
        function initPipelineElements(this)
            
            % set standard values for parameters
            this.generalParams.retrainClassifierOnStateRecovery = queryStruct(this.generalParams,'retrainClassifierOnStateRecovery',0);
            % -> 1: use kCrossVal sets to to train kCrossVal classifiers,
            % otherwise (0) train 1 classifer with whole dataset
            this.generalParams.multiClassifierFromCrossValidationSets = queryStruct(this.generalParams,'multiClassifierFromCrossValidationSets',0);
            
            % 1. feature subset selection
            pe1 = PipelineElemFeatureSelection();
            this.appendPipelineElement(pe1);   
            
            % 2. preprocessing (e.g. feature scaling)
            pe2 = PipelineElemFeaturePreprocessing();
            this.appendPipelineElement(pe2);
            
            % 3. performing feature transform (PCA, manifold learning)
            pe3 = PipelineElemFeatureTransform();
            this.appendPipelineElement(pe3);
            
            % 4. classifier
            pe4 = PipelineElemClassifier();
            this.appendPipelineElement(pe4);
        end
        
        
        %__________________________________________________________________
        % get specific handles on pipeline elements    
        function [pElem, index] = getPElemFeatureSelection(this)
            index = 1;
            pElem = this.pipelineElementList{index};
        end
        
        
        %__________________________________________________________________
        % get specific handles on pipeline elements    
        function [pElem, index] = getPElemFeaturePreprocessing(this)
            index = 2;
            pElem = this.pipelineElementList{index};
        end
        
        %__________________________________________________________________
        % get specific handles on pipeline elements    
        function [pElem, index] = getPElemFeatureTransform(this)
            index = 3;
            pElem = this.pipelineElementList{index};
        end
        
        %__________________________________________________________________
        % get specific handles on pipeline elements    
        function [pElem, index] = getPElemClassifier(this)
            index = 4;
            pElem = this.pipelineElementList{index};
        end        
                        
        
        %__________________________________________________________________
        % Initialize the classification pipeline from a given configuration 
        % struct (config) and the dataSet .
        % Last step is training within the classifier component
        function preparePipelineForClassification(this,config,dataSet)      
            this.consitentState = 0;
            this.pipelineConfiguration = config;
            this.dataSetBase = dataSet;
            
            % struct for preparation
            data = struct;
            data.dataSet = dataSet;
            data.config = config;
            
            try
                % call preparation of each element
                for iPipelineIndex = 1:numel(this.pipelineElementList)
                    cPipelineElement = this.pipelineElementList{iPipelineIndex};
                    data = cPipelineElement.prepareElement(data);
                end
                this.consitentState = 1;
            catch err
                 warning('Pipeline preparation error');
                 this.consitentState = 0;
            end
        end
                
    
%         %__________________________________________________________________
%         % Initialize the pipeline given the config and dataset and prepare
%         % it until the classifier, but run the evaluation function rather
%         % than the training function.
%         % crossValidationSets is a set of cross validation indices
%         % generated by generateCrossValidationIndexSets
%         function evaluationResult = evaluatePipelineFromConfiguration(this,config,dataSet,crossValidationSets)                  
%             this.pipelineConfiguration = config;
%             % struct for preparation
%             data = struct;
%             data.dataSet = dataSet;
%             data.config = config;
%             
%             % call preparation of element 1, 2 and 3
%             for iPipelineIndex = [1 2 3]
%                 cPipelineElement = this.pipelineElementList{iPipelineIndex};
%                 data = cPipelineElement.prepareElement(data);
%             end    
%             
%             data.crossValidationSets = crossValidationSets;
%             % get the classifier element and call evaluation function.
%             % Note: data is now the data element returned from the second last
%             % element, feature transform.
%             classifierElement = this.pipelineElementList{4};
%             evaluationResult = classifierElement.evaluateClassifierConfiguration(data);
%         end        
        
        
        %__________________________________________________________________
        % Initialize the pipeline given the baseConfig and dataset and prepare
        % it until the feature selection element. After that the feature
        % transform and classifier are involved into the cross validation
        % to measure the predictive power of both models: feature transform
        % and classifier. To optimize processing speed,
        % -classifierConfigList is a list of classifier parameters that are
        % validated withing the same loop without recalculating the feature
        % transform.
        % crossValidationSets is a set of cross validation indices. params
        % is a struct with additional parameters: skipPreProcessing, and
        % processParallel and jobParams

        function  [resultsList, bestConfig, otherResults] = evaluatePipelineCVFeatureTransformationSingleClassifiers(this,config,dataSet,crossValidationSets, params) 
            classifierConfigList = {config.configClassifier};
            [resultsList, bestConfig, otherResults] = this.evaluatePipelineCVFeatureTransformationMultiClassifiers(config,classifierConfigList,dataSet,crossValidationSets, params);     
        end        


        %__________________________________________________________________
        % Initialize the pipeline given the baseConfig and dataset and prepare
        % it until the feature selection element. After that the feature
        % transform and classifier are involved into the cross validation
        % to measure the predictive power of both models: feature transform
        % and classifier. To optimize processing speed,
        % -classifierConfigList is a list of classifier parameters that are
        % validated withing the same loop without recalculating the feature
        % transform.
        % crossValidationSets is a set of cross validation indices. params
        % is a struct with additional parameters: skipPreProcessing, and
        % processParallel and jobParams
        
        % Note: PREPOCESSING READY
        % 
        function  [resultsList, bestConfig, otherResults] = evaluatePipelineCVFeatureTransformationMultiClassifiers(this,baseConfig,classifierConfigList,dataSet,crossValidationSets, params) 
            
            errorOccurred = 0;
            otherResults = struct;
            
            % struct for preparation
            data = struct;
            data.dataSet = dataSet;
            data.config = baseConfig;
            
            % pipeline elements
            pipelineElemFeatureSelection= this.getPElemFeatureSelection();
            pipelineElementFeaturePreprocessing = this.getPElemFeaturePreprocessing();
            pipelineElemFeatureTransform = this.getPElemFeatureTransform();
            pipelineElemClassifier = this.getPElemClassifier();
            
            % start processing data
            dataFeatSel= pipelineElemFeatureSelection.prepareElement(data);

            %store results of cross validation rounds
            nCrossValSets = numel(crossValidationSets);
   
            % first: estimate instrinsic dimensionality of dataset
            if ~strcmp(baseConfig.configFeatureTransform.featureTransformMethod,'none')
                nDimMax = size(dataFeatSel.dataSet.featureMatrix,2);    
                if nDimMax < 2
                    % dimension reduction requested, but only 1D data
                    % available -> not possible
                    errorOccurred = 1;
                else          
                    if baseConfig.configFeatureTransform.featureTransformParams.estimateDimensionality
                       
                        %methodEstimaton = 'EigValueMin10PercentVariance'; % criterion: PCA dimenions with at least 10% variance
                        methodEstimaton = 'PCAEigValSumCriterion'; % criterion: dimensions threshold with more than 80% of variance
                        numberDimensionsEst = intrinsic_dim(dataFeatSel.dataSet.featureMatrix, methodEstimaton);     
                        numberDimensionsReduced = max(1,min(nDimMax, round(numberDimensionsEst)));                              
                        %fprintf('    PCA estimated dimensionality estimation %d / %d \n',numberDimensionsReduced,nDimMax);
                    else
                        numberDimensionsEst = nDimMax*baseConfig.configFeatureTransform.featureTransformParams.dimensionalityPercentage/100;
                        numberDimensionsReduced = max(1,min(nDimMax, round(numberDimensionsEst)));      
                        %fprintf('    Dimensionality percentaged reduced %d / %d   (%0.2f percent) \n',numberDimensionsReduced,nDimMax,baseConfig.configFeatureTransform.featureTransformParams.dimensionalityPercentage);
                    end
                    baseConfig.configFeatureTransform.featureTransformParams.nDimensions = numberDimensionsReduced; 
                end
            end
            
            resultsList = {};
            bestConfig = struct;
            bestConfig.bestQuality = 0;
            bestConfig.bestQualityIndex = 0;  
            otherResults.earlyDiscardingPercentages = [];
            otherResults.nEvaluationsSaved = [];
            otherResults.nRoundsTotal = [];

            if ~errorOccurred
                if params.processParallel %------------ Parallel Mode
                    % parallel processing (only for Heuristic Grid Search)
                    %warning('try catch!')
                    try % check if anything goes wrong (e.g. bad parameter and data conditions)  
                        % prepare cross validation data sets: "train" feature
                        % selection and use out-of-sample extension to process the
                        % validation set. This checks validates the out of sample
                        % extension pf
                        crossValidationFeatureTransformedData = cell(nCrossValSets,1);
                        %disp('Processing Feature Transform CV sets')
                        baseConfigList = cell(nCrossValSets,1);
                        parfor iCVRound = 1:nCrossValSets
                            [crossValidationFeatureTransformedData{iCVRound}, baseConfigRound] = ...
                             featureTransformCVSet(baseConfig,dataFeatSel,crossValidationSets,pipelineElementFeaturePreprocessing,pipelineElemFeatureTransform,iCVRound);
                             baseConfigList{iCVRound} = baseConfigRound;
                        end
                     % check errors (soft one that have been caught inside of the
                     % loop)
                     baseConfig = baseConfigList{1}; 
                     for iCVRound = 1:nCrossValSets
                         if baseConfigList{iCVRound}.configFeatureTransform.featureTransformParams.nDimensions ~= baseConfig.configFeatureTransform.featureTransformParams.nDimensions
                             % different target dimensionality for different
                             % CV rounds
                            errorOccurred = 1; 
                         end
                         if crossValidationFeatureTransformedData{iCVRound}.dataTrain.errorProcessing
                            errorOccurred = 1;
                         end
                     end                     
                    catch err
                        errorOccurred = 1;
                    end                                               
                    if ~errorOccurred
                        % now test classifiers
                        nConfigsClassifier = numel(classifierConfigList);
                        resultsList = cell(nConfigsClassifier,1);
                        parfor iClassConf =1:nConfigsClassifier
                            resultsList{iClassConf} = evaluateClassifierConfig(baseConfig,classifierConfigList,dataSet,crossValidationFeatureTransformedData,pipelineElemClassifier,params,iClassConf);
                        end
                    end                 
                else %------------ Sequential Mode
                   %warning('try catch!!')
                   try 
                        % init early discarding objects (one for all
                        % classifier/parameter combis
                        nConfigsClassifier = numel(classifierConfigList);
                        earlyDiscardingHandlers = cell(nConfigsClassifier,1);
                        configList = cell(nConfigsClassifier,1);
                        for iClassConf = 1:nConfigsClassifier
                            earlyDiscardingHandlers{iClassConf} = EarlyDiscardingController(params.dataStruct.earlyDiscardingParams);
                        end
                        baseConfigList = cell(nCrossValSets,1);
                        for iCVRound = 1:nCrossValSets
                            stopAfterRound = 0;
                            
                            [crossValidationFeatureTransformedDataSingle, baseConfigRound] = ...
                             featureTransformCVSet(baseConfig,dataFeatSel,crossValidationSets,pipelineElementFeaturePreprocessing,pipelineElemFeatureTransform,iCVRound);
                            baseConfigList{iCVRound} = baseConfigRound;
                            
                            % any error for feature transform
                             if crossValidationFeatureTransformedDataSingle.dataTrain.errorProcessing
                                errorOccurred = 1;
                                stopAfterRound = 1;
                             end                            
                            
                             % check dimensionality
                             if baseConfigList{1}.configFeatureTransform.featureTransformParams.nDimensions ~= baseConfigRound.configFeatureTransform.featureTransformParams.nDimensions
                                 % different target dimensionality for different CV rounds
                                errorOccurred = 1; 
                                stopAfterRound = 1;
                             end
                             
                            % test classifier/parameter combis
                            if ~errorOccurred
                                for iClassConf =1:nConfigsClassifier
                                    if ~earlyDiscardingHandlers{iClassConf}.discarded
                                        earlyDiscardingHandlers{iClassConf}.cvRoundStarted();
                                        
%                                        debugClassifier = 0;
% 
%                                         if debugClassifier
%                                             debugFileName = sprintf('debug_%d.mat',randi(999999999,1));
%                                             debugData = struct;
%                                             debugData.crossValidationFeatureTransformedDataSingle = crossValidationFeatureTransformedDataSingle;
%                                             debugData.baseConfigRound = baseConfigRound;
%                                             debugData.cConfigClassifier = classifierConfigList{iClassConf};
%                                             %fprintf('save %s \n',debugFileName);
%                                             save(debugFileName,'debugData');
%                                         end                                      
                                        
                                        %---- classifier evaluation
                                        timerClassifier=tic;
                                        
                                        cConfigClassifier = classifierConfigList{iClassConf};
                                        resultData = evaluateClassifierConfigSingleCVSet(baseConfigRound,cConfigClassifier,dataSet,...
                                            crossValidationFeatureTransformedDataSingle,pipelineElemClassifier,params);  
                                        
                                        timePassed = toc(timerClassifier);
                                        try
                                            if this.generalParams.advancedTimeMeasurements
                                                if timePassed > this.generalParams.timeThreshSlow
                                                    fprintf(' !! AdvancedTimeMeasurement: Slow classifier %s needed %0.2f min \n',cConfigClassifier.classifierName, timePassed/60);
                                                end
                                            end
                                        catch ee
                                        end                                        

                                        % --- classifier eval
                                        
%                                         if debugClassifier
%                                             delete(debugFileName);
%                                         end                                      
                                        
                                        configList{iClassConf} = resultData.configuration;
                                        if resultData.evaluationResultSingleCVRound.errorOccurred
                                            earlyDiscardingHandlers{iClassConf}.setErrorOccured();
                                        else
                                            earlyDiscardingHandlers{iClassConf}.cvRoundPerformed(resultData.evaluationResultSingleCVRound.evalMetricsCVRound);
                                        end
                                        
                                    end
                                end                    
                            end                                     
                            discardingCounter = 0;
                            for iClassConf =1:nConfigsClassifier
                                if earlyDiscardingHandlers{iClassConf}.discarded
                                    discardingCounter = discardingCounter+1;
                                end
                            end  
                            allDiscarded = discardingCounter == nConfigsClassifier;
                            
                            if allDiscarded
                                %fprintf('EarlyDiscarding: ALL classifiers discarded\n');
                                stopAfterRound = 1;
                            end                         
                            % stop loop 
                            if stopAfterRound || errorOccurred
                                %fprintf('Loop stopped!\n')
                                break;
                            end
                        end

                    % build result list  
                    if ~errorOccurred
                        resultsList = cell(1,nConfigsClassifier);
                        for iClassConf = 1:nConfigsClassifier
                            earlyDiscardingHandlers{iClassConf}.updateCurrentQualityMetrics();
                            resultData = struct;
                            resultData.configuration = configList{iClassConf};
                            resultData.evaluationMetrics = earlyDiscardingHandlers{iClassConf}.averageCVResultStruct;
                            resultData.qualityMetric = earlyDiscardingHandlers{iClassConf}.qualityMetric;                                   
                            resultsList{iClassConf} = resultData;
                            otherResults.earlyDiscardingPercentages(end+1) = earlyDiscardingHandlers{iClassConf}.percentageEvalsNeeded;
                            otherResults.nEvaluationsSaved(end+1) = earlyDiscardingHandlers{iClassConf}.nEvaluationsSaved;
                            otherResults.nRoundsTotal(end+1) = earlyDiscardingHandlers{iClassConf}.nRoundsTotal;
                        end                    
                    end
   
                   catch err
                       errorOccurred = 1;
                   end  
                end
            end
            
            % --- Results
            if numel(resultsList) > 0
                for iRes = 1:numel(resultsList) 
                    cRes = resultsList{iRes};
                    if cRes.qualityMetric > bestConfig.bestQuality 
                        bestConfig.bestQuality = cRes.qualityMetric;
                        bestConfig.bestQualityIndex = iRes;
                    end
                end
            end
        end        
                  

               
        
        %__________________________________________________________________
        % Export the current pipeline state so that it can be e.g. saved to
        % disk to load it back in initFromPipelineState.
        function pipelineStatePackage = exportPipelineState(this)      
            pipelineStatePackage = struct;
            if this.consitentState
                pipelineStatePackage.pipelineStates = this.getPipelineStates();
                pipelineStatePackage.dataSetBase = this.dataSetBase;
                pipelineStatePackage.pipelineConfiguration = this.pipelineConfiguration;
                pipelineStatePackage.trainedClassifier = []; % retrain classifier
                
                if ~this.generalParams.retrainClassifierOnStateRecovery
                    % store classifier model data
                    classifierElement = this.pipelineElementList{4};
                    pipelineStatePackage.trainedClassifierFusion = classifierElement.trainedClassifierFusion;
                end
            else
                error('Pipeline state is not consistent for saving!'); 
            end
        end        
 
        
        %__________________________________________________________________
        % Use the pipeline state package derived from exportPipelineState to init
        % the classification pipeline to be ready for classification
        function initFromPipelineState(this, pipelineStatePackage)      
            this.setPipelineStates(pipelineStatePackage.pipelineStates);
            this.dataSetBase = pipelineStatePackage.dataSetBase;
            this.pipelineConfiguration = pipelineStatePackage.pipelineConfiguration;
            
            trainedClassifierAvailable = ~isempty(pipelineStatePackage.trainedClassifierFusion);
            classifierElement = this.pipelineElementList{4};
            
            if this.generalParams.retrainClassifierOnStateRecovery
                disp('Prepare retraining classifier...')
                % get dataset from feature transform
                dataSetFeatTrans = this.processPipelinePart(this.dataSetBase,1,3);
                
                data = struct;
                data.dataSet = dataSetFeatTrans;
                data.config = this.pipelineConfiguration;
                
                % now train classifier
                disp('... retraining...')
                classifierElement.prepareElement(data);
                disp('... done');
            else
                if trainedClassifierAvailable
                    classifierElement.trainedClassifierFusion = pipelineStatePackage.trainedClassifierFusion;
                else
                    error('no trained classifier in pipelineStatePackage. Consider switching on mode retraining on state recovery!');
                end
            end
            
            this.consitentState = 1;
        end      
        
        
      end % end methods public ____________________________________________
    

      
     % static methods _____________________________________________________     
     methods(Static = true)
      
      
        %__________________________________________________________________
        % get an empty the hyper parameter configuration struct for the
        % classification pipeline.
        % However, it will need to be trained to work as valid
        % configuration
        function pipelineConfig = getEmptyPipelineConfiguration(jobParams)
            pipelineConfig = struct;
            
            
            % here are the basic sub structures for the configuration of
            % each pipeline element
            
            % =========== preprocessing pipeline element
            configPreprocessing = struct;
            
            % feature preprocessing is now in feature transform
            configPreprocessing.featurePreProcessingMethod = 'none';
            
            pipelineConfig.configPreprocessing = configPreprocessing;
                        
            
            % =========== feature selection pipeline element            
            configFeatureSelection = struct;
            % which sub set of features should be selected
            configFeatureSelection.featureSubSet = {};
            
            pipelineConfig.configFeatureSelection = configFeatureSelection;
            
            
            % =========== feature transform pipeline element   
            configFeatureTransform = struct;
            % which feature transform should be applied
            configFeatureTransform.featureTransformMethod = '';
            % additional parameters for feature transform
            configFeatureTransform.featureTransformParams = struct;
	    %hyperparameters of feature transform
            configFeatureTransform.featureTransformHyperparams = struct;
                       
            pipelineConfig.configFeatureTransform = configFeatureTransform;
            
            % =========== classifier pipeline element            
            configClassifier = struct;       
            % classifier subclass name
            configClassifier.classifierName = '';
            % classifier sub parameters
            configClassifier.classifierParams = struct;
            
            pipelineConfig.configClassifier = configClassifier;      
        end        
      
        
     end
      


    methods(Access = private)

    end %private methods   


end

        
function resultData = evaluateClassifierConfigSingleCVSet(baseConfig,cClassConfigIn,dataSet,...
                                        crossValidationFeatureTransformedDataSingle,pipelineElemClassifier,params)
    cConfig = baseConfig;
    cConfig.configClassifier = cClassConfigIn;
                
    
    classifierController = ClassifierController(pipelineElemClassifier.pipelineHandle.generalParams);
    evaluationResultSingleCVRound = classifierController.evaluateClassifierPerformanceSingleCVSet(dataSet, cConfig, crossValidationFeatureTransformedDataSingle);
            
    resultData = struct;
    resultData.configuration = cConfig;
    resultData.evaluationResultSingleCVRound = evaluationResultSingleCVRound;                                  
end



function resultData = evaluateClassifierConfig(baseConfig,classifierConfigList,dataSet,crossValidationFeatureTransformedData,pipelineElemClassifier,params,iClassConf)
    cConfig = baseConfig;
    cConfig.configClassifier = classifierConfigList{iClassConf};
    evaluationResult = pipelineElemClassifier.evaluateClassifierConfigurationFromPreComputedCVSets(cConfig, dataSet, crossValidationFeatureTransformedData);                    
    resultData = struct;
    resultData.configuration = cConfig;
    resultData.evaluationMetrics = evaluationResult;
    resultData.qualityMetric = getQualityMetricFormEvaluation(evaluationResult,params.jobParams);      
end


% extended cross validation: 
% - no feature selection (done before)
% - feature preprocessing train with train data and process both train and validation data
% - feature transform: train with train data and process both train and validation data
% - no classifier 
% Output: train and validation data processed for classifier

function [transformedCVDataSet, baseConfig] = featureTransformCVSet(baseConfig,dataIn,crossValidationSets,pipelineElementFeaturePreprocessing,pipelineElemFeatureTransform,iCVRound)

    transformedCVDataSet = struct;
    % get data set
    crossValIndexSet = crossValidationSets{iCVRound};
    crossValDataRound = applyCrossValidationIndexSet(dataIn.dataSet, crossValIndexSet);
    dataSetTrain = crossValDataRound.dataTrain;
    dataSetValidation = crossValDataRound.dataTest; 

    % "train" feature Preprocessing and feature transform
    
    dataForFeatureTransformTrain = struct;
    dataForFeatureTransformTrain.dataSet = dataSetTrain;
    dataForFeatureTransformTrain.config = baseConfig;
    
    dataPreProc = pipelineElementFeaturePreprocessing.prepareElement(dataForFeatureTransformTrain);
    
    transformedCVDataSet.dataTrain = pipelineElemFeatureTransform.prepareElement(dataPreProc); 
    % write back target dimensionality (might not have been reached)
    baseConfig.configFeatureTransform.featureTransformParams.nDimensions = pipelineElemFeatureTransform.elementState.featureTransformParams.nDimensions;
    
    % forward processing feature preprocessing and feature transform (out of sample
    % extension of unseen data!)
    validationDataPreProc = pipelineElementFeaturePreprocessing.process(dataSetValidation);
    transformedCVDataSet.dataValidation = pipelineElemFeatureTransform.process(validationDataPreProc);

end

        

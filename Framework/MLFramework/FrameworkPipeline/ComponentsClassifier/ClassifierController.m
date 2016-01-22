% Class definition ClassifierController
% 
% This class controls the classifier functions like evaluate/train/classify
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef ClassifierController < handle
    
    properties  
        paramsGeneral
    end
    
    %====================================================================
    methods
        
        %__________________________________________________________________ 
        % constructor
        function obj = ClassifierController(paramsGeneral)
            obj.paramsGeneral = paramsGeneral;
        end
        
        
%         %__________________________________________________________________
%         % Train classifier (model and hyperparameters from config) for a 
%         % classification task in dataSet. 
%         % This is meant to prepare the classifier for classifying new
%         % samples
%         % Returns a trained classifier object
%         function trainedClassifier = trainClassifier(this, dataSet, config)
%             % get object
%             trainedClassifier = this.getClassifierObjectFromConfig(config);
%             % set parameters
%             trainedClassifier.init(config.configClassifier.classifierParams);
%             trainedClassifier.trainClassifier(dataSet.featureMatrix,dataSet.targetClasses);
%         end

        %__________________________________________________________________
        % Train classifier fusion (model and hyperparameters from config) for a 
        % classification task in dataSet. Classifier parameters are inside of config.
        % fusionParams is a struct and ff its flag trainingCrossValidationClassifiers flag is true, kCrossVal
        % classifiers will be trained and fused later on. If this flag is
        % off,  only 1 classifier will be used that is trained with the
        % whole dataset.
        function trainedClassifierFusion = trainClassifierFusion(this, dataSet, config, crossValidationSets, fusionParams)
            trainedClassifierFusion = ClassifierFusion(fusionParams);

            % distinguish case: Division into cross validation
            % classifiers...
            if fusionParams.multiClassifierFromCrossValidationSets

                nCrossValSets = numel(crossValidationSets);
                for iCVRound = 1:nCrossValSets
                    %fprintf('training cross val classifier %d / %d \n',iCVRound,nCrossValSets)
                    % get classifier object from configuration
                    classifier = this.getClassifierObjectFromConfig(config);

                    % get data set from cross validation subset
                    crossValIndexSet = crossValidationSets{iCVRound};
                    crossValData = applyCrossValidationIndexSet(dataSet, crossValIndexSet);

                    % set parameters
                    classifier.init(config.configClassifier.classifierParams);

                    % train classifier
                    classifier.trainClassifier(crossValData.dataTrain.featureMatrix, ...
                        crossValData.dataTrain.targetClasses);

                    % append classifier to list
                    trainedClassifierFusion.appendClassifier(classifier);
                end
            else 
                % ... or use only 1 classifier with the whole training set
                classifier = this.getClassifierObjectFromConfig(config);
                % set parameters
                classifier.init(config.configClassifier.classifierParams);
                classifier.trainClassifier(dataSet.featureMatrix,dataSet.targetClasses);    
                % append only 1 classifier
                trainedClassifierFusion.appendClassifier(classifier);
            end
            trainedClassifierFusion.pipelineReady = 1;
        end        
        
   
        %__________________________________________________________________
        % Init the correct subclass from a given configuration.
        % The config struct must have the field
        % configClassifier.classifierName which must be equal to a class
        % name of a subclass of ClassifierAbstract.
        function classifierObject = getClassifierObjectFromConfig(this, config)
            % init the class name. Note: Eval does not work in parallel
            % environments, so str2func is used here!
            cClassifierConstrHandle = str2func(config.configClassifier.classifierName);
            classifierObject= cClassifierConstrHandle();            
        end
        

        %__________________________________________________________________
        % perform evaluation of a classifier configuration (model and hyperparameters) 
        % specified in config on a dataSet object. Early Discarding is
        % performed.
        % The function returns the struct evaluationResults
        function [evaluationResults, otherResults] = evaluateClassifierPerformanceEarlyDiscarding(this, dataSet, config, crossValidationSets, earlyDiscardingParams, otherResults)
            evaluationResults = struct;
            
            classifierParams = config.configClassifier.classifierParams;
            
            evaluationResults.errorOccurred = 0;        
            %store results of cross validation rounds
            nCrossValSets = numel(crossValidationSets);
            
            % get classifier object
            classifier = this.getClassifierObjectFromConfig(config);
                
            try % check if anything goes wrong (e.g. bad parameter and data conditions)  
                % loop trough all validation sets
                earlyDiscardingHandler = EarlyDiscardingController(earlyDiscardingParams);
                for iCVRound = 1:nCrossValSets
                    earlyDiscardingHandler.cvRoundStarted();
                    stopAfterRound = 0;
                    errorOccurred = 0;
                    
                    % get data set
                    crossValIndexSet = crossValidationSets{iCVRound};
                    crossValData = applyCrossValidationIndexSet(dataSet, crossValIndexSet);
                    
                    % reset and init classifier
                    classifier.resetClassifier();
                    classifier.init(classifierParams);
                                    
                    % train classifier
                    timerTraining = tic;
                    classifier.trainClassifier(crossValData.dataTrain.featureMatrix, ...
                        crossValData.dataTrain.targetClasses);
                    timeTraining=toc(timerTraining);
                    
                    %classify test data
                    timerClassification = tic;
                    predictedTargets = classifier.classify(crossValData.dataTest.featureMatrix);
                    timeClassification=toc(timerClassification);
                    
                    %evaluate with ground truth labels
                    evalMetricsCVRound = evaluateClassficationResults(...
                       crossValData.dataTest.targetClasses, predictedTargets, dataSet.classIds);

                    %store times passed, too
                    evalMetricsCVRound.timeTraining = timeTraining;
                    evalMetricsCVRound.timeClassification = timeClassification;                    
                    evalMetricsCVRound.timeTrainingPerInstance = timeTraining/numel(predictedTargets);
                    evalMetricsCVRound.timeClassificationPerInstance = timeClassification/numel(predictedTargets);
                    
                    earlyDiscardingHandler.cvRoundPerformed(evalMetricsCVRound);
                    if earlyDiscardingHandler.discarded
                        stopAfterRound = 1;
                    end
                    
                    if stopAfterRound || errorOccurred
                        %fprintf('Loop stopped!\n')
                        break;
                    end                    
                end
                % make results
                earlyDiscardingHandler.updateCurrentQualityMetrics();
                
                evaluationResults.configuration = config;
                evaluationResults.evaluationMetrics = earlyDiscardingHandler.averageCVResultStruct;
                evaluationResults.qualityMetric = earlyDiscardingHandler.qualityMetric;                                   

                otherResults.earlyDiscardingPercentages(end+1) = earlyDiscardingHandler.percentageEvalsNeeded;
                otherResults.nEvaluationsSaved(end+1) = earlyDiscardingHandler.nEvaluationsSaved;
                otherResults.nRoundsTotal(end+1) = earlyDiscardingHandler.nRoundsTotal;                
                
            catch err
                evaluationResults.errorOccurred = 1;
                evaluationResults.qualityMetric = -1;
            end
               
        end
       
        
        
        %__________________________________________________________________
        % perform evaluation of a classifier configuration (model and hyperparameters) 
        % specified in config on a dataSet object.
        % The function returns the struct evaluationResults
        function evaluationResults = evaluateClassifierPerformance(this, dataSet, config, crossValidationSets)
            evaluationResults = struct;

            classifierParams = config.configClassifier.classifierParams;
            
            evaluationResults.errorOccurred = 0;        
            %store results of cross validation rounds
            nCrossValSets = numel(crossValidationSets);
            evalMetricAllCVRounds = cell(nCrossValSets,1);  
            
            % get classifier object
            classifier = this.getClassifierObjectFromConfig(config);
                
            try % check if anything goes wrong (e.g. bad parameter and data conditions)  
                % loop trough all validation sets
                for iCVRound = 1:nCrossValSets
                    % get data set
                    crossValIndexSet = crossValidationSets{iCVRound};
                    crossValData = applyCrossValidationIndexSet(dataSet, crossValIndexSet);
                    
                    % reset and init classifier
                    classifier.resetClassifier();
                    classifier.init(classifierParams);
                                    
                    % train classifier
                    timerTraining = tic;
                    classifier.trainClassifier(crossValData.dataTrain.featureMatrix, ...
                        crossValData.dataTrain.targetClasses);
                    timeTraining=toc(timerTraining);
                    
                    %classify test data
                    timerClassification = tic;
                    predictedTargets = classifier.classify(crossValData.dataTest.featureMatrix);
                    timeClassification=toc(timerClassification);
                    
                    %evaluate with ground truth labels
                    evalMetricsCVRound = evaluateClassficationResults(...
                       crossValData.dataTest.targetClasses, predictedTargets, dataSet.classIds);

                    %store times passed, too
                    evalMetricsCVRound.timeTraining = timeTraining;
                    evalMetricsCVRound.timeClassification = timeClassification;                    
                    evalMetricsCVRound.timeTrainingPerInstance = timeTraining/numel(predictedTargets);
                    evalMetricsCVRound.timeClassificationPerInstance = timeClassification/numel(predictedTargets);
                    
                    % append to total cross validation round list
                    evalMetricAllCVRounds{iCVRound} = evalMetricsCVRound;                    
                end

            catch err
                if this.paramsGeneral.developmentMode
                    %disp(['Classifier train error: ' err.identifier]);
                end
                evaluationResults.errorOccurred = 1;
            end
               
            % evaluate only if no error occurred
            if ~evaluationResults.errorOccurred
                %evaluation results for all cross validation rounds
                useTimeStats = 1;
                evaluationResults = averageCVResults(evaluationResults,evalMetricAllCVRounds,dataSet,nCrossValSets, useTimeStats);
            end                        
            
        end
      
        
        
        
        
        %__________________________________________________________________
        % perform evaluation of a classifier configuration (model and hyperparameters) 
        % specified in config on the pre computed crossvalidation sets
        % The function returns the struct evaluationResults
        function evaluationResults = evaluateClassifierPerformancePreComputedCVSets(this, dataSet, config, cvDataSets)
            evaluationResults = struct;

            classifierParams = config.configClassifier.classifierParams;
            
            evaluationResults.errorOccurred = 0;
            %store results of cross validation rounds
            nCrossValSets = numel(cvDataSets);
            evalMetricAllCVRounds = cell(nCrossValSets,1);  
            
            % get classifier object
            classifier = this.getClassifierObjectFromConfig(config);
                
            try % check if anything goes wrong (e.g. bad parameter and data conditions)  
                % loop trough all validation sets
                for iCVRound = 1:nCrossValSets
                    % get data set
                    cvData = cvDataSets{iCVRound};
                    cvDataTrain = cvData.dataTrain.dataSet;
                    cvDataValidation = cvData.dataValidation;
                                        
                    % reset and init classifier
                    classifier.resetClassifier();
                    classifier.init(classifierParams);
                                    
                    % train classifier
                    classifier.trainClassifier(cvDataTrain.featureMatrix, ...
                        cvDataTrain.targetClasses);
                    
                    %classify test data
                    predictedTargets = classifier.classify(cvDataValidation.featureMatrix);
                    
                    %evaluate with ground truth labels
                    evalMetricsCVRound = evaluateClassficationResults(...
                       cvDataValidation.targetClasses, predictedTargets, dataSet.classIds);
                    
                    % append to total cross validation round list
                    evalMetricAllCVRounds{iCVRound} = evalMetricsCVRound;                    
                end

            catch err
                evaluationResults.errorOccurred = 1;
            end
            % evaluate only if no error occurred
            if ~evaluationResults.errorOccurred
                %evaluation results for all cross validation rounds
                useTimeStats = 0;
                evaluationResults = averageCVResults(evaluationResults,evalMetricAllCVRounds,dataSet,nCrossValSets, useTimeStats);
            end                        
            
        end
                        
        
        
        %__________________________________________________________________
        % perform evaluation of a classifier configuration (model and hyperparameters) 
        % specified in config on the pre computed crossvalidation sets
        % The function returns the struct evaluationResults
        function evaluationResults = evaluateClassifierPerformanceSingleCVSet(this, dataSet, config, cvDataSet)
            evaluationResults = struct;

            classifierParams = config.configClassifier.classifierParams;
            evaluationResults.errorOccurred = 0;
            
            % get classifier object
            classifier = this.getClassifierObjectFromConfig(config);
                
            %warning('TRY catch commented')
            try 
                cvDataTrain = cvDataSet.dataTrain.dataSet;
                cvDataValidation = cvDataSet.dataValidation;

                % reset and init classifier
                classifier.resetClassifier();
                classifier.init(classifierParams);

                % train classifier
                classifier.trainClassifier(cvDataTrain.featureMatrix, ...
                    cvDataTrain.targetClasses);

                %classify test data
                predictedTargets = classifier.classify(cvDataValidation.featureMatrix);

                %evaluate with ground truth labels
                evaluationResults.evalMetricsCVRound = evaluateClassficationResults(...
                   cvDataValidation.targetClasses, predictedTargets, dataSet.classIds);
                   
            catch err
                evaluationResults.errorOccurred = 1;
            end            
        end
                
                
        
        
      end % end methods public ____________________________________________
    



end




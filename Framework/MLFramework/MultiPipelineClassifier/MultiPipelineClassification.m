% Class definition MultiPipelineClassification
%
% This class uses the training results from the MachineLearningFramework to
% generate a multi classifier system made out of multiple pipelines.
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef MultiPipelineClassification < handle
    
    properties 

        trainingResultFolder = '';
        multiPipelineParams = struct;
        trainingData = struct;
        
        % list of pipelines
        pipelinesReadyForClassification = {};
        
        %current results
        currentPipelineResults;
        
        diversityMaximizedRanking = [];
        classificationSpeedsPerItem = [];
    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = MultiPipelineClassification()

        end
        
            
        %__________________________________________________________________
        % initFromTrainingResults: use results from training to initialize
        % the multi pipeline classifier. Also set parameters:
        % - trainingResultFolder: result folder from MLFramework training
        % (Job Results!)
        % - multiPipelineParams: param with struct (see fields and values
        % in function)
        function initFromTrainingResults(this, trainingResultFolder, multiPipelineParams)
            
            if ~(strcmp(trainingResultFolder(end),'/') || strcmp(trainingResultFolder(end),'\'))
                trainingResultFolder(end+1) = filesep;
            end
            this.trainingResultFolder = trainingResultFolder;
            if nargin == 2
                multiPipelineParams = struct;
            end
            this.multiPipelineParams = multiPipelineParams;
            
            % parameters and standard values-----------------------
            
            % main strategy
            this.multiPipelineParams.trainingStrategy = queryStruct(multiPipelineParams,'trainingStrategy','simpleTopPipelines');
            % 'simpleTopPipelines' or 'adaptiveMostCertainPipelines'

            % trainingCrossValidationClassifiers: in case (1) train kCrossVal 
            % classifiers and use the majority of votes for each instance, 
            % otherwise (0) use the whole dataset and train one classfier
            this.multiPipelineParams.trainingCrossValidationClassifiers = queryStruct(multiPipelineParams,'trainingCrossValidationClassifiers',true);  

            % how many pipelines should be trained and are available for a
            % fusion?
            this.multiPipelineParams.maxNumberConfigurations = queryStruct(multiPipelineParams,'maxNumberConfigurations',50);
            % this number determines the number of initialized pipelines
            % that are used for classification
            this.multiPipelineParams.useNumberConfigurations = queryStruct(multiPipelineParams,'useNumberConfigurations',this.multiPipelineParams.maxNumberConfigurations);
            
            % calculate class confidences
            this.multiPipelineParams.calculateClassConfidences = queryStruct(multiPipelineParams,'calculateClassConfidences',true);
                    
            
            %--------------------------------------------------------------
            % load training data
            this.loadTrainingData();
            % train classifiers
            this.trainPipelines();
        end
        
        
        
        %__________________________________________________________________
        % classify data from dataset object
        % results is a struct with fields:
        %
        %
        function results = classifyDataSet(this, dataSetIn)
            results = struct;
            nPipelinesClassify = this.getNumberOfPipelinesNeededForClassification();
            this.currentPipelineResults = struct;
            resultsList = cell(nPipelinesClassify,1);
            if nPipelinesClassify>0
                fprintf('Classifying using %d pipelines... \n',nPipelinesClassify);
                pipelinesReady = this.pipelinesReadyForClassification;
                % order fieldnames alphabetically
                dataSetIn.instanceFeatures = orderStructLexicographically(dataSetIn.instanceFeatures);                
                % make split features
                if this.trainingData.trainingInfo.trainingInfo.job.jobParams.splitMultiChannelFeatures
                    dataSetIn = dataSetSubFeatureDivision(dataSetIn);
                end
                if this.trainingData.trainingInfo.trainingInfo.job.dataSet.nFeatures ~= numel(fieldnames(dataSetIn.instanceFeatures))
                    error('Number of features in test set is not equal to number of training features!');
                end
                fieldnamesList = fieldnames(dataSetIn.instanceFeatures);
                firstFeature = fieldnamesList{1};
                firstData = dataSetIn.instanceFeatures.(firstFeature);
                numberInstances = size(firstData,1);
                classificationSpeeds = zeros(1,nPipelinesClassify); % in seconds per item
                %warning('here should be PARFOR')
                parfor iPipeline = 1:nPipelinesClassify
                    cPipeline = pipelinesReady{iPipeline};
                    timertic = tic;
                    cResults = cPipeline.processWholePipeline(dataSetIn);
                    passedTime = toc(timertic);
                    classificationSpeeds(iPipeline) = passedTime/numberInstances;
                    resultsList{iPipeline} = cResults;
                end
                disp('fusing results...')
                this.currentPipelineResults.resultsList = resultsList;
                this.currentPipelineResults.nSamples = numel(resultsList{1}.labelsMajority);
                this.currentPipelineResults.dataSetTest = dataSetIn;
                % make fusion according to strategy
                results=this.fusePipelineResults();
                this.classificationSpeedsPerItem = classificationSpeeds;
            end
        end
        
        
        %__________________________________________________________________
        % Evaluate performance of a test data set (with labels)
        function evalResults = evaluateTestDataSet(this, dataSetIn)
            resultsPredicted = this.classifyDataSet(dataSetIn);
            evalResults = evaluateClassficationResults(...
               dataSetIn.targetClasses, resultsPredicted.predictedLabels, resultsPredicted.classIds);
        end    
        
        %__________________________________________________________________
        % Evaluate performance of last data set (parameters may have
        % changed in the mean time)
        function evalResults = evaluateLastDataSetAgain(this)
            resultsPredicted = this.fusePipelineResults();               
            evalResults = evaluateClassficationResults(...
               this.currentPipelineResults.dataSetTest.targetClasses, resultsPredicted.predictedLabels, resultsPredicted.classIds);
        end           

        %__________________________________________________________________
        % Evaluate performance of last data set (parameters may have
        % changed in the mean time)
        function evalResults = evaluateLastDataSetAgainSubSet(this,pipelineIndices)
            resultsPredicted = this.fusePipelineResultsIndices(pipelineIndices);               
            evalResults = evaluateClassficationResults(...
               this.currentPipelineResults.dataSetTest.targetClasses, resultsPredicted.predictedLabels, resultsPredicted.classIds);
        end          
        
       
        
       
        
  %__________________________________________________________________
        % fuse the results of the used classification pipelines
        function results = fusePipelineResultsIndices(this,pipelineIndices)
           results = struct;  
           subResultList = this.currentPipelineResults.resultsList(pipelineIndices);
           
           nSamples = this.currentPipelineResults.nSamples;
           nResults = numel(subResultList);
           labelsAllPipelines = zeros(nSamples,nResults);
           confidencesAllPipelines = zeros(nSamples,nResults);
           classIds = this.trainingData.trainingInfo.trainingInfo.job.dataSet.classIds;
           results.classIds = classIds;
               
           if this.multiPipelineParams.calculateClassConfidences 
               results.confidencePerClass = zeros(nSamples,numel(classIds));
           end
           
            %make matrices of results
            for iRes = 1:nResults
               cResult = subResultList{iRes};
               labelsAllPipelines(:,iRes) = cResult.labelsMajority;
               confidencesAllPipelines(:,iRes) = cResult.classiferConfidence;
            end
            % cut according to parameters (can be set after calling
            % classification pipelines)
            nPipelinesClassify = this.getNumberOfPipelinesNeededForClassification();

            %----------------------------------------------------------------------------------                
            % just majority of all pipelines
            results.predictedLabels = mode(labelsAllPipelines,2);
            if this.multiPipelineParams.calculateClassConfidences 
                % class confidences
                for iClassId = 1:numel(classIds) 
                    cClassId = classIds(iClassId);
                    classIndexMatrix = cClassId*ones(nSamples,nResults);
                    equalsClass = labelsAllPipelines == classIndexMatrix;
                    confidenceThisClass = sum(equalsClass,2)/nResults;
                    results.confidencePerClass(:,iClassId) = confidenceThisClass;
                end
            end
    
        end             
        
        
        %__________________________________________________________________
        % fuse the results of the used classification pipelines
        function results = fusePipelineResults(this)
           results = struct;      
           nSamples = this.currentPipelineResults.nSamples;
           nResults = numel(this.currentPipelineResults.resultsList);
           labelsAllPipelines = zeros(nSamples,nResults);
           confidencesAllPipelines = zeros(nSamples,nResults);
           classIds = this.trainingData.trainingInfo.trainingInfo.job.dataSet.classIds;
           results.classIds = classIds;
               
           if this.multiPipelineParams.calculateClassConfidences 
               results.confidencePerClass = zeros(nSamples,numel(classIds));
           end
           
            %make matrices of results
            for iRes = 1:nResults
               cResult = this.currentPipelineResults.resultsList{iRes};
               labelsAllPipelines(:,iRes) = cResult.labelsMajority;
               confidencesAllPipelines(:,iRes) = cResult.classiferConfidence;
            end
            % cut according to parameters (can be set after calling
            % classification pipelines)
            nPipelinesClassify = this.getNumberOfPipelinesNeededForClassification();
            nResults = nPipelinesClassify;
            
            if strcmp(this.multiPipelineParams.trainingStrategy,'simpleTopPipelines') || ...
                  strcmp(this.multiPipelineParams.trainingStrategy,'adaptiveMostCertainPipelines')  
                labelsAllPipelines = labelsAllPipelines(:,1:nResults);
                confidencesAllPipelines = confidencesAllPipelines(:,1:nResults);
            elseif strcmp(this.multiPipelineParams.trainingStrategy,'diversityMaxRanking')
                indexList = this.diversityMaximizedRanking(1:nResults);
                labelsAllPipelines = labelsAllPipelines(:,indexList);
                confidencesAllPipelines = confidencesAllPipelines(:,indexList);                
            end
            
            
            if strcmp(this.multiPipelineParams.trainingStrategy,'simpleTopPipelines') || ...
                strcmp(this.multiPipelineParams.trainingStrategy,'diversityMaxRanking')
            %----------------------------------------------------------------------------------                
                % just majority of all pipelines
                if nResults == 2
                    results.predictedLabels = labelsAllPipelines(:,1); % just best result (doesnt make sense to make majority for 2 pipelines)
                else
                    results.predictedLabels = mode(labelsAllPipelines,2);
                end
                if this.multiPipelineParams.calculateClassConfidences 
                    % class confidences
                    for iClassId = 1:numel(classIds) 
                        cClassId = classIds(iClassId);
                        classIndexMatrix = cClassId*ones(nSamples,nResults);
                        equalsClass = labelsAllPipelines == classIndexMatrix;
                        confidenceThisClass = sum(equalsClass,2)/nResults;
                        results.confidencePerClass(:,iClassId) = confidenceThisClass;
                    end
                end
            elseif strcmp(this.multiPipelineParams.trainingStrategy,'adaptiveMostCertainPipelines')
            %----------------------------------------------------------------------------------                
                % use the most confident results per instance (!) only
                results.predictedLabels = zeros(nSamples,1);
                nPipelinesAvailable = size(labelsAllPipelines,2);
                nMostConfPipelines = min(nPipelinesAvailable,this.multiPipelineParams.useNumberConfigurations);
                for iSample=1:nSamples
                    cInstancePipelineLabels = labelsAllPipelines(iSample,:);
                    cInstancePipelineConfidences =  confidencesAllPipelines(iSample,:);
                    [vals,indices] = sort(cInstancePipelineConfidences,'descend');
                    indicesHighestConfidence = indices(1:nMostConfPipelines);
                    labelsHighestConfidence = cInstancePipelineLabels(indicesHighestConfidence);
                    results.predictedLabels(iSample) = mode(labelsHighestConfidence,2);
                    if this.multiPipelineParams.calculateClassConfidences 
                        for iClassId = 1:numel(classIds) 
                            cClassId = classIds(iClassId);
                            classIndexMatrix = cClassId*ones(1,nMostConfPipelines);
                            equalsClass = labelsHighestConfidence == classIndexMatrix;
                            confidenceThisClass = sum(equalsClass,2)/nMostConfPipelines;
                            results.confidencePerClass(iSample,iClassId) = confidenceThisClass;
                        end      
                    end
                end
            else
                error('Fusion strategy %s not identified',this.multiPipelineParams.trainingStrategy);
            end           
        end     
        
        
        
        %__________________________________________________________________
        % save the current pipeline to disk
        function savePipelinesToFile(this, fileName)    
            dataPackage = struct;
            dataPackage.multiPipelineParams = this.multiPipelineParams;
            dataPackage.trainingData = this.trainingData;
            dataPackage.pipelinesReadyForClassification = this.pipelinesReadyForClassification;
            save(fileName,'dataPackage','-v7.3');
        end            
        
        
        %__________________________________________________________________
        % load the current pipeline to disk
        function loadPipelinesFromFile(this, fileName)
            load(fileName);
            this.multiPipelineParams = dataPackage.multiPipelineParams;
            this.pipelinesReadyForClassification = dataPackage.pipelinesReadyForClassification; 
            this.trainingData = dataPackage.trainingData;
            fprintf('Loaded %d pipelines \n', numel(this.pipelinesReadyForClassification));
        end      
        
        
        
        
        
        %__________________________________________________________________
        % select indices with the highest diversity along configurations
        function [diversityMaximizedRanking, diversityDistribution] = prepareDiversityMaximizationStrategy(this)
             [configurationListSorted, diversityMaximizedRanking, diversityDistribution] = diversityMaximization(this.trainingData.configurationList, this.trainingData.trainingInfo.trainingInfo.job);
            this.diversityMaximizedRanking = diversityMaximizedRanking;
        end            
        
        
      end % end methods public ____________________________________________
      
      
      
      
  
      
      
      
      methods(Access = private)
        
        %__________________________________________________________________
        % load training data
        function loadTrainingData(this)
           this.trainingData = struct;
           this.trainingData.successLoading = 0;

           this.trainingData.fileTrainingInfo = [this.trainingResultFolder  'trainingInfo.mat'];
           this.trainingData.fileTopConfigurations = [this.trainingResultFolder  'data' filesep 'sortedConfigurationListTop.mat'];
           
           % this file is most likely not needed
           this.trainingData.fileAllConfigurations = [this.trainingResultFolder  'trainingResults.mat'];

           if exist(this.trainingData.fileTrainingInfo,'file') == 2 &&  exist(this.trainingData.fileTopConfigurations ,'file') == 2
               %general information
               fprintf('Loading %s...\n',this.trainingData.fileTrainingInfo);
               this.trainingData.trainingInfo = load(this.trainingData.fileTrainingInfo);
               % training top configurations
               fprintf('Loading %s...\n',this.trainingData.fileTopConfigurations);
               this.trainingData.topResults = load(this.trainingData.fileTopConfigurations); 
               this.trainingData.successLoading = 1;
           else
               error('Training data incomplete in %s',this.trainingResultFolder);
           end
        end     
        
        %__________________________________________________________________
        % helper as it is used several times
        function nPipelinesClassify = getNumberOfPipelinesNeededForClassification(this)
            nPipelinesAll = numel(this.pipelinesReadyForClassification);
            if strcmp(this.multiPipelineParams.trainingStrategy,'simpleTopPipelines') || ...
                    strcmp(this.multiPipelineParams.trainingStrategy,'diversityMaxRanking') 
                % only ask the useNumberConfigurations for majority fusion
                nPipelinesClassify = min(nPipelinesAll,this.multiPipelineParams.useNumberConfigurations);
            elseif strcmp(this.multiPipelineParams.trainingStrategy,'adaptiveMostCertainPipelines')
                % always ask all pipelines, later use most certain useNumberConfigurations per item
                nPipelinesClassify = nPipelinesAll;
            else
                error('Fusion strategy %s not identified',this.multiPipelineParams.trainingStrategy);
            end
        end             
        
       
        
        
        
        %__________________________________________________________________
        % train pipelines according to loaded training data
        function trainPipelines(this)
           if this.trainingData.successLoading
               
               this.multiPipelineParams.maxNumberConfigurationsAvailable = ...
               min(this.multiPipelineParams.maxNumberConfigurations, numel(this.trainingData.topResults.evalItemsSortedQualityMetricTop));
           
               this.trainingData.configurationList = cell(this.multiPipelineParams.maxNumberConfigurationsAvailable,1);
               % read configs
               for iRes = 1:this.multiPipelineParams.maxNumberConfigurationsAvailable
                   cResult = this.trainingData.topResults.evalItemsSortedQualityMetricTop{iRes};
                   configItem = struct;
                   configItem.configuration = cResult.resultData.configuration;
                   configItem.quality = cResult.resultData.qualityMetric;
                   configItem.rank = iRes;
                   this.trainingData.configurationList{iRes} = configItem;
               end
               
               %train pipelines
               nPipelinesTrain = numel(this.trainingData.configurationList);
               pipelinesReadyForClassification = cell(nPipelinesTrain,1);
               configurationList = this.trainingData.configurationList;
               pipelineReadyList = zeros(nPipelinesTrain,1);
               %warning('HERE SHOULD BE PARFOR')
               parfor iPipeline = 1:nPipelinesTrain
                    cConfigItem = configurationList{iPipeline};
                    % train pipeline
                    stringConfig = configuration2string(cConfigItem.configuration);
                    fprintf('Training pipeline %d / %d: Quality %0.4f  Config: %s \n',iPipeline,numel(configurationList),cConfigItem.quality,stringConfig);
                    pipeline = this.trainSinglePipeline(cConfigItem.configuration);
                    % add to list
                    pipelinesReadyForClassification{iPipeline} = pipeline;
                    pipelineReadyList(iPipeline) = pipeline.consitentState;
               end
               %remove inconsistant pipelines
               removePipelines = find(~pipelineReadyList);
               pipelinesReadyForClassification(removePipelines)=[];
               this.trainingData.topResults.evalItemsSortedQualityMetricTop(removePipelines)=[];
               this.trainingData.configurationList(removePipelines)=[];
               this.pipelinesReadyForClassification = pipelinesReadyForClassification;
           end
        end           
       
        
        %__________________________________________________________________
        % train a single pipeline from configuration struct
        function pipeline = trainSinglePipeline(this,configuration)
            generalParams = struct;
            generalParams.retrainClassifierOnStateRecovery = 0;
            generalParams.multiClassifierFromCrossValidationSets = this.multiPipelineParams.trainingCrossValidationClassifiers;
            generalParams.crossValidationSets = this.trainingData.trainingInfo.trainingInfo.job.crossValidationSets;
            dataSetTrain = this.trainingData.trainingInfo.trainingInfo.job.dataSet;
            pipeline = ClassificationPipeline();
            pipeline.initParams(generalParams);
            % train
            pipeline.preparePipelineForClassification(configuration,dataSetTrain);
        end                   
          
        
      end %private methods
        
        
        
   
    
    
end

        

        
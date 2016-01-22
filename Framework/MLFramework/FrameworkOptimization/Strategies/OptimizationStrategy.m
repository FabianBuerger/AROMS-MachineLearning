% Class definition OptimizationStrategy
% This is an abstract class for a training strategy for the machine
% learning framework.
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef OptimizationStrategy < handle
    
    properties 
        % general parameters
        generalParams;
        % job contains dataSet and parameters
        job;
        % struct with general training Info like time stamps
        trainingInfo = struct;
        
        % store cross validation sets
        crossValidationSets = {};
        
        % result collection
        optimizationResultController;
        
        stopCriterion = 0;
        
        % handle to controller
        optimizationControllerHandle = [];
        % handle general time series
        timeSeriesStorage = [];
        
        % here are aggregated results
        aggregatedResults = struct;
        
    end
    
    %====================================================================
    methods
                
            
        %__________________________________________________________________
        % init and set parameters
        function init(this,generalParamsIn,jobIn)
            this.generalParams = generalParamsIn;
            this.job = jobIn;
        end
        
        
        %__________________________________________________________________
        % start training process
        function startTrainingProcess(this)
            
            % prepare cross validation sets
            if this.job.jobParams.performCrossValidation
                % cache cross validation set
                if this.job.jobParams.crossValidationGenerateNewDivisions
                    this.crossValidationSets = generateCrossValidationIndexSets(this.job.dataSet.nSamples,this.job.jobParams.crossValidationK);
                else
                    % use cached cv sets
                    this.crossValidationSets = this.optimizationControllerHandle.crossValidationSetStore.getCrossValSet(...
                        this.job.dataSet.dataSetName, this.job.dataSet.nSamples, this.job.jobParams.crossValidationK);                    
                end

                
                this.job.crossValidationSets = this.crossValidationSets;
            end
            
            % set start time
            this.trainingInfo.trainingTotalTimer = tic();
            
            % init training result controller
            this.optimizationResultController = OptimizationResultController(this.generalParams);
            this.optimizationResultController.resultStorage.componentsFeatureSelection = this.job.jobParams.dynamicComponents.componentsFeatureSelection;
            this.timeSeriesStorage = TimeSeriesStorage();
            
            % call subclass for training
            this.performOptimization();
            
            % calculate passed seconds
            this.trainingInfo.trainingTimeSeconds = toc(this.trainingInfo.trainingTotalTimer);
            
            % finish training and export
            disp('> Exporting results...')
            this.finishOptimization();
            
            % finish list
            this.optimizationResultController.finalizeList(); 
            
            % export results to result directories
            this.exportTrainingResults();
            
            % free ram and class links
            this.optimizationResultController.resultStorage = [];
            this.optimizationResultController = [];
            this.optimizationControllerHandle = [];
            this.timeSeriesStorage = [];
            this.aggregatedResults = [];
        end        
        
        
        %__________________________________________________________________
        % check if computation Stop Criterion is reached.
        % This can be defined as 
        % - computation time limit
        % - quality metric reached
        % - iteration number reached

        function stopCriterion = computationStopCriterion(this)
            
            if this.stopCriterion 
                stopCriterion = 1;
                return;
            end
            
            % check time limit
            secondsPassed = toc(this.trainingInfo.trainingTotalTimer);
            timeOver = secondsPassed > this.job.jobParams.stopCriterionComputingTimeHours*3600;
            if timeOver
                disp('>>>> STOP CRITERION: Timelimit');
            end
            
            % stop quality metric
            currentBestQuality = this.optimizationResultController.getCurrentBestQualityMetric();
            qualityReached = currentBestQuality >= this.job.jobParams.stopCriterionGoalQualityMetric;
            if qualityReached
                 disp('>>>> STOP CRITERION: Quality reached!');
            end
            
            % number iterations
            numIterations = this.optimizationResultController.numberResults();
            iterationsReached = numIterations >= this.job.jobParams.stopCriterionIterationNumber;
            if iterationsReached
                 disp('>>>> STOP CRITERION: Iterations reached!');
            end            
            
            % file based stop criterion (if file stop.txt exists in result
            % base folder and contains a "1")
            stopFile = [this.generalParams.resultPath filesep 'stop.txt'];
            stopFileCriterion = 0;
            if exist(stopFile, 'file') == 2
                try
                    stopFileContent = load(stopFile);
                    if ~isempty(stopFileContent) && isnumeric(stopFileContent) && stopFileContent == 1
                        stopFileCriterion = 1;
                        disp('>>>> STOP CRITERION: User set stop file, stop current job!');
                        % write zero to file again (next job won't stop)
                        saveMultilineString2File({'0'},stopFile); 
                    end
                    if ~isempty(stopFileContent) && isnumeric(stopFileContent) && stopFileContent == 2
                        stopFileCriterion = 1;
                        disp('>>>> STOP CRITERION: User set stop file, stop all jobs!'); 
                    end                    
                catch
                    
                end
            end
            
            stopCriterion = timeOver || qualityReached || iterationsReached || stopFileCriterion;
            if stopCriterion 
                this.stopCriterion = 1;
            end
        end           
            

        
        %__________________________________________________________________
        % export standard training data format
        function exportTrainingResults(this)
            disp('exporting optimization results...');
            % save lightweight training to file
            trainingInfo = struct;
            trainingInfo.generalParams = this.generalParams;
            trainingInfo.job = this.job;
            trainingInfo.trainingInfo = this.trainingInfo;
            trainingInfoFile = [this.job.jobParams.resultPath 'trainingInfo.mat'];
            save(trainingInfoFile,'trainingInfo','-v7.3');
            
            % save time series
            timeSeriesList = this.timeSeriesStorage.timeSeriesList;
            timeSeriesFile = [this.job.jobParams.resultPath 'timeSeries.mat'];
            save(timeSeriesFile,'timeSeriesList','-v7.3');            
            
            % save training history to disk
            trainingResults= struct;
            trainingResults.resultStorage = this.optimizationResultController.getResultListForExport();
            trainingResults.timeSeriesList = timeSeriesList;
            
            % save to file
            trainingResultFile = [this.job.jobParams.resultPath 'trainingResults.mat'];
            save(trainingResultFile,'trainingResults','-v7.3');  
            
            % prepare results
            optimizationResultData = struct;
            optimizationResultData.trainingInfo = trainingInfo;
            optimizationResultData.trainingResults = trainingResults;
            
            %set evaluation parameters
            evaluationParams = struct;
            evaluationParams.resultPathBase = this.job.jobParams.resultPath;
            evaluationParams.job = this.job;
            evaluationParams.showPlots = 0;
            evaluationParams.exportPlots = 1;
            evaluationParams.preferredFigureFormat = 'pdf';
            evaluationParams.activeStatsList = {'ResultListTop','ResultTableCSVFull', 'LatexTopTable', 'TopFitnessDistribution', ...
                'ConfigurationGraph_v3','ComponentsFrequencies','DimensionalitiesPlot'};
            
            optimizationStatistics = OptimizationStatistics();
            disp('> Exporting statistics...');
            this.aggregatedResults.resultsTraining = optimizationStatistics.performEvaluations(optimizationResultData, evaluationParams);
            
            % make multi pipeline system
            if this.job.jobParams.multiPipelineTraining %&& ~isempty(this.job.jobParams.multiPipelineTestDataSet)
                trainingJobResultPath = this.job.jobParams.resultPath;
                multiPipelineParameter = this.job.jobParams.multiPipelineParameter;
                multiPipelineTestDataSet = this.job.jobParams.multiPipelineTestDataSet;
                this.aggregatedResults.resultsMultiPipeline = handleMultiPipelineAnalysis(trainingJobResultPath, multiPipelineParameter, multiPipelineTestDataSet);
            end 
            
            %make overview stats
            summaryStatsOpt = struct;
            summaryStatsOpt.resultPath = this.job.jobParams.resultPath;
            summaryStatsOpt.job = this.job;
            dataSetResultSummary(this.aggregatedResults,summaryStatsOpt);
            
            % finally save results again with aggregated results
            trainingInfo.aggregatedResults = this.aggregatedResults;
            save(trainingInfoFile,'trainingInfo','-v7.3');
            
        end         
        
 
        
        %__________________________________________________________________
        % log or debug text message
        function log(this, messageText)
            verbose = 1;
            if verbose
                disp(messageText);
            end
        end      
        
        

      end % end methods public ____________________________________________
    


    methods(Abstract) % defined in subclasses
        performOptimization(this); % perform training
        finishOptimization(this) % export standard training history format
    end 


end

        



% ----- helper -------




        

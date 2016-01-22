% Class definition FrameworkOptimizationController
%
% This class handles training jobs from local/remote sessions
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef FrameworkOptimizationController < handle
    
    properties 
        generalParams = struct;
        
        % store overview objects if several jobs have been started
        jobsSummary = struct;
        
        % flag -> set if analysis is restarted
        restartAnalysisFlag = 0;
        
        % timer for first starting
        analysisStartTimer = 0;
        
        % store training jobs
        trainingJobList;
        
        % store cross validation sets
        crossValidationSetStore;
        
        % counter
        totalJobCounter = 0;
        currentJobIndex = 0;
        
        % class
        repetitionStats = 0;
        
        % for optimization
        parallelToolBoxHandler;
              

    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = FrameworkOptimizationController(generalParamsIn)
            obj.generalParams = generalParamsIn;
            obj.crossValidationSetStore = CrossValidationSetStore;
            obj.repetitionStats = StatisticsRepetitions();
            obj.parallelToolBoxHandler = ParallelToolBoxHandler();
        end
        
        %__________________________________________________________________
        % re init state from result path 
        function initStateFromPath(this,pathResults)
            
            this.restartAnalysisFlag = 1;
            % load data
            stateFile = [pathResults 'analysisState.mat'];
            
            load(stateFile); % analysisState is now in workspace
            this.generalParams = analysisState.generalParams;
            this.jobsSummary = analysisState.jobsSummary;  
            this.analysisStartTimer = analysisState.analysisStartTimer;
            this.trainingJobList = analysisState.trainingJobList;
        end
        
        %__________________________________________________________________
        % analyze feature value ranges/domains graphically
        function saveAnalysisState(this)
            if this.generalParams.analysisSaveState
                analysisState = struct;
                analysisState.generalParams = this.generalParams;
                analysisState.analysisStartTimer = this.analysisStartTimer;
                analysisState.jobsSummary = this.jobsSummary;
                analysisState.trainingJobList = this.trainingJobList;
                
                stateFile = [this.generalParams.resultPathFinal 'analysisState.mat'];
                save(stateFile,'analysisState','-v7.3');
                % store cross validation sets
                this.saveCrossValidationSets();
                
                disp('Saved analysis state');
            end
        end                      
        
        %__________________________________________________________________
        % prepare Analysis start parallel session and prepare result folders     
        function prepareTraining(this)
            % switch off warnings locally
            switchOffWarnings();
            
            %pass parameters to parallel toolbox handler
            this.parallelToolBoxHandler.parallelToolboxActive = this.generalParams.parallelToolboxActive;
            this.parallelToolBoxHandler.parallelToolboxNumberWorkers = this.generalParams.parallelToolboxNumberWorkers;      
            this.parallelToolBoxHandler.parallelToolboxSaveMemory = this.generalParams.parallelToolboxSaveMemory;
            
            if ~this.restartAnalysisFlag
                %make summary
                this.jobsSummary = struct;
                this.jobsSummary.jobInfos = {};
                this.jobsSummary.processingHistory = [];  % nJobs x 2 matrix with [jobIndex, repetition]

                % result folder
                dateFolder = datestr(now, 'yy-mm-dd');
                pathTemp = [this.generalParams.resultPath dateFolder filesep];
                [~,~,~] = mkdir(pathTemp);
                analysisName = cleanString(this.generalParams.analysisName);
                this.generalParams.resultPathFinal = [pathTemp mkUnusedDir(pathTemp,analysisName)];        
            end
            
            % reload cross validation sets
            if this.generalParams.storeCrossValidationSetsGlobally
                cValFile = [this.generalParams.resultPath 'crossValidationSets.mat'];
                this.crossValidationSetStore.loadFromFile(cValFile);
            end                
        end
                
        
        %__________________________________________________________________
        % start training job processing
        function [trainingJobList, generalParamsOut] = startProcessingJobs(this,trainingJobList)
            
            % local processing
            if ~this.restartAnalysisFlag
                this.logText('START Analysis');
                this.trainingJobList = trainingJobList;
                this.saveAnalysisState();                
            else
                this.logText('CONTINUE Analysis');
            end
            
            % local processing mode
            % start parallel processing pool
            this.parallelToolBoxHandler.restartParallelPool(false);
            
            this.startLocalJobs();           
            
            trainingJobList = this.trainingJobList;
            % ready, save information
            generalParamsOut = this.generalParams;
            
            % store cross validation sets
            this.saveCrossValidationSets();
            
        end
        
        %__________________________________________________________________
        % start training job processing        
        function saveCrossValidationSets(this)
            if this.generalParams.storeCrossValidationSetsGlobally
                cValFile = [this.generalParams.resultPath 'crossValidationSets.mat'];
                this.crossValidationSetStore.saveToFile(cValFile);
            end                  
        end
        
           
        %__________________________________________________________________
        % start local job processing
        function startLocalJobs(this)
                                    
            fprintf('> Starting LOCAL processing of %d optimization job(s)... \n', numel(this.trainingJobList));
            fprintf('> Results will be in: %s\n', this.generalParams.resultPathFinal);
            totalTimer = tic();
            for iJob = 1:numel(this.trainingJobList)
                this.currentJobIndex = iJob;
                fprintf('> Processing Job %d/%d \n',iJob,numel(this.trainingJobList)); 
                % job handling
                this.processSingleJob(iJob);
                this.jobsSummary.jobInfos{iJob} = this.trainingJobList{iJob}.jobSummary;                
            end
            totalTime = toc(totalTimer);
            totalTimeStr = secs2hms(totalTime);
            
            %store job summary (for later automatic multiple job analyes)
            jobsSummary = this.jobsSummary;
            save([this.generalParams.resultPathFinal 'jobsSummary.mat'],'jobsSummary','-v7.3');
                        
        end
 

        
        
        %__________________________________________________________________
        % process single local job
        function processSingleJob(this,jobIndex)
            % job summary
            job = this.trainingJobList{jobIndex};
            if ~isfield(job,'jobSummary')
                job.jobSummary = struct;
                job.jobSummary.repetitionResultPathRelative = {};
            end
            repetitionActive = job.jobParams.nRepetitions>1;
            allRepsAlreadyDone = 1;
            for iRep = 1:job.jobParams.nRepetitions
                
                if this.jobAlreadyDone(this.currentJobIndex, iRep)    
                   fprintf('>> Job already done: job %d repetition %d SKIPPING\n',this.currentJobIndex ,iRep);
                else
                    allRepsAlreadyDone = 0;
                    s=sprintf('Job %d/%d processing repetition %d/%d',this.currentJobIndex,numel(this.trainingJobList),iRep,job.jobParams.nRepetitions);
                    this.logText(s);
                    % make result paths
                    job = this.prepareJobResultFolder(job,repetitionActive, iRep);
                    job.jobSummary.repetitionResultPathRelative{end+1} = job.jobParams.resultPathRelative;
                    % display job infos
                    if this.generalParams.verbosityLevel > 0
                        this.displayJobInfos(job);
                    end

                    %make feature distribution analysis
                    if job.jobParams.performFeatureDistributionAnalysis
                        this.performFeatureDistributionAnalysis(job);
                    end         

                    % init strategy class object
                    optimizationStrategyObject = [];
                    trainingInitSuccessful = 0;
                    try
                        if this.generalParams.verbosityLevel > 0
                            fprintf('> Starting optimization class %s \n',job.jobParams.optimizationStrategy);
                        end   
                        % string to class object
                        optimizationStrategyObjectConstructor = str2func(job.jobParams.optimizationStrategy);
                        optimizationStrategyObject = optimizationStrategyObjectConstructor();
                        trainingInitSuccessful = 1;
                    catch e
                        warning('Initalization of optimization class %s not successful. Error: %s \n',...
                            job.jobParams.optimizationStrategy, e.message);
                    end
                    if trainingInitSuccessful
                        % now start
                        optimizationStrategyObject.optimizationControllerHandle = this;
                        optimizationStrategyObject.init(this.generalParams,job);
                        optimizationStrategyObject.startTrainingProcess();
                    end 

                    % repetition finished
                    this.trainingJobList{jobIndex} = job;
                    
                    %handle job history
                    this.jobsSummary.processingHistory = ...
                    [this.jobsSummary.processingHistory; [this.currentJobIndex,  iRep]];
                    this.saveAnalysisState();

                    % close matlabpool sometimes to save memory
                    % close every now and then
                    this.totalJobCounter = this.totalJobCounter + 1;
                    this.parallelToolBoxHandler.checkTimePassedAndRestartIfNecessary();
                end
            end
            if ~allRepsAlreadyDone
                % job summary
                job.jobSummary.job = job; % -> job is also stored in subfolder resultPathRelative
                job.jobSummary.resultPathRelative = job.jobParams.resultPathRelativeBase;

                % job repetition statistics
                pathAbs = [this.generalParams.resultPathFinal];
                jobInfos =struct;
                jobInfos.job = job;
                jobInfos.repetitionResultPathRelative = job.jobSummary.repetitionResultPathRelative;
                jobInfos.resultPathRelative = job.jobParams.resultPathRelativeBase;
                aggregatedResults = this.repetitionStats.performEvaluations(jobInfos,pathAbs,jobIndex);

                this.trainingJobList{jobIndex} = job;

                % save state
                this.saveAnalysisState();
            end
        end     
        
        %__________________________________________________________________
        % handle repetitions
        function flag = jobAlreadyDone(this, jobIndex, repetitionIndex)      
            flag = 0;
            for ii = 1:size(this.jobsSummary.processingHistory,1)
                if (this.jobsSummary.processingHistory(ii,1) == jobIndex) && ...
                   (this.jobsSummary.processingHistory(ii,2) == repetitionIndex)     
                    flag = 1;
                end
            end
        end
        
        
        %__________________________________________________________________
        % display job infos
        function displayJobInfos(this,job)
           disp('---------------------------')
           fprintf('Job data set\n - Name: %s\n',job.dataSet.dataSetName);
           fprintf(' - Input data: %d total samples.\n',...
              job.dataSet.nSamples );
           fprintf(' - Number of classes: %d\n', job.dataSet.nClasses);
           for iClass=1:numel(job.dataSet.classIds)
               cClassId = job.dataSet.classIds(iClass);
               classLabels =job.dataSet.targetClasses;
               nSamplesClass = sum(classLabels==cClassId);
               fprintf('  - Class %d: %s with %d samples\n',cClassId,job.dataSet.classNames{iClass},nSamplesClass);
           end
           fprintf(' - Number of features: %d \n',job.dataSet.nFeatures)
           totalDimensions = 0;
           for iFeat = 1:numel(job.dataSet.featureNames)
               cField = job.dataSet.featureNames{iFeat};
               cData = job.dataSet.instanceFeatures.(cField);
               %fprintf('  - Feature %d: %s with %d dimension(s)\n',iFeat, cField,size(cData,2));
               totalDimensions = totalDimensions + size(cData,2);
           end             
	       fprintf(' - Number of total dimensions: %d \n',totalDimensions);
           fprintf('Job parameter\n');
           if numel(job.jobParams.jobDescription) > 0
               fprintf(' - Description:%s \n',job.jobParams.jobDescription);
           end
           fprintf(' - Optimization strategy: %s \n',job.jobParams.optimizationStrategy);
           fprintf(' - StopCriterion: Optimization time: %0.2f hours\n',job.jobParams.stopCriterionComputingTimeHours);
           fprintf(' - StopCriterion: Quality metric: %0.3f \n',job.jobParams.stopCriterionGoalQualityMetric);
           fprintf(' - StopCriterion: Number iterations: %0.0f \n',job.jobParams.stopCriterionIterationNumber);
        end     
                

        %__________________________________________________________________
        % make sub folders
        function job = prepareJobResultFolder(this,job,repetitionActive, iRepetition)
            if numel(job.jobParams.jobDescription) > 0
                folderSuffix = ['_' cleanString(job.jobParams.jobDescription)];
            else
                folderSuffix = '';
            end
            job.jobParams.resultPathRelativeBase = sprintf('Job%04d%s', ...
                job.number,folderSuffix);
            % save relative path
            if repetitionActive
                job.jobParams.resultPathRelative = sprintf('%s%srep%d', ...
                 job.jobParams.resultPathRelativeBase,filesep,iRepetition);
            else
                job.jobParams.resultPathRelative = job.jobParams.resultPathRelativeBase;
            end
            
            % absolute path
            job.jobParams.resultPath = [this.generalParams.resultPathFinal job.jobParams.resultPathRelative filesep];
            [~,~,~] = mkdir(job.jobParams.resultPath);
            
            % write job info as text
            stringJob = struct2string(job.jobParams);
            stringStrategyParams = struct2string(job.jobParams.optimizationStrategyParameters);
            jobStrings = {stringJob, stringStrategyParams};
            
            saveMultilineString2File(jobStrings,[job.jobParams.resultPath 'jobParams.txt']);

        end             

        
        %__________________________________________________________________
        % analyze feature value ranges/domains graphically
        function performFeatureDistributionAnalysis(this,job)
            disp('> Performing graphical feature distribution analysis')
            directory = [job.jobParams.resultPath 'featureDistribution' filesep];
            [~,~,~] = mkdir(directory);
            featureDistributionAnalysis(job.dataSet,directory,false);
        end              
        
        %__________________________________________________________________
        % log text line   
        function logText(this, textLine)
            appendLog([this.generalParams.resultPathFinal 'log.txt'],textLine);
            fprintf('%s\n',textLine);
        end
        
        
      end % end methods public ____________________________________________
      
      
      
      
      methods(Access = private)
      
      end %private methods
        

    
    
end

        

        

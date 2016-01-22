% Class definition AROMSFrameworkController
%
% This is the main class for the AROMS Machine Learning Framework
% that controls the job processing for the framework.
% A job is defined by a dataSet struct and parameters.
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef AROMSFrameworkController < handle
    
    properties 

        % struct with general parameters like result path and parallel information
        generalParams = struct;
        
        % optimization jobs in this list
        jobList = {};
        
        % framework version (year.month)
        softwareVersion = 2015.11;
    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = AROMSFrameworkController()
            obj.generalParams = FrameworkParameterController.checkGeneralParamters(obj.generalParams);
            obj.generalParams.softwareVersion = obj.softwareVersion;
            % init random generator
            rng('shuffle');
        end
        
            
        %__________________________________________________________________
        % set general parameters
        function setGeneralParameters(this, generalParamsIn)
            % check parameter and add standard values
            this.generalParams = FrameworkParameterController.checkGeneralParamters(generalParamsIn);
            this.generalParams.softwareVersion = this.softwareVersion;
            [pathstring] = fileparts(which('AROMSFrameworkController'));
            this.generalParams.frameworkPath = [pathstring filesep];
        end
        
        
        %__________________________________________________________________
        % add job for framework optimization/training
        % a job consists of a dataSet struct and the struct jobParameters.
        % If a cell array of multiple jobParameters is passed, as many jobs
        % with the same dataSet will be created.
        function addJob(this, dataSetIn, jobParameters)
            % allow multiple parameter sets to add
            if ~iscell(jobParameters)
                jobParameters = {jobParameters};
            end
                % add dataSet to job "multiplied" by parameters sets
                for iJob=1:numel(jobParameters)
                    [jobParams, validConfig, dataSetPrepared] = FrameworkParameterController.checkTrainingJobParameters(jobParameters{iJob},dataSetIn);
                    if validConfig
                        job = struct;
                        job.number = numel(this.jobList)+1;                        
                        job.jobParams = jobParams;
                        job.dataSet = dataSetPrepared;
                        this.jobList{end+1} = job;
                    else
                        warning('Skipped job.');
                    end
                end     
        end       
        
        
        %__________________________________________________________________
        % removes jobs 
        function clearJobs(this)
            this.jobList = {};
        end                    
    
        
        %__________________________________________________________________
        % Prepares analysis path with all jobs and parameters.
        % Does not start analysis!
        function analysisPath = prepareAnalysisPath(this)

            %init training controller and prepare results
            frameworkOptimizationController = FrameworkOptimizationController(this.generalParams);
            frameworkOptimizationController.prepareTraining();              
            frameworkOptimizationController.trainingJobList = this.jobList;
            frameworkOptimizationController.analysisStartTimer = tic; % set timer for real start/preparation
            frameworkOptimizationController.saveAnalysisState();           
            analysisPath = frameworkOptimizationController.generalParams.resultPathFinal;
            frameworkOptimizationController.logText(['Prepared analysis path in ' analysisPath]);
                        
            fprintf('===================\n');
            fprintf('> New AROMS analysis path prepared:\n%s\n> Run <this>.runAnalysis(analysisPath) or AROMSFrameworkController.runAnalysisFailSafe(analysisPath); \n',analysisPath);
        end           
          
           
        
        %__________________________________________________________________
        % Run analysis given by a prepared path
        %
        function resultStruct = runAnalysis(this, analysisPath)
            % check directory delimiter
            analysisPath = checkPathDelimiter(analysisPath);
            
            fprintf('===================\n');
            fprintf('> This is AROMS MachineLearningFramework version %0.2f by Fabian Buerger, University of Duisburg-Essen, Germany.\n', this.softwareVersion);
            fprintf('> Start/continue analysis in analysisPath=%s \n', analysisPath);

            resultStruct = struct;
                        
            %init training controller and prepare results
            frameworkOptimizationController = FrameworkOptimizationController(struct);
            frameworkOptimizationController.initStateFromPath(analysisPath);
            
            frameworkOptimizationController.prepareTraining();  
            
            % start training and return results
            [jobListWithResults, generalParamsOut] = frameworkOptimizationController.startProcessingJobs({});  
            this.generalParams = generalParamsOut;
            resultStruct.jobListWithResults = jobListWithResults;
            resultStruct.generalParams = generalParamsOut;
            
            if frameworkOptimizationController.analysisStartTimer > 0
                totalTimeHours = toc(frameworkOptimizationController.analysisStartTimer)/3600;
            else
                totalTimeHours = 0; 
            end
            finishMessage = sprintf('AROMS analysis finished successfully for path:\n%s\nTotal time since analysis preparation: %0.2f hours',analysisPath,totalTimeHours);
            frameworkOptimizationController.logText(finishMessage);  
            fprintf('=====================================\n');
            
            
            % call finish script with message
            if isfield(this.generalParams,'analysisFinishFunction')
                try
                    functionCall = sprintf('%s(finishMessage);',this.generalParams.analysisFinishFunction);
                    eval(functionCall);
                catch
                    disp('Finish message error.')
                end
            end
        end         
        

        
      end % end methods public ____________________________________________
      
     methods(Static)
      
        %__________________________________________________________________
        % Run analysis given by a prepared path in robust way:
        % when errors occur, the anylsis is continued automaticall
        %
        % AROMSFrameworkController.runAnalysisFailSafe(analysisPath)
        function resultStruct = runAnalysisFailSafe(analysisPath)
            % return results
            resultStruct = struct;
            repeatFlag = 1;
            while repeatFlag
               %warning('Failsafe off! Try catch commented!')
               try
                    mlfr=AROMSFrameworkController();
                    resultStruct = mlfr.runAnalysis(analysisPath); 
                    repeatFlag = 0;
               catch me
                    fprintf('ERROR occured: %s \n',me.message);
                    repeatFlag = 1;
                    try
                        appendLog([analysisPath 'log.txt'],['ERROR - ' me.message]);
                    catch
                    end
                    disp('Trying again...');
                    pause(10);                    
                    try  % most errors come from parallel pool, try to restart
                        delete(gcp('nocreate'));
                        pause(2);  
                    catch

                    end                    
               end
            end
        end      
      
        
        %__________________________________________________________________
        % Add a analysisPath to analysis queue located in textfile
        % basePath/analysisQueue.txt
        % if priority is >0, it will be added before all other outstanding
        % analyses
        % -
        % AROMSFrameworkController.addAnalysisToQueue(basePath, analysisPath, priority);
        function addAnalysisToQueue(basePath, analysisPath, priority)
            basePath = checkPathDelimiter(basePath); 
            analysisQueueFile = [basePath 'analysisQueue.txt'];
            if exist(analysisQueueFile,'file') ~= 2
                warning('File %s does not exist, creating one.',analysisQueueFile);
                saveMultilineString2File({},analysisQueueFile);
            end
            
            % read file
            analysisQueue = readMultilineString(analysisQueueFile);
            
            % check existence
            [existsAlready, indices] = cellStringsContainString(analysisQueue,analysisPath);
            if existsAlready
                warning('Analysis path already in Queue!');
                analysisQueue(indices) = [];
            end
            
            if priority > 0
                % prepend
                analysisQueue = [analysisPath;analysisQueue];
            else
                % append
                analysisQueue = [analysisQueue;analysisPath];
            end
            
            fprintf('AROMS Analysis Queue: Added analysis - run AROMSFrameworkController.runAnalysisQueueDeamon(basePath);\n %s\n',analysisPath);
            
            % save file 
            saveMultilineString2File(analysisQueue,analysisQueueFile);
        end      
        
        
        %__________________________________________________________________
        % process Analyses placed as directory list in text file
        % basePath/analysisQueue.txt
        % -
        % AROMSFrameworkController.runAnalysisQueueDeamon(basePath)
        function runAnalysisQueueDeamon(basePath)
            basePath = checkPathDelimiter(basePath);
            
            analysisQueueFile = [basePath 'analysisQueue.txt'];
            running = 1;
            counter = 0;
            while running
                
                % check file
                if exist(analysisQueueFile,'file') == 2
                    analysisQueue = readMultilineString(analysisQueueFile);
                    if ~isempty(analysisQueue)
                        currentPath = analysisQueue{1};
                        
                        if exist(currentPath,'dir') == 7 
                            fprintf('==========================================================\n AROMS Framework Analysis Queue: Start analysis in \n%s\n==========================================================\n',currentPath);
                            
                            % run on current path
                            AROMSFrameworkController.runAnalysisFailSafe(currentPath);                            
                            
                            %done! try to remove from list (may have been
                            %updated now!)
                            analysisQueue = readMultilineString(analysisQueueFile);
                            [existsAlready, indices] = cellStringsContainString(analysisQueue,currentPath);
                            analysisQueue(indices) = [];
                            saveMultilineString2File(analysisQueue,analysisQueueFile);
                            counter = 0;
                        else
                            % not exist
                            warning('AROMS Analysis Queue: Analysis path %s does not exist.\n',currentPath);
                            analysisQueue{1} = [];
                            saveMultilineString2File(analysisQueue,analysisQueueFile);
                        end
                        pause(1); % wait a bit
                    else %nothing to do
                        fprintf('AROMS Analysis Queue: Queue file empty, waiting...\n')
                        counter = counter+1;
                        if counter > 10
                            pause(10); % wait a bit longer
                        elseif counter > 20
                            pause(120);
                        else
                            fprintf('AROMS Analysis Deamon stopped!\n')
                            return;
                        end
                        
                    end
                else
                    warning('AROMS Analysis Queue: Analysis file %s not found, exiting.\n',analysisQueueFile)
                    running = 0;
                end
            end
        end      
              
        
        
     end % end static methods
      
      
        
        
   
    
    
end

        

        

% Class definition MultiJobStatistics
%
% This class handles the analysis and comparison of statistics of multiple
% jobs. Its base structure are matrices of 
% - nDataSets (y)
% - nMetaparameters (x)  
% nDataSets x nMetaparameters -> jobfolder
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef MultiJobStatistics < handle
    
    properties 

        % base data (collected during training)
        inputJobResultsDirs = '';
        outputDir = '';
        jobsSummaries;
        
        dataSetIds = {};
        metaParameterIds = {};
        jobInfoMatrix = {};
        dataSetList = {};
        
        nDataSets = 0;
        nMetaParams = 0;
        
        statisticParams = struct;
        
    end
    
    %====================================================================
    methods
                
        
        %__________________________________________________________________
        % init class from job info file
        % - inputJobResultsDirs -> cell array with paths to result dir with
        %   all jobs, or single path
        % - outputDir -> path where results should be written to
        % - statisicParams -> struct with parameters

        function initStatistics(this, inputJobResultsDirs, outputDir, statisticParams)
            if ~iscell(inputJobResultsDirs)
                inputJobResultsDirs = {inputJobResultsDirs};
            end
            for ii=1:numel(inputJobResultsDirs)
                inputJobResultsDirs{ii} = checkPathDelimiter(inputJobResultsDirs{ii});
            end    
            
            this.statisticParams = statisticParams;
            this.inputJobResultsDirs = inputJobResultsDirs;
            
            this.outputDir = checkPathDelimiter(outputDir);
            [~,~,~] = mkdir([this.outputDir 'csv']);
            [~,~,~] = mkdir([this.outputDir 'latex']);
            
            this.jobsSummaries = {};
            % get unique captions
            this.dataSetIds = {};
            this.metaParameterIds = {};            
            
            % loop through all paths and collect data
            for iPath = 1:numel(inputJobResultsDirs)
                cPath = inputJobResultsDirs{iPath};                

                jobSummaryFile = [cPath 'jobsSummary.mat'];
                load(jobSummaryFile); % job summary should be in workspace now
                this.jobsSummaries{end+1} = jobsSummary;

                nJobs = numel(jobsSummary.jobInfos);
                for iJob = 1:nJobs
                    cJobInfo = jobsSummary.jobInfos{iJob};

                     dataSetId = cJobInfo.job.jobParams.jobGroupInfo.dataSetId;

                     metaParameterId = cJobInfo.job.jobParams.jobGroupInfo.profileId;
                     if numel(cJobInfo.job.jobParams.jobGroupInfo.metaParameterDescription) > 0
                         metaParameterId =[metaParameterId '_' cJobInfo.job.jobParams.jobGroupInfo.metaParameterDescription];
                     end
                     cJobInfo.job.jobParams.jobGroupInfo.metaParameterId = metaParameterId;
                     cJobInfo.job.jobParams.jobGroupInfo.dataSetId = dataSetId;

                     this.jobsSummaries{end}.jobInfos{iJob} = cJobInfo;

                     % make unique lists, datasets from first path only
                     if iPath == 1
                        [this.dataSetIds, added] = uniqueStringList(this.dataSetIds, dataSetId);
                        if added
                            this.dataSetList{end+1} = cJobInfo.job.dataSet;
                        end
                     end
                     this.metaParameterIds = uniqueStringList(this.metaParameterIds, metaParameterId);                
                end            
            end            
            
            this.nDataSets =     numel(this.dataSetIds);
            this.nMetaParams =   numel(this.metaParameterIds);
            this.jobInfoMatrix = cell(this.nDataSets, this.nMetaParams);
            
            totalJobs = 0;
            % fill matrix with job paths
            for iPath = 1:numel(inputJobResultsDirs)
                cPath = inputJobResultsDirs{iPath};   
                jobsSummary = this.jobsSummaries{iPath};
                nJobs = numel(jobsSummary.jobInfos);
                totalJobs = totalJobs + nJobs;
                for iJob = 1:nJobs
                     cJobInfo = jobsSummary.jobInfos{iJob};
                     cJobInfo.resultPath = cPath;
                     cJobInfo.resultPathIndex = iPath;
                     metaParamIndex = findIndexOfString(this.metaParameterIds, cJobInfo.job.jobParams.jobGroupInfo.metaParameterId);
                     dataSetIndex = findIndexOfString(this.dataSetIds, cJobInfo.job.jobParams.jobGroupInfo.dataSetId);
                     this.jobInfoMatrix{dataSetIndex, metaParamIndex} = cJobInfo;
                end            
            end            
            
            fprintf('Multi Job Data with %d jobs in %d paths: %d datasets and %d metaparameters \n',totalJobs,numel(inputJobResultsDirs),this.nDataSets,this.nMetaParams);
            fprintf('  -dataSetIds: %s\n', cellArrayToCSVString(this.dataSetIds,','));
            fprintf('  -metaParameterIds: %s\n', cellArrayToCSVString(this.metaParameterIds,','));
            
        end
        
        %__________________________________________________________________
        % make standard stats and save to outputDir
        %  
        %
        function makeStandardStats(this, statList, statParamsBase)       
            
            multiplicationFactorAccuracy = 1;
            nDigits = 4;
            
            allStats = ~iscell(statList);
            if allStats || cellStringsContainString(statList,'info')    
                   this.makeInfoStats(statParamsBase);
            end    
            if allStats || cellStringsContainString(statList,'training_average_cv_acc')    
                statParams = statParamsBase;
                statParams.statisticFunction = 'training_average_cv_acc';
                statParams.multiplicationFactor = multiplicationFactorAccuracy;
                statParams.highlightBestValues = 'max';
                statParams.nDigitsMean = nDigits;
                statParams.nDigitsStd = nDigits;
                this.exportStat(statParams);     
            end         
            if allStats || cellStringsContainString(statList,'training_average_cv_acc_best')    
                statParams = statParamsBase;
                statParams.statisticFunction = 'training_average_cv_acc_best';
                statParams.multiplicationFactor = multiplicationFactorAccuracy;
                statParams.highlightBestValues = 'max';
                statParams.hideStd = 1;                
                statParams.nDigitsMean = nDigits;
                statParams.nDigitsStd = nDigits;
                this.exportStat(statParams);     
            end                 
            if allStats || cellStringsContainString(statList,'training_time')
                statParams = statParamsBase;
                statParams.statisticFunction = 'training_time';
                statParams.multiplicationFactor = 1/60; % minutes
                statParams.highlightBestValues = 'min';
                statParams.nDigitsMean = 2;
                statParams.nDigitsStd = 2;
                this.exportStat(statParams);                     
            end    
            if allStats || cellStringsContainString(statList,'average_classification_time_bestPipeline')
                statParams = statParamsBase;
                statParams.statisticFunction = 'average_classification_time_bestPipeline';
                statParams.multiplicationFactor = 1000; % milliseconds
                statParams.highlightBestValues = 'min';
                statParams.nDigitsMean = 2;
                statParams.nDigitsStd = 2;
                this.exportStat(statParams);                     
            end        
            if allStats || cellStringsContainString(statList,'average_classification_time_bestPipeline_exportOnly')
                statParams = statParamsBase;
                statParams.statisticFunction = 'average_classification_time_bestPipeline';
                statParams.multiplicationFactor = 1000; % milliseconds
                statParams.highlightBestValues = 'min';
                statParams.statParams.exportFiles = 0;
                statParams.nDigitsMean = 2;
                statParams.nDigitsStd = 2;
                statData = this.exportStat(statParams);
                statData.dataSetList = this.dataSetList;      
                save([this.outputDir filesep 'classificationTimesDatapackage.mat'],'statData');
                   
            end                 
            
            
            if allStats || cellStringsContainString(statList,'training_time_influence_graph')
                statParams = statParamsBase;
                statParams.statisticFunction = 'training_time';
                statParams.multiplicationFactor = 1/60; % minutes
                statParams.highlightBestValues = 'min';
                statParams.statParams.exportFiles = 0;
                statParams.nDigitsMean = 2;
                statParams.nDigitsStd = 2;
                statData = this.exportStat(statParams); 
                scaleFactor = 1/60;
                
                iM = statParams.metaParamIndexSelection(1);
                metaName = this.metaParameterIds{iM};
                fprintf('meta id:  %s \n',metaName); 
                infoByDataset = {};
                for iDs = 1:numel(this.dataSetIds)                
                    info = struct;
                    info.meanVal = statData.meanMatrixFull(iDs,iM)*scaleFactor;
                    info.stdVal = statData.stdMatrixFull(iDs,iM)*scaleFactor;
                    info.dataSet = this.dataSetList{iDs};                   
                    infoByDataset{iDs} = info;
                end
                
                dataPackage = struct;
                dataPackage.infoByDataset = infoByDataset;
                dataPackage.statParams = statParams;
                dataPackage.resultPath = [this.outputDir filesep];
                frameworkTimeInfluence(dataPackage);
                
            end              
            
            if allStats || cellStringsContainString(statList,'test_acc_top_single_pipeline')
                statParams = statParamsBase;
                statParams.statisticFunction = 'test_acc_top_single_pipeline';
                statParams.multiplicationFactor = multiplicationFactorAccuracy;
                statParams.highlightBestValues = 'max';
                statParams.nDigitsMean = nDigits;
                statParams.nDigitsStd = nDigits;
                this.exportStat(statParams);                   
            end     
            if allStats || cellStringsContainString(statList,'test_acc_top_single_pipeline_best')
                statParams = statParamsBase;
                statParams.statisticFunction = 'test_acc_top_single_pipeline_best';
                statParams.multiplicationFactor = multiplicationFactorAccuracy;
                statParams.highlightBestValues = 'max';
                statParams.hideStd = 1;                
                statParams.nDigitsMean = nDigits;
                statParams.nDigitsStd = nDigits;
                this.exportStat(statParams);                   
            end                 
            if allStats || cellStringsContainString(statList,'combined_train_test_acc') 
                if numel(statParamsBase.dataSetIndexSelection) ~= 1
                    disp('combined_train_test_acc only for 1 dataset')
                else       
                    statParams = statParamsBase;
                    statParams.statisticFunction = 'training_average_cv_acc';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.highlightBestValues = 'max';
                    statParams.nDigitsMean = nDigits;
                    statParams.nDigitsStd = nDigits;
                    statParams.exportFiles = 0;
                    statParams.useTTest = queryStruct(statParams,'useTTest',0);
                    statParams.useTTestReferenceSource = queryStruct(statParams,'useTTestReferenceSource','');
                    statDataTrain = this.exportStat(statParams);    

                    statParams.statisticFunction = 'test_acc_top_single_pipeline';
                    statDataTest = this.exportStat(statParams);    

                    % fuse tables
                    ttrain = statDataTrain.tableMatrixLatex;
                    ttest = statDataTest.tableMatrixLatex;
                    if ~statParams.transposeTable
                        ttrain = ttrain';
                        ttest = ttest';
                    end
                    tableFull = [ttrain, ttest(:,2:end)];
                    tableFull{1,2} = [tableFull{1,2} ' Cross-validation accuracy'];
                    tableFull{1,3} = [tableFull{1,3} ' Generalization accuracy'];
                    if ~statParams.transposeTable
                        tableFull = tableFull';
                    end                       
                    statParams.exportMode = 'latex';
                    statParams.statName = 'combined_train_test_acc';
                    tableStrings = this.getTableStringLines(tableFull,statParams);      
                    fileName = [this.outputDir filesep 'latex' filesep 'combined_train_test_acc.tex'];
                    saveMultilineString2File(tableStrings,fileName);       
                    
                end
            end  
            if allStats || cellStringsContainString(statList,'multipipeline_param_comparison') 
                    statParams = statParamsBase;
                    statParams.statisticFunction = 'test_acc_multipipeline_top_majority_list';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.nPipes = 1:50;
                    statParams.showDifftoSingle = 0;
                    statParams.exportFiles = 0;
                    statParams.useTTest=0;
                    statParams.metaParamIndexSelection = statParamsBase.metaParamIndexSelection;
                    
                    statData = this.exportStat(statParams);    
                    % fixed meta index
                    iM = statParams.metaParamIndexSelection(1);
                    metaName = this.metaParameterIds{iM};
                    fprintf('meta id:  %s \n',metaName); 
                    infoByDataset = {};
                    for iDs = 1:numel(this.dataSetIds)
                        valueLists = statData.valueListMatrixFull{iDs,iM};
                       
                        stackedList = [];
                        for ii=1:numel(valueLists)
                            valList = valueLists{ii};
                            if statParams.showDifftoSingle
                                valList = valList - valList(1);
                            end
                            stackedList = [stackedList;valList];
                        end
                        % stattest
                        singleConfigList = stackedList(:,1);
                        statResults = [];
                        for iVal = 1:size(stackedList,2)
                            cList = stackedList(:,iVal);
                            if ~any(isnan(cList))
                                testResults = statisticalTests(singleConfigList, cList);    
                                statResults(iVal) = testResults.h;
                            end
                        end
                        meanValues = [];
                        stdValues = [];
                        for ii =1:size(stackedList,2)
                            vList = stackedList(:,ii);
                            vList(isnan(vList)) = [];
                            meanValues(ii) = mean(vList);
                            stdValues(ii) = std(vList);
                        end
                        meanValues_StaticSel = meanValues(statParams.nPipes);
                        stdValues_StaticSel = stdValues(statParams.nPipes);    
                        item = struct;
                        item.dataSetIndex = iDs;
                        item.dataSet = this.dataSetList{iDs};
                        item.meanValues_StaticSel = meanValues_StaticSel;
                        item.stdValues_StaticSel = stdValues_StaticSel;
                        item.valueList_StaticSel = stackedList;
                        item.xValues_StaticSel = 1:numel(meanValues_StaticSel);
                        infoByDataset{end+1} = item;
                    end  
                    
                    % fitness dependent
                    statParams.statisticFunction = 'test_acc_multipipeline_fitnessDependent';
                    statData = this.exportStat(statParams);    
                    % fixed meta index

 
                    for iDs = 1:numel(this.dataSetIds)
                        valueData = statData.valueListMatrixFull{iDs,iM};
                        accValueLists = valueData.test_MP_fusion_FitDep_accuracyFitnessDelta;  
                        dFitnessThresh = valueData.test_MP_fusion_FitDep_deltaFitnessValues{1}; % the same for all
                        
                        stackedList = [];
                        for ii=1:numel(accValueLists)
                            valList = accValueLists{ii};
                            if statParams.showDifftoSingle
                                valList = valList - valList(1);
                            end
                            stackedList = [stackedList;valList];
                        end

                        meanValues = mean(stackedList,1);
                        stdValues = std(stackedList,0,1);
                        meanValues_FitDepSel = meanValues(statParams.nPipes);
                        stdValues_FitDepSel = stdValues(statParams.nPipes);    
                        
                        infoByDataset{iDs}.meanValues_FitDepSel = meanValues_FitDepSel;
                        infoByDataset{iDs}.stdValues_FitDepSel = stdValues_FitDepSel;
                        infoByDataset{iDs}.valueList_FitDepSel = stackedList;
                        infoByDataset{iDs}.xValues_FitDepSel = dFitnessThresh;
                    end                      
                                        
                exportStrings = {};
                % static selection
                xValues = [1 10 25 50];
                xValues = [25];
                header = 'Dataset';
                for ii= 1:numel(xValues)
                    header = [header ' & ' sprintf('npipes=%d',xValues(ii))  ]; 
                end
                exportStrings{end+1} = header;
                for iDs = 1:numel(this.dataSetIds)
                    dataForDs = infoByDataset{iDs};
                    valLine = sprintf('%s & ',dataForDs.dataSet.dataSetName);
                    
                    for ii= 1:numel(xValues)
                        xVal = xValues(ii);
                        yVal = dataForDs.meanValues_StaticSel(xVal);
                        stdVal = dataForDs.stdValues_StaticSel(xVal);
                        valueList = dataForDs.valueList_StaticSel(:,xVal);
                        compValList = dataForDs.valueList_StaticSel(:,1);
                        valueList(isnan(valueList))=[];
                        compValList(isnan(compValList))=[];
                        testResults = statisticalTests(valueList, compValList); 
                        addText = testResults.stringMaker;
                        addItem = sprintf('%0.4f $ \\pm $ %0.4f %s',yVal,stdVal,addText);
                        valLine = [valLine addItem];
                        if ii < numel(xValues)
                             valLine = [valLine ' & '];
                        end
                    end                    
                    
                    exportStrings{end+1} = valLine;
                end
                
                outputFile = [this.outputDir filesep 'multipipelineComparison_Static.txt'];
                saveMultilineString2File(exportStrings,outputFile);
                

                exportStrings = {};
                % fitness dependent selection
                xValues = [0 0.01 0.03 0.04];
                xValues = [0.03];
                
                dFitnessThresh;
                xValIndices = [];
                for ii=1:numel(xValues)
                    xValIndices(ii) = find(dFitnessThresh==xValues(ii));
                end
                
                header = 'Dataset';
                for ii= 1:numel(xValues)
                    header = [header ' & ' sprintf('thresh=%0.4f',xValues(ii))  ]; 
                end
                exportStrings{end+1} = header;
                for iDs = 1:numel(this.dataSetIds)
                    dataForDs = infoByDataset{iDs};
                    valLine = sprintf('%s & ',dataForDs.dataSet.dataSetName);
                    
                    for ii= 1:numel(xValIndices)
                        xVal = xValIndices(ii);
                        yVal = dataForDs.meanValues_FitDepSel(xVal);
                        stdVal = dataForDs.stdValues_FitDepSel(xVal);
                        valueList = dataForDs.valueList_FitDepSel(:,xVal);
                        
                        compValList = dataForDs.valueList_StaticSel(:,1);  % to ECA full
                        valueList(isnan(valueList))=[];
                        compValList(isnan(compValList))=[];
                        testResults = statisticalTests(valueList, compValList); 
                        addText = testResults.stringMaker;
                        addItem = sprintf('%0.4f $ \\pm $ %0.4f %s',yVal,stdVal,addText);
                        valLine = [valLine addItem];
                        if ii < numel(xValues)
                             valLine = [valLine ' & '];
                        end
                    end                    
                    
                    exportStrings{end+1} = valLine;
                end
                
                outputFile = [this.outputDir filesep 'multipipelineComparison_FitnessDep.txt'];
                saveMultilineString2File(exportStrings,outputFile);                
                
                    
            end              
            
            
            if allStats || cellStringsContainString(statList,'main_metrics_data_export') 
   
                %statParamsBase.dataSetIndexSelection
                
                statParams = statParamsBase;
                statParams.statisticFunction = 'training_average_cv_acc';
                statParams.multiplicationFactor = multiplicationFactorAccuracy;
                statParams.highlightBestValues = 'max';
                statParams.nDigitsMean = nDigits;
                statParams.nDigitsStd = nDigits;
                statParams.exportFiles = 0;
                statParams.useTTest = queryStruct(statParams,'useTTest',0);
                statParams.useTTestReferenceSource = queryStruct(statParams,'useTTestReferenceSource','');
                statDataTrain = this.exportStat(statParams);    

                statParams.statisticFunction = 'test_acc_top_single_pipeline';
                statDataTest = this.exportStat(statParams);    

                statParams.statisticFunction = 'training_time';
                statDataTime = this.exportStat(statParams);    
                
                datapackage = struct;
                datapackage.statDataTrain = statDataTrain;
                datapackage.statDataTest = statDataTest;
                datapackage.statDataTime = statDataTime;
                
                fileName = [this.outputDir filesep 'mainmetrics_datapackage.mat'];
                save(fileName,'datapackage');     
            end                
            
            if allStats || cellStringsContainString(statList,'best_repetitions') 
    
                statParams = statParamsBase;
                statParams.statisticFunction = 'training_average_cv_acc';
                statParams.multiplicationFactor = multiplicationFactorAccuracy;
                statParams.highlightBestValues = 'max';
                statParams.nDigitsMean = nDigits;
                statParams.nDigitsStd = nDigits;
                statParams.exportFiles = 0;
                statParams.useTTest = 0;
                statParams.useTTestReferenceSource = queryStruct(statParams,'useTTestReferenceSource','');
                statDataTrain = this.exportStat(statParams);    

                statParams.statisticFunction = 'test_acc_top_single_pipeline';
                statDataTest = this.exportStat(statParams);    

                statParams.statisticFunction = 'test_acc_multipipeline_top_majority_list';
                statDataMPCStatic = this.exportStat(statParams);                        

                statParams.statisticFunction = 'test_acc_multipipeline_fitnessDependent';
                statDataMPCFitness = this.exportStat(statParams);                           


                for iDs = statParamsBase.dataSetIndexSelection

                    resLines = {};
                    resLines{end+1} = sprintf('Best repetitions Dataset %d  %s',iDs, this.dataSetIds{iDs});
                    resLines{end+1} = '    ';

                    maxValTrainByMetaParam = [];
                    maxValTestByMetaParam = [];

                    for indexMetaId= statParams.metaParamIndexSelection

                        % find best values
                        metricsTrain = statDataTrain.valueListMatrixFull{iDs,indexMetaId};
                        metricsTest = statDataTest.valueListMatrixFull{iDs,indexMetaId};
                        valueListMPCStatic =  statDataMPCStatic.valueListMatrixFull{iDs,indexMetaId};
                        valueListMPCFitness =  statDataMPCFitness.valueListMatrixFull{iDs,indexMetaId};

                        [maxValTrain,maxIdxTrain] = max(metricsTrain);
                        [maxValTest,maxIdxTest] = max(metricsTest);
                        maxValTrainByMetaParam(end+1) = maxValTrain;
                        maxValTestByMetaParam(end+1) = maxValTest;

                        maxInfoMPCStatic =  getMaxFromVectorCellArray(valueListMPCStatic);
                        maxInfoMPCFitness =  getMaxFromVectorCellArray(valueListMPCFitness.test_MP_fusion_FitDep_accuracyFitnessDelta);
                        thresholds = valueListMPCFitness.test_MP_fusion_FitDep_deltaFitnessValues{1};

                        %maxInfo.maxVal = maxVal;
                        %maxInfo.maxCellIndex = maxCellIndex;
                        %maxInfo.maxVecIndex = maxVecIndex;


                        job = this.jobInfoMatrix{iDs,indexMetaId};
                        bestTrainDir = [job.resultPath job.repetitionResultPathRelative{maxIdxTrain}];
                        bestTestDir = [job.resultPath job.repetitionResultPathRelative{maxIdxTest}];

                        resLines{end+1} = sprintf('========== Metaparam %d, name %s',indexMetaId,statDataTrain.metaParameterCaptionsFull{indexMetaId});
                        resLines{end+1} = '== Highest Fitness';
                        resLines{end+1} = sprintf('Fitness = %0.4f',metricsTrain(maxIdxTrain));
                        resLines{end+1} = sprintf('Generalization = %0.4f',metricsTest(maxIdxTrain));
                        resLines{end+1} = sprintf('dir   %s',bestTrainDir);
                        resLines{end+1} = '== Highest Generalization';
                        resLines{end+1} = sprintf('Fitness = %0.4f',metricsTrain(maxIdxTest));
                        resLines{end+1} = sprintf('Generalization = %0.4f',metricsTest(maxIdxTest));
                        resLines{end+1} = sprintf('dir   %s',bestTestDir); 
                        resLines{end+1} = '== MultiPipeline';
                        resLines{end+1} = sprintf('Static: Best Gen.Acc: %0.4f, NPipes=%d, rep=%d',maxInfoMPCStatic.maxVal,maxInfoMPCStatic.maxVecIndex,maxInfoMPCStatic.maxCellIndex);
                        resLines{end+1} = sprintf('FitDep: Best Gen.Acc: %0.4f, Thresh=%0.4f, rep=%d',maxInfoMPCFitness.maxVal,thresholds(maxInfoMPCFitness.maxVecIndex),maxInfoMPCFitness.maxCellIndex);
                        resLines{end+1} = '   ';       

                    end
                    resLines{end+1} ='=========';
                    outputFile = [this.outputDir filesep sprintf('best_repetitions_ds_%d.txt',iDs)];
                    saveMultilineString2File(resLines,outputFile);
                end  
            end              
            
            
            
            if allStats || cellStringsContainString(statList,'combined_train_test_acc_best') 
                if numel(statParamsBase.dataSetIndexSelection) ~= 1
                    disp('combined_train_test_acc only for 1 dataset')
                else       
                    statParams = statParamsBase;
                    statParams.statisticFunction = 'training_average_cv_acc_best';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.highlightBestValues = 'max';
                    statParams.nDigitsMean = nDigits;
                    statParams.nDigitsStd = nDigits;
                    statParams.hideStd = 1;
                    statParams.exportFiles = 0;
                    statParams.useTTest = 0;
                    statParams.useTTestReferenceSource = '';
                    statDataTrain = this.exportStat(statParams);    

                    statParams.statisticFunction = 'test_acc_top_single_pipeline_best';
                    statDataTest = this.exportStat(statParams);    

                    % fuse tables
                    ttrain = statDataTrain.tableMatrixLatex;
                    ttest = statDataTest.tableMatrixLatex;
                    if ~statParams.transposeTable
                        ttrain = ttrain';
                        ttest = ttest';
                    end
                    tableFull = [ttrain, ttest(:,2:end)];
                    tableFull{1,2} = [tableFull{1,2} ' Cross-validation accuracy'];
                    tableFull{1,3} = [tableFull{1,3} ' Generalization accuracy'];
                    if ~statParams.transposeTable
                        tableFull = tableFull';
                    end                       
                    statParams.exportMode = 'latex';
                    statParams.statName = 'combined_train_test_acc_best';
                    tableStrings = this.getTableStringLines(tableFull,statParams);      
                    fileName = [this.outputDir filesep 'latex' filesep 'combined_train_test_acc_best.tex'];
                    saveMultilineString2File(tableStrings,fileName);       
                    
                end
            end              
            if allStats || cellStringsContainString(statList,'component_influence_barchart')
                if numel(statParamsBase.dataSetIndexSelection) ~= 1
                    disp('component_influence_barchart only for 1 dataset')
                else       
                    statParams = statParamsBase;
                    statParams.addParams = queryStruct(statParams,'addParams',struct);
                    statParams.metaParamIndexSelection = 1:this.nMetaParams;
                    statParams.statisticFunction = 'training_average_cv_acc';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.highlightBestValues = 'max';
                    statParams.nDigitsMean = nDigits;
                    statParams.nDigitsStd = nDigits;
                    statParams.exportFiles = 0;
                    statDataTrain = this.exportStat(statParams);    

                    statParams.statisticFunction = 'test_acc_top_single_pipeline';
                    statDataTest = this.exportStat(statParams);    
                    
                    % find stat meta indices
                    metaVariants = {'ECA-full', 'ECA-noFeatSel', 'ECA-noPreProc', 'ECA-noFeatTrans', 'ECA-simpleClassifier','ECA-defaultHyperparams'};
                    metaVariantIndices = zeros(1,numel(metaVariants));
                    skipAnalysis = 0;
                    for ii=1:numel(metaVariants)
                        search = metaVariants{ii}; 
                        [found, indices] = cellStringsContainString(this.metaParameterIds,search);
                        if found
                            metaVariantIndices(ii) = indices(1);
                        else
                           disp('component_influence_barchart not possible.')
                           skipAnalysis = 1;
                           break; 
                        end
                    end
                    sigMarkersTrain = [0 0 0 0 0]; 
                    sigMarkersTest = [0 0 0 0 0];
                    if ~skipAnalysis
                       dataTrain = zeros(1,numel(metaVariants)-1);
                       dataTest = zeros(1,numel(metaVariants)-1);
                       dataTrainSD = zeros(1,numel(metaVariants)-1);
                       dataTestSD = zeros(1,numel(metaVariants)-1);                       
                       fullValTrain = statDataTrain.meanMatrix(metaVariantIndices(1));
                       fullValTest = statDataTest.meanMatrix(metaVariantIndices(1));
                       
                       fullListTrain  = statDataTrain.valueListMatrix{metaVariantIndices(1)};
                       fullListTest = statDataTest.valueListMatrix{metaVariantIndices(1)};
                       
                       for ii=2:numel(metaVariants)
                        compareValTrain = statDataTrain.meanMatrix(metaVariantIndices(ii));
                        compareValTest = statDataTest.meanMatrix(metaVariantIndices(ii));
                        dataTrain(ii-1) = compareValTrain-fullValTrain;
                        dataTest(ii-1) = compareValTest-fullValTest;
                        dataTrainSD(ii-1) = statDataTrain.stdMatrix(metaVariantIndices(ii));  
                        dataTestSD(ii-1) = statDataTest.stdMatrix(metaVariantIndices(ii));   

                        compareListTrain  = statDataTrain.valueListMatrix{metaVariantIndices(ii)};
                        compareListTest = statDataTest.valueListMatrix{metaVariantIndices(ii)};
                        
                        testResultsTrain = statisticalTests(fullListTrain, compareListTrain);
                        testResultsTest = statisticalTests(fullListTest, compareListTest);
                        
                        sigMarkersTrain(ii-1) = testResultsTrain.direction;
                        sigMarkersTest(ii-1) = testResultsTest.direction;
                        
                       end

                       dataStruct = struct;
                       dataStruct.addParams = statParams.addParams;
                       dataStruct.dataTrain = dataTrain;
                       dataStruct.dataTrainSD = dataTrainSD; 
                       dataStruct.sigMarkersTrain = sigMarkersTrain; 
                       dataStruct.dataTest = dataTest;
                       dataStruct.dataTestSD = dataTestSD;
                       dataStruct.sigMarkersTest = sigMarkersTest;
                       dataStruct.resultPath = [this.outputDir filesep 'latex' filesep];
                       frameworkComponentBarPlot(dataStruct);
                    end

                    
                end
            end        
            
            
            if allStats || cellStringsContainString(statList,'component_influence_time_barchart')
                if numel(statParamsBase.dataSetIndexSelection) ~= 1
                    disp('component_influence_time_barchart only for 1 dataset')
                else       
                    statParams = statParamsBase;
                    statParams.addParams = queryStruct(statParams,'addParams',struct);
                    statParams.metaParamIndexSelection = 1:this.nMetaParams;
                    statParams.statisticFunction = 'training_time';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.highlightBestValues = 'min';
                    statParams.nDigitsMean = nDigits;
                    statParams.nDigitsStd = nDigits;
                    statParams.exportFiles = 0;
                    statDataTrain = this.exportStat(statParams);    
                    
                    % find stat meta indices
                    metaVariants = {'ECA-full', 'ECA-noFeatSel', 'ECA-noPreProc', 'ECA-noFeatTrans', 'ECA-simpleClassifier','ECA-defaultHyperparams'};
                    metaVariantIndices = zeros(1,numel(metaVariants));
                    skipAnalysis = 0;
                    for ii=1:numel(metaVariants)
                        search = metaVariants{ii}; 
                        [found, indices] = cellStringsContainString(this.metaParameterIds,search);
                        if found
                            metaVariantIndices(ii) = indices(1);
                        else
                           disp('component_influence_barchart not possible.')
                           skipAnalysis = 1;
                           break; 
                        end
                    end
                    factorTime = 1/60;
                    sigMarkersTrain = [0 0 0 0 0]; 
                    if ~skipAnalysis
                       dataTrain = zeros(1,numel(metaVariants)-1);
                       dataTrainSD = zeros(1,numel(metaVariants)-1);                  
                       fullValTrain = statDataTrain.meanMatrix(metaVariantIndices(1))*factorTime;
                       fullListTrain  = statDataTrain.valueListMatrix{metaVariantIndices(1)}*factorTime;
                       
                       for ii=2:numel(metaVariants)
                        compareValTrain = statDataTrain.meanMatrix(metaVariantIndices(ii))*factorTime;
                        dataTrain(ii-1) = compareValTrain-fullValTrain;
                        dataTrainSD(ii-1) = statDataTrain.stdMatrix(metaVariantIndices(ii))*factorTime;  
                        compareListTrain  = statDataTrain.valueListMatrix{metaVariantIndices(ii)}*factorTime;
                        testResultsTrain = statisticalTests(fullListTrain, compareListTrain);
                        
                        sigMarkersTrain(ii-1) = testResultsTrain.direction;
                        
                       end

                       dataStruct = struct;
                       dataStruct.addParams = statParams.addParams;
                       dataStruct.dataTrain = dataTrain;
                       dataStruct.dataTrainSD = dataTrainSD; 
                       dataStruct.sigMarkersTrain = sigMarkersTrain; 
                      
                       dataStruct.resultPath = [this.outputDir filesep 'latex' filesep];
                       frameworkComponentBarPlotTime(dataStruct);
                    end

                    
                end
            end                
            
            
            if allStats || cellStringsContainString(statList,'test_acc_multipipeline_top')
                statParams = statParamsBase;
                statParams.statisticFunction = 'test_acc_multipipeline_top_majority';
                statParams.multiplicationFactor = multiplicationFactorAccuracy;
                statParams.highlightBestValues = 'max';
                statParams.nDigitsMean = nDigits;
                statParams.nDigitsStd = nDigits;
                % preselected number
                nPipeliens = [10 20 50];
                for nPipe=nPipeliens
                    statParams.nPipelines = nPipe;
                    statParams.statName = sprintf('%s_top_%d',statParams.statisticFunction,statParams.nPipelines);
                    this.exportStat(statParams);                     
                end      
                
                % max div
                statParams.statisticFunction = 'test_acc_multipipeline_top_majority_max';
                statParams.statName = sprintf('%s_max',statParams.statisticFunction);
                this.exportStat(statParams);    
                                 
            end 
            if allStats || cellStringsContainString(statList,'test_acc_multipipeline_simpletop_graph')
                if numel(statParamsBase.dataSetIndexSelection) ~= 1
                    disp('test_acc_multipipeline_simpletop_graph only for 1 dataset')
                else                      
                    statParams = statParamsBase;
                    statParams.statisticFunction = 'test_acc_multipipeline_top_majority_list';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.nPipes = 1:50;
                    xlimrange = [statParams.nPipes(1) statParams.nPipes(end)] ;
                    statParams.showDifftoSingle = 0;
                    statParams.exportFiles = 0;
                    statParams.useTTest=0;
                    statParams.metaParamIndexSelection = 1:this.nMetaParams;
                    
                    statData = this.exportStat(statParams);    
                    
                    for iM=statParams.metaParamIndexSelection
                        valueLists = statData.valueListMatrix{1,iM};
                        metaName = this.metaParameterIds{iM};
                        stackedList = [];
                        for ii=1:numel(valueLists)
                            valList = valueLists{ii};
                            if statParams.showDifftoSingle
                                valList = valList - valList(1);
                            end
                            stackedList = [stackedList;valList];
                        end
                        % stattest
                        singleConfigList = stackedList(:,1);
                        statResults = [];
                        for iVal = 1:size(stackedList,2)
                            cList = stackedList(:,iVal);
                            if ~any(isnan(cList))
                                testResults = statisticalTests(singleConfigList, cList);    
                                statResults(iVal) = testResults.h;
                            end
                        end
                        
                        meanValues = mean(stackedList,1);
                        stdValues = std(stackedList,0,1);
                        meanValues = meanValues(statParams.nPipes);
                        stdValues = stdValues(statParams.nPipes);
                        exportFilename = [this.outputDir filesep 'latex' filesep 'mpcsimple' filesep];
                         [~,~,~ ] =  mkdir(exportFilename);
                        exportFilename = [exportFilename 'simpletop-' metaName];
                        addparams = struct;
                        addparams.xlimrange =  [xlimrange(1),xlimrange(2)+3];
                        addparams.xTick = [1 5:5:50];
                        addparams.statResults = statResults;
                        addparams.dx= -0.45;
                        addparams.dy= 0.01;
                        addparams.dy2= -0.0005;
                        addparams.gridMinor = 0;
                        addparams.markerSize = 10;
                        plotMultiPipelineRepetionPlot(exportFilename,statParams.nPipes, meanValues, stdValues, ['mpc-simpletop ' metaName],'N_{Pipes}','Generalization accuracy',addparams);  
                    end   
                end                 
            end 
            
            if allStats || cellStringsContainString(statList,'test_acc_multipipeline_fitnessdependent_graph')
                if numel(statParamsBase.dataSetIndexSelection) ~= 1
                    disp('test_acc_multipipeline_simpletop_graph only for 1 dataset')
                else                      
                    statParams = statParamsBase;
                    statParams.statisticFunction = 'test_acc_multipipeline_fitnessDependent';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.showDifftoSingle = 0;
                    statParams.exportFiles = 0;
                    statParams.useTTest=0;
                    statParams.metaParamIndexSelection = 1:this.nMetaParams;
                    
                    statData = this.exportStat(statParams);    
                    
                    statParams.statisticFunction = 'test_acc_multipipeline_top_majority_list'; 
                    statDataStatic = this.exportStat(statParams);    
                    
                    for iM=statParams.metaParamIndexSelection
                        valueData = statData.valueListMatrix{1,iM};
                        dFitnessThresh = valueData.test_MP_fusion_FitDep_deltaFitnessValues{1}; % the same for all
                        xlimrange = [dFitnessThresh(1) dFitnessThresh(end)];
                        accValueLists = valueData.test_MP_fusion_FitDep_accuracyFitnessDelta;                        
                        metaName = this.metaParameterIds{iM};
                        stackedList = [];
                        for ii=1:numel(accValueLists)
                            valList = accValueLists{ii};
                            if statParams.showDifftoSingle
                                valList = valList - valList(1);
                            end
                            stackedList = [stackedList;valList];
                        end
                        
                        
                        
                        % stattest
                        valueListsStatic = statDataStatic.valueListMatrix{1,iM};
                        metaName = this.metaParameterIds{iM};
                        stackedListStatic = [];
                        for ii=1:numel(valueListsStatic)
                            valList = valueListsStatic{ii};
                            if statParams.showDifftoSingle
                                valList = valList - valList(1);
                            end
                            stackedListStatic = [stackedListStatic;valList];
                        end
                        % stattest
                        singleConfigList = stackedListStatic(:,1);
                        statResults = [];
                        for iVal = 1:size(stackedList,2)
                            cList = stackedList(:,iVal);
                            if ~any(isnan(cList))
                                testResults = statisticalTests(singleConfigList, cList);    
                                statResults(iVal) = testResults.h;
                            end
                        end                        
                        
                        meanValues = mean(stackedList,1);
                        stdValues = std(stackedList,0,1);
                        
                        % do not show too many datapoints
                        meanValues = meanValues(1:2:end);
                        stdValues = stdValues(1:2:end);
                        statResults = statResults(1:2:end);
                        dFitnessThresh = dFitnessThresh(1:2:end);
                        
                        exportFilename = [this.outputDir filesep 'latex' filesep 'mpcfitnessdep' filesep];
                          [~,~,~ ] =  mkdir(exportFilename);
                        exportFilename = [exportFilename 'mpcfitnessdep-' metaName];
                        % '\Delta_{fit,max}'
                        addparams = struct;
                        addparams.xlimrange = [xlimrange(1),xlimrange(2)+0.007];
                        addparams.xTick = [0 : 0.02 : 0.1 ];
                        addparams.statResults = statResults;
                        addparams.gridMinor = 1;
                        addparams.dx= -0.001;
                        addparams.dy= 0.008;
                        addparams.dy2= -0.0005;
                        addparams.markerSize = 10;                        
                        plotMultiPipelineRepetionPlot(exportFilename, dFitnessThresh, meanValues, stdValues, ['mpc-fitdept ' metaName],'Fitness Threshold','Generalization accuracy', addparams);  
                    end   
                end                                       
            end     
            
            if allStats || cellStringsContainString(statList,'best_multi_pipeline')
                if numel(statParamsBase.dataSetIndexSelection) ~= 1
                    disp('test_acc_multipipeline_simpletop_graph only for 1 dataset')
                else                      
                    statParams = statParamsBase;
                    statParams.statisticFunction = 'test_acc_multipipeline_fitnessDependent';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.showDifftoSingle = 0;
                    statParams.exportFiles = 0;
                    statParams.useTTest=0;
                    statParams.metaParamIndexSelection = 1:this.nMetaParams;
                    
                    statDataFitnessDep = this.exportStat(statParams);  
                    
                    
                    statParams.statisticFunction = 'test_acc_multipipeline_top_majority_list';
                    statDataStaticSel = this.exportStat(statParams);    
                    
                    for iM=statParams.metaParamIndexSelection
                        valueDataFitDep = statDataFitnessDep.valueListMatrix{1,iM};
                        
                        bestValFitDep = -1;
                        bestValFitDepX = -1;
                        for iRep = 1:numel(valueDataFitDep.test_MP_fusion_FitDep_deltaFitnessValues)
                            xFitnessDep = valueDataFitDep.test_MP_fusion_FitDep_deltaFitnessValues{iRep}; 
                            yFitnessDep = valueDataFitDep.test_MP_fusion_FitDep_accuracyFitnessDelta{iRep};
                            [maxVal,maxIdx]=max(yFitnessDep);
                            if maxVal > bestValFitDep
                                bestValFitDep = maxVal;
                                bestValFitDepX = xFitnessDep(maxIdx);
                            end
                        end
                        
                        %valueDataStatic = statDataStaticSel.valueListMatrix{1,iM};
                        
                        
                    end   
                end                                       
            end                 
            
            
            if allStats || cellStringsContainString(statList,'logtime_test_acc_plot')
                if numel(statParamsBase.dataSetIndexSelection) ~= 1
                    disp('logtime_test_acc_plot only for 1 dataset')
                else                                          
                    statParams = statParamsBase;
                    statParams.statisticFunction = 'training_time';
                    statParams.exportFiles = 0;
                    statParams.multiplicationFactor = 1; % minutes
                    statParams.highlightBestValues = 'min';
                    statParams.nDigitsMean = 2;
                    statParams.nDigitsStd = 2;
                    statDataTime = this.exportStat(statParams);                          

                    statParams = statParamsBase;
                    statParams.exportFiles = 0;
                    statParams.statisticFunction = 'training_average_cv_acc';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.highlightBestValues = 'max';
                    statParams.nDigitsMean = nDigits;
                    statParams.nDigitsStd = nDigits;
                    statDataTrainAcc = this.exportStat(statParams);                       
                    
                    statParams = statParamsBase;
                    statParams.exportFiles = 0;
                    statParams.statisticFunction = 'test_acc_top_single_pipeline';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.highlightBestValues = 'max';
                    statParams.nDigitsMean = nDigits;
                    statParams.nDigitsStd = nDigits;
                    statDataTestAcc = this.exportStat(statParams);                   

                    plotItems = {};
                    for iM=statParams.metaParamIndexSelection
                        item = struct;
                        item.timeMean = statDataTime.meanMatrixFull(1,iM);
                        item.timeStd = statDataTime.stdMatrixFull(1,iM);

                        item.trainAccMean = statDataTrainAcc.meanMatrixFull(1,iM);
                        item.trainAccStd = statDataTrainAcc.stdMatrixFull(1,iM);                        
                        
                        item.testAccMean = statDataTestAcc.meanMatrixFull(1,iM);
                        item.testAccStd = statDataTestAcc.stdMatrixFull(1,iM);
                        
                        item.index = iM;
                        item.caption = statDataTestAcc.metaParameterCaptionsFull{iM};
                        plotItems{end+1} = item;
                    end            
                    dataStruct = struct;
                    exportFilename = [this.outputDir filesep 'latex' filesep ];
                    dataStruct.exportFileName=  [exportFilename 'time_acc_plot_train'];
                    dataStruct.plotItems = plotItems;
                    dataStruct.skipMetaIndices = 1;
                                        
                    dataStruct.mode = 1;
                    timeAccuracyPlot(dataStruct);
                    dataStruct.mode = 2;
                    timeAccuracyPlot(dataStruct);                    
                end
            end
            
            
            if allStats || cellStringsContainString(statList,'train_test_acc_plot')
                if numel(statParamsBase.dataSetIndexSelection) ~= 1
                    disp('train_test_acc_plot only for 1 dataset')
                else                                          
                
                    statParams = statParamsBase;
                    statParams.exportFiles = 0;
                    statParams.statisticFunction = 'training_average_cv_acc';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.highlightBestValues = 'max';
                    statParams.nDigitsMean = nDigits;
                    statParams.nDigitsStd = nDigits;
                    statDataTrainAcc = this.exportStat(statParams);                       
                    
                    statParams = statParamsBase;
                    statParams.exportFiles = 0;
                    statParams.statisticFunction = 'test_acc_top_single_pipeline';
                    statParams.multiplicationFactor = multiplicationFactorAccuracy;
                    statParams.highlightBestValues = 'max';
                    statParams.nDigitsMean = nDigits;
                    statParams.nDigitsStd = nDigits;
                    statDataTestAcc = this.exportStat(statParams);                   

                    plotItems = {};
                    for iM=statParams.metaParamIndexSelection
                        item = struct;

                        item.trainAccMean = statDataTrainAcc.meanMatrixFull(1,iM);
                        item.trainAccStd = statDataTrainAcc.stdMatrixFull(1,iM);                        
                        
                        item.testAccMean = statDataTestAcc.meanMatrixFull(1,iM);
                        item.testAccStd = statDataTestAcc.stdMatrixFull(1,iM);
                        
                        item.index = iM;
                        item.caption = statDataTestAcc.metaParameterCaptionsFull{iM};
                        plotItems{end+1} = item;
                    end            
                    dataStruct = struct;
                    exportFilename = [this.outputDir filesep 'latex' filesep ];
                    dataStruct.exportFileName=  [exportFilename 'train_test_acc_plot'];
                    dataStruct.plotItems = plotItems;
                    dataStruct.skipMetaIndices = 1;
                                        
                    train_test_acc_plot(dataStruct);                    
                end
            end            
            
        end
        
        
        %__________________________________________________________________
        % make dataset info and meta info
        %           
        function makeInfoStats(this,statParamsBase)
            
            % make table strings            
            this.statisticParams.exportLatex = queryStruct(this.statisticParams,'exportLatex',1);
            this.statisticParams.exportCSV =   queryStruct(this.statisticParams,'exportCSV',1);         
            
            dataSetCaptionMapping = queryStruct(statParamsBase,'dataSetCaptionMapping',{});
            metaParameterCaptionMapping = queryStruct(statParamsBase,'metaParameterCaptionMapping',{});
            
            dataSetCaptions = applyStringMapping(this.dataSetIds, dataSetCaptionMapping);
            metaParameterCaptions = applyStringMapping(this.metaParameterIds, metaParameterCaptionMapping);  
            
            dataSetIndexSelection = queryStruct(this.statisticParams,'dataSetIndexSelection',1:numel(this.dataSetIds));
            metaParamIndexSelection  = queryStruct(this.statisticParams,'metaParamIndexSelection',1:numel(this.metaParameterIds));            
            
            transposeTable = queryStruct(this.statisticParams,'transposeTable',0);
            splitNumberColumns = queryStruct(this.statisticParams,'splitNumberColumns',1);
            
            % dataset table ----
            cellTable = cell(numel(this.dataSetIds)+1,5);
            cellTable{1,1} = 'index';
            cellTable{1,2} = 'dataset';
            cellTable{1,3} = 'dimensions';
            cellTable{1,4} = 'samples';
            cellTable{1,5} = 'classes';    
            %cellTable{1,6} = 'datasetid';            
            for iRow=1:numel(this.dataSetIds)
                cDataSet = this.dataSetList{iRow};
                cellTable{iRow+1,1} = sprintf('%d',iRow);
                cellTable{iRow+1,2} = sprintf('%s',dataSetCaptions{iRow});
                cellTable{iRow+1,3} = sprintf('%d',cDataSet.nFeatures);
                cellTable{iRow+1,4} = sprintf('%d',cDataSet.nSamples);
                cellTable{iRow+1,5} = sprintf('%d',cDataSet.nClasses);
                %cellTable{iRow+1,6} = sprintf('%s',this.dataSetIds{iRow});                
            end
            % select part
            cellTable = cellTable([1 [dataSetIndexSelection+1]],:);
            
            
            if transposeTable 
                cellTable = cellTable';
            end
            if splitNumberColumns > 1
                cellTable = splitColumnsTable(cellTable,splitNumberColumns);
            end
            
            statParams = struct;
            
            if this.statisticParams.exportLatex
                statParams.exportMode = 'latex';
                tableStrings = this.getTableStringLines(cellTable,statParams);
                fileName = [this.outputDir filesep 'latex' filesep 'datasetInfo.tex'];
                saveMultilineString2File(tableStrings,fileName);
            end
            if this.statisticParams.exportCSV 
                statParams.exportMode = 'csv';
                tableStrings = this.getTableStringLines(cellTable,statParams); 
                fileName = [this.outputDir filesep 'csv' filesep 'datasetInfo.csv'];
                saveMultilineString2File(tableStrings,fileName);
            end
            
            % meta parameter table ----
            cellTable = cell(numel(this.metaParameterIds)+1,3);
            cellTable{1,1} = 'index';
            cellTable{1,2} = 'caption';
            cellTable{1,3} = 'parameterid';   
            
            for iRow=1:numel(this.metaParameterIds)
                cellTable{iRow+1,1} = sprintf('%d',iRow);
                cellTable{iRow+1,2} = sprintf('%s',metaParameterCaptions{iRow});
                cellTable{iRow+1,3} = sprintf('%s',this.metaParameterIds{iRow});
            end
            statParams = struct;
            % select part
            cellTable = cellTable([1 [metaParamIndexSelection+1]],:);            
            if transposeTable 
                cellTable = cellTable';
            end   
            if splitNumberColumns > 1
                cellTable = splitColumnsTable(cellTable,splitNumberColumns);
            end         
            
            if this.statisticParams.exportLatex
                statParams.exportMode = 'latex';
                tableStrings = this.getTableStringLines(cellTable,statParams);
                fileName = [this.outputDir filesep 'latex' filesep 'metaparamInfo.tex'];
                saveMultilineString2File(tableStrings,fileName);
            end
            if this.statisticParams.exportCSV 
                statParams.exportMode = 'csv';
                tableStrings = this.getTableStringLines(cellTable,statParams); 
                fileName = [this.outputDir filesep 'csv' filesep 'metaparamInfo.csv'];
                saveMultilineString2File(tableStrings,fileName);
            end            
                  
        end
        
        %__________________________________________________________________
        % make and save stats according to statParams
        %        
        function statData = exportStat(this, statParams)
            statData = this.getStatMatrixGeneral(statParams);
            
            exportFiles = queryStruct(statParams,'exportFiles',1);
            if exportFiles
                if fieldNotEmpty(statData,'tableStringsLatex')
                    dirExp = [this.outputDir 'latex' filesep];
                    [~,~,~] = mkdir(dirExp);
                    saveMultilineString2File(statData.tableStringsLatex,[dirExp statData.statName '.tex']);  
                end
                if fieldNotEmpty(statData,'tableStringsCSV')
                    dirExp = [this.outputDir 'csv' filesep];
                    [~,~,~] = mkdir(dirExp);                
                    saveMultilineString2File(statData.tableStringsCSV,[dirExp statData.statName '.csv']);  
                end     
            end
        end
        
        
        
        %__________________________________________________________________
        % generalized statistics matrix
        % fields in statParams struct
        %  -statName: string for filename and reference
        %  -dataSetIndexSelection: selection and order
        %  -metaParamIndexSelection: selection and order
        %  -dataSetCaptionNumeric: flag if datasets should be denoted as numbers
        %  -dataSetCaptionMapping: cell string n x 2 mapping {search,replace; ...}
        %  -metaParameterCaptionMapping: cell string n x 2 mapping {search,replace; ...}
        %  -statisticFunction: evaluation profile, e.g.
        %  training_average_cv_acc or 'custom'
        %  -statisticFunctionCustom: custom statistic function
        %  -highlightBestValues: 'max','min', 'none'
        %  -multiplicationFactor: any real number, standard is 1
        %  Delta baselines 
        %  - deltaBaselineColumnIndex: index from original index, 0 (standard) -> switch off
        %  - deltaBaselineModeShowDeltas (show deltas instead of absolute values)
        %  - deltaBaselineModeShowAverageDeltaRow ()
        %  -exportLatex: 0,1
        %  -exportCSV: 0,1
        
        function statData = getStatMatrixGeneral(this, statParams)
            statData = struct;
                        
            % row and column selection and order
            statData.dataSetIndexSelection = queryStruct(statParams,'dataSetIndexSelection',1:this.nDataSets);
            statData.metaParamIndexSelection  = queryStruct(statParams,'metaParamIndexSelection',1:this.nMetaParams);
            statData.dataSetCaptionNumeric = queryStruct(statParams,'dataSetCaptionNumeric',0); 
            
            % row and column header    
            statData.dataSetIdsFull = this.dataSetIds;
            statData.metaParameterIdsFull = this.metaParameterIds;       
            statData.dataSetCaptions = this.dataSetIds(statData.dataSetIndexSelection);
            statData.metaParameterCaptions = this.metaParameterIds(statData.metaParamIndexSelection);            
%             statData.dataSetRefStringSelection = this.dataSetIds(statData.dataSetIndexSelection);
%             statData.metaParameterRefStringSelection = this.metaParameterIds(statData.metaParamIndexSelection);
            
                        
            %name mappings of captions         
            dataSetCaptionMapping = queryStruct(statParams,'dataSetCaptionMapping',{});
            metaParameterCaptionMapping = queryStruct(statParams,'metaParameterCaptionMapping',{});
            statData.dataSetCaptions = applyStringMapping(statData.dataSetCaptions, dataSetCaptionMapping);
            if statData.dataSetCaptionNumeric
                for iDs = 1:numel(statData.dataSetCaptions)
                    statData.dataSetCaptions{iDs} = sprintf('%d',iDs);
                end
            end
            statData.metaParameterCaptions = applyStringMapping(statData.metaParameterCaptions, metaParameterCaptionMapping);
            statData.metaParameterCaptionsFull = applyStringMapping(this.metaParameterIds, metaParameterCaptionMapping); 
            
            % fill data matrix           
            statData.meanMatrixFull = zeros(size(this.jobInfoMatrix));
            statData.stdMatrixFull = zeros(size(this.jobInfoMatrix));      
            statData.valueListMatrixFull = cell(size(this.jobInfoMatrix));  
            statData.addStringMatrixFull = cell(size(this.jobInfoMatrix));  
            
            % ttestRef
            statData.useTTest = queryStruct(statParams,'useTTest',0);
            statData.useTTestReferenceSource = queryStruct(statParams,'useTTestReferenceSource','');
            if statData.useTTest
                if ~isempty(statData.useTTestReferenceSource) && ~isstruct(statData.useTTestReferenceSource)
                    [foundId, idIndex] = cellStringsContainString(statData.metaParameterIdsFull, statData.useTTestReferenceSource);
                    if foundId
                        statData.tTestMetaParamId = idIndex;
                        statData.tTestReferenceSource = 1; % same dataset, just id
                    else
                        warning('Metaparameter id not found!');
                        statData.useTTest = 0;
                    end
                elseif  ~isempty(statData.useTTestReferenceSource) && isstruct(statData.useTTestReferenceSource)
                   % struct!
                   statData.tTestReferenceSource = 2; % other file 
                   statData.tTestReferencePath = statData.useTTestReferenceSource.path;
                   
                else
                    warning('t test deactivated!');
                    statData.useTTest = 0;                    
                end
                
            end
            
            statParams.statisticFunction = queryStruct(statParams,'statisticFunction','');
            if isempty(statParams.statisticFunction)
                error('empty field statisticFunction in statParams');
            end
            statData.statName = queryStruct(statParams,'statName',statParams.statisticFunction);
            
            for iDs = 1:size(this.jobInfoMatrix,1)
                for iMp = 1:size(this.jobInfoMatrix,2)
                    cJobInfo = this.jobInfoMatrix{iDs,iMp};
                   
                    cJobPath = [cJobInfo.resultPath cJobInfo.resultPathRelative filesep];
                    
                    % call statistic function
                    [meanVal, stdVal, valueList] = this.getStatsForJob(cJobPath,statParams);
                    statData.meanMatrixFull(iDs,iMp) = meanVal;
                    statData.stdMatrixFull(iDs,iMp) = stdVal;
                    statData.valueListMatrixFull{iDs,iMp} = valueList;

                end                
            end
            %-- ttest/ welch test
            if statData.useTTest
                for iDs = 1:size(this.jobInfoMatrix,1)
                    % t test ref data
                   if statData.tTestReferenceSource == 1  % meta id
                      referenceData = statData.valueListMatrixFull{iDs,statData.tTestMetaParamId};    
                   else
                       % external file
                       [~, ~, referenceData] = this.getStatsForJob(statData.tTestReferencePath,statParams);
                   end                          
                    for iMp = 1:size(this.jobInfoMatrix,2)
                        compareData = statData.valueListMatrixFull{iDs,iMp};   
                        % make ttest
                        testResults = statisticalTests(referenceData, compareData);        
                        statData.addStringMatrixFull{iDs,iMp} = testResults.stringMaker;
                    end                
                end            
            end
            
            statData.meanMatrix = statData.meanMatrixFull(statData.dataSetIndexSelection,statData.metaParamIndexSelection);
            statData.stdMatrix = statData.stdMatrixFull(statData.dataSetIndexSelection,statData.metaParamIndexSelection); 
            statData.valueListMatrix = statData.valueListMatrixFull(statData.dataSetIndexSelection,statData.metaParamIndexSelection); 
            statData.addStringMatrix = statData.addStringMatrixFull(statData.dataSetIndexSelection,statData.metaParamIndexSelection); 
            
            statParams.transposeTable = queryStruct(statParams,'transposeTable',0);
            statParams.splitNumberColumns = queryStruct(this.statisticParams,'splitNumberColumns',1);            
            
            % Delta baseline
            statParams.deltaBaselineColumnIndex = queryStruct(statParams,'deltaBaselineColumnIndex',0);
            statParams.deltaBaselineModeShowDeltas = queryStruct(statParams,'deltaBaselineModeShowDeltas',1);
            statParams.deltaBaselineModeShowAverageDeltaRow = queryStruct(statParams,'deltaBaselineModeShowAverageDeltaRow',1);
            
            statParams.indicesLinesHorizontal = [1];
            statParams.indicesLinesVertical = [1];
            if statParams.deltaBaselineColumnIndex > 0
                baselineRow = real(statData.meanMatrixFull(statData.dataSetIndexSelection,statParams.deltaBaselineColumnIndex));
                baselineRowAll = repmat(baselineRow,1,size(statData.meanMatrix,2));
                deltaBaseLineMatrix = real(statData.meanMatrix) - baselineRowAll;
                deltaBaseLineMeans = mean(deltaBaseLineMatrix,1);
                deltaBaseLineStds = std(deltaBaseLineMatrix,0,1);

                if statParams.deltaBaselineModeShowDeltas
                    statData.meanMatrix = deltaBaseLineMatrix;
                    statData.stdMatrix = nan(size(statData.stdMatrix));
                    statParams.showStd = 0; % std does not make sense here
                end
                if statParams.deltaBaselineModeShowAverageDeltaRow
                    % add row with delta
                    statData.meanMatrix = [statData.meanMatrix; deltaBaseLineMeans];
                    statData.stdMatrix = [statData.stdMatrix; deltaBaseLineStds];
                    statData.dataSetCaptions{end+1} = sprintf('Average Delta Baseline (%d)',statParams.deltaBaselineColumnIndex);
                    nRows = size(statData.meanMatrix,1);
                    if statParams.transposeTable
                        statParams.indicesLinesVertical = [statParams.indicesLinesVertical (nRows)];
                    else
                        statParams.indicesLinesHorizontal = [statParams.indicesLinesHorizontal (nRows)];
                    end
                end                
            end
   
            % bold options (min/max)
            statParams.highlightBestValues = queryStruct(statParams,'highlightBestValues','max'); %max, min, none
            statParams.highLightOn = strcmp(statParams.highlightBestValues,'max') || strcmp(statParams.highlightBestValues,'min'); 
            
            if statParams.highLightOn
                if strcmp(statParams.highlightBestValues,'max') 
                    statData.boldIndices = tableBoldIndices(statData.meanMatrix);
                elseif strcmp(statParams.highlightBestValues,'min')
                    statData.boldIndices = tableBoldIndices(-statData.meanMatrix);
                end
            else
                statData.boldIndices = false(size(statData.meanMatrix));
            end
           
            statParams.multiplicationFactor = queryStruct(statParams,'multiplicationFactor',1);
            
            % make table strings            
            statParams.exportLatex = queryStruct(statParams,'exportLatex',1);
            statParams.exportCSV =   queryStruct(statParams,'exportCSV',1);         
            
            if statParams.exportLatex
                 [statData.tableStringsLatex, statData.tableMatrixLatex] = this.getTableStrings(statData,statParams,'latex');
            end
            
            if statParams.exportCSV
                 [statData.tableStringsCSV, statData.tableMatrixCSV] = this.getTableStrings(statData,statParams,'csv');
            end            

        end

            
            
        %__________________________________________________________________
        % get table with latex/csv format
        function [tableStrings, fullMatrix] = getTableStrings(this, statData, statParams, mode)
            
            tableStrings = {};
            innerMatrix = cell(size(statData.meanMatrix));
            nDigitsMean = queryStruct(statParams,'nDigitsMean',3);
            nDigitsStd = queryStruct(statParams,'nDigitsStd',3);
            hideStd = queryStruct(statParams,'hideStd',0);
            
            %showStd = queryStruct(statParams,'showStd',1);
            
            mlatex = strcmp(mode,'latex');
            mcsv = strcmp(mode,'csv'); 
            
            for iDs = 1:size(statData.meanMatrix,1)
                for iMp = 1:size(statData.meanMatrix,2)
                    meanVal = statParams.multiplicationFactor*statData.meanMatrix(iDs,iMp);
                    stdVal =  statParams.multiplicationFactor*statData.stdMatrix(iDs,iMp);
                    bold = statData.boldIndices(iDs,iMp);
                    addString =  statData.addStringMatrix{iDs,iMp};
                    
                    formatStringMean =  ['%0.' num2str(nDigitsMean) 'f'];
                    formatStringStd =  ['%0.' num2str(nDigitsStd) 'f'];
                    showStd = (~isnan(stdVal)) && (~hideStd); % show non nan values
                    
                    if showStd
                        if mlatex
                            formatString = [formatStringMean ' $\\pm$ ' formatStringStd];
                        elseif mcsv
                            formatString = [formatStringMean ' +- ' formatStringStd];
                        end
                    else
                        formatString = formatStringMean;
                    end
                    
                    if bold
                        if mlatex
                            formatString = ['\\textbf{' formatString '}'];
                        elseif mcsv
                            formatString = [formatString ' ^'];
                        end
                    end
                    
                    if showStd
                        stringVal = sprintf(formatString,real(meanVal),real(stdVal));
                    else
                        stringVal = sprintf(formatString,real(meanVal));
                    end
                    
                    if ~isreal(meanVal)
                        stringVal = [stringVal sprintf(' (%d)',imag(meanVal)/statParams.multiplicationFactor)];
                    end
                    % additional string 
                    stringVal = [stringVal addString];
                    innerMatrix{iDs,iMp} = stringVal;
                end                
            end           
            
            %make full matrix
            fullMatrix = cell(size(innerMatrix)+1);
            fullMatrix(2:end,2:end) = innerMatrix;
            fullMatrix(2:end,1) = statData.dataSetCaptions(:);
            fullMatrix(1,2:end) = statData.metaParameterCaptions(:)';
            
            % tanspose columns and rows
            if statParams.transposeTable
                fullMatrix = fullMatrix';
            end
            if statParams.splitNumberColumns > 1
                fullMatrix = splitColumnsTable(fullMatrix,statParams.splitNumberColumns);
            end         
            
            if mlatex
                statParams.exportMode = 'latex';
            end
            if mcsv
                statParams.exportMode = 'csv';
            end         
            statParams.statName = statData.statName;
            tableStrings = this.getTableStringLines(fullMatrix,statParams);      
            
        end      

        
        %__________________________________________________________________
        % get table strings
        function tableStrings = getTableStringLines(this,fullMatrix,statParams)        
            
            mode = queryStruct(statParams,'exportMode','');
            mlatex = strcmp(mode,'latex');
            mcsv = strcmp(mode,'csv'); 
            
            statParams.statName = queryStruct(statParams,'statName',strrep(queryStruct(statParams,'statisticFunction',''),'_','-'));
            tableStrings = {};
            if mlatex 
                statParams.latexUseBookTabs = queryStruct(statParams,'latexUseBookTabs',1);
                if statParams.latexUseBookTabs
                    options = struct;
                    options.indicesLinesVertical = queryStruct(statParams,'indicesLinesVertical',[]);
                    options.indicesLinesHorizontal = queryStruct(statParams,'indicesLinesHorizontal',1);
                    tableStrings = latexOuterTableFrom2DStringArrayBookTabs(fullMatrix, statParams.statName, options);
                else
                    latexColumnStyle = queryStruct(statParams,'latexColumnStyle','p{2.5cm}');
                    tableStrings = latexOuterTableFrom2DStringArray(fullMatrix, statParams.statName, latexColumnStyle);
                end
                
                % remove illegal characters
                for iLine = 1:numel(tableStrings)
                    tableStrings{iLine} = strrep(tableStrings{iLine},'_','-');
                end   
            elseif mcsv
                % make csv lines
                tableStrings = {};
                for iRow =1:size(fullMatrix,1)
                    csvSeparator = queryStruct(statParams,'csvSeparator',';');
                    tableStrings{end+1} = cellArrayToCSVString(fullMatrix(iRow,:),csvSeparator);
                end
            end        
        
        end
        
        
        %__________________________________________________________________
        % get statistics from job: input are job directory and parameters
        function [meanVal, stdVal, valueList] = getStatsForJob(this,jobDirectory,statParams)
            meanVal = nan;
            stdVal = nan;
            valueList = nan;
            if strcmp(statParams.statisticFunction, 'custom')
                customFunction = sprintf('%s(jobDirectory,statParams);',statParams.statisticFunctionCustom);
                [meanVal, stdVal] = eval(customFunction);
            else
                % load standard function
                repetitionResultsFile = [jobDirectory 'repetitionResults/repetitionResults.mat'];
                load(repetitionResultsFile);
                if strcmp(statParams.statisticFunction, 'training_average_cv_acc')
                    meanVal = repetitionResults.summaryRepetitions.train_accuracyOverallMean.mean;
                    stdVal =  repetitionResults.summaryRepetitions.train_accuracyOverallMean.std;
                    valueList = cell2mat(getCellArrayOfProperties(repetitionResults.resultListRepetitions,'train_accuracyOverallMean'));
                end            
                if strcmp(statParams.statisticFunction, 'training_average_cv_acc_best')
                    valueList = cell2mat(getCellArrayOfProperties(repetitionResults.resultListRepetitions,'train_accuracyOverallMean'));
                    meanVal = max(valueList);
                    stdVal = 0;
                end                   
                if strcmp(statParams.statisticFunction, 'training_time')
                    meanVal = repetitionResults.summaryRepetitions.train_trainingTimeSeconds.mean;
                    stdVal =  repetitionResults.summaryRepetitions.train_trainingTimeSeconds.std;
                    valueList = cell2mat(getCellArrayOfProperties(repetitionResults.resultListRepetitions,'train_trainingTimeSeconds'));
                end 
                if strcmp(statParams.statisticFunction, 'average_classification_time_bestPipeline')
                    [meanVal, stdVal, valueList] = this.statFromRepetitions(jobDirectory,statParams,repetitionResults, 'average_classification_time_bestPipeline');
                end                 
                
                if strcmp(statParams.statisticFunction, 'test_acc_top_single_pipeline')
                    meanVal = repetitionResults.summaryRepetitions.test_TopSinglePipelineAccuracy.mean;
                    stdVal =  repetitionResults.summaryRepetitions.test_TopSinglePipelineAccuracy.std;
                    valueList = cell2mat(getCellArrayOfProperties(repetitionResults.resultListRepetitions,'test_TopSinglePipelineAccuracy'));
                end  
                if strcmp(statParams.statisticFunction, 'test_acc_top_single_pipeline_best')
                    valueList = cell2mat(getCellArrayOfProperties(repetitionResults.resultListRepetitions,'test_TopSinglePipelineAccuracy'));
                    meanVal = max(valueList);
                    stdVal = 0;
                end                     
                if strcmp(statParams.statisticFunction, 'test_acc_multipipeline_top_majority')
                    nPipelines = statParams.nPipelines;
                    meanVal = repetitionResults.summaryRepetitions.test_MP_fusion_TopMajorityAccuracyList.mean(nPipelines);
                    stdVal = repetitionResults.summaryRepetitions.test_MP_fusion_TopMajorityAccuracyList.std(nPipelines);
                end    
                if strcmp(statParams.statisticFunction, 'test_acc_multipipeline_top_majority_list')
                    meanVal = 0;
                    stdVal = 0;
                    valueList = getCellArrayOfProperties(repetitionResults.resultListRepetitions,'test_MP_fusion_TopMajorityAccuracyList') ;
                end                  
                if strcmp(statParams.statisticFunction, 'test_acc_multipipeline_fitnessDependent')
                    meanVal = 0;
                    stdVal = 0;
                    valueList = struct;
                    valueList.test_MP_fusion_FitDep_deltaFitnessValues = getCellArrayOfProperties(repetitionResults.resultListRepetitions,'test_MP_fusion_FitDep_deltaFitnessValues') ;
                    valueList.test_MP_fusion_FitDep_accuracyFitnessDelta = getCellArrayOfProperties(repetitionResults.resultListRepetitions,'test_MP_fusion_FitDep_accuracyFitnessDelta') ;  
                end                  
                
                if strcmp(statParams.statisticFunction, 'test_acc_multipipeline_top_majority_max')
                    [~ ,nPipelines] = max(repetitionResults.summaryRepetitions.test_MP_fusion_TopMajorityAccuracyList.mean);
                    meanVal = repetitionResults.summaryRepetitions.test_MP_fusion_TopMajorityAccuracyList.mean(nPipelines) +1i*nPipelines; % code index as complex number
                    stdVal = repetitionResults.summaryRepetitions.test_MP_fusion_TopMajorityAccuracyList.std(nPipelines);
                end                  
                if strcmp(statParams.statisticFunction, 'test_acc_multipipeline_max_diversity')
                    nPipelines = statParams.nPipelines;
                    meanVal = repetitionResults.summaryRepetitions.test_MP_fusion_MaxDiversityAccuracyList.mean(nPipelines);
                    stdVal =  repetitionResults.summaryRepetitions.test_MP_fusion_MaxDiversityAccuracyList.std(nPipelines);
                end  
                if strcmp(statParams.statisticFunction, 'test_acc_multipipeline_max_diversity_max')
                    [~ ,nPipelines] = max(repetitionResults.summaryRepetitions.test_MP_fusion_MaxDiversityAccuracyList.mean);
                    meanVal = repetitionResults.summaryRepetitions.test_MP_fusion_MaxDiversityAccuracyList.mean(nPipelines) +1i*nPipelines; % code index as complex number
                    stdVal =  repetitionResults.summaryRepetitions.test_MP_fusion_MaxDiversityAccuracyList.std(nPipelines);
                end                                  
                
 
            end
        end
    
         %__________________________________________________________________
        % get statistics from each subfolder (repetions)
        function [meanVal, stdVal, valueList] = statFromRepetitions(this,jobDirectory,statParams, repetitionResults,statName)
            meanVal = nan;
            stdVal = nan;   
            valueList = [];
            if strcmp(statName,'average_classification_time_bestPipeline')
                nRep = repetitionResults.summaryRepetitions.nRepetitions;
                for ii=1:nRep
                    repDir = [jobDirectory sprintf('rep%d',ii) filesep];
                    trainInfoFile = [repDir 'trainingInfo.mat'];
                    load(trainInfoFile);
                    speedperItemBestPipeline = trainingInfo.aggregatedResults.resultsMultiPipeline.classificationSpeed.speedPerItemBestPipeline;
                    valueList = [valueList speedperItemBestPipeline];
                end
            end
            meanVal = mean(valueList);
            stdVal = std(valueList);
            
            
        end
        
        
      end % end methods public ____________________________________________

    
end



% helper -----------------------


% add to unique cell array list
function [cellArr, added] = uniqueStringList(cellArr, item)
    added = 0;
    if ~cellStringsContainString(cellArr,item)
        cellArr{end+1} = item;
        added = 1;
    end
end

% index of string in cell array
function index = findIndexOfString(cellArr, item)
    index = 0;
    for ii=1:numel(cellArr)
        if strcmp(cellArr{ii},item)
            index = ii;
        end
    end
end

% struct field available and not empty
function flag = fieldNotEmpty(structIn, field)
    flag = 0;
    if isfield(structIn,field)
        flag = ~isempty(structIn.(field));
    end
end


% mappingArray is nx2 of {from, to; from, to; ... } strings
function cellArrayMapped = applyStringMapping(cellArrayIn, mappingArray)
    cellArrayMapped = cellArrayIn;
    if ~isempty(mappingArray)
        mappedIndex = zeros(size(cellArrayIn));
        if size(mappingArray,2) == 2
            for iItem = 1:numel(cellArrayIn)
                cItem = cellArrayIn{iItem};
                for iMap=1:size(mappingArray,1)
                    cFrom = mappingArray{iMap,1};
                    cTo = mappingArray{iMap,2};
                    if strcmp(cFrom,cItem)
                        cItem = cTo;
                        mappedIndex(iItem) = 1;
                        break;
                    end
                end
                cellArrayMapped{iItem} = cItem;
            end
        else
            warning('mapping array should be cell with n x 2 entries!');
        end
        if any(mappedIndex(:) == 0)
           % warning('string mapping incomplete');
        end
    else
        % no mapping
    end
end



% split table in 2 columns
function cellTableOut = splitColumnsTable(cellTable,nColsSet)
   nRows = size(cellTable,1);
   nCols = size(cellTable,2);
   nDataRows = nRows -1;
   deltaCols = 2;
   nRowsNew = ceil(nDataRows/nColsSet);
   cellTableOut = cell(1+nRowsNew,nColsSet*nCols+(nColsSet-1)*deltaCols);
    % head
    
    for iCol=1:nColsSet
        colStart = (iCol-1)*(nCols+deltaCols)+1;
        cellTableOut(1,colStart:colStart+nCols-1) = cellTable(1,:);
    end
   cCol = 1;
   cRow = 1;
   for iRow = 2:nRows
       colStart = (cCol-1)*(nCols+deltaCols)+1;
       cellTableOut(cRow+1,colStart:colStart+nCols-1) = cellTable(iRow,:);
       
       cRow = cRow+1;
       if cRow>nRowsNew
           cCol = cCol+1;
           cRow = 1;
       end
   end
end




    %__________________________________________________________________
    % plot mean and std of multi pipeline classifier
    function plotMultiPipelineRepetionPlot(exportFilename, xVector, meanValues, stdValues, titleStr,labelx,labely,addparams)          
    % plot results            
    h= figure;
    set(h,'Visible','off');

    plotW = 340;
    plotH = 260;

    set(h,'Position', [10 500 plotW plotH]);            

    y = meanValues;
    e = stdValues;
    errorbar(xVector,y,e);

    colorMarkers = [195 227 255]/255;
    if isfield(addparams,'statResults')
        hold on; 
        for ii=1:numel(addparams.statResults)
           if addparams.statResults(ii)
               
               ySig =  y(ii)-e(ii)-addparams.dy;
               plot(xVector(ii),ySig,'^','MarkerSize',addparams.markerSize,'MarkerEdgeColor',colorMarkers,'MarkerFaceColor',colorMarkers);
               
           end
        end
        for ii=1:numel(addparams.statResults)
           if addparams.statResults(ii)
               
               xSig= xVector(ii)+addparams.dx;
               ySig =  y(ii)-e(ii)-addparams.dy;

               text(xSig,ySig-addparams.dy2,'!');
           end
        end        
    end
    
    xlabel(labelx);
    ylabel(labely);
    title(titleStr)
    if addparams.gridMinor
        grid minor;
    else
        grid on;
    end
    xlim(addparams.xlimrange);
    ax = gca;
    ax.XTick = addparams.xTick;

    set(h,'PaperPositionMode','auto');
    print(h,'-dpdf','-r0',[exportFilename '.pdf']);    

    % export as figure (for later calling and changing size or such)
    saveas(h,[exportFilename '.fig'],'fig') 
    close(h);

    end


    
    
function maxInfo =  getMaxFromVectorCellArray(vectorCellArray)
    maxVal = -inf;
    maxCellIndex = 0;
    maxVecIndex = 0;
    for ii = 1:numel(vectorCellArray)
        cVec = vectorCellArray{ii};
        [maxValVector, maxIndxVector] = max(cVec);
        if maxValVector > maxVal
            maxVal = maxValVector;
            maxCellIndex = ii;
            maxVecIndex = maxIndxVector;
        end
    end
    maxInfo = struct;
    maxInfo.maxVal = maxVal;
    maxInfo.maxCellIndex = maxCellIndex;
    maxInfo.maxVecIndex = maxVecIndex;
end
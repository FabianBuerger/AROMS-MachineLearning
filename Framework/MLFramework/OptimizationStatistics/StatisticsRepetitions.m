% Class definition StatisticsRepetitions
%
% This class handles evaluation of results from several repetitions of
% experiments to obtain stats
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef StatisticsRepetitions < handle
    
    properties 
        %resultStorage = {};
    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = StatisticsRepetitions()
        end
        
        
        %__________________________________________________________________
        % perform evalutions based on job summary information
        function repetitionResults = performEvaluations(this, jobInfo, pathAbs,jobIndex)
            repetitionResults = struct;
            nRep = numel(jobInfo.repetitionResultPathRelative);
            resultListRepetitions = {};
            for iRep = 1:nRep
                cRelPath = jobInfo.repetitionResultPathRelative{iRep};
                cAbsPath = [pathAbs cRelPath];
                trainingInfoFile = [cAbsPath filesep 'trainingInfo.mat'];
                load(trainingInfoFile);
                
                % training results
                repRes = struct;
                repRes.train_accuracyOverallMean = trainingInfo.aggregatedResults.resultsTraining.bestResultDetails.evaluationMetrics.accuracyOverallMean;
                repRes.train_accuracyOverallStd = trainingInfo.aggregatedResults.resultsTraining.bestResultDetails.evaluationMetrics.accuracyOverallStd;
                repRes.train_trainingTimeSeconds = trainingInfo.trainingInfo.trainingTimeSeconds;
                repRes.train_InitialImprovementTimeSeconds = queryStruct(trainingInfo.aggregatedResults,'initialOptimizationTime',0);
                
                % multi pipeline results -> test results
                try
                    if jobInfo.job.jobParams.multiPipelineTraining
                        repRes.test_TopSinglePipelineAccuracy = trainingInfo.aggregatedResults.resultsMultiPipeline.fusionTopMajority.MultiPipelineTop001Accuracy;

                        nPipelines = trainingInfo.job.jobParams.multiPipelineParameter.multiClassifierNPipelinesMax;
                        repRes.test_MP_fusion_TopMajorityAccuracyList = ...
                            cutOrFillVector(trainingInfo.aggregatedResults.resultsMultiPipeline.fusionTopMajority.accuracies,nPipelines,nan);
                        repRes.test_MP_fusion_MaxDiversityAccuracyList = ...
                            cutOrFillVector(trainingInfo.aggregatedResults.resultsMultiPipeline.fusionMaxDiversity.accuracies,nPipelines,nan);   
                        
                        repRes.test_MP_fusion_FitDep_deltaFitnessValues = trainingInfo.aggregatedResults.resultsMultiPipeline.fusionTopMajorityPipelineNumberDependentOnFitness.deltaFitnessValues;
                        repRes.test_MP_fusion_FitDep_nPipelinesFitnessDelta = trainingInfo.aggregatedResults.resultsMultiPipeline.fusionTopMajorityPipelineNumberDependentOnFitness.nPipelinesFitnessDelta;
                        repRes.test_MP_fusion_FitDep_accuracyFitnessDelta = trainingInfo.aggregatedResults.resultsMultiPipeline.fusionTopMajorityPipelineNumberDependentOnFitness.accuracyFitnessDelta;                                           
                        
                    end
                catch
                    disp('Skipped Multipipeline analysis')
                end
                resultListRepetitions{end+1} = repRes;
            end
            
            % make summary 
            summaryRepetitions = struct;
            summaryRepetitions.nRepetitions = nRep;
            summaryRepetitions.multiPipelineAvailable = jobInfo.job.jobParams.multiPipelineTraining;
            allStats = fieldnames(resultListRepetitions{1});
            for iStat =1:numel(allStats)
                fieldName = allStats{iStat};
                s=struct;
                s.mean = getStatisticsForStructFieldInCellArray(resultListRepetitions, fieldName, 'mean');
                s.std = getStatisticsForStructFieldInCellArray(resultListRepetitions, fieldName, 'std');
                summaryRepetitions = setfield(summaryRepetitions,fieldName, s);
            end

            repetitionResults.jobFolderRel = jobInfo.job.jobParams.resultPathRelativeBase;
            repetitionResults.resultListRepetitions = resultListRepetitions;
            repetitionResults.summaryRepetitions = summaryRepetitions;  
            
            this.exportPlots(jobInfo, repetitionResults, pathAbs);            
            %this.resultStorage{end+1} = repetitionResults;
            
            this.exportJobSummary(repetitionResults,jobInfo, pathAbs,jobIndex);
        end
        
        
        %__________________________________________________________________
        % perform evalutions based on job summary information
        function repetitionResults = exportPlots(this, jobInfo, repetitionResults, pathAbs)        
        
            % repetion result path
            jobMainPathAbs = [pathAbs jobInfo.resultPathRelative filesep];
            resultPath = [jobMainPathAbs 'repetitionResults' filesep ];
            [~,~,~] = mkdir(resultPath);
            
            % data           
            fileName = [resultPath 'repetitionResults.mat'];
            save(fileName,'repetitionResults','-v7.3');            
            
            %text file summary
            summaryText = {};
            fields=fieldnames(repetitionResults.summaryRepetitions);
            for iField = 1:numel(fields)
                cFieldName = fields{iField};
                cData = repetitionResults.summaryRepetitions.(cFieldName);
                cLine = [cFieldName ' ='];
                appendLine = 0;
                if isstruct(cData)
                    if numel(cData.mean) == 1 && numel(cData.std) == 1 
                        cLine = sprintf('%s %0.4f +- %0.4f',cLine, cData.mean, cData.std);
                        appendLine = 1;
                    end
                end
                if numel(cData) == 1 && isnumeric(cData)
                    cLine = sprintf('%s %0.2f',cLine, double(cData));
                    appendLine = 1;
                end
                if appendLine
                    summaryText{end+1} = cLine;
                end
            end
            
            fileName = [resultPath 'summary.txt'];
            saveMultilineString2File(summaryText,fileName);
            
            try
                if jobInfo.job.jobParams.multiPipelineTraining
                    %make plots for multi pipeline aggregation
                    titleStr = 'Multi-Pipeline Fusion Strategy Majority Top';
                    fileName = 'multiPipelineMajorityTopFusion';
                    meanValues = repetitionResults.summaryRepetitions.test_MP_fusion_TopMajorityAccuracyList.mean;
                    stdValues = repetitionResults.summaryRepetitions.test_MP_fusion_TopMajorityAccuracyList.std;
                    this.plotMultiPipelineRepetionPlot(resultPath, fileName, meanValues, stdValues, titleStr);     

                    titleStr = 'Multi-Pipeline Fusion Strategy Diversity Maximization';
                    fileName = 'multiPipelineMaxDiversityFusion';
                    meanValues = repetitionResults.summaryRepetitions.test_MP_fusion_MaxDiversityAccuracyList.mean;
                    stdValues = repetitionResults.summaryRepetitions.test_MP_fusion_MaxDiversityAccuracyList.std;
                    this.plotMultiPipelineRepetionPlot(resultPath, fileName, meanValues, stdValues, titleStr);                
                end
            catch
            end
        end
        
        
   
        %__________________________________________________________________
        % plot mean and std of multi pipeline classifier
        function plotMultiPipelineRepetionPlot(this, resultPath, fileName, meanValues, stdValues, titleStr)          
        % plot results            
        h= figure;
        set(h,'Visible','off');

        set(h,'Position', [10 500 600 300]);            
            
        x = 1:numel(meanValues);
        y = meanValues;
        e = stdValues;
        errorbar(x,y,e);
        
        xlabel('Number of fused pipelines');
        ylabel('Accuracy');
        title(titleStr);
        
        exportFilename = [resultPath filesep fileName];
        
        set(h,'PaperPositionMode','auto');
        print(h,'-dpdf','-r0',[exportFilename '.pdf']);    

        % export as figure (for later calling and changing size or such)
        saveas(h,[exportFilename '.fig'],'fig') 
        close(h);
        
        end
        
            
        
        %__________________________________________________________________
        % csv export a quick summary
        function exportJobSummary(this,repetitionResults,jobInfo,pathAbs,jobIndex)          
            
            exportFields = {'train_accuracyOverallMean','train_accuracyOverallStd','train_trainingTimeSeconds',...
                'test_TopSinglePipelineAccuracy'};
            
            % header
            headline = 'jobDir;';
            for ii=1:numel(exportFields)
                headline = [headline sprintf('%s_mean;%s_std;',exportFields{ii},exportFields{ii})];
            end
            if jobIndex == 1
                exportlines = {headline};
            else
                exportlines = {};
            end
            
            cResultSummary = repetitionResults.summaryRepetitions;
            cLine = [repetitionResults.jobFolderRel ';'];
            for ii=1:numel(exportFields)
                cField = exportFields{ii};
                if isfield(cResultSummary,cField)
                    dataField = getfield(cResultSummary,cField);
                    dataStr = sprintf('%0.5f;%0.5f;',dataField.mean,dataField.std);
                else
                    dataStr = '-1;-1;';
                end
                cLine = [cLine dataStr];
            end                
            exportlines{end+1} = cLine;

            csvFile = [pathAbs 'jobResultOverview.csv'];
            appendText(csvFile, exportlines)
            
        end
        
                    
        
        
      end % end methods public ____________________________________________

    
end



        

% helper
function vecOut = cutOrFillVector(vecIn,targetLength,fillValue)
    if numel(vecIn) == targetLength
        vecOut = vecIn;
    elseif numel(vecIn) > targetLength
        vecOut = vecIn(1:targetLength);
    else %numel(vecIn) < targetLength
        dSize = targetLength-numel(vecIn);
        vecOut = [vecIn, fillValue*ones(1,dSize)];
    end
end
        

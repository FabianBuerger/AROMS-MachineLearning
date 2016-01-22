% Class definition OptimizationStatistics
%
% This class handles evaluation of results of a framework optimization process
% The data can either be passed directly after optimization - or
% can be passed from a stored result file.
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef OptimizationStatistics < handle
    
    properties 
   
    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = OptimizationStatistics()
        end
        
        
        %__________________________________________________________________
        % perfrom evaluation of optimization results based on data in the
        % struct optimizationResultData which contains
        % -trainingInfo (job and parameters)
        % -trainingResults (configuration and evaluation lists)
        % See class OptimizationStrategy for more info
        % The struct evaluationParams specifies evaluation options (which
        % plots with what parameters)
            
        function aggregatedResults = performEvaluations(this,optimizationResultData, evaluationParams)
            aggregatedResults = struct;
            %warning('Try catch evaluations!')
            try
                showPlots = evaluationParams.showPlots;
                exportPlot = evaluationParams.exportPlots;
                preferredFigureFormat = evaluationParams.preferredFigureFormat;
                optInfos = queryStruct(evaluationParams,'optInfos', struct);

                evaluationParams.resultPathPlots = [evaluationParams.resultPathBase 'plots' filesep];
                [~,~,~]= mkdir(evaluationParams.resultPathPlots);
                evaluationParams.resultPathData = [evaluationParams.resultPathBase 'data' filesep];
                [~,~,~]= mkdir(evaluationParams.resultPathData);            
                evaluationParams.resultPathTables = [evaluationParams.resultPathBase 'tables' filesep];
                [~,~,~]= mkdir(evaluationParams.resultPathTables);

                % flag if all should be exported
                if ~iscell(evaluationParams.activeStatsList)     
                    evaluationParams.exportAll = 1;
                else
                    evaluationParams.exportAll = 0;
                end

                % prepare results ================
                % sort items by quality metric
                evalItemsSortedByCalculation = optimizationResultData.trainingResults.resultStorage.evaluationItems;
                evalItemsSortedQualityMetric = OptimizationResultController.sortResultListByQualityMetric(evalItemsSortedByCalculation);            

                nEvaluations = numel(evalItemsSortedQualityMetric);
                
                aggregatedResults.nEvaluations = nEvaluations;
                bestEvalItem = evalItemsSortedQualityMetric{1};
                aggregatedResults.bestResultDetails = bestEvalItem.resultData;
                aggregatedResults.bestAccuracyOverallMean = bestEvalItem.resultData.evaluationMetrics.accuracyOverallMean;
                aggregatedResults.bestTimeNeeded = bestEvalItem.calcTimePassedSinceStart;
                aggregatedResults.bestIterationsNeeded = bestEvalItem.calcIndex;


                % export statistics ==============

                %_______________________________________________________________
                % top result configurations for fast reading from HDD (big list
                % of all items takes quite some time to load)
                if  evaluationParams.exportAll || cellStringsContainString(evaluationParams.activeStatsList,...
                        'ResultListTop')
                    disp('  Exporting top results');
                    nItemsTop = min(250,nEvaluations); % save the best 250 configs 
                    evalItemsSortedQualityMetricTop = evalItemsSortedQualityMetric(1:nItemsTop);
                    exportFileName = [evaluationParams.resultPathData 'sortedConfigurationListTop.mat']; 
                    save(exportFileName,'evalItemsSortedQualityMetricTop','-v7.3');
                end            

                %_______________________________________________________________
                % result table csv
                if  evaluationParams.exportAll || cellStringsContainString(evaluationParams.activeStatsList,...
                        'ResultTableCSVFull')
                    disp('  Exporting csv result table');

                    tableOptions = struct;
                    tableOptions.classNames = optimizationResultData.trainingInfo.job.dataSet.classNames;
                    tableOptions.nItemLimit = 5000; % limit to save disk space
                    tableOptions.exportFileName = [evaluationParams.resultPathTables 'sortedConfigurationList.csv']; 
                    tableOptions.job = evaluationParams.job;
                    StatisticsTextBased.exportResultTable(evalItemsSortedQualityMetric,tableOptions);

                end

                %_______________________________________________________________
                % result table for latex
                if  evaluationParams.exportAll || cellStringsContainString(evaluationParams.activeStatsList,...
                        'LatexTopTable')
                    disp('  Exporting latex result table');

                    tableOptions = struct;
                    tableOptions.classNames = optimizationResultData.trainingInfo.job.dataSet.classNames;
                    tableOptions.nItemLimit = 5000; % limit to save disk space                    
                    tableOptions.exportFileName = [evaluationParams.resultPathTables 'sortedConfigurationLatex.tex']; 
                    tableOptions.job = evaluationParams.job;
                    topConfigsLatex(evalItemsSortedQualityMetric,tableOptions);
                end                
                
                
                %_______________________________________________________________
                % result table for latex
                if  evaluationParams.exportAll || cellStringsContainString(evaluationParams.activeStatsList,...
                        'TopFitnessDistribution')
                    disp('  Exporting top fitness distribution');
                    plotOptions = struct;
                    plotOptions.exportFileName = [evaluationParams.resultPathPlots 'topFitnessDistribution']; 
                    plotOptions.job = evaluationParams.job;
                    topFitnessDistribution(evalItemsSortedQualityMetric,plotOptions);
                end                
                                
                
                %_______________________________________________________________
                % Quality plot iteration based
                if evaluationParams.exportAll ||  cellStringsContainString(evaluationParams.activeStatsList,...
                        'QualityPlotIteration') 
                    disp('  Exporting quality plot iteration');

                    plotOptions = struct;
                    plotOptions.showPlots = showPlots;
                    plotOptions.xAxisUnit = 'iteration';
                    plotOptions.exportPlot = 1;
                    plotOptions.exportPlotFormat = preferredFigureFormat;                    
                    plotOptions.exportFileName = [evaluationParams.resultPathPlots 'qualityMetricIteration'];
                    StatisticsPlots.exportQualityMetricPlot(evalItemsSortedByCalculation, plotOptions);
                end            

                %_______________________________________________________________
                % Quality plot time based
                if evaluationParams.exportAll ||  cellStringsContainString(evaluationParams.activeStatsList,...
                        'QualityPlotTime')
                    disp('  Exporting quality plot time');

                    plotOptions = struct;
                    plotOptions.showPlots = showPlots;
                    plotOptions.xAxisUnit = 'time';
                    plotOptions.exportPlot = 1;
                    plotOptions.exportPlotFormat = preferredFigureFormat;                    
                    plotOptions.exportFileName = [evaluationParams.resultPathPlots 'qualityMetricTime'];
                    StatisticsPlots.exportQualityMetricPlot(evalItemsSortedByCalculation, plotOptions);                
                end                 
                

                %_______________________________________________________________
                % system configuration graph version 3
                % (extended version)
                if evaluationParams.exportAll ||  cellStringsContainString(evaluationParams.activeStatsList,...
                        'ConfigurationGraph_v3')
                    disp('  Exporting configuration graphs');

                    for iVariant = 2

                        plotOptions = struct;
                        plotOptions.optInfos = optInfos;
                        plotOptions.exportPlot = exportPlot;
                        plotOptions.showPlots = showPlots;
                        plotOptions.numberOfFeaturesDisplay = 16; % most relevant features
                        nTopConfigs = min(nEvaluations,50); %number of top-n configs to plot
                        plotOptions.exportPlotFormat = preferredFigureFormat;
                        
                        plotOptions.markBestSolution = 1;
                        plotOptions.featureSplitUndo = 0;
                        if iVariant == 1
                             plotOptions.showFeaturePreProcessing = 1;
                             exportSuffix = '_PreProc';
                        else
                             plotOptions.showFeaturePreProcessing = 0;
                             exportSuffix = '';                            
                        end
                        plotOptions.exportFileName = sprintf('%sConfigurationGraph%s',evaluationParams.resultPathPlots,exportSuffix);
                        evalItemsSortedTop = evalItemsSortedQualityMetric(1:nTopConfigs); 
                        configurationPlot_v3(evalItemsSortedTop, optimizationResultData.trainingInfo, plotOptions);        

                        % grouped plot if splitting was activated and necessary
                        if evaluationParams.job.jobParams.splitMultiChannelFeatures && ...
                           evaluationParams.job.dataSet.featureSplitInfo.splitNecessary
                           plotOptions.featureSplitUndo = 1; 
                           plotOptions.exportFileName = sprintf('%sConfigurationGraph_unsplit%s',evaluationParams.resultPathPlots,exportSuffix);
                           disp('  Exporting configuration graph v3 feature grouping');
                           configurationPlot_v3(evalItemsSortedTop, optimizationResultData.trainingInfo, plotOptions);   
                        end
                    end
                    
                end                

                %_______________________________________________________________
                % system configuration graph version 3 custom
                % (extended version)
                if evaluationParams.exportAll ||  cellStringsContainString(evaluationParams.activeStatsList,...
                        'ConfigurationGraph_v3_custom')
                    disp('  Exporting configuration graph v3 custom');

                    plotOptions = struct;
                    plotOptions.exportPlot = exportPlot;
                    plotOptions.showPlots = showPlots;
                    plotOptions.numberOfFeaturesDisplay = 20; % most relevant features
                    nTopConfigs = min(nEvaluations,20); %number of top-n configs to plot
                    plotOptions.exportPlotFormat = preferredFigureFormat;
                    plotOptions.exportFileName = sprintf('%sstackedConfigurationGraphCustom_%d',evaluationParams.resultPathPlots,nTopConfigs);
                    plotOptions.markBestSolution = 1;
                    plotOptions.showFeaturePreProcessing = 1;
                    evalItemsSortedTop = evalItemsSortedQualityMetric(1:nTopConfigs);
                    configurationPlot_v3(evalItemsSortedTop, optimizationResultData.trainingInfo, plotOptions);                
                end  

                %_______________________________________________________________
                % dimensionalities plot
                if evaluationParams.exportAll ||  cellStringsContainString(evaluationParams.activeStatsList,...
                        'DimensionalitiesPlot')
                    disp('  Exporting dimensionalities plot ');

                    plotOptions = struct;
                    plotOptions.exportPlot = exportPlot;
                    plotOptions.showPlots = showPlots;
                   
                    nTopConfigs = min(nEvaluations,50); %number of top-n configs to plot
                    plotOptions.exportPlotFormat = preferredFigureFormat;
                    plotOptions.exportFileName = sprintf('%sdimensionalitiesPlot',evaluationParams.resultPathPlots);
                    evalItemsSortedTop = evalItemsSortedQualityMetric(1:nTopConfigs);
                    dimensionalitiesPlot(evalItemsSortedTop, optimizationResultData.trainingInfo, plotOptions);                
                end                
                
                %_______________________________________________________________
                % dimensionalities plot custom
                if evaluationParams.exportAll ||  cellStringsContainString(evaluationParams.activeStatsList,...
                        'DimensionalitiesPlot_custom')
                    disp('  Exporting dimensionalities plot custom');

                    plotOptions = struct;
                    plotOptions.exportPlot = exportPlot;
                    plotOptions.showPlots = showPlots;
                   
                    nTopConfigs = min(nEvaluations,20); %number of top-n configs to plot
                    plotOptions.exportPlotFormat = preferredFigureFormat;
                    plotOptions.exportFileName = sprintf('%sdimensionalitiesPlot',evaluationParams.resultPathPlots);
                    evalItemsSortedTop = evalItemsSortedQualityMetric(1:nTopConfigs);
                    dimensionalitiesPlot(evalItemsSortedTop, optimizationResultData.trainingInfo, plotOptions);                
                end                     
                
                %_______________________________________________________________
                % Components Frequencies
                % (extended version)
                if evaluationParams.exportAll ||  cellStringsContainString(evaluationParams.activeStatsList,...
                        'ComponentsFrequencies')
                    disp('  Exporting components frequencies');
                    nTopConfigs = min(nEvaluations,50);
                    evalItemsSortedTop = evalItemsSortedQualityMetric(1:nTopConfigs);

                    exportOptions = struct;
                    exportOptions.components = 'Features';
                    exportOptions.exportPlot = exportPlot;
                    exportOptions.showPlots = showPlots;
                    exportOptions.exportPlotFormat = preferredFigureFormat;
                    exportOptions.exportPlotFileName = sprintf('%scompFreq_%s_top%d',evaluationParams.resultPathPlots,exportOptions.components,nTopConfigs);
                    exportOptions.exportListFileName = sprintf('%scompFreq_%s_top%d.csv',evaluationParams.resultPathTables,exportOptions.components,nTopConfigs);          
                    StatisticsFrequencies.frequencyAnalysis(evalItemsSortedTop,optimizationResultData.trainingInfo,exportOptions);

                    exportOptions = struct;
                    exportOptions.components = 'FeaturePreprocessing';
                    exportOptions.exportPlot = exportPlot;
                    exportOptions.showPlots = showPlots;
                    exportOptions.exportPlotFormat = preferredFigureFormat;
                    exportOptions.exportPlotFileName = sprintf('%scompFreq_%s_top%d',evaluationParams.resultPathPlots,exportOptions.components,nTopConfigs);
                    exportOptions.exportListFileName = sprintf('%scompFreq_%s_top%d.csv',evaluationParams.resultPathTables,exportOptions.components,nTopConfigs);          
                    StatisticsFrequencies.frequencyAnalysis(evalItemsSortedTop,optimizationResultData.trainingInfo,exportOptions);                    
                    
                    exportOptions = struct;
                    exportOptions.components = 'FeatureTransforms';
                    exportOptions.exportPlot = exportPlot;
                    exportOptions.showPlots = showPlots;
                    exportOptions.exportPlotFormat = preferredFigureFormat;
                    exportOptions.exportPlotFileName = sprintf('%scompFreq_%s_top%d',evaluationParams.resultPathPlots,exportOptions.components,nTopConfigs);
                    exportOptions.exportListFileName = sprintf('%scompFreq_%s_top%d.csv',evaluationParams.resultPathTables,exportOptions.components,nTopConfigs);          
                    StatisticsFrequencies.frequencyAnalysis(evalItemsSortedTop,optimizationResultData.trainingInfo,exportOptions);

                    exportOptions = struct;
                    exportOptions.components = 'Classifiers';
                    exportOptions.exportPlot = exportPlot;
                    exportOptions.showPlots = showPlots;
                    exportOptions.exportPlotFormat = preferredFigureFormat;
                    exportOptions.exportPlotFileName = sprintf('%scompFreq_%s_top%d',evaluationParams.resultPathPlots,exportOptions.components,nTopConfigs);
                    exportOptions.exportListFileName = sprintf('%scompFreq_%s_top%d.csv',evaluationParams.resultPathTables,exportOptions.components,nTopConfigs);          
                    StatisticsFrequencies.frequencyAnalysis(evalItemsSortedTop,optimizationResultData.trainingInfo,exportOptions);

                end      


                %_______________________________________________________________
                % Time Series
                if evaluationParams.exportAll ||  cellStringsContainString(evaluationParams.activeStatsList,...
                        'TimeSeries')

                    if isfield(optimizationResultData.trainingResults,'timeSeriesList')
                        disp('  Exporting time series');
                        tsList = optimizationResultData.trainingResults.timeSeriesList;

                        for iTS = 1:numel(tsList)

                            try
                                cTSName = tsList{iTS}.id;
                                cDataList = tsList{iTS}.dataList;
                                if numel(cDataList) > 0
                                    tsValues = [];
                                    indexValues = [];
                                    timeValues = [];
                                    for ii=1:numel(cDataList)
                                        tsValues(end+1)=cDataList{ii}.dataItem.value; % query dataItem.value
                                        indexValues(end+1)=cDataList{ii}.index;
                                        timeValues(end+1)=cDataList{ii}.timePassedSinceStart/60; % in minutes
                                    end

                                    plotOptions = struct;
                                    plotOptions.showPlots = showPlots;
                                    plotOptions.exportPlot = 1;
                                    plotOptions.title = cTSName;
                                    plotOptions.xLabel = 'iteration';
                                    plotOptions.yLabel = 'quality';                         
                                    plotOptions.exportPlotFormat = preferredFigureFormat;                    
                                    plotOptions.exportFileName = [evaluationParams.resultPathPlots  cTSName '_byIndex'];
                                    StatisticsPlots.exportTimeSeriesPlot(indexValues,tsValues, plotOptions);  

                                    plotOptions = struct;
                                    plotOptions.showPlots = showPlots;
                                    plotOptions.exportPlot = 1;
                                    plotOptions.title = cTSName;
                                    plotOptions.xLabel = 'time [min]';
                                    plotOptions.yLabel = 'quality';                         
                                    plotOptions.exportPlotFormat = preferredFigureFormat;                    
                                    plotOptions.exportFileName = [evaluationParams.resultPathPlots cTSName '_byTime'];
                                    StatisticsPlots.exportTimeSeriesPlot(timeValues,tsValues, plotOptions);                                  
                                end                        


                            catch
                                disp('Time Series skipped!');
                            end
                        end



                    end


                end      
            
            catch err
                errorId = err.identifier;
                errorMsg = err.message;
                warning('Error occured during statistics: %s, %s',errorId,errorMsg)
            end
        end
        
        
        
        
        
        
        
        
      end % end methods public ____________________________________________
      
        

    
    
end

        

        

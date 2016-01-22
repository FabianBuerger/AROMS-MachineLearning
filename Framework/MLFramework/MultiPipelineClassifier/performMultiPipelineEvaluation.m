%  function dataAggregated = performMultiPipelineEvaluation(multiPipelineParams,dataSetTest,params)
%
% Evaluate MultiClassifier System from Framework training data
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015


function dataAggregated = performMultiPipelineEvaluation(multiPipeline,dataSetTest,params)

    nMaxPipelines = numel(multiPipeline.pipelinesReadyForClassification);
    multiPipeline.multiPipelineParams.maxNumberConfigurations = ...
        min(multiPipeline.multiPipelineParams.maxNumberConfigurations,nMaxPipelines);
        
    % this is just to init the classification results (and cache the
    % decisions of each pipeline
    multiPipeline.evaluateTestDataSet(dataSetTest);

    % now start evaluation
    numbersPipelinesVector = 1:multiPipeline.multiPipelineParams.maxNumberConfigurations;

    % first strategy: simpleTopPipelines
    evaluationListDetails = {};
    accuraciesSimpleTop = [];
    
    multiPipeline.multiPipelineParams.trainingStrategy = 'simpleTopPipelines';     
    for iN=numbersPipelinesVector   
        multiPipeline.multiPipelineParams.useNumberConfigurations = iN;
        cEvalRes = multiPipeline.evaluateLastDataSetAgain();
        accuraciesSimpleTop(end+1) = cEvalRes.accuracyOverall;
        evaluationListDetails{end+1} = cEvalRes;
    end
    accuracyOnlyBestPipeline = accuraciesSimpleTop(1);
    [accuracyBestMultiPipeline, ind] = max(accuraciesSimpleTop);
    multiPipelineBestNumber = numbersPipelinesVector(ind);
       
    
    % only indices that improve: test
%     indicesOfPipelinesThatImprove = find(diff(accuraciesSimpleTop) >= 0)+1;
%     pipelineSubSet = [1,indicesOfPipelinesThatImprove];
%     cEvalRes = multiPipeline.evaluateLastDataSetAgainSubSet(pipelineSubSet);
%     bestOnlyPositive = cEvalRes.accuracyOverall
    
%     % export data
    dataAggregated = struct;
    dataAggregated.multiPipelineParams = multiPipeline.multiPipelineParams;
    dataAggregated.classificationSpeed = struct;
    dataAggregated.classificationSpeed.speedPerItemAllPipelines = multiPipeline.classificationSpeedsPerItem;     
    dataAggregated.classificationSpeed.speedPerItemBestPipeline = multiPipeline.classificationSpeedsPerItem(1);
    dataAggregated.classificationSpeed.speedPerItemAverageMultipipeline = mean(multiPipeline.classificationSpeedsPerItem);
    dataAggregated.classificationSpeed.speedPerItemAverageMultipipelineStd = std(multiPipeline.classificationSpeedsPerItem);

    dataAggregated.fusionTopMajority = struct;
    dataAggregated.fusionTopMajority.evaluationListDetails = evaluationListDetails;
    dataAggregated.fusionTopMajority.accuracies = accuraciesSimpleTop;
    dataAggregated.fusionTopMajority.numbersPipelines = numbersPipelinesVector;   

    dataAggregated.fusionTopMajority.MultiPipelineTop001Accuracy = accuraciesSimpleTop(1); 
    
    if numel(accuraciesSimpleTop) >= 10
        dataAggregated.fusionTopMajority.MultiPipelineTop010Accuracy = accuraciesSimpleTop(10);
    else
        dataAggregated.fusionTopMajority.MultiPipelineTop010Accuracy = 0;
    end
    if numel(accuraciesSimpleTop) >= 20
        dataAggregated.fusionTopMajority.MultiPipelineTop020Accuracy = accuraciesSimpleTop(20);
    else
        dataAggregated.fusionTopMajority.MultiPipelineTop020Accuracy = 0;
    end
    if numel(accuraciesSimpleTop) >= 50
        dataAggregated.fusionTopMajority.MultiPipelineTop050Accuracy = accuraciesSimpleTop(50);
    else
        dataAggregated.fusionTopMajority.MultiPipelineTop050Accuracy = 0;
    end    
    
    % best accuracy, but adapted with training data 
    dataAggregated.fusionTopMajority.MultiPipelineBestAccuracy = accuracyBestMultiPipeline;
    dataAggregated.fusionTopMajority.MultiPipelineBestNumberPipelines = multiPipelineBestNumber;

    % choose n dependent of training accurarcy
    % get quality vector
    fitnessVector = [];
    for iConfig = 1:numel(accuraciesSimpleTop)
        fitnessVector(end+1) = params.evalItemsSortedTop.evalItemsSortedQualityMetricTop{iConfig}.qualityMetric;
    end
    %figure, plot(fitnessVector);
    % adaptive n choosing
    deltaFitnessValues = [0: 0.001: 0.1];
    fitnessVectorDeltaFirst = abs(fitnessVector - fitnessVector(1));
    nPipelinesFitnessDelta = [];
    accuracyFitnessDelta = [];
    for iFitnessDelta = 1:numel(deltaFitnessValues)
        cDelta = deltaFitnessValues(iFitnessDelta);
        nPipelinesRecommended = find(fitnessVectorDeltaFirst <= cDelta);
        nPipelinesRecommended = nPipelinesRecommended(end);
        nPipelinesFitnessDelta(end+1) = nPipelinesRecommended;
        accuracyFitnessDelta(end+1) = accuraciesSimpleTop(nPipelinesRecommended);
    end
    
    dataAggregated.fusionTopMajorityPipelineNumberDependentOnFitness = struct;
    dataAggregated.fusionTopMajorityPipelineNumberDependentOnFitness.deltaFitnessValues = deltaFitnessValues;
    dataAggregated.fusionTopMajorityPipelineNumberDependentOnFitness.nPipelinesFitnessDelta = nPipelinesFitnessDelta;
    dataAggregated.fusionTopMajorityPipelineNumberDependentOnFitness.accuracyFitnessDelta = accuracyFitnessDelta;
    
    %--------- plot
    h= figure;
    if params.silentPlot
        set(h,'Visible','off');
    end
    set(h,'Position', [10 500 600 300]);            

    plot(deltaFitnessValues,accuracyFitnessDelta, 'Color',[0.6 0.6 0.6], 'LineWidth',1.5);

    xlabel('Delta fitness threshold');
    ylabel('accuracy');

    ht = title([dataSetTest.dataSetName ' - Fitness Thresh Accuracy']);
    set(ht,'Interpreter','none');    
    
    set(h,'PaperPositionMode','auto');
    fname=[params.resultPath 'fitnessThreshAccuracy.pdf'];
    print(h,'-dpdf','-r0',fname);    

	% export as figure (for later calling and changing size or such)
	fname = [ params.resultPath 'fitnessThreshAccuracy.fig'];
	saveas(h,fname,'fig') 
    
    if params.silentPlot
        close(h);
    end         
    
    h= figure;
    if params.silentPlot
        set(h,'Visible','off');
    end
    set(h,'Position', [10 500 600 300]);            

    plot(deltaFitnessValues,nPipelinesFitnessDelta, 'Color',[0.6 0.6 0.6], 'LineWidth',1.5);

    xlabel('Delta fitness threshold');
    ylabel('NPipes');

    ht = title([dataSetTest.dataSetName ' - Fitness Thresh NPipes']);
    set(ht,'Interpreter','none');    
    
    set(h,'PaperPositionMode','auto');
    fname=[params.resultPath 'fitnessThreshNPipes.pdf'];
    print(h,'-dpdf','-r0',fname);    

	% export as figure (for later calling and changing size or such)
	fname = [ params.resultPath 'fitnessThreshNPipes.fig'];
	saveas(h,fname,'fig') 
    
    if params.silentPlot
        close(h);
    end        
    
    
   %-----------------------------------------
   % second strategy: diversity maximized
    evaluationListDetailsDiversityMax = {};
    accuraciesDiversityMax = [];
    
    [indexListDiversityMax, diversityDistribution] = multiPipeline.prepareDiversityMaximizationStrategy();
    multiPipeline.multiPipelineParams.trainingStrategy = 'diversityMaxRanking'; 
    
    for iN=numbersPipelinesVector   
        multiPipeline.multiPipelineParams.useNumberConfigurations = iN;
        cEvalRes = multiPipeline.evaluateLastDataSetAgain();
        accuraciesDiversityMax(end+1) = cEvalRes.accuracyOverall;
        evaluationListDetailsDiversityMax{end+1} = cEvalRes;
    end

    dataAggregated.fusionMaxDiversity = struct;
    dataAggregated.fusionMaxDiversity.evaluationListDetails = evaluationListDetailsDiversityMax;
    dataAggregated.fusionMaxDiversity.accuracies = accuraciesDiversityMax;
    dataAggregated.fusionMaxDiversity.indexListMaxDiversity = indexListDiversityMax;      
    dataAggregated.fusionMaxDiversity.diversityDistribution = diversityDistribution;   
    
    [bestPFDivMaxAcc, bestPFDivMaxNumber] = max(accuraciesDiversityMax);
     
    dataAggregated.fusionMaxDiversity.MultiPipelineBestAccuracy = bestPFDivMaxAcc;
    dataAggregated.fusionMaxDiversity.MultiPipelineBestNumberPipelines = bestPFDivMaxNumber;    
   
    
   %------------------------------
   % plot diversity results            
    h= figure;
    if params.silentPlot
        set(h,'Visible','off');
    end
    set(h,'Position', [10 500 600 300]);            

    plot(diversityDistribution, 'Color','k', 'LineWidth',1.5);

    xlabel('Diversity Sorted Index');
    ylabel('Diversity Metric');

    ht = title([dataSetTest.dataSetName ' - Diversity Distribution']);
    set(ht,'Interpreter','none');    
    
    set(h,'PaperPositionMode','auto');
    fname=[params.resultPath 'diversityDistribution.pdf'];
    print(h,'-dpdf','-r0',fname);    

	% export as figure (for later calling and changing size or such)
	fname = [ params.resultPath 'diversityDistribution.fig'];
	saveas(h,fname,'fig') 
    
    if params.silentPlot
        close(h);
    end       
    
    % make diversity sorted config list
    
    tableOptions = struct;
    tableOptions.classNames = params.trainingInfo.trainingInfo.job.dataSet.classNames;
    tableOptions.nItemLimit = 1000; % limit to save disk space
    tableOptions.exportFileName = [params.resultPath 'diversitySortedConfigList.csv']; 
    tableOptions.job = params.trainingInfo.trainingInfo.job;
    
    sortedList = multiPipeline.trainingData.topResults.evalItemsSortedQualityMetricTop;
    sortedList = sortedList(indexListDiversityMax);
    
    StatisticsTextBased.exportResultTable(sortedList,tableOptions); 
    
    
    
    
    
%--------------------------------------------------
% plot simple top and diversity maximizer stats
    for plotIndex =1:2

        % plot results            
        h= figure;
        if params.silentPlot
            set(h,'Visible','off');
        end
        set(h,'Position', [10 500 620 290]);            
        legends = {};
        hold on;

       if plotIndex == 1
           
           labelOffset = 0.06*(max(accuraciesSimpleTop)-min(accuraciesSimpleTop));
           
            % accuracies simple top fusion
            plot(numbersPipelinesVector, accuraciesSimpleTop, 'Color',[0.5 0.5 0.5], 'LineWidth',1.5);
            legends{end+1} = 'Accuracy pipeline fusion';            

            %only best
            plot(1,accuracyOnlyBestPipeline, 'o', 'MarkerSize',7,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor', [0 0 0]);
            text(1,accuracyOnlyBestPipeline+labelOffset, sprintf('%0.4f',accuracyOnlyBestPipeline));
            legends{end+1} = sprintf('Top single pipeline');    

%             % top n
%             topn = [10 20 50];
%             markers={'^','v','s'};
%             for itopn=1:numel(topn)
%                 ctopn= topn(itopn);
%                 if numel(accuraciesSimpleTop) >= ctopn
%                     cVal = accuraciesSimpleTop(ctopn);
%                     plot(ctopn,cVal, markers{itopn}, 'MarkerSize',7,'MarkerEdgeColor',[0.3 0.3 0.3],'MarkerFaceColor', [0.3 0.3 0.3]);
%                     text(ctopn,cVal+labelOffset, sprintf('%0.4f',cVal));                        
%                 end
%                 legends{end+1} = sprintf('Top %d pipelines',ctopn);  
%             end
            
            %best fusion
            plot(multiPipelineBestNumber ,accuracyBestMultiPipeline, 'p',  'MarkerSize',9,'MarkerEdgeColor',[0.5 0.5 0.5],'MarkerFaceColor', [0.5 0.5 0.5]);
            text(multiPipelineBestNumber ,accuracyBestMultiPipeline+labelOffset, sprintf('%0.4f',accuracyBestMultiPipeline));
            legends{end+1} = sprintf('Best pipeline fusion (%d pipelines)',multiPipelineBestNumber);  

            
            
       else
           labelOffset = 0.06*(max(accuraciesDiversityMax)-min(accuraciesDiversityMax));
            % accuracies diversity max fusion
            plot(numbersPipelinesVector, accuraciesDiversityMax, 'Color',[0.5 0.5 0.5], 'LineWidth',1.5);
            legends{end+1} = 'Accuracy pipeline fusion';  
            
            %best fusion
            plot(bestPFDivMaxNumber ,bestPFDivMaxAcc, 'p',  'MarkerSize',7,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor', [0 0 0]);
            text(bestPFDivMaxNumber ,bestPFDivMaxAcc+labelOffset, sprintf('%0.4f',bestPFDivMaxAcc));
            legends{end+1} = sprintf('Best pipeline fusion (%d pipelines)',bestPFDivMaxNumber);           
       end
        
        grid on;

        legend(legends,'Location','Best');
        xlim([1 numbersPipelinesVector(end)])

        if plotIndex == 1
            ht = title([dataSetTest.dataSetName ' - Simple top fusion']);
            exportFilename = [params.resultPath 'AccuarcyPlotSimpleTop'];
         else
            ht = title([dataSetTest.dataSetName ' - Diversity max fusion']);
             exportFilename = [params.resultPath 'AccuarcyPlotMaxDiv'];
        end
        set(ht,'Interpreter','none');

        xlabel('Number of fused pipelines');
        ylabel('Accuracy');

        set(h,'PaperPositionMode','auto');
        print(h,'-dpdf','-r0',[exportFilename '.pdf']);    

         % export as figure (for later calling and changing size or such)
         saveas(h,[exportFilename '.fig'],'fig') 

        if params.silentPlot
            close(h);
        end    
    end
    
    
    
    
    % make configuration plot of best multi pipeline fusion solutions
%     plotOptions = struct;
%     plotOptions.exportPlot = 1;
%     plotOptions.showPlots = 0;
%     plotOptions.numberOfFeaturesDisplay = 20; % most relevant features
%     nTopConfigs = multiPipelineBestNumber;
%     plotOptions.exportPlotFormat = 'pdf';
%     plotOptions.exportFileName = sprintf('%sconfigurationGraphMultiPipeline',params.resultPath);
%     plotOptions.markBestSolution = 0;
%     plotOptions.headline = sprintf('Stacked Configuration Graph of Multi Pipeline System (%d Pipelines)',nTopConfigs);
%     evalItemsSortedTop = params.evalItemsSortedTop.evalItemsSortedQualityMetricTop(1:nTopConfigs);
%     configurationPlot_v3(evalItemsSortedTop, params.trainingInfo.trainingInfo, plotOptions);    
    
    
    
    
    
    

end

 
        

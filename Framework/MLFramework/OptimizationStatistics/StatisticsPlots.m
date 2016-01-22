% Class definition StatisticsPlots
%
% This class handles plots of evaluations
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef StatisticsPlots < handle
    
    properties 
 
    end
    
    %====================================================================
    methods
         

        
      end % end methods public ____________________________________________
      
        
      
      
     methods(Static = true)      
 
        %__________________________________________________________________
        % get a plot of the development of the evaluation metric
        % over time/iterations
        % evalItems should be sorted by time/iteration!
        function exportQualityMetricPlot(evalItems, plotOptions)
            nItems = numel(evalItems);
            historyQuality = zeros(nItems,1);
            historyQualityBest = zeros(nItems,1);
            currentBestVal = -1;
            currentBestIndex = 0;
            xVectorTime = zeros(nItems,1);
            xVectorIterations = 1:nItems;
            for ii=1:nItems
                cEval = evalItems{ii};
                qVal = cEval.qualityMetric;
                historyQuality(ii)=qVal;
                if qVal > currentBestVal
                    currentBestVal = qVal;
                    currentBestIndex= ii;
                end
                historyQualityBest(ii)=currentBestVal;
                xVectorTime(ii) = cEval.calcTimePassedSinceStart/60;
            end
            
            % clean data
            historyQuality(historyQuality <=-1) = NaN;
            historyQualityBest(historyQualityBest <=-1) = NaN;
            
            h=figure();
            if ~plotOptions.showPlots
                set(h,'Visible','off');
            end
            set(h,'Position', [10 800 800 500]);
             
            if strcmp(plotOptions.xAxisUnit,'time')
                xVector = xVectorTime;
            else
                xVector = xVectorIterations; 
            end
            plot(xVector,historyQuality,'Color',[0.6 0.6 0.6]);
            hold on;
            plot(xVector,historyQualityBest,'LineWidth',2);
            
            ylabel('quality metric');
            legend({'current quality metric','best quality metric'},'Location','SouthWest');
                        
            if strcmp(plotOptions.xAxisUnit,'time')
                xlabel('time [min]');
                bestTime = xVectorTime(currentBestIndex);
                vline(bestTime,'b--',[sprintf('T=%0.2f min, quality=%0.4f',bestTime,currentBestVal)]);
                plot(bestTime,currentBestVal,'bs','MarkerFaceColor','b');
            else
                xlabel('iteration');
                vline(currentBestIndex,'b--',[sprintf('index=%d, quality=%0.4f',currentBestIndex,currentBestVal)]);
                plot(currentBestIndex,currentBestVal,'bs','MarkerFaceColor','b');
            end            
            if plotOptions.exportPlot
                if strcmp(plotOptions.exportPlotFormat,'png')
                    set(h,'PaperPositionMode','auto');
                    print(h,'-dpng','-r0',[plotOptions.exportFileName '.png']);    
                end
                if strcmp(plotOptions.exportPlotFormat,'pdf')
                    %set(h,'PaperPositionMode','auto');
                    print(h,'-dpdf','-r0',[plotOptions.exportFileName '.pdf']);    
                end  
                % export as figure (for later calling and changing size or such)
                saveas(h,[plotOptions.exportFileName '.fig'],'fig')
            end
            
            if ~plotOptions.showPlots
                close(h);
            end
        end        
        
        
        %__________________________________________________________________
        % time series plot export 
        function exportTimeSeriesPlot(xVector,yVector, plotOptions)
            
            h=figure();
            if ~plotOptions.showPlots
                set(h,'Visible','off');
            end
            set(h,'Position', [10 800 800 450]);
            
            plot(xVector,yVector,'Color',[0 0 0]);
            hold on;
            
            [maxVal, maxInd] = max(yVector);
            maxValX = xVector(maxInd);
            plot(maxValX,maxVal,'bs','MarkerFaceColor','b');
            vline(maxValX,'b--',[sprintf('best=%0.4f',maxVal)]);
            
            ylabel(plotOptions.yLabel);
            xlabel(plotOptions.xLabel);
            title(plotOptions.title)
            
            if plotOptions.exportPlot
                if strcmp(plotOptions.exportPlotFormat,'png')
                    set(h,'PaperPositionMode','auto');
                    print(h,'-dpng','-r0',[plotOptions.exportFileName '.png']);    
                end
                if strcmp(plotOptions.exportPlotFormat,'pdf')
                    set(h,'PaperPositionMode','auto');
                    print(h,'-dpdf','-r0',[plotOptions.exportFileName '.pdf']);    
                end 
                % export as figure (for later calling and changing size or such)
                saveas(h,[plotOptions.exportFileName '.fig'],'fig')                
            end
            
            if ~plotOptions.showPlots
                close(h);
            end
        end        
        
        
        
        
 
        %__________________________________________________________________
        % time series evolutionary stats 1 
        function exportEvolutionaryTimeSeries1(timeSeriesObject, plotOptions)
            % iplot = 1=index, 2 = time
            for iPlot=1:2
                h=figure();
                if iPlot == 1
                    name = 'fitness_generation';
                else
                    name = 'fitness_time';
                end                
                if ~plotOptions.showPlots
                    set(h,'Visible','off');
                end
                set(h,'Position', [10 100 400 300]);
                hold on;
                valueFactor = 1;
                [y_mean, index, time] = timeSeriesObject.getTimeSeriesValues('genMeanFitness');
                [y_std, index_std, time_std] = timeSeriesObject.getTimeSeriesValues('genStdFitness');
                [y_genBest, index_genBest, time_genBest] = timeSeriesObject.getTimeSeriesValues('genBestFitness');
                y_mean = valueFactor*y_mean;
                y_std = valueFactor*y_std;
                y_genBest = valueFactor*y_genBest;
                time = time/60;
                
                %[y_overBest, index_overBest, time_overBest] = timeSeriesObject.getTimeSeriesValues('bestFitnessOverall');
                [bestFitness, bestFitnessIndex] = max(y_genBest);
                bestFitnessTime = time_genBest(bestFitnessIndex)/60;
                
                if iPlot == 1
                    %index
                    errorbar(index-1,y_mean,y_std,'color',[0.6 0.6 0.6],'linewidth',1);
                    plot(index-1,y_genBest,'color',[0 0 0],'linewidth',1);
                    plot(bestFitnessIndex-1,bestFitness,'^','color',[0 0 0],'markerfacecolor',[0 0 0])
                    text(bestFitnessIndex-1,bestFitness+0.02, sprintf('%0.4f',bestFitness));
                    maxIndex = max((index-1));
                    xlim( [-0.5,maxIndex+0.5]);
                    
                else
                    %time
                    errorbar(time,y_mean,y_std,'color',[0.6 0.6 0.6],'linewidth',1);
                    plot(time,y_genBest,'color',[0 0 0],'linewidth',1);
                    plot(bestFitnessTime,bestFitness,'^','color',[0 0 0],'markerfacecolor',[0 0 0])
                    text(bestFitnessTime,bestFitness+0.02, sprintf('%0.4f',bestFitness));
                    maxTime = max(time);
                    xlim( [0,maxTime]);
                end    
                
                legendEntries = {'Generation mean +- SD','Generation best','Overall best'};
                legend(legendEntries,'Location','SouthEast');
                ylabel('Fitness');
                if iPlot == 1
                    xlabel('Generation');
                else
                    xlabel('Time [min]');
                end
                grid on;
                grid minor;
                
                
                if plotOptions.exportPlot
                    if strcmp(plotOptions.exportPlotFormat,'png')
                        set(h,'PaperPositionMode','auto');
                        print(h,'-dpng','-r0',[plotOptions.exportFileName '_' name '.png']);    
                    end
                    if strcmp(plotOptions.exportPlotFormat,'pdf')
                        set(h,'PaperPositionMode','auto');
                        print(h,'-dpdf','-r0',[plotOptions.exportFileName '_' name '.pdf']);    
                    end    
                    % export as figure (for later calling and changing size or such)
                    saveas(h,[plotOptions.exportFileName  '_' name '.fig'],'fig')                   
                end

                if ~plotOptions.showPlots
                    close(h);
                end
            end
         
        end                       
        
        
        
        
  %__________________________________________________________________
        % time series evolutionary stats 2 
        function exportEvolutionaryTimeSeries2(timeSeriesObject, plotOptions)
            h=figure();
            name = 'individualRatios';
            if ~plotOptions.showPlots
                set(h,'Visible','off');
            end
            set(h,'Position', [10 100 400 300]);
            hold on;
            valueFactor = 100;
            [nIndividualsBadRatio, index, time] = timeSeriesObject.getTimeSeriesValues('nIndividualsBadRatio');
            [nIndividualsBetterThanBestRatio, ~, ~] = timeSeriesObject.getTimeSeriesValues('nIndividualsBetterThanBestRatio');
            [nIndividualsBetterThanAverageRatio, ~, ~] = timeSeriesObject.getTimeSeriesValues('nIndividualsBetterThanAverageRatio');
            
            %nIndividualsBadRatio = valueFactor*nIndividualsBadRatio;
            nIndividualsBetterThanBestRatio = valueFactor*nIndividualsBetterThanBestRatio;
            nIndividualsBetterThanAverageRatio = valueFactor*nIndividualsBetterThanAverageRatio;
            indexVals = index-1;
            
            plot(indexVals(2:end),nIndividualsBetterThanBestRatio(2:end),'color',[0.6 0.6 0.6],'linewidth',2);
            plot(indexVals(2:end),nIndividualsBetterThanAverageRatio(2:end),'color',[0 0 0],'linewidth',1);
            %plot(indexVals,nIndividualsBadRatio,':','color',[0 0 0],'linewidth',1);
            legendEntries = {'better than last best','better than last average'};
            
            maxIndex = max((indexVals));
            xlim( [-0.5,maxIndex+0.5]);

            
            legend(legendEntries,'Location','northoutside');
                
            ylabel('% Individuals');
            xlabel('Generation');

            grid on;

            if plotOptions.exportPlot
                if strcmp(plotOptions.exportPlotFormat,'png')
                    set(h,'PaperPositionMode','auto');
                    print(h,'-dpng','-r0',[plotOptions.exportFileName '_' name '.png']);    
                end
                if strcmp(plotOptions.exportPlotFormat,'pdf')
                    set(h,'PaperPositionMode','auto');
                    print(h,'-dpdf','-r0',[plotOptions.exportFileName '_' name '.pdf']);    
                end    
                % export as figure (for later calling and changing size or such)
                saveas(h,[plotOptions.exportFileName  '_' name '.fig'],'fig')                   
            end

            if ~plotOptions.showPlots
                close(h);
            end

         
        end                       
                
        
              
        %__________________________________________________________________
        % time series evolutionary stats 3
        function exportEvolutionaryTimeSeries3(timeSeriesObject, plotOptions)
            h=figure();
            name = 'earlyDiscardingSaving';
            if ~plotOptions.showPlots
                set(h,'Visible','off');
            end
            set(h,'Position', [10 100 400 300]);
            hold on;
            valueFactor = 100;
            [earlyDiscardingRatios, index, time] = timeSeriesObject.getTimeSeriesValues('EarlyDiscardingEvalRatio');
            [totalSaved, ~, ~] = timeSeriesObject.getTimeSeriesValues('EarlyDiscardingTotalEvalsSaved');
            [totalEvals, ~, ~] = timeSeriesObject.getTimeSeriesValues('EarlyDiscardingTotalEvals');
            
            
            earlyDiscardingRatios =  valueFactor*(1-earlyDiscardingRatios);
            indexVals = index-1;

            if ~isempty(earlyDiscardingRatios) && ~any(isnan(earlyDiscardingRatios))
                plot(indexVals,earlyDiscardingRatios,'--','color',[0 0 0],'linewidth',1);
            end
            totalCounter = sum(totalEvals(:));
            totalSavedCounter = sum(totalSaved(:));
            percentage = 100*totalSavedCounter/totalCounter;
            
            title(sprintf('Evaluations Saved by Early Discarding (Total %d / %d = %0.1f %%)',totalSavedCounter,totalCounter,percentage));
            ylabel('%');
            xlabel('Generation');

            grid on;

            if plotOptions.exportPlot
                if strcmp(plotOptions.exportPlotFormat,'png')
                    set(h,'PaperPositionMode','auto');
                    print(h,'-dpng','-r0',[plotOptions.exportFileName '_' name '.png']);    
                end
                if strcmp(plotOptions.exportPlotFormat,'pdf')
                    set(h,'PaperPositionMode','auto');
                    print(h,'-dpdf','-r0',[plotOptions.exportFileName '_' name '.pdf']);    
                end    
                % export as figure (for later calling and changing size or such)
                saveas(h,[plotOptions.exportFileName  '_' name '.fig'],'fig')                   
            end

            if ~plotOptions.showPlots
                close(h);
            end 
        end                       
                        
 
  %__________________________________________________________________
        % time series evolutionary stats 4
        function exportEvolutionaryTimeSeries4(timeSeriesObject, plotOptions)
            h=figure();
            name = 'earlyDiscardingAcceptanceIntervals';
            if ~plotOptions.showPlots
                set(h,'Visible','off');
            end
            set(h,'Position', [10 100 400 300]);
            hold on;
            valueFactor = 100;
            [EarlyDiscardingQualityMean, index, time] = timeSeriesObject.getTimeSeriesValues('EarlyDiscardingQualityMean');
            [EarlyDiscardingQualityStd, ~, ~] = timeSeriesObject.getTimeSeriesValues('EarlyDiscardingQualityStd');
            
            indexVals = index-1;
            % first value not meaningfull
            EarlyDiscardingQualityMean(1) = [];
            EarlyDiscardingQualityStd(1) = [];
            indexVals(1) = [];
            if ~isempty(EarlyDiscardingQualityMean) && ~any(isnan(EarlyDiscardingQualityMean))
                errorbar(indexVals,EarlyDiscardingQualityMean,EarlyDiscardingQualityStd,'color',[0 0 0],'linewidth',1);
                
            end

            ylabel('Fitness');
            xlabel('Generation');

            maxIndex = max((indexVals));
            xlim( [0.5,maxIndex+0.5]);
            
            grid on;

            if plotOptions.exportPlot
                if strcmp(plotOptions.exportPlotFormat,'png')
                    set(h,'PaperPositionMode','auto');
                    print(h,'-dpng','-r0',[plotOptions.exportFileName '_' name '.png']);    
                end
                if strcmp(plotOptions.exportPlotFormat,'pdf')
                    set(h,'PaperPositionMode','auto');
                    print(h,'-dpdf','-r0',[plotOptions.exportFileName '_' name '.pdf']);    
                end    
                % export as figure (for later calling and changing size or such)
                saveas(h,[plotOptions.exportFileName  '_' name '.fig'],'fig')                   
            end

            if ~plotOptions.showPlots
                close(h);
            end

         
        end                    
        
        
        %__________________________________________________________________
        % time series group plot export 
        function exportTimeSeriesGroupPlot(timeSeriesObject, plotOptions)
            % iplot = 1=index, 2 = time
            for iPlot=1:2
                h=figure();
                if iPlot == 1
                    name = 'generation';
                else
                    name = 'time';
                end                
                if ~plotOptions.showPlots
                    set(h,'Visible','off');
                end
                set(h,'Position', [10 800 800 850]);
                hold on;
                legendEntries = {};
                nTimeSeries = numel(timeSeriesObject.timeSeriesList);
                colorList = linspecer(nTimeSeries);
                maxVal = 0;
                minVal = 1;
                for iTs =1:nTimeSeries
                    cTs = timeSeriesObject.timeSeriesList{iTs};
                    cName = cTs.id;
                    cDataValues = [];
                    cIndexValues = [];
                    cTimeValues = [];
                    for ii=1:numel(cTs.dataList)
                        cDataValues(end+1)=cTs.dataList{ii}.dataItem.value;
                        cIndexValues(end+1) = cTs.dataList{ii}.index;
                        cTimeValues(end+1) = cTs.dataList{ii}.timePassedSinceStart/60;
                    end
                    if iPlot == 1
                        plot(cIndexValues,cDataValues,'color',colorList(iTs,:),'linewidth',2);
                    else
                        plot(cTimeValues,cDataValues,'color',colorList(iTs,:),'linewidth',2);
                    end
                    if max(cDataValues) > maxVal
                        maxVal = max(cDataValues);
                    end
                    if min(cDataValues) < minVal
                        minVal = min(cDataValues);
                    end                    
                    legendEntries{end+1} = cName;
                end

                legend(legendEntries,'Location','SouthEast');
                ylabel('fitness');
                if iPlot == 1
                    xlabel('generation');
                else
                    xlabel('time [min]');
                end
                 ylim([minVal-0.02 maxVal+0.05]);
                grid on;
                grid minor;
                if plotOptions.exportPlot
                    if strcmp(plotOptions.exportPlotFormat,'png')
                        set(h,'PaperPositionMode','auto');
                        print(h,'-dpng','-r0',[plotOptions.exportFileName '_' name '.png']);    
                    end
                    if strcmp(plotOptions.exportPlotFormat,'pdf')
                        set(h,'PaperPositionMode','auto');
                        print(h,'-dpdf','-r0',[plotOptions.exportFileName '_' name '.pdf']);    
                    end    
                    % export as figure (for later calling and changing size or such)
                    saveas(h,[plotOptions.exportFileName '.fig'],'fig')                   
                end

                if ~plotOptions.showPlots
                    close(h);
                end
            end
        end                
     
        
     end
              
      
      
      methods(Access = private)
      
      end %private methods
        

    
    
end



       






        

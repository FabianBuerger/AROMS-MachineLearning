% Class definition StatisticsFrequencies
%
% This class handles frequency analyses of components
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef StatisticsFrequencies < handle
    
    properties 
     
    end
    
    %====================================================================
    methods
  
    end % end methods public ____________________________________________
   
     methods(Static = true)


         
         
        %__________________________________________________________________
        % perform frequency analysis
        function frequencyAnalysis(evalItems,trainingInfo,exportOptions)
            %exportOptions.exportFileName
            %exportOptions.exportTable = 1;
            %exportOptions.exportBarPlot = 1;
            exportOptions.orderItemsByFrequency = 1; 
            
            counterObject = FrequencyCounter;
            if strcmp(exportOptions.components,'Features')
                counterObject.initCounter(trainingInfo.job.jobParams.dynamicComponents.componentsFeatureSelection);
            end
            if strcmp(exportOptions.components,'FeaturePreprocessing')
                componentsItems = trainingInfo.job.jobParams.dynamicComponents.componentsFeaturePreProcessing;
                counterObject.initCounter(componentsItems);
            end              
            if strcmp(exportOptions.components,'FeatureTransforms')
                componentsItems = getCellArrayOfProperties(...
                   trainingInfo.job.jobParams.dynamicComponents.componentsFeatureTransSelection,'name');
                counterObject.initCounter(componentsItems);
            end                
            if strcmp(exportOptions.components,'Classifiers')
                componentsItems = getCellArrayOfProperties(...
                   trainingInfo.job.jobParams.dynamicComponents.componentsClassifierSelection,'name');
                counterObject.initCounter(componentsItems);
            end              
            nEvalItems = numel(evalItems);
            for iEvalItem = 1:nEvalItems
                cEvalItem = evalItems{iEvalItem};
                config = cEvalItem.resultData.configuration;
                
                if strcmp(exportOptions.components,'Features')
                    counterObject.addItemCounterBin(config.configFeatureSelection.featureSubSet,1);
                end
                if strcmp(exportOptions.components,'FeaturePreprocessing')
                    counterObject.addItemCounter(config.configPreprocessing.featurePreProcessingMethod,1);
                end                     
                if strcmp(exportOptions.components,'FeatureTransforms')
                    counterObject.addItemCounter(config.configFeatureTransform.featureTransformMethod,1);
                end                
                if strcmp(exportOptions.components,'Classifiers')
                    counterObject.addItemCounter(config.configClassifier.classifierName,1);
                end   
            end
            if exportOptions.orderItemsByFrequency
                counterObject.orderItemsByFrequency();
            end
            normFactor=100/nEvalItems;
            [itemStrings, itemFrequencies] = counterObject.getData(normFactor);
         
            nFeat = numel(trainingInfo.job.jobParams.dynamicComponents.componentsFeatureSelection);
            exportBar = strcmp(exportOptions.components,'FeatureTransforms') || strcmp(exportOptions.components,'Classifiers') || nFeat < 100;
            exportLine = strcmp(exportOptions.components,'Features');
            
            if exportBar 
                h = figure('Position',[1 100 700 400],'Color', [1 1 1]);
                if ~exportOptions.showPlots
                    set(h,'Visible','off');
                end 

                barh(itemFrequencies);
                set(gca, 'YTick', 1:numel(itemFrequencies), 'YTickLabel', itemStrings);
                set(gca,'YDir','reverse');
                title(['Frequencies of ' exportOptions.components ]);
                xlabel('% of appreance');
                ylabel(exportOptions.components);


                set(gca,'LooseInset',get(gca,'TightInset'));
                if exportOptions.exportPlot
                    if strcmp(exportOptions.exportPlotFormat,'png')
                        set(h,'PaperPositionMode','auto');
                        print(h,'-dpng','-r0',[exportOptions.exportPlotFileName '_bar.png']);    
                    end
                    if strcmp(exportOptions.exportPlotFormat,'pdf')
                        %set(h,'PaperPositionMode','auto');
                        print(h,'-dpdf','-r0',[exportOptions.exportPlotFileName '_bar.pdf']);    
                    end   
                    % export as figure (for later calling and changing size or such)
                    saveas(h,[exportOptions.exportPlotFileName '_bar.fig'],'fig')                
                end

                if ~exportOptions.showPlots
                    close(h);
                end
            end
            
            if exportLine 
                h = figure('Position',[1 100 700 400],'Color', [1 1 1]);
                if ~exportOptions.showPlots
                    set(h,'Visible','off');
                end 

                plot(itemFrequencies);
                
                title(['Frequencies of ' exportOptions.components ]);
                xlabel('index');
                ylabel('frequency');

                set(gca,'LooseInset',get(gca,'TightInset'));
                if exportOptions.exportPlot
                    if strcmp(exportOptions.exportPlotFormat,'png')
                        set(h,'PaperPositionMode','auto');
                        print(h,'-dpng','-r0',[exportOptions.exportPlotFileName '_line.png']);    
                    end
                    if strcmp(exportOptions.exportPlotFormat,'pdf')
                        %set(h,'PaperPositionMode','auto');
                        print(h,'-dpdf','-r0',[exportOptions.exportPlotFileName '_line.pdf']);    
                    end   
                    % export as figure (for later calling and changing size or such)
                    saveas(h,[exportOptions.exportPlotFileName '_line.fig'],'fig')                
                end

                if ~exportOptions.showPlots
                    close(h);
                end
            end            
            
            % export csv List
            csvString = {};
            for ii=1:numel(itemStrings)
                cItem = itemStrings{ii};
                cVal = itemFrequencies(ii);
                csvString{end+1} = sprintf('%s,%0.2f',cItem,cVal);
            end
            
            
            saveMultilineString2File(csvString,exportOptions.exportListFileName );
        end         
         
         
                 
      end
              
      
      
      methods(Access = private)
      
      end %private methods
        

    
    
end


        

        

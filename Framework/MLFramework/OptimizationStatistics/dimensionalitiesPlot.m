% function dimensionalitiesPlot(evalItems,trainingInfo, plotOptions)
% plot stages of dimensionalities in the top x configurations
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015    
function dimensionalitiesPlot(evalItems,trainingInfo, plotOptions)

    % base statistics
    nConfigs = numel(evalItems);
    featureNamesAll=fieldnames(trainingInfo.job.dataSet.instanceFeatures);
    nDimensionsAll = getSubSetDimensionality(trainingInfo.job.dataSet, featureNamesAll);
    
    
    
    % count frequencies
    dimensionalities = [];
    for iConfig = 1:nConfigs
        cEvalItem = evalItems{iConfig};
        featSubSetBin = cEvalItem.resultData.configuration.configFeatureSelection.featureSubSet;
        featSubSet = featureSubSetFromBitString(featSubSetBin, featureNamesAll);
        featSelDim = getSubSetDimensionality(trainingInfo.job.dataSet,featSubSet);
        featTransDim = cEvalItem.resultData.configuration.configFeatureTransform.featureTransformParams.nDimensions;
        cDimVec = [nDimensionsAll, featSelDim, featTransDim];
        dimensionalities = [dimensionalities; cDimVec];
    end    
    
    
    
    
    plotHeight = 400;
    h = figure('Position',[1 100 500 plotHeight],'Color', [1 1 1]);
    if ~plotOptions.showPlots
        set(h,'Visible','off');
    end 
    hold on;
    
    
    % plot lines
    lineColor = [0.7 0.7 0.7];
    meanDim = median(dimensionalities,1);
    for iConfig = 1:nConfigs
       cDims = dimensionalities(iConfig,:);
       hAll = plot([0 1 1 2 2 3], [cDims(1), cDims(1), cDims(2), cDims(2), cDims(3), cDims(3)] ,'-', 'LineWidth',2 ,'Color', lineColor); 
    end
    
    % plot mean     
    hMean = plot([0 1 1 2 2 3], [meanDim(1), meanDim(1), meanDim(2), meanDim(2), meanDim(3), meanDim(3)] ,'-', 'LineWidth',2 ,'Color', [0 0 0]);
    
    % plot best
    bestDim = dimensionalities(1,:);
    hBest = plot([0 1 1 2 2 3], [bestDim(1), bestDim(1), bestDim(2), bestDim(2), bestDim(3), bestDim(3)] ,'--', 'LineWidth',2 ,'Color', [0 0 0]);
    
    legend([hAll, hMean, hBest],{sprintf('top %d configurations',nConfigs), sprintf('median top %d configurations',nConfigs),'best configuration'});
    
    ylabel('Dimensionality');
    set(gca,'XTick',[0 1 2 3])
    set(gca,'XTickLabel',{'Input', 'Feature Selection', 'Feature Transform', 'Classifier'})
    

    % last options
    set(gca,'LooseInset',get(gca,'TightInset'));

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



%=======================
% helper

function nDims = getSubSetDimensionality(dataSet, featureSubset)
    nDims = 0;
    for iFeat = 1:numel(featureSubset)
        cFeat = featureSubset{iFeat};
        cFeatData = dataSet.instanceFeatures.(cFeat);
        nDims = nDims+size(cFeatData,2);
    end
end



        

        

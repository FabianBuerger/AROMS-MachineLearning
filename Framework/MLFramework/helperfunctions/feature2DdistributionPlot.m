% function feature2DdistributionPlot(jobAnalysisPath, plotOptions)
% plot 2D feature selection distribution after analysis
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015    
function feature2DdistributionPlot(jobAnalysisPath, plotOptions)


% load data
load([jobAnalysisPath 'trainingInfo.mat']);
%load([jobAnalysisPath 'trainingResults.mat']);
load([jobAnalysisPath 'data/sortedConfigurationListTop.mat']);

exportFileBase = [jobAnalysisPath 'plots' filesep];

nItemsTop = min(plotOptions.nConfigsTop,numel(evalItemsSortedQualityMetricTop));
fprintf('Using %d configurations\n',nItemsTop);
evalItemsTop = evalItemsSortedQualityMetricTop(1:nItemsTop);
compFeatureSel = trainingInfo.job.jobParams.dynamicComponents.componentsFeatureSelection;

for iPlot = 1:size(plotOptions.feature2DInfos,1)
   cAnalysisName = plotOptions.feature2DInfos{iPlot,1};
   cFeatureNames = plotOptions.feature2DInfos{iPlot,2};
   targetDim = numel(cFeatureNames);
   cImSize = plotOptions.feature2DInfos{iPlot,3};

   if targetDim ~= prod(cImSize)
        error('Image Size does not match number of dimensions');
   end
    
    %locate feature indices
    featureIndices = nan(1,numel(cFeatureNames));
    for iFeat = 1:numel(cFeatureNames)
        [found, indices] = cellStringsContainString(compFeatureSel,cFeatureNames{iFeat});
        if found
            featureIndices(iFeat) = indices;
        end
    end
    if any(isnan(featureIndices))
        error('Some features have not been found in optimization!');
    end

    imageDataLinear = zeros(1,targetDim);
    for iConfig = 1:nItemsTop
        cEvalItem = evalItemsTop{iConfig};
        featSubSetBin = cEvalItem.resultData.configuration.configFeatureSelection.featureSubSet;
        selectedFeatures = featSubSetBin(featureIndices);
        imageDataLinear = imageDataLinear + double(selectedFeatures);
    end        
    imageDataLinear = imageDataLinear/nItemsTop;
    image = reshape(imageDataLinear,cImSize);
    image = imresize(image,4,'nearest');
    
    plotHeight = 400;
    h = figure();
    imshow(image,[]);
    set(h,'Position',[-1000 000 plotHeight plotHeight]); % ubuntu multi screen hack 

    
    plotExportName = [exportFileBase 'feature2DAnalysis_' cAnalysisName '.png'];
    imageExp = uint8(image*255);
    imwrite(imageExp,plotExportName);
    
%     % export
%     plotExport = [exportFileBase 'feature2DAnalysis_' cAnalysisName];
%     set(gca,'LooseInset',get(gca,'TightInset'));
% 
%     set(h,'PaperPositionMode','auto');
%     print(h,'-dpdf','-r0',[plotExport '.pdf']);  
%     
%     % export as figure (for later calling and changing size or such)
%     saveas(h,[plotExport '.fig'],'fig')

end
    
    



    







        

        

% function featureDistributionAnalysis(dataSet,resultFolder,showFigures)
% Analyze value domains/feature distribution of features from a dataSet
% with box plots and exports them to images
% 
% 
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015


function featureDistributionAnalysis(dataSet,resultFolder,showFigures)

nPlotsPerFigure = 4;
cPlot = 0;
cSubIndex = 0;  
cFigure = 0;

featureNames = fieldnames(dataSet.instanceFeatures);
for iFeat=1:numel(featureNames)
   cFeatureName = featureNames{iFeat};
   cFeatureVector = getfield(dataSet.instanceFeatures,cFeatureName);
    
   % plot each channel
   nChannels = size(cFeatureVector,2);
   for iChannel = 1:nChannels
        cVec = cFeatureVector(:,iChannel);
        if mod(cPlot,nPlotsPerFigure)==0
            
            hf= figure('Color', [1 1 1]); 
            if ~showFigures
                set(hf, 'Visible', 'off');
            end
            set(hf,'Position', [10 800 800,500]);
            cFigure = cFigure+1;
            cSubIndex = 0;
        end        
        cPlot = cPlot+1;
        cSubIndex = cSubIndex+1;
        
        subplot(nPlotsPerFigure,1,cSubIndex)
        boxplot(cVec,dataSet.targetClasses,'orientation','horizontal','labels',dataSet.classNames);

       titleStr = ['Feature: ' cFeatureName];
       if nChannels > 1
           titleStr = [titleStr ' (' num2str(iChannel) ')'];
       end
       title(titleStr);
       
       % export plot
        if cSubIndex==nPlotsPerFigure || (iFeat == numel(featureNames) && iChannel==nChannels)
            if ~strcmp(resultFolder,'')
                fileNamePlot = [resultFolder 'featureDistribution_' num2str(cFigure) '.png'];
                set(gcf,'PaperPositionMode','auto');
                print(gcf,'-dpng','-r0',fileNamePlot);
            end
           close(hf); 
        end        
   end

end









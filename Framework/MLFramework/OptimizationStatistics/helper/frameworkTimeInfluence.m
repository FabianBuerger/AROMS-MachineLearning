% function frameworkTimeInfluence()    
% graphically analyze the dataset property impact
%

function frameworkTimeInfluence(dataStruct)


% add additional infoByDataset from other analyses
for ii=1:numel(dataStruct.statParams.addParams.additionalFiles)
    cFile = dataStruct.statParams.addParams.additionalFiles{ii};
    ds = load(cFile);
    for iInfo = 1:numel(ds.dataStruct.infoByDataset)
        cds = ds.dataStruct.infoByDataset{iInfo};
        dataStruct.infoByDataset{end+1} = cds;
    end
end



exportFileName  = [dataStruct.resultPath 'datasetTimeInfluence'];

for iMode = [1 2]
    figure;  
    hold on;
  
    if iMode == 1
        suffix = 'no_features';
    end
    if iMode == 2
         suffix = 'no_samples';
    end    
    if iMode == 3
         suffix = 'no_classes';
    end    
    if iMode == 4
         suffix = 'no_features_no_samples';
    end       
     
    colorVal = 0.7*[74 150 215]/255;
    trainingTestDivisionFactor = 2;
    
    dataX = [];
    dataY = [];
    
    for iDs = 1:numel(dataStruct.infoByDataset)
        cInfo = dataStruct.infoByDataset{iDs};

        if iMode == 1
            xVal = cInfo.dataSet.totalDimensionality;
        end
        if iMode == 2
            xVal = cInfo.dataSet.nSamples*trainingTestDivisionFactor; %
        end    
        if iMode == 3
            xVal = cInfo.dataSet.nClasses;  
        end    
        if iMode == 4
            xVal = cInfo.dataSet.totalDimensionality+cInfo.dataSet.nSamples*trainingTestDivisionFactor;
        end               
        yVal = cInfo.meanVal;
        yStd = cInfo.stdVal;

        plot(xVal,yVal,'o','MarkerEdgeColor',colorVal,'MarkerFaceColor',colorVal,'MarkerSize',3);
        errorbar(xVal,yVal,yStd,'Color',colorVal);
        
        dataX(end+1) = xVal;
        dataY(end+1) = yVal;
    end
    [dataX, sortidx] =  sort(dataX);
    dataY = dataY(sortidx);
    
    
    ylabel('Optimization time [min]');
    
    if iMode == 1
        xlabel('Number features');
        set(gca,'xscale','log');
        set(gca,'XTick',[ 10 100 1000]);
       xlim([3 1100]);
    end
    if iMode == 2
         xlabel('Number samples');
         set(gca,'xscale','log');
         %set(gca,'XTick',[100 500 1000 2000]);
         xlim([100 2000]);
    
    end    
    if iMode == 3
        xlabel('Number classes');
    end    
    if iMode == 4
        xlabel('number features + samples ');
        set(gca,'xscale','log');
    end        
    grid minor
    
    %
    % poly fit regression
    p = polyfit(dataX,dataY,1); 
    xDataReg = [min(dataX):max(dataX)];
    r = p(1) .* xDataReg + p(2); % compute a new vector r that has matching datapoints in x
	hh= plot(xDataReg, r, '--');
    legend([hh],'Linear regression','Location','Best');
    
    
    correlcoefficient  = corr2(dataX,dataY)
    
    set(gcf,'Position',[100 100 310, 250])
    print(gcf,'-dpdf','-r0',[exportFileName '_' suffix '.pdf']);    

    % export as figure (for later calling and changing size or such)
    saveas(gcf,[exportFileName '_' suffix '.fig'],'fig')      
    
end





save([dataStruct.resultPath 'frameworkTimeInfluenceData.mat'], 'dataStruct');




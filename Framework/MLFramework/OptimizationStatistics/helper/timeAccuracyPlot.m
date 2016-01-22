% function timeAccuracyPlot()    
% graphically analyze the connection between time and accuracy
% accuracy
%

function timeAccuracyPlot(dataStruct)

 
figure;

hold on;

dx=2.2;
dy=0.01;

handleList = [];
legendList={};
counter = 0;
indexHighlight = 3;
symbols = {'o','s','d','^','v','>','<'};

for iM=1:numel(dataStruct.plotItems)
    if ~any(iM == dataStruct.skipMetaIndices)
        counter = counter+1;
        cItem = dataStruct.plotItems{iM};

        xVal = cItem.timeMean/60;
        xStd = cItem.timeStd/60;
        if dataStruct.mode == 1
            yVal = cItem.trainAccMean;
            yStd = cItem.trainAccStd;
        end
        if dataStruct.mode == 2
            yVal = cItem.testAccMean;
            yStd = cItem.testAccStd;
        end    
        errorbar(xVal,yVal,yStd,'Color',[0.5 0.5 0.5],'LineWidth',[1.5]);
        herrorbarGray(xVal,yVal,xStd);
        
    end
end
counter = 0;

for iM=1:numel(dataStruct.plotItems)
    if ~any(iM == dataStruct.skipMetaIndices)
        counter = counter+1;
        cItem = dataStruct.plotItems{iM};

        xVal = cItem.timeMean/60;
        xStd = cItem.timeStd/60;
        if dataStruct.mode == 1
            yVal = cItem.trainAccMean;
            yStd = cItem.trainAccStd;
        end
        if dataStruct.mode == 2
            yVal = cItem.testAccMean;
            yStd = cItem.testAccStd;
        end    
      
        if counter == 1
            %pointColor = [74 150 215]/255;
            pointColor = [0 0 0];
            faceColor = [74 150 215]/255;
        else
            pointColor = [0 0 0];
            faceColor = [1 1 1];
        end
        handlePoint = plot(xVal,yVal,symbols{counter},'Color',pointColor,'MarkerFaceColor',faceColor, 'LineWidth',1.1);
        %ss = sprintf('%d',counter);
        %text(dx+xVal,dy+yVal,ss);
        handleList(end+1) = handlePoint;
        legendList{end+1} = sprintf('%s',cItem.caption);
    end
end


legend(handleList, legendList,'Location','Best');

%set(gca,'XScale','log');

if dataStruct.mode == 1
    ylabel('Cross-validation accuracy')
    suffix = 'train';
end
if dataStruct.mode == 2
    ylabel('Generalization accuracy')    
    suffix = 'test';
end

xlabel('Processing time [min]')




set(gcf,'Position',[100 100 380, 280])
%set(gca,'LooseInset',get(gca,'TightInset'));

print(gcf,'-dpdf','-r0',[dataStruct.exportFileName '_' suffix '.pdf']);    

% export as figure (for later calling and changing size or such)
saveas(gcf,[dataStruct.exportFileName '_' suffix '.fig'],'fig')
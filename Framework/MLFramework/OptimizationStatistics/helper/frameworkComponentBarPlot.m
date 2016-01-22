% function frameworkComponentBarPlot()    
% graphically analyze the importance of the components of the framework 
%

function frameworkComponentBarPlot(dataStruct)


dataTrain = dataStruct.dataTrain;
dataTrainSD = dataStruct.dataTrainSD; 
sigMarkersTrain = dataStruct.sigMarkersTrain; 

dataTest = dataStruct.dataTest;
dataTestSD = dataStruct.dataTestSD;
sigMarkersTest= dataStruct.sigMarkersTest;


addInfo = struct;
addInfo.colors = {[74 150 215]/255, [208 230 249]/255};
%addInfo.axisLables = { 'Feature selection off', 'Feature preprocessing off', 'Feature transforms off', 'Simple classifier only' , 'Hyperparameter tuning off' };
addInfo.axisLables = { 'ECA-noFeatSel', 'ECA-noPreProc', ...
    'ECA-noTrans', 'ECA-simpleClassifier' , 'ECA-defaultHyper' };
legendEntries = {'Cross-validation accuracy','Generalization accuracy'};

%  {'ECA-full', 'ECA-noFeatSel', 'ECA-noPreProc', 'ECA-noTrans', 'ECA-simpleClassifier','ECA-defaultHyperparams'};

exportFileName  = [dataStruct.resultPath 'ComponentInfluenceDiagram'];

figure;

y= [dataTrain',dataTest'];
errY = [dataTrainSD',dataTestSD'];
sigMarkers = [ sigMarkersTrain', sigMarkersTest'];


h = barwitherr(errY, y, sigMarkers,dataStruct.addParams.componentInfluencePlotInfo);% Plot with errorbars
set(gca,'YTickLabel',addInfo.axisLables);
order = [2 1];
legend([h(2), h(1)], legendEntries(order),'Location',dataStruct.addParams.componentInfluencePlotInfo.legendPos);
xlabel('Accuracy change')
set(h(1),'FaceColor', addInfo.colors{1});   
set(h(2),'FaceColor',addInfo.colors{2});  
if isfield(dataStruct,'addParams')
    xlim(dataStruct.addParams.componentInfluencePlotInfo.XLim);
end

grid minor;

set(gcf,'Position',[100 100 600, 250])
%set(gca,'LooseInset',get(gca,'TightInset'));

print(gcf,'-dpdf','-r0',[exportFileName '.pdf']);    

% export as figure (for later calling and changing size or such)
saveas(gcf,[exportFileName  '.fig'],'fig')
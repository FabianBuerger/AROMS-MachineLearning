% function frameworkComponentBarPlotTime()    
% graphically analyze the importance of the components of the framework 
%

function frameworkComponentBarPlotTime(dataStruct)


dataTrain = dataStruct.dataTrain;
dataTrainSD = dataStruct.dataTrainSD; 
sigMarkersTrain = dataStruct.sigMarkersTrain; 



addInfo = struct;
addInfo.colors = {[208 230 249]/255};
%addInfo.axisLables = { 'Feature selection off', 'Feature preprocessing off', 'Feature transforms off', 'Simple classifier only' , 'Hyperparameter tuning off' };
addInfo.axisLables = { 'ECA-noFeatSel', 'ECA-noPreProc', ...
    'ECA-noTrans', 'ECA-simpleClassifier' , 'ECA-defaultHyper' };
%legendEntries = {'Cross-validation accuracy','Generalization accuracy'};

%  {'ECA-full', 'ECA-noFeatSel', 'ECA-noPreProc', 'ECA-noTrans', 'ECA-simpleClassifier','ECA-defaultHyperparams'};

exportFileName  = [dataStruct.resultPath 'ComponentInfluenceDiagramTime'];

figure;

y= [dataTrain'];
errY = [dataTrainSD'];
sigMarkers = [ sigMarkersTrain'];

h = barwitherr(errY, y, sigMarkers,dataStruct.addParams.componentInfluenceTimePlotInfo);% Plot with errorbars
set(gca,'YTickLabel',addInfo.axisLables);
%order = [2 1];
%legend(h(1), legendEntries,'Location','best');
xlabel('Optimization time change [min]')
set(h(1),'FaceColor', addInfo.colors{1});   

if isfield(dataStruct,'addParams')
    xlim(dataStruct.addParams.componentInfluenceTimePlotInfo.XLim);
end

grid minor;

set(gcf,'Position',[100 100 600, 180])
%set(gca,'LooseInset',get(gca,'TightInset'));

print(gcf,'-dpdf','-r0',[exportFileName '.pdf']);    

% export as figure (for later calling and changing size or such)
saveas(gcf,[exportFileName  '.fig'],'fig')
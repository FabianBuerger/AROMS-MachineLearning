% function variableImportanceRandomForestExport(importanceValues, featureNames, destinationFolder)

% export variable importance information 

function variableImportanceRandomForestExport(importanceValues, featureNames, destinationFolder)

    [~, indexSort] =  sort(importanceValues,'descend');

    importanceValuesSorted = 100*importanceValues(indexSort);
    featureNamesSorted = featureNames(indexSort);



    % export csv List
    csvString = {};
    for ii=1:numel(featureNamesSorted)
        cItem = featureNamesSorted{ii};
        cVal = importanceValuesSorted(ii);
        csvString{end+1} = sprintf('%s;%0.2f',cItem,cVal);
    end
    [~, ~ ,~ ] = mkdir([destinationFolder 'tables']);
    fileName = [destinationFolder 'tables' filesep 'variableImportanceRandomForest.csv'];
    saveMultilineString2File(csvString, fileName );


    % export bar plot with best 20 features
    nBestFeatures = min(20,numel(importanceValuesSorted));
    importanceValuesSortedCut = importanceValuesSorted(1:nBestFeatures);
    featureNamesSortedCut = featureNamesSorted(1:nBestFeatures);

    h = figure('Position',[1 100 700 400],'Color', [1 1 1]);
    set(h,'Visible','off');


    barh(importanceValuesSortedCut);
    set(gca, 'YTick', 1:numel(importanceValuesSortedCut), 'YTickLabel', featureNamesSortedCut);
    set(gca,'YDir','reverse');
    title(['Feature Importance Estimation by Random Forest']);
    xlabel('% importance');
    ylabel('Features');

    set(gca,'LooseInset',get(gca,'TightInset'));
    
    fileName =  [destinationFolder 'plots' filesep 'variableImportanceRandomForest'];
    [~, ~ ,~ ] = mkdir([destinationFolder 'plots']);
    print(h,'-dpdf','-r0', [fileName '.pdf']);    

    % export as figure (for later calling and changing size or such)
    saveas(h,[fileName '.fig'],'fig')                

    close(h);

end


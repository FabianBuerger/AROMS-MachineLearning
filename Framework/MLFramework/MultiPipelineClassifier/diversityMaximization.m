% function [configurationListSorted, indicesFromBaseList] = diversityMaximization(configurationListTmp, job)
% 
% sort configurations by diversity -> the n+1th item adds maximum diversity
% to the currently selected n configurations
% 
%  
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015


function [configurationListSorted, indicesFromBaseList, diversityDistribution] = diversityMaximization(configurationListTmp, job)


fullFeatureSet = fieldnames(job.dataSet.instanceFeatures);

% make new index list (some pipelines cause trouble so the rank doesnt help
% so much!
for ii=1:numel(configurationListTmp)
    cConfigItem = configurationListTmp{ii};
    cConfigItem.listIndex = ii;
%     cConfigItem.configuration.configFeatureSelection.featureBinCode = ...   
%          makeFeatureBinCode(cConfigItem.configuration.configFeatureSelection.featureSubSet, fullFeatureSet);
    configurationListTmp{ii} = cConfigItem;
end


% pre calculate the feature bin mask



nItemsInSortedList = numel(configurationListTmp);
indicesFromBaseList = [];
diversityDistribution = [];
configurationListSorted = {};

% append first and best solution in any case
[configurationListTmp,configurationListSorted] = moveAndAppendCellItem(configurationListTmp,configurationListSorted,1);
indicesFromBaseList(end+1) = 1;
diversityDistribution(end+1) = 1;


for ii = 1:nItemsInSortedList-1
    
    divTmpMax = -1;
    cIndexTmpmaxDiv = 0;
    % find the item from tmp list with maximum diversity to final list  
    for jTmp = 1:numel(configurationListTmp)

        cItemTmp= configurationListTmp{jTmp};
        % diversity regarding all items in final list (take smallest to
        % final list)
        divMin = 1;
        for iItemCurrentTop = 1:numel(configurationListSorted)
            cItemTop = configurationListSorted{iItemCurrentTop};
            diversity = evalutateDiversityBetween2Configurations(cItemTmp.configuration,cItemTop.configuration,fullFeatureSet);
            if diversity < divMin
                divMin = diversity;
            end
        end
        
        if divMin > divTmpMax
            divTmpMax = divMin;
            cIndexTmpmaxDiv = jTmp;
        end
    end
    
    if cIndexTmpmaxDiv > 0
        [configurationListTmp,configurationListSorted] = moveAndAppendCellItem(configurationListTmp,configurationListSorted,cIndexTmpmaxDiv);
        indicesFromBaseList(end+1) = configurationListSorted{end}.listIndex;
        diversityDistribution(end+1) = divTmpMax;
    end
    
end



%-------------- helper


function diversity = evalutateDiversityBetween2Configurations(config1,config2,fullFeatureSet)


singleFactors = [0 0 0 0];
% 1) Features

try

    binaryFeaturesConfig1 = config1.configFeatureSelection.featureSubSet;
    binaryFeaturesConfig2 = config2.configFeatureSelection.featureSubSet;

    diffFeatures = sum(abs(binaryFeaturesConfig1-binaryFeaturesConfig2))/numel(fullFeatureSet);
    singleFactors(1) = diffFeatures;

    % 2) preprocessing
    if ~strcmp(config1.configPreprocessing.featurePreProcessingMethod, config2.configPreprocessing.featurePreProcessingMethod)
        singleFactors(2) = 1;
    end

    % 3) feature transform
    if ~strcmp(config1.configFeatureTransform.featureTransformMethod, config2.configFeatureTransform.featureTransformMethod)
        singleFactors(3) = 1;
    end

    % 4) classifier
    if ~strcmp(config1.configClassifier.classifierName, config2.configClassifier.classifierName)
        singleFactors(4) = 1;
    end

catch
end

diversity = mean(singleFactors);







function [cell1,cell2] = moveAndAppendCellItem(cell1,cell2,index)
cell2{end+1} = cell1{index};
cell1(index) = [];

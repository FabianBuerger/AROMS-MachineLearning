% function configurationPlot_v2(evalItems,trainingInfo, plotOptions)
% plot configurations as graph to visualize
% the usage of components with overlaying all evaluation items.
% This version plots horizontically
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015    
function configurationPlot_v3(evalItems,trainingInfo, plotOptions)

    %plotDimensionBars = 0;
    
    nConfigs = numel(evalItems);
        
    % prepare component names and displaynames
    if plotOptions.featureSplitUndo
        featureNames = trainingInfo.job.dataSet.featureSplitInfo.originalFeatureNames;
    else
        featureNames = trainingInfo.job.jobParams.dynamicComponents.componentsFeatureSelection;
    end
    
    %make string lists from binary features
    allFeatureStrings = trainingInfo.job.jobParams.dynamicComponents.componentsFeatureSelection;
    for iConfig = 1:nConfigs
        cEvalItem = evalItems{iConfig};
        cEvalItem.resultData.configuration.configFeatureSelection.featureSubSetStrings = ...
            featureSubSetFromBitString(cEvalItem.resultData.configuration.configFeatureSelection.featureSubSet, allFeatureStrings);
        cEvalItem.resultData.configuration.configFeatureSelection.featureSubSetIndexLists = ...
            find(cEvalItem.resultData.configuration.configFeatureSelection.featureSubSet);
        evalItems{iConfig} = cEvalItem;
    end
    
    componentsFeatures = {};
    for ii=1:numel(featureNames)
        feat = struct;
        feat.displayName = featureNames{ii};
        feat.name = featureNames{ii};
        componentsFeatures{end+1} = feat;
    end
    componentsFeatTransforms = trainingInfo.job.jobParams.dynamicComponents.componentsFeatureTransSelection;
    componentsClassifiers = trainingInfo.job.jobParams.dynamicComponents.componentsClassifierSelection;
    
    if numel(featureNames) > 12
        plotHeight = 900; 
    else
        plotHeight = 700;
    end
    h = figure('Position',[1 100 700 plotHeight],'Color', [1 1 1]);
    if ~plotOptions.showPlots
        set(h,'Visible','off');
    end 
    hold on;
    set(gca,'YDir','reverse');    
    
    % calculate occurrences of components
    %--------------------------------------------------------------    
    componentsFeatures = frequencyCounterList(componentsFeatures);
    componentsFeatTransforms = frequencyCounterList(componentsFeatTransforms);
    
    % feature preprocessing + feature transform
    frameworkBaseComponents = frameworkComponentLists();
    
    if plotOptions.showFeaturePreProcessing
        methodsWithPreProc = {};
        for iFeatTrans = 1:numel(componentsFeatTransforms)
            
           
            for iPreProc = 1:numel(frameworkBaseComponents.featurePreProcessingMethods.options)
                cTrans = componentsFeatTransforms{iFeatTrans};
                cPreProcMethod = frameworkBaseComponents.featurePreProcessingMethods.options{iPreProc};
                cPreProcMethodName = frameworkBaseComponents.featurePreProcessingMethods.optionNames{iPreProc};
                
                preProcNone = strcmp(cPreProcMethod,'none');
                featTransNone = strcmp(cTrans.name,'none');
                
                sumNones = single(preProcNone) + single(featTransNone);
                if sumNones == 2
                    cTrans.displayName = 'no transform';    
                elseif sumNones == 1
                    if preProcNone
                        cTrans.displayName = [cTrans.displayName];   
                    end
                    if featTransNone
                        cTrans.displayName = [cPreProcMethodName];   
                    end                    
                else
                    cTrans.displayName = [cPreProcMethodName ' + ' cTrans.displayName];    
                end
                cTrans.name = [cPreProcMethod ',' cTrans.name];
                methodsWithPreProc{end+1} = cTrans;                
            end
            

        end
        componentsFeatTransforms = methodsWithPreProc;
    end
    
    
    componentsClassifiers = frequencyCounterList(componentsClassifiers);
    
%     dimbarFeatSel = getEmptyDimensionBar(trainingInfo.job.dataSet.totalDimensionality);
%     dimbarFeatTrans = getEmptyDimensionBar(trainingInfo.job.dataSet.totalDimensionality);
    
    % count frequencies
    for iConfig = 1:nConfigs
        cEvalItem = evalItems{iConfig};
        % feature frequencies
        if plotOptions.featureSplitUndo
            componentsFeatures = frequencyCounterIncrementCounterBinSplit(componentsFeatures,...
                cEvalItem.resultData.configuration.configFeatureSelection.featureSubSet,trainingInfo.job.dataSet.featureSplitInfo);
        else
            componentsFeatures = frequencyCounterIncrementCounterBin(componentsFeatures,...
                cEvalItem.resultData.configuration.configFeatureSelection.featureSubSet);            
        end
        % feature transform frequencies
        cTransName = cEvalItem.resultData.configuration.configFeatureTransform.featureTransformMethod;
        % add preprocessing
        if plotOptions.showFeaturePreProcessing
            cTransName = [cEvalItem.resultData.configuration.configPreprocessing.featurePreProcessingMethod  ',' cTransName];
        end
        componentsFeatTransforms = frequencyCounterIncrementCounter(componentsFeatTransforms,cTransName);
        
        % classifier frequencies
        componentsClassifiers = frequencyCounterIncrementCounter(componentsClassifiers,...
            cEvalItem.resultData.configuration.configClassifier.classifierName);           
        
    end
    
    % name mapping
    if isfield(plotOptions.optInfos,'configPlotFeatureNameMapping')
        featMapping = plotOptions.optInfos.configPlotFeatureNameMapping;
        for iFeat = 1:numel(componentsFeatures)
           cFeat = componentsFeatures{iFeat};
           featName = cFeat.displayName;
           for iName = 1:size(featMapping,1)
                if strcmp(featMapping{iName,1},featName)
                    featName = featMapping{iName,2};
                    break;
                end
           end
           componentsFeatures{iFeat}.displayName = featName;
        end
        
    end
    
    % round values (sorting issue..)
    if plotOptions.featureSplitUndo
        for ii=1:numel(componentsFeatures)
            cCompFeat = componentsFeatures{ii};
            cCompFeat.frequencyCounter = double(round(cCompFeat.frequencyCounter*100)/100);
            componentsFeatures{ii} = cCompFeat;
        end
    end
    
    %order features by frequency
    [~,sortOrder] = sort(cellfun(@(v) v.frequencyCounter,componentsFeatures),'descend');
    componentsFeaturesDisplay = componentsFeatures(sortOrder);   
    
    [~,sortOrder] = sort(cellfun(@(v) v.frequencyCounter,componentsFeatTransforms),'descend');
    componentsFeatTransformsDisplay = componentsFeatTransforms(sortOrder);   
    
    [~,sortOrder] = sort(cellfun(@(v) v.frequencyCounter,componentsClassifiers),'descend');
    componentsClassifiersDisplay = componentsClassifiers(sortOrder);     
    
    % feature rest box active?
    restId = '__REST_Feature__'; % note a feature name with leading _ can not be added to struct
    featureRestMapping = {};
    featureRestMappingIndices = [];
    if numel(componentsFeaturesDisplay) > plotOptions.numberOfFeaturesDisplay+1
        featuresRestActive = 1;
        % put names of features that should be mapped to rest
        restFrequencyCounter = 0;
        restItems = 0;
        restDim = 0;
        for iFeat = plotOptions.numberOfFeaturesDisplay+1:numel(componentsFeaturesDisplay)
            cItem = componentsFeaturesDisplay{iFeat};
            featureRestMapping{end+1} = cItem.name;
            [~, foundAtIndex] = cellStringsContainString(featureNames,cItem.name);
            featureRestMappingIndices(end+1) = foundAtIndex;
            restFrequencyCounter = restFrequencyCounter + cItem.frequencyCounter;
            restItems = restItems+1;
            if plotOptions.featureSplitUndo
                restDim = restDim+trainingInfo.job.dataSet.featureSplitInfo.originalDimensionalities(foundAtIndex);
            else
                restDim = restDim+1;
            end            
        end
        % cut display list
        componentsFeaturesDisplay = componentsFeaturesDisplay(1:plotOptions.numberOfFeaturesDisplay);
        % add rest item
        restItem = struct;
        restItem.name = restId;
        restItem.displayName = sprintf('Rest (%d features)',restItems);
        restItem.frequencyCounter = restFrequencyCounter;
        % relative rest item (frequency divided by number of items)
        % best color perception in plot later
        if restItems > 1 
            restItem.frequencyCounter = restItem.frequencyCounter/restItems;
        end	
        restItem.isRestItem = 1; % for display gap
        componentsFeaturesDisplay{end+1} = restItem;
    else
        featuresRestActive = 0;
        restItems = 0;
        restDim = 0;
    end
    
    % calculate relative frequency
    componentsFeaturesDisplay=frequencyCounterRelativeFrequencies(componentsFeaturesDisplay);
    componentsFeatTransformsDisplay=frequencyCounterRelativeFrequencies(componentsFeatTransformsDisplay);
    componentsClassifiersDisplay=frequencyCounterRelativeFrequencies(componentsClassifiersDisplay);
    %mark best solution if desired
    if plotOptions.markBestSolution 
        bestConfig = evalItems{1};
        bestFeatSubSet = bestConfig.resultData.configuration.configFeatureSelection.featureSubSetStrings;
        restAlreadyMarked = 0;
        for ii=1:numel(bestFeatSubSet)
            if plotOptions.featureSplitUndo
                cFeat = '??';
                cFeatSplit = bestFeatSubSet{ii};
                for iMap = 1:numel(trainingInfo.job.dataSet.featureSplitInfo.featureSplitMapping)
                    map = trainingInfo.job.dataSet.featureSplitInfo.featureSplitMapping{iMap};
                    if strcmp(cFeatSplit,map.splitName)
                        cFeat = map.origName;
                        break;
                    end
                end
                
            else
                cFeat = bestFeatSubSet{ii};
            end
            if cellStringsContainString(featureRestMapping,cFeat)
                if ~restAlreadyMarked
                    componentsFeaturesDisplay{end}.displayName = [componentsFeaturesDisplay{end}.displayName '*'];
                   restAlreadyMarked = 1; 
                end
            else
                for ij = 1:numel(componentsFeaturesDisplay)
                    if strcmp(componentsFeaturesDisplay{ij}.name,cFeat)
                        if ~componentsFeaturesDisplay{ij}.marker
                            componentsFeaturesDisplay{ij}.displayName = [componentsFeaturesDisplay{ij}.displayName '*'];
                            componentsFeaturesDisplay{ij}.marker = 1;
                        end
                    end
                end
            end
        end
        bestFeatTrans = bestConfig.resultData.configuration.configFeatureTransform.featureTransformMethod;
        
        if plotOptions.showFeaturePreProcessing
            bestFeatTrans = [bestConfig.resultData.configuration.configPreprocessing.featurePreProcessingMethod  ',' bestFeatTrans];
        end
        for ij = 1:numel(componentsFeatTransformsDisplay)
            if strcmp(componentsFeatTransformsDisplay{ij}.name,bestFeatTrans)
                componentsFeatTransformsDisplay{ij}.displayName = [componentsFeatTransformsDisplay{ij}.displayName '*'];
            end
        end 
        bestClassifier = bestConfig.resultData.configuration.configClassifier.classifierName;
        for ij = 1:numel(componentsClassifiersDisplay)
            if strcmp(componentsClassifiersDisplay{ij}.name,bestClassifier)
                componentsClassifiersDisplay{ij}.displayName = [componentsClassifiersDisplay{ij}.displayName '*'];
            end
        end         
    end
    % get connections for graph
    edgesFeatures2Transforms = GraphConnections;   % 
    edgesTransforms2Classifiers = GraphConnections;
    qualityMetrics = zeros(nConfigs,1);
    for iConfig = 1:nConfigs
        cEvalItem = evalItems{iConfig};
        qualityMetrics(iConfig) = cEvalItem.qualityMetric;
        featureSubSet = cEvalItem.resultData.configuration.configFeatureSelection.featureSubSetStrings;
        featureSubSetIndexLists = cEvalItem.resultData.configuration.configFeatureSelection.featureSubSetIndexLists;
        % feature transform frequencies
        featureTransformMethod = cEvalItem.resultData.configuration.configFeatureTransform.featureTransformMethod;
        % add preprocessing
        if plotOptions.showFeaturePreProcessing
            featureTransformMethod = [cEvalItem.resultData.configuration.configPreprocessing.featurePreProcessingMethod  ',' featureTransformMethod];
        end
        
        classifierName = cEvalItem.resultData.configuration.configClassifier.classifierName;
        
        % add connection to every feature
        for iFeat = 1:numel(featureSubSet)
            cFeatIndex = featureSubSetIndexLists(iFeat);
            edgeVaule = 1;
            if plotOptions.featureSplitUndo
                map = trainingInfo.job.dataSet.featureSplitInfo.featureSplitMapping{cFeatIndex};
                cFeat = map.origName;
                edgeVaule = 1/map.origDim;
                %mappedIndex
                cFeatIndex = map.origFeatureIndex; 
%                 cFeat = '??';
%                 cFeatSplit = featureSubSet{iFeat};                
%                 for iMap = 1:numel(trainingInfo.job.dataSet.featureSplitInfo.featureSplitMapping)
%                     map = trainingInfo.job.dataSet.featureSplitInfo.featureSplitMapping{iMap};
%                     if strcmp(cFeatSplit,map.splitName)
%                         cFeat = map.origName;
%                         edgeVaule = 1/map.origDim;
%                         break;
%                     end
%                 end
                
            else
                cFeat = featureSubSet{iFeat};
            end
            % map to rest
            if featuresRestActive
                %forRest = cellStringsContainString(featureRestMapping,cFeat);
                forRest = any(featureRestMappingIndices == cFeatIndex);
                if forRest
                    featureMapped = restId;
                    if restItems>1
                        %edgeVaule = 1/restItems;
                        edgeVaule = 1/restDim;
                    end
                else
                    featureMapped = cFeat;
                end
            else
                % no rest mapping
                featureMapped = cFeat;
            end
            edgesFeatures2Transforms.updateConnection(featureMapped, featureTransformMethod, edgeVaule);
        end
        % add connection transforms to classifiers
        edgesTransforms2Classifiers.updateConnection(featureTransformMethod, classifierName, 1);
    end    
    % sort edges (for painting)
    edgesFeatures2Transforms.sortEdges();
    edgesTransforms2Classifiers.sortEdges();
    
    % general params
    %--------------------------------------------------------------    
    frequencyColorBoxSize  = 4;

    %calculate positions and draw objects
    %--------------------------------------------------------------
    % features

    centerX = 0;
    centerY = 0;
    textScale = 4.7;
    
    objectStyle = struct;
    objectStyle.adaptiveVisibility = 0; % show all features   
    objectStyle.additionalGap = 4; % for rest features
    objectStyle.textRotation = 0;
    objectStyle.textBoxAlignment = 'center';
    objectStyle.fillColor = [1 1 1];
    objectStyle.positionMarkerLeft = 0;
    objectStyle.positionMarkerRight = 0;
    objectStyle.markerSize =12;
    objectStyle.markerColor = [0.7 0.7 0.7];            

    nMaxL = getMaxDisplayNameLength(componentsFeaturesDisplay, 10,~objectStyle.adaptiveVisibility);
    maxWidth = textScale*nMaxL;
    
    objectStyle.itemWidth = maxWidth;
    objectStyle.itemHeight = 11;
    objectStyle.itemSpacing = 1;
    objectStyle.pointSpacingHorizontal = 0;
    
    objectStyle.frequencyColorBox = 0;
    objectStyle.frequencyColorBG = 1;
    objectStyle.frequencyColorBoxSize = frequencyColorBoxSize;
    objectStyle.frequencyColorBoxColorProfile = 'node_linear';
    
    [componentsFeaturesDisplay, objectBorderInfoFeatures] = fillListWithObjectProperties(componentsFeaturesDisplay, centerX, centerY, objectStyle);

    
    %--------------------------------------------------------------
    % feature transforms
    
    deltaSpace = 40; 
    centerX = objectBorderInfoFeatures.maxX+deltaSpace;
    centerY = 0;
    
    posXFeatTrans = centerX;
    
    objectStyle = struct;
    objectStyle.adaptiveVisibility = 1;    
    objectStyle.textRotation = 0;
    objectStyle.textBoxAlignment = 'center';    
    objectStyle.fillColor = [1 1 1];
    objectStyle.positionMarkerLeft = 0;
    objectStyle.positionMarkerRight = 0; 
    objectStyle.markerSize =12;
    objectStyle.markerColor = [0.7 0.7 0.7];            

    nMaxL = getMaxDisplayNameLength(componentsFeatTransformsDisplay, 10,~objectStyle.adaptiveVisibility);
    maxWidth = textScale*nMaxL;
        
    objectStyle.itemWidth = maxWidth;
    objectStyle.itemHeight = 11;
    objectStyle.itemSpacing = 2;
    objectStyle.pointSpacingHorizontal = 0;

    objectStyle.frequencyColorBox = 0;
    objectStyle.frequencyColorBG = 1;
    objectStyle.frequencyColorBoxSize = frequencyColorBoxSize;
    objectStyle.frequencyColorBoxColorProfile = 'node_linear';
    
    [componentsFeatTransformsDisplay, objectBorderInfoFeatTransforms] = fillListWithObjectProperties(componentsFeatTransformsDisplay, centerX, centerY, objectStyle);  
    
    
    %--------------------------------------------------------------
    % classifiers
    deltaSpace = 40;
    centerX = objectBorderInfoFeatTransforms.maxX+deltaSpace;
    centerY = 0;
    
    posXClassifier = centerX;
    
    objectStyle = struct;
    objectStyle.adaptiveVisibility = 1;
    objectStyle.textRotation = 0;
    objectStyle.textBoxAlignment = 'center';    
    objectStyle.fillColor = [1 1 1];
    objectStyle.positionMarkerLeft = 0;
    objectStyle.positionMarkerRight = 0;
    objectStyle.markerSize =12;
    objectStyle.markerColor = [0.7 0.7 0.7];

    nMaxL = getMaxDisplayNameLength(componentsClassifiersDisplay, 15,~objectStyle.adaptiveVisibility);
    maxWidth = textScale*nMaxL;
    
    objectStyle.itemWidth = maxWidth;
    objectStyle.itemHeight = 11;
    objectStyle.itemSpacing = 2;
    objectStyle.pointSpacingHorizontal = 0;
    
    objectStyle.frequencyColorBox = 0;
    objectStyle.frequencyColorBG = 1;
    objectStyle.frequencyColorBoxSize = frequencyColorBoxSize;
    objectStyle.frequencyColorBoxColorProfile = 'node_linear';
    
    [componentsClassifiersDisplay, objectBorderInfoClassifiers]= fillListWithObjectProperties(componentsClassifiersDisplay, centerX, centerY, objectStyle);            
    
    %--------------------------------------------------------------
    % draw graph edges
    plotOptionsEdges = struct;
    plotOptionsEdges.frequencyColorBoxColorProfile = 'edge_linear';
    plotOptionsEdges.lineWidth = 2.5;
    plotOptionsEdges.paintArrow = 0;
    % features to feature transforms
    drawGraphEdges(edgesFeatures2Transforms.edgeItemList,componentsFeaturesDisplay,componentsFeatTransformsDisplay,plotOptionsEdges);
    % feature transforms to classifiers 
    drawGraphEdges(edgesTransforms2Classifiers.edgeItemList,componentsFeatTransformsDisplay,componentsClassifiersDisplay,plotOptionsEdges);
     
    
%     %draw dimensionalityboxes
%     if plotDimensionBars
% %         posBarSel = posXFeatTrans/2;
% %         dimbarFeatSel.PostionCenterXY(1) = posBarSel;
% %         drawDimensionalityBar(dimbarFeatSel)
% %         
%         posbarTrans = (posXClassifier)-deltaSpace/2; 
%         dimbarFeatTrans.PostionCenterXY(1) = posbarTrans;
%         drawDimensionalityBar(dimbarFeatTrans)
%     end
    
    
    %--------------------------------------------------------------            
    % draw component boxes
    drawObjectsAndPositionList(componentsFeaturesDisplay);
    drawObjectsAndPositionList(componentsFeatTransformsDisplay);
    drawObjectsAndPositionList(componentsClassifiersDisplay);         

    

    %--------------------------------------------------------------
    % headlines "Features", "Feature Transforms", "Classifiers"
    delta = 8;
    minYValues = [objectBorderInfoFeatures.minY, objectBorderInfoFeatTransforms.minY, objectBorderInfoClassifiers.minY];
    yHeadlines = min(minYValues)-2*delta;
    if plotOptions.featureSplitUndo
        featureText = 'Feature Groups';
    else
        featureText = 'Feature Groups';
    end
    text(objectBorderInfoFeatures.centerX,yHeadlines, featureText ,'HorizontalAlignment','center','fontSize',13,'fontWeight','normal');   
    if plotOptions.showFeaturePreProcessing
        middleColumText = 'Preprocessing + Transforms';
    else
        middleColumText = 'Feature Transforms';
    end
    
    text(objectBorderInfoFeatTransforms.centerX,yHeadlines, middleColumText ,'HorizontalAlignment','center','fontSize',13,'fontWeight','normal');  
    text(objectBorderInfoClassifiers.centerX,yHeadlines, 'Classifiers' ,'HorizontalAlignment','center','fontSize',13,'fontWeight','normal');

    % headline
    % sort quality 
    qualityMetricsSorted = sort(qualityMetrics);
    minQual = qualityMetricsSorted(1);
    maxQual = qualityMetricsSorted(end);
    %headlineStandard = sprintf('Top %d Configurations (Quality min: %0.4f, max: %0.4f)',nConfigs,minQual,maxQual);
    dataSetName = strrep(trainingInfo.job.dataSet.dataSetName,'_','-');
    headlineStandard = sprintf('Top Configuration Graph for %s',dataSetName);
    headlineText = queryStruct(plotOptions,'headline',headlineStandard);
    text(objectBorderInfoFeatTransforms.centerX,yHeadlines-4*delta, headlineText ,'HorizontalAlignment','center','fontSize',14,'fontWeight','bold');  
    
    % make colorbar for frequency display
    
    maxY = max([objectBorderInfoFeatTransforms.maxY, objectBorderInfoClassifiers.maxY]);
    maxX = objectBorderInfoClassifiers.maxX;
    
    deltaColorbarY = 15;
    deltaColorbarX =45;
    colorBarW = 50;
    colorBarH = 10;
    posColorbar = [maxY+deltaColorbarY, maxX-colorBarW-deltaColorbarX];
    
    cVal1 = 0.8;
    cVal2 = 0;
    nSteps = 40;
    boxSubWidth = colorBarW * 1/nSteps;
    for ii=0:nSteps-1
       cVal =  cVal1 + (cVal2-cVal1)*ii/nSteps;
       cX = posColorbar(2) + boxSubWidth*ii;
       
       rectangle('Position',[cX, posColorbar(1),boxSubWidth, colorBarH], 'FaceColor', ones(3,1)* cVal, 'EdgeColor',ones(3,1)* cVal);  
    end
    rectangle('Position',[posColorbar(2), posColorbar(1),colorBarW, colorBarH ]);  
    xText =posColorbar(2)+colorBarW+3;
    yText = posColorbar(1) + colorBarH/2;
    text(xText,yText, 'Frequency','fontSize',12,'fontWeight','normal');
    text(posColorbar(2)+3,posColorbar(1) + colorBarH/2, 'low','fontSize',10,'fontWeight','bold','Color',[0 0 0]);
    text(posColorbar(2)+colorBarW-17,posColorbar(1)+ colorBarH/2, 'high','fontSize',10,'fontWeight','bold','Color',[1 1 1]);
    
    % last options
    set(findobj(gcf, 'type','axes'), 'Visible','off')
    set(gca,'YDir','reverse');
    daspect([1 1 1])
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


%=== helper ======

%__________________________________________________________________
% add counters = 0 to item list
function itemList = frequencyCounterList(itemList)
    for ii=1:numel(itemList)
        item = itemList{ii};
        item.frequencyCounter = 0;
        item.marker = 0;
        itemList{ii} = item;
    end
end

%__________________________________________________________________
% increase counter of items. items can be a cell array of strings or a
% single string
function itemList = frequencyCounterIncrementCounter(itemList,stringItems)
    if ~iscell(stringItems)
        stringItems = {stringItems};
    end
    for iStr=1:numel(stringItems)
        cString = stringItems{iStr};
        % search for string
        foundStr = 0;
        for iItem=1:numel(itemList)
            item = itemList{iItem};
            if strcmp(item.name,cString)
                item.frequencyCounter = item.frequencyCounter + 1;
                itemList{iItem} = item;      
                foundStr = 1;
            end
        end    
        if ~foundStr
            warning('Did not find string %s in list',cString);
        end
    end
end

%__________________________________________________________________
% increase counter of items. items can be a cell array of strings or a
% single string
function itemList = frequencyCounterIncrementCounterBin(itemList,itemsBin)

    for iItem=1:numel(itemsBin)
        if itemsBin(iItem)
            item = itemList{iItem};
            item.frequencyCounter = item.frequencyCounter + 1;
            itemList{iItem} = item;      
        end
    end
end



%__________________________________________________________________
% increase counter of items. items can be a cell array of strings or a
% single string
function itemList = frequencyCounterIncrementCounterBinSplit(itemList,itemsBin,featureSplitInfo)

    for iItem=1:numel(itemsBin)
        if itemsBin(iItem)
            mapInfo = featureSplitInfo.featureSplitMapping{iItem};
            item = itemList{mapInfo.origFeatureIndex};
            item.frequencyCounter = item.frequencyCounter + 1/mapInfo.origDim;
            itemList{mapInfo.origFeatureIndex} = item;    
            
        end
    end
end


%__________________________________________________________________
% calculate relative frequencies
function itemList = frequencyCounterRelativeFrequencies(itemList)
minVal = inf;
maxVal = 0;
    for iItem=1:numel(itemList)
        item = itemList{iItem};
        if item.frequencyCounter > maxVal
            maxVal = item.frequencyCounter;
        end
        if item.frequencyCounter < minVal
            minVal = item.frequencyCounter;
        end        
    end  
    for iItem=1:numel(itemList)
        item = itemList{iItem};
        %item.frequencyRelative = (item.frequencyCounter-minVal)/(maxVal-minVal);  
        item.frequencyRelative = item.frequencyCounter/maxVal;  
        itemList{iItem} = item;
    end     
end

%__________________________________________________________________
% get colormapping from relativeVal (0-1) to rgb color defined by 
% colorProfile
function colorVal = frequencyColorMapping(relativeVal,colorProfile)
    colorVal = [1 0 1];
    %boxes can be white
    if strcmp(colorProfile,'node_linear')
	if relativeVal < eps
		colorVal = [1 1 1];	
	else
	        lowColor = [0.8 0.8 0.8]; % white
        	highColor = [0 0 0]; % black
        	deltaCol = highColor-lowColor;
        	colorVal = lowColor+relativeVal*deltaCol;
	end
    end
    % draw edges not entirely white
    if strcmp(colorProfile,'edge_linear')
        lowColor = [0.75 0.75 0.75]; % gray
        highColor = [0 0 0]; % black
        deltaCol = highColor-lowColor;
        colorVal = lowColor+relativeVal*deltaCol;        
    end    
    colorVal = min(1,max(0,colorVal));
end

%__________________________________________________________________
% draw the item lists with postions and style
function drawObjectsAndPositionList(itemList)
    for ii=1:numel(itemList)
        cItem = itemList{ii};
        objStyle = cItem.objectStyle;
        objPos = cItem.objectPositionInfo;
        % only draw visible items
        if objPos.visible
            if objStyle.positionMarkerLeft
                plot(objPos.pointCenterLeftXY(1),objPos.pointCenterLeftXY(2),'s','MarkerSize', objStyle.markerSize,'MarkerFaceColor',objStyle.markerColor,'MarkerEdgeColor',objStyle.markerColor);
            end

            if objStyle.positionMarkerRight
                plot(objPos.pointCenterRightXY(1),objPos.pointCenterRightXY(2),'s','MarkerSize', objStyle.markerSize, 'MarkerFaceColor',objStyle.markerColor,'MarkerEdgeColor',objStyle.markerColor);
            end

            % rectangle top
            if objStyle.frequencyColorBG
                % draw frequency as background color
                mainRectFillColor = objPos.frequencyColor;
                mainTextColor = [0 0 0];
                if mean(mainRectFillColor) < 0.6
                    mainTextColor = [1 1 1];
                end
            else
                mainRectFillColor = objStyle.fillColor;
                mainTextColor = [0 0 0];
            end
            rectangle('Position',[objPos.topleftXY(1), objPos.topleftXY(2), objPos.width, objPos.height],'FaceColor',mainRectFillColor);       

            % frequency box
            if isfield(objPos,'frequencyBox')
                rectangle('Position',[objPos.frequencyBox.topleftXY(1), objPos.frequencyBox.topleftXY(2), objPos.frequencyBox.width, objPos.frequencyBox.height],...
                    'FaceColor',objPos.frequencyColor);
            end

            fontSize= 11;
            if strcmp(objStyle.textBoxAlignment,'right')
            % text caption bottom for rotated
                delta= -2;
                hText = text(objPos.topleftXY(1)+objPos.width+delta, objPos.centerXY(2), cItem.displayName,'HorizontalAlignment', ...
                    objStyle.textBoxAlignment,'Color',mainTextColor,'Rotation',objStyle.textRotation,'fontSize',fontSize);
                set(hText, 'Interpreter', 'none')
            else
                % text caption center
                delta = 3;
                hText = text(objPos.centerXY(1) + delta, objPos.centerXY(2), cItem.displayName,'HorizontalAlignment',...
                    objStyle.textBoxAlignment,'Color',mainTextColor,'Rotation',objStyle.textRotation,'fontSize',fontSize);
                set(hText, 'Interpreter', 'none')
            end
        end
    end
end

%__________________________________________________________________
% draw edge list (edge list from GraphConnections)
function drawGraphEdges(edgeList, componentListStart, componentListEnd, plotOptions)
    for iEdge = 1:numel(edgeList)
       cEdge = edgeList{iEdge};
       lineOptions = struct;
       lineOptions.lineColor = frequencyColorMapping(cEdge.relativeEdgeWeight, plotOptions.frequencyColorBoxColorProfile);
       lineOptions.lineWidth = plotOptions.lineWidth;
       lineOptions.paintArrow = plotOptions.paintArrow;
       drawConnection(componentListStart, cEdge.startName, componentListEnd, cEdge.endName, lineOptions);
        
    end
end


%__________________________________________________________________
% draw edge line/arrow
function drawConnection(componentListStart, nameStart, componentListEnd, nameEnd, lineOptions)
    P1 = getObjectPoint(nameStart,componentListStart,'right');
    P2 = getObjectPoint(nameEnd,componentListEnd,'left');
    drawLineVertical(P1,P2,lineOptions)
end


%__________________________________________________________________
% get line connection point of box
function P = getObjectPoint(itemName,componentList,pointPos)
    index = 0;
    P = [0 0];
    for ii=1:numel(componentList)
        if strcmp(itemName,componentList{ii}.name)
            index = ii;
        end
    end
    if index==0
        warning('object not found');
    else
        cComponent = componentList{index};
        if strcmp(pointPos,'left')
            P=cComponent.objectPositionInfo.pointCenterLeftXY;
        end
        if strcmp(pointPos,'right')
            P=cComponent.objectPositionInfo.pointCenterRightXY;
        end    
    end
end


%__________________________________________________________________
% draw single line element with plot options
function drawLineVertical(P1,P2,plotOptions)
    xCoords = [P1(1),  P2(1)];
    yCoords = [P1(2),  P2(2)];

    if plotOptions.paintArrow
        arrow(xCoords, yCoords);
    else
        plot(xCoords, yCoords, 'Color', plotOptions.lineColor,'LineWidth',plotOptions.lineWidth);
    end
    
end

%__________________________________________________________________
% vertical alignment of objects and other properties
function [itemList, objectBorderInfo]= fillListWithObjectProperties(itemList, centerX, centerY, objectStyle)
    objectBorderInfo = struct;
    nItems = numel(itemList); 
    if objectStyle.adaptiveVisibility
        nItemsVisible = 0;
          for ii=1:nItems
            cItem = itemList{ii};
            if cItem.frequencyRelative > 0
                nItemsVisible = nItemsVisible+1;
            end
          end
    else
        nItemsVisible = numel(itemList); 
    end
    % calculate alignments
    totalHeight = nItemsVisible*objectStyle.itemHeight + (nItemsVisible-1)*objectStyle.itemSpacing;
    % top left
    yStartTL = centerY-totalHeight/2;
    addGap = 0; 
    
    visibleCounter = 0;
    for ii=1:nItems
        cItem = itemList{ii};
        if isfield(cItem,'isRestItem')
            addGap = addGap+objectStyle.additionalGap;
        end
        posInfo = struct;
        if objectStyle.adaptiveVisibility
            posInfo.visible = cItem.frequencyRelative > 0;
        else
            posInfo.visible = 1;
        end
        if posInfo.visible
            visibleCounter = visibleCounter+1;
        end
        y = addGap + yStartTL+ (max(visibleCounter-1,0))*(objectStyle.itemHeight + objectStyle.itemSpacing);
        x = centerX;
        posInfo.topleftXY = [x,y];
        posInfo.centerXY = [x+objectStyle.itemWidth/2,y+objectStyle.itemHeight/2];
        posInfo.pointCenterLeftXY = posInfo.centerXY - [objectStyle.itemWidth/2+objectStyle.pointSpacingHorizontal,0];
        posInfo.pointCenterRightXY = posInfo.centerXY + [objectStyle.itemWidth/2+objectStyle.pointSpacingHorizontal,0];
        posInfo.width = objectStyle.itemWidth;
        posInfo.height = objectStyle.itemHeight;
        posInfo.totalHeight = posInfo.height;
        posInfo.totalWidth = posInfo.width;
        posInfo.frequencyColor = frequencyColorMapping(cItem.frequencyRelative, objectStyle.frequencyColorBoxColorProfile);
        
        % a colored box with frequency indicators
        if objectStyle.frequencyColorBox
            frequencyBox = struct;
            frequencyBox.topleftXY = [x+posInfo.width,y];
            frequencyBox.width = objectStyle.frequencyColorBoxSize;
            frequencyBox.height = posInfo.height;
            posInfo.frequencyBox = frequencyBox;
            % adapt reight position
            posInfo.totalWidth = posInfo.totalWidth + frequencyBox.width;
            posInfo.pointCenterRightXY = posInfo.pointCenterRightXY + [frequencyBox.width 0];
        end        
        
        itemList{ii}.objectPositionInfo = posInfo;
        itemList{ii}.objectStyle = objectStyle;    
        
    end 
    
    objectBorderInfo.minX = itemList{1}.objectPositionInfo.topleftXY(1);
    objectBorderInfo.minY = itemList{1}.objectPositionInfo.topleftXY(2);
    objectBorderInfo.maxX = itemList{end}.objectPositionInfo.topleftXY(1)+itemList{end}.objectPositionInfo.totalWidth;
    objectBorderInfo.maxY = itemList{end}.objectPositionInfo.topleftXY(2)+itemList{end}.objectPositionInfo.totalHeight;   
    objectBorderInfo.centerX = (objectBorderInfo.maxX+objectBorderInfo.minX)/2;
    objectBorderInfo.centerY = (objectBorderInfo.maxY+objectBorderInfo.minY)/2;
    

end 



%=======================================


function dimbar = getEmptyDimensionBar(maxVal)
    dimbar = struct;
    dimbar.minVal = 1;
    dimbar.maxVal = maxVal;
    dimbar.values = [];
    dimbar.PostionCenterXY = [0,0];
    dimbar.width = 15;
    dimbar.height = 50;
end

function drawDimensionalityBar(dimbar)
    posX = dimbar.PostionCenterXY(1) - dimbar.width/2;
    posY = dimbar.PostionCenterXY(2) - dimbar.height/2;
    
    %get value histogram
    nBars = min(40,round(dimbar.maxVal));
    [bins,centers] = customHist(dimbar.values,1,dimbar.maxVal,nBars);
    binsNormed = bins/max(bins);
    binHeight = dimbar.height/nBars;
    
    for ii=1:numel(binsNormed)
         binFrq = binsNormed(ii);         
         binYStart = posY + (ii-1)*binHeight;
         lowColor = [0.8 0.8 0.8]; % white
         highColor = [0 0 0]; % black
         deltaCol = highColor-lowColor;
         colorVal = lowColor+binFrq*deltaCol;
         if binFrq < 0.0001
             colorVal = [1 1 1];
         end
         rectangle('Position',[posX, binYStart, dimbar.width, binHeight],'FaceColor',colorVal,'EdgeColor',colorVal);  
    end
    
    % surrounding rectangle
    rectangle('Position',[posX, posY, dimbar.width, dimbar.height]);   
    
end



function maxL = getMaxDisplayNameLength(componentList, minLength, countAll)
    maxL = minLength;
     for ii=1:numel(componentList)
        cName = componentList{ii}.displayName;
        if countAll || (componentList{ii}.frequencyRelative > 0)
            cLength = numel(cName);
            if cLength > maxL
                maxL = cLength;
            end
        end
    end   

end



% function nDims = getSubSetDimensionality(dataSet, featureSubset)
%     nDims = 0;
%     for iFeat = 1:numel(featureSubset)
%         cFeat = featureSubset{iFeat};
%         cFeatData = getfield(dataSet.instanceFeatures,cFeat);
%         nDims = nDims+size(cFeatData,2);
%     end
% end

        

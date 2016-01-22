% function configurationPlot_v2(evalItems,trainingInfo, plotOptions)
% plot configurations as graph to visualize
% the usage of components with overlaying all evaluation items.
% This is the more sophisticated version with feature ordering.
% Can be exported as vector graphics.
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015    
function configurationPlot_v2(evalItems,trainingInfo, plotOptions)

    h = figure('Position',[1 400 600 400],'Color', [1 1 1]);
    if ~plotOptions.showPlots
        set(h,'Visible','off');
    end 
    hold on;
    set(gca,'YDir','reverse');

    nConfigs = numel(evalItems);
        
    % prepare component names and displaynames
    featureNames = trainingInfo.job.jobParams.dynamicComponents.componentsFeatureSelection;
    componentsFeatures = {};
    for ii=1:numel(featureNames)
        feat = struct;
        feat.displayName = featureNames{ii};
        feat.name = featureNames{ii};
        componentsFeatures{end+1} = feat;
    end
    componentsFeatTransforms = trainingInfo.job.jobParams.dynamicComponents.componentsFeatureTransSelection;
    componentsClassifiers = trainingInfo.job.jobParams.dynamicComponents.componentsClassifierSelection;
    
    % calculate occurrences of components
    %--------------------------------------------------------------    
    componentsFeatures = frequencyCounterList(componentsFeatures);
    componentsFeatTransforms = frequencyCounterList(componentsFeatTransforms);
    componentsClassifiers = frequencyCounterList(componentsClassifiers);
    
    % count frequencies
    for iConfig = 1:nConfigs
        cEvalItem = evalItems{iConfig};
        % feature frequencies
        componentsFeatures = frequencyCounterIncrementCounter(componentsFeatures,...
            cEvalItem.resultData.configuration.configFeatureSelection.featureSubSet);
        componentsFeatTransforms = frequencyCounterIncrementCounter(componentsFeatTransforms,...
            cEvalItem.resultData.configuration.configFeatureTransform.featureTransformMethod);
        componentsClassifiers = frequencyCounterIncrementCounter(componentsClassifiers,...
            cEvalItem.resultData.configuration.configClassifier.classifierName);           
    end
    
    %order features by frequency
    [~,sortOrder] = sort(cellfun(@(v) v.frequencyCounter,componentsFeatures),'descend');
    componentsFeaturesDisplay = componentsFeatures(sortOrder);   
    
    [~,sortOrder] = sort(cellfun(@(v) v.frequencyCounter,componentsFeatTransforms),'descend');
    componentsFeatTransformsDisplay = componentsFeatTransforms(sortOrder);   
    
    [~,sortOrder] = sort(cellfun(@(v) v.frequencyCounter,componentsClassifiers),'descend');
    componentsClassifiersDisplay = componentsClassifiers(sortOrder);     
    
    % feature rest box active?
    restId = '______RESTFeature'; % note a feature name with leading _ can not be added to struct
    featureRestMapping = {};
    if numel(componentsFeaturesDisplay) > plotOptions.numberOfFeaturesDisplay
        featuresRestActive = 1;
        % put names of features that should be mapped to rest
        restFrequencyCounter = 0;
        restItems = 0;
        for iFeat = plotOptions.numberOfFeaturesDisplay+1:numel(componentsFeaturesDisplay)
            cItem = componentsFeaturesDisplay{iFeat};
            featureRestMapping{end+1} = cItem.name;
            restFrequencyCounter = restFrequencyCounter + cItem.frequencyCounter;
            restItems = restItems+1;
        end
        % cut display list
        componentsFeaturesDisplay = componentsFeaturesDisplay(1:plotOptions.numberOfFeaturesDisplay);
        % add rest item
        restItem = struct;
        restItem.name = restId;
        restItem.displayName = sprintf('Rest (%d features)',restItems);
        restItem.frequencyCounter = restFrequencyCounter;
        restItem.isRestItem = 1; % for display gap
        componentsFeaturesDisplay{end+1} = restItem;
    else
        featuresRestActive = 0;
    end
    
    % calculate relative frequency
    componentsFeaturesDisplay=frequencyCounterRelativeFrequencies(componentsFeaturesDisplay);
    componentsFeatTransformsDisplay=frequencyCounterRelativeFrequencies(componentsFeatTransformsDisplay);
    componentsClassifiersDisplay=frequencyCounterRelativeFrequencies(componentsClassifiersDisplay);
    
    % get connections for graph
    edgesFeatures2Transforms = GraphConnections;   % 
    edgesTransforms2Classifiers = GraphConnections;
    for iConfig = 1:nConfigs
        cEvalItem = evalItems{iConfig};
        featureSubSet = cEvalItem.resultData.configuration.configFeatureSelection.featureSubSet;
        featureTransformMethod = cEvalItem.resultData.configuration.configFeatureTransform.featureTransformMethod;
        classifierName = cEvalItem.resultData.configuration.configClassifier.classifierName;
        
        % add connection to every feature
        for iFeat = 1:numel(featureSubSet)
            cFeat = featureSubSet{iFeat};
            % map to rest
            if featuresRestActive
                if cellStringsContainString(featureRestMapping,cFeat)
                    featureMapped = restId;
                else
                    featureMapped = cFeat;
                end
            else
                % no rest mapping
                featureMapped = cFeat;
            end
            edgesFeatures2Transforms.updateConnection(featureMapped, featureTransformMethod, 1);
        end
        % add connection transforms to classifiers
        edgesTransforms2Classifiers.updateConnection(featureTransformMethod, classifierName, 1);
    end    
    % sort edges (for painting)
    edgesFeatures2Transforms.sortEdges();
    edgesTransforms2Classifiers.sortEdges();
    
    
    % general params
    %--------------------------------------------------------------    
    frequencyColorBoxHeight  = 4;
   
    %calculate positions and draw objects
    %--------------------------------------------------------------
    % features
    centerX = 0;
    centerY = 0;
    
    objectStyle = struct;
    objectStyle.additionalGap = 4; % for rest features
    objectStyle.textRotation = 90;
    objectStyle.fillColor = [1 1 1];
    objectStyle.positionMarkerTop = 0;
    objectStyle.positionMarkerBottom = 0;
    objectStyle.markerSize =12;
    objectStyle.markerColor = [0.7 0.7 0.7];            

    objectStyle.itemWidth = 7;
    objectStyle.itemHeight = 40;
    objectStyle.itemSpacing = 2;
    objectStyle.pointSpacingVertical = 0;
    
    objectStyle.frequencyColorBox = 1;
    objectStyle.frequencyColorBoxHeight = frequencyColorBoxHeight;
    objectStyle.frequencyColorBoxColorProfile = 'node_linear';
    
    [componentsFeaturesDisplay, objectBorderInfoFeatures] = fillListWithObjectProperties(componentsFeaturesDisplay, centerX, centerY, objectStyle);

    % caption
    delta = 5;
    text(objectBorderInfoFeatures.minX-delta,objectBorderInfoFeatures.centerY, 'Features' ,'HorizontalAlignment','right','fontSize',14,'fontWeight','bold');
    
    %--------------------------------------------------------------
    % feature transforms
    centerX = 0;
    centerY = 62;

    objectStyle = struct;
    objectStyle.textRotation = 0;
    objectStyle.fillColor = [1 1 1];
    objectStyle.positionMarkerTop = 0;
    objectStyle.positionMarkerBottom = 0; 
    objectStyle.markerSize =12;
    objectStyle.markerColor = [0.7 0.7 0.7];            
    
    objectStyle.itemWidth = 30;
    objectStyle.itemHeight = 7;
    objectStyle.itemSpacing = 2;
    objectStyle.pointSpacingVertical = 0;

    objectStyle.frequencyColorBox = 1;
    objectStyle.frequencyColorBoxHeight = frequencyColorBoxHeight;
    objectStyle.frequencyColorBoxColorProfile = 'node_linear';
    
    [componentsFeatTransformsDisplay, objectBorderInfoFeatTransforms] = fillListWithObjectProperties(componentsFeatTransformsDisplay, centerX, centerY, objectStyle);  
    
    % caption
    delta = 5;
    text(objectBorderInfoFeatTransforms.minX-delta,objectBorderInfoFeatTransforms.centerY, 'Feature Transforms' ,'HorizontalAlignment','right','fontSize',14,'fontWeight','bold');
    

    %--------------------------------------------------------------
    % classifiers
    centerX = 0;
    centerY = 90;
    
    objectStyle = struct;
    objectStyle.textRotation = 0;
    objectStyle.fillColor = [1 1 1];
    objectStyle.positionMarkerTop = 0;
    objectStyle.positionMarkerBottom = 0;
    objectStyle.markerSize =12;
    objectStyle.markerColor = [0.7 0.7 0.7];

    objectStyle.itemWidth = 30;
    objectStyle.itemHeight = 7;
    objectStyle.itemSpacing = 2;
    objectStyle.pointSpacingVertical = 0;
    
    objectStyle.frequencyColorBox = 1;
    objectStyle.frequencyColorBoxHeight = frequencyColorBoxHeight;
    objectStyle.frequencyColorBoxColorProfile = 'node_linear';
    
    [componentsClassifiersDisplay, objectBorderInfoClassifiers]= fillListWithObjectProperties(componentsClassifiersDisplay, centerX, centerY, objectStyle);            
    
    % caption
    delta = 5;
    text(objectBorderInfoClassifiers.minX-delta,objectBorderInfoClassifiers.centerY, 'Classifiers' ,'HorizontalAlignment','right','fontSize',14,'fontWeight','bold');

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
    

    %--------------------------------------------------------------            
    % draw component boxes
    drawObjectsAndPositionList(componentsFeaturesDisplay);
    drawObjectsAndPositionList(componentsFeatTransformsDisplay);
    drawObjectsAndPositionList(componentsClassifiersDisplay);         


    % last options
    set(findobj(gcf, 'type','axes'), 'Visible','off')
    set(gca,'YDir','reverse');
    daspect([1 1 1])
    %set(gcf, 'Renderer', 'zbuffer');

    if plotOptions.exportPlot
        if strcmp(plotOptions.exportPlotFormat,'png')
            set(h,'PaperPositionMode','auto');
            print(h,'-dpng','-r0',[plotOptions.exportFileName '.png']);    
        end
        if strcmp(plotOptions.exportPlotFormat,'pdf')
            %set(h,'PaperPositionMode','auto');
            print(h,'-dpdf','-r0',[plotOptions.exportFileName '.pdf']);      
        end        
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
        item.frequencyRelative = (item.frequencyCounter-minVal)/(maxVal-minVal);  
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
        lowColor = [0.9 0.9 0.9]; % gray
        highColor = [0 0 0]; % black
        deltaCol = highColor-lowColor;
        colorVal = lowColor+relativeVal*deltaCol;
    end
    % draw edges not entirely white
    if strcmp(colorProfile,'edge_linear')
        lowColor = [0.9 0.9 0.9]; % gray
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

        if objStyle.positionMarkerTop
            plot(objPos.pointCenterTopXY(1),objPos.pointCenterTopXY(2),'s','MarkerSize', objStyle.markerSize,'MarkerFaceColor',objStyle.markerColor,'MarkerEdgeColor',objStyle.markerColor);
        end
        
        if objStyle.positionMarkerBottom
            plot(objPos.pointCenterBottomXY(1),objPos.pointCenterBottomXY(2),'s','MarkerSize', objStyle.markerSize, 'MarkerFaceColor',objStyle.markerColor,'MarkerEdgeColor',objStyle.markerColor);
        end
        
        % rectangle top
        rectangle('Position',[objPos.topleftXY(1), objPos.topleftXY(2), objPos.width, objPos.height],'FaceColor',objStyle.fillColor);
        % frequency box
        if isfield(objPos,'frequencyBox')
            rectangle('Position',[objPos.frequencyBox.topleftXY(1), objPos.frequencyBox.topleftXY(2), objPos.frequencyBox.width, objPos.frequencyBox.height],...
                'FaceColor',objPos.frequencyBox.color);
        end
        if objStyle.textRotation ~= 0
        % text caption bottom for rotated
            delta= -1;
            text(objPos.centerXY(1), objPos.topleftXY(2)+objPos.height+delta, cItem.displayName,'HorizontalAlignment','left','Rotation',objStyle.textRotation);
        else
            % text caption center
            text(objPos.centerXY(1), objPos.centerXY(2), cItem.displayName,'HorizontalAlignment','center','Rotation',objStyle.textRotation);
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
    P1 = getObjectPoint(nameStart,componentListStart,'bottom');
    P2 = getObjectPoint(nameEnd,componentListEnd,'top');
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
        if strcmp(pointPos,'top')
            P=cComponent.objectPositionInfo.pointCenterTopXY;
        end
        if strcmp(pointPos,'bottom')
            P=cComponent.objectPositionInfo.pointCenterBottomXY;
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
% horizontal alignment of objects and other properties
function [itemList, objectBorderInfo]= fillListWithObjectProperties(itemList, centerX, centerY, objectStyle)
    objectBorderInfo = struct;
    nItems = numel(itemList);
    % calculate alignments
    totalWidth = nItems*objectStyle.itemWidth + (nItems-1)*objectStyle.itemSpacing;
    % top left
    xStartTL = centerX-totalWidth/2;
    addGap = 0; 
    
    for ii=1:nItems
        cItem = itemList{ii};
        if isfield(cItem,'isRestItem')
            addGap = addGap+objectStyle.additionalGap;
        end
        posInfo = struct;
        x = addGap + xStartTL+ (ii-1)*(objectStyle.itemWidth + objectStyle.itemSpacing);
        y = centerY;
        posInfo.topleftXY = [x,y];
        posInfo.centerXY = [x+objectStyle.itemWidth/2,y+objectStyle.itemHeight/2];
        posInfo.pointCenterTopXY = posInfo.centerXY - [0, objectStyle.itemHeight/2+objectStyle.pointSpacingVertical];
        posInfo.pointCenterBottomXY = posInfo.centerXY + [0, objectStyle.itemHeight/2+objectStyle.pointSpacingVertical];
        posInfo.width = objectStyle.itemWidth;
        posInfo.height = objectStyle.itemHeight;
        posInfo.totalHeight = posInfo.height;
        posInfo.totalWidth = posInfo.width;
        
        % a colored box with frequency indicators
        if objectStyle.frequencyColorBox
            frequencyBox = struct;
            frequencyBox.topleftXY = [x,y+posInfo.height];
            frequencyBox.width = posInfo.width;
            frequencyBox.height = objectStyle.frequencyColorBoxHeight;
            frequencyBox.color = frequencyColorMapping(cItem.frequencyRelative, objectStyle.frequencyColorBoxColorProfile);
            posInfo.frequencyBox = frequencyBox;
            % adapt bottom position
            posInfo.totalHeight = posInfo.totalHeight + frequencyBox.height;
            posInfo.pointCenterBottomXY = posInfo.pointCenterBottomXY + [0 frequencyBox.height];
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




        

        
% function configurationPlot_v1(evalItems,trainingInfo, plotOptions)
% plot configurations as graph to visualize
% the usage of components with overlaying all evaluation items with transparency.
% This is not nice when the graph shall be exported. 
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015    
function configurationPlot_v1(evalItems,trainingInfo, plotOptions)

    h = figure('Position',[1 400 600 400],'Color', [1 1 1]);
    if ~plotOptions.showPlots
        set(h,'Visible','off');
    end 
    hold on;
    set(gca,'YDir','reverse');

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

    %calculate positions and draw objects
    %--------------------------------------------------------------
    % features
    objectStyle = struct;
    objectStyle.textRotation = 90;
    objectStyle.fillColor = [1 1 1];
    objectStyle.positionMarkerTop = 0;
    objectStyle.positionMarkerBottom = 0;
    objectStyle.markerSize =12;
    objectStyle.markerColor = [0.7 0.7 0.7];            
    centerX = 0;
    centerY = 0;

    itemWidth = 7;
    itemHeight = 40;
    itemSpacing = 2;
    pointSpacingVertical = 0;
    componentsFeatures = fillListWithAlignmets(componentsFeatures, centerX, centerY, itemWidth, itemHeight, itemSpacing, pointSpacingVertical, objectStyle);

    %--------------------------------------------------------------
    % feature transforms
    objectStyle = struct;
    objectStyle.textRotation = 0;
    objectStyle.fillColor = [1 1 1];
    objectStyle.positionMarkerTop = 0;
    objectStyle.positionMarkerBottom = 0; 
    objectStyle.markerSize =12;
    objectStyle.markerColor = [0.7 0.7 0.7];            
    centerX = 0;
    centerY = 62;

    itemWidth = 30;
    itemHeight = 7;
    itemSpacing = 2;
    pointSpacingVertical = 0;
    componentsFeatTransforms = fillListWithAlignmets(componentsFeatTransforms, centerX, centerY, itemWidth, itemHeight, itemSpacing, pointSpacingVertical, objectStyle);            

    %--------------------------------------------------------------
    % classifiers

    objectStyle = struct;
    objectStyle.textRotation = 0;
    objectStyle.fillColor = [1 1 1];
    objectStyle.positionMarkerTop = 0;
    objectStyle.positionMarkerBottom = 0;
    objectStyle.markerSize =12;
    objectStyle.markerColor = [0.7 0.7 0.7];
    centerX = 0;
    centerY = 90;

    itemWidth = 30;
    itemHeight = 7;
    itemSpacing = 2;
    pointSpacingVertical = 0;
    componentsClassifiers = fillListWithAlignmets(componentsClassifiers, centerX, centerY, itemWidth, itemHeight, itemSpacing, pointSpacingVertical, objectStyle);            



    %--------------------------------------------------------------
    % configuration lines            
    % dynamic transparency
    nConfigs = numel(evalItems);


    configurationOptions = struct;
    configurationOptions.lineWidth = 4;
    configurationOptions.transparency1 = max(0.01,exp(-0.3*nConfigs));
    configurationOptions.transparency2 = max(0.01,exp(-0.6*nConfigs));
    for ii=1:numel(evalItems)
        cEvalItem = evalItems{ii};
        drawConfiguration(cEvalItem,componentsFeatures,componentsFeatTransforms,componentsClassifiers,configurationOptions);
    end


    %--------------------------------------------------------------            
    % draw component boxes
    drawObjectsAndPositionList(componentsFeatures);
    drawObjectsAndPositionList(componentsFeatTransforms);
    drawObjectsAndPositionList(componentsClassifiers);         


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
% draw the item lists with postions and style
function drawObjectsAndPositionList(itemList)
    for ii=1:numel(itemList)
        cItem = itemList{ii};
        objStyle = cItem.objectInfo.objectStyle;
        objPos = cItem.objectInfo;

        if objStyle.positionMarkerTop
            plot(objPos.pointCenterTopXY(1),objPos.pointCenterTopXY(2),'s','MarkerSize', objStyle.markerSize,'MarkerFaceColor',objStyle.markerColor,'MarkerEdgeColor',objStyle.markerColor);
        end
        
        if objStyle.positionMarkerBottom
            plot(objPos.pointCenterBottomXY(1),objPos.pointCenterBottomXY(2),'s','MarkerSize', objStyle.markerSize, 'MarkerFaceColor',objStyle.markerColor,'MarkerEdgeColor',objStyle.markerColor);
        end
        
        % rectangle
        rectangle('Position',[objPos.topleftXY(1), objPos.topleftXY(2), objPos.width, objPos.height],'FaceColor',objStyle.fillColor);
        % text caption
        text(objPos.centerXY(1), objPos.centerXY(2), cItem.displayName,'HorizontalAlignment','center','Rotation',objStyle.textRotation);
    end
end

%__________________________________________________________________
% draw configuration
function drawConfiguration(evalItem,componentsFeatures,componentsFeatTransforms,componentsClassifiers,configurationOptions)

    config = evalItem.resultData.configuration;
    featureSet = config.configFeatureSelection.featureSubSet;
    featTransMethod = config.configFeatureTransform.featureTransformMethod;
    classifier = config.configClassifier.classifierName;
    % draw features
    lineColor = [0 0 0];
    for iFeat = 1:numel(featureSet)
        cFeat = featureSet{iFeat};
        configurationOptions.transparency = configurationOptions.transparency1; 
        drawConnection(componentsFeatures,cFeat,componentsFeatTransforms,featTransMethod,lineColor,configurationOptions);
    end
    configurationOptions.transparency = configurationOptions.transparency2; 
    drawConnection(componentsFeatTransforms,featTransMethod,componentsClassifiers,classifier,lineColor,configurationOptions);
end


%__________________________________________________________________
% draw connection line
function drawConnection(componentListStart, nameStart, componentListEnd, nameEnd, lineColor,plotOptions)
    P1 = getObjectPoint(nameStart,componentListStart,'bottom');
    P2 = getObjectPoint(nameEnd,componentListEnd,'top');
    drawLineVertical(P1,P2,lineColor,plotOptions)
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
            P=cComponent.objectInfo.pointCenterTopXY;
        end
        if strcmp(pointPos,'bottom')
            P=cComponent.objectInfo.pointCenterBottomXY;
        end    
    end
end



%__________________________________________________________________
% draw single line element with plot options
function drawLineVertical(P1,P2,lineColor,plotOptions)
    xCoords = [P1(1),  P2(1)];
    yCoords = [P1(2),  P2(2)];
    % plot transparent lines as patches
    patch(xCoords, yCoords, 'r','EdgeAlpha',plotOptions.transparency,'FaceAlpha', 0.0, 'FaceColor', [0 0 0],'LineWidth',plotOptions.lineWidth);
    %plot(xCoords, yCoords, 'Color', lineColor,'LineWidth',plotOptions.lineWidth);
end

%__________________________________________________________________
% horizontal alignment of objects
function itemList = fillListWithAlignmets(itemList, centerX, centerY, itemWidth, itemHeight, itemSpacing, pointSpacingVertial, objectStyle)
    nItems = numel(itemList);
    positions = getCenteredHorizontalAlignments(centerX, centerY, nItems, itemWidth, itemHeight, itemSpacing, pointSpacingVertial);
    
    for ii=1:nItems
        itemList{ii}.objectInfo = positions{ii};
        itemList{ii}.objectInfo.objectStyle = objectStyle;
    end

end 


%__________________________________________________________________
% horizontal alignment
% center will be centerX, centerY
function positions = getCenteredHorizontalAlignments(centerX, centerY, nItems, itemWidth, itemHeight, itemSpacing, pointSpacingVertial)
    positions = {};
    
    totalWidth = nItems*itemWidth + (nItems-1)*itemSpacing;
    
    % top left
    xStartTL = centerX-totalWidth/2;

    for ii=1:nItems
        cPos = struct;
        x = xStartTL+ (ii-1)*(itemWidth + itemSpacing);
        y = centerY;
        cPos.topleftXY = [x,y];
        cPos.centerXY = [x+itemWidth/2,y+itemHeight/2];
        cPos.pointCenterTopXY = cPos.centerXY - [0, itemHeight/2+pointSpacingVertial];
        cPos.pointCenterBottomXY = cPos.centerXY + [0, itemHeight/2+pointSpacingVertial];
        cPos.width = itemWidth;
        cPos.height = itemHeight;
        
        positions{end+1} = cPos;
    end
    

end 



        

        
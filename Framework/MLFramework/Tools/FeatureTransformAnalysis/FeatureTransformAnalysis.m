% Class definition FeatureTransformAnalysis
% 
% This class is allows a graphical analysis of feature transforms in 1D,2D
% and 3D
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef FeatureTransformAnalysis < handle
    
    properties 
        dataSetTrain;
        dataSetTest;
    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = FeatureTransformAnalysis()

        end
        
            
        %__________________________________________________________________
        % init with data sets to start analysis of feature transforms
        % dataSetTrain
        % dataSetTest is optional and can be left []
        function initWithDataSet(this,dataSetTrain,dataSetTest)
            this.dataSetTrain = dataSetTrain;
            this.dataSetTest = dataSetTest;
        end
        
        
        %__________________________________________________________________
        % show training dataset with options with multiple transforms
        % options.transformations - cell string reference for transformation
        % options.nDim - number dimensions
        function visualizeDataSetMultipleTransforms(this, dataSet, options)
            this.getDataSetInfo(dataSet);
 
            for iTrans = 1:numel(options.transformations)
                try
                    cTransform = options.transformations{iTrans};
                    fprintf('- Transform %d/%d %s \n',iTrans,numel(options.transformations), cTransform);
                    options.transformationName = cTransform;
                    % calculate transform
                    transformedFeatures = this.calcTransformation(dataSet, options);
                    % plot transform
                    this.plotTransform(transformedFeatures, dataSet, options);
                catch 
                   fprintf(' transform FAILED\n') 
                end
            end
            
        end       
                
        
        %__________________________________________________________________
        % show training dataset with options
        % options.transformationName - string reference for transformation
        % options.nDim - number dimensions
        function nDimOriginal = getDataSetInfo(this, dataSet)
            nDimOriginal = 0;
            featureNames = fieldnames(dataSet.instanceFeatures);
            for ii=1:numel(featureNames)
                cName = featureNames{ii};
                cData = getfield(dataSet.instanceFeatures,cName);
                nDimOriginal = nDimOriginal + size(cData,2);
            end
            fprintf('dataSet %s  nDimOriginal = %d  nSamples = %d \n',dataSet.dataSetName, nDimOriginal, numel(dataSet.targetClasses));           
        end       
                
        
        
        %__________________________________________________________________
        % calculate feature transform from DataSet using options struct
        % with
        % transformationName and nDim dimensions
        function [transformedFeatures] =  calcTransformation(this, dataSet, options)
                     
            transformationName = options.transformationName;
            nDim = options.nDim;
            
            fprintf('Calculating transform %s with %d dim... \n', transformationName, nDim);
             tic
            % generate pipeline
            generalParams = struct;
            cPipeline = ClassificationPipeline();
            cPipeline.initParams(generalParams);
            
            % make configuration
            jobParams = struct;
            jobParams.featurePreProcessingMethod = 'scaling_zero_one';            
            pipelineConfig = ClassificationPipeline.getEmptyPipelineConfiguration(jobParams);
            
%            pipelineConfig.configPreprocessing.featurePreProcessingMethod = 'scaling_zero_one';
            pipelineConfig.configFeatureSelection.featureSubSet = logical(ones(1,numel(fieldnames(dataSet.instanceFeatures)))); % use all for the moment
            pipelineConfig.configFeatureTransform.featureTransformMethod = transformationName;
            pipelineConfig.configFeatureTransform.featureTransformParams.nDimensions = nDim;
                        

            % ==============> stage 1) Feature Subset selection
            data0 = struct;
            data0.dataSet = dataSet;
            data0.config = pipelineConfig;            
            featureSelectionElem = cPipeline.getPipelineElementByIndex(1); % get first element in pipeline
            data1 = featureSelectionElem.prepareElement(data0);            
            
            % ==============> stage 2) Feature PreProcessing
            data1.config = pipelineConfig;            
            preProcessingElem = cPipeline.getPipelineElementByIndex(2); % get second element in pipeline
            data2= preProcessingElem.prepareElement(data1);           

            % ==============> stage 3) Feature Transform
            data2.config = pipelineConfig;  
            featureTransformElem = cPipeline.getPipelineElementByIndex(3); % get third element
            % train manifold/dimension reduction and make feature matrix
            data3=featureTransformElem.prepareElement(data2);       
            
            timePassed = toc;
            fprintf('Done took %0.2f seconds \n', timePassed)
            
            transformedFeatures = data3.dataSet.featureMatrix;
            
        end        
        
        
        
        %__________________________________________________________________
        % plot dimension transform
        function plotTransform(this, transformedFeatures, dataSet, options)
        %(featureMatrix, targetClasses, numberDimensions, classNames)
           
            classNames = dataSet.classNames;
            numberDimensions = options.nDim;
            transformationName = options.transformationName;
            
            % check dimensionality
            numberDimensions = max(1,min(4,numberDimensions));
            numberDimensions = min(numberDimensions,size(transformedFeatures,2));

            displayMatrix = transformedFeatures(:,1:numberDimensions);

            uniqueClasses = unique(dataSet.targetClasses);
            uniqueClasses = sort(uniqueClasses);

            h=figure();
            set(gcf, 'renderer', 'painters');
            if ~options.showPlots
               set(h,'Visible','off');
            end
           % set(h,'Position', [10 800 400 300]);
            set(h,'Position', [10 800 800 600]);
             
            
            hold on;
            legendEntries = {};
            for iClass = 1:numel(uniqueClasses)
                cClassInd = uniqueClasses(iClass);
                cRowIndices = find(dataSet.targetClasses == cClassInd);
                cData = displayMatrix(cRowIndices,:);
                [plotSymbol, plotColor] = getClassPlotStyle(cClassInd);

                if numberDimensions == 1
                    plot(cData(:,1),0*cData(:,1),plotSymbol,'MarkerEdgeColor',plotColor,'MarkerFaceColor',plotColor,'MarkerSize',5);
                elseif numberDimensions == 2
                    plot(cData(:,1),cData(:,2),plotSymbol,'MarkerEdgeColor',plotColor,'MarkerFaceColor',plotColor,'MarkerSize',5);
                elseif numberDimensions == 3
                    plot3(cData(:,1),cData(:,2),cData(:,3),plotSymbol,'MarkerEdgeColor',plotColor,'MarkerFaceColor',plotColor,'MarkerSize',5);
                else
                    minDim = min(cData(:,4));
                    maxDim = max(cData(:,4));
                    
                    color1 = 0.7*[40 122 193]/255;
                    color2 = [205 231 255]/255;
                    
                    for jj=1:size(cData,1)
                        valueShow = (cData(jj,4)-minDim)/(maxDim-minDim);
                        hueVal = max(0,min(1,valueShow));
                        plotcolor4ThsDim = hsv2rgb([hueVal 1 0.8]);
                        %plotcolor4ThsDim = color1*(1-valueShow) + valueShow*color2;
                        plot3(cData(jj,1),cData(jj,2),cData(jj,3),plotSymbol,'MarkerEdgeColor',plotcolor4ThsDim,'MarkerFaceColor',plotcolor4ThsDim,'MarkerSize',5);
                    end
                    
                end
                legendEntries{end+1} = classNames{cClassInd};
            end
            if numberDimensions < 4
            legend(legendEntries);
            end
            if numberDimensions >= 3
                view([-45 19])
            end
            if numberDimensions >= 1
                xlabel('x_1');
            end 
            if numberDimensions >= 2
                ylabel('x_2');
            end            
            if numberDimensions >= 3
                zlabel('x_3');
            end                        
            grid minor;

                
            titleString = sprintf('%s - %s',dataSet.dataSetName,transformationName);
            hTitle=title(titleString);
            set(hTitle,'interpreter','none');
            
            exportName = sprintf('%s%s_%s',options.exportPath ,dataSet.dataSetName, transformationName);
            
            if options.exportPlot
                set(h,'PaperPositionMode','auto');
                if strcmp(options.exportFormat,'png')
                    print(h,'-dpng','-r0',[exportName '.png']);    
                end
                if 1 || strcmp(options.exportFormat,'pdf')
                    print(h,'-dpdf','-r0',[exportName '.pdf']);    
                end  
                % export as figure (for later calling and changing size or such)
                saveas(h,[exportName '.fig'],'fig')
            end            
            
            if ~options.showPlots
                close(h);
            end
            
        end        
                
        
        
        
        
        
    end  
        

end

        



% ----- helper -------


% get unique plot style for class index
function [plotSymbol, plotColor] = getClassPlotStyle(classIndex)
   
    color1 = [40 122 193]/255;
    %color2 = [205 231 255]/255;
   color2 = [189 44 0]/255;

    switch classIndex
        
        case 1
           plotColor = color1;    
           plotSymbol = '^';
        case 2
           plotColor = color2;    
           plotSymbol = '*';
        case 3
           plotColor = color1;    
           plotSymbol = 'x';
        case 4
           plotColor = color2;    
           plotSymbol = 'v';
        case 5
           plotColor = color1;    
           plotSymbol = 'o';
        case 6
           plotColor = color2;    
           plotSymbol = '<';
        case 7
           plotColor = color1;    
           plotSymbol = '>';
        case 8
           plotColor = color2;    
           plotSymbol = 'o';           
        case 9
           plotColor = color1;    
           plotSymbol = '*';    
        case 10
           plotColor = color2;    
           plotSymbol = '^';               
        otherwise
           plotColor = [1 0 0];    
           plotSymbol = '*';
           warning('class label exceeds number of symbols.')
    end

end


% get unique plot style for class index
function [plotSymbol, plotColor] = getClassPlotStyle_Gray(classIndex)
   
    color1 = [0 0 0];
    color2 = [0.65 0.65 0.65];

    switch classIndex
        
        case 1
           plotColor = color1;    
           plotSymbol = 'o';
        case 2
           plotColor = color2;    
           plotSymbol = '*';
        case 3
           plotColor = color1;    
           plotSymbol = 'x';
        case 4
           plotColor = color2;    
           plotSymbol = 'v';
        case 5
           plotColor = color1;    
           plotSymbol = '^';
        case 6
           plotColor = color2;    
           plotSymbol = '<';
        case 7
           plotColor = color1;    
           plotSymbol = '>';
        case 8
           plotColor = color2;    
           plotSymbol = 'o';           
        case 9
           plotColor = color1;    
           plotSymbol = '*';    
        case 10
           plotColor = color2;    
           plotSymbol = '^';               
        otherwise
           plotColor = [1 0 0];    
           plotSymbol = '*';
           warning('class label exceeds number of symbols.')
    end

end


        
% get unique plot style for class index
function [plotSymbol, plotColor] = getClassPlotStyle2(classIndex)
    symbolIndices = 5;
    colorIndex = floor((classIndex-1)/symbolIndices);
    symbolIndex = mod((classIndex-1),symbolIndices);
    
     if colorIndex ==  0
        plotColor = [0 0 0];
     else
        plotColor = [0.65 0.65 0.65];
     end


    if symbolIndex == 0
        plotSymbol = 'o';
    elseif symbolIndex == 1
        plotSymbol = '*';
    elseif symbolIndex == 2
        plotSymbol = '^';
    elseif symbolIndex == 3
         plotSymbol='x';
    else
         plotSymbol = 'v';
    end
end


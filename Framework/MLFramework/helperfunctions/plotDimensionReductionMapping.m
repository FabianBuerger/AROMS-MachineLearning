
% function plotDimensionReductionMapping(featureMatrix, instaceLabels, numberDimensions, classNames)
%
% plot the first dimensions of the data. In dimension reduction the first
% components represent the most significant values of the dataset.
%
% -featureMatrix: n obersavtions x m features feature matrix
% -instaceLabels: instance feature correspondance (n x 1) matrix
% -numberDimensions: plot number of dimensions (1, 2 or 3 typically)
% -classNames: class names cell array (indices like instance lables)
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015
function plotDimensionReductionMapping(featureMatrix, targetClasses, numberDimensions, classNames)
    
    % check dimensionality
    numberDimensions = max(1,min(3,numberDimensions));
    numberDimensions = min(numberDimensions,size(featureMatrix,2));
    
    displayMatrix = featureMatrix(:,1:numberDimensions);
    
    uniqueClasses = unique(targetClasses);
    uniqueClasses = sort(uniqueClasses);
    
    figure();    
    hold on;
    legendEntries = {};
    for iClass = 1:numel(uniqueClasses)
        cClassInd = uniqueClasses(iClass);
        cRowIndices = find(targetClasses == cClassInd);
        cData = displayMatrix(cRowIndices,:);
        [plotSymbol, plotColor] = getClassPlotStyle(cClassInd);
        
        if numberDimensions == 1
            plot(cData(:,1),0*cData(:,1),plotSymbol,'MarkerEdgeColor',plotColor);
        elseif numberDimensions == 2
            plot(cData(:,1),cData(:,2),plotSymbol,'MarkerEdgeColor',plotColor);
        else
            plot3(cData(:,1),cData(:,2),cData(:,3),plotSymbol,'MarkerEdgeColor',plotColor);
        end  
        legendEntries{end+1} = classNames{cClassInd};
    end
    legend(legendEntries);
    if numberDimensions == 3
        view([-20 45])
    end

end




% get unique plot style for class index
function [plotSymbol, plotColor] = getClassPlotStyle(classIndex)
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

% 
% % get unique plot style for class index
% function [plotSymbol, plotColor] = getClassPlotStyle(classIndex)
%     classSymbols = 4;
%     indexMod = mod(classIndex-1,classSymbols);
%     indexDiv = floor((classIndex-1)/classSymbols);
%     
%      switch indexMod
%      case 0
%         plotSymbol='*';
%      case 1
%         plotSymbol='o';
%      case 2
%         plotSymbol='+';
%      case 3
%         plotSymbol='x';
%      end
% %      case 4
% %         plotSymbol='s';
% %      case 5
% %         plotSymbol='d';
% %      case 6 
% %         plotSymbol='^';
% %      case 7   
% %         plotSymbol='v';
% %      end
%     
%     plotColor = [0 0 0];
%     if indexDiv == 0
%         plotColor = [0 0 0];
%     elseif indexDiv == 1
%         plotColor = [0.6 0.6 0.6];
%     elseif indexDiv == 2
%         plotColor = [0.35 0.35 0.35];
%     elseif indexDiv == 3
%          plotColor = [1 0 0];
%     elseif indexDiv == 4
%          plotColor = [0 1 0];
%     else
%          plotColor = [0 0 1];
%     end
% end
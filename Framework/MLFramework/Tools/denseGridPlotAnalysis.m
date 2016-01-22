% function denseGridPlotAnalysis(resultFolder)
%  analyze grid search with dense parameter grids
%  
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015


function denseGridPlotAnalysis(resultFolder)

close all;


resultFile = [resultFolder filesep 'resultList.mat'];
load(resultFile);
classifierInfo = resultStruct.classifierInfo;
resultList = resultStruct.resultList;


rangeSizes = [];
for ii=1:numel(classifierInfo.parameterRanges)
    n = numel(classifierInfo.parameterRanges{ii}.values);
    rangeSizes = [rangeSizes n];
end

nRangeDim = numel(classifierInfo.parameterRanges);
if nRangeDim ~= 2
    error('2 parameters needed!')
end    
    
gridCoordList = {};
for iP=1:numel(resultList)
    [gridCoords{1:nRangeDim}] = ind2sub(rangeSizes,iP);
    gridCoordList{end+1} = gridCoords;
end


% make value grid
p1RangeNum = makeNumGrid(classifierInfo.parameterRanges{1});
p2RangeNum = makeNumGrid(classifierInfo.parameterRanges{2});


[p1mesh, p2mesh] = meshgrid(p1RangeNum,p2RangeNum);
qualityMatrix = zeros(size(p1mesh));

for iP=1:numel(resultList)
    cRes = resultList{iP};
    [gridCoords{1:nRangeDim}] = ind2sub(rangeSizes,iP);
    qualityMatrix(gridCoords{2},gridCoords{1}) = cRes.qualityMetric;
end



% make plot     
h=figure();
set(h,'Position', [10 420 420 320]);

surf(p1RangeNum,p2RangeNum,qualityMatrix);

% check axes for string names
pRange = classifierInfo.parameterRanges{1}.values;
if iscell(pRange)
    set(gca,'XTick',[1:numel(pRange)])
    set(gca,'XTickLabel',pRange)
end
pRange = classifierInfo.parameterRanges{2}.values;
if iscell(pRange)
    set(gca,'YTick',[1:numel(pRange)])
    set(gca,'YTickLabel',pRange)
end

pName = classifierInfo.parameterRanges{1}.name;
if strcmp(classifierInfo.parameterRanges{1}.paramType,'realLog10')
    pName = ['log(' pName ')'];
end
xlabel(pName);

pName = classifierInfo.parameterRanges{2}.name;
if strcmp(classifierInfo.parameterRanges{2}.paramType,'realLog10')
    pName = ['log(' pName ')'];
end
ylabel(pName);

zlabel('accuracy');
% 
% maxVal = max(qualityMatrix(:));
% indexWithMax = qualityMatrix >= maxVal;


view([-143 44]);


% export ----
addName = queryStruct(resultStruct.job.jobParams,'jobDescription','');
exportFileName = [resultFolder 'gridPlot' addName];

set(h,'PaperPositionMode','auto');

print(h,'-dpdf','-r0',[exportFileName  '.pdf']);    
saveas(h,[exportFileName '.fig'],'fig')
close all;



function numRange = makeNumGrid(parameterRangeInfo)
if iscell(parameterRangeInfo.values)
    numRange = 1:numel(parameterRangeInfo.values);
else
    numRange = parameterRangeInfo.values;
    if strcmp(parameterRangeInfo.paramType,'realLog10')
        numRange = log10(numRange);
    end
end



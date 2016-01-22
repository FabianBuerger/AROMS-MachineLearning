%  function multiPipelineEvaluationTextBased(dataAggregated,dataSetTest,params)
%
% Text based analyses of multi pipeline systems
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015


function multiPipelineEvaluationTextBased(dataAggregated,dataSetTest,params)

% ------------------------
% write out csv based table of detail evaluations per pipeline fusion

    stringHeader = '';
    sep = ','; % columns
    stringHeader = ['nPipelines' sep 'accuracyOverall'];
    
    % add class wise stats
    for iClass = 1:numel(dataSetTest.classNames)
        cClass = dataSetTest.classNames{iClass};
        stringHeader = [stringHeader sep '-' sep 'class ' cClass ' recall' sep 'class ' cClass ' precision' sep 'class ' cClass ' f1'];
    end

    tableStrings = {};
    tableStrings{end+1} = stringHeader;
    
    for iPipelines = 1:numel(dataAggregated.fusionTopMajority.evaluationListDetails)
        cRes = dataAggregated.fusionTopMajority.evaluationListDetails{iPipelines};
        
        cLine = sprintf('%d%s%0.4f',iPipelines,sep,cRes.accuracyOverall);
        % append class wise stats
        for iClass=1:numel(cRes.statsClassWise)
            cClassStats = cRes.statsClassWise{iClass};
            classStr = sprintf('%0.4f%s%0.4f%s%0.4f',cClassStats.recall,sep,cClassStats.precision,sep,cClassStats.f1);
            cLine = [cLine sep '-' sep classStr];
        end
        tableStrings{end+1} = cLine;
    end
   
% save to file
exportFileName = [params.resultPath 'multiPipelineDetailEvals.csv'];
saveMultilineString2File(tableStrings,exportFileName);

 
        
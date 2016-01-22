
% export top configuations as latex table 
function topConfigsLatex(evalItems,tableOptions)    
    % manual parameters
    nConfigs = 3;
    qualityFactor = 1;
    limitStringFeatures = 100;
    transposeTab = 1;

	nConfigs=min(nConfigs,numel(evalItems));
	latexTable = cell(nConfigs+1,6);
		% fill configtexts
		latexTable{1,1} = 'Rank';
		latexTable{1,2} = 'Quality';
		latexTable{1,3} = 'Feature subset';
		latexTable{1,4} = 'Feature preprocessing';
		latexTable{1,5} = 'Feature transform';
		latexTable{1,6} = 'Classifier';          
        
        fullFeatureSetInfo = struct;
        fullFeatureSetInfo.showFull = 1;
        fullFeatureSetInfo.fullFeatureSet = tableOptions.job.jobParams.dynamicComponents.componentsFeatureSelection;

        % list configuration
        nConfigs=min(nConfigs,numel(evalItems));
        for iRank = 1:nConfigs     
            cEvalItem = evalItems{iRank};
            latexTable{iRank+1,1} = sprintf('%d', iRank);
            latexTable{iRank+1,2} = sprintf('%0.4f', qualityFactor*cEvalItem.qualityMetric);
           
            configStr = StatisticsTextBased.getConfigurationAsString(cEvalItem.resultData.configuration, 'tex', {'configFeatureSelection'},fullFeatureSetInfo);
            nChars = min(limitStringFeatures,numel(configStr));
            latexTable{iRank+1,3} = [strrep(configStr(1:nChars),'_','-') ' ...'];
            
            configStr = StatisticsTextBased.getConfigurationAsString(cEvalItem.resultData.configuration, 'tex', {'configPreprocessing'},fullFeatureSetInfo);
            latexTable{iRank+1,4} = configStr;
            
            configStr = StatisticsTextBased.getConfigurationAsString(cEvalItem.resultData.configuration, 'tex', {'configFeatureTransform'},fullFeatureSetInfo);
            latexTable{iRank+1,5} = configStr;  
            
            configStr = StatisticsTextBased.getConfigurationAsString(cEvalItem.resultData.configuration, 'tex', {'configClassifier'},fullFeatureSetInfo);
            latexTable{iRank+1,6} = configStr;             
        end
             
        if transposeTab
            latexTable = latexTable';
        end
        
        mStats = MultiJobStatistics();
        statParams = struct;
        statParams.exportMode='latex';
        statParams.latexUseBookTabs = 1;
        tableLines = mStats.getTableStringLines(latexTable, statParams);
        
        saveMultilineString2File(tableLines, tableOptions.exportFileName);
        
  
end
           


        

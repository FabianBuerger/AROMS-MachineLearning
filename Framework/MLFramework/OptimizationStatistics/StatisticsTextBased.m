% Class definition StatisticsTextBased
%
% This class handles text based statistics
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef StatisticsTextBased < handle
    
    properties 
     
    end
    
    %====================================================================
    methods
  
    end % end methods public ____________________________________________
   
     methods(Static = true)


         
         
        %__________________________________________________________________
        % export evaluation results as string table and store to file
        % evalItems: result list
        % tableOptions: struct with options
        function exportResultTable(evalItems,tableOptions)
                        additionalInfo = struct;
                        
            additionalInfo.classNames = tableOptions.classNames;
            additionalInfo.job = tableOptions.job;
            % internal parameters
            outputType = 'csv';
            profile = 'resulttable1'; % this is the table with columns:
            % rank, configuration, overall accuracy, classwise stats
            
            % to do ranks
            resultStringList = {};
            tableHeader = StatisticsTextBased.getResultHeader(profile,outputType,additionalInfo);
            resultStringList{end+1} = tableHeader;
            % list configuration
            nConfigs=min(tableOptions.nItemLimit,numel(evalItems));
            for iRank = 1:nConfigs
                cEvalItem = evalItems{iRank};
                cEvalItem.rank = iRank;
                fullFeatureSetInfo = struct;
                fullFeatureSetInfo.showFull = iRank <= 50; % full set just for the first 50 entries
                fullFeatureSetInfo.fullFeatureSet = tableOptions.job.jobParams.dynamicComponents.componentsFeatureSelection;
                tableRow = StatisticsTextBased.getConfigurationEvaluationAsString(cEvalItem,profile,outputType,fullFeatureSetInfo);
                resultStringList{end+1} = tableRow;
            end
            % save string
            saveMultilineString2File(resultStringList,tableOptions.exportFileName );
        end         
         

         
         
        %__________________________________________________________________
        % get string representation of the pipeline configuration for
        % consoles (debug/status)
        function stringRep = getConfigurationStringForConsole(configuration)
            pipelineElements = {'configFeatureSelection', 'configPreprocessing', ...
            'configFeatureTransform', 'configClassifier'};
            fullFeatureSetInfo = struct;
            fullFeatureSetInfo.showFull=0;
            stringRep = StatisticsTextBased.getConfigurationAsString(configuration,...
                'csv', pipelineElements,fullFeatureSetInfo);
        end
        
        
        %__________________________________________________________________
        % get string representation for header to display the table with
        % optimization results
        % profile defines several profiles for this header, e.g.
        % - 'resulttable1', 'resulttable2'
        % additionalInfo is struct with e.g. class names
        function stringRep = getResultHeader(profile,outputType, additionalInfo)
            stringRep = '';
            if strcmp(outputType,'csv')
                sep = ','; % separate pipeline elements
            end
            if strcmp(outputType,'tex')
                sep = ' & '; % separate pipeline elements
            end   
            if strcmp(profile,'resulttable1') || strcmp(profile,'resulttable2')
                qualitymetricName =additionalInfo.job.jobParams.evaluationQualityMetric;
                stringRep = ['rank' sep 'feature subset' sep 'preprocessing' sep 'feature transform' sep 'classifier' sep 'quality (' qualitymetricName ')' sep 'mean accuracy' sep 'std accuracy'];
            end  
            if strcmp(profile,'resulttable1')
                for iClass = 1:numel(additionalInfo.classNames)
                    cClass = additionalInfo.classNames{iClass};
                    stringRep = [stringRep sep '-' sep 'class ' cClass ' recall' sep 'class ' cClass ' precision' sep 'class ' cClass ' f1'];
                end
            end
            if strcmp(outputType,'tex')
                % append tex table end
                stringRep = [stringRep ' \\'];
            end                   
        end

        
        %__________________________________________________________________
        % get string representation for a line in the table of
        % optimization results
        % profile defines several profiles for this header, e.g.
        % - 'resulttable1', 'resulttable2'
        function stringRep = getConfigurationEvaluationAsString(evaluationItem,profile,outputType,fullFeatureSetInfo)
            stringRep = '';
            try
                errOccur = evaluationItem.resultData.evaluationMetrics.errorOccurred;
                if strcmp(outputType,'csv')
                    sep = ','; % separate pipeline elements
                end
                if strcmp(outputType,'tex')
                    sep = ' & '; % separate pipeline elements
                end   
                if isfield(evaluationItem,'rank')
                    rankStr = num2str(evaluationItem.rank);
                else
                    rankStr = '';
                end
                if strcmp(profile,'resulttable1') || strcmp(profile,'resulttable2')
                    pipelineElements = {'configFeatureSelection', 'configPreprocessing', ...
                'configFeatureTransform', 'configClassifier'};
                    configStr = StatisticsTextBased.getConfigurationAsString(evaluationItem.resultData.configuration, outputType, pipelineElements,fullFeatureSetInfo);
                    if ~errOccur
                        qualityMetric = evaluationItem.qualityMetric;
                        overallAccurarcyMean = evaluationItem.resultData.evaluationMetrics.accuracyOverallMean;
                        overallAccurarcyStd = evaluationItem.resultData.evaluationMetrics.accuracyOverallStd;
                        %overallCorrectClassRate = evaluationItem.resultData.evaluationMetrics.nCorrectRelativeMean;
                    else
                        qualityMetric = 0;
                        overallAccurarcyMean = 0;
                        overallAccurarcyStd = 0;         
                        %overallCorrectClassRate = 0;
                    end
                    stringRep =  sprintf('%s%s%s%s%0.4f%s%0.4f%s%0.4f',rankStr,sep,configStr,sep,qualityMetric,sep,overallAccurarcyMean,sep,overallAccurarcyStd);
                end
                if strcmp(profile,'resulttable1')
                    if ~errOccur
                        % append class wise stats
                        for iClass=1:numel(evaluationItem.resultData.evaluationMetrics.classWiseStats)
                            cClassStats = evaluationItem.resultData.evaluationMetrics.classWiseStats{iClass};
                            classStr = sprintf('%0.4f%s%0.4f%s%0.4f',cClassStats.recallMean,sep,cClassStats.precisionMean,sep,cClassStats.f1Mean);
                            stringRep = [stringRep sep '-' sep classStr];
                        end
                    else
                        % else case -> valid table?
                    end
                end 
                if strcmp(outputType,'tex')
                    % append tex table end
                    stringRep = [stringRep ' \\'];
                end 
            catch exception
                fprintf('!!! Error while exporting statistics: %s',exception.message);
            end
        end        
        
        
  
        %__________________________________________________________________
        % get string representation of the pipeline configuration
        % - configuration is the pipeline configuration struct
        % - formatStyle is either 'csv' or 'tex' style
        % - pipelineElements is a cell array of pipeline element names
        % which are 'configPreprocessing', 'configFeatureSelection',
        % 'configFeatureTransform' or 'configClassifier'
        function stringRep = getConfigurationAsString(configuration, outputType, pipelineElements, fullFeatureSetInfo)
            stringRep = '';
            fieldSeparator1 = ',';
            if strcmp(outputType,'csv')
                fieldSeparator1 = ','; % separate pipeline elements
                fieldSeparator2 = '; '; % separate inside of lists
            end
            if strcmp(outputType,'tex')
                fieldSeparator1 = ' & '; % separate pipeline elements
                fieldSeparator2 = ', '; % separate inside of lists
            end    
            
            for iElem = 1:numel(pipelineElements)
                cElemString = pipelineElements{iElem};
                appendStr = '';
                
                if strcmp(cElemString,'configFeatureSelection')
                    nFeatures = sum(configuration.configFeatureSelection.featureSubSet(:)); 
                    if fullFeatureSetInfo.showFull
                        featureSubList = featureSubSetFromBitString(configuration.configFeatureSelection.featureSubSet, fullFeatureSetInfo.fullFeatureSet);
                        featureString = cellArrayToCSVString(featureSubList,fieldSeparator2);
                        appendStr = sprintf('%d features: %s',nFeatures, featureString);
                    else
                        appendStr = sprintf('%d features',nFeatures);                        
                    end
                end                
                
                if strcmp(cElemString,'configPreprocessing')
                    appendStr = configuration.configPreprocessing.featurePreProcessingMethod;
                end
                
                if strcmp(cElemString,'configFeatureTransform')
                    appendStr = configuration.configFeatureTransform.featureTransformMethod;
                    params = configuration.configFeatureTransform.featureTransformParams;
                    if ~strcmp(configuration.configFeatureTransform.featureTransformMethod,'none')
                        if isfield(params,'nDimensions')
                            appendStr = [appendStr fieldSeparator2 sprintf('nTargetDim=%d',params.nDimensions)];                        
                        end
    %                     if numel(fieldnames(params)) > 0
    %                         params=renameStructField(params,'estimateDimensionality','estDim');
    %                         params=renameStructField(params,'dimensionalityPercentage','dimPercent');
    %                         stringParams = struct2csv(params,fieldSeparator2);
    %                         appendStr = [appendStr fieldSeparator2 stringParams];
    %                     end 
                        hyperparams = queryStruct(configuration.configFeatureTransform,'featureTransformHyperparams',struct);
                        if numel(fieldnames(hyperparams)) > 0
                            stringParams = struct2csv(hyperparams,fieldSeparator2);
                            appendStr = [appendStr fieldSeparator2 stringParams];                        
                        end  
                    end
                end
                if strcmp(cElemString,'configClassifier')
                    appendStr = configuration.configClassifier.classifierName;
                    params = configuration.configClassifier.classifierParams;
                    if numel(fieldnames(params)) > 0
                        stringParams = struct2csv(params,fieldSeparator2);
                        appendStr = [appendStr fieldSeparator2 stringParams];
                    end                 
                end
                stringRep = [stringRep appendStr];
                % append separator if it is not the last entry
                if iElem < numel(pipelineElements)
                    stringRep = [stringRep fieldSeparator1];
                end
            end  
        end
        
        
           
         
     end
              
      
      
      methods(Access = private)
      
      end %private methods
        

    
    
end


        

        

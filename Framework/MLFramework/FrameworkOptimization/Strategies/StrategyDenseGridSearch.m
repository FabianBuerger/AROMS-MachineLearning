% Class definition StrategyDenseGridSearch
% make a dense grid search for e.g. visualization purposes
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef StrategyDenseGridSearch < OptimizationStrategy
    
    properties 
        classificationPipeline;
    end
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % start optimization process
        % note: use this.computationStopCriterion() for time limit check!
        function performOptimization(this)
            disp('-- start StrategyDenseGridSearch')

            % prepare
            nGridValues = this.job.jobParams.optimizationStrategyParameters.gridValues;
            classifierInfo = this.job.jobParams.dynamicComponents.componentsClassifierSelection{1};
            
            this.classificationPipeline = ClassificationPipeline();
            this.classificationPipeline.initParams(this.generalParams);

            baseConfig = ClassificationPipeline.getEmptyPipelineConfiguration();
            baseConfig.configFeatureSelection.featureSubSet = true(1,this.job.dataSet.nFeatures);
            baseConfig.configPreprocessing.featurePreProcessingMethod = this.job.jobParams.featurePreProcessingMethod;
            
            baseConfig.configFeatureTransform.featureTransformMethod = queryStruct(this.job.jobParams.optimizationStrategyParameters,'featureTransform','none');
            baseConfig.configFeatureTransform.featureTransformParams.nDimensions = round(this.job.dataSet.nFeatures*queryStruct(this.job.jobParams.optimizationStrategyParameters,'dimensionFraction',1));
            
            baseConfig.configClassifier.classifierName = classifierInfo.name;
            
            % make grid
            paramRanges = classifierInfo.parameterRanges;
            for ii=1:numel(paramRanges)
                pRange = paramRanges{ii}.paramRange;
                if ~iscell(pRange)
                    stepsize = pRange(2) - pRange(1);
                    stepsize = stepsize/nGridValues;
                    if strcmp(paramRanges{ii}.paramType,'int')
                        stepsize = max(1,floor(stepsize));
                    end             
                    paramRanges{ii}.values = [pRange(1) : stepsize : pRange(2)];
                    if strcmp(paramRanges{ii}.paramType,'realLog10')
                        paramRanges{ii}.values = 10.^paramRanges{ii}.values;
                    end
                end                    
            end
            classifierInfo.parameterRanges = paramRanges;
            paramGrid = parameterGridSearchLinear(paramRanges);
            
            % build pipeline ---
            
            % pipeline elements
            pipelineElemFeatureSelection= this.classificationPipeline.getPElemFeatureSelection();
            pipelineElementFeaturePreprocessing = this.classificationPipeline.getPElemFeaturePreprocessing();
            pipelineElemFeatureTransform = this.classificationPipeline.getPElemFeatureTransform();
            pipelineElemClassifier = this.classificationPipeline.getPElemClassifier();
              
            % start processing data
            dataPipelineIn = struct;
            dataPipelineIn.config = baseConfig;
            dataPipelineIn.dataSet = this.job.dataSet;

            % process
            dataFeatSel= pipelineElemFeatureSelection.prepareElement(dataPipelineIn);
            dataFeatPreProc = pipelineElementFeaturePreprocessing.prepareElement(dataFeatSel);
            dataFeatTrans=pipelineElemFeatureTransform.prepareElement(dataFeatPreProc);  
            
            paramsString = sprintf('PreProc %s  FeatTrans %s  Dim %d \n',...
                baseConfig.configPreprocessing.featurePreProcessingMethod,...
                baseConfig.configFeatureTransform.featureTransformMethod,... 
                baseConfig.configFeatureTransform.featureTransformParams.nDimensions);

            fprintf('Optimizing classifier %s with %d grid samples \n  OTHER CONFIG: %s \n',classifierInfo.name ,numel(paramGrid),paramsString);
            
            
            resultList = cell(1,numel(paramGrid));
            parfor iGrid = 1:numel(paramGrid)
                resultItem = struct;
                resultItem.errorOccurred = 0;
                try
                    cClassParam = paramGrid{iGrid};
                    dataForClassifier = dataFeatTrans;
                    dataForClassifier.config = baseConfig;
                    dataForClassifier.config.configClassifier.classifierParams = cClassParam;
                    dataForClassifier.crossValidationSets = this.crossValidationSets;
                    evaluationMetrics = pipelineElemClassifier.evaluateClassifierConfiguration(dataForClassifier);
                    
                    resultItem.configuration = dataForClassifier.config;
                    resultItem.evaluationMetrics = evaluationMetrics;
                    resultItem.qualityMetric = evaluationMetrics.accuracyOverallMean;
                    fprintf('Hyperparams %s   quality %0.5f \n',struct2csv(cClassParam),resultItem.qualityMetric);
                catch
                    resultItem.errorOccurred = 1;
                    resultItem.evaluationMetrics = struct;
                    resultItem.qualityMetric = 0;
                end
                
                
                resultList{iGrid} = resultItem;
            end        
            resultStruct = struct;
            resultStruct.classifierInfo = classifierInfo;
            resultStruct.resultList = resultList;
            resultStruct.job = this.job;
            
            fileresults = [this.job.jobParams.resultPath 'resultList.mat'];  
            save(fileresults,'resultStruct');
            fprintf('done grid evaluation! Saved to %s \n',fileresults);
            fprintf('  running denseGridPlotAnalysis(''%s'');\n',this.job.jobParams.resultPath);
            
            %make plots
            try
                denseGridPlotAnalysis(this.job.jobParams.resultPath);
            catch 
            end
            
            % append to results
            for iConfig = 1:numel(resultList)
                this.optimizationResultController.appendResult(resultList{iConfig})
            end
            
        end        
        
        
        
        %__________________________________________________________________
        % start optimization process
        function finishOptimization(this)
            disp('finishing results');
        end    
        
        
      end % end methods public ____________________________________________

      
      

end

        



% ----- helper -------




        

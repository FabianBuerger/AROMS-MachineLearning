% Class definition StrategyGridSearch
% This strategy uses greedy feature selection (e.g. Sequential Floating Forward
% Selection) combined with grid search of the other parameters.
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef StrategyGridSearch < OptimizationStrategy
    
    properties 
        %cache dataset after pre processing
        dataStruct;
        
        %classification pipeline
        classificationPipeline;
        
        % store feature selection sets and quality results
        featureSelectionHistory = {};
        
        featureNamesSetAll;
        nFeat = 0;
        
        paramDebug = 0;
    end
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % start optimization process
        % note: use this.computationStopCriterion() for time limit check!
        function performOptimization(this)
            this.featureSelectionHistory = {};
          
%             % prepare cross validation sets
%             if this.job.jobParams.performCrossValidation
%                 disp('> dividing data into cross validation sets')
%                 this.crossValidationSets = generateCrossValidationIndexSets(...
%                     this.job.dataSet.nSamples,this.job.jobParams.crossValidationK);
%             end
            
            % set strategy based parameters --------------------------
            this.job.jobParams.optimizationStrategyParameters.featureSelectionStrategy = ...
                queryStruct(this.job.jobParams.optimizationStrategyParameters, 'featureSelectionStrategy', 'SFFS');
            
            % --------------------------------------------------------
            % set of components and parameters
            dynamicComponents = this.job.jobParams.dynamicComponents;
            this.featureNamesSetAll = dynamicComponents.componentsFeatureSelection;
            this.nFeat = numel(this.featureNamesSetAll);
            
            % base configuration (has to be filled)
            pipelineConfig = ClassificationPipeline.getEmptyPipelineConfiguration(this.job.jobParams);
            pipelineConfig.configPreprocessing.featurePreProcessingMethod = this.job.jobParams.featurePreProcessingMethod;
            
            this.classificationPipeline = ClassificationPipeline();
            this.classificationPipeline.initParams(this.generalParams);
 
            this.dataStruct = struct;
            this.dataStruct.dataSet = this.job.dataSet;
            this.dataStruct.config = pipelineConfig;    

            % start heuristic feature selection
            featSelStrat = this.job.jobParams.optimizationStrategyParameters.featureSelectionStrategy;
            switch featSelStrat
                case 'allFeatures'
                    this.featureSelection_AllFeatures();
                case 'SFS'     
                    this.featureSelection_SFS();
                case 'SBS' 
                    this.featureSelection_SBS();
                case 'SFFS'
                    this.featureSelection_SFFS();
                case 'SFBS'
                    this.featureSelection_SFBS();
                otherwise
                    error('Feature selection strategy %s unknown',featSelStrat);
            end
            
            this.log('Feature Selection done.');
               
        end        
        

        %==================================================================
        % Feature Selection code
        %==================================================================        
        
        %__________________________________________________________________
        % perform Feature Selection with all features
        function featureSelection_AllFeatures(this)
            this.log('Feature Selection: All Features');
            this.log('----------------------------------');
            
            % set of components and parameters
            dynamicComponents = this.job.jobParams.dynamicComponents;
            featureNamesSetAll = dynamicComponents.componentsFeatureSelection;
            
            this.getQualityOfFeatureSet(featureNamesSetAll);
        end
        
        %__________________________________________________________________
        % perform Feature Selection Sequential Forward Selection
        function featureSelection_SFS(this)
            this.log('Feature Selection: Sequential Forward Selection SFS');
            this.log('----------------------------------');
            
            % set of components and parameters
            dynamicComponents = this.job.jobParams.dynamicComponents;
            featureNamesSetAll = dynamicComponents.componentsFeatureSelection;
            
            nFeatAll = numel(featureNamesSetAll);
            setCurrent = {}; % start with empty set
            setRest = featureNamesSetAll; % rest contains all other
            for iSelRound = 1: nFeatAll
                if ~this.computationStopCriterion()
                    bestVal = 0;
                    bestIndex = 0;
                    for iCurr = 1:numel(setRest)
                        cItem = setRest{iCurr};
                        tempSet = [setCurrent, cItem];
                        if ~this.computationStopCriterion()
                            bestQualityCurrent = this.getQualityOfFeatureSet(tempSet);
                            if bestQualityCurrent > bestVal
                                bestVal = bestQualityCurrent;
                                bestIndex = iCurr;
                            end
                        end
                    end     
                    if numel(setRest) > 0
                        % get best item
                        bestItem = setRest{bestIndex};
                        setCurrent = [setCurrent, bestItem];
                        setRest(bestIndex) = [];
                    end
                end
            end                            
        end        
        
        %__________________________________________________________________
        % perform Feature Selection Sequential Backward Selection
        function featureSelection_SBS(this)
            this.log('Feature Selection: Sequential Backward Selection SBS');
            this.log('----------------------------------');
            
            % set of components and parameters
            dynamicComponents = this.job.jobParams.dynamicComponents; 
            featureNamesSetAll = dynamicComponents.componentsFeatureSelection;  
            
            nFeatAll = numel(featureNamesSetAll);
            setCurrent = featureNamesSetAll; % start with full set
            this.getQualityOfFeatureSet(featureNamesSetAll); % evaluate all
            for iSelRound = 1: nFeatAll
                if ~this.computationStopCriterion()
                    bestVal = 0;
                    bestIndex = 0;
                    if numel(setCurrent) > 1
                        for iCurr = 1:numel(setCurrent)
                            tempSet = setCurrent;
                            tempSet(iCurr) = [];
                            if ~this.computationStopCriterion()
                                bestQualityCurrent = this.getQualityOfFeatureSet(tempSet);
                                if bestQualityCurrent > bestVal
                                    bestVal = bestQualityCurrent;
                                    bestIndex = iCurr;
                                end
                            end
                        end     
                        %best combination
                        setCurrent(bestIndex) = [];
                    end
                end
            end            
        end           
        
        %__________________________________________________________________
        % perform Feature Selection Sequential Floating Forward Selection
        function featureSelection_SFFS(this)
            this.log('Feature Selection: Sequential Floating Forward Selection SFFS');
            this.log('----------------------------------');
            
            % set of components and parameters
            dynamicComponents = this.job.jobParams.dynamicComponents;
            featureNamesSetAll = dynamicComponents.componentsFeatureSelection;
            
            nFeatAll = numel(featureNamesSetAll);
            setsCheckedForBW = {};
            setCurrent = {}; % start with empty set
            setRest = featureNamesSetAll; % rest contains all other
            loopOuterDone = false;    
            while ~loopOuterDone 
                % SFS, add best feature
                disp('>> Forward step')
                [setCurrent, setRest, lastQuality] = ...
                    this.SFS_step(setCurrent, setRest);
                
                if numel(setCurrent) > 1
                    loopInnerDone = false;
                    while ~loopInnerDone 
                        %SBS to remove worst features
                        setCurrent_temp = setCurrent;
                        setRest_temp = setRest;                        
                        checkedAlreay = listContainsSet(setsCheckedForBW,setCurrent_temp);
                        setsCheckedForBW{end+1} = setCurrent_temp;
                        if ~checkedAlreay
                            disp('<< Backward step')
                            [setCurrent_temp, setRest_temp, qualityBackwardStep] = ...
                                this.SBS_step(setCurrent_temp, setRest_temp); 
                            if qualityBackwardStep > lastQuality
                                lastQuality = qualityBackwardStep;
                                setCurrent = setCurrent_temp;
                                setRest = setRest_temp;
                                loopInnerDone = numel(setCurrent)<=1; %only go on if at least 2 elements inside of list
                            else
                                loopInnerDone = true;
                            end
                        else
                            loopInnerDone = true;
                        end
                        % timer constraints
                        if this.computationStopCriterion()
                            loopInnerDone = true;
                        end
                    end
                end
                if numel(setRest) == 0 || this.computationStopCriterion()
                    loopOuterDone = true;
                end
            end % outer loop            
            
            
        end         
        
        %__________________________________________________________________
        % perform Feature Selection Sequential Floating Backward Selection
        function featureSelection_SFBS(this)
            this.log('Feature Selection: Sequential Floating Backward Selection SFBS');
            this.log('----------------------------------');
                 
            % set of components and parameters
            dynamicComponents = this.job.jobParams.dynamicComponents;
            featureNamesSetAll = dynamicComponents.componentsFeatureSelection;
            
            nFeatAll = numel(featureNamesSetAll);
            this.getQualityOfFeatureSet(featureNamesSetAll);
            setsCheckedForFW = {featureNamesSetAll};
            setCurrent = featureNamesSetAll; % start with all
            setRest = {}; % rest empty
            loopOuterDone = false;    
            while ~loopOuterDone 
                % SBS, remove feature
                disp('<< Backward step')
                [setCurrent, setRest, lastQuality] = ...
                    this.SBS_step(setCurrent, setRest);
                
                if numel(setCurrent) < nFeatAll
                    loopInnerDone = false;
                    while ~loopInnerDone 
                        %SFS to add best again
                        setCurrent_temp = setCurrent;
                        setRest_temp = setRest;                        
                        checkedAlreay = listContainsSet(setsCheckedForFW,setCurrent_temp);
                        setsCheckedForFW{end+1} = setCurrent_temp;
                        if ~checkedAlreay
                            disp('>> Forward step')
                            [setCurrent_temp, setRest_temp, qualityForwardStep] = ...
                                this.SFS_step(setCurrent_temp, setRest_temp); 
                            if qualityForwardStep > lastQuality
                                lastQuality = qualityForwardStep;
                                setCurrent = setCurrent_temp;
                                setRest = setRest_temp;
                                loopInnerDone = numel(setRest)<1; %only go on if at least 2 elements inside of list
                            else
                                loopInnerDone = true;
                            end
                        else
                            loopInnerDone = true;
                        end
                        % timer constraints
                        if this.computationStopCriterion()
                            loopInnerDone = true;
                        end
                    end
                end
                if numel(setCurrent) <= 1 || this.computationStopCriterion()
                    loopOuterDone = true;
                end
            end % outer loop            
        end     
        
        
        %__________________________________________________________________
        % single step in sfs with book keeping functions
        function [setCurrent, setRest, quality] = SFS_step(this,setCurrent, setRest)
            bestVal = 0;
            bestIndex = 0;
            quality = 0;
            for iCurr = 1:numel(setRest)
                cItem = setRest{iCurr};
                tempSet = [setCurrent; cItem];
                if ~this.computationStopCriterion()
                    bestQualityCurrent = this.getQualityOfFeatureSet(tempSet);
                    if bestQualityCurrent > bestVal
                        bestVal = bestQualityCurrent;
                        bestIndex = iCurr;
                    end
                else
                   return; 
                end
            end     
            if numel(setRest) > 0
                % get best item
                bestItem = setRest{bestIndex};
                setCurrent = [setCurrent; bestItem];
                setRest(bestIndex) = [];     
            end
            quality=bestVal;
        end

        
        %__________________________________________________________________
        % single step in sbs with book keeping functions
        function [setCurrent, setRest, quality] = SBS_step(this,setCurrent, setRest)
            bestVal = 0;
            bestIndex = 0;
            quality = 0;            
            if numel(setCurrent) > 1
                for iCurr = 1:numel(setCurrent)
                    tempSet = setCurrent;
                    tempSet(iCurr) = [];
                    if ~this.computationStopCriterion()
                        bestQualityCurrent = this.getQualityOfFeatureSet(tempSet);
                        if bestQualityCurrent > bestVal
                            bestVal = bestQualityCurrent;
                            bestIndex = iCurr;
                        end
                    else
                       return; 
                    end
                end     
                %best combination
                r=setCurrent{bestIndex};
                setRest = [setRest;r];
                setCurrent(bestIndex) = [];
            end
            quality = bestVal;
        end                
        
        
        
        
        %==================================================================
        % Evaluation code 
        %==================================================================
        
        
        %__________________________________________________________________
        % evaluate quality of a feature sub set and cache sets that are
        % already evaluated
        function [qualityMetric, evaluatedAlready] = getQualityOfFeatureSet(this, featureSet)
            qualityMetric = -1;
            evaluatedAlready = 0;
            
            % look inside of cache
            iList = 0;
            while ~evaluatedAlready && iList < numel(this.featureSelectionHistory)
                iList = iList+1;
                cSetCache = this.featureSelectionHistory{iList};
                if stringCellArraysContainSameElements(featureSet, cSetCache.featureSet)
                    evaluatedAlready = 1;
                    qualityMetric = cSetCache.qualityMetric;
                    %this.log(sprintf('  Feature Set in Cache: %s', cellArrayToCSVString(featureSet,',')));
                    this.log(sprintf('  => Quality Metric: %0.4f', qualityMetric));
                end
            end
            % not found in cache
            if ~evaluatedAlready
                %this.log(sprintf('  Testing Feature Set: %s', cellArrayToCSVString(featureSet,',')));
                % perform grid search
                qualityMetric = this.qualityMetricGridParamterSearch(featureSet);
                this.log(sprintf('  => Quality Metric: %0.4f', qualityMetric));
                % store in list
                cSetCache = struct;
                cSetCache.featureSet = featureSet;
                cSetCache.qualityMetric = qualityMetric;
                this.featureSelectionHistory{end+1} = cSetCache;
            end
            % append to time series for feature selection quality
            % measurement
            dataItem.value = qualityMetric;
            dataItem.featureSet = featureSet;
            this.timeSeriesStorage.appendValue('QualityFeatureSelectionSteps', dataItem);
        end      
        
        
        %__________________________________________________________________
        % perform grid search on feature transform and classifier and
        % parameters
        function qualityMetric = qualityMetricGridParamterSearch(this, featureSet)
            % make binary feature set
            if numel(featureSet) == this.nFeat
                % full set -> speedup
                featureSetBin = true(1,this.nFeat);
            else
                featureSetBin = bitStringFromFeatureSubSet(featureSet, this.featureNamesSetAll);
            end
            
            % all optimizations are added in subclass
            addConfigToDatabase = 1;
%             if this.job.jobParams.extendedCrossValidation
%                 % NOT USED anymore. Heuristic grid search only for baseline methods without feature transform
%                 % call grid optimizer with CV feature transform and classifier validation
%               %  [resultList, bestConfig] = gridOptimizerFeatureTransfromAndClassifierCV(this, featureSetBin,addConfigToDatabase); 
                % call grid optimizer with CV classifier validation
            [resultList, bestConfig] = gridOptimizerFeatureTransfromAndClassifier(this, featureSetBin,addConfigToDatabase);                 

            % get best config
            qualityMetric=bestConfig.bestQuality;
        end           
        
        
        %__________________________________________________________________
        % start optimization process
        function finishOptimization(this)
            disp('finishing results');
        end    
        
        
      end % end methods public ____________________________________________

      
      

end

        



% ----- helper -------


% contains a cell array of cell strings a sub set in any order?
function flag = listContainsSet(setList, set)
    flag = 0;
    for ii=1:numel(setList)
        cSet = setList{ii};
        cFlag = stringCellArraysContainSameElements(cSet, set);
        if cFlag
            flag = 1;
        end
    end

end

        

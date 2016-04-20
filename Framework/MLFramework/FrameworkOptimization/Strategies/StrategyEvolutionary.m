% Class definition StrategyEvolutionary
% This strategy uses evolutionary optimization to find the best framework
% configuration.
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef StrategyEvolutionary < OptimizationStrategy
    
    properties 
        
        % evolutionary coding and operations
        evoStratOpt; %
        currentEvolutionaryProfile = '';       
        appendConfigEvaluationsToFinalResultList = 0;
        
        % main components code components
        geneIdFeatureSelection = 0;
        geneIdFeaturePreProcessing = 0;
        geneIdFeatureTransform = 0;
        geneIdFeatureTransformDimensionality = 0;
        featureTransfromHyperparamsActive = 0;
        geneIdsFeatureTransformHyperparams = {} % store locations of feature transform hyperparameters (only in CES strategy and optimizationComponentsFeatureTransformHyperParams=1)
        geneIdClassifier = 0;
        geneIdsClassifierHyperparams = {}; % store location and name indices for appended classifier hyperparameters (only in CES strategy)
        
        initialOptimizationClassifierName = 'ClassifierNaiveBayes';
        initialOptimizationTime = 0;
        currentEvoMode = '';
        paramDebug = 0;
        logMutationInfo = 1;
        
        earlyDiscardingTimeLimitSecs = inf; % time limit 
        earlyDiscardingTimeLimitFactorMedian = 1;
    end
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % start optimization process
        % note: use this.computationStopCriterion() for time limit check!
        function performOptimization(this)
                      
            % set strategy based parameters --------------------------
            
            % optimization profile: what should be optimized genetically
            % - EvolutionaryGridSearch: Feature Selection + Feature Transform + Classifier
            % - EvolutionaryConfigurationAdaptation: is Feature Selection + Feature Transform + Classifier + parameters (without grid)
            evoOptProf = queryStruct(this.job.jobParams.optimizationStrategyParameters, 'evoOptProfile', 'EvolutionaryConfigurationAdaptation');
            this.job.jobParams.optimizationStrategyParameters.evoOptProfile = evoOptProf;
            fprintf('Evolutionary Optimization Profile %s \n',evoOptProf);       
            
            % standard strategy parameters
            if strcmp(evoOptProf,'EvolutionaryGridSearch')   
                standardParameterStruct = frameworkJobProfiles('EvolutionaryGridSearch',struct);
                standardParameterStruct = standardParameterStruct{1}.optimizationStrategyParameters;
            elseif strcmp(evoOptProf,'EvolutionaryConfigurationAdaptation')
                standardParameterStruct = frameworkJobProfiles('EvolutionaryConfigurationAdaptation',struct);
                standardParameterStruct = standardParameterStruct{1}.optimizationStrategyParameters;
            else
               warning('ERROR: evoOptProf not recognized!');
               error('ERROR: evoOptProf not recognized!')
            end
            
            this.job.jobParams.optimizationStrategyParameters = parameterMergeWithStandardStruct(this.job.jobParams.optimizationStrategyParameters,standardParameterStruct);   
            
            %- params end -------------------------------------------------
 
            % prepare configuration ===
            classificationPipeline = ClassificationPipeline();
            classificationPipeline.initParams(this.generalParams);     
                        
            % === INITIAL optimization of population (only if feature
            % selection is selected)
            initialImprovementData = struct;
            this.initialOptimizationTime = 0; % if all features are used, initial feature optimization does not make sense
            if ~strcmp(this.job.jobParams.optimizationStrategyParameters.featureSelectionStrategy,'allFeatures')
                timer = tic();
                if strcmp(this.job.jobParams.optimizationStrategyParameters.evoOptInitialPopulationImprovement,'evolutionaryFeatureOptimization')
                    % variant: optimize relaxed problem with only feature
                    % selection, preprocessing and bayes classifier (without
                    % hyperparameters)
                    disp('Improvement of initial population: evolutionaryFeatureOptimization');
                    this.appendConfigEvaluationsToFinalResultList = 0;
                    evoParams = struct;
                    evoParams.evoMode = 'InitialImprovement';
                    initialParams = this.job.jobParams.optimizationStrategyParameters;
                    initialParams.evoOptNIndividualsInitial = 200;
                    initialParams.evoOptNOptimizationGenerations = 5;
                    initialParams.evoOptNChildrenPerGeneration = 50;
                    initialParams.evoOptGenerationPopulationSize = 20;
                    initialParams.evoOptMaxIndiviualAge = inf;

                    evoParams.optimizationStrategyParameters = initialParams;
                    %get evoluationary object
                    this.evoStratOpt = this.getEvolutionaryStrategyObject(evoParams);      
                    this.evoStratOpt.appendRandomPopulation();        
                    fprintf('== Initial Population Optimization ==\n');
                    
                    this.evoStratOpt.runEvolutionaryOptimization(@this.evaluatePopulationFitness);  
                    initialImprovementData.goodInitialPopulation = this.evoStratOpt.currentPopulation;          

                elseif (strcmp(this.job.jobParams.optimizationStrategyParameters.evoOptInitialPopulationImprovement,'randomForestVariableImportance') && ...
                        this.job.jobParams.splitMultiChannelFeatures)
                    
                    % use random forest variable importance to set
                    % probabilities for intial random feature generation
                    disp('Improvement of initial population: randomForestVariableImportance');     
                    nTrees = 20;
                    initialImprovementData.variableImportances = variableImportanceRandomForest(this.job.dataSet, nTrees);
               
                else
                    % no initial improvement
                    disp('Improvement of initial population: NONE!');
                end
                this.initialOptimizationTime = toc(timer);
            end
            % this should be stored
            this.aggregatedResults.initialImprovementData = initialImprovementData;
            
            % === MAIN Evolutionary optimization 
            fprintf('== Main Optimization ==\n');
            
            this.appendConfigEvaluationsToFinalResultList = 1;
            evoParams = struct;
            evoParams.evoMode = this.job.jobParams.optimizationStrategyParameters.evoOptProfile;
            evoParams.optimizationStrategyParameters = this.job.jobParams.optimizationStrategyParameters;
           
            this.evoStratOpt = this.getEvolutionaryStrategyObject(evoParams);     

            % handle initial improvement
            this.handleInitialPopulationGeneration(initialImprovementData);
                        
            % start main evolutionary optimization            
            this.evoStratOpt.runEvolutionaryOptimization(@this.evaluatePopulationFitness);
           
        end        
        
        
        %__________________________________________________________________
        % handle initial generation of population with prior knowledge
        function handleInitialPopulationGeneration(this,initialImprovementData)
            if isfield(initialImprovementData,'variableImportances')
                % set initial probabilities according to feature importance
                minP = 0.25; % scale probability to [minP 1]
                intialPValues = minP + (1-minP)*initialImprovementData.variableImportances;
                this.evoStratOpt.genomeInfo.genomePropertyList{this.geneIdFeatureSelection}.probabilityThreshInitial = intialPValues;
            end
            
            % inital population by random generation (uses initial p values
            % set above)
            this.evoStratOpt.appendRandomPopulation();            
                
            if isfield(initialImprovementData,'goodInitialPopulation')
                % take features from good candidates
                this.improveInitialPopulation(initialImprovementData.goodInitialPopulation);
            end
        end
                
        
        
        %__________________________________________________________________
        % fuse information from initial optimization into random start
        % population of the main optimization
        function improveInitialPopulation(this,goodInitialPopulation)
            disp('> Improving Main initial population')
            for iInd = 1:numel(this.evoStratOpt.currentPopulation)
                % for each main individual select one from the good initial
                % individuals
                randomGoodIndex = randi([1,numel(goodInitialPopulation)],1,1);
                goodIndividual = goodInitialPopulation{randomGoodIndex};
                % take feature selection
                goodFeatures = goodIndividual.propertyValues{this.geneIdFeatureSelection};
                % manipulate main individual
                this.evoStratOpt.currentPopulation{iInd}.propertyValues{this.geneIdFeatureSelection} = goodFeatures;
            end
        end
        
     
        
        %__________________________________________________________________
        % get prepared and parameterized object for evolutionary
        % optimization
        function evoStratOptObj = getEvolutionaryStrategyObject(this,evoParams)        
            this.currentEvoMode = evoParams.evoMode;
            % select profile
            % - EvolutionaryGridSearch
            % - EvolutionaryConfigurationAdaptation
            % - InitialImprovement
            evoMode = evoParams.evoMode;
            optimizationStrategyParameters = evoParams.optimizationStrategyParameters;
            
            % set of components and parameters
            dynamicComponents = this.job.jobParams.dynamicComponents;
           
            % reset time limit for early discaring
            this.earlyDiscardingTimeLimitSecs = inf;
            
            %--------------------------------------------------------------
            % evolutionary class init
            evoStratOptObj = EvolutionaryStrategyOptimization();
            evoStratOptObj.init();
            evoStratOptObj.setMutationParams(optimizationStrategyParameters.evoOptMutationParams);
            
            evoStratOptObj.badFitnessTresh = 1/this.job.dataSet.nClasses;
            
            % set up genetic information (dependent on profile)
            %=============================================================
            
            if strcmp(evoMode,'EvolutionaryGridSearch')
                this.currentEvolutionaryProfile = 'EvolutionaryGridSearch';
            end
            
            if strcmp(evoMode,'EvolutionaryConfigurationAdaptation')
                this.currentEvolutionaryProfile = 'EvolutionaryConfigurationAdaptation';
            end         
            
            %reset ids for gene coding
            this.geneIdFeatureSelection = 0;
            this.geneIdFeaturePreProcessing = 0;
            this.geneIdFeatureTransform = 0;
            this.geneIdFeatureTransformDimensionality = 0;
            this.geneIdClassifier = 0;            
            this.geneIdsClassifierHyperparams = {};
                
            % ===== add Feature Selection to optimization
            if cellStringsContainString({'EvolutionaryGridSearch','EvolutionaryConfigurationAdaptation','InitialImprovement'},evoMode)
                % add bit string type for feature selection
                emptyBitsAllowed = 0;
                probabilityThreshInitial = []; % empty -> this value is determined randomly
                allBitsTrue = strcmpi(optimizationStrategyParameters.featureSelectionStrategy,'allFeatures');
                evoStratOptObj.genomeInfo.appendGenomeTypeBitString('FeatureSelection', ...
                    numel(dynamicComponents.componentsFeatureSelection),emptyBitsAllowed,allBitsTrue,probabilityThreshInitial,[]);
                % get gene index for componenet
                this.geneIdFeatureSelection = numel(evoStratOptObj.genomeInfo.genomePropertyList);
            end
            
            
            % ===== add preprocessing methods
            if cellStringsContainString({'EvolutionaryGridSearch','EvolutionaryConfigurationAdaptation','InitialImprovement'},evoMode)  
                evoStratOptObj.genomeInfo.appendGenomeTypeSet('featurePreProcessingMethod', dynamicComponents.componentsFeaturePreProcessing,[]);
                this.geneIdFeaturePreProcessing = numel(evoStratOptObj.genomeInfo.genomePropertyList);
            end    
            
            
            % ===== initial optimization genetics
            if cellStringsContainString({'InitialImprovement'},evoMode)
                this.currentEvolutionaryProfile = 'EvolutionaryGridSearch';

                evoStratOptObj.genomeInfo.appendGenomeTypeSet('FeatureTransform',{'none'},[]);    
                this.geneIdFeatureTransform = numel(evoStratOptObj.genomeInfo.genomePropertyList);
                
                evoStratOptObj.genomeInfo.appendGenomeTypeNumberReal('FeatTransDimensionality', 100,100,[]);               
                this.geneIdFeatureTransformDimensionality = numel(evoStratOptObj.genomeInfo.genomePropertyList);
                
                evoStratOptObj.genomeInfo.appendGenomeTypeSet('Classifier', {this.initialOptimizationClassifierName},[]);   
                this.geneIdClassifier = numel(evoStratOptObj.genomeInfo.genomePropertyList);
            end                  
            
            
            % ===== add FeatureTransform to optimization genes
            if cellStringsContainString({'EvolutionaryGridSearch','EvolutionaryConfigurationAdaptation'},evoMode)
                % list of feature transform as set
                featureTransformList = getCellArrayOfProperties(...
                    dynamicComponents.componentsFeatureTransSelection,'name');
                evoStratOptObj.genomeInfo.appendGenomeTypeSet('FeatureTransform', ...
                    featureTransformList,[]);  
                %gene id
                this.geneIdFeatureTransform = numel(evoStratOptObj.genomeInfo.genomePropertyList);                
                
                % feature transform dimensionality (as percentage of
                % feature selection) % dimension reduction prior
                maxDim = this.job.jobParams.featureTransformDimensionPrior; % max target dim set to 50
                maxDimPrecentage = min(100,100*maxDim/this.job.dataSet.totalDimensionality);
                
                addInfo = struct;
                evoStratOptObj.genomeInfo.appendGenomeTypeNumberReal('FeatTransDimensionality', 0, maxDimPrecentage, addInfo);
                % gene id
                this.geneIdFeatureTransformDimensionality = numel(evoStratOptObj.genomeInfo.genomePropertyList);
                     
            end 
            
            % ===== add FeatureTransform Hyperparameters to optimization genes           
            if cellStringsContainString({'EvolutionaryConfigurationAdaptation'},evoMode)
                this.featureTransfromHyperparamsActive = 1;
                useDefault = ~this.job.jobParams.optimizationComponentsFeatureTransformHyperParams;
                [evoStratOptObj, genomeIdInfoList] = this.appendHyperparametersToGenome(evoStratOptObj,dynamicComponents.componentsFeatureTransSelection, useDefault); 
                this.geneIdsFeatureTransformHyperparams = genomeIdInfoList;                
            else
                this.featureTransfromHyperparamsActive=0;
            end
            

            % ===== add Classifier to optimization genes
            if cellStringsContainString({'EvolutionaryGridSearch','EvolutionaryConfigurationAdaptation'},evoMode)
                % add list of classifiers as set
                classfierList = getCellArrayOfProperties(...
                    dynamicComponents.componentsClassifierSelection,'name');                
                evoStratOptObj.genomeInfo.appendGenomeTypeSet('Classifier', ...
                    classfierList,[]);  
                % gene id
                this.geneIdClassifier = numel(evoStratOptObj.genomeInfo.genomePropertyList);
            end             
            

            % ===== EvolutionaryConfigurationAdaptation: add all hyperparameters
            if  cellStringsContainString({'EvolutionaryConfigurationAdaptation'},evoMode)  
                % add classifier parameters to genetic information                
                useDefault = ~this.job.jobParams.optimizationComponentsClassifierHyperParams;
                [evoStratOptObj, genomeIdInfoList] = this.appendHyperparametersToGenome(evoStratOptObj,dynamicComponents.componentsClassifierSelection, useDefault); 
                this.geneIdsClassifierHyperparams = genomeIdInfoList;
                
            end               
      
            
            %--------------------------------------------------------------    
            % evolutionary parameters
            evoStratOptObj.searchMode = optimizationStrategyParameters.searchMode;
            evoStratOptObj.nIndividualsInitial = optimizationStrategyParameters.evoOptNIndividualsInitial;
            evoStratOptObj.nOptimizationGenerations = optimizationStrategyParameters.evoOptNOptimizationGenerations;
            evoStratOptObj.nParentsPerChild = optimizationStrategyParameters.evoOptNParentsPerChild;
            evoStratOptObj.nChildrenPerGeneration = optimizationStrategyParameters.evoOptNChildrenPerGeneration;
            evoStratOptObj.generationPopulationSize = optimizationStrategyParameters.evoOptGenerationPopulationSize;  
            evoStratOptObj.generationPopulationSizeHighSelectionPressure = ...
                optimizationStrategyParameters.evoOptGenerationPopulationSizeHighPressure; 
            evoStratOptObj.selectionPressureGenerations = optimizationStrategyParameters.evoOptNumberHighPressureGenerations; 
            evoStratOptObj.evoOptStopCriterionNumberGenerationsWithNoImprovement =  ...
                optimizationStrategyParameters.evoOptStopCriterionNumberGenerationsWithNoImprovement;
            
            evoStratOptObj.evoOptNumberMinGenerations = optimizationStrategyParameters.evoOptNumberMinGenerations;
            evoStratOptObj.evoOptMaxIndiviualAge = optimizationStrategyParameters.evoOptMaxIndiviualAge;
            
            evoStratOptObj.statusTextFile = [this.job.jobParams.resultPath  filesep 'LogEvoStrat_' evoMode '.txt'];            
            
            % get some stats
            evoStatInfoFile = [this.job.jobParams.resultPath  filesep 'EvoStrat_GenomeInfo_' evoMode '.txt'];
            evoStratOptObj.makeGenomeStatInfo(evoStatInfoFile);
            
            if this.logMutationInfo
                evoStratOptObj.mutationInfoFile = [this.job.jobParams.resultPath  filesep 'EvoStrat_MutationInfo_' evoMode '.csv'];  
            end
        end    
            
            
        
        %__________________________________________________________________
        % include set of hyperparameters to genome coding (classifier
        % hyperparameter and feature transform hyperparameter
        function [evoStratOptObj, genomeIdInfoList] = appendHyperparametersToGenome(this,evoStratOptObj,componentsList,useDefaultValues) 
            genomeIdInfoList = {};
            % add classifier parameters to genetic information         
            for iMeth = 1:numel(componentsList)
                cMethInfo = componentsList{iMeth};
                paramGeneInfo = struct;
                paramGeneInfo.methName = cMethInfo.name;
                paramGeneInfo.paramGeneIndices = []; % linear numbering of classifier indices to find them later again
                % add classifier params to genes according to type
                for iParam = 1:numel(cMethInfo.parameterRanges)
                    cParam = cMethInfo.parameterRanges{iParam};
                    data = struct;
                    data.methName = paramGeneInfo.methName;
                    data.parameterName = cParam.name;
                    data.paramType=cParam.paramType;                
                    cParamName = [paramGeneInfo.methName '_' cParam.name];
                    
                    if useDefaultValues
                        if strcmp(cParam.paramType,'int')
                            evoStratOptObj.genomeInfo.appendGenomeTypeNumberInteger(cParamName, cParam.standardValue,cParam.standardValue,data);
                        elseif strcmp(cParam.paramType,'set')
                            evoStratOptObj.genomeInfo.appendGenomeTypeSet(cParamName, {cParam.standardValue}, data);
                        elseif strcmp(cParam.paramType,'realLog10') || strcmp(cParam.paramType,'real')
                            evoStratOptObj.genomeInfo.appendGenomeTypeNumberReal(cParamName, cParam.standardValue,cParam.standardValue, data);
                        else
                            error('Parameter type not recognized!');
                        end                            
                    else
                        if strcmp(cParam.paramType,'int')
                            evoStratOptObj.genomeInfo.appendGenomeTypeNumberInteger(cParamName, cParam.paramRange(1),cParam.paramRange(2),data);
                        elseif strcmp(cParam.paramType,'set')
                            evoStratOptObj.genomeInfo.appendGenomeTypeSet(cParamName, cParam.paramRange, data);
                        elseif strcmp(cParam.paramType,'realLog10') || strcmp(cParam.paramType,'real')
                            evoStratOptObj.genomeInfo.appendGenomeTypeNumberReal(cParamName, cParam.paramRange(1),cParam.paramRange(2), data);
                        else
                            error('Parameter type not recognized!');
                        end                              
                    end
                    cGeneIndex = numel(evoStratOptObj.genomeInfo.genomePropertyList);
                    paramGeneInfo.paramGeneIndices(end+1) = cGeneIndex;
                end
                genomeIdInfoList{end+1} = paramGeneInfo;
            end
        end
        
        
        
        %__________________________________________________________________
        % evaluation of evolutionary optimization round (called from
        % class EvolutionaryStrategyOptimization)
        function fitnessValues = evaluatePopulationFitness(this,individualsList)
            nIndividuals = numel(individualsList);
            this.log(sprintf('Fitness evaluations of %d individuals',nIndividuals));

            % get configuration from genome coding
            evoOptProf = this.currentEvolutionaryProfile;
            
            if strcmp(evoOptProf,'EvolutionaryGridSearch')
                evoOptProfBin = 0;
            elseif strcmp(evoOptProf,'EvolutionaryConfigurationAdaptation')
                evoOptProfBin = 1;
            else
                error('evoOptProf parameter not recognized');
            end
            
            configurationList = this.configurationsFromEvolutionaryCoding(individualsList);
            
            % data passing for optimization (do not pass all objects to
            % parallel computing!)
            dataStructBase = struct;
            dataStructBase.dataSet = this.job.dataSet;
            dataStructBase.configurationList = configurationList;
            dataStructBase.generalParams = this.generalParams;
            
            dataStructBase.dynamicComponents = this.job.jobParams.dynamicComponents;            
            if strcmp(this.currentEvoMode,'InitialImprovement')
                % add just initial optimization classifier to dynamic
                % classifer info
                allFrameworkComponents = frameworkComponentLists();
                dataStructBase.dynamicComponents.componentsClassifierSelection = FrameworkParameterController.getComponentAndParameterSelection(...
                allFrameworkComponents.classifiers,{this.initialOptimizationClassifierName}, 2);      
                
            end
            
            dataStructBase.crossValidationSets = this.crossValidationSets;
            dataStructBase.jobParams = this.job.jobParams;
            
            % get statistics of current best solutions to discard bad
            % solutions quickly
            earlyDiscardingParams = struct;
            earlyDiscardingParams.active = this.job.jobParams.crossValidationEarlyDiscarding;
            earlyDiscardingParams.significance = this.job.jobParams.crossValidationEarlyDiscardingSignificance;
            earlyDiscardingParams.bestQualityMean = this.optimizationResultController.getCurrentBestQualityMetric();
            earlyDiscardingParams.bestQualityStd = this.optimizationResultController.getCurrentStdEstimation(); 
            earlyDiscardingParams.nRoundsTotal = this.job.jobParams.crossValidationK;
            earlyDiscardingParams.badQualityThresh = 1/this.job.dataSet.nClasses;
            earlyDiscardingParams.classIds = this.job.dataSet.classIds;
            earlyDiscardingParams.jobParams = this.job.jobParams;
            earlyDiscardingParams.timeLimitCriterionActive =  this.job.jobParams.crossValidationEarlyDiscardingTimeCriterion;
            earlyDiscardingParams.timeLimitSeconds = this.earlyDiscardingTimeLimitSecs;
            
            dataStructBase.earlyDiscardingParams = earlyDiscardingParams;      
            this.log(sprintf('Early discarding mean %0.5f with std %0.5f',earlyDiscardingParams.bestQualityMean, earlyDiscardingParams.bestQualityStd));
            
            % resultList
            fitnessValues = [];
            timeValues = [];
            resultListAll = {};
            otherResultsAll = {};
            individiualLogger = {};
            % subdivide into blocks of evaluations
                        
            if this.evoStratOpt.iEvolutionRound == 0
                individualsFirstRound = min(nIndividuals,6); % evaluate few first, to allo early discarding to work as fast as possible
            else
                individualsFirstRound = min(nIndividuals,30);
            end
            individualsOtherRounds = min(nIndividuals,30);
            continueEvals = 1;
            cStartInd = 1;
            cEndInd = individualsFirstRound;       
                    
            parallelTBHandler = this.optimizationControllerHandle.parallelToolBoxHandler;
            while continueEvals
                individualsIndexList = cStartInd:cEndInd;
                fprintf('IndividualsIndexList: from-to %d - %d (%d) \n',cStartInd,cEndInd,numel(individualsIndexList));
                resListTmp    = cell(numel(individualsIndexList),1);
                otherResultList    = cell(numel(individualsIndexList),1);
                fitnessListTmp = nan(numel(individualsIndexList),1);
                timeValuesTmp = nan(numel(individualsIndexList),1);
               
                individiualLoggerTmp = cell(1,numel(individualsIndexList));
                
                % fail safe evaluations (sometimes workers crash)                
                evalRoundFinished = 0;
                numberTries = 0;
                numberTriesMax = 5;                
                while ~evalRoundFinished && numberTries < numberTriesMax
                    numberTries = numberTries+1;
                    try
                        %warning('HERE SHOULD BE PARFOR!')
                        parfor ii = 1:numel(individualsIndexList) %----------- PARFOR

                            switchOffWarnings(); %supress numerical warnings
                            % get fresh data package
                            dataStruct = dataStructBase;
                            % new cross validation sets new generation 
                            if  dataStructBase.jobParams.crossValidationGenerateNewDivisions
                                % randomize cross validation set each
                                % generation using no dependency
                                % information
                                if ~isstruct(dataStructBase.jobParams.crossValidationInstanceDependencyInformation)
                                    dataStruct.crossValidationSets = generateCrossValidationIndexSets(dataStructBase.dataSet.nSamples,dataStructBase.jobParams.crossValidationK);
                                else
                                    dataStruct.crossValidationSets = generateCrossValidationIndexSetsDependency(dataStructBase.dataSet.nSamples,dataStructBase.jobParams.crossValidationK,dataStructBase.jobParams.crossValidationInstanceDependencyInformation);
                                end
                            end

                            dataStruct.classificationPipeline = ClassificationPipeline();
                            dataStruct.classificationPipeline.initParams(dataStruct.generalParams);

                            iConfig = individualsIndexList(ii);
                            cConfig = dataStruct.configurationList{iConfig};        

                            %%-- debug
        %                         featureSubSet=cConfig.configFeatureSelection.featureSubSet;
        %                         configString =  sprintf(' Individual %d/%d, %d Features Selected, Feature Transform: %s,  Classifier: %s', ...
        %                             iConfig, nIndividuals, sum(single(featureSubSet)), cConfig.configFeatureTransform.featureTransformMethod, ...
        %                             cConfig.configClassifier.classifierName);
        %                         fprintf('Config: %s \n',configString);
                            %---

                            tic
                            otherResults = [];
                            if evoOptProfBin == 0
                                % perform evol. grid search
                                if dataStruct.jobParams.extendedCrossValidation
                                    [resultsList, bestConfig, success, otherResults] = suboptimizerConfigEvolutionaryCV(cConfig, dataStruct);
                                else
                                    [resultsList, bestConfig, success, otherResults] = suboptimizerConfigEvolutionary(cConfig, dataStruct);
                                end
                            end
                            if evoOptProfBin == 1
                                % just evaluation of config, all parameters at inside
                                [resultsList, bestConfig, success, otherResults] = configEvalEvolutionary(cConfig, dataStruct);
                            end                
                            timePassed = toc();
                            configString =  sprintf(' Individual %d/%d, %s', iConfig, nIndividuals, configuration2string(cConfig));
                             if timePassed>120
                                slowMsg = 'SLOW CONFIG:';
                             else
                                slowMsg = ''; 
                             end
                             individualMsg =  sprintf('%s Processing Time %0.1f seconds for config: %s',slowMsg,timePassed, configString);
                             timeValuesTmp(ii) = timePassed;
                             individiualLoggerTmp{ii} = individualMsg;

                            if success
                                fitnessListTmp(ii) = bestConfig.bestQuality;
                                resListTmp{ii} = resultsList;  
                                otherResultList{ii} = otherResults;
                            end

                            % free memory
                            dataStruct = [];
                        end %------------------PARFOR END 
                        % success!
                        evalRoundFinished = 1;
                    catch me
                        % something went wrong
                        statisString = sprintf('PARFOR Evaluation crash number %d at evolutionary generation %d error: %s',numberTries,this.evoStratOpt.iEvolutionRound, me.message);
                        warning(statisString);
                        appendLog([this.generalParams.resultPathFinal 'log.txt'],statisString);
                        if numberTries >= numberTriesMax
                            error('PARFOR Evaluation crashing too often :( Stopping!')
                        else
                            %restart parpool
                            pause(3);                    
                            try  % most errors come from parallel pool, try to restart
                                delete(gcp('nocreate'));
                                pause(2);  
                            catch
                            end                                 
                            parallelTBHandler.restartParallelPool(true);
                        end
                        
                    end
                end
                %------------ evaluations done
                
                timeValues = [timeValues; timeValuesTmp];
                fitnessValues = [fitnessValues;fitnessListTmp];
                resultListAll = [resultListAll;resListTmp];
                otherResultsAll = [otherResultsAll; otherResultList];
                individiualLogger = [individiualLogger;individiualLoggerTmp'];
                clear resListTmp;                

                % update early rejection -> as soon as possible
                
                % update best quality so far
                % best in temp list -> List of results
                try
                    [maxVal,maxIdx] = max(fitnessValues);
                    if maxVal > 0
                        bestResultTmp= resultListAll{maxIdx};
                        % find best in list of best
                        bestQMeanThisGen = 0;
                        bestQStdThisGen = 1;
                        for iListTmp = 1:numel(bestResultTmp)
                            cResTmp = bestResultTmp{iListTmp};
                            if cResTmp.evaluationMetrics.accuracyOverallMean > bestQMeanThisGen
                                bestQMeanThisGen = cResTmp.evaluationMetrics.accuracyOverallMean;
                                bestQStdThisGen = cResTmp.evaluationMetrics.accuracyOverallStd;
                            end
                        end

                        bestQMeanLastGen = this.optimizationResultController.getCurrentBestQualityMetric();
                        bestQStdLastGen = this.optimizationResultController.getCurrentStdEstimation();

                        if bestQMeanThisGen > bestQMeanLastGen
                            dataStructBase.earlyDiscardingParams.bestQualityMean = bestQMeanThisGen;
                            dataStructBase.earlyDiscardingParams.bestQualityStd =  bestQStdThisGen;     
                        else
                            dataStructBase.earlyDiscardingParams.bestQualityMean = bestQMeanLastGen;
                            dataStructBase.earlyDiscardingParams.bestQualityStd =  bestQStdLastGen;                         
                        end
                        % update time
                        medianTimeEstimation = median(timeValues);
                        this.earlyDiscardingTimeLimitSecs = this.earlyDiscardingTimeLimitFactorMedian*medianTimeEstimation;                
                        dataStructBase.earlyDiscardingParams.timeLimitSeconds = this.earlyDiscardingTimeLimitSecs;                    
                    end
                catch
                    
                end
                
                %handle parallel TB
                parallelTBHandler.checkTimePassedAndRestartIfNecessary();
                
                % calculate new indices
                cStartInd = cEndInd+1;
                cEndInd = min(nIndividuals,cStartInd + individualsOtherRounds-1);
                % finish
                if cStartInd > nIndividuals
                    continueEvals = 0;
                end
            end
            
            [bestFitnessValue, bestIndex] = max(fitnessValues);
            fprintf('====> current best fitness: %0.4f \n',bestFitnessValue);
            
            % stats early discarding            
            discardingPercentagesAll = [];
            totalEvalSaved = [];
            evalRoundsAll = [];
            for iOR = 1:numel(otherResultsAll)
                cRes = otherResultsAll{iOR};
                if ~isempty(cRes)
                    discardingPercentagesAll = [discardingPercentagesAll; cRes.earlyDiscardingPercentages(:)];    
                    totalEvalSaved = [totalEvalSaved; cRes.nEvaluationsSaved(:)];
                    evalRoundsAll = [evalRoundsAll; cRes.nRoundsTotal(:)];
                end
            end
            if numel(discardingPercentagesAll) > 0
                averageRatioDiscarding = mean(discardingPercentagesAll);
                this.log(sprintf(' Early discarding saved evaluations ratio: %0.4f %% \n',100*(1-averageRatioDiscarding)));
            else
                averageRatioDiscarding = nan;
            end
            if numel(totalEvalSaved) > 0
                totalEvalSaved = sum(totalEvalSaved(:));
                totalEvals = sum(evalRoundsAll(:));
            else
                totalEvalSaved = nan;
                totalEvals = nan;
            end
            
            if this.appendConfigEvaluationsToFinalResultList
                dataItem = struct;
                dataItem.value = earlyDiscardingParams.bestQualityMean;   
                this.evoStratOpt.timeSeriesStorage.appendValue('EarlyDiscardingQualityMean', dataItem);
                dataItem = struct;
                dataItem.value = earlyDiscardingParams.bestQualityStd;   
                this.evoStratOpt.timeSeriesStorage.appendValue('EarlyDiscardingQualityStd', dataItem);

                dataItem = struct;
                dataItem.value = averageRatioDiscarding;   
                this.evoStratOpt.timeSeriesStorage.appendValue('EarlyDiscardingEvalRatio', dataItem);                
                dataItem = struct;
                dataItem.value = totalEvalSaved;   
                this.evoStratOpt.timeSeriesStorage.appendValue('EarlyDiscardingTotalEvalsSaved', dataItem);     
                dataItem = struct;
                dataItem.value = totalEvals;   
                this.evoStratOpt.timeSeriesStorage.appendValue('EarlyDiscardingTotalEvals', dataItem);    
                
                % log individuals
                appendLog([this.job.jobParams.resultPath 'individualLog.txt'], individiualLogger);
            end            
            
            % set external stop criterion for optimization
            this.evoStratOpt.externalStopCriterion = this.computationStopCriterion();            
            
            if this.appendConfigEvaluationsToFinalResultList 
                % append to time series for individual quality measurement
                for iConfig = 1:nIndividuals
                    cFitness = fitnessValues(iConfig);
                    if ~isnan(cFitness)
                        dataItem = struct;
                        dataItem.value = cFitness;
                        dataItem.individualConfig = configurationList{iConfig};
                        this.timeSeriesStorage.appendValue('QualityOffspring', dataItem);
                    end
                end
                % append to time series for best solution this generation
                dataItem = struct;
                dataItem.value = bestFitnessValue;
                dataItem.individualConfig = configurationList{bestIndex};
                this.timeSeriesStorage.appendValue('BestQualityOffspring', dataItem);

                % Save resultListAll to result handler
                for iIndividual=1:numel(resultListAll)
                    cResList = resultListAll{iIndividual};
                    for iConfig = 1:numel(cResList);
                        this.optimizationResultController.appendResult(cResList{iConfig})
                    end 
                end
            end
        end
        
        %__________________________________________________________________
        % get configuration from evolutionary properties
        function configurationList = configurationsFromEvolutionaryCoding(this,individualsList)

            configurationList = cell(numel(individualsList),1);
            baseConfig = ClassificationPipeline.getEmptyPipelineConfiguration(this.job.jobParams);
            
            for iInd = 1:numel(individualsList)
               cConfig = baseConfig;
               cIndividualProps = individualsList{iInd}.propertyValues;
                            
                evoOptProf = this.currentEvolutionaryProfile;
                if strcmp(evoOptProf,'EvolutionaryGridSearch')
                    evoOptProfBin = 0;
                elseif strcmp(evoOptProf,'EvolutionaryConfigurationAdaptation')
                    evoOptProfBin = 1;
                else
                    error('evoOptProf parameter not recognized');
                end
               
                if evoOptProfBin == 0 || evoOptProfBin == 1 
                   % feature selection
                   featureBitString = cIndividualProps{this.geneIdFeatureSelection};
                   cConfig.configFeatureSelection.featureSubSet = featureBitString; 
                end

                % feature pre processing methods
                if evoOptProfBin == 0 || evoOptProfBin == 1
                    cConfig.configPreprocessing.featurePreProcessingMethod = cIndividualProps{this.geneIdFeaturePreProcessing};
                end                
                
                if evoOptProfBin == 0 || evoOptProfBin == 1
                   % feature transform
                   featureTransformMethod = cIndividualProps{this.geneIdFeatureTransform};
                   cConfig.configFeatureTransform.featureTransformMethod = featureTransformMethod; 
                   
                    % append feature transform dimensionality estimation
                    cConfig.configFeatureTransform.featureTransformParams.estimateDimensionality = 0; % do not use PCA to estimate dimensionality
                    cConfig.configFeatureTransform.featureTransformParams.dimensionalityPercentage = cIndividualProps{this.geneIdFeatureTransformDimensionality};
                    
                    % read out hyperparameters
                    if this.featureTransfromHyperparamsActive
                       methodName = cIndividualProps{this.geneIdFeatureTransform};
                        cConfig.configFeatureTransform.featureTransformHyperparams = ...
                            this.getHyperparametersFromGeneCoding(this.evoStratOpt,cIndividualProps,methodName,this.geneIdsFeatureTransformHyperparams);                              
                    else
                        cConfig.configFeatureTransform.featureTransformHyperparams = struct;
                    end
                end
                
                if evoOptProfBin == 0 || evoOptProfBin == 1
                   % classifier
                   classifierMethod = cIndividualProps{this.geneIdClassifier};
                   cConfig.configClassifier.classifierName = classifierMethod;   
                end
                
                 if evoOptProfBin == 1
                   % classifier parameters from genes
                   methodName = cIndividualProps{this.geneIdClassifier};
                    cConfig.configClassifier.classifierParams = ...
                        this.getHyperparametersFromGeneCoding(this.evoStratOpt,cIndividualProps,methodName,this.geneIdsClassifierHyperparams);                    
                end               
                
               % append to list
               configurationList{iInd} = cConfig;
            end
        end        
        
        
        %__________________________________________________________________
        % get hyperparameters from gene coding
        function paramStruct = getHyperparametersFromGeneCoding(this,evoStratOpt,cIndividualProps,methodName,genomeIdInfoList)   
            
           paramStruct = struct;
           % first: find selected method in list
           methodIndex = 0;
           for iMeth=1:numel(genomeIdInfoList)
                if strcmp(methodName,genomeIdInfoList{iMeth}.methName)
                    methodIndex = iMeth;
                    break;
                end
           end
           if methodIndex > 0
               paramInfo = genomeIdInfoList{methodIndex};
               for iParam = 1:numel(paramInfo.paramGeneIndices)
                  cGeneIndex = paramInfo.paramGeneIndices(iParam);
                  paramValue = cIndividualProps{cGeneIndex};
                  genomeProperty = evoStratOpt.genomeInfo.genomePropertyList{cGeneIndex};
                  paramType = genomeProperty.addInfo.paramType;
                  paramName = genomeProperty.addInfo.parameterName;
                  % decode logarithmic exponent
                  if strcmp(paramType,'realLog10')
                      paramValue = 10^paramValue;
                  end
                  %append to parameter list
                  paramStruct.(paramName) = paramValue;
               end
           else
               error('Method not found in gene coding')
           end        
        end
        
        
        %__________________________________________________________________
        % finish optimization process
        function finishOptimization(this)
            disp('finishing results');
            % save time series
            timeSeriesFile = [this.job.jobParams.resultPath 'evolutionaryTimeSeries.mat'];
            this.evoStratOpt.timeSeriesStorage.saveToFile(timeSeriesFile);
            
            % other metrics
            this.aggregatedResults.initialOptimizationTime = this.initialOptimizationTime;            
            
            plotOptions = struct;
            plotOptions.showPlots = 0;
            plotOptions.exportPlot = 1;
            plotOptions.title = '';                     
            plotOptions.exportPlotFormat = 'pdf';   
            %plotOptions.exportPlotFormat = 'fig';   
            plotFolder = [this.job.jobParams.resultPath  filesep 'plots' filesep];
            [~, ~, ~] = mkdir(plotFolder);
            plotOptions.exportFileName = [plotFolder 'evoDev'];
            % diverse statistics
            StatisticsPlots.exportEvolutionaryTimeSeries1(this.evoStratOpt.timeSeriesStorage, plotOptions);
            StatisticsPlots.exportEvolutionaryTimeSeries2(this.evoStratOpt.timeSeriesStorage, plotOptions);
            StatisticsPlots.exportEvolutionaryTimeSeries3(this.evoStratOpt.timeSeriesStorage, plotOptions);
            StatisticsPlots.exportEvolutionaryTimeSeries4(this.evoStratOpt.timeSeriesStorage, plotOptions);
            
            % variable importance export (if available)
            if isfield(this.aggregatedResults,'initialImprovementData') && isfield(this.aggregatedResults.initialImprovementData,'variableImportances')
                destinationFolder =  [this.job.jobParams.resultPath ];
                featureNames = this.job.jobParams.dynamicComponents.componentsFeatureSelection;
                variableImportanceRandomForestExport(this.aggregatedResults.initialImprovementData.variableImportances, featureNames, destinationFolder);
            end
               
        end    
        
        
      end % end methods public ____________________________________________

      
      

end

        




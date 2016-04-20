% Class definition FrameworkParameterController
% This class controls the parameter of the framework and jobs
% to prevent to have undefined parameter values in structs
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef FrameworkParameterController < handle
    
    properties 
        
    end
    
    %====================================================================
    methods
         
%         % constructor
%         function obj = FrameworkParameterController()
%         end
        
      end % end methods public ____________________________________________
    
    
     methods(Static = true)
    
        %__________________________________________________________________
        % check framework parameters and fill useful standard parameters
        function paramsOut = checkGeneralParamters(paramsIn)
           paramsOut = struct;
           
           % result base folder
           paramsOut.resultPath = appendFileSep(queryStruct(paramsIn,'resultPath',[getUserDir() filesep 'mlFrameworkResults' filesep]));
           
           % a name inside of the folder to categorize the results
           paramsOut.analysisName = queryStruct(paramsIn,'analysisName','MLTraining');
           
           % continue analysis mode to restart any analysis
           paramsOut.analysisSaveState = queryStruct(paramsIn,'analysisSaveState',true);
           
           %parallel settings
           paramsOut.parallelToolboxActive = queryStruct(paramsIn,'parallelToolboxActive',true);
           paramsOut.parallelToolboxNumberWorkers = queryStruct(paramsIn,'parallelToolboxNumberWorkers',2);
           paramsOut.parallelToolboxSaveMemory = queryStruct(paramsIn,'parallelToolboxSaveMemory',true); % shut pool down after every job
           
           % this is a number in range {0 1 2} and denotes increasing level
           % of verbosity
           paramsOut.verbosityLevel = queryStruct(paramsIn,'verbosityLevel',1);
          
           % this flag enables specific development options/exports
           paramsOut.developmentMode = queryStruct(paramsIn,'developmentMode',false);  
           
           % store cross validation sets (just index divsions) in a global dataset to prevent
           % noise influence from different sets
           paramsOut.storeCrossValidationSetsGlobally = queryStruct(paramsIn,'storeCrossValidationSetsGlobally',true);    
           
           % retrain classifiers on pipeline state recovery (for safety)
           paramsOut.retrainClassifierOnStateRecovery = queryStruct(paramsIn,'retrainClassifierOnStateRecovery',false);      
           
           % activated advanced time measurements for slow methods -> console
           paramsOut.advancedTimeMeasurements = queryStruct(paramsIn,'advancedTimeMeasurements',0);     
           % time threshold in seconds for a slow method
           paramsOut.timeThreshSlow = queryStruct(paramsIn,'timeThreshSlow',60);   
           
           % function with one argument that is called at the end of the
           % analysis
           paramsOut.analysisFinishFunction = queryStruct(paramsIn,'analysisFinishFunction',''); 
                                   
        end
        
 
        %__________________________________________________________________
        % check common parameters of trianing jobs 
        function [paramsOut, validConfig, dataSetOut] = checkTrainingJobParameters(paramsIn, dataSetIn)
           paramsOut = struct;
           validConfig = 1;
                  
           % strategy class for training
           paramsOut.optimizationStrategy = queryStruct(paramsIn,'optimizationStrategy','EvolutionaryConfigurationAdaptation');             
           % check validity of training strategy
           components = frameworkComponentLists();
           if ~cellStringsContainString(components.optimizationStrategyList,paramsOut.optimizationStrategy)
                warning('Optimization strategy %s not found.',paramsOut.optimizationStrategy);
                validConfig = 0;
                return;
           end
           
           % a job may have a description
           paramsOut.jobDescription = queryStruct(paramsIn,'jobDescription','');
           
            % number repetitions
           paramsOut.nRepetitions = queryStruct(paramsIn,'nRepetitions',1);          
           
           % a job may have group info (e.g. dataset 2/6 with parameterset
           % 4/5)
           paramsOut.jobGroupInfo = queryStruct(paramsIn,'jobGroupInfo',struct);
           
           % plot ranges of features and export to result folder
           paramsOut.performFeatureDistributionAnalysis = queryStruct(paramsIn,'performFeatureDistributionAnalysis',false);            
           
           % preprocessing method for heuristic grid search
           paramsOut.featurePreProcessingMethod = queryStruct(paramsIn,'featurePreProcessingMethod','featureScalingStatistically');           
           
           % split high dimensional features into one dimensional features
           paramsOut.splitMultiChannelFeatures = queryStruct(paramsIn,'splitMultiChannelFeatures',true);            
           
           % define a computation time limit
           paramsOut.stopCriterionComputingTimeHours = queryStruct(paramsIn,'stopCriterionComputingTimeHours',24); 
           
           % define a quality threshold level which is sufficient to stop
           paramsOut.stopCriterionGoalQualityMetric = queryStruct(paramsIn,'stopCriterionGoalQualityMetric',inf);           
           
           % define a maximum number of evaluated iterations
           paramsOut.stopCriterionIterationNumber = queryStruct(paramsIn,'stopCriterionIterationNumber',inf);            
           
           % cross validation settings
           paramsOut.performCrossValidation = queryStruct(paramsIn,'performCrossValidation',true);
           % number of cross validation rounds (standard is k=5)
           paramsOut.crossValidationK = queryStruct(paramsIn,'crossValidationK',5);
           
           % include feature transform out of sample extension into cross
           % validation process (otherwise only classifier will be cross
           % validated) (holisticCVactive)
           paramsOut.extendedCrossValidation = queryStruct(paramsIn,'extendedCrossValidation',1);     
           
           % add additional information about instance dependencies: either
           % empty or a vector with NT numbers pointing at the original,
           % unique indicies
           paramsOut.crossValidationInstanceDependencyInformation = queryStruct(paramsIn,'crossValidationInstanceDependencyInformation',[]);  
           if ~isempty(paramsOut.crossValidationInstanceDependencyInformation) 
                indexInfo = paramsOut.crossValidationInstanceDependencyInformation(:);
                % check
                if (numel(indexInfo) == numel(dataSetIn.targetClasses))
                    paramsOut.crossValidationInstanceDependencyInformation = struct;
                    paramsOut.crossValidationInstanceDependencyInformation.indexInfo = indexInfo;
                    paramsOut.crossValidationInstanceDependencyInformation.indexInfoUnique = unique(indexInfo);
                else
                    warning('Dataset problem: Invalid crossValidationInstanceDependencyInformation: must contain as many indices as instances!');
                    validConfig = 0;
                    return;    
                end
               
           end
           
           
           % use new division sets (1) or use cached cross validation division (0)
           %paramsOut.crossValidationGenerateNewDivisions = queryStruct(paramsIn,'crossValidationGenerateNewDivisions',1);       
           paramsOut.crossValidationGenerateNewDivisions = 1; % this always set
                      
           % stop cross validation round if the first rounds are already bad (earlyDiscarding)
           paramsOut.crossValidationEarlyDiscarding = queryStruct(paramsIn,'crossValidationEarlyDiscarding',1);  
           
           % significance level for stopping cross validation
           paramsOut.crossValidationEarlyDiscardingSignificance = queryStruct(paramsIn,'crossValidationEarlyDiscardingSignificance',0);  % 1.28 for 10% of error, 0 for variant: current mean must be always better than last mean
           
            % use time criterion for stopping cross validation
           paramsOut.crossValidationEarlyDiscardingTimeCriterion = queryStruct(paramsIn,'crossValidationEarlyDiscardingTimeCriterion',0);            
           
           % create a multi pipeline classifier
           paramsOut.multiPipelineTraining = queryStruct(paramsIn,'multiPipelineTraining',1);   

           % after training of a multi pipeline system, validate it with a
           % test dataSet
           paramsOut.multiPipelineTestDataSet = queryStruct(paramsIn,'multiPipelineTestDataSet',[]);   
           
           % after training of a multi pipeline system, validate it with a
           % test dataSet
           multiPipelineStandardParams = struct;
           multiPipelineStandardParams.multiClassifierNPipelinesMax = 50;
           multiPipelineStandardParams.multiClassifierFromCrossValidation = 0; % train k classifiers and fuse the results
           paramsOut.multiPipelineParameter = queryStruct(paramsIn,'multiPipelineParameter',multiPipelineStandardParams);              
           
           % objective function (to rank evaluations)
           % implement new ones in class TrainingStrategy.getQualityMetricFormEvaluation
           paramsOut.evaluationQualityMetric = queryStruct(paramsIn,'evaluationQualityMetric','overallAccuracy');

           % define strategy dependent parameters as struct (each strategy
           % has its own standard values)
           paramsOut.optimizationStrategyParameters = queryStruct(paramsIn,'optimizationStrategyParameters',struct);   
           
           % components for feature selection (feature channels to be used)
           paramsOut.optimizationComponentsFeatureSelection = queryStruct(paramsIn,'optimizationComponentsFeatureSelection','*'); 
           
           % components for feature preprocessing
           paramsOut.optimizationComponentsFeaturePreprocessing = queryStruct(paramsIn,'optimizationComponentsFeaturePreprocessing','*');            
           
           % amount of optimization components for feature transform element (default all active)
           paramsOut.optimizationComponentsFeatureTransform = queryStruct(paramsIn,'optimizationComponentsFeatureTransform','*');     
           
           % optimization for feature transform hyperparameters (in ECA-full only)
           paramsOut.optimizationComponentsFeatureTransformHyperParams = queryStruct(paramsIn,'optimizationComponentsFeatureTransformHyperParams',true);             
           
           % amount of optimization components for classifier element (default all active)
           paramsOut.optimizationComponentsClassifier = queryStruct(paramsIn,'optimizationComponentsClassifier','*'); 
           
           % optimization for classifier hyperparameters (this variable affects ECA-full only)
           paramsOut.optimizationComponentsClassifierHyperParams = queryStruct(paramsIn,'optimizationComponentsClassifierHyperParams',true);              
           
           % amount of parameter search space (either 1,2 or 3)
           paramsOut.optimizationParameterAmount = queryStruct(paramsIn,'optimizationParameterAmount',2);         
           
           if paramsOut.optimizationParameterAmount < 1 || paramsOut.optimizationParameterAmount > 3
                paramsOut.optimizationParameterAmount = 2;
           end            
           
           % check and prepare dataSet
            [dataSetOut,skipDataSet] = DataSetPreparation.checkDataSet(dataSetIn,paramsOut);
           if skipDataSet
                warning('Dataset problem!');
                validConfig = 0;
                return;
           end
           
           % prior maximum dimensionality
           paramsOut.featureTransformDimensionPrior= queryStruct(paramsIn,'featureTransformDimensionPrior',50);   
           
           % calculate dynamic framework components 
           paramsOut.dynamicComponents = FrameworkParameterController.getDynamicComponentsAndParametersForJob(paramsOut);
           % feature selection should be a dynamic part too!
           paramsOut.dynamicComponents.componentsFeatureSelection = {};
           
           if ~iscell(paramsOut.optimizationComponentsFeatureSelection)
               if strcmp(paramsOut.optimizationComponentsFeatureSelection,'*')
                   % take all features if * is provided
                     paramsOut.dynamicComponents.componentsFeatureSelection = dataSetOut.featureNames;
               else
                    error('optimizationComponentsFeatureSelection must be either a cell array or a "*"');
               end
           else
               for ii=1:numel(paramsOut.optimizationComponentsFeatureSelection)
                    cFeatName = paramsOut.optimizationComponentsFeatureSelection{ii};
                    if cellStringsContainString(dataSetOut.featureNames,cFeatName)
                        % check if feature exists
                        paramsOut.dynamicComponents.componentsFeatureSelection{end+1} = cFeatName;
                    else
                        warning('The data set does not include feature %s. Skipping!',cFeatName);
                        pause(5);
                    end
               end               
           end
           
           if numel(paramsOut.dynamicComponents.componentsFeatureSelection) == 0
                validConfig = 0;
                warning('No features selected for optimization. Pass "*" to optimizationComponentsFeatureSelection to use all features.');
           end

           
                     
           
        end        
        
        
        
        %__________________________________________________________________
        % select components of framework
        %
        function dynamicComponents = getDynamicComponentsAndParametersForJob(params)
            dynamicComponents = struct;
            allFrameworkComponents = frameworkComponentLists();
            
            % feature preprocessing
            allPreProcMeths = allFrameworkComponents.featurePreProcessingMethods.options;
            if iscell(params.optimizationComponentsFeaturePreprocessing)
                dynamicComponents.componentsFeaturePreProcessing = {};
                for ii=1:numel(params.optimizationComponentsFeaturePreprocessing)
                    cPreMeth = params.optimizationComponentsFeaturePreprocessing{ii};
                    if cellStringsContainString(allPreProcMeths,cPreMeth)
                        dynamicComponents.componentsFeaturePreProcessing{end+1} = cPreMeth;
                    else
                        warning('Preprocessing Method %s not recognized!',cPreMeth);
                    end
                end
            else
                % just use all if '*' is passed
                dynamicComponents.componentsFeaturePreProcessing = allPreProcMeths;
            end
            
            % feature transform components
            componentsFeatureTrans = allFrameworkComponents.featureTransformMethods;
            dynamicComponents.componentsFeatureTransSelection = FrameworkParameterController.getComponentAndParameterSelection(...
                componentsFeatureTrans,params.optimizationComponentsFeatureTransform, ...
                params.optimizationParameterAmount);
            
            % classifier components
            componentsClassifier = allFrameworkComponents.classifiers;
            dynamicComponents.componentsClassifierSelection = FrameworkParameterController.getComponentAndParameterSelection(...
                componentsClassifier,params.optimizationComponentsClassifier, ...
                params.optimizationParameterAmount);            
 
        end
        
        
        
        
        %__________________________________________________________________
        % get a selection of dynamic components and corresponding parameters 
        % based on all available components from frameworkComponentLists and a selection
        function componentsAndParameters = getComponentAndParameterSelection(allComponentsStruct,componentSelection,parameterAmount)
            componentsAndParameters = {};
            
            if ~iscell(componentSelection)
                if strcmp(componentSelection,'*')
                    % selection of all components (all fields of struct)
                    componentSelection = fieldnames(allComponentsStruct);
                else
                    error('Invalid component specifier. Use * to get all components!');
                end
            end
            
            % loop all components
            for ii=1:numel(componentSelection)
                cComp = componentSelection{ii};
                compInfo = getfield(allComponentsStruct,cComp);
                if compInfo.active
                    % add component
                    component = struct;
                    component.name = compInfo.name;
                    component.displayName = compInfo.displayName;
                    component.parameterRanges = {};
                    if isfield(compInfo,'params')
                        parametersNames = fieldnames(compInfo.params);
                        for iPar = 1:numel(parametersNames)
                           cParamName = parametersNames{iPar}; 
                           cParamInfo = getfield(compInfo.params,cParamName);
                           % this shall be a cell array
                           allvalueRanges = cParamInfo.gridValues;
                           if numel(allvalueRanges) == 3
                            values = allvalueRanges{parameterAmount};
                           else
                            values = allvalueRanges{1};
                            warning('frameworkComponentLists: Parameter %s does not specify 3 parameter ranges.',cParamName);
                           end
                           paramItem = struct;
                           paramItem.name = cParamName;
                           paramItem.values = values;
                           paramItem.standardValue = cParamInfo.standardValue;
                           % append parameter range info (for evolutionary
                           % algo)
                           if isfield(cParamInfo,'paramDescription')
                               paramItem.paramType = cParamInfo.paramDescription.type;
                               paramItem.paramRange = cParamInfo.paramDescription.range;
                           end
                           component.parameterRanges{end+1} = paramItem; 
                        end                        
                    end
                    componentsAndParameters{end+1} = component;
                end
            end
            
            
        end
                
        
        
      end % end methods static ____________________________________________
                
    

    
    
end

        

        

% ----- helper -------


% get directory of user
function userdir=getUserDir()
    if ispc
        userdir= getenv('USERPROFILE');
    else 
        userdir= getenv('HOME');
    end
end




% function jobParameterList = frameworkJobProfiles(profileList,commonParams)
% Get framework job parameters from given profile string ids in form of a 
% cell string profileList. These can be:
% ------ GRID SEARCH ---------------------
% - 'BaselineSVM': Baseline Gauss SVM with HyperParameter optimization
%   (C,gamma), no feature selection
% - 'BaselineRandomForest'  Baseline Random Forest with HyperParameter 
%   optimization (number trees), no feature selection
% - 'RandomSearch': Randomly search of Feature Selection, Feature Transform, 
%        Classifier and classifier HyperParameter without grid 
%        (continuous parameter intervals) 
% - 'EvolutionaryGridSearch': EGS - Evolutionary Optimization with Feature
%        Selection, Feature Preprocessing, Feature Transform, Classifier Coding and Grid Search
%        for HyperParameter.
% - 'EvolutionaryConfigurationAdaptation': ACA - Full Evolutionary Optimization:
%        Selection, Feature Preprocessing, Feature Transform, Classifier and classifier HyperParameter
%        without grid (continuous parameter intervals) 
%
% Optionally, commonParamsIn is a struct with common parameters. If not
% passed, standard parameters are used. List of common parameters and
% values can be found in line 36.
%

function jobParameterList = frameworkJobProfiles(profileList,metaParamsIn)

jobParameterList = {};

if ~iscell(profileList)
    profileList = {profileList};
end
 
if nargin == 1
    metaParamsIn = struct;
end

% meta parameters and standard values/options
commonParams = struct;
%standard parameters
commonParams.metaParameterDescription = queryStruct(metaParamsIn,'metaParameterDescription','');  % describe metaparameters more precisely and identifiy it later
commonParams.nRepetitions = queryStruct(metaParamsIn,'nRepetitions',1);  % number repetitions for each job (statistically more relevant results)
commonParams.splitMultiChannelFeatures = queryStruct(metaParamsIn,'splitMultiChannelFeatures',1); % 0 or 1
commonParams.performFeatureDistributionAnalysis = queryStruct(metaParamsIn,'performFeatureDistributionAnalysis',0); % 0 or 1 (just statistical plots/analysis)

%components for optimization
commonParams.optimizationComponentsFeatureSelection = queryStruct(metaParamsIn,'optimizationComponentsFeatureSelection','*'); % '*' or specific subset
commonParams.featureSelectionStrategy = queryStruct(metaParamsIn,'featureSelectionStrategy','on');  % 'on' or 'allFeatures'-> off/use all features
commonParams.optimizationComponentsFeatureTransform = queryStruct(metaParamsIn,'optimizationComponentsFeatureTransform','*'); % new standard: all
commonParams.optimizationComponentsFeatureTransformHyperParams = queryStruct(metaParamsIn,'optimizationComponentsFeatureTransformHyperParams',true); % only in ECA
commonParams.optimizationComponentsClassifierHyperParams = queryStruct(metaParamsIn,'optimizationComponentsClassifierHyperParams',true); % only in ECA
commonParams.optimizationComponentsFeaturePreprocessing = queryStruct(metaParamsIn,'optimizationComponentsFeaturePreprocessing','*'); % 
commonParams.optimizationComponentsClassifier = queryStruct(metaParamsIn,'optimizationComponentsClassifier','*');
commonParams.optimizationParameterAmount = queryStruct(metaParamsIn,'optimizationParameterAmount',2); % 1,2,3  (low, medium, high) only for EGS strategy

% target metrics
commonParams.evaluationQualityMetric = queryStruct(metaParamsIn,'evaluationQualityMetric','overallAccuracy');
commonParams.stopCriterionComputingTimeHours = queryStruct(metaParamsIn,'stopCriterionComputingTimeHours',12); 
commonParams.performCrossValidation = queryStruct(metaParamsIn,'performCrossValidation',1); 
commonParams.stopCriterionGoalQualityMetric =  queryStruct(metaParamsIn,'stopCriterionGoalQualityMetric',inf); 
commonParams.stopCriterionIterationNumber =  queryStruct(metaParamsIn,'stopCriterionIterationNumber',inf); 
commonParams.crossValidationK = queryStruct(metaParamsIn,'crossValidationK',5); 
commonParams.extendedCrossValidation = queryStruct(metaParamsIn,'extendedCrossValidation',true);  % use feature transform and classifier in crossvalidation (holisticCVactive)
commonParams.crossValidationEarlyDiscarding = queryStruct(metaParamsIn,'crossValidationEarlyDiscarding',1); % stop cross validation rounds if the first round is already bad (earlyDiscarding)
% crossValidationEarlyDiscardingSignificance 0 = current mean must be
% better than last one to go on with evaluation (fastest), 1.28=10%, 1.96=2,5% error
% confidence interval
commonParams.crossValidationEarlyDiscardingSignificance = queryStruct(metaParamsIn,'crossValidationEarlyDiscardingSignificance',0); 
% instance dependency information
commonParams.crossValidationInstanceDependencyInformation = queryStruct(metaParamsIn,'crossValidationInstanceDependencyInformation',[]); 

% multi pipeline analysis / test data
commonParams.multiPipelineTraining = queryStruct(metaParamsIn,'multiPipelineTraining',true);  % make multi classifier system
commonParams.multiPipelineParameter = queryStruct(metaParamsIn,'multiPipelineParameter',struct); 

%__________________________________________________________________________
% Profile Baseline (SVM), Gaussian SVM + HyperParameter tuning
profileId = 'BaselineSVM';
if cellStringsContainString(profileList,profileId)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams,profileId);
    
    % training function
    jobParams.optimizationStrategy = 'StrategyGridSearch'; 
    % amount of parameters/components
    jobParams.featurePreProcessingMethod = queryStruct(metaParamsIn,'featurePreProcessingMethod','none'); % no preprocessing methods
    jobParams.optimizationComponentsFeatureTransform = {'none'};
    jobParams.optimizationComponentsClassifier = {'ClassifierSVMGauss'};
    %jobParams.nRepetitions = 1; %
    %--- specific training stratgey sub parameters
    strategyParameters = struct;
    strategyParameters.featureSelectionStrategy = 'allFeatures'; % no feature selection
    jobParams.optimizationStrategyParameters = strategyParameters;
    
    % add to list
    jobParameterList{end+1} = jobParams;
end


%__________________________________________________________________________
% Profile Baseline (RandomForest), RandomForest + HyperParameter tuning
profileId = 'BaselineRandomForest';
if cellStringsContainString(profileList,profileId)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams,profileId);
    
    % training function
    jobParams.optimizationStrategy = 'StrategyGridSearch'; 
    jobParams.featurePreProcessingMethod = queryStruct(metaParamsIn,'featurePreProcessingMethod','none'); % no preprocessing methods
    % amount of parameters/components
    jobParams.optimizationComponentsFeatureTransform = {'none'};
    jobParams.optimizationComponentsClassifier = {'ClassifierRandomForest'};

    %--- specific training stratgey sub parameters
    strategyParameters = struct;
    strategyParameters.featureSelectionStrategy = 'allFeatures'; % no feature selection
    jobParams.optimizationStrategyParameters = strategyParameters;
    
    % add to list
    jobParameterList{end+1} = jobParams;
end




%__________________________________________________________________________
% Evolutionary Grid Search EGS
% Feature Selection + Feature Transform + Classifier,
% Grid Search for HyperParameter
profileId = 'EvolutionaryGridSearch';
if cellStringsContainString(profileList,profileId)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams,profileId);

    % training function
    jobParams.optimizationStrategy = 'StrategyEvolutionary'; 

    %--- specific training stratgey sub parameters
    strategyParameters = getEvolutionaryParameters('EvolutionaryGridSearch',metaParamsIn);
    jobParams.optimizationStrategyParameters = strategyParameters;
    
    % add to list
    jobParameterList{end+1} = jobParams;

end



%__________________________________________________________________________
% Evolutionary Configuration Adaptation (ECA) with full components / old name CES
% Feature Selection + Feature Preprocessing + Feature Transform +
% Classifier + HyperParameters

profileIds = {'EvolutionaryConfigurationAdaptation', 'EvolutionaryConfigurationAdaptation-Full', 'ECA', 'ECA-full'};
if cellStringsContainStrings(profileList,profileIds)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams,'ECA-full');
    
    % training function
    jobParams.optimizationStrategy = 'StrategyEvolutionary'; 

    %--- specific training stratgey sub parameters
    strategyParameters = getEvolutionaryParameters('EvolutionaryConfigurationAdaptation',metaParamsIn);    
    jobParams.optimizationStrategyParameters = strategyParameters;
    
    % add to list
    jobParameterList{end+1} = jobParams;
end


%__________________________________________________________________________
% Evolutionary Configuration Adaptation (ECA) Variant multi classifier
profileIds = { 'EvolutionaryConfigurationAdaptation-multiClassifier', 'ECA-multiClassifier'};
if cellStringsContainStrings(profileList,profileIds)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams,'ECA-multiClassifier');

    % training function
    jobParams.optimizationStrategy = 'StrategyEvolutionary'; 
    
    jobParams.optimizationComponentsFeaturePreprocessing = {'none'};    
    jobParams.optimizationComponentsFeatureTransform = {'none'};    
    
    %--- specific training stratgey sub parameters
    strategyParameters = getEvolutionaryParameters('EvolutionaryConfigurationAdaptation',metaParamsIn);    
    strategyParameters.featureSelectionStrategy = 'allFeatures'; % no feature selection
    jobParams.optimizationStrategyParameters = strategyParameters;
    
    % add to list
    jobParameterList{end+1} = jobParams;
end




%__________________________________________________________________________
% Evolutionary Configuration Adaptation (ECA) Variant only feature
% selection and one classifier tuned
profileIds = { 'EvolutionaryConfigurationAdaptation-featSel', 'ECA-featSel'};
if cellStringsContainStrings(profileList,profileIds)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams,'ECA-featSel');

    % training function
    jobParams.optimizationStrategy = 'StrategyEvolutionary'; 
    
    jobParams.optimizationComponentsFeaturePreprocessing = {'none'};    
    jobParams.optimizationComponentsFeatureTransform = {'none'};    
    jobParams.optimizationComponentsClassifier = {'ClassifierSVMGauss'};
    
    %--- specific training stratgey sub parameters
    strategyParameters = getEvolutionaryParameters('EvolutionaryConfigurationAdaptation',metaParamsIn);    
    jobParams.optimizationStrategyParameters = strategyParameters;
    
    % add to list
    jobParameterList{end+1} = jobParams;
end




%__________________________________________________________________________
% Evolutionary Configuration Adaptation (ECA) Variant No feature selection
profileIds = { 'EvolutionaryConfigurationAdaptation-noFeatSel', 'ECA-noFeatSel'};
if cellStringsContainStrings(profileList,profileIds)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams,'ECA-noFeatSel');

    % training function
    jobParams.optimizationStrategy = 'StrategyEvolutionary'; 
    
    %--- specific training stratgey sub parameters
    strategyParameters = getEvolutionaryParameters('EvolutionaryConfigurationAdaptation',metaParamsIn);    
    strategyParameters.featureSelectionStrategy = 'allFeatures'; % no feature selection
    jobParams.optimizationStrategyParameters = strategyParameters;
    
    % add to list
    jobParameterList{end+1} = jobParams;
end


%__________________________________________________________________________
% Evolutionary Configuration Adaptation (ECA) Variant no preprocessing
profileIds = { 'EvolutionaryConfigurationAdaptation-noPreProc', 'ECA-noPreProc'};

if cellStringsContainStrings(profileList,profileIds)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams,'ECA-noPreProc');

    % training function
    jobParams.optimizationStrategy = 'StrategyEvolutionary'; 
    jobParams.optimizationComponentsFeaturePreprocessing = {'none'};
    
    %--- specific training stratgey sub parameters
    strategyParameters = getEvolutionaryParameters('EvolutionaryConfigurationAdaptation',metaParamsIn);    
    jobParams.optimizationStrategyParameters = strategyParameters;
    % add to list
    jobParameterList{end+1} = jobParams;
end

%__________________________________________________________________________
% Evolutionary Configuration Adaptation (ECA) Variant no feature transform
profileIds = { 'EvolutionaryConfigurationAdaptation-noFeatTrans', 'ECA-noFeatTrans'};

if cellStringsContainStrings(profileList,profileIds)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams,'ECA-noFeatTrans');

    % training function
    jobParams.optimizationStrategy = 'StrategyEvolutionary'; 
    jobParams.optimizationComponentsFeatureTransform = {'none'};
    
    %--- specific training stratgey sub parameters
    strategyParameters = getEvolutionaryParameters('EvolutionaryConfigurationAdaptation',metaParamsIn);    
    jobParams.optimizationStrategyParameters = strategyParameters;
    % add to list
    jobParameterList{end+1} = jobParams;
end

%__________________________________________________________________________
% Evolutionary Configuration Adaptation (ECA) Variant only simple naive
% bayes classifier
profileIds = { 'EvolutionaryConfigurationAdaptation-linearClassifier', 'ECA-simpleClassifier'};

if cellStringsContainStrings(profileList,profileIds)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams, 'ECA-simpleClassifier');

    % training function
    jobParams.optimizationStrategy = 'StrategyEvolutionary'; 
    jobParams.optimizationComponentsClassifier = {'ClassifierNaiveBayes'};
    
    %--- specific training stratgey sub parameters
    strategyParameters = getEvolutionaryParameters('EvolutionaryConfigurationAdaptation',metaParamsIn);    
    jobParams.optimizationStrategyParameters = strategyParameters;
    % add to list
    jobParameterList{end+1} = jobParams;
end

%__________________________________________________________________________
% Evolutionary Configuration Adaptation (ECA) Variant no hyperparameter
% adaptation
profileIds = { 'EvolutionaryConfigurationAdaptation-defaultHyperparams', 'ECA-defaultHyperparams'};

if cellStringsContainStrings(profileList,profileIds)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams, 'ECA-defaultHyperparams');

    % training function
    jobParams.optimizationStrategy = 'StrategyEvolutionary'; 
    jobParams.optimizationComponentsFeatureTransformHyperParams = 0;
    jobParams.optimizationComponentsClassifierHyperParams = 0;
    
    %--- specific training stratgey sub parameters
    strategyParameters = getEvolutionaryParameters('EvolutionaryConfigurationAdaptation',metaParamsIn);    
    jobParams.optimizationStrategyParameters = strategyParameters;
    % add to list
    jobParameterList{end+1} = jobParams;
end




%__________________________________________________________________________
% Dense grid search vor visualization
profileId = 'StrategyDenseGridSearch';
if cellStringsContainString(profileList,profileId)
    % fill job group info
    jobParams = getJobGroupInfo(commonParams,profileId);
    jobParams.featurePreProcessingMethod = queryStruct(metaParamsIn,'featurePreProcessingMethod','none'); % no preprocessing methods
    % training function
    jobParams.optimizationStrategy = 'StrategyDenseGridSearch'; 

    %--- specific training stratgey sub parameters   
    jobParams.optimizationStrategyParameters =  queryStruct(metaParamsIn,'optimizationStrategyParameters',struct);
    
    % add to list
    jobParameterList{end+1} = jobParams;
end



%=============================================================================================================

% helper of evolutionary parameters. profileBaseId is 'EGS' or 'CES'
% the main parameters can be passed in metaParamsIn
function strategyParameters = getEvolutionaryParameters(profileBaseId,metaParamsIn)
strategyParameters = struct;


if strcmp(profileBaseId,'EvolutionaryGridSearch') % evolutionary grid search
    strategyParameters.evoOptProfile =  'EvolutionaryGridSearch';  %<! switch Feature Selection + Feature Transform + Classifier    
    strategyParameters.searchMode = 'evolutionary';
        
    strategyParameters.evoOptNIndividualsInitial = queryStruct(metaParamsIn,'evoOptNIndividualsInitial',100); %     % initial random population
    strategyParameters.evoOptNOptimizationGenerations = queryStruct(metaParamsIn,'evoOptNOptimizationGenerations',10000); % max generations 
    strategyParameters.evoOptNParentsPerChild = queryStruct(metaParamsIn,'evoOptNParentsPerChild',3);           % rho 
    strategyParameters.evoOptNChildrenPerGeneration = queryStruct(metaParamsIn,'evoOptNChildrenPerGeneration',50); %   % lambda (each round new children)
    strategyParameters.evoOptGenerationPopulationSize = queryStruct(metaParamsIn,'evoOptGenerationPopulationSize',25); %  % mu (new generation selection)
    
    strategyParameters.evoOptNumberMinGenerations =queryStruct(metaParamsIn,'evoOptNumberMinGenerations',5); % minimal number of generations to be performed 
    strategyParameters.evoOptStopCriterionNumberGenerationsWithNoImprovement = queryStruct(metaParamsIn,'evoOptStopCriterionNumberGenerationsWithNoImprovement',3);    % the quality is monitored and if no changes after this amount of generations it stops
    strategyParameters.evoOptMaxIndiviualAge = queryStruct(metaParamsIn,'evoOptMaxIndiviualAge',4); % Limited individual age in generations (kappa), if inf this is switched off
    
    strategyParameters.evoOptNumberHighPressureGenerations = queryStruct(metaParamsIn,'evoOptNumberHighPressureGenerations',0);  % how many rounds with high pressure (no standard option)  
    strategyParameters.evoOptGenerationPopulationSizeHighPressure = queryStruct(metaParamsIn,'evoOptGenerationPopulationSizeHighPressure',10);  % mu for last rounds (high pressure rounds) (no standard option)
    
    strategyParameters.featureSelectionStrategy = queryStruct(metaParamsIn,'featureSelectionStrategy','evolutionary'); % 'evolutionary' or 'allFeatures'
    if strcmp(strategyParameters.featureSelectionStrategy,'on')
        strategyParameters.featureSelectionStrategy = 'evolutionary';
    end    

    % intial population improvement (initPopImpr)
    strategyParameters.evoOptInitialPopulationImprovement = queryStruct(metaParamsIn,'evoOptInitialPopulationImprovement','randomForestVariableImportance'); % method = {'randomForestVariableImportance','evolutionaryFeatureOptimization','none'}
    
    evoTestMode = queryStruct(metaParamsIn,'evoTestMode',0);
    if evoTestMode
        warning('TEST mode EvolutionaryGridSearch')
        strategyParameters.evoOptNOptimizationGenerations = 6;
        strategyParameters.evoOptNIndividualsInitial = 20;
        strategyParameters.evoOptNChildrenPerGeneration = 10;
        strategyParameters.evoOptGenerationPopulationSize = 10;
    end    
    
    % mutation parameters (base)    
    strategyParameters.evoOptMutationParams = getStandardMutationParameters();           
end

if strcmp(profileBaseId,'EvolutionaryConfigurationAdaptation')  % complete evolutionary
    strategyParameters.evoOptProfile = 'EvolutionaryConfigurationAdaptation';  %<! switch Feature Selection + Feature Preprocessing + Feature Transform + Classifier+Parameter

    strategyParameters.searchMode = 'evolutionary';
    
    strategyParameters.evoOptNIndividualsInitial = queryStruct(metaParamsIn,'evoOptNIndividualsInitial',400); % initial random population
    strategyParameters.evoOptNOptimizationGenerations = queryStruct(metaParamsIn,'evoOptNOptimizationGenerations',10000); % max generations 
    strategyParameters.evoOptNParentsPerChild = queryStruct(metaParamsIn,'evoOptNParentsPerChild',3);           % rho 
    strategyParameters.evoOptNChildrenPerGeneration =queryStruct(metaParamsIn,'evoOptNChildrenPerGeneration',200); % lambda (each round new children) (was 200 previously)
    strategyParameters.evoOptGenerationPopulationSize =queryStruct(metaParamsIn,'evoOptGenerationPopulationSize',20);  % mu (new generation selection)

    strategyParameters.evoOptNumberMinGenerations =queryStruct(metaParamsIn,'evoOptNumberMinGenerations',5); % minimal number of generations to be performed  
    strategyParameters.evoOptStopCriterionNumberGenerationsWithNoImprovement =queryStruct(metaParamsIn,'evoOptStopCriterionNumberGenerationsWithNoImprovement',3);    % the quality is monitored and if no changes after this amount of generations it stops    
    strategyParameters.evoOptMaxIndiviualAge =queryStruct(metaParamsIn,'evoOptMaxIndiviualAge',4); % Limited individual age in generations (kappa), if inf this is switched off  
    
    strategyParameters.evoOptNumberHighPressureGenerations =queryStruct(metaParamsIn,'evoOptNumberHighPressureGenerations',0);  % how many rounds with high pressure (no standard option)     
    strategyParameters.evoOptGenerationPopulationSizeHighPressure =queryStruct(metaParamsIn,'evoOptGenerationPopulationSizeHighPressure',10);  % mu for last rounds (high pressure) (no standard option)
       
    strategyParameters.featureSelectionStrategy = queryStruct(metaParamsIn,'featureSelectionStrategy','evolutionary'); % 'evolutionary' or 'allFeatures'
    if strcmp(strategyParameters.featureSelectionStrategy,'on')
        strategyParameters.featureSelectionStrategy = 'evolutionary';
    end

    % intial population improvement
    strategyParameters.evoOptInitialPopulationImprovement = queryStruct(metaParamsIn,'evoOptInitialPopulationImprovement','randomForestVariableImportance'); % method = {'randomForestVariableImportance','evolutionaryFeatureOptimization','none'}
    
    evoTestMode = queryStruct(metaParamsIn,'evoTestMode',0);
    if evoTestMode
        warning('TEST mode EvolutionaryConfigurationAdaptation')
        strategyParameters.evoOptNOptimizationGenerations = 6;
        strategyParameters.evoOptNIndividualsInitial = 20;
        strategyParameters.evoOptNChildrenPerGeneration = 10;
        strategyParameters.evoOptGenerationPopulationSize = 10;
    end        
    

     
    % mutation parameters (base)    
    strategyParameters.evoOptMutationParams = getStandardMutationParameters();    
    
end



% fill job info to find analysis group later on
function commonParams = getJobGroupInfo(commonParams,profileId)


commonParams.jobDescription = profileId;
if numel(commonParams.metaParameterDescription) > 0
    commonParams.jobDescription = [commonParams.jobDescription '_' commonParams.metaParameterDescription];
end

commonParams.jobGroupInfo = struct;
commonParams.jobGroupInfo.profileId = profileId;
commonParams.jobGroupInfo.metaParameterDescription = commonParams.metaParameterDescription;
commonParams.jobGroupInfo.dataSetId = ''; % needs to be filled later
    


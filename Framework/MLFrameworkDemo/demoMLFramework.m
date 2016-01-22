
% Test the MachineLearningFramework/AROMS-Framework
% (Automatic Representation Optimization and Model Selection Framework)
% - dataset
% - basic parameters
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function demoMLFramework()

% add path to framework
addpath(genpath(['..' filesep 'MLFramework']));

%__________________________________________________________________________
% Dataset

% demo from UCI https://archive.ics.uci.edu/ml/datasets/Statlog+%28Heart%29 
%load('Datasets/dataSetUCI_statlogheart.mat'); 


% own dataset with classification of coins (and multidimensional features)
 load('Datasets/dataSetCoins.mat');

% 1) simple variant
dataSetTrain = dataSet; % dataSet is in workspace now
dataSetTest = dataSet; % after optimization: test with training dataset (or put a separated test dataset!)

% 2) complex variant
% .. or randomly separate into training and test dataset
%[dataSetTrain, dataSetTest] = dataSetTrainTestSeparation(dataSet, 0.7); % e.g. 0.7 for 70% to training set and 30% in testing set


%__________________________________________________________________________
% set general parameters
generalParams = struct;
if ispc
    generalParams.resultPath = 'C:/MLFrameworkResults/'; % windows
else
    generalParams.resultPath = '~/MLFrameworkResults/'; % linux
end
generalParams.analysisName = 'test';

generalParams.parallelToolboxActive = 1;
generalParams.parallelToolboxNumberWorkers = 4; % should be number of processors/threads on computer


%__________________________________________________________________________
% set analysis parameters

analysisParams = struct;
analysisParams.nRepetitions = 1; % number of repetions
analysisParams.stopCriterionComputingTimeHours = 12; % running time [h]

% all components
% framework components (see frameworkComponentLists.m)
%analysisParams.optimizationComponentsFeaturePreprocessing = '*';  % '*' for all - or subset, e.g. {'none','preWhitening', 'normalization'}
%analysisParams.optimizationComponentsFeatureTransform = '*';      % '*' for all - or subset, e.g. {'none','PCA','LDA'}
%analysisParams.optimizationComponentsClassifier = '*';            % '*' for all - or subset, e.g. {'ClassifierSVMLinear','ClassifierRandomForest'}

% popular and fast subset of methods
analysisParams.optimizationComponentsFeaturePreprocessing = '*';
analysisParams.optimizationComponentsFeatureTransform = {'none','PCA','KernelPCAGauss','KernelPCAPoly','LDA'};
analysisParams.optimizationComponentsClassifier = {'ClassifierSVMLinear','ClassifierSVMGauss','ClassifierSVMPoly'};


optimizationAlgorithm = 'EvolutionaryConfigurationAdaptation'; % evolutionary opt + continuous hyperparameter opt
%optimizationAlgorithm = 'BaselineSVM'; % comparison with baseline SVM classifier

% get job parameters
analysisJobParams = frameworkJobProfiles(optimizationAlgorithm,analysisParams);
analysisJobParams = analysisJobParams{1}; % only one job
analysisJobParams.jobDescription = generalParams.analysisName;

% set dataset for testing (is never used for training!)
analysisJobParams.multiPipelineTestDataSet = dataSetTest;
analysisJobParams.multiPipelineTraining = 1; % this should be switched on even though when only the best single pipeline alone will be used
analysisJobParams.multiPipelineParameter = struct;
analysisJobParams.multiPipelineParameter.multiClassifierNPipelinesMax = 10; % number of maximum fusion of best pipelines


% framework init
%__________________________________________________________________________
mlFrameworkController = AROMSFrameworkController();
mlFrameworkController.setGeneralParameters(generalParams);
mlFrameworkController.addJob(dataSetTrain,analysisJobParams); % multiple jobs possible with different datasets and parameters


% prepare analysis to get path
analysisPath = mlFrameworkController.prepareAnalysisPath();

% directly run experiments
AROMSFrameworkController.runAnalysisFailSafe(analysisPath);

    





% Test the MachineLearningFramework/AROMS-Framework
% (Automatic Representation Optimization and Model Selection Framework)
% - use best classifier(s) for acutal classification tasks
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function demoUseClassifier()

% add path to framework
addpath(genpath(['..' filesep 'MLFramework']));

%__________________________________________________________________________
jobResultPath = '/home/buerger/MLFrameworkResults/15-11-06/test009/Job0001_test/';

% dataSet to classifiy (in this case the training dataset is used. Could
% also be any other data with the same structure
load([jobResultPath 'trainingInfo.mat']);
dataSetToClassify = trainingInfo.job.dataSet; % trainingInfo is in workspace now


multiPipelineClassifier = MultiPipelineClassification();
multiPipelineClassifier.loadPipelinesFromFile([jobResultPath '/multipipeline/multiPipelineSystem.mat']);
multiPipelineClassifier.multiPipelineParams.trainingStrategy = 'simpleTopPipelines';
multiPipelineClassifier.multiPipelineParams.useNumberConfigurations = 1; % only best pipeline
%multiPipelineClassifier.multiPipelineParams.useNumberConfigurations = 10; % best 10..20..50 (use parallel pool to increase speed for processing)
multiPipelineClassifier.multiPipelineParams.calculateClassConfidences = 0; % not used
timerClassifier = tic;
classResults = multiPipelineClassifier.classifyDataSet(dataSetToClassify);    
timeForClassification = toc(timerClassifier);
predictedLabels=classResults.predictedLabels
fprintf('== Time needed for classifying %d instances %0.2f s = %0.4f s per instance \n',numel(predictedLabels), timeForClassification, timeForClassification/numel(predictedLabels));










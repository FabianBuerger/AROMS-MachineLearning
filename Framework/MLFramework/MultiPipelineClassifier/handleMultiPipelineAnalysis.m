% function dataAggregatedMultiPipeline = handleMultiPipelineAnalysis(...
%  trainingJobResultPath, multiPipelineParameter, multiPipelineTestDataSet)
%
% Evaluate MultiClassifier System from Framework training data
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015


function dataAggregatedMultiPipeline = handleMultiPipelineAnalysis(trainingJobResultPath, multiPipelineParameter, multiPipelineTestDataSet)
    dataAggregatedMultiPipeline = [];
    % generate free directory
    multiPipeLPathBase = [trainingJobResultPath filesep 'multipipeline'];
    multiPipeLPath = multiPipeLPathBase;
    counter = 1;
    while exist(multiPipeLPath,'dir') == 7
        multiPipeLPath = [multiPipeLPathBase num2str(counter)];
        counter = counter +1;
    end
    [~, ~, ~] = mkdir(multiPipeLPath);
    multiPipeLPath = [multiPipeLPath filesep];
    disp('> Training Multi Pipeline Classifier...');
    % parameters
    multiClassifierNPipelinesMax = queryStruct(multiPipelineParameter,'multiClassifierNPipelinesMax',50);
    multiPipelineParams = struct;
    multiPipelineParams.trainingStrategy = 'simpleTopPipelines';
    multiPipelineParams.maxNumberConfigurations = multiClassifierNPipelinesMax;            
    multiPipelineParams.useNumberConfigurations = multiClassifierNPipelinesMax;
    multiPipelineParams.trainingCrossValidationClassifiers = queryStruct(multiPipelineParameter,'multiClassifierFromCrossValidation',0);

    multiPipeline = MultiPipelineClassification();
    multiPipeline.initFromTrainingResults(trainingJobResultPath, multiPipelineParams);
    % just save pipeline...
    multiPipeline.savePipelinesToFile([multiPipeLPath 'multiPipelineSystem.mat']);     

    % ... if test set is also set, the performance is evaluated too
    if ~isempty(multiPipelineTestDataSet)
        fprintf('> Evaluating Multi Pipeline Classifier with test dataset containing %d instances...\n',numel(multiPipelineTestDataSet.targetClasses));
        params = struct;
        params.resultPath = multiPipeLPath;
        params.silentPlot = 1;
        params.evalItemsSortedTop = multiPipeline.trainingData.topResults;
        params.trainingInfo = multiPipeline.trainingData.trainingInfo;
        try % some statistics may fail in some strange cases
            dataAggregatedMultiPipeline = performMultiPipelineEvaluation(multiPipeline,multiPipelineTestDataSet,params);
            multiPipelineEvaluationTextBased(dataAggregatedMultiPipeline,multiPipelineTestDataSet,params);
        catch
        end
    end   
end

        
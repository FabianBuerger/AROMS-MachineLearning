% function evalMetrics = evaluateClassficationResults(targetClasses, predictedTargets, classIds)
% Evaluate the predicted output of a classifier with ground truth
% labels which is done in every cross validation round.
% Input:
% -targetClasses: ground truth labels (n x 1 vector) 
% -predictedTargets: the predicted classes of the classifier output
%                    (n x 1 vector) 
% -classIds: vector with possible class ids in the right order,
% e.g. [1,2,3] for a three class problem. These labels are used in
% the targetClasses and predictedTargets vectors
% 
% Output:
% evalMetrics = struct with evaluation results
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function evalMetrics = evaluateClassficationResults(targetClasses, predictedTargets, classIds)
    evalMetrics = struct;            

    % analyze confusion matrix
    confusionMatrix = confusionmat(targetClasses,predictedTargets,'order',classIds);

    columSum = sum(confusionMatrix,2);
    rowSum = sum(confusionMatrix,1);
    nClasses = numel(classIds);
    classStats = cell(nClasses,1);
    for iClass = 1:nClasses
        classStat = struct;
        classStat.recall = confusionMatrix(iClass,iClass)/columSum(iClass); %Nominator:(TP+FN)
        classStat.precision = confusionMatrix(iClass,iClass)/rowSum(iClass);  %Nominator:(TP+FP)
        % note precision is also called producer accuracy

        % handle edge cases of evaluation
        %http://stats.stackexchange.com/questions/1773/what-are-correct-values-for-precision-and-recall-in-edge-cases
        %http://www.techques.com/question/17-1773/What-are-correct-values-for-precision-and-recall-in-edge-cases
        if columSum(iClass) == 0
            classStat.recall = 1; % this is 1 since 0 of 0 have been discovered
        end
        if confusionMatrix(iClass,iClass) == 0 % TP = 0
            restFP = rowSum(iClass);
            if restFP == 0
                classStat.precision = 1;
            else
                classStat.precision = 0;
            end
        end    
        if classStat.precision + classStat.recall > 0
            classStat.f1 = 2*(classStat.precision*classStat.recall)/(classStat.precision+classStat.recall);
        else
            classStat.f1 = 0;
        end

        % add to class statistics list
        classStats{iClass} = classStat;
    end

    % overall statisics
    sumCorrectClass = trace(confusionMatrix);
    sumClassifications = sum(confusionMatrix(:));
    evalMetrics.accuracyOverall = sumCorrectClass/sumClassifications; 
    
    % simple error stats
    evalMetrics.nErrorsAbsolute = sum(targetClasses ~= predictedTargets);
    evalMetrics.nErrorsRelative = evalMetrics.nErrorsAbsolute/numel(targetClasses);
    
    evalMetrics.nCorrectAbsolute = sum(targetClasses == predictedTargets);
    evalMetrics.nCorrectRelative = evalMetrics.nCorrectAbsolute/numel(targetClasses);    
    
    % all classes stats
    evalMetrics.allClassesMeanRecall = getStatisticsForStructFieldInCellArray(classStats, 'recall', 'mean');
    evalMetrics.allClassesMeanPrecision = getStatisticsForStructFieldInCellArray(classStats, 'precision', 'mean');
    evalMetrics.allClassesMeanF1 = getStatisticsForStructFieldInCellArray(classStats, 'f1', 'mean');
    
    % detailed class statistics
    evalMetrics.confusionMatrix = confusionMatrix;
    evalMetrics.statsClassWise = classStats;
end
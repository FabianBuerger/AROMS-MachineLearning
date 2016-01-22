% Calculate mean and std metrics from cross validation rounds
function evaluationResults = averageCVResults(evaluationResults,evalMetricAllCVRounds,dataSet,nCrossValSets, doTimeResults)

evaluationResults.accuracyOverallMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'accuracyOverall','mean');
evaluationResults.accuracyOverallStd = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'accuracyOverall','std');
evaluationResults.accuracyOverallMin = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'accuracyOverall','min');
evaluationResults.accuracyOverallMax = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'accuracyOverall','max');

% simple error stats
evaluationResults.nErrorsAbsoluteMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'nErrorsAbsolute','mean');
evaluationResults.nErrorsAbsoluteStd = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'nErrorsAbsolute','std');

evaluationResults.nErrorsRelativeMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'nErrorsRelative','mean');
evaluationResults.nErrorsRelativeStd = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'nErrorsRelative','std');

evaluationResults.nCorrectAbsoluteMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'nCorrectAbsolute','mean');
evaluationResults.nCorrectAbsoluteStd = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'nCorrectAbsolute','std');

evaluationResults.nCorrectRelativeMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'nCorrectRelative','mean');
evaluationResults.nCorrectRelativeStd = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'nCorrectRelative','std');    


evaluationResults.allClassesMeanRecallMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'allClassesMeanRecall','mean');
evaluationResults.allClassesMeanPrecisionMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'allClassesMeanPrecision','mean');
evaluationResults.allClassesMeanF1Mean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'allClassesMeanF1','mean');

evaluationResults.allClassesMeanRecallStd = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'allClassesMeanRecall','std');
evaluationResults.allClassesMeanPrecisionStd = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'allClassesMeanPrecision','std');
evaluationResults.allClassesMeanF1Std = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'allClassesMeanF1','std');                

% ! do not store mean confusion matrix (field
% confusionMatrix) for now

% class results
classWiseStats = cell(numel(dataSet.classIds),1);
for iClass = 1:numel(dataSet.classIds)
    classStats = struct;
    classStats.classId = dataSet.classIds(iClass);  

    % collect all evaluation of that class
    recallValues = zeros(nCrossValSets,1);
    precisionValues = zeros(nCrossValSets,1);
    f1Values = zeros(nCrossValSets,1);
    for iCVRound = 1:nCrossValSets
        recallValues(iCVRound) = evalMetricAllCVRounds{iCVRound}.statsClassWise{iClass}.recall;
        precisionValues(iCVRound) = evalMetricAllCVRounds{iCVRound}.statsClassWise{iClass}.precision;
        f1Values(iCVRound) = evalMetricAllCVRounds{iCVRound}.statsClassWise{iClass}.f1;                
    end
    classStats.recallMean = mean(recallValues);
    classStats.precisionMean = mean(precisionValues);
    classStats.f1Mean = mean(f1Values);

    classStats.recallStd = std(recallValues);
    classStats.precisionStd = std(precisionValues);
    classStats.f1Std = std(f1Values);  

    classWiseStats{iClass} = classStats;
end            
evaluationResults.classWiseStats = classWiseStats;                                


if doTimeResults
    % time measurements
    evaluationResults.timeTrainingMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'timeTraining','mean');
    evaluationResults.timeTrainingPerInstanceMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'timeTrainingPerInstance','mean');
    evaluationResults.timeClassificationMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'timeClassification','mean');
    evaluationResults.timeClassificationPerInstanceMean = getStatisticsForStructFieldInCellArray(evalMetricAllCVRounds,'timeClassificationPerInstance','mean');
end    
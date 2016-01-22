        
%__________________________________________________________________
% get the scalar quality metric from a specific evaluation
% which is defined in the job parameters
function qualityMetric = getQualityMetricFormEvaluation(evalutationResult, jobParams)
    qualityMetric  = -1; % if any error occured set -1
    if ~evalutationResult.errorOccurred 
        % basic overall accuracy (scientific standard)
        if strcmp(jobParams.evaluationQualityMetric,'overallAccuracy')
            qualityMetric = evalutationResult.accuracyOverallMean;
        end
        % get average value of precision and recall of each class
        if strcmp(jobParams.evaluationQualityMetric,'averagePrecisionRecall')
            % loop class wise stats
             nValues = 0;
             qualityMetric = 0;
             for iClass=1:numel(evalutationResult.classWiseStats)
                 cClassStats = evalutationResult.classWiseStats{iClass};
                 nValues = nValues+2;
                 qualityMetric = qualityMetric + cClassStats.recallMean+cClassStats.precisionMean;
             end
             qualityMetric = qualityMetric/nValues;   
        end        
        % multiplicative 
        if strcmp(jobParams.evaluationQualityMetric,'productPrecisionRecall')
            % loop class wise stats
             qualityMetric = 1;
             for iClass=1:numel(evalutationResult.classWiseStats)
                 cClassStats = evalutationResult.classWiseStats{iClass};
                 qualityMetric = qualityMetric*cClassStats.recallMean*cClassStats.precisionMean;
             end  
        end 
        % geometric mean for all classes
        if strcmp(jobParams.evaluationQualityMetric,'GMeasure')
            % loop class wise stats
             qualityMetric = 1;
             for iClass=1:numel(evalutationResult.classWiseStats)
                 cClassStats = evalutationResult.classWiseStats{iClass};
                 qualityMetric = qualityMetric*cClassStats.recallMean*cClassStats.precisionMean;
             end  
             qualityMetric = sqrt(qualityMetric);
        end
        % weighting low std
        if strcmp(jobParams.evaluationQualityMetric,'overallAccuracyStdWeighted')
            weightStd = 50;
            maxDiff = -0.05;
            accVal = evalutationResult.accuracyOverallMean;
            stdVal = evalutationResult.accuracyOverallStd;
            delta =  max(maxDiff,-weightStd*stdVal^2);
            qualityMetric = accVal+delta;
        end
        % minimum accuracy
        if strcmp(jobParams.evaluationQualityMetric,'overallAccuracyMin')
            qualityMetric = evalutationResult.accuracyOverallMin;
        end        
        
    end
end   

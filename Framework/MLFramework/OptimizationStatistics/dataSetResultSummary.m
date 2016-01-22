% function dataSetResultSummary(aggregatedResults,summaryStatsOpt)
%
% Write a quick summary of results from training and testing of a data set
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

        

function dataSetResultSummary(aggregatedResults,summaryStatsOpt)

textStats = {};

textStats{end+1} = sprintf('DataSet: %s',summaryStatsOpt.job.dataSet.dataSetName);
try 
    textStats{end+1} = sprintf('Strategy: %s',summaryStatsOpt.job.jobParams.jobGroupInfo.profileName);
catch
end
textStats{end+1} = sprintf('Result Path: %s',summaryStatsOpt.resultPath);



if isfield(aggregatedResults,'resultsTraining')

    textStats{end+1} = sprintf(' ');
    textStats{end+1} = sprintf('Training Results');
    textStats{end+1} = sprintf('-------------');
    
    textStats{end+1} = sprintf('average CV accuracy = %0.4f',aggregatedResults.resultsTraining.bestAccuracyOverallMean);    
end


try
    if isfield(aggregatedResults,'resultsMultiPipeline')
        if ~isempty(aggregatedResults.resultsMultiPipeline)
            textStats{end+1} = sprintf(' ');
            textStats{end+1} = sprintf('Test Results');
            textStats{end+1} = sprintf('-------------');

            textStats{end+1} = sprintf('Top solution pipeline');
            textStats{end+1} = sprintf('accuracy = %0.4f',aggregatedResults.resultsMultiPipeline.fusionTopMajority.MultiPipelineTop001Accuracy);

            results = aggregatedResults.resultsMultiPipeline.fusionTopMajority.evaluationListDetails{1};

            textStats{end+1} = sprintf('Correctly Classified Instances = %d     %0.4f %%',results.nCorrectAbsolute,100*results.nCorrectRelative);
            textStats{end+1} = sprintf('Incorrectly Classified Instances = %d     %0.4f %%',results.nErrorsAbsolute,100*results.nErrorsRelative);
            textStats{end+1} = sprintf('Total Number of Instances = %d',results.nCorrectAbsolute+results.nErrorsAbsolute);
            textStats{end+1} =  sprintf(' ');
            textStats{end+1} = sprintf('Classification Time Per Instance: Best Pipeline  = %0.5f seconds',aggregatedResults.resultsMultiPipeline.classificationSpeed.speedPerItemBestPipeline);
            textStats{end+1} = sprintf('Classification Time Per Instance: Average All Pipelines  = %0.5f +-  %0.5f seconds',aggregatedResults.resultsMultiPipeline.classificationSpeed.speedPerItemAverageMultipipeline,...
               aggregatedResults.resultsMultiPipeline.classificationSpeed.speedPerItemAverageMultipipelineStd ); 

           % multi pipeline fusion dependent on fitness
           textStats{end+1} =  sprintf(' ');
           textStats{end+1} =  sprintf('Multipipeline fusion by fitness');
           stringsFitnessDeltas = ' FitnessDeltas: ';
           stringsPipelines = ' nPipelines: ';
           stringsAccuracy = ' Accuracy: ';
           for ii= 1: numel(aggregatedResults.resultsMultiPipeline.fusionTopMajorityPipelineNumberDependentOnFitness.deltaFitnessValues)
            stringsFitnessDeltas = [stringsFitnessDeltas sprintf('%0.4f, ',aggregatedResults.resultsMultiPipeline.fusionTopMajorityPipelineNumberDependentOnFitness.deltaFitnessValues(ii))];
            stringsPipelines= [stringsPipelines sprintf('%d,    ', aggregatedResults.resultsMultiPipeline.fusionTopMajorityPipelineNumberDependentOnFitness.nPipelinesFitnessDelta(ii))];
            stringsAccuracy = [stringsAccuracy sprintf('%0.5f, ',aggregatedResults.resultsMultiPipeline.fusionTopMajorityPipelineNumberDependentOnFitness.accuracyFitnessDelta(ii))];      
           end
            textStats{end+1} = stringsFitnessDeltas;
            textStats{end+1} = stringsPipelines;
            textStats{end+1} = stringsAccuracy;

            textStats{end+1} = sprintf(' ');
            textStats{end+1} = sprintf('Best multi pipeline fusion');
            textStats{end+1} = sprintf('accuracy = %0.4f',aggregatedResults.resultsMultiPipeline.fusionTopMajority.MultiPipelineBestAccuracy);
            textStats{end+1} = sprintf('nPipelines = %d',aggregatedResults.resultsMultiPipeline.fusionTopMajority.MultiPipelineBestNumberPipelines);

            results = aggregatedResults.resultsMultiPipeline.fusionTopMajority.evaluationListDetails{aggregatedResults.resultsMultiPipeline.fusionTopMajority.MultiPipelineBestNumberPipelines};

            textStats{end+1} = sprintf('Correctly Classified Instances = %d     %0.4f %%',results.nCorrectAbsolute,100*results.nCorrectRelative);
            textStats{end+1} = sprintf('Incorrectly Classified Instances = %d     %0.4f %%',results.nErrorsAbsolute,100*results.nErrorsRelative);
            textStats{end+1} = sprintf('Total Number of Instances = %d',results.nCorrectAbsolute+results.nErrorsAbsolute);    


            %----------------------------------
            % max diversity
            results = aggregatedResults.resultsMultiPipeline.fusionMaxDiversity.evaluationListDetails{aggregatedResults.resultsMultiPipeline.fusionMaxDiversity.MultiPipelineBestNumberPipelines};
            textStats{end+1} = sprintf(' ');
            textStats{end+1} = sprintf('Diversity Max - Best multi pipeline fusion');
            textStats{end+1} = sprintf('accuracy = %0.4f',aggregatedResults.resultsMultiPipeline.fusionMaxDiversity.MultiPipelineBestAccuracy);
            textStats{end+1} = sprintf('nPipelines = %d',aggregatedResults.resultsMultiPipeline.fusionMaxDiversity.MultiPipelineBestNumberPipelines);

            textStats{end+1} = sprintf('Correctly Classified Instances = %d     %0.4f %%',results.nCorrectAbsolute,100*results.nCorrectRelative);
            textStats{end+1} = sprintf('Incorrectly Classified Instances = %d     %0.4f %%',results.nErrorsAbsolute,100*results.nErrorsRelative);
            textStats{end+1} = sprintf('Total Number of Instances = %d',results.nCorrectAbsolute+results.nErrorsAbsolute);        
        end
    end
catch 
end


fileName = [summaryStatsOpt.resultPath filesep 'resultSummary.txt'];
saveMultilineString2File(textStats,fileName);


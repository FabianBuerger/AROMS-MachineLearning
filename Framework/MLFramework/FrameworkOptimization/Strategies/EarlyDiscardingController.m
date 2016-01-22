% Class definition EarlyDiscardingController
% This class handles the early discarding of configurations during cross
% validation
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef EarlyDiscardingController < handle
    
    properties 
        active = 1;
        timeLimitCriterionActive = 0;
        timeLimitSeconds = inf;
        bestQualityMean = 0;
        bestQualityStd = 1;
        nRoundsTotal =  5;
        badQualityThresh = 0;
        jobParams;
        classIds;
        
        evaluationResultsCVRounds = {};
        nEvaluations = 0;
        percentageEvalsNeeded = 0;
        nEvaluationsSaved = 0;
        qualityMetric = 0;
        averageCVResultStruct = [];

        discarded = 0;
        errorOccured = 0;        
        
        debugMode = 0;
        
        % time criterion
        timerTimeCriterion = [];
        totalTimeUsed = 0;
        
        % quality level criterion
        significanceLevel = 0; % current mean must be better than last mean
        %significanceLevel = 1.28; % 10% error
        %significanceLevel = 1.64; % 5% error
        %significanceLevel = 1.96; % 2.5% error
        %significanceLevel = 2.32;  % 1%   error
       
    end
    
    %====================================================================
    methods
                
  
        % constructor
        function obj = EarlyDiscardingController(earlyDiscardingParams)
            
            obj.bestQualityMean = earlyDiscardingParams.bestQualityMean;
            obj.bestQualityStd = earlyDiscardingParams.bestQualityStd;
            obj.nRoundsTotal = earlyDiscardingParams.nRoundsTotal;
            obj.badQualityThresh = earlyDiscardingParams.badQualityThresh;
            obj.active = earlyDiscardingParams.active;
            obj.significanceLevel = earlyDiscardingParams.significance;
            obj.jobParams = earlyDiscardingParams.jobParams;
            obj.classIds = earlyDiscardingParams.classIds;
            obj.timeLimitCriterionActive = earlyDiscardingParams.timeLimitCriterionActive;
            obj.timeLimitSeconds = earlyDiscardingParams.timeLimitSeconds;
            
            if obj.debugMode
            fprintf('EarlyDiscardingControl: Params active=%d  bestQualityMean=%0.4f  bestQualityStd=%0.4f  nRoundsTotal=%d  badQualityThresh=%0.4f timeLimitActive=%d timeLimitSeconds=%0.2f \n',...
                earlyDiscardingParams.active, earlyDiscardingParams.bestQualityMean, earlyDiscardingParams.bestQualityStd, earlyDiscardingParams.nRoundsTotal, earlyDiscardingParams.badQualityThresh,...
                earlyDiscardingParams.timeLimitCriterionActive, earlyDiscardingParams.timeLimitSeconds);
            end    
        end        
        
        
        
        
        %__________________________________________________________________
        % calculate current quality metric according to parameters   
        function updateCurrentQualityMetrics(this)
            if this.errorOccured
                this.averageCVResultStruct = struct;
                this.averageCVResultStruct.errorOccurred = 1;
                this.qualityMetric = nan;                 
            else
                dummyDataSet = struct;
                dummyDataSet.classIds = this.classIds;
                this.averageCVResultStruct = struct;
                this.averageCVResultStruct.errorOccurred = 0;
                this.averageCVResultStruct = averageCVResults(this.averageCVResultStruct, this.evaluationResultsCVRounds, dummyDataSet, numel(this.evaluationResultsCVRounds),0);
                this.qualityMetric = getQualityMetricFormEvaluation(this.averageCVResultStruct, this.jobParams);                
            end
            this.averageCVResultStruct.earlyDiscarding = this.discarded;
            this.nEvaluations = numel(this.evaluationResultsCVRounds);
            this.percentageEvalsNeeded = this.nEvaluations/this.nRoundsTotal;
            this.nEvaluationsSaved=this.nRoundsTotal-this.nEvaluations;
        end

        %__________________________________________________________________
        % set error occured
        function setErrorOccured(this)
            this.errorOccured = 1;
            this.discarded = 1;
            this.updateCurrentQualityMetrics();
        end
        
        %__________________________________________________________________
        % start timer at beginning of cv round
        function cvRoundStarted(this)
            this.timerTimeCriterion = tic();
            if this.debugMode
                fprintf('EarlyDiscardingControl: START timer \n');
            end                    
        end
        
        %__________________________________________________________________
        % main function after each cross validation round: go on
        function [discarding] = cvRoundPerformed(this,evalMetricsCVRound)
            discarding = 0;
            timePassedRound = toc(this.timerTimeCriterion);
            this.totalTimeUsed = this.totalTimeUsed + timePassedRound;
            
            this.evaluationResultsCVRounds{end+1} = evalMetricsCVRound;
            
            % get current quality value
            currentAccuracy = evalMetricsCVRound.accuracyOverall;
            standardAccuracyMetric = strcmp(this.jobParams.evaluationQualityMetric,'overallAccuracy');
            
            % calculate the current quality metrics (even if results are
            % only partially available)
            this.updateCurrentQualityMetrics();

            nRounds = numel(this.evaluationResultsCVRounds);
            
            % confidence intervals
            spread = this.significanceLevel*this.bestQualityStd/sqrt(nRounds);
            lowerBound = this.bestQualityMean - spread;            
            
            if ~this.active
                return;
            end
            % worse than guessing -> stop ONLY WHEN STANDARD ACCURACY is
            % chosen
            if standardAccuracyMetric && currentAccuracy < this.badQualityThresh
                discarding = 1;
                this.discarded = 1;
                if this.debugMode
                    fprintf('EarlyDiscardingControl: DISCARDING, Reason: Accuracy bad %0.4f \n',currentAccuracy);
                end
                return;
            end
            % only discard if less than current mean
            if this.qualityMetric < this.bestQualityMean
                if this.qualityMetric < lowerBound
                    discarding = 1;
                    this.discarded = 1;
                    if this.debugMode
                        fprintf('EarlyDiscardingControl: DISCARDING, Reason: current metric %0.4f outside Interval lower=%0.4f mean=%0.4f \n',this.qualityMetric,lowerBound,this.bestQualityMean);
                    end                    
                    return;
                end
            end  
            
            % time control
            if this.timeLimitCriterionActive
                % discard if time limit is exeeded and quality is not
                % better than current best (otherwise no limit)
                if (this.totalTimeUsed > this.timeLimitSeconds)
                    if (this.qualityMetric < this.bestQualityMean)
                        discarding = 1;
                        this.discarded = 1;   
                        if this.debugMode
                            fprintf('EarlyDiscardingControl: DISCARDING, Reason: Timelimit and bad quality %0.2f secs needed, limit %0.2f - quality current %0.4f, best %0.4f \n',this.totalTimeUsed, this.timeLimitSeconds, this.qualityMetric, this.bestQualityMean);
                        end     
                        return;                        
                    else
                        if this.debugMode
                            fprintf('EarlyDiscardingControl: Time limit passed, but quality promising. Going on - quality current %0.4f, best %0.4f \n',this.qualityMetric, this.bestQualityMean);
                        end
                    end
                end
            end
            
            if this.debugMode
                fprintf('EarlyDiscardingControl: ACCEPTED, current quality %0.4f Interval lower=%0.4f mean=%0.4f timepassed %0.2f \n',this.qualityMetric,lowerBound,this.bestQualityMean, this.totalTimeUsed);
            end              
        end
        

      end % end methods public ____________________________________________
     


end

        



% ----- helper -------




        

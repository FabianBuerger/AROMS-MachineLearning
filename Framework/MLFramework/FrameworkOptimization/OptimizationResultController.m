% Class definition OptimizationResultController
%
% This class handles the result storage and analysis of the classification
% optimization process. It stores a list of tuples of 
% configuration and evaluationResults with timestamps and provides online 
% sorting functions to get the current best solution
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef OptimizationResultController < handle
    
    properties 
        generalParams = struct;
       
        % struct that contains optimization history data
        resultStorage;
        
        % dynamic cell array pre allocation
        storageSizeAllocationSteps = 1000;
        
        startTimer = 0;
        
    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = OptimizationResultController(generalParamsIn)
            obj.generalParams = generalParamsIn;
            obj.resetTrainingHistory();
            obj.setTrainStartTimeNow();
        end
        
        %__________________________________________________________________
        % reset the training storage        
        function resetTrainingHistory(this)
            this.resultStorage = struct;
            this.resultStorage.evaluationItems = cell(this.storageSizeAllocationSteps,1);
            this.resultStorage.numberItems = 0;
            % current best information
            this.resultStorage.currentBestInfo = struct;
            this.resultStorage.currentBestInfo.bestIndexInStorageList = 0;
            this.resultStorage.currentBestInfo.bestQualityMetric = -1;
            this.resultStorage.currentBestInfo.bestQualityStd = -1;
            this.resultStorage.currentBestInfo.qualityStdValues = [];
            this.resultStorage.currentBestInfo.qualityValues = [];
            this.resultStorage.componentsFeatureSelection = {};
        end
        
         %__________________________________________________________________
        % reset the training storage        
        function setTrainStartTimeNow(this)
            this.startTimer = tic;
        end       
        
        
        %__________________________________________________________________
        % append a single result struct resultData
        % to the internal result storage
        % resultData is the struct with data
        function appendResult(this, resultData)
            itemIndex = this.resultStorage.numberItems + 1;
            
            if isnan(resultData.qualityMetric) || resultData.qualityMetric < 0
                resultData.qualityMetric = 0;
            end
            
            evaluationItem = struct;
            evaluationItem.resultData = resultData;
            evaluationItem.qualityMetric = resultData.qualityMetric;
            % store index and time
            evaluationItem.calcIndex = itemIndex;
            evaluationItem.calcTimePassedSinceStart = toc(this.startTimer);
            
            currentCellArraySize = numel(this.resultStorage.evaluationItems);
            % dynamic allocation check
            if itemIndex > currentCellArraySize
                % increase cell array size
                this.resultStorage.evaluationItems{currentCellArraySize+this.storageSizeAllocationSteps} = [];
            end
            
            % finally set to the right position
            this.resultStorage.evaluationItems{itemIndex} = evaluationItem;
            this.resultStorage.numberItems = this.resultStorage.numberItems + 1;
            
            % get Std value
            stdVal = nan;
            try
                if isfield(resultData.evaluationMetrics,'accuracyOverallStd')
                    stdVal = resultData.evaluationMetrics.accuracyOverallStd;
                    if stdVal < 0
                        stdVal = nan;
                    end
                end
            catch
            end
            
            % update the current best position
            if evaluationItem.qualityMetric > this.resultStorage.currentBestInfo.bestQualityMetric
                this.resultStorage.currentBestInfo.bestIndexInStorageList = itemIndex;
                this.resultStorage.currentBestInfo.bestQualityMetric = evaluationItem.qualityMetric; 
                if ~isnan(stdVal)
                    this.resultStorage.currentBestInfo.bestQualityStd = stdVal;
                end
            end
            
            % update average standard deviation of results
            if ~isnan(stdVal)
                this.resultStorage.currentBestInfo.qualityValues(end+1) = evaluationItem.qualityMetric; 
                this.resultStorage.currentBestInfo.qualityStdValues(end+1) = stdVal;
            end
        end        
   
        %__________________________________________________________________
        % return the number of results
        function numRes = numberResults(this)       
            numRes = this.resultStorage.numberItems;
        end                  
        
        %__________________________________________________________________
        % return the currently best quality metric
        function qualityMetric = getCurrentBestQualityMetric(this)       
            qualityMetric = this.resultStorage.currentBestInfo.bestQualityMetric; 
        end          
                  
        %__________________________________________________________________
        % return the current best solutions Std value
        function stdVal = getCurrentBestQualityStd(this)       
            stdVal = this.resultStorage.currentBestInfo.bestQualityStd; 
        end               
        
        
        %__________________________________________________________________
        % return the current best solutions Std value
        function stdVal = getCurrentStdEstimation(this)
            stdVal = 1.0; % some standard value
            nTop = min(10, numel(this.resultStorage.currentBestInfo.qualityValues));
            if nTop > 0
                [~, bestIndices] = sort(this.resultStorage.currentBestInfo.qualityValues,'descend');
                bestIndicesCut = bestIndices(1:nTop);
                stdVals = this.resultStorage.currentBestInfo.qualityStdValues(bestIndicesCut);
                stdVal = mean(stdVals);
            end
        end                 
        
        
        %__________________________________________________________________
        % return result Item memory consumpution in MB       
        function memUsedMB = getMemoryConsumption(this)
            result = this.resultStorage;
            s = whos('result');
            memUsedMB= s.bytes/(1000000);             
        end
        
        %__________________________________________________________________
        % return the currently best configuration with evaluation info
        % evaluationItem is a tuple.
        function evaluationItem = getCurrentBestConfiguration(this)   
            if this.resultStorage.numberItems > 0
            evaluationItem = this.resultStorage.evaluationItems{...
                this.resultStorage.currentBestInfo.bestIndexInStorageList};
            else
                evaluationItem = [];
            end
        end                
        

        %__________________________________________________________________
        % cut list to correct the preallocated space
        function finalizeList(this)       
            this.resultStorage.evaluationItems = this.resultStorage.evaluationItems(1:this.resultStorage.numberItems);
        end          
        
        
        %__________________________________________________________________
        % export the result storage for e.g. saving
        function resultStorage = getResultListForExport(this)       
            resultStorage = this.resultStorage;
        end           

        
      end % end methods public ____________________________________________

      
      
      
     methods(Static = true)
         
        %__________________________________________________________________
        % sort list the passed list evaluationItems by quality metric
        function evaluationItemsSorted = sortResultListByQualityMetric(evaluationItems)       
            if numel(evaluationItems) > 0
                % now sortcell array of structs
                [~,sortOrder] = sort(cellfun(@(v) v.qualityMetric,evaluationItems),'descend');
                evaluationItemsSorted = evaluationItems(sortOrder);    
            else
                evaluationItemsSorted = [];
            end
        end      
        
     end
      
      
      methods(Access = private)
      
      end %private methods
        

    
    
end

        

        
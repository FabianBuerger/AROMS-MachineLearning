% Class definition PipelineElemFeaturePreprocessing
% 
% This class handles the preprocessing of feature vector data
% 
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef PipelineElemFeaturePreprocessing < PipelineElement
    
    properties 

        % preprocessed dataset for cache for training
        dataSetPreprocessed = struct;
        
        
    end
    
    %====================================================================
    methods
                 
        %__________________________________________________________________
        % constructor
        function obj = PipelineElemFeaturePreprocessing()
            obj.elementStringName = 'FeatPreProcessing';
            obj.elementState.preProcInfo=struct;
        end    
        
        
        %__________________________________________________________________        
        % prepare element with parameters
        function dataOut = prepareElement(this,dataIn)
            
            config = dataIn.config;
            timerProcessing=tic;
            this.elementState.preProcInfo.preProcMapping = featurePreProc_compute(dataIn.dataSet.featureMatrix, ...
                config.configPreprocessing.featurePreProcessingMethod);
            
            % process dataset to cache
            this.dataSetPreprocessed = this.process(dataIn.dataSet);
            
            timePassed = toc(timerProcessing);
            try
                if this.pipelineHandle.generalParams.advancedTimeMeasurements
                    if timePassed > this.pipelineHandle.generalParams.timeThreshSlow
                        fprintf(' !! AdvancedTimeMeasurement: Slow feature preprocessing %s needed %0.2f min \n',config.configPreprocessing.featurePreProcessingMethod, timePassed/60);
                    end
                end
            catch
            end            
            
            
            dataOut = struct;
            dataOut.dataSet = this.dataSetPreprocessed;
            dataOut.config = config;            
           
        end
        
        
        %__________________________________________________________________
        % Main processing function of pipeline element
        %
        % Function: Perform pre processing steps (e.g. feature scaling)
        %
        % Input: dataSet struct, with featureMatrix field
        %
        % Output: dataSet struct, with preprocessed featureMatrix
        
        function dataOut = process(this, dataIn)
            dataOut = dataIn;
            % perform preprocessing according to model obtained during
            % training
            dataOut.featureMatrix = real(featurePreProc_transform(dataOut.featureMatrix, this.elementState.preProcInfo.preProcMapping)); 

        end
        
        
        
        
      end % end methods public ____________________________________________
    




end

        




        

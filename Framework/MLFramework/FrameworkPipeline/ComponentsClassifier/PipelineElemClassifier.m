% Class definition PipelineElemClassifier
% 
% This class handles the classifier layer
% 
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef PipelineElemClassifier < PipelineElement
    
    properties 
        
        % the trained classifer model (for classifying new instances)
        trainedClassifierFusion = [];
        
    end
    
    %====================================================================
    methods
                 
        %__________________________________________________________________
        % constructor
        function obj = PipelineElemClassifier()
            obj.elementStringName = 'Classifier';
        end    
            
        %__________________________________________________________________        
        % evaluate the chosen classifier performance on the dataset
        % performing cross validation. Note: No classifier model is saved
        % for classification. Use prepareElement to train the classifier
        % for classification purpose.
        function evaluationResult = evaluateClassifierConfiguration(this, dataIn)
            
            config = dataIn.config;
            dataSet = dataIn.dataSet;
            crossValidationSets = dataIn.crossValidationSets;
            
            classifierController = ClassifierController(this.pipelineHandle.generalParams);
            evaluationResult = classifierController.evaluateClassifierPerformance(dataSet, config, crossValidationSets);
        end       
        
        
        %__________________________________________________________________        
        % evaluate the chosen classifier performance on precomputed cross
        % validation data sets (typically from feature transform)
        function evaluationResult = evaluateClassifierConfigurationFromPreComputedCVSets(this, config, dataSet, cvDataSets)
            classifierController = ClassifierController(this.pipelineHandle.generalParams);
            evaluationResult = classifierController.evaluateClassifierPerformancePreComputedCVSets(dataSet, config, cvDataSets);
        end            
        
        
        
        %__________________________________________________________________        
        % prepare element with parameters
        % Train classifier and save its model. 
        function dataOut = prepareElement(this,dataIn)
            config = dataIn.config;
            dataSet = dataIn.dataSet;
            multiClassifierFromCrossValidationSets = queryStruct(this.pipelineHandle.generalParams,'multiClassifierFromCrossValidationSets', 1);
            generalParams = this.pipelineHandle.generalParams;
            generalParams.multiClassifierFromCrossValidationSets = multiClassifierFromCrossValidationSets;
            if multiClassifierFromCrossValidationSets
                crossValidationSets = this.pipelineHandle.generalParams.crossValidationSets;
            else
                crossValidationSets = [];
            end
            classifierController = ClassifierController(generalParams);
            this.trainedClassifierFusion = classifierController.trainClassifierFusion(dataSet, config, crossValidationSets, generalParams);
            
            % final pipeline element
            dataOut = dataIn;
            dataOut.trainedClassifierFusionReady = this.trainedClassifierFusion.pipelineReady;
        end
        
        
        %__________________________________________________________________
        % Main processing function of pipeline element      
        %
        % Function: Classify the instance vectors of struct field
        % dataIn.featureMatrix
        %
        % Input: dataIn struct with fields featureMatrix (instance features
        % of n oberservations x m features)
        %
        % Output: vector n x 1 with predicted instance labels
        
        function dataOut = process(this, dataIn)

            dataOut = [];
            if ~isempty(this.trainedClassifierFusion)
                dataOut = this.trainedClassifierFusion.classify(dataIn.featureMatrix);
            else
                error('No classifier trained!')
            end
            
        end
        
        
      end % end methods public ____________________________________________
    




end

        



% ----- helper -------




        

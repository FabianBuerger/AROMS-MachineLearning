% Class definition ClassifierKNN
% 
% This realizes a k-Nearest-Neighbor classifier (Matlab interface)
%
% author Fabian Bürger, University Duisburg-Essen

classdef ClassifierKNN < ClassifierAbstract
    %====================================================================
    properties 
    end
    
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % constructor
        function obj = ClassifierKNN()
            obj.classifierName='kNN';
        end
        
        %__________________________________________________________________
        % init subclass       
        function initSubclass(this)
            % nothing to do here
        end
        
        %__________________________________________________________________
        % reset interal classifier variables
        function resetClassifier(this)
            this.classifierModel = 0;
        end        
        
        %__________________________________________________________________
        % train classifier with training data of n oversations and m
        % feature dimensions
        % -featureMatrix : n x m matrix 
        % -targetClasses : n x 1 vector with numeric labels (ground truth)  
        function trainClassifier(this,featureMatrix,targetClasses)
            this.classifierModel = ClassificationKNN.fit(featureMatrix,targetClasses,...
                'NumNeighbors',this.classifierParams.kNeighbors, ...
                'Distance',this.classifierParams.distanceMetric);
        end              
        
        %__________________________________________________________________
        % classify data given as featureMatrix with n instances and m
        % feature dimensions
        % -featureMatrix -> n x m matrix       
        function results = classify(this,featureMatrix)
            results=predict(this.classifierModel,featureMatrix);    
        end  
        
        
    
    end % end methods
    
end

       

        
        
% Class definition ClassifierKNN
% 
% This realizes a Naive Bayes classifier (Matlab interface)
%
% author Fabian Bürger, University Duisburg-Essen

classdef ClassifierNaiveBayes < ClassifierAbstract
    %====================================================================
    properties 
    end
    
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % constructor
        function obj = ClassifierNaiveBayes()
            obj.classifierName='NaiveBayes';
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
            this.classifierModel = NaiveBayes.fit(featureMatrix,targetClasses);
        end              
        
        %__________________________________________________________________
        % classify data given as featureMatrix with n instances and m
        % feature dimensions
        % -featureMatrix -> n x m matrix       
        function results = classify(this,featureMatrix)
            results = this.classifierModel.predict(featureMatrix);     
        end  
        
        
    
    end % end methods
    
end

       

        
        
% Class definition Random Forest (Matlab Statistics Toolbox Implementation)
% 
% This realizes a Random Forest Classifier (Matlab Statistics Toolbox Implementation)
% Random Forests by Leo Breiman and Adele Cutler
%
% author Fabian Bürger, University Duisburg-Essen

classdef ClassifierRandomForest < ClassifierAbstract
    %====================================================================
    properties 
    end
    
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % constructor
        function obj = ClassifierRandomForest()
            obj.classifierName='randomForest';
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
            this.classifierModel = TreeBagger(this.classifierParams.nTrees,featureMatrix,targetClasses, 'Method', 'classification');
        end              
        
        %__________________________________________________________________
        % classify data given as featureMatrix with n instances and m
        % feature dimensions
        % -featureMatrix -> n x m matrix       
        function results = classify(this,featureMatrix)
            results = str2double(this.classifierModel.predict(featureMatrix));    
        end  
        
                
    
    end % end methods
    
    
    
    
end

       

        
        
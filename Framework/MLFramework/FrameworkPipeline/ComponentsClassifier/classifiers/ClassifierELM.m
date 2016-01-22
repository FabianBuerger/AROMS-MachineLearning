% Class definition ClassifierELM
% 
% This realizes an Extreme Learning Machine classifier by 
% MR QIN-YU ZHU AND DR GUANG-BIN HUANG
% http://www.ntu.edu.sg/eee/icis/cv/egbhuang.htm
%
% author Fabian Bürger, University Duisburg-Essen

classdef ClassifierELM < ClassifierAbstract
    %====================================================================
    properties 
    end
    
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % constructor
        function obj = ClassifierELM()
            obj.classifierName='ClassifierELM';
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
            Elm_Type = 1; % classification
            ActivationFunction = 'sigmoid';
            this.classifierModel = elm_train(featureMatrix,targetClasses, Elm_Type, this.classifierParams.nHiddenNeurons, ActivationFunction);
        end              
        
        %__________________________________________________________________
        % classify data given as featureMatrix with n instances and m
        % feature dimensions
        % -featureMatrix -> n x m matrix       
        function results = classify(this,featureMatrix)
            targetClassesFake = ones(size(featureMatrix,1),1);
            results = elm_predict(this.classifierModel, featureMatrix, targetClassesFake);    
        end  
        
        
    
    end % end methods
    
end

       

        
        
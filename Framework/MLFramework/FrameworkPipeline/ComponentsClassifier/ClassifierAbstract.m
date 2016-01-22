% Class definition ClassifierAbstract
% 
% Abstract classifier class to handle the interface of all classifiers
% 
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef ClassifierAbstract < handle

    
    properties 
        classifierParams = struct; % parameters for classification
        classifierName = ''; % should be a string, set this in subclass
        
        % classifier model variables (set in subclass)
        classifierModel = [];
    end
    
    %====================================================================
    methods
         
        
        %__________________________________________________________________
        % set classifier parameters from configuration and init the classifier
        function init(this, classifierParams)
            this.classifierParams=classifierParams;
            % call subclass init
            this.initSubclass();
        end

        
        
    end % end methods
    
    

    methods(Abstract) % interface of classifiers subclass
        
        % init subclass after given parameters
        initSubclass(this); 
        
        % reset interal classifier variables
        resetClassifier(this); 

        % train classifier with training data of n oversations and m
        % feature dimensions
        % -featureMatrix : n x m matrix 
        % -targetClasses : n x 1 vector with numeric labels (ground truth)  
        trainClassifier(this,featureMatrix,targetClasses);
        
        % classify data given as featureMatrix with n instances and m
        % feature dimensions
        % -featureMatrix -> n x m matrix             
        results = classify(this,featureMatrix); 
        
      
    end 
    
    
end

        

                
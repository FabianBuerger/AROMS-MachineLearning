% Class definition ClassifierFusion
% 
% This class implements classifier fu
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef ClassifierFusion < handle
    
    properties  
        % list of classifiers
        classifierList = {};
        % parameters for fusion
        params = struct;
        pipelineReady = 0;
    end
    
    %====================================================================
    methods
        
        %__________________________________________________________________ 
        % constructor with parameters
        function obj = ClassifierFusion(params)
            obj.params = params;
        end
        
        
        %__________________________________________________________________
        % append a classifier object to the internal list
        function appendClassifier(this, classifier)
            this.classifierList{end+1} = classifier;
        end
        
   
        %__________________________________________________________________
        % classify the instances from the feature matrix (n rows = n
        % instances with m features) with all classifiers in the
        % classifierList and fuse the results:
        %
        % classificationResults.classifiersOutput : raw output of each
        % classifier (n instances x k classifiers
        %
        % classificationResults.labelsMajority : majority / mode for each
        % instance (n instances x 1)
        %
        % classificationResults.classiferConfidence : classifier
        % agreement/certainty (n instances x 1 in range [0,1])
        % 
        function classificationResults = classify(this, featureMatrix)
            classificationResults = struct;
            nClassifiers = numel(this.classifierList);
            nSamples = size(featureMatrix,1);
            
            if nClassifiers > 0
                classificationResults.classifiersOutput = zeros(nSamples,nClassifiers);
                for iClassifier = 1:nClassifiers
                    cClassifier = this.classifierList{iClassifier};
                    cLabels = cClassifier.classify(featureMatrix);
                    % fill into classifier output list
                    classificationResults.classifiersOutput(:,iClassifier) = cLabels;
                end
                % get most often chosen value (mode)
                classificationResults.labelsMajority = mode(classificationResults.classifiersOutput,2);
                % prediction certainty / agreement
                majorityRep = repmat(classificationResults.labelsMajority,1,nClassifiers);
                equalToMajority = classificationResults.classifiersOutput == majorityRep;
                classificationResults.classiferConfidence = sum(equalToMajority,2)/nClassifiers;  
            else
                warning('No classifiers in pipeline, All result labels will be set to 1.');
                classificationResults.classiferConfidence = zeros(nSamples,1);
                classificationResults.labelsMajority = ones(nSamples,1);
                classificationResults.classifiersOutput = ones(nSamples,1);
            end
        end       
        

                
                
        
        
      end % end methods public ____________________________________________
    



end

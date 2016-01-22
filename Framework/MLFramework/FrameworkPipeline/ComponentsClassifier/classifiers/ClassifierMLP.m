% Class definition ClassifierMLP
% 
% This realizes a Multi-Layer Perceptron classifier (from Matlab Toolbox)
%
% author Fabian Bürger, University Duisburg-Essen

classdef ClassifierMLP < ClassifierAbstract
    %====================================================================
    properties
        classIds = [];
    end
    
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % constructor
        function obj = ClassifierMLP()
            obj.classifierName='ClassifierMLP';
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
            this.classIds = [];
        end        
        
        %__________________________________________________________________
        % train classifier with training data of n oversations and m
        % feature dimensions
        % -featureMatrix : n x m matrix 
        % -targetClasses : n x 1 vector with numeric labels (ground truth)  
        function trainClassifier(this,featureMatrix,targetClasses)

            % get neuronal codes class ids (class 3 eg. becomes [0 0 1])
            this.classIds = unique(targetClasses);
            targetsNeuronal = classIndicesToNeuralVectors(this.classIds,targetClasses);
            
            % network structure and training parameters
            netStructure = this.classifierParams.nNeuronsPerLayer*ones(1,this.classifierParams.nHiddenLayers);
            net = feedforwardnet(netStructure);
            net.trainParam.showWindow = false;
            %net.trainParam.epochs = 3;
            net.trainParam.time = 20; % max train time in seconds
            %net.divideParam.valRatio = 0; %no stopping before
            %net.divideParam.trainRatio = 1; %no internal cross validation
            
            % input m feat x n vectors
            % output m outdim x n vectors
            net = train(net,featureMatrix',targetsNeuronal');
            this.classifierModel = net;
        end              
        
        %__________________________________________________________________
        % classify data given as featureMatrix with n instances and m
        % feature dimensions
        % -featureMatrix -> n x m matrix       
        function results = classify(this,featureMatrix)
            outputs = sim(this.classifierModel,featureMatrix');
            results = neuralVectorsToClassLabels(this.classIds,outputs');           
        end  
        
        
    
    end % end methods
    
end

       

%==================================

% convert a class index to multidimensional target vector 
% eg. 2 of classes [1,2,3] becomes [0 1 0]
% input:
% classIdList -> numeric class indices e.g. [1 2 3]
% targetLabels -> target labels, n element row vector for n feature vectors
% NOTE: Each vectors are put in rows, therefore transpose before put to
% matlab neural net!
function neuralVectors = classIndicesToNeuralVectors(classIdList,targetLabels)
    nSamples = size(targetLabels,1);
    if size(classIdList,1) > size(classIdList,2)
        classIdList = classIdList';
    end
    neuralVectors = repmat(classIdList,[nSamples,1]);
    for ii=1:nSamples
        neuralVectors(ii,:) = neuralVectors(ii,:) == targetLabels(ii);
    end
end


% neuronal network multiclass output to most likely classlabel
% e.g.  [0 0.9 0.1] -> 2
% classIdList -> numeric class indices e.g. [1 2 3]
% neuralOutputs -> [0 0.9 0.1]
% NOTE: Each vectors are put in rows, therefore transpose needed for
% matlab neural net!
function labels = neuralVectorsToClassLabels(classIdList,neuralOutputs)
    nSamples = size(neuralOutputs,1);
    labels = zeros(nSamples,1);
    for ii=1:nSamples
        cRow = neuralOutputs(ii,:);
        [maxVal, maxInd] = max(cRow);
        labels(ii) = classIdList(maxInd);
    end
end

        
        
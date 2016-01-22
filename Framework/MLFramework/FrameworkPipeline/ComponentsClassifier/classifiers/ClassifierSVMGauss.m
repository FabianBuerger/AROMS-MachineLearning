% Class definition ClassifierSVMGauss
% 
% This realizes a SVM with a Gaussian kernel and penalty parameter C (CSVM)
% It is based on libSVM.
%
% author Fabian Bürger, University Duisburg-Essen

classdef ClassifierSVMGauss < ClassifierAbstract
    %====================================================================
    properties 
    end
    
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % constructor
        function obj = ClassifierSVMGauss()
            obj.classifierName='SVMGauss';
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
            
            %LibSVm Params
            % options:
            % -s svm_type : set type of SVM (default 0)
            % 	0 -- C-SVC
            % 	1 -- nu-SVC
            % 	2 -- one-class SVM
            % 	3 -- epsilon-SVR
            % 	4 -- nu-SVR
            % -t kernel_type : set type of kernel function (default 2)
            % 	0 -- linear: u'*v
            % 	1 -- polynomial: (gamma*u'*v + coef0)^degree
            % 	2 -- radial basis function: exp(-gamma*|u-v|^2)
            % 	3 -- sigmoid: tanh(gamma*u'*v + coef0)
            % -d degree : set degree in kernel function (default 3)
            % -g gamma : set gamma in kernel function (default 1/num_features)
            % -r coef0 : set coef0 in kernel function (default 0)
            % -c cost : set the parameter C of C-SVC, epsilon-SVR, and nu-SVR (default 1)
            % -n nu : set the parameter nu of nu-SVC, one-class SVM, and nu-SVR (default 0.5)
            % -p epsilon : set the epsilon in loss function of epsilon-SVR (default 0.1)
            % -m cachesize : set cache memory size in MB (default 100)
            % -e epsilon : set tolerance of termination criterion (default 0.001)
            % -h shrinking: whether to use the shrinking heuristics, 0 or 1 (default 1)
            % -b probability_estimates: whether to train a SVC or SVR model for probability estimates, 0 or 1 (default 0)
            % -wi weight: set the parameter C of class i to weight*C, for C-SVC (default 1)
            % 
            % The k in the -g option means the number of attributes in the input data.
  
            paramString = ['-s 0 -t 2 -c ' sprintf('%0.5f',this.classifierParams.C) ' -g ' sprintf('%0.5f',this.classifierParams.gamma)];     
            
%             dataDebug = struct;
%             dataDebug.targetClasses = targetClasses;
%             dataDebug.featureMatrix = featureMatrix;
%             dataDebug.paramString = paramString;
%             fname = sprintf('svmdata_%0.12f.mat',now);
%             save(['debug/' fname],'dataDebug');         
            
            this.classifierModel = svmtrain(targetClasses, featureMatrix, paramString); % Gaussian kernel C-SVM

            % test data
            %[predict_label, accuracy, dec_values] = svmpredict(labels, features, model);         
            
            
        end              
        
        %__________________________________________________________________
        % classify data given as featureMatrix with n instances and m
        % feature dimensions
        % -featureMatrix -> n x m matrix       
        function results = classify(this,featureMatrix)
           labels = ones(size(featureMatrix,1),1); % random labels necessary for libSVM
           results = svmpredict(labels, featureMatrix, this.classifierModel);                
        end  
        
        
    
    end % end methods
    
end

       

        
        
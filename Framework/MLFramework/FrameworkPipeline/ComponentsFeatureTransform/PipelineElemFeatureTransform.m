% Class definition PipelineElemFeatureTransform
% 
% This class handles the feature transform (e.g. manifold learning or PCA)
% 
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef PipelineElemFeatureTransform < PipelineElement
    
    properties 
        % temporary dataset for training
        tempDataSet = [];
        
        % cache data for training
        cachedMappedDataSet = [];
        
        %dimension reduction toolbox methods with out-of-sample extension
        %(all the rest need the approximation estimation method)
        % this list is generated according to properties found in frameworkComponentLists
        featureTransformsWithExtension = {};        

        % set of functions that require the labels of the data
        % this list is generated according to properties found in frameworkComponentLists
        featureTransformsSupervised = {};   
        
        % plotting
        plotFeatureTransformedVectors = 0;
        plotFeatureTransformedVectorsNumberDimensions = 0;
        
        debugMode = 0;
    end
    
    %====================================================================
    methods
                 
        %__________________________________________________________________
        % constructor
        function obj = PipelineElemFeatureTransform()
            obj.elementStringName = 'FeatTransform';
            
            % get transforms with certain properties according to
            % frameworkComponentLists()
            
            basicComponents = frameworkComponentLists();
            
           featTransAll = fieldnames(basicComponents.featureTransformMethods);
            for ii=1:numel(featTransAll)
                cTrans = featTransAll{ii};
                cTransInfo = basicComponents.featureTransformMethods.(cTrans);
                if cTransInfo.active
                    % out-of-sample extension
                    if cellStringsContainString(cTransInfo.properties,'extension')
                        obj.featureTransformsWithExtension{end+1} = cTransInfo.name;
                    end
                    if cellStringsContainString(cTransInfo.properties,'supervised')
                        obj.featureTransformsSupervised{end+1} = cTransInfo.name;
                    end                    
                end
            end
        end    
            
        %__________________________________________________________________        
        % prepare element with parameters
        function dataOut = prepareElement(this,dataIn)
            timerTransform=tic;
            
            errorProcessing = 0;
            config = dataIn.config;
            dataSet = dataIn.dataSet;
            
            dataOut = struct;        
            dataOut.errorProcessing = 1;
            
            % set parameter
            this.elementState.featureTransformMethod = config.configFeatureTransform.featureTransformMethod;
            this.elementState.featureTransformParams = config.configFeatureTransform.featureTransformParams;
            this.elementState.featureTransformHyperparams = queryStruct(config.configFeatureTransform,'featureTransformHyperparams',struct);
                  
            % set data set
            instanceNumberBefore = size(dataSet.featureMatrix,1);
            
            % check dimensionality
            numberDimensions = queryStruct(this.elementState.featureTransformParams,'nDimensions','auto');
            
            %estimate dimensionality if applicaple
            dynamicDimensionality = 0;
            if ~isnumeric(numberDimensions) 
                numberDimensions = 0;
                dynamicDimensionality = 1;
            end
            
            numberDimensionsBefore = size(dataSet.featureMatrix,2);
            if numberDimensions > numberDimensionsBefore
                warning(sprintf('Feature Transform: Requested number dimensions (%d) higher than dataSet dimensionality (%d)',numberDimensions,size(dataSet.featureMatrix,2)));
                numberDimensions = numberDimensionsBefore;
            end            
            this.elementState.featureTransformParams.nDimensions = numberDimensions;
            
            %==============================================================
            
            if strcmp(this.elementState.featureTransformMethod,'none')
                % no transform -> use data set directly
                this.elementState.featureMapping = [];
                this.elementState.featureTransformParams.nDimensions = size(dataSet.featureMatrix,2);
            else
                if dynamicDimensionality
                    % IMPORTANT this is legacy code here... most of the
                    % times the dimension is estimated before in the
                    % classificationPipeline main class....
                    if this.elementState.featureTransformParams.estimateDimensionality 
                        %methodEstimaton = 'EigValueMin10PercentVariance';% estimator criterion: number PCA dimenions with variance of >= 10 %
                        methodEstimaton = 'PCAEigValSumCriterion'; % criterion: dimensions threshold with more than 80% of variance
                        numberDimensionsDestination = intrinsic_dim(dataSet.featureMatrix, methodEstimaton);
                        %fprintf('    Estimated dimensionality %d using PCA \n',round(numberDimensionsDestination))                        
                    else
                        %use percentage from evolutionary coding (value
                        %between 0 - 100 % of features before
                        numberDimensionsDestination = numberDimensionsBefore*this.elementState.featureTransformParams.dimensionalityPercentage/100;
                        %fprintf('    Percentage dimensionality %d (%0.2f percent) \n',round(numberDimensionsDestination),this.elementState.featureTransformParams.dimensionalityPercentage)      
                    end
                    
                    numberDimensions = max(1,min(numberDimensionsBefore, round(numberDimensionsDestination)));
                    this.elementState.featureTransformParams.nDimensions = numberDimensions;
                end
                
                % compute mapping with dimension reduction toolbox
                mappingType = this.elementState.featureTransformMethod;
                %warning('here should be try catch')
                try
                    featureMatrixBefore = dataSet.featureMatrix;
                    if cellStringsContainString(this.featureTransformsSupervised,mappingType)
                        % supervised method
                        % prepend label dimension (format for dimension
                        % reduction toolbox)
                        if this.debugMode
                            fprintf('   --ft:learnmodel: SUPERVISED\n');
                        end
                        featureMatrixBeforeWithLabels = [dataSet.targetClasses , featureMatrixBefore];
                        [mappedData, mapping] = compute_mapping_params(featureMatrixBeforeWithLabels, mappingType, numberDimensions,this.elementState.featureTransformHyperparams);                    
                    else
                        % unsupervised method
                        if this.debugMode
                            fprintf('   --ft:learnmodel: unsupervised\n');
                        end
                        [mappedData, mapping] = compute_mapping_params(featureMatrixBefore, mappingType, numberDimensions,this.elementState.featureTransformHyperparams);
                    end
                    %check if dimensionality was changed!
                    targetDimensionality = size(mappedData,2);
                    this.elementState.featureTransformParams.nDimensions = targetDimensionality;
                    
                    %dataSet.featureMatrix = mappedData; % short cut (not
                    %available for all methods)
                    
                    % store mapping data
                    this.elementState.featureMapping = mapping;    
                    
                    % check if out of sample estimation needs to be done
                    % (for this the storage of the original data and the
                    % projected data needs to be available. For the rest, there is a 
                    % built in out of sample extension)
                    if cellStringsContainString(this.featureTransformsWithExtension, mappingType)
                        % out of sample extension available from model
                        this.elementState.outOfSampleEstimationData = [];
                    else
                        % out of sample extension not available: store
                        % projected data and original data
                        this.elementState.outOfSampleEstimationData = struct;
                        if isfield(mapping,'conn_comp')
                            originalDataCut = featureMatrixBefore(mapping.conn_comp,:); %maybe not all points could have been projected
                        else
                            originalDataCut = featureMatrixBefore;
                        end
                        this.elementState.outOfSampleEstimationData.originalDataSet = originalDataCut;
                        this.elementState.outOfSampleEstimationData.mappedDataSet = mappedData;
                    end
                    
                    %perform out of sample extension/estimation
                    [dataSet.featureMatrix, outOfSampleError] = this.performOutOfSampleEmbedding(featureMatrixBefore);
                    if outOfSampleError
                        errorProcessing = 1;
                    end
                    % check if all points are embedded
                    if size(dataSet.featureMatrix ,1) ~= instanceNumberBefore
                        errorProcessing = 1;
                    end   
                    
                    % normalize values to harden against numerical
                    % instabilities ( rescale to 0-1 )
                    this.elementState.featureMappingNormalization = featurePreProc_compute(dataSet.featureMatrix, 'featureScaling01');
                    % normalize 
                    dataSet.featureMatrix = featurePreProc_transform(dataSet.featureMatrix, this.elementState.featureMappingNormalization);
                    
                catch
                    errorProcessing = 1;
                end                  
            end
            this.cachedMappedDataSet = dataSet;
            if errorProcessing
               % fprintf('ERROR Dimension Reduction mapping %s with %d of %d dimensions!\n',this.elementState.featureTransformMethod,numberDimensions,numberDimensionsBefore);
            end

            % return for preparation next element
            dataOut = struct;
            dataOut.dataSet = dataSet;
            dataOut.config = config;            
            dataOut.errorProcessing = errorProcessing;
            
            %plotting of dimension reduction
            if this.plotFeatureTransformedVectors
                plotDimensionReductionMapping(dataSet.featureMatrix, dataSet.targetClasses,...
                    this.plotFeatureTransformedVectorsNumberDimensions, dataSet.classNames);
            end   
            
            timePassed = toc(timerTransform);
            try
                if this.pipelineHandle.generalParams.advancedTimeMeasurements
                    if timePassed > this.pipelineHandle.generalParams.timeThreshSlow
                        fprintf(' !! AdvancedTimeMeasurement: Slow feature transform %s needed %0.2f min \n',this.elementState.featureTransformMethod, timePassed/60);
                    end
                end
            catch
            end
        end
        
        %__________________________________________________________________
        % perform mapping using either the out-of-sample extension provided
        % by some functions or an estimation based on the projected data
        %        
        function [dataMatrixOut, outOfSampleError] = performOutOfSampleEmbedding(this,dataMatrixIn)
            outOfSampleError = 1;
            try
                 if cellStringsContainString(this.featureTransformsWithExtension, this.elementState.featureTransformMethod)
                    if this.debugMode
                        fprintf('   --ft:embedding: extension available\n');
                    end
                    % out of sample extension available
                    dataMatrixOut = out_of_sample(dataMatrixIn, this.elementState.featureMapping);      
                 else
                    % out of sample extension not available -> use estimation
                    % based on projected data
                    % out of sample extension not available: store
                    % projected data and original data
                    if this.debugMode
                        fprintf('   --ft:embedding: estimation\n');
                    end
                    dataMatrixOut = out_of_sample_est(dataMatrixIn, ...
                        this.elementState.outOfSampleEstimationData.originalDataSet, ...
                        this.elementState.outOfSampleEstimationData.mappedDataSet);
                 end
                 % handle numerical issues...
                 if ~isreal(dataMatrixOut)
                    if this.debugMode
                        fprintf('   --ft:embedding: truncate imaginary data\n');
                    end                     
                     dataMatrixOut = real(dataMatrixOut);
                 end
                 if any(isnan(dataMatrixOut(:)))
                    if this.debugMode
                        fprintf('   --ft:embedding: remove NAN\n');
                    end                     
                     dataMatrixOut(isnan(dataMatrixOut)) = 0;
                 end   
                 if any(isinf(dataMatrixOut(:)))
                    if this.debugMode
                        fprintf('   --ft:embedding: remove inf\n');
                    end                     
                     dataMatrixOut(isinf(dataMatrixOut)) = 0;
                 end                    
                 
                 outOfSampleError = 0;
            catch
                dataMatrixOut = [];
                outOfSampleError = 1;
            end
        end
        
        %__________________________________________________________________
        % Main processing function of pipeline element
        %
        % Function: Perform feature transform/manifold learning/dimension
        % reduction
        %
        % Input: dataIn structure with field featureMatrix coming from
        % feature selection element
        %
        % Output: dataOut struct with transformed featureMatrix field
        
        function dataOut = process(this, dataIn)
            dataOut = dataIn;            
            
            % if a method should was applied
            if ~strcmp(this.elementState.featureTransformMethod,'none') 
                % call out of sample extension from dimension reduction
                % toolbox

               nDataPointsBefore = size(dataOut.featureMatrix,1);
               %perform out of sample extension/estimation
               dataOut.featureMatrix  = this.performOutOfSampleEmbedding(dataOut.featureMatrix);
               
               % normalize
               if isfield(this.elementState,'featureMappingNormalization')
                    dataOut.featureMatrix = featurePreProc_transform(dataOut.featureMatrix, this.elementState.featureMappingNormalization);   
               end
               
               if size(dataOut.featureMatrix,1) ~= nDataPointsBefore
                   fprintf('Projection Error in %s with %d dimensions - Items missing \n',this.elementState.featureTransformMethod, this.elementState.featureTransformParams.nDimensions);
                   error('Projection Error - Items missing');
               end
               if size(dataOut.featureMatrix,2) ~= this.elementState.featureTransformParams.nDimensions
                   fprintf('Projection Error in %s with %d dimensions - Dimensionality no reached \n', this.elementState.featureTransformMethod, this.elementState.featureTransformParams.nDimensions);
                   error('Projection Error - Dimensionality no reached');
               end               
            end       
            
            %plotting of dimension reduction
            if this.plotFeatureTransformedVectors
                plotDimensionReductionMapping(dataOut.featureMatrix, dataOut.targetClasses,...
                    this.plotFeatureTransformedVectorsNumberDimensions, dataOut.classNames);
            end            
            if this.debugMode
                targetSize = size(dataOut.featureMatrix);
                fprintf('   --ft:process: ok with %d x %d target featurematrix\n',targetSize(1),targetSize(2));
            end
        end
        
        
      end % end methods public ____________________________________________
    




end

        



% ----- helper -------








        

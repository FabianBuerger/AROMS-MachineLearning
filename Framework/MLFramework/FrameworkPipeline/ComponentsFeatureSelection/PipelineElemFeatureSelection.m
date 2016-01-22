% Class definition PipelineElemFeatureSelection
% 
% This class handles the feature subset selection
% 
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef PipelineElemFeatureSelection < PipelineElement
    
    properties 
    end
    
    %====================================================================
    methods
                 
        %__________________________________________________________________
        % constructor
        function obj = PipelineElemFeatureSelection()
            obj.elementStringName = 'FeatSelection';
           
        end    
            
        %__________________________________________________________________        
        % prepare element with parameters
        function dataOut = prepareElement(this,dataIn)           
            config = dataIn.config;
            dataSet = dataIn.dataSet;
            if ~islogical(config.configFeatureSelection.featureSubSet)
                error('non logical feature subset detected!')
            end
            
            % set element parameters for processing
            this.elementState.featureSubSet = config.configFeatureSelection.featureSubSet;
            
            % return for preparation next element
            dataOut = struct;
            dataOut.dataSet = this.process(dataSet);
            dataOut.config = config;
        end
        
        
        %__________________________________________________________________
        % Main processing function of pipeline element
        %
        % Function: Performs the selection of sub features (from list of 
        % feature channels names) and concatenates
        % all selected features to a single featureMatrix that is used in
        % the next steps. 
        %
        % Input: dataSet struct from preprocessing
        %
        % Output: dataSet struct with extra matrix featureMatrix (see
        % Function)
        % 
        % 
        function dataOut = process(this, dataIn)
            dataOut = dataIn;
            % concatenate feature matrix
            dataOut.featureMatrix = this.applySubSetSelection(dataOut.instanceFeatures,this.elementState.featureSubSet);
        end
        
     
        %__________________________________________________________________
        % apply the feature selection to the instance feature set.
        % Select fields in the instanceFeatures subset and concatenate them
        % to a feature matrix
        function featureMatrix = applySubSetSelection(this,instanceFeatures,featureSubSet)
            % first count concatenated dimensions to preallocate feaure
            % data matrix (for speed)
            concatenatedDimensions = 0;
            nSamples = 0;
            nSelected = sum(featureSubSet(:));
            featureSubSetString = cell(1,nSelected);
            allFieldNames = fieldnames(instanceFeatures);
            iF = 0;
            for iFeatSel = 1:numel(featureSubSet)
                selected = featureSubSet(iFeatSel); % bit string
                if selected == 1 
                    cName = allFieldNames{iFeatSel};
                    iF = iF+1;
                    featureSubSetString{iF} = cName;
                    cFeatData = instanceFeatures.(cName);
                    concatenatedDimensions = concatenatedDimensions + size(cFeatData,2);
                    nSamples = size(cFeatData,1);                    
                end
            end
            
            if concatenatedDimensions == 0
                error('Feature Selection: Empty Feature Sub Set chosen.');
            end
            featureMatrix = zeros(nSamples,concatenatedDimensions);
            
            % fill the columns of the feature matrix
            cColIndex = 1;
            for iFeatSel = 1:numel(featureSubSetString)
                cName = featureSubSetString{iFeatSel};
                cFeatData = instanceFeatures.(cName);
                featureMatrix(:,cColIndex: (cColIndex+size(cFeatData,2)-1)) = cFeatData;
                cColIndex = cColIndex + size(cFeatData,2);
            end         
        end        
        
        
%         %__________________________________________________________________
%         % apply the feature selection to the instance feature set.
%         % Select fields in the instanceFeatures subset and concatenate them
%         % to a feature matrix
%         function featureMatrix = applySubSetSelectionString(this,instanceFeatures,featureSubSet)
%             % first count concatenated dimensions to preallocate feaure
%             % data matrix (for speed)
%             concatenatedDimensions = 0;
%             nSamples = 0;
%             for iFeatSel = 1:numel(featureSubSet)
%                 cName = featureSubSet{iFeatSel};
%                 cFeatData = instanceFeatures.(cName);
%                 concatenatedDimensions = concatenatedDimensions + size(cFeatData,2);
%                 nSamples = size(cFeatData,1);
%             end
%             
%             if concatenatedDimensions == 0
%                 error('Feature Selection: Empty Feature Sub Set chosen.');
%             end
%             featureMatrix = zeros(nSamples,concatenatedDimensions);
%             
%             % fill the columns of the feature matrix
%             cColIndex = 1;
%             for iFeatSel = 1:numel(featureSubSet)
%                 cName = featureSubSet{iFeatSel};
%                 cFeatData = instanceFeatures.(cName);
%                 featureMatrix(:,cColIndex: (cColIndex+size(cFeatData,2)-1)) = cFeatData;
%                 cColIndex = cColIndex + size(cFeatData,2);
%             end       
%         end
%         
        
      end % end methods public ____________________________________________
    




end

        



% ----- helper -------




        

% Class definition DataSetCheck
% This class checks the machine learning data sets if 
% - all fields are available
% - the dimensions are correct
% - NaN/Inf values appear and correct them
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef DataSetPreparation < handle
    
    properties 
        
    end
    
    %====================================================================
    methods    
    end % end methods public ____________________________________________
    
    
     methods(Static = true)
    
        %__________________________________________________________________
        % check dataSet and repair if necessary.
        % 
        % These fields should be provided for a proper dataset:
        %
        % dataSet.dataSetName = string data set name
        % dataSet.instanceFeatures = m sub feature vectors: n x num_feat_i
        % dataSet.targetClasses = ground truth classes n x 1
        % dataSet.classNames = string classes for indices in targetClasses
        %
        function [dataSet, skipDataSet] = checkDataSet(dataSet,jobParams)
            skipDataSet = false;

            % order fieldnames alphabetically
            [dataSet.instanceFeatures, sortOrder] = orderStructLexicographically(dataSet.instanceFeatures);
            
            % perform splitting
            if jobParams.splitMultiChannelFeatures
                dataSet = dataSetSubFeatureDivision(dataSet);
            end

            if ~isfield(dataSet,'targetClasses')
                warning('Dataset problem: field targetClasses not available.')
                skipDataSet = true;
                return;
            end
            % check target classes
            if numel(dataSet.targetClasses)==0  
                warning('Dataset problem: field targetClasses is empty.')
                skipDataSet = true;
                return;                    
            end
            % check target classes
            if size(dataSet.targetClasses,2)~=1  
                warning('Dataset problem: field targetClasses must be column vector.')
                skipDataSet = true;
                return;                    
            end            
            % check target classes
            if ~isnumeric(dataSet.targetClasses) 
                warning('Dataset problem: field targetClasses must be numeric.')
                skipDataSet = true;
                return;                    
            end            
            % check numeration of classes is correct
            uniqueClasses = unique(dataSet.targetClasses(:));
            if numel(uniqueClasses) < 2
                warning('Dataset problem: field targetClasses contains less than 2 classes!')
                skipDataSet = true;
                return;                    
            end                
            if min(uniqueClasses) <= 0
                warning('Dataset problem: field targetClasses class indices must start with 1.')
                skipDataSet = true;
                return;                    
            end    
            if max(uniqueClasses) ~= numel(uniqueClasses)
                warning('Dataset problem: field targetClasses class indices must start with 1 and end with the number of classes. All inbetween indices must be used!')
                skipDataSet = true;
                return;                    
            end               
            if ~isfield(dataSet,'instanceFeatures')
                warning('Dataset problem: field instanceFeatures not available.')
                skipDataSet = true;
                return;
            end   
            if ~isstruct(dataSet.instanceFeatures)
                warning('Dataset problem: field instanceFeatures is not a struct with features.')
                skipDataSet = true;
                return;
            end              
            if ~isfield(dataSet,'classNames')
                warning('Dataset issue: field classNames not available. Using standard names.')
                uniqueClasses = unique(dataSet.targetClasses(:));
                dataSet.classNames = {};
                for iClass = 1:numel(uniqueClasses)
                    dataSet.classNames{end+1} = sprintf('Class%d',iClass);
                end
            end            
            if ~isfield(dataSet,'dataSetName')
                warning('Dataset issue: field dataSetName not available. Using standard.')
                dataSet.dataSetName = 'Dataset';
            end                 
             
            % get some information from data set
            dataSet.featureNames = fieldnames(dataSet.instanceFeatures);
            dataSet.nFeatures = numel(dataSet.featureNames);
            dataSet.nSamples = size(dataSet.targetClasses,1);        
            dataSet.classIds = unique(dataSet.targetClasses);
            dataSet.nClasses = numel(dataSet.classIds);
            disp('Dataset ok');
            if dataSet.nFeatures <= 0
                warning('Dataset problem: no features in dataSet.instanceFeatures provided.')
                skipDataSet = true;
                return;                
            end
            
            if dataSet.nSamples <= 0
                warning('Dataset problem: no instances in dataSet.targetClasses provided.')
                skipDataSet = true;
                return;                
            end            

            % check each feature channel
            featuresWithProblems = {};
            totalDimensionality = 0;
            % convert all fields to double values
            for iFeat = 1:numel(dataSet.featureNames)
               cField = dataSet.featureNames{iFeat};
               cData = double(getfield(dataSet.instanceFeatures,cField));
               dataSet.instanceFeatures = setfield(dataSet.instanceFeatures,cField,cData);
               totalDimensionality = totalDimensionality + size(cData,2);
               % check number
               if size(cData,1) ~= dataSet.nSamples
                    warning(['Dataset problem: feature ' cField ' has different number of entries than targetClasses. Removing field.'])
                    dataSet.instanceFeatures = rmfield(dataSet.instanceFeatures,cField);
               else
                   if any(isnan(cData(:))) || any(isinf(cData(:)))
                       featuresWithProblems{end+1} = cField;
                   end
               end
            end
            dataSet.totalDimensionality = totalDimensionality;

            if numel(featuresWithProblems) > 0
                choice = questdlg(['Warning: The following features contain NaNs or Infs: ' ...
                    cellArrayToCSVString(featuresWithProblems,', ')], ...
                 'Feature Data Warning', ...
                 'Stop','Repair','Stop');

                % Handle response
                switch choice
                    case 'Stop'
                        warning('User stopped, feature data problem.');
                        skipDataSet = true;
                        return;                               
                    case 'Repair'
                        warning('Repairing feature data (NaNs to 0 Infs to big numbers');
                        for iFeat = 1:numel(dataSet.featureNames)
                           cField = dataSet.featureNames{iFeat};
                           cData = getfield(dataSet.instanceFeatures,cField);
                           indexNaN = isnan(cData);
                           indexInfPlus = isinf(cData) & cData > 0;
                           indexInfMinus = isinf(cData) & cData < 0;
                           if any(indexNaN(:))
                              warning('> Found %d NaNs in feature %s\n',sum(indexNaN(:)),cField);
                           end
                           if any(indexInfPlus(:))
                              warning('> Found %d Positive Infs in feature %s\n',sum(indexInfPlus(:)),cField);
                           end
                           if any(indexInfMinus(:))
                              warning('> Found %d Negative Infs in feature %s\n',sum(indexInfMinus(:)),cField);
                           end                       
                           cData(indexNaN) = 0;
                           cData(indexInfPlus) = 100;
                           cData(indexInfMinus)= -100;
                           dataSet.instanceFeatures= setfield(dataSet.instanceFeatures,cField,cData);
                       end                            
                end
            end
        end
        
 
      end % end methods static ____________________________________________
                
    

    
    
end

        

       


% Class definition DataSetImporter
% This class imports machine learning datasets 
% to the internal data format
% Support for Comma/Tab/Separated data from e.g. UCI database
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef DataSetImporter < handle
    
    properties 
        
    end
    
    %====================================================================
    methods    
    end % end methods public ____________________________________________
    
    
     methods(Static = true)
    
        %__________________________________________________________________
        % Import datasets from plain csv or tab separated data from a text
        % file to the dataSet-format of the framework
        %
        % parameters 
        % - dataFile: file name of text data (csv or tab) with obervations
        % in rows, and features in columns!
        % - columnIndicesFeatures: vector with column indices which should
        % be used.
        % - columnIndexTargetClasses: index of column for target classes
        % - dataSetName: optional string with name for data set
        % - classNames: optional cell array of strings
        % - featureNames: optimal names for features
        % - classIdMappingOrder: optimal vector mapping targets, e.g.
        % [a1, a2, a3 ...] -> map a1 -> 1, a2 -> 2, a3 -> 3
        %      
        % Resulting dataSet structure is: 
        % dataSet.dataSetName = string data set name
        % dataSet.instanceFeatures = m sub feature vectors: n x num_feat_i
        % dataSet.targetClasses = ground truth classes n x 1
        % dataSet.classNames = string classes for indices in targetClasses  
        function dataSet = importTextDataSet(dataFile, columnIndicesFeatures, columnIndexTargetClasses, dataSetName, classNames, featureNames, classIdMappingOrder)
            dataSet = struct;
            dataSet.dataSetName = dataSetName;
            dataSet.instanceFeatures = struct;
            dataSet.classNames = classNames; 
            dataMatrix = load(dataFile);
            
            % map target classes
            targetClasses = dataMatrix(:,columnIndexTargetClasses);
            if ~isempty(classIdMappingOrder)
               targetClassesFinal = nan(size(targetClasses));
               for iMap =1:numel(classIdMappingOrder)
                    mapFrom = classIdMappingOrder(iMap);
                    mapEnd = iMap;
                    targetClassesFinal(targetClasses==mapFrom) = mapEnd;
               end
               if any(isnan(targetClassesFinal))
                   targetClassesFinal
                    error('Class Id mapping error. Missing entries.');
               end
               dataSet.targetClasses = targetClassesFinal;
            else
                % no mapping
               dataSet.targetClasses = targetClasses;
            end
            if numel(featureNames) > 0 && numel(featureNames) ~= numel(columnIndicesFeatures)
                warning('NUMEL of feature names does not match with given column number!') 
            end
            
            for iFeat=1:numel(columnIndicesFeatures)
                cColumnIndex = columnIndicesFeatures(iFeat);
                cDataColumn = dataMatrix(:,cColumnIndex);
                if numel(featureNames) == numel(columnIndicesFeatures)
                    featureName = featureNames{iFeat};
                else
                    featureName = ['F' num2str(iFeat)];
                end
                if isfield(dataSet.instanceFeatures,featureName)     
                    error('Data Import: Field %s already set!', featureName);
                else
                    dataSet.instanceFeatures = setfield(dataSet.instanceFeatures,featureName,cDataColumn);
                end
            end
        end
        
 
        
        %__________________________________________________________________
        % Import datasets from a struct array with fields.
        %
        % parameters 
        % - dataStructArray: the struct array
        % - dataSetName: a string with a name for the dataset
        % - fieldNamesFeatures: fields that will be added as features as
        % CELLARRAY of Strings
        % - fieldNameTargets: fieldname (single String) with the targets (classes)
        %      
        % Resulting dataSet structure is: 
        % dataSet.dataSetName = string data set name
        % dataSet.instanceFeatures = m sub feature vectors: n x num_feat_i
        % dataSet.targetClasses = ground truth classes n x 1
        % dataSet.classNames = string classes for indices in targetClasses  
        
        function dataSet = importStructArrayDataSet(dataStructArray, dataSetName, fieldNamesFeatures, fieldNameTargets)
          
            nSamples = numel(dataStructArray);
            
            % find class labels
            allClassNames = {};
            for iSample = 1:nSamples
                cLabel = getfield(dataStructArray(iSample),fieldNameTargets);
                allClassNames{end+1} = cLabel;
            end
            classNames = unique(allClassNames);
            targetClasses = zeros(nSamples,1);
            for iSample = 1:nSamples
                cLabel = getfield(dataStructArray(iSample),fieldNameTargets);
                indexInClassLabelList = 0;
                for iClassNamesUnique=1:numel(classNames)
                    if strcmp(cLabel,classNames{iClassNamesUnique})
                        indexInClassLabelList = iClassNamesUnique;
                    end
                end
                targetClasses(iSample) = indexInClassLabelList;
            end            
            
            if any(targetClasses==0)
                error('Class label error');
            end
            
            dataSet = struct;
            dataSet.dataSetName = dataSetName;
            dataSet.instanceFeatures = struct;
            dataSet.classNames = classNames;          
            dataSet.targetClasses = targetClasses; 
            
            for iFeat=1:numel(fieldNamesFeatures)
                cFeatName = fieldNamesFeatures{iFeat};
                
                if isfield(dataStructArray,cFeatName)
                    firstData = getfield(dataStructArray(1),cFeatName);
                    importField = 1;
                    if (size(firstData,1) > 1 && size(firstData,2) > 1)
                        importField = 0;
                        warning('Datafield %s is 2D!',cFeatName);
                    end     
                    if importField
                        featureDim = size(firstData,1)*size(firstData,2);
                        featureData = zeros(nSamples,featureDim);
                        for iSample = 1:nSamples
                           cData = getfield(dataStructArray(iSample),cFeatName);
                           featureData(iSample,:) = cData(:)';
                        end
                        dataSet.instanceFeatures = setfield(dataSet.instanceFeatures,cFeatName,featureData);
                    end
                else
                    warning('Datafield %s does not exist.',cFeatName);
                end
               
            end
        end
        
        
        %__________________________________________________________________
        % Subsample number of instances from a dataSet based on sampleRatio
        % sampleRatio is in range 0-1, e.g. for sampleRatio = 0.75,
        % 25% of sample instances will be removed.
        % Possible class inbalance will be kept. addSuffixName is a flat such that
        % the dataSetName will be change with a suffix
        %  "_subsample_0.75" e.g.
        
        function dataSetOut = dataSetSubNumberOfInstanceSubSampling(dataSetIn,sampleRatio, addSuffixName)
            % init rng to always have the same indices
            rng(1850932070);
            dataSetOut = randomInstanceSamplingRelative(dataSetIn, sampleRatio);
            if addSuffixName
                dataSetOut.dataSetName = sprintf('%s_subsample_%0.3f',dataSetOut.dataSetName,sampleRatio); 
            end
        end        
                
        
        %__________________________________________________________________
        % see dataSetSubNumberOfInstanceSubSampling but for a cell array of
        % datasets.
        
        function dataSetOutList = dataSetSubNumberOfInstanceSubSamplingList(dataSetInList,sampleRatio, addSuffixName)
            dataSetOutList = {};
            for ii=1:numel(dataSetInList)
                dataSetIn = dataSetInList{ii};
                 dataSetOut = DataSetImporter.dataSetSubNumberOfInstanceSubSampling(dataSetIn,sampleRatio, addSuffixName);
                 dataSetOut.InstancesSubSampleRatio = sampleRatio;
                 dataSetOutList{end+1} = dataSetOut;
            end
            rng('shuffle');
        end                
        
        
      end % end methods static ____________________________________________
                
    

    
    
end

        

       


% Class definition CrossValidationSetStore
%
% This class stores cross validation sets to reuse the same divison for the
% same datasets in different job/training processes
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef CrossValidationSetStore < handle
    
    properties 
        crossValSets = {};
    end
    
    %====================================================================
    methods

        %__________________________________________________________________
        % get a cross validation set for a specific dataSet name,
        % numberSamples and k. After generation it is stored in the storage
        % and the same division is returned on the next query
        function cvSet = getCrossValSet(this, dataSetName, nSamples, kVal)
            foundIndex = 0;
            for ii=1:numel(this.crossValSets)
                cCVSet = this.crossValSets{ii};
                if (strcmp(cCVSet.dataSetName,dataSetName) && ...
                        cCVSet.nSamples == nSamples && cCVSet.kVal == kVal)
                    foundIndex = ii;
                end
            end
            if foundIndex > 0
                % found it
                disp('> cross validation sets: Use cached divison');
                cvSet = this.crossValSets{foundIndex}.cvSet;
            else
                % not found
                disp('> cross validation sets: GENERATING set!');
                cvSet = generateCrossValidationIndexSets(nSamples,kVal);
                cvStorageItem = struct;
                cvStorageItem.cvSet = cvSet;
                cvStorageItem.dataSetName = dataSetName;
                cvStorageItem.nSamples = nSamples;
                cvStorageItem.kVal = kVal;
                this.crossValSets{end+1} = cvStorageItem;
            end
        end
        
        
        %__________________________________________________________________
        % save storage to file
        function saveToFile(this,fileName)
            try
               crossValSets=this.crossValSets;
               save(fileName,'crossValSets');
            catch
            end
        end

        
        %__________________________________________________________________
        % load storage from file
        function loadFromFile(this,fileName)
            try
               if exist(fileName,'file') == 2 
                   loadedData=load(fileName);
                   this.crossValSets = loadedData.crossValSets;
                   fprintf('Loaded %d cross validation sets\n',numel(crossValSets));
               end
            catch
            end            
        end        
    end
     
      methods(Access = private)
      
      end %private methods
        

    
    
end

        

        

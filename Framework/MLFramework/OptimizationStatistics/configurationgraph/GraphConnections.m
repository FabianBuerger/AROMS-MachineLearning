% Class definition GraphConnections
% This is a helper for a graph connection/edge handler for e.g. the
% configuration graph plot
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef GraphConnections < handle
    
    properties  
        % store connections and frequencies
        % each item is a struct with strings startName, endName, and
        % edgeWeight
        edgeItemList = {};
        % statistics
        edgeWeightMin = 0;
        edgeWeightMax = 0;
    end
    
    %====================================================================
    methods
                
            
        %__________________________________________________________________
        % clear edge connections
        function init(this)
            this.edgeItemList = {};
            this.edgeWeightMin = 0;
            this.edgeWeightMax = 0;            
        end
        
        
        %__________________________________________________________________
        % add connection from startName to endName with edgeWeight
        function updateConnection(this, startName, endName, edgeWeight)
            % first look if it already exists
            indexOfEdge = 0;
            for iItem = 1:numel(this.edgeItemList)
                cItem = this.edgeItemList{iItem};
                if strcmp(startName,cItem.startName) &&  strcmp(endName,cItem.endName)
                    indexOfEdge = iItem;
                end  
            end
            % add if not existing
            if indexOfEdge == 0
                newEdgeItem = struct;
                newEdgeItem.startName = startName;
                newEdgeItem.endName = endName;
                newEdgeItem.edgeWeight = 0;
                this.edgeItemList{end+1} = newEdgeItem;
                indexOfEdge = numel(this.edgeItemList);
            end
            % update connection
            this.edgeItemList{indexOfEdge}.edgeWeight = this.edgeItemList{indexOfEdge}.edgeWeight + edgeWeight;
        end
        
        %__________________________________________________________________
        % sort edges by connectionWeight (for painting reasons ascend)
        function sortEdges(this)
            [~,sortOrder] = sort(cellfun(@(v) v.edgeWeight,this.edgeItemList),'ascend');
            this.edgeItemList = this.edgeItemList(sortOrder);   
            this.edgeWeightMin = this.edgeItemList{1}.edgeWeight;
            this.edgeWeightMax = this.edgeItemList{end}.edgeWeight;  
            % add relative values
            for iItem = 1:numel(this.edgeItemList)
                cItem = this.edgeItemList{iItem};
                %cItem.relativeEdgeWeight =(cItem.edgeWeight-this.edgeWeightMin)/(this.edgeWeightMax-this.edgeWeightMin);
                cItem.relativeEdgeWeight = cItem.edgeWeight/this.edgeWeightMax;
                this.edgeItemList{iItem} = cItem;
            end            
        end
                


      end % end methods public ____________________________________________
    


end

        



% ----- helper -------




        

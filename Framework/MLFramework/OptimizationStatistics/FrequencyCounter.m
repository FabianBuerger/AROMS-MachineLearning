% Class definition FrequencyCounter
%
% This class handles the frequency analysis of items/components 
% (as strings) and creates histograms
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef FrequencyCounter < handle
    
    properties 
        itemList = {}
    end
    
    
       
   
   methods(Static = true)
   
       % get binary list of strings from subset 
       % e.g. stringSubSet = {a,c},stringFullSet = {a,b,c}, binVec = [1 0 1];
       % binVec = FrequencyCounter.getBinaryItemList(stringSubSet, stringFullSet)
       function binVec = getBinaryItemList(stringSubSet, stringFullSet)
           binVec = false(1,numel(stringFullSet));
           for ii = 1:numel(stringFullSet)
                if cellStringsContainString(stringSubSet,stringFullSet{ii})
                    binVec(ii) = true;
                end
           end
       end
   end
   
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % init the histogram with discrete items (strings as cell string)
        function initCounter(this,itemNames)
            this.itemList = {};
            for ii=1:numel(itemNames)
                cItem = struct;
                cItem.name = itemNames{ii};
                cItem.counter = 0;
                this.itemList{end+1} = cItem;
            end
        end
        
        
        %__________________________________________________________________
        % add item counter. itemNames is a cell array of identifiers
        % (strings) or a single string. value sets the amount each provided
        % item should be increased (typically 1)
        function addItemCounter(this,itemNames,deltaValue)
            if ~iscell(itemNames)
                itemNames = {itemNames};
            end
            
            for iItem=1:numel(itemNames)
                % find index
                indexDBfound = 0;
                cItemName = itemNames{iItem};
                for iDB=1:numel(this.itemList)
                    if strcmp(this.itemList{iDB}.name,cItemName)
                        indexDBfound = iDB;
                    end
                end
                if indexDBfound ~= 0
                    this.itemList{indexDBfound}.counter = ...
                    this.itemList{indexDBfound}.counter + deltaValue;
                else
                    warning('Item %s not found!',cItemName);
                end
            end
        end    
        
        
        %__________________________________________________________________
        % add item counter by binary vector (speed up), indices of
        % itemBinIndices must be equal to inital feature set
        % delta value sets the amount each provided
        % item should be increased (typically 1)
        function addItemCounterBin(this,itemBinIndices,deltaValue)
            for iItem=1:numel(itemBinIndices)
                if itemBinIndices(iItem)
                    this.itemList{iItem}.counter = ...
                    this.itemList{iItem}.counter + deltaValue;
                end
            end
        end    
        
        
        
        %__________________________________________________________________
        % order items by frequency
        function orderItemsByFrequency(this)
            [~,sortOrder] = sort(cellfun(@(v) v.counter,this.itemList),'descend');
            this.itemList = this.itemList(sortOrder);   
        end            
        
        %__________________________________________________________________
        % get data for plots and tables. Optional normFactor.
        function [itemStrings, itemFrequencies] = getData(this, normFactor)
            if nargin == 1
                normFactor = 1;
            end
            itemStrings = {};
            itemFrequencies = [];
            for iDB=1:numel(this.itemList)
                itemStrings{end+1} = this.itemList{iDB}.name;
                itemFrequencies(end+1) = this.itemList{iDB}.counter;
            end
            itemFrequencies = itemFrequencies*normFactor;
        end    
        
  
    end % end methods public ____________________________________________
   
    
    
end


        

        
% Class definition TimeSeriesStorage
%
% This class stores times series / index series and values (e.g. quality
% values)
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef TimeSeriesStorage < handle
    
    properties 

        % cell array of results (this class can handle several time series
        timeSeriesList = {};

        startTimer = 0;      
    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = TimeSeriesStorage()
            obj.setTrainStartTimeNow();
        end
        

        %__________________________________________________________________
        % reset the training storage        
        function setTrainStartTimeNow(this)
            this.startTimer = tic;
        end       
        
        
        %__________________________________________________________________
        % save time series to file        
        function saveToFile(this,fileName)
            timeSeriesList = this.timeSeriesList;
            save(fileName,'timeSeriesList','-v7.3');
        end            
        
        
        %__________________________________________________________________
        % load time series from file        
        function loadFromFile(this,fileName)
            load(fileName);
            this.timeSeriesList = timeSeriesList;
        end            
                
        %__________________________________________________________________
        % append a single data item dataItem to the timeSeriesId (string)
        % with time index now
        function appendValue(this, timeSeriesId, dataItem)
            % get or append time series
            [timeSeries, timeSeriesIndex] = this.getTimeSeries(timeSeriesId);
           
            tsItem = struct;
            tsItem.dataItem = dataItem;
            tsItem.index = numel(timeSeries.dataList)+1;
            tsItem.timePassedSinceStart = toc(this.startTimer);
            timeSeries.dataList{end+1} = tsItem;
            
            % write back
            this.timeSeriesList{timeSeriesIndex} = timeSeries;
        end        
   
        %__________________________________________________________________
        % get time series values by timeSeriesId
        function [tsValsY, tsValsIndex, tsValsTime] = getTimeSeriesValues(this,timeSeriesId)
            tsValsY = [];
            tsValsIndex = [];
            tsValsTime = [];
            
            timeSeriesIndex = 0;
            for ii=1:numel(this.timeSeriesList)
                cTs = this.timeSeriesList{ii};
                if strcmp(cTs.id,timeSeriesId)
                    timeSeriesIndex = ii;
                end
            end 
            if timeSeriesIndex > 0
               timeSeries = this.timeSeriesList{timeSeriesIndex};
               for ii=1:numel(timeSeries.dataList)
                    cItem = timeSeries.dataList{ii};
                    tsValsY(end+1) = queryStruct(cItem.dataItem,'value',0);
                    tsValsIndex(end+1) = cItem.index;
                    tsValsTime(end+1) = cItem.timePassedSinceStart;
               end
            end
        end
        
        %__________________________________________________________________
        % find time series by timeSeriesId or add if not exists      
        function [timeSeries, timeSeriesIndex] = getTimeSeries(this,timeSeriesId)
            timeSeriesIndex = 0;
            for ii=1:numel(this.timeSeriesList)
                cTs = this.timeSeriesList{ii};
                if strcmp(cTs.id,timeSeriesId)
                    timeSeriesIndex = ii;
                end
            end 
            if timeSeriesIndex == 0
               % not existing
               timeSeries = struct;
               timeSeries.id = timeSeriesId;
               timeSeries.dataList = {};
               this.timeSeriesList{end+1} = timeSeries;
               timeSeriesIndex = numel(this.timeSeriesList);
            else
               timeSeries = this.timeSeriesList{timeSeriesIndex};
            end
        end

        
        
        
        

      end % end methods public ____________________________________________

      
      
      
     methods(Static = true)
         
     end
      
      
      methods(Access = private)
      
      end %private methods
        

    
    
end

        

        

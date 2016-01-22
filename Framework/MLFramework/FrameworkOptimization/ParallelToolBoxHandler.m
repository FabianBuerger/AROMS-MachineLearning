% Class definition ParallelToolBoxHandler
%
% This class handles restarting the parallel pool (this might be necessary
% because of memory leaks
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef ParallelToolBoxHandler < handle
    
    properties 
        
        timerLastReset = 0;
        parallelToolboxActive = 1;
        parallelToolboxNumberWorkers = 2;      
        
        % time after that the pool should be restarted
        timeTresholdHours = 2; 
        parallelToolboxSaveMemory = 1;
        
    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = ParallelToolBoxHandler()
        end
        
      %__________________________________________________________________
        % handle opeining parallel pool      
        function restartParallelPool(this,forceRestartPool)
            if this.parallelToolboxActive
                parallelPoolSuccessful = 0;
                while ~parallelPoolSuccessful
                    try  
                        pool = gcp('nocreate');
                        if ~isempty(pool)
                            %parallel pool exists
                            if forceRestartPool || pool.NumWorkers ~= this.parallelToolboxNumberWorkers
                                % restart if necessary
                                delete(pool);   
                                pause(1)
                                parpool('local', this.parallelToolboxNumberWorkers);
                                pause(1)
                            end
                        else
                            % parallel pool does not exist -> start it
                            parpool('local', this.parallelToolboxNumberWorkers);
                        end

                        % switch off warnings (also on parallel pool)
                        pctRunOnAll switchOffWarnings();
                        parallelPoolSuccessful = 1;
                        this.timerLastReset = tic();
                    catch e
                        fprintf('Parallel Pool Error %s \n waiting... \n', e.message);
                        parallelPoolSuccessful = 0;
                        pause(30);
                        fprintf('Trying again!\n');
                    end
                end
                fprintf('Parallel Pool started!\n');
            end   
            switchOffWarnings();            
        end      
        
        
        %__________________________________________________________________
        % check if current time is over and restart parallel pool if
        % necessary
        function checkTimePassedAndRestartIfNecessary(this)
            if this.parallelToolboxSaveMemory && this.timerLastReset > 0
                timePassedHours = toc(this.timerLastReset)/(60*60);
                if timePassedHours > this.timeTresholdHours
                    if this.parallelToolboxActive
                        % start again
                        this.restartParallelPool(true);
                    end
                end
            end
        end                      
    
    end
    
    
    
    
    
end

        

        

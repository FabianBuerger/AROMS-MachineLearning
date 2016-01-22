% Class definition PipelineElement
% 
% This class is an abstract class for a pipeline element
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef PipelineElement < handle
    
    properties        
        % handle to "mother" pipeline data object
        pipelineHandle = 0;
        
        % parameters of this item
        elementParams;   
        
        % element string name (set in subclass)
        elementStringName = '';
        
        % saveable state of the element
        elementState = struct;
    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = PipelineElement()
        end
        

        % set parameters to element
        function setElementParams(this,params)
             this.elementParams = params;
        end
        
        
        %__________________________________________________________________
        % init the pipeline
        function init(this, pipelineHandle)
            % set handle to mother pipeline (e.g. for parameters or such)
            this.pipelineHandle = pipelineHandle;
        end
        
        
        %__________________________________________________________________
        % log or debug text message
        function log(this, messageText)
            if this.pipelineHandle.pipelineVerbose
                disp(messageText);
            end
        end            
        
        
      end % end methods public ____________________________________________
    



    methods(Abstract) % defined in subclasses     
        
        % prepare element in subclass and return data for preparation of
        % the next element
        dataOut = prepareElement(this,dataIn)
        
        % Main processing function of pipeline element
        % dataIn comes from the predecessor and dataOut is passed to the
        % successor
        dataOut = process(this,dataIn);
        
    end %abstract methods   


end

        



% ----- helper -------




        

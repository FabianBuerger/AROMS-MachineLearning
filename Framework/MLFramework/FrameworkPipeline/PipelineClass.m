% Class definition PipelineClass
% 
% This class is the basis for all (machine learning) pipelines. 
% It has very general functionality, e.g. it contains a list of pipeline
% elements that can be evaluated as a whole. More specialized functions
% have to be implemented into the subclasses
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef PipelineClass < handle
    
    properties 
        % struct with general parameters like result path and parallel information
        generalParams = struct;     
        
        % this cell array contains the list of pipelineComponents
        % class PipelineComponent
        pipelineElementList = {}; 
    
    end
    
    %====================================================================
    methods
         
        % constructor
        function obj = PipelineClass()

        end
        
            
        %__________________________________________________________________
        % init the pipeline with parameters
        function initParams(this,generalParams)
            this.generalParams = generalParams;
            % call subclass
            this.initPipelineElements();
        end
        
        
        %__________________________________________________________________
        % append a pipeline element
        function appendPipelineElement(this,pipelineElement)
            % init object and set reference to this pipeline object
            pipelineElement.init(this);
            % append to list
            this.pipelineElementList{end+1} = pipelineElement;
        end        
        
        
        %__________________________________________________________________
        % set parameters of the pipeline elements, the struct 
        % pipelineParams is passed to all pipeline elements
        function sendParametersToPipelineElements(this, pipelineParams)
            for iPipelineIndex = 1:numel(this.pipelineElementList)
                cPipelineElement = this.pipelineElementList{iPipelineIndex};
                cPipelineElement.setElementParams(pipelineParams);
            end            
        end      
          
         
        %__________________________________________________________________
        % get the pipeline element at a certain index
        function elem = getPipelineElementByIndex(this, index)
            elem = this.pipelineElementList{index};
        end    
        
        %__________________________________________________________________
        % returns the pipeline element with the specific name
        % If it was not found, the value 0 is returned
        function elem = getPipelineElementByName(this, elementStringName)
            foundIndex = 0;
            elem = 0;
            for iPipelineIndex = 1:numel(this.pipelineElementList)
                cPipelineElement = this.pipelineElementList{iPipelineIndex};
                if strcmp(cPipelineElement.elementStringName,elementStringName)
                    foundIndex = iPipelineIndex;
                end
            end       
            if foundIndex > 0
                elem = this.pipelineElementList{foundIndex};
            end
        end            
        
        
        %__________________________________________________________________
        % process all pipeline elements.
        % Note: For this, the subclass has to set up the pipelines properly
        function dataOut = processWholePipeline(this, dataIn)
            dataOut = [];
            if numel(this.pipelineElementList) > 0
                dataOut = this.processPipelinePart(dataIn, 1, numel(this.pipelineElementList));
            else
                warning('Empty pipeline!');
            end
        end        
        
        
        %__________________________________________________________________
        % get a list of all pipeline states to recover it from
        function stateList = getPipelineStates(this)
            stateList = cell(numel(this.pipelineElementList),1);
            for iPipelineIndex = 1:numel(this.pipelineElementList)
                cPipelineElement = this.pipelineElementList{iPipelineIndex};
                stateList{iPipelineIndex} = cPipelineElement.elementState;
            end
        end        
                
        
        %__________________________________________________________________
        % set the pipeline states to the pipeline elements
        function setPipelineStates(this, stateList)
            for iPipelineIndex = 1:numel(this.pipelineElementList)
                cPipelineElement = this.pipelineElementList{iPipelineIndex};
                cPipelineElement.elementState = stateList{iPipelineIndex};
            end
        end        
                        
        
        
        %__________________________________________________________________
        % process a part of the pipeline only, defined by start and end
        % index
        function dataOut = processPipelinePart(this, dataIn, indexStartElement, indexEndElement)
            dataOut = [];
            if numel(this.pipelineElementList) > 0
                if indexStartElement <= indexEndElement
                    dataOut = dataIn;
                    for iPipelineIndex = indexStartElement:indexEndElement
                        cPipelineElement = this.pipelineElementList{iPipelineIndex};
                        dataOut = cPipelineElement.process(dataOut);
                    end
                else
                    warning('Wrong pipeline element indices!');
                end
            else
                warning('Empty pipeline!');
            end
        end                 
                
        
        %__________________________________________________________________
        % remove all pipeline elements
        function clearPipeline(this)
            this.pipelineElementList = [];
        end           
        
        
    
      end % end methods public ____________________________________________
    

    methods(Abstract) % defined in subclasses  
        initPipelineElements(this);
    end %private methods   


end

        



% ----- helper -------




        

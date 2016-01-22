% Class definition PipelineElementTest
% 
% This class is just a testing element for the pipeline
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef PipelineElementTest < PipelineElement
    
    properties 
    end
    
    %====================================================================
    methods
                
        
        %__________________________________________________________________
        % constructor
        function obj = PipelineElementTest()
            obj.elementStringName = 'TestElement.Adder';
        end    
            
        %__________________________________________________________________        
        % prepare element with parameters
        function dataOut = prepareElement(this, dataIn)
            dataOut = dataIn;
            this.log(['PREPARE ELEMENT ' this.elementStringName]);
        end
        
        
        %__________________________________________________________________
        % Main processing function of pipeline element
        % dataIn comes from the predecessor and dataOut is passed to the
        % successor
        function dataOut = process(this, dataIn)
            this.log(['PROCESS ' this.elementStringName]);
            dataOut = dataIn;
            if isnumeric(dataIn)
                dataOut = dataIn+this.elementParams.amountAdding;
            end
        end
        
        
      end % end methods public ____________________________________________
    




end

        



% ----- helper -------




        

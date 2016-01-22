% Class definition GenomeInfoClass
% This class handles the genome info and allele ranges
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef GenomeInfoClass < handle
    
    properties 
        % genome and allele info
        genomePropertyList = {}
        
        % typeCoding CONSTANTS
        typeBitString = 1;
        typeSet = 2;
        typeNumberReal = 3;
        typeNumberInteger = 4;
        mutationMutationRoundValue = 0; % this is set every generation to N(0,1)
        mutationParams = struct;
    end
    
    %====================================================================
    methods
        
        %__________________________________________________________________
        % init and set parameters
        function init(this)
            this.mutationMutationRoundValue = randn();
        end        
        
        %__________________________________________________________________
        % append allele information / genetic BITSTRING
        % - name: a string description        
        % - nBits: number of bits for coding
        % - emptyBitsAllowed: flag wether zero only bitstrings are allowed
        % - probabilityThresh: value 0-1, 0.5 for equal likelyhood for 1
        % and 0 bits
        % - addInfo: optional data field
        function appendGenomeTypeBitString(this, name, nBits, emptyBitsAllowed, allBitsTrue, probabilityThreshInitial, addInfo)
            genProp = struct;
            genProp.type = this.typeBitString;
            genProp.name = name;
            genProp.nBits = nBits;
            genProp.probabilityThreshInitial = probabilityThreshInitial;
            genProp.mutationProbValuesBase = this.mutationParams.probMutationBitStringBitFlip*ones(1,nBits);
            
            genProp.emptyBitsAllowed = emptyBitsAllowed;
            genProp.allBitsTrue = allBitsTrue;
            genProp.addInfo = addInfo;
            this.genomePropertyList{end+1} = genProp;
        end        
        
        %__________________________________________________________________
        % append allele information / genetic SET
        %  - name: a string description        
        %  -itemSet: cell array of all possible items (e.g. strings)
        % - addInfo: optional data field        
        function appendGenomeTypeSet(this, name, itemSet, addInfo)
            genProp = struct;
            genProp.type = this.typeSet;
            genProp.name = name;            
            genProp.itemSet = itemSet;
            genProp.mutationProbValueBase = this.mutationParams.probMutationSet;
            
            genProp.nItemsSet = numel(itemSet);
            genProp.addInfo = addInfo;            
            this.genomePropertyList{end+1} = genProp;
        end            
        
        %__________________________________________________________________
        % append allele information / genetic REAL NUMBER (exponentially
        % scaled values are handled outside of this class)
        %  - name: a string description        
        %  - lowerBound: interval start
        %  - upperBound: inetrval end
        % - addInfo: optional data field        
        function appendGenomeTypeNumberReal(this, name, lowerBound, upperBound, addInfo)
            genProp = struct;
            genProp.type = this.typeNumberReal;
            genProp.name = name;            
            genProp.lowerBound = lowerBound;
            genProp.upperBound = upperBound;

            valueRange = abs(upperBound-lowerBound);
            genProp.mutationSigmaBase = this.mutationParams.probMutationStdAdaptiveRangePercentage*valueRange;

            genProp.addInfo = addInfo;            
            this.genomePropertyList{end+1} = genProp;
        end          
        
        %__________________________________________________________________
        % append allele information / genetic INTEGER NUMBER
        %  - name: a string description
        %  - lowerBound: interval start
        %  - upperBound: inetrval end
        % - addInfo: optional data field        
        function appendGenomeTypeNumberInteger(this, name, lowerBound, upperBound, addInfo)
            genProp = struct;
            genProp.type = this.typeNumberInteger;
            genProp.name = name;            
            genProp.lowerBound = lowerBound;
            genProp.upperBound = upperBound;
            valueRange = abs(upperBound-lowerBound);
            genProp.mutationSigmaBase = this.mutationParams.probMutationStdAdaptiveRangePercentage*valueRange;
            genProp.addInfo = addInfo;            
            this.genomePropertyList{end+1} = genProp;
        end     
        
        
        %__________________________________________________________________
        % generate a random individual consisting of all property ranges
        % defined in genomePropertyList
        function individual = generateRandomIndividual(this)
            individual = struct; 
            individual.propertyValues = {};
            individual.mutationValues = {};
            individual.fitness = NaN;
            individual.age = 0;
            for ii=1:numel(this.genomePropertyList)
                genProp=this.genomePropertyList{ii};
                [propValues, mutationValues] = this.generateRandomPropertyValue(genProp);
                individual.propertyValues{end+1} = propValues;
                individual.mutationValues{end+1} = mutationValues;
            end
        end          
        
        

        %__________________________________________________________________
        % generate a single random property depending on the type 1-4
        function [genValue, mutationValue] = generateRandomPropertyValue(this, genProp)
            mutationValue =[];
            % bit string generation
            if genProp.type == this.typeBitString
                mutationValue = genProp.mutationProbValuesBase;
                probTreshvalues = genProp.probabilityThreshInitial;
                % only true allowed, e.g. for feature selection
                if genProp.allBitsTrue 
                    genValue = true(1,genProp.nBits);
                else
                    if isempty(probTreshvalues)
                        % super random mode: get random global probability
                        %probTreshvalueGlobal = max(0.01,rand());
                        probTreshvalueGlobal =  0.5;
                        genValue = rand(1,genProp.nBits)<probTreshvalueGlobal;
                    else
                        % a probability value per bit
                        genValue = rand(1,genProp.nBits)<probTreshvalues;
                    end    
                    % empty not allowed -> find one bit randomly that is 1
                    if ~genProp.emptyBitsAllowed && ~any(genValue)
                        randIndex = randi(genProp.nBits);
                        genValue(randIndex) = true;
                    end       
                end                
            end
            % set generation
            if genProp.type == this.typeSet
                index = randi([1 genProp.nItemsSet],1,1);
                genValue =  genProp.itemSet{index};
                mutationValue = genProp.mutationProbValueBase;
            end
            % real number generation
            if genProp.type == this.typeNumberReal
                if isstruct(genProp.addInfo) && isfield(genProp,'addInfo') && isfield(genProp.addInfo,'initialRange') 
                    initLowerBound = genProp.addInfo.initialRange(1);
                    initUpperBound = genProp.addInfo.initialRange(2);
                else
                    initLowerBound = genProp.lowerBound;
                    initUpperBound = genProp.upperBound;                  
                end
                genValue = initLowerBound + rand()*(initUpperBound-initLowerBound);
                mutationValue = genProp.mutationSigmaBase;
            end
            % integer generation
            if genProp.type == this.typeNumberInteger
                if isstruct(genProp.addInfo) && isfield(genProp,'addInfo') && isfield(genProp.addInfo,'initialRange') 
                    initLowerBound = genProp.addInfo.initialRange(1);
                    initUpperBound = genProp.addInfo.initialRange(2);
                else
                    initLowerBound = genProp.lowerBound;
                    initUpperBound = genProp.upperBound;                  
                end                
                genValue = randi([initLowerBound, initUpperBound],1,1);   
                mutationValue = genProp.mutationSigmaBase;
            end
        end           

        %__________________________________________________________________
        % generate a child/offspring from a cell array of parents genomes
        % mutationParams is a struct with parameters
        function child = recombinationFromParents(this, parents, parentsFitnessValues)
            child = struct; 
            child.propertyValues = {};
            child.mutationValues = {};
            child.fitness = NaN;
            child.age = 0;
            nParents = numel(parents);
%             parentsFitnessValues = zeros(1,nParents);
%             for iPar = 1:nParents
%                 parentsFitnessValues(iPar) = parents{iPar}.fitness;
%             end            
            for iProp=1:numel(this.genomePropertyList)
                geneProperty=this.genomePropertyList{iProp};
                setGeneValuesParents = cell(nParents,1);
                mutationValsParents = cell(nParents,1);
                for iPar = 1:nParents
                    setGeneValuesParents{iPar} = parents{iPar}.propertyValues{iProp}; 
                    mutationValsParents{iPar} = parents{iPar}.mutationValues{iProp}; 
                end
                recombinedValue = this.recombinationSinglePropertyFromParents(setGeneValuesParents, parentsFitnessValues, geneProperty);
                recombinedValueMutation = this.recombinationMutationParams(mutationValsParents, parentsFitnessValues);
                child.propertyValues{end+1} = recombinedValue;
                child.mutationValues{end+1} = recombinedValueMutation;
            end
        end         
                
        
        %__________________________________________________________________
        % generate a recombined value for a gene from a set of genetic
        % values of the parents. geneProperty defines the value domain
        function recombinedValue = recombinationSinglePropertyFromParents(this, setGeneValuesParents, parentsFitnessValues, geneProperty)
            recombinedValue = [];
            % bit string 
            if geneProperty.type == this.typeBitString
                recombinedValue = false(1,geneProperty.nBits);
               for iBit = 1:geneProperty.nBits
                   % chose parent source for each bit independantly
                   cParentIndex = RouletteWheelSelection(parentsFitnessValues);
                   cParentBitStr = setGeneValuesParents{cParentIndex};
                   recombinedValue(iBit) = cParentBitStr(iBit);
               end
            end
            % set 
            if geneProperty.type == this.typeSet
               cParentIndex = RouletteWheelSelection(parentsFitnessValues);
               recombinedValue = setGeneValuesParents{cParentIndex};          
            end
            % real number 
            if geneProperty.type == this.typeNumberReal
               recombinedValue = weightedAverage(cell2mat(setGeneValuesParents), parentsFitnessValues);          
            end
            % integer 
            if geneProperty.type == this.typeNumberInteger
               recombinedValue = round(weightedAverage(cell2mat(setGeneValuesParents), parentsFitnessValues));                         
            end
        end
        
        
        %__________________________________________________________________
        % generate a recombined value for mutation parameters
        function mutationVal = recombinationMutationParams(this, mutationValsParents, parentsFitnessValues)
            nDim = numel(mutationValsParents{1});
            nParents = numel(mutationValsParents);
            mutationVal = zeros(1,nDim);
            
            mutationValsParentsMat = [];
            for iPar = 1:nParents
                mutationValsParentsMat = [mutationValsParentsMat; mutationValsParents{iPar}];
            end

            for iBit=1:nDim
                parValues = mutationValsParentsMat(:,iBit);
                mutationVal(iBit) = weightedAverage(parValues, parentsFitnessValues);    
            end

        end           
        
        %__________________________________________________________________
        % add random mutation to individual, all probablities are
        % multiplied with mutationFactor
        function individual = mutateIndividual(this, individual)
            for iProp=1:numel(this.genomePropertyList)
                geneProperty=this.genomePropertyList{iProp};
                cPropertyValue = individual.propertyValues{iProp};
                cMutationValue = individual.mutationValues{iProp};
                % bit string ---------
                if geneProperty.type == this.typeBitString
                   for iBit = 1:numel(cPropertyValue)
                        if rand() <= cMutationValue(iBit)
                             cPropertyValue(iBit) = ~cPropertyValue(iBit);
                        end
                        % mutate mutation parameter
                        
                   end
                end
                % set ---------------- 
                if geneProperty.type == this.typeSet
                    if rand() <= cMutationValue
                        newIndex = randi([1 geneProperty.nItemsSet],1,1);
                        cPropertyValue=geneProperty.itemSet{newIndex};
                   end
                end
                % real number -------
                if geneProperty.type == this.typeNumberReal
                    % add normal distributed value
                    cPropertyValue = cPropertyValue + randn()*cMutationValue;
                end
                % integer ----------
                if geneProperty.type == this.typeNumberInteger
                    % add normal distributed value
                    cPropertyValue = floor(cPropertyValue + randn()*cMutationValue);               
                end  
                % write back property value and mutation value
                individual.propertyValues{iProp} = cPropertyValue;
                individual.mutationValues{iProp} = this.mutateMutationValue(cMutationValue);
            end
        end          
        
        %__________________________________________________________________
        % check the value ranges to fit to the definded constraints
        function individual = rangeCheck(this, individual)
            for iProp=1:numel(this.genomePropertyList)
                geneProperty=this.genomePropertyList{iProp};
                cPropertyValue = individual.propertyValues{iProp};
                % bit string 
                if geneProperty.type == this.typeBitString
                    if ~geneProperty.emptyBitsAllowed
                        if sum(cPropertyValue) == 0
                            % put random bit
                            newIndex = randi([1 geneProperty.nBits],1,1);
                            cPropertyValue(newIndex) = true;
                        end
                    end
                    if geneProperty.allBitsTrue % only true allowed!
                        cPropertyValue = true(size(cPropertyValue));
                    end
                end
                % set 
                if geneProperty.type == this.typeSet
                    % should be ok!
                end
                % real number 
                if geneProperty.type == this.typeNumberReal
                    cPropertyValue = max(geneProperty.lowerBound, min(geneProperty.upperBound,cPropertyValue));
                end
                % integer 
                if geneProperty.type == this.typeNumberInteger
                    cPropertyValue = max(geneProperty.lowerBound, min(geneProperty.upperBound,round(cPropertyValue)));
                end  
                % write back value
                individual.propertyValues{iProp} = cPropertyValue;
            end
        end          
        
        
        %__________________________________________________________________
        % get string representation of property
        function str = getPropertyAsString(this, val)
            str = '';
            if isa(val,'char')
                % is string
                str = val;
            else
                if size(val,2) > 1
                   % bitstring
                   bitsSel = sum(val(:));
                   str = sprintf('%d selected: ',bitsSel);
                   maxBits = 200;
                   for ii=1:min(maxBits,numel(val))
                       str = [str sprintf('%d',val(ii))];
                   end
                   if numel(val) > maxBits
                       str = [str '...'];
                   end
                else
                   % numeric values
                    if abs(val-round(val)) < eps
                        % integer number
                        str = sprintf('%d',val);
                    else
                        % float number
                        str = sprintf('%0.3f',val);
                    end
                end
            end
        end     
        
        
        %__________________________________________________________________
        % apply originally proposed mutation of mutation value
        function mutValOut = mutateMutationValue(this, mutValIn)
            mutValOut = mutValIn;
            tau1 = 0.5;
            tau2 = 0.5;
            for ii=1:numel(mutValIn)
                mutValOut(ii) = mutValIn(ii)*exp(tau1*this.mutationMutationRoundValue + tau2*randn());
            end
        end     
        
        
        
        %__________________________________________________________________
        % get string represenation of individual values
        function str = individualAsString(this, individual)
            str = sprintf('%0.4f - %d - ',individual.fitness, individual.age);
            sep = ' - ';
            for ii=1:numel(individual.propertyValues)
                cProp= individual.propertyValues{ii};
                cstr=this.getPropertyAsString(cProp);
                str = [str cstr];
                if ii < numel(individual.propertyValues)
                    str =[str sep];
                end
            end
        end         
        
        
        %__________________________________________________________________
        % get table header for mutation values (CSV)
        function str = mutationTableHeader(this)
            str = '';
            sep = ',';
            for iProp=1:numel(this.genomePropertyList)
                geneProperty=this.genomePropertyList{iProp};
                if geneProperty.type == this.typeBitString
                    nItems = geneProperty.nBits;
                    for ij = 1:nItems
                        str = [str sprintf('%s_%d',geneProperty.name,ij) sep];
                    end                    
                else
                   str = [str geneProperty.name sep];
                end
            end
        end 
        
        %__________________________________________________________________
        % get string represenation of individual mutation values (CSV)
        function str = individualMutationInfoAsString(this, individual)
            str = '';
            sep = ',';
            for ii=1:numel(individual.propertyValues)
                cMut= individual.mutationValues{ii};
                for ij = 1:numel(cMut)
                    str = [str sprintf('%0.3f',cMut(ij)) sep];
                end
            end
        end         
                        
                
        
        %__________________________________________________________________
        % get string with info for genome
        function strLines = getGenomeInfo(this)
            strLines = {};
            strLines{end+1} = '==== Genome Info Overview';
            totalBit = 0;
            totalSet = 0;
            totalReal = 0;
            totalInt = 0;
            detailStrings = {};
            
             for iProp=1:numel(this.genomePropertyList)
                geneProperty=this.genomePropertyList{iProp};
                
                detailGeneInfo = sprintf('------ Gene %d    Type: ',iProp);
                
                % bit string ---------
                if geneProperty.type == this.typeBitString
                  totalBit = totalBit + geneProperty.nBits;
                  detailGeneInfo = [detailGeneInfo 'BITSTRING'];
                end
                % set ---------------- 
                if geneProperty.type == this.typeSet
                    totalSet = totalSet + 1;
                    detailGeneInfo = [detailGeneInfo 'SET'];
                end
                % real number -------
                if geneProperty.type == this.typeNumberReal
                    totalReal = totalReal+1;
                    detailGeneInfo = [detailGeneInfo 'REAL'];
                end
                % integer ----------
                if geneProperty.type == this.typeNumberInteger
                   totalInt = totalInt+1;
                   detailGeneInfo = [detailGeneInfo 'INTEGER'];
                end  
                detailGeneInfo = [detailGeneInfo '   Name: ' geneProperty.name];

                detailStrings = [detailStrings; {detailGeneInfo; struct2string(geneProperty);' '}];
                
             end
             totalVariables = totalBit+totalSet+totalReal+totalInt;
            
             strLines{end+1} = sprintf(' - Bit variables: %d\n - Set variables: %d\n - Real variables: %d\n - Integer variables: %d',...
               totalBit, totalSet, totalReal, totalInt);
             strLines{end+1} = sprintf('== Total genes: %d\n== Total variables: %d',numel(this.genomePropertyList),totalVariables);
             
             strLines{end+1} = '';
             strLines{end+1} = '===============================';
             strLines{end+1} = ''; 
             strLines = [strLines,detailStrings'];
             
        end       
        
        
        

      end % end methods public ____________________________________________
    



end

        



% ----- helper -------



        

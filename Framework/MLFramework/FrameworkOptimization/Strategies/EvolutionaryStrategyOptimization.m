% Class definition EvolutionaryStrategyOptimization
% This class is an implementation of evolutionary strategy optimization
% techniques.
%
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

classdef EvolutionaryStrategyOptimization < handle
    
    properties        
        % parameters
        nIndividualsInitial = 100; 
        nOptimizationGenerations = 10; 
        nParentsPerChild = 3; % rho 
        nChildrenPerGeneration = 50; % lambda (each round new children)
        generationPopulationSize = 50; % mu (new generation selection)
        generationPopulationSizeHighSelectionPressure = 20; % mu (new generation selection)
        rouletteWheelScaleMode = 1; % scale fitness weights to 0-1
        mutationParams = struct; % mutation rate parameters
        timeBudgetRandomSearchHours = 0.5; % only for random search
        evoOptStopCriterionNumberGenerationsWithNoImprovement = 4;
        evoOptNumberMinGenerations = 10; % minimal number generations
        selectionPressureGenerations  = 0; %rounds with high selection pressure
        evoOptMaxIndiviualAge = Inf; %Limited individual age, if inf this is switched off
        
        minDeltaFitness = 0.001;

        % switch search mode: {'randomSearch','evolutionary'}
        searchMode = 'evolutionary';
        
        verbose = 1;
        iEvolutionRound = 0;
        %------------------------------------------------------------------
        
        % genome information (value ranges/alleles)
        genomeInfo = 0;
        
        % optimization state variables
        % -----------------------------------------------------------------
        % the current population set
        currentPopulation = {};
        
        % external trigger to stop main loop 
        externalStopCriterion = 0;
        
        % stop optimization if no improvement is achieved
        internalStopCriterion = 0;
        
        % highMutationMode
        highMutationMode=0;
        selectionPressureGenerationCounter = 0;
        
        badFitnessTresh = 0.5; % 1/number classes
        
        % handle to evaluation function
        evaluationFunctionHandle = 0;
        
        % statistics
        timeSeriesStorage; % store time series
        bestFitnessOverall = 0;
        generationFitnessAverage = 0;
        
        timerStart = 0;
        
        statusTextFile = ''; % if filled with file name, status messages will be written here
        statusFileId = 0;
        writeStatusFile = 0;
        
        mutationInfoFile = ''; % if filled with file name, mutation development is filled here
        
    end
    
    %====================================================================
    methods
                
        %__________________________________________________________________
        % init and set parameters
        function init(this)
            this.genomeInfo = GenomeInfoClass();
            this.genomeInfo.init();
            this.currentPopulation = {};
            this.externalStopCriterion = 0;
                        
            this.timeSeriesStorage = TimeSeriesStorage();
        end
        
        
        %__________________________________________________________________
        % set mutation params
        function setMutationParams(this,pmutationParams)
            this.mutationParams = pmutationParams;
            this.genomeInfo.mutationParams = this.mutationParams;
        end
        
        %__________________________________________________________________
        % generate random population and set to current set
        function appendRandomPopulation(this)
            for ii=1:this.nIndividualsInitial
                this.currentPopulation{end+1} = this.genomeInfo.generateRandomIndividual();
            end
        end        
        
        
        %__________________________________________________________________
        % get the list of current population for evaluation
        function populationList = getCurrentPopulation(this)
             populationList = this.currentPopulation;
        end             
        
        %__________________________________________________________________
        % displays current population info
        function getCurrentPopulationInfo(this)
            nIndividuals = numel(this.currentPopulation);
            s=sprintf('------------------------\nCurrent population size: %d \n',nIndividuals);
            this.logStatus(s);
            s=sprintf('No    Fitness   Age   Properties \n');
            this.logStatus(s);
            for iPop=1:nIndividuals
                cPopVal = this.currentPopulation{iPop};
                cString = this.genomeInfo.individualAsString(cPopVal);
                s=sprintf('%03d  -  %s \n',iPop,cString); 
                this.logStatus(s);
            end
        end        
        
        %__________________________________________________________________
        % start evolutionary optimization process
        % - evalFunctionHandle is a function handle that is called to
        % evaluate the fitness of the individuals. It must have a parameter
        % to take the list of n individuals and must return the fitness
        % values (vector with n doubles in range 0-1 or NaN).
        function runEvolutionaryOptimization(this, evalFunctionHandle)
            
            % write state
            if ~isempty(this.statusTextFile)
                try
                    this.statusFileId = fopen(this.statusTextFile, 'at'); % append text
                    this.writeStatusFile = 1;
                catch 
                end
            end            
            
            this.timerStart = tic();
            this.evaluationFunctionHandle = evalFunctionHandle;
            
            % first: evaluate inital population
            s = sprintf('EvoOpt: Evaluation intial population...\n');
            this.logStatus(s);
            this.currentPopulation = this.evaluatePopulation(this.currentPopulation);
                         
            this.generationStatistics();
            
            if this.verbose
                this.getCurrentPopulationInfo();
            end            
            
            % perform evaluation rounds
            stopOptimization = 0;
            this.iEvolutionRound = 1;            
            while ~stopOptimization
                s = sprintf('==========================================================\n');
                this.logStatus(s);
                s=sprintf('EvoOpt: Generation %d / %d \n',this.iEvolutionRound,this.nOptimizationGenerations);                
                this.logStatus(s);
                
                % search mode switch
                if strcmp(this.searchMode,'randomSearch')
                    % RANDOM SEARCH
                    this.evolutionStrategyRandomSearch();
                elseif strcmp(this.searchMode,'evolutionary')
                    % STANDARD EVOLUTIONARY STRATEGY
                    this.evolutionStrategyStandard();    
                else
                   error('Search Mode %s not recognized',this.searchMode);
                end
                
                if this.verbose
                    this.getCurrentPopulationInfo();
                end                
                %make stats
                this.generationStatistics();
                
                % stop criteria---------------------
                this.iEvolutionRound = this.iEvolutionRound+1;
                stopOptimization = this.iEvolutionRound > this.nOptimizationGenerations;
                % special random search time budget
                timePassed = toc(this.timerStart);
                if strcmp(this.searchMode,'randomSearch')
                    if timePassed/3600 > this.timeBudgetRandomSearchHours
                        stopOptimization = 1;
                        disp('> Time Budget for Random Search reached.')
                    end
                end
                
                if this.internalStopCriterion || this.externalStopCriterion
                    stopOptimization = 1;
                end
            end
        end   
        
        %__________________________________________________________________
        % sort by fitness        
        function sortCurrentPopulationByFitness(this)
            [~,sortOrder] = sort(cellfun(@(v) v.fitness,(this.currentPopulation)),'descend');
            this.currentPopulation = this.currentPopulation(sortOrder);                 
        end
        
        
        %__________________________________________________________________
        % calculate current generation statistics
        function generationStatistics(this)    
            
            this.sortCurrentPopulationByFitness();
            fitnessVector = cell2mat(getCellArrayOfProperties(this.currentPopulation,'fitness'));
            
            generationBestFitness = fitnessVector(1);
            this.generationFitnessAverage = mean(fitnessVector);
            
            fitnessStd = std(fitnessVector);
            worstFitness = fitnessVector(end);
            
            if generationBestFitness > this.bestFitnessOverall
                this.bestFitnessOverall = generationBestFitness;
            end         
            
            dataItem = struct;
            dataItem.value = this.bestFitnessOverall;
            this.timeSeriesStorage.appendValue('bestFitnessOverall', dataItem);             
                        
            dataItem = struct;
            dataItem.value = generationBestFitness;
            this.timeSeriesStorage.appendValue('genBestFitness', dataItem);
            
            dataItem = struct;
            dataItem.value = this.generationFitnessAverage;
            this.timeSeriesStorage.appendValue('genMeanFitness', dataItem);            

            dataItem = struct;
            dataItem.value = fitnessStd;
            this.timeSeriesStorage.appendValue('genStdFitness', dataItem); 
            
            dataItem = struct;
            dataItem.value = worstFitness;
            this.timeSeriesStorage.appendValue('genWorstFitness', dataItem); 
            
            s=sprintf('==> OverallBest: %0.5f  GenerationBest: %0.5f  GenerationMean: %0.5f +- %0.5f  \n',...
                this.bestFitnessOverall,generationBestFitness,this.generationFitnessAverage,fitnessStd);
            this.logStatus(s);
            
            % analyzing stop criteria for too slow convergence
            minGenerations = this.evoOptNumberMinGenerations;
            minGenerations = max(this.evoOptStopCriterionNumberGenerationsWithNoImprovement,minGenerations);
            deltaGenerationsIndex = this.evoOptStopCriterionNumberGenerationsWithNoImprovement;
            
            [tyValsY, tsValsIndex, tsValsTime] = this.timeSeriesStorage.getTimeSeriesValues('bestFitnessOverall');
                                        
            if strcmp(this.searchMode,'evolutionary') && this.iEvolutionRound >= minGenerations
                deltaFitnessTermination = tyValsY(end) - tyValsY(end-deltaGenerationsIndex+1);
                s=sprintf('Fitness improvements criteria values: termination = %0.6f \n',deltaFitnessTermination);   
                this.logStatus(s);
                
                % termination
                if deltaFitnessTermination < this.minDeltaFitness
                     s=sprintf('No or too little fitness improvement!\n');
                     this.logStatus(s);
 %                   this.internalStopCriterion = 1; % direct stop
                     this.generationPopulationSize = this.generationPopulationSizeHighSelectionPressure; 
                     this.selectionPressureGenerationCounter = this.selectionPressureGenerationCounter+1;
                     if this.selectionPressureGenerationCounter > this.selectionPressureGenerations
                         disp('> Stop optimization!');
                         this.internalStopCriterion = 1;
                     end
                else
                    this.selectionPressureGenerationCounter = 0;
                end
                
            end
            
            % mutation stats
            if ~isempty(this.mutationInfoFile)
                if this.iEvolutionRound < 1 % append table header
                    appendText(this.mutationInfoFile,this.genomeInfo.mutationTableHeader());
                end
                 bestIndividual = this.currentPopulation{1};
                 appendText(this.mutationInfoFile,this.genomeInfo.individualMutationInfoAsString(bestIndividual));
            end
        end         
                     
        
        %__________________________________________________________________
        % Evolution Strategy: Random Search
        function evolutionStrategyRandomSearch(this)
            disp('EvoOpt: Random Search')
            % remove the whole population
            this.currentPopulation = {};
            % create random population
            this.appendRandomPopulation();
            % evaluate them!
            this.currentPopulation = this.evaluatePopulation(this.currentPopulation);                    
        end         
        
        %__________________________________________________________________
        % Evolution Strategy: Standard evolutionary strategy
        function evolutionStrategyStandard(this)
            disp('EvoOpt: Standard Strategy');
            
            % update mutation mutation value
            this.genomeInfo.mutationMutationRoundValue = randn();
            
            % update age of current population
            for iInd = 1:numel(this.currentPopulation)
                this.currentPopulation{iInd}.age = this.currentPopulation{iInd}.age+1;
            end
            
            % step1: generate offspring
            s=sprintf('EvoOpt: Generating %d children with %d parents\n',this.nChildrenPerGeneration,this.nParentsPerChild);
            this.logStatus(s);
            children = cell(this.nChildrenPerGeneration,1);
            parentFitnessVector = cell2mat(getCellArrayOfProperties(this.currentPopulation,'fitness'));
            % perform roulette wheel selection according to fitness
            if this.rouletteWheelScaleMode % relative roulette wheel selection mode
                % rescale weights
                minVal = 0.25; % worst genes are only 25% likely than fittest genes -> faster selection of better solution
                maxVal = 1;
                parentFitnessVector=scaleFitnessValues(parentFitnessVector,minVal,maxVal);
            end            
            for iChild=1:this.nChildrenPerGeneration
                cParents = cell(this.nParentsPerChild,1);
                cParentFitnessValues = zeros(this.nParentsPerChild,1);
                for iParents = 1:this.nParentsPerChild
                    parentIndex = RouletteWheelSelection(parentFitnessVector);
                    cParentFitnessValues(iParents) = parentFitnessVector(parentIndex);
                    cParents{iParents} = this.currentPopulation{parentIndex};
                end
                child = this.genomeInfo.recombinationFromParents(cParents,cParentFitnessValues);
                
                % mutate child
                child = this.genomeInfo.mutateIndividual(child);
                
                %check if all values are in the correct range
                child = this.genomeInfo.rangeCheck(child); 
                
                % add to list
                children{iChild} = child;
            end
            
            % evaluating new children
            s=sprintf('EvoOpt: Evaluating new children...');
            this.logStatus(s);
            children = this.evaluatePopulation(children);
                        
            %select new parents
            totalSet = [this.currentPopulation,children'];
            
            % update age and filter out too old individuals
            tooOldIndividualIndices = [];
            for iInd = 1:numel(totalSet)
                if totalSet{iInd}.age > this.evoOptMaxIndiviualAge
                    tooOldIndividualIndices(end+1) = iInd;
                end
            end
            fprintf('Age filter: %d individuals too old.\n',numel(tooOldIndividualIndices));
            totalSet(tooOldIndividualIndices) = [];
            
            %by fitness
            [~,sortOrder] = sort(cellfun(@(v) v.fitness,totalSet),'descend');
            totalSet = totalSet(sortOrder);   
            
            %select top items (and kill the items that are not fit enough
            nPopulationSize = min(numel(totalSet),this.generationPopulationSize);
            this.currentPopulation = totalSet(1:nPopulationSize);  
            
%             
        end         
        
                  
        
       
        %__________________________________________________________________
        % evaluate population and write fitness values to 
        function population = evaluatePopulation(this, population)
            nIndividuals = numel(population);
            tic;
            s=sprintf('EvoOpt: Evaluating fitness of %d individuals...\n',nIndividuals);
            this.logStatus(s);
            
            % get fitness values from function handle
            fitnessValues = this.evaluationFunctionHandle(population);
            % set nans and values < 0 to 0 -> will not be chosen
            fitnessValues(isnan(fitnessValues)) = 0;
            fitnessValues(fitnessValues<eps) = 0;
            % write back fitness values
            for ii=1:nIndividuals
                population{ii}.fitness = fitnessValues(ii);
            end
            
            % statistics
            nIndividualsBetterThanBest = sum(fitnessValues > this.bestFitnessOverall);
            dataItem = struct;
            dataItem.value = nIndividualsBetterThanBest;
            this.timeSeriesStorage.appendValue('nIndividualsBetterThanBest', dataItem);             
            dataItem = struct;
            dataItem.value = nIndividualsBetterThanBest/numel(fitnessValues);
            this.timeSeriesStorage.appendValue('nIndividualsBetterThanBestRatio', dataItem);               
            
            nIndividualsBetterThanAverage = sum(fitnessValues > this.generationFitnessAverage);
            dataItem = struct;
            dataItem.value = nIndividualsBetterThanAverage;
            this.timeSeriesStorage.appendValue('nIndividualsBetterThanAverage', dataItem);              
            dataItem = struct;
            dataItem.value = nIndividualsBetterThanAverage/numel(fitnessValues);
            this.timeSeriesStorage.appendValue('nIndividualsBetterThanAverageRatio', dataItem);                
            
            % bad individuals /worse than random guessing
            nIndividualsBad = sum(fitnessValues <= this.badFitnessTresh);
            dataItem = struct;
            dataItem.value = nIndividualsBad;
            this.timeSeriesStorage.appendValue('nIndividualsBad', dataItem);                

            dataItem = struct;
            dataItem.value = nIndividualsBad/numel(fitnessValues);
            this.timeSeriesStorage.appendValue('nIndividualsBadRatio', dataItem);               

            %------------            
                        
            s=sprintf('EvoOpt: Population Evaluation Done!\n');
            this.logStatus(s);
            toc;
        end      
        
        
        %__________________________________________________________________
        % log textmessage to console and, additionally to text file      
        function logStatus(this,textMessage)
            fprintf(textMessage);             
            if this.writeStatusFile
                fprintf(this.statusFileId,textMessage);  
            end            
        end
        
        
        %__________________________________________________________________
        % get genome stat info     
        function makeGenomeStatInfo(this,fileName)
            stringLines = this.genomeInfo.getGenomeInfo();
            saveMultilineString2File(stringLines,fileName);
        end        
  

      end % end methods public ____________________________________________
    



end

        



% ----- helper -------




        

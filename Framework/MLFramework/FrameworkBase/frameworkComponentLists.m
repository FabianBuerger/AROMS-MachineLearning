%function components = frameworkComponentLists()
% This function lists the base framework components of methods and portfolios.
% NOTE: Whenever a new function/class should be registered, it should
% appear here.
%
% It contains: 
% - optimization strategies class names
% - feature preprocessing methods
% - feature transform methods
% - classifier class names and parameters
% -...

function components = frameworkComponentLists()
components = struct;

%__________________________________________________________________________
% Optimization strategy subclasses (to be placed in
% MLFramework/FrameworkOptimization/Strategies/)
components.optimizationStrategyList = {...
    'StrategyTest',... % test some stuff
    'StrategyDenseGridSearch',... % make dense parameter grids
    'StrategyGridSearch', ...  % heuristic feature selection
    'StrategyEvolutionary'...  % Evolutionary optimization
    };


%__________________________________________________________________________
% feature pre processing methods

featurePreProcessingMethods = struct;
featurePreProcessingMethods.options = {'none','featureScalingStatistically', 'featureScaling01','preWhitening', 'normalization'};
featurePreProcessingMethods.optionNames = {'','Standardization',               'Rescaling',   'Pre-Whitening', 'L2-Normalization'};
components.featurePreProcessingMethods = featurePreProcessingMethods;


%__________________________________________________________________________
% feature transform and parameters
components.featureTransformMethods= struct;

maxkNeighbors = 20; % affects all methods having a nearest neighbor parameter

% no transform / identity
info = struct;
info.active = 1;
info.name = 'none'; % class name
info.displayName = 'no transform'; % name in graphs and plots
info.properties = {'unsupervised','extension','linear'};
info.params = struct; % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% Principal Component Analysis
info = struct;
info.active = 1;
info.name = 'PCA'; % class name
info.displayName = 'PCA'; % name in graphs and plots
info.properties = {'unsupervised','extension','linear'};
info.params = struct; % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% Independent Component Analysis 
info = struct;
info.active = 1;
info.name = 'FastICA'; % class name
info.displayName = 'Fast ICA'; % name in graphs and plots
info.properties = {'unsupervised','extension','linear'};
info.params = struct; % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% Kernel Principal Component Analysis Gauss
info = struct;
info.active = 1;
info.name = 'KernelPCAGauss'; % class name
info.displayName = 'Kernel-PCA Gauss'; % name in graphs and plots
info.properties = {'unsupervised','extension'};
info = addHypParamInfo(info,'gamma','realLog10',[-5, 2], [], 1);
components.featureTransformMethods.(info.name) = info; % add to components

% Kernel Principal Component Analysis Polynomial Kernel
info = struct;
info.active = 1;
info.name = 'KernelPCAPoly'; % class name
info.displayName = 'Kernel-PCA Poly'; % name in graphs and plots
info.properties = {'unsupervised','extension'};
info     = addHypParamInfo(info,'c','real',[0 10],[],1); % hyperparams
info     = addHypParamInfo(info,'degree','int',[1 3],[],3); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% AutoEncoder
info = struct;
info.active = 1;
info.name = 'AutoEncoder'; % class name
info.displayName = 'AutoEncoder'; % name in graphs and plots
info.properties = {'unsupervised','extension'};
info     = addHypParamInfo(info,'lambda','real',[0 1],[], 0); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% LLE
info = struct;
info.active = 1;
info.name = 'LLE'; % class name
info.displayName = 'LLE'; % name in graphs and plots
info.properties = {'unsupervised','extension'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[], 12); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% Hessian LLE
info = struct;
info.active = 1;
info.name = 'HessianLLE'; % class name
info.displayName = 'Hessian LLE'; % name in graphs and plots
info.properties = {'unsupervised'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],12); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% Isomap
info = struct;
info.active = 1;
info.name = 'Isomap'; % class name
info.displayName = 'Isomap'; % name in graphs and plots
info.properties = {'unsupervised','extension'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],12); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% LandmarkIsomap
info = struct;
info.active = 1;
info.name = 'LandmarkIsomap'; % class name
info.displayName = 'Landmark Isomap'; % name in graphs and plots
info.properties = {'unsupervised','extension'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],12); % hyperparams
info     = addHypParamInfo(info,'percentage','real',[0 1],[],0.2); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% ManifoldChart
info = struct;
info.active = 1;
info.name = 'ManifoldChart'; % class name
info.displayName = 'Manifold Charting'; % name in graphs and plots
info.properties = {'unsupervised','extension'};
info     = addHypParamInfo(info,'no_analyzers','int',[1 100],[],40); % hyperparams
info     = addHypParamInfo(info,'max_iterations','int',[50 500],[],200); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% Laplacian Eigenmaps
info = struct;
info.active = 1;
info.name = 'LaplacianEigenmaps'; % class name
info.displayName = 'Laplacian Eigenmaps'; % name in graphs and plots
info.properties = {'unsupervised','extension'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],12); % hyperparams
info = addHypParamInfo(info,'sigma','realLog10',[-5, 2], [],1);
components.featureTransformMethods.(info.name) = info; % add to components

% LLTSA linear local tangent space alignment algorithm
info = struct;
info.active = 1;
info.name = 'LLTSA'; % class name
info.displayName = 'LLTSA'; % name in graphs and plots
info.properties = {'unsupervised','extension','linear'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],12); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% LTSA local tangent space alignment algorithm
info = struct;
info.active = 1;
info.name = 'LTSA'; % class name
info.displayName = 'LTSA'; % name in graphs and plots
info.properties = {'unsupervised'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],12); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% MVU Maximum Variance Unfolding 
info = struct;
info.active = 0;  %%off (implementation problems, not parallizable!)
info.name = 'MVU'; % class name
info.displayName = 'MVU'; % name in graphs and plots
info.properties = {'unsupervised'};
info.params = struct; % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% Fast MVU Maximum Variance Unfolding 
info = struct;
info.active = 0; %%off (implementation problems, not parallizable!)
info.name = 'FastMVU'; % class name
info.displayName = 'Fast MVU'; % name in graphs and plots
info.properties = {'unsupervised','extension'};
info.params = struct; % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% DiffusionMaps
info = struct;
info.active = 1;
info.name = 'DiffusionMaps'; % class name
info.displayName = 'Diffusion Maps'; % name in graphs and plots
info.properties = {'unsupervised'};
info     = addHypParamInfo(info,'t','int',[1 5],[],1); % hyperparams
info = addHypParamInfo(info,'sigma','realLog10',[-5, 2], [],1);
components.featureTransformMethods.(info.name) = info; % add to components

% SNE  Stochastic Neighbor Embedding
info = struct;
info.active = 1;
info.name = 'SNE'; % class name
info.displayName = 'SNE'; % name in graphs and plots
info.properties = {'unsupervised'};
info     = addHypParamInfo(info,'perplexity','int',[0 100],[],30); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% SymmetricSNE
info = struct;
info.active = 1;
info.name = 'SymmetricSNE'; % class name
info.displayName = 'Symmetric SNE'; % name in graphs and plots
info.properties = {'unsupervised'};
info     = addHypParamInfo(info,'perplexity','int',[0 100],[],30); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% tSNE  t Stochastic Neighbor Embedding
info = struct;
info.active = 1;
info.name = 'tSNE'; % class name
info.displayName = 't-SNE'; % name in graphs and plots
info.properties = {'unsupervised'};
info     = addHypParamInfo(info,'perplexity','int',[0 100],[],30); % hyperparams
info     = addHypParamInfo(info,'initial_dims','int',[0 50],[],30); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% tSNE  parametric t Stochastic Neighbor Embedding
info = struct;
info.active = 1;
info.name = 'paramtSNE'; % class name
info.displayName = 'param. t-SNE'; % name in graphs and plots
info.properties = {'unsupervised','extension'};
info     = addHypParamInfo(info,'neuronslayer1','int',[1 500],[],200); % hyperparams
info     = addHypParamInfo(info,'neuronslayer2','int',[1 500],[],200); % hyperparams
info     = addHypParamInfo(info,'neuronslayer3','int',[1 2000],[],1000); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% GPLVM
info = struct;
info.active = 1;
info.name = 'GPLVM'; % class name
info.displayName = 'GPLVM'; % name in graphs and plots
info.properties = {'unsupervised'};
info = addHypParamInfo(info,'sigma','realLog10',[-5, 2], [],1);
components.featureTransformMethods.(info.name) = info; % add to components

% LLC
info = struct;
info.active = 1;
info.name = 'LLC'; % class name
info.displayName = 'LLC'; % name in graphs and plots
info.properties = {'unsupervised'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],12); % hyperparams
info     = addHypParamInfo(info,'no_analyzers','int',[1 100],[],20); % hyperparams
info     = addHypParamInfo(info,'max_iterations','int',[50 500],[],200); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% CFA
info = struct;
info.active = 1;
info.name = 'CFA'; % class name
info.displayName = 'CFA'; % name in graphs and plots
info.properties = {'unsupervised'};
info     = addHypParamInfo(info,'no_analyzers','int',[1 100],[],40); % hyperparams
info     = addHypParamInfo(info,'max_iterations','int',[1 500],[],200); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% ConformalEigenmaps
info = struct;
info.active = 0;   %%off (-> implementation problems)
info.name = 'ConformalEigenmaps'; % class name
info.displayName = 'Conformal Eigenmaps'; % name in graphs and plots
info.properties = {'unsupervised'};
info.params = struct; % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% SPE
info = struct;
info.active = 1;
info.name = 'SPE'; % class name
info.displayName = 'SPE'; % name in graphs and plots
info.properties = {'unsupervised'};
info     = addHypParamInfo(info,'variant','set',{'Global', 'Local'},[],'Global'); % hyperparams
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],12); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% LPP
info = struct;
info.active = 1;
info.name = 'LPP'; % class name
info.displayName = 'LPP'; % name in graphs and plots
info.properties = {'unsupervised','extension','linear'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],12); % hyperparams
info = addHypParamInfo(info,'sigma','realLog10',[-5, 2], [],1);
components.featureTransformMethods.(info.name) = info; % add to components

% NPE
info = struct;
info.active = 1;
info.name = 'NPE'; % class name
info.displayName = 'NPE'; % name in graphs and plots
info.properties = {'unsupervised','extension','linear'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],12); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% Sammon Mapping
info = struct;
info.active = 1;
info.name = 'Sammon'; % class name
info.displayName = 'Sammon Mapping'; % name in graphs and plots
info.properties = {'unsupervised'};
info.params = struct; % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% FactorAnalysis
info = struct;
info.active = 1;
info.name = 'FactorAnalysis'; % class name
info.displayName = 'Factor Analysis'; % name in graphs and plots
info.properties = {'unsupervised','extension','linear'};
info.params = struct; % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% supervised LDA
info = struct;
info.active = 1;
info.name = 'LDA'; % class name
info.displayName = 'LDA'; % name in graphs and plots
info.properties = {'supervised','extension','linear'};
info.params = struct; % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% supervised KernelLDAGauss
info = struct;
info.active = 1;
info.name = 'KernelLDAGauss'; % class name
info.displayName = 'Kernel-LDA Gauss'; % name in graphs and plots
info.properties = {'supervised'};
info = addHypParamInfo(info,'gamma','realLog10',[-5, 2], [],1);
components.featureTransformMethods.(info.name) = info; % add to components

% supervised KernelLDAPoly
info = struct;
info.active = 1;
info.name = 'KernelLDAPoly'; % class name
info.displayName = 'Kernel-LDA Poly'; % name in graphs and plots
info.properties = {'supervised'};
info     = addHypParamInfo(info,'c','real',[0 10],[],1); % hyperparams
info     = addHypParamInfo(info,'degree','int',[1 3],[],3); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% supervised MCML
info = struct;
info.active = 1;
info.name = 'MCML'; % class name
info.displayName = 'MCML'; % name in graphs and plots
info.properties = {'supervised','extension','linear'};
info.params = struct; % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% supervised NCA
info = struct;
info.active = 1;
info.name = 'NCA'; % class name
info.displayName = 'NCA'; % name in graphs and plots
info.properties = {'supervised','extension','linear'};
info     = addHypParamInfo(info,'lambda','real',[0 1],[],0); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components

% supervised LMNN
info = struct;
info.active = 1;
info.name = 'LMNN'; % class name
info.displayName = 'LMNN'; % name in graphs and plots
info.properties = {'supervised','extension','linear'};
info     = addHypParamInfo(info,'kNeighbors','int',[1 maxkNeighbors],[],3); % hyperparams
components.featureTransformMethods.(info.name) = info; % add to components






%__________________________________________________________________________
% Classifiers and parameters
components.classifiers = struct;


% k Nearest Neighbor classifier -------
info = struct;
info.active = 1;
info.name = 'ClassifierKNN'; % class name
info.displayName = 'kNN'; % name in graphs and plots
info = addHypParamInfo(info,'kNeighbors','int',[1, 20],{[1], [1  3 10], [1:10 15 20 30 40 50 100]}, 3);
info = addHypParamInfo(info,'distanceMetric','set',{'euclidean', 'mahalanobis','cityblock','chebychev'},{{'euclidean'}, {'euclidean', 'mahalanobis','cityblock','chebychev'}, {'euclidean', 'mahalanobis','cityblock','chebychev'}}, 'euclidean');
components.classifiers.(info.name) = info; % add to components


% Naive Bayes ------
info = struct;
info.active = 1;
info.name = 'ClassifierNaiveBayes'; % class name
info.displayName = 'Naive Bayes'; % name in graphs and plots
info.params = struct;
components.classifiers.(info.name) = info; % add to components


% Linear C-SVM ------
info = struct;
info.active = 1;
info.name = 'ClassifierSVMLinear'; % class name
info.displayName = 'SVM linear'; % name in graphs and plots
info = addHypParamInfo(info,'C','realLog10',[-2, 4],{[1],  expRange(10, [-2, 0, 2]), expRange(10,-2:8)}, 1);
components.classifiers.(info.name) = info; % add to components


% Gaussian C-SVM ------
info = struct;
info.active = 1;
info.name = 'ClassifierSVMGauss'; % class name
info.displayName = 'SVM Gauss'; % name in graphs and plots
info = addHypParamInfo(info,'C','realLog10',[-2, 4],{[1],  expRange(10, [-2, 0, 2]), expRange(10,-2:8)}, 1);
info = addHypParamInfo(info,'gamma','realLog10',[-5, 2], {[0.1],  expRange(10, [-4, -1, 2]), expRange(10,-5:4)}, -1);
components.classifiers.(info.name) = info; % add to components


% Poly C-SVM ------
info = struct;
info.active = 1;
info.name = 'ClassifierSVMPoly'; % class name
info.displayName = 'SVM Poly'; % name in graphs and plots
info = addHypParamInfo(info,'C','realLog10',[-2, 4],{[1],  expRange(10, [-2, 0, 2]), expRange(10,-2:8)}, 1);
info = addHypParamInfo(info,'degree','int',[2, 5], {2, [2 3 4], 2:5}, 3);
components.classifiers.(info.name) = info; % add to components


% Multi Layer Perceptron ------
info = struct;
info.active = 1;
info.name = 'ClassifierMLP'; % class name
info.displayName = 'MLP'; % name in graphs and plots
info = addHypParamInfo(info,'nHiddenLayers',   'int',[0 3],{[0],[0 1 2], [0 1 2 3]}, 2 );
info = addHypParamInfo(info,'nNeuronsPerLayer','int',[1 30],{[5],[2 10 30], [2 5 10 30]}, 5);
components.classifiers.(info.name) = info; % add to components


% Random Forest Tree Bagger / Random Forest------
info = struct;
info.active = 1;
info.name = 'ClassifierRandomForest'; % class name
info.displayName = 'Random Forest'; % name in graphs and plots
info = addHypParamInfo(info,'nTrees','int',[10 500],{[20], [10 50 200] ,[10 20 50 100 150 200]}, 50);
components.classifiers.(info.name) = info; % add to components


% Extreme Learning Machine ------
info = struct;
info.active = 1;
info.name = 'ClassifierELM'; % class name
info.displayName = 'ELM'; % name in graphs and plots
info = addHypParamInfo(info,'nHiddenNeurons','int',[1 1000],{[20], [50 200 1000] ,[20 50 100 200 500]}, 100);
components.classifiers.(info.name) = info; % add to components




%-------- helper
% short notation for adding hyperparameters
% - info struct with component info
% - paramName: name of parameter (without white space!)
% - param type: 'int', 'realLog10', 'real', 'set'
% - paramRange: continous range of values
% - gridValues: grid values with discrete grid values, if {[],[],[]} is
% passed, different grid densities can be achieved

function info = addHypParamInfo(info,paramName,paramType,paramRange,gridValues,standardValue)

if ~isfield(info,'params')
    info.params = struct;
end
paramStr = struct;
paramStr.paramDescription = struct;
if ~cellStringsContainString({'int', 'realLog10', 'real', 'set'},paramType)
    error('Parameter type "%s" not recognized for parameter %s',paramType,paramName)
end
paramStr.paramDescription.type = paramType;  
paramStr.paramDescription.range = paramRange;
if ~iscell(gridValues)
    gridValues = {gridValues};
end
if numel(gridValues) == 1
    gridValues = {gridValues{1}, gridValues{1}, gridValues{1}};
end
paramStr.gridValues = gridValues;
paramStr.standardValue = standardValue;

if ~isfield(info.params,paramName)
    info.params.(paramName) = paramStr;
else
    error('Parameter %s already added!',paramName);
end






%function demoFeatureTransformVisualization
% 
% visualize feature transforms (and their out of sample extensions)
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function demoFeatureTransformVisualization()


% add path to framework
addpath(genpath([ '..' filesep 'MLFramework']));


%__________________________________________________________________________
% datasets

load('Datasets/dataSetUCI_statlogheart.mat'); % demo from UCI 
% https://archive.ics.uci.edu/ml/datasets/Statlog+%28Heart%29

% own dataset with classification of coins (and multidimensional features)
%load('Datasets/dataSetCoins.mat');

% dataset must be in workspace!



%__________________________________________________________________________
% Options
    
options = struct;
 

if ispc
   options.exportPath = ['C:/MLFrameworkResults/FeatureTransformVisualization/Test/']; % windows
else
    options.exportPath = ['~/MLFrameworkResults/FeatureTransformVisualization/Test/'] ; % linux
end

options.nDim = 4; % target dimensionality 1-4
options.showPlots = 1;
options.exportPlot = 1;

% select transforms
options.transformations = getFeatureTransformGroups('*'); % all
options.transformations = {'PCA','Isomap','LLE','tSNE'}; % subset
% options are:
% options.transformations = 
% { 'none','PCA','FastICA','KernelPCAGauss','KernelPCAPoly','AutoEncoder',...
%   'LLE','HessianLLE','Isomap','LandmarkIsomap','ManifoldChart',...
%   'LaplacianEigenmaps','LLTSA','LTSA','DiffusionMaps','SNE','SymmetricSNE',...
%   'tSNE','paramtSNE','GPLVM','LLC','CFA','SPE','LPP','NPE',...
%   'Sammon','FactorAnalysis','LDA','KernelLDAGauss','KernelLDAPoly','MCML',...
%   'NCA','LMNN'};

% run
featTransAnalysis = FeatureTransformAnalysis();
featTransAnalysis.visualizeDataSetMultipleTransforms(dataSet, options);

end






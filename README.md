# AROMS-MachineLearning

Automatic Representation Optimization and Model Selection Framework for Machine Learning - AROMS-Framework

This is the publication of the Matlab source code of the AROMS-Framework. It is the main contribution of my PhD project at the Intelligent Systems Group (Intelligente Systeme) of the University of Duisburg-Essen in Germany. 


Dipl.-Inf. Fabian Bürger, 22.01.2016


One way to contact me is the following: mail.fabian <at> gmx [.] de




== Application Field and Approach ==

The application field of the AROMS-Framework is the optimization of a data processing pipeline for the supervised classification problem. The pipeline is highly adaptable to every learning task and consists of four elements that process the data consecutively:

1) The feature selection element selects a useful feature subset

2) The feature preprocessing element applies data preprocessing methods such as rescaling, L2-normalization or prewhitening

3) The feature transform element applies a suitable feature transform from the field of manifold learning and representation learning such as Principal Component Analysis (PCA), Autoencoder or LLE (Locally Linear Embedding) 

4) The classifier element contains the classifier and offers several alternatives such as kernel Support Vector Machines (SVM), random forests or artificial neural networks.


An Evolutionary Algorithm called Evolutionary Configuration Adaptation (ECA) is used to optimize the pipeline configuration to a given training dataset. The ECA algorithm selects the feature subset, the preprocessing algorithm, the feature transform, the classifier and all hyperparameters based on cross-validation. Furthermore, the optimization trajectory is exploited to obtain a graph visualization of the best configurations (multi-configuration graph) and to improve the classification performance using a multi-pipeline classifier.




== System Requirements ==

The system was developed and tested for Matlab 2014b and Ubuntu Linux 14.04, however, tests on newer versions of Matlab and also under Windows were successful. Depending on the dataset size, > 8GB of RAM are useful.

The following Matlab toolboxes are required / very useful:
- Parallel Computing Toolbox for the parallel evaluation of individuals (optional)
- Neural Network Toolbox for some classifiers (optional)
- Statistics and Machine Learning Toolbox for random forest (optional)




== Framework Demo Scripts ==

Demo scripts to run the optimization and to use the resulting classification pipelines can be found in /Framework/MLFrameworkDemo/




== Framework Input Data ==

The framework solely requires a dataset structure with the training dataset, which contains the following data:
dataSet = struct:
  - dataSetName: string with a name, e.g., 'coinsClassification'
  - classNames: cell array with string class names, e.g., {'coins10ct'  'coins1ct'  'coins20ct'  'coins2ct'  'coins5ct'}
  - targetClasses: column vector with one class label per instance, [Nx1 double], e.g. [1; 1; 1; ... 2; 2; 2 ...], N = number of instances
- instanceFeatures: struct with feature data in groups (can be multidimensional), one field per feature group that contains a double matrix with a size of NxDi in which Di is the dimensionality of the ith feature group and N = number of instances. The lth row of every feature matrix represents the features of the lth instance and thus must match with the lth row of the targetClasses field.

See /Framework/MLFrameworkDemo/Datasets/ for exemplary datasets
Optionally, metaparameters to control the AROMS-Framework can be passed (see demo scripts) in classification jobs.




== Framework Results ==

The main results of an optimization run are saved in a subfolder of a result directory. It consists - amongst others - of the following lists, plots and data:
- [resultdir]/resultSummary.txt: Summary of results

- [resultdir]/tables/sortedConfigurationList.csv: Configuration list sorted by cross-validation accuracy
- [resultdir]/tables/compFreq_Classifiers_top50.csv: Frequency of classifiers under the best 50 configurations
- [resultdir]/tables/compFreq_FeaturePreprocessing_top50.csv: Frequency of feature preprocessing methods under the best 50 configurations
- [resultdir]/tables/compFreq_Features_top50.csv: Frequency of features under the best 50 configurations
- [resultdir]/tables/compFreq_FeatureTransforms_top50.csv: Frequency of features transforms under the best 50 configurations
- [resultdir]/tables/variableImportanceRandomForest.csv: Feature importance metric of random forest (used to improve the initial population)

- [resultdir]/plots/evoDev_fitness_generation.pdf: Fitness development over the generations
- [resultdir]/plots/evoDev_fitness_time.pdf: Fitness development over time
- [resultdir]/plots/ConfigurationGraph.pdf: Multi-configuration graph to visualize the best 50 configurations: features, feature transforms and classifiers. The feature groups are split into single feature channels.
- [resultdir]/plots/ConfigurationGraph_unsplit.pdf: Multi-configuration graph to visualize the best 50 configurations: features, feature transforms and classifiers. The feature groups are used directly.

- [resultdir]/multipipeline/AccuarcyPlotSimpleTop.pdf: Results of multi-pipeline classifier depending on the number of pipelines (if a test datasets is provided)

- [resultdir]/data/sortedConfigurationListTop.mat: Data of configurations




== Citation of the Framework ==

If you find the AROMS-Framework somehow useful and you like to cite it, please use the following data:

@incollection{buerger2015,
year={2015},
booktitle={Pattern Recognition: Applications and Methods - 4th International Conference, ICPRAM 2015, Lisbon, Portugal, January 10-12, 2015, Revised Selected Papers},
volume={9493},
series={Lecture Notes in Computer Science},
editor={Ana Fred and Maria De Marsico and Mário Figueiredo},
title={A Holistic Classification Optimization Framework with Feature Selection, Preprocessing, Manifold Learning and Classifiers},
publisher={Springer International Publishing},
author={B\"urger, Fabian and Pauli, Josef},
pages={52-68}
}




== Relevant Peer-Reviewed Publications ==

- [Bürger et al., 2014] Bürger, F., Buck, C., Pauli, J., and Luther, W. (2014). Image-based Object Classification of Defects in Steel using Data-driven Machine Learning Optimization. In Braz, J. and Battiato, S., editors, Proceedings of VISAPP 2014 - International Conference on Computer Vision Theory and Applications, volume 2, pages 143–152. SCITEPRESS, Lisbon, Portugal.

- [Bürger and Pauli, 2015a] Bürger, F. and Pauli, J. (2015). Automatic Representation and Classifier Optimization for Image-based Object Recognition. In Battiato, S. and Imai, F., editors, Proceedings of the 10th International Conference on Computer Vision Theory and Applications (VISAPP 2015), volume 2, pages 542–550. SCITEPRESS, Lisbon, Portugal.

- [Bürger and Pauli, 2015b] Bürger, F. and Pauli, J. (2015). A Holistic Classification Optimization Framework with Feature Selection, Preprocessing, Manifold Learning and Classifiers. In Fred, A., Marsico, M. D., and Figueiredo, M., editors, Pattern Recognition: Applications and Methods - 4th International Conference, ICPRAM 2015, Lisbon, Portugal, January 10-12, 2015, Revised Selected Papers, volume 9493 of Lecture Notes in Computer Science, pages 52–68. Springer International Publishing.

- [Bürger and Pauli, 2015c] Bürger, F. and Pauli, J. (2015). Representation Optimization with Feature Selection and Manifold Learning in a Holistic Classification Framework. In De Marsico, M. and Fred, A., editors, ICPRAM 2015 - Proceedings of the International Conference on Pattern Recognition Applications and Methods, volume 1, pages 35–44. SCITEPRESS, Lisbon, Portugal.

- [Bürger and Pauli, 2016] Bürger, F. and Pauli, J. (2016). Understanding the Interplay of Simultaneous Model Selection and Representation Optimization for Classification Tasks. International Conference on Pattern Recognition Applications and Methods ICPRAM 2016, Rome, Italy, 24.-26.02.2016, accepted.

My PhD thesis about the AROMS-Framework is going to be submitted and published soon. 




== Software license  ==

*My* code can be freely used for research and commercial purpose unless you leave my name inside of the comments. However, some files contain (partly slightly modified) versions of:

- Matlab Toolbox for Dimensionality Reduction, provided by Laurens van der Maaten, https://lvdmaaten.github.io/drtoolbox/
- LIBSVM library, Copyright (c) 2000-2014 Chih-Chung Chang and Chih-Jen Lin, https://www.csie.ntu.edu.tw/~cjlin/libsvm/
- Implementation of the Extreme Learning Machine, MR QIN-YU ZHU AND DR GUANG-BIN HUANG, http://www.ntu.edu.sg/eee/icis/cv/egbhuang.htm
- arrow.m, Arrow Drawing Library by  Dr. Erik A. Johnson, http://www.usc.edu/civil_eng/johnsone/
- csvimport.m, Import function for CSV files: Ashish Sadanandan
- vline.m and hline.m, functions to draw special lines, Brandon Kuczenski for Kensington Labs
- linspecer.m, color list of distinguishable and nice looking colors, Jonathan Lansey, March 2009-2013
- sort_nat.m for natural sorting of strings, Douglas M. Schwarz
- demo dataset Statlog (Heart), Gavin Brown. Diversity in Neural Network Ensembles. The University of Birmingham, 2004, https://archive.ics.uci.edu/ml/datasets/Statlog+%28Heart%29

I like to thank all these people for their contributions!

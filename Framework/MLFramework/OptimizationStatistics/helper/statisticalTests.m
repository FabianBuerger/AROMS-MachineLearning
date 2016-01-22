%function tteststats
% make ttest/welch test stats
%
% -------
% Author: Fabian Buerger, Intelligent Systems Group,
% University of Duisburg-Essen, Germany
% http://www.is.uni-due.de/
% 2013-2015

function testResults = statisticalTests(dataReference, dataComparison)

testResults = struct;

% welch test standard 5%, unequal variances -> equality cannot be assumed!
confidenceInterval = 0.05;
[h,p,ci,stats] = ttest2(dataReference,dataComparison,'Vartype','unequal','Alpha',confidenceInterval);

% alternatives
%[h,p,ci,stats] = ttest2(dataReference,dataComparison,'Alpha',confidenceInterval);
%[h,p,ci,stats] = ttest2(dataReference,dataComparison,'Vartype','unequal','Alpha',confidence,'Tail','right');

% -
testResults.h=h;
testResults.p=p;
testResults.stats = stats;

% make string
if mean(dataReference) < mean(dataComparison)
    testResults.direction = +1; % comparison value is larger
else
    testResults.direction = -1; % comparison value is smaller
end

if testResults.h % significant
    if testResults.direction > 0
        %testResults.stringMaker = '  $\oplus$'; 
        testResults.stringMaker = ' (!)'; 
    else
        %testResults.stringMaker = ' $\ominus$'; 
        testResults.stringMaker = ' (!)';
    end
else
    % not significant
   testResults.stringMaker = ''; 
    testResults.direction  = 0;
end




function changePathOfAnalysisState()


fileIn = '/media/Data/MlFrameworkResults/14-11-15/VISAPP15/analysisState.mat';
oldPath = '/home/buerger/mlFrameworkResults/';
newPath = '/media/Data/MlFrameworkResults/';

[pth,fle,ext]=fileparts(fileIn);

copyfile(fileIn,[pth filesep fle '_backup' ext]);
load(fileIn);

analysisState.generalParams.resultPath = repPath(analysisState.generalParams.resultPath, oldPath, newPath);
analysisState.generalParams.resultPathFinal = repPath(analysisState.generalParams.resultPathFinal, oldPath, newPath);

for ii=1:numel(analysisState.jobsSummary.jobInfos)
    fprintf('Job Summary %d \n',ii);
    analysisState.jobsSummary.jobInfos{ii}.job.jobParams.resultPath = repPath(analysisState.jobsSummary.jobInfos{ii}.job.jobParams.resultPath, oldPath, newPath);
    analysisState.jobsSummary.jobInfos{ii}.job.jobSummary.job.jobParams.resultPath = repPath(analysisState.jobsSummary.jobInfos{ii}.job.jobSummary.job.jobParams.resultPath, oldPath, newPath);
    analysisState.jobsSummary.jobInfos{ii}.job.jobSummary.job.jobSummary.job.jobParams.resultPath = repPath(analysisState.jobsSummary.jobInfos{ii}.job.jobSummary.job.jobSummary.job.jobParams.resultPath, oldPath, newPath);
end


for ii=1:numel(analysisState.trainingJobList)
    fprintf('Job List %d \n',ii);
    try
        analysisState.trainingJobList{ii}.jobParams.resultPath = repPath(analysisState.trainingJobList{ii}.jobParams.resultPath, oldPath, newPath);
        analysisState.trainingJobList{ii}.jobSummary.job.jobParams.resultPath = repPath(analysisState.trainingJobList{ii}.jobSummary.job.jobParams.resultPath, oldPath, newPath);
        analysisState.trainingJobList{ii}.jobSummary.job.jobSummary.job.jobParams.resultPath = repPath(analysisState.trainingJobList{ii}.jobSummary.job.jobSummary.job.jobParams.resultPath, oldPath, newPath);
    catch
        disp('job skipped');
    end
end

save(fileIn,'analysisState');


function strOut = repPath(strIn, search, replace)
    strOut = strrep(strIn,search,replace);


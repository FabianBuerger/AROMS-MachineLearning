% function subDirCreated = mkUnusedDir(baseDir, desiredSubDir)
% Makes a folder desiredSubDir in baseDir. The function keeps appending numbers to
% the desiredSubDir if there are similarly named dir already

function subDirCreated = mkUnusedDir(baseDir, desiredSubDir)
    foundFreeDirName = false;
    dirIndex = 0;
    while ~foundFreeDirName
        if dirIndex > 0
            subDirCreated = [desiredSubDir sprintf('%03d', dirIndex) filesep];
        else
            subDirCreated = [desiredSubDir filesep];
        end
	totalSubdir = [baseDir subDirCreated];
        if ~exist(totalSubdir,'dir')
            mkdir(totalSubdir);   
            foundFreeDirName = true;
        else
            dirIndex = dirIndex+1;
        end
    end



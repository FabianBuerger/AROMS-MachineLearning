% function sourceListOut = varsourcelist(sourceIn, fileFilter)
% gets variable files from a source which can be
% - a single file
% - a cell array of files
% - a folder -> all files in a folder fitting fileFilter (e.g. "*.mat")
% - a cell array of folders
% sourceListOut: returns a list of files

function fileList = varsourcelist(sourceIn, fileFilter)

fileList = {};

if iscell(sourceIn)
   sourceIn = sourceIn;
else 
   sourceIn = {sourceIn}; 
end
for ii=1:numel(sourceIn)
    source = sourceIn{ii};

    % check input
    typeSource = '';
    if exist(source,'file') == 2
        typeSource = 'file';
    else
        % probably dir
        if ~(strcmp(source(end),'/') ||strcmp(source(end),' \'))
            source = [source '/']; 
        end       
        if exist(source,'dir') == 7
            typeSource = 'dir';
        end

    end

    if strcmpi(typeSource,'file')
        fileList{end+1} = source;
    else
        fileListTmp = dir([source fileFilter]);
        for ii=1:numel(fileListTmp)
            fileList{end+1} = [source fileListTmp(ii).name];
        end
    end    
    
end


fprintf('%d files\n',numel(fileList))
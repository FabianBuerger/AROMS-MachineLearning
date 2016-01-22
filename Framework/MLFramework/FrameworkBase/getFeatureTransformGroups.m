%function list = getFeatureTransformGroups(group,excludeList)
% get the list of feauture transforms for a group. excludeList allows
% exclusion of specific transforms.
%
% Groups are 
% - 'none': identity only
% - '*': all
% - 'linear': all linear transforms
% - 'nonlinear': non linear
% - 'unsupervised': all unsupervised methods
% - 'supervised' supervised
% - 'extension': all with extension method


function list = getFeatureTransformGroups(group,excludeList)
if nargin == 1
   excludeList = {}; 
end
list = {};

validGroups = {'none','*','linear','nonlinear','unsupervised','supervised','extension'};

if ~cellStringsContainString(validGroups,group)
    warning('Feature transfrom group %s not recognized.',group);
end

% base components
components = frameworkComponentLists();
allFeatureTransforms = fieldnames(components.featureTransformMethods);

for ii = 1:numel(allFeatureTransforms)
    cName = allFeatureTransforms{ii};
	cTransInfo = getfield(components.featureTransformMethods,cName);
    % only active ones
    if cTransInfo.active     
        
        addTrans = 0;
        
        if strcmp(group,'none')
            addTrans = strcmp(cName,'none');
            
        elseif strcmp(group,'*')
            addTrans = 1;
        elseif strcmp(group,'linear')    
            addTrans = cellStringsContainString(cTransInfo.properties,'linear');
            
        elseif strcmp(group,'nonlinear')    
            addTrans = ~cellStringsContainString(cTransInfo.properties,'linear');      
            
        elseif strcmp(group,'unsupervised') 
            addTrans = cellStringsContainString(cTransInfo.properties,'unsupervised') && ~cellStringsContainString(cTransInfo.properties,'supervised');

        elseif strcmp(group,'supervised') 
            addTrans = cellStringsContainString(cTransInfo.properties,'supervised');            
            
        elseif strcmp(group,'extension') 
            addTrans = cellStringsContainString(cTransInfo.properties,'extension');
            
        end
        
        % add to list
        if addTrans && ~cellStringsContainString(excludeList,cName)
            list{end+1} = cName;
        end

    end 
end




% old version 

% if nargin == 1
%    excludeList = {}; 
% end
% list = {};
% if ~iscell(groupList)
%     groupList = {groupList}; 
% end
% components = frameworkComponentLists();
% allFeatureTransforms = fieldnames(components.featureTransformMethods);
% 
% for ii = 1:numel(allFeatureTransforms)
%     cName = allFeatureTransforms{ii};
% 	cTransInfo = getfield(components.featureTransformMethods,cName);
%     
%     if cTransInfo.active
%         if cellStringsContainString(groupList,cTransInfo.group)
%             if ~cellStringsContainString(excludeList,cName)
%                 list{end+1} = cName;
%             end
%         end 
%     end 
% end
% 


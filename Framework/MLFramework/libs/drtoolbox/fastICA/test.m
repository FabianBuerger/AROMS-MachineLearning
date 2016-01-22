
X = 88+10*rand(100,10);
%[sig,mixedsig]=demosig();
%X = mixedsig;
no_dims = 5;



[mappedXPCA, mappingPCA] = compute_mapping(X, 'PCA', no_dims);
[mappedXICA, mappingICA] = compute_mapping(X, 'FastICA', no_dims);


% t_point = out_of_sample(point, mapping)


% [mappedX_PCA, mapping_PCA] = pca(X, no_dims);
% 
% [icasig, A, W] = fastica(X,'numOfIC',no_dims,'verbose','off');
% icasig = icasig';
% mappedX_ICA =  X* icasig;

% 
% [sig,mixedsig]=demosig();
% 
% 
% close all;
% 
%  figure
%  subplot(4,1,1)
%  plot(sig(1,:));
%   subplot(4,1,2)
%  plot(sig(2,:));
%   subplot(4,1,3)
%  plot(sig(3,:));
%   subplot(4,1,4)
%  plot(sig(4,:));
%  
%   figure
%  subplot(4,1,1)
%  plot(mixedsig(1,:));
%   subplot(4,1,2)
%  plot(mixedsig(2,:));
%   subplot(4,1,3)
%  plot(mixedsig(3,:));
%   subplot(4,1,4)
%  plot(mixedsig(4,:));
%  
%  
%  numOfIC = 3;
%  
% [icasig, A, W] = fastica(mixedsig,'numOfIC',numOfIC);
% 
% try
%   figure
%  subplot(4,1,1)
%  plot(icasig(1,:));
%   subplot(4,1,2)
%  plot(icasig(2,:));
%   subplot(4,1,3)
%  plot(icasig(3,:));
%   subplot(4,1,4)
%  plot(icasig(4,:));
% catch
% end
%  
%  y = (icasig*(mixedsig'))';
%  y
%  
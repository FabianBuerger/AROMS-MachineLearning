
% export top configuation fitness plot
function topFitnessDistribution(evalItems,plotOptions)    
    % manual parameters
    nConfigs = 1000;
    plotOptions.showPlots = 0;
    
    % list configuration
    nConfigs=min(nConfigs,numel(evalItems));
    fitnessVals = zeros(1,nConfigs);
    for iRank = 1:nConfigs     
        cEvalItem = evalItems{iRank};
        fitnessVals(iRank) = cEvalItem.qualityMetric;
    end
             
    h=figure();
    if ~plotOptions.showPlots
        set(h,'Visible','off');
    end
    set(h,'Position', [10 800 460 250]);    
    
    plot(fitnessVals,'LineWidth',1.5);
    grid on;
    xlabel('Rank');
    ylabel('Fitness');
        
   
    set(h,'PaperPositionMode','auto');
    print(h,'-dpdf','-r0',[plotOptions.exportFileName '.pdf']);    
    % export as figure (for later calling and changing size or such)
    saveas(h,[plotOptions.exportFileName '.fig'],'fig')
            
    save([plotOptions.exportFileName '_data.mat'],'fitnessVals');
    
    if ~plotOptions.showPlots
        close(h);
    end

  
end
           


        

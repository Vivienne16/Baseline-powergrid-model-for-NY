function plotFuel(timeStamp,result,fuelMix,interFlow,type,savefig,figDir)

[fuelSim,fuelReal,fuelError,fuelName] = ...
    fuel4Plot(result,fuelMix,interFlow);

timeStampStr = datestr(timeStamp,"yyyymmdd_hh");

fontsize = 16;

% Plot simulated and real interface flow
f1 = figure();
bar([fuelSim,fuelReal]);
xticklabels(fuelName);
legend(["Simulated","Real"],"FontSize",fontsize,"Location","northeast");
xlabel("Fuel","FontSize", fontsize);
ylabel("Fuel mix (MW)","FontSize", fontsize);
title(type+": Real and simulated fuel mix "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",fontsize);
set(gca,"FontSize",fontsize);
set(f1,"Position",[100,100,800,600]);
if savefig
    figName = fullfile(figDir,type+"_FM_Com_"+timeStampStr+".png");
    saveas(f1,figName);
    close(f1);
end

% Plot interface flow error
f2 = figure();
bar(fuelError*100);
xticklabels(fuelName);
ytickformat('percentage');
ylabel("Fuel mix Error %","FontSize",fontsize);
xlabel("Fuel","FontSize",fontsize);
title(type+": Fuel mix error "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",fontsize);
set(gca,"FontSize",fontsize);
set(f2,"Position",[100,100,800,600]);
if savefig
    figName = fullfile(figDir,type+"_FM_Err_"+timeStampStr+".png");
    saveas(f2,figName);
    close(f2);
end

end
function plotFlow(timeStamp,result,interFlow,flowLimit,type,savefig,figDir)

[flowSim,flowReal,flowError,flowName] = ...
    flow4Plot(result,interFlow,flowLimit);

timeStampStr = datestr(timeStamp,"yyyymmdd_hh");

fontsize = 16;

% Plot simulated and real interface flow
f1 = figure();
bar([flowSim,flowReal]);
xticklabels(flowName);
legend(["Simulated","Real"],"FontSize",fontsize,"Location","northwest");
xlabel("Interface","FontSize", fontsize);
ylabel("Interface flow (MW)","FontSize", fontsize);
title(type+": Real and simulated interface flow "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",fontsize);
set(gca,"FontSize",fontsize);
set(f1,"Position",[100,100,800,600]);
if savefig
    figName = fullfile(figDir,type+"_IF_Com_"+timeStampStr+".png");
    saveas(f1,figName);
    close(f1);
end

% Plot interface flow error
f2 = figure();
bar(flowError*100);
xticklabels(flowName);
ytickformat('percentage');
ylabel("Power flow Error %","FontSize",fontsize);
xlabel("Interface","FontSize",fontsize);
title(type+": Interface flow error "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",fontsize);
set(gca,"FontSize",fontsize);
set(f2,"Position",[100,100,800,600]);
if savefig
    figName = fullfile(figDir,type+"_IF_Err_"+timeStampStr+".png");
    saveas(f2,figName);
    close(f2);
end

end
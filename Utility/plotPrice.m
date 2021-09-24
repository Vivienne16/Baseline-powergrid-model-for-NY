function plotPrice(timeStamp,result,zonalPrice,busInfo,type,savefig,figDir)

[priceSim,priceReal,priceError,zoneName] = ...
    price4Plot(result,zonalPrice,busInfo);

timeStampStr = datestr(timeStamp,"yyyymmdd_hh");

fontsize = 16;

% Plot simulated and real price
f1 = figure();
bar([priceSim priceReal])
xticklabels(zoneName);
legend(["Simulated","Real"],"FontSize",fontsize,"Location","northwest");
xlabel("Zone","FontSize", fontsize);
ylabel("LMP ($/MW)","FontSize", fontsize); 
title(type+": Real and simulated price "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",fontsize);
set(gca,"FontSize",fontsize);
set(f1,"position",[100,100,800,600]);
if savefig
    figName = fullfile(figDir,type+"_LMP_Com_"+timeStampStr+".png");
    saveas(f1,figName);
    close(f1);
end

% Plot price error
f2 = figure();
bar(priceError*100);
xticklabels(zoneName);
ytickformat('percentage');
ylabel("Price Error %","FontSize",fontsize);
xlabel("Zone","FontSize",fontsize);
title(type+": Price error "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",fontsize);
set(gca,"FontSize",fontsize);
set(f2,"Position",[100,100,800,600]);
if savefig
    figName = fullfile(figDir,type+"_LMP_Err_"+timeStampStr+".png");
    saveas(f2,figName);
    close(f2);
end

end
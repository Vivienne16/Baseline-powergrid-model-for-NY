function plotPrice(timeStamp,result,zonalPrice,busInfo,type,savefig,figDir)

[priceSim,priceReal,priceError,zoneName] = ...
    price4Plot(result,zonalPrice,busInfo);

timeStampStr = datestr(timeStamp,"yyyymmdd_hh");

fontsize = 16;

% Plot simulated and real price
f1 = figure();
% bar([priceSim priceReal])
% xticklabels(zoneName);
% legend(["Simulated","Real"],"FontSize",fontsize,"Location","northwest");
% xlabel("Zone","FontSize", fontsize);
% ylabel("LMP ($/MW)","FontSize", fontsize); 
% title(type+": Real and simulated price "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",fontsize);
% set(gca,"FontSize",fontsize);
% set(f1,"position",[100,100,800,600]);
x0=10;
y0=10;
width=550;
height=400;
set(gca,'FontSize',18)
set(gcf,'position',[x0,y0,width,height])
plot(priceReal,'LineWidth',3)
hold on
plot(priceSim,'LineWidth',3)
h = legend('Historical LMP','Simulated LMP','Real Power Error','FontSize', 18);
set(h,'Location','best')
ax = gca;
ax.FontSize = 16; 
xticks([1:14])
xticklabels({'West','Genese','Central','North','MHK VL','Capital','HUD VL','MILLWD','DUNWOD','NYC','Long IL','PJM','NE','Ontario','HQ'})
xtickangle(45)
xlabel('Zone','FontSize', 18)
ylabel('LMP ($/MW)','FontSize', 18)
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
function resultOPF = OPFtestcase(mpcreduced,timeStamp,savefig)
%OPFTESTCASE
% 
%   This file run a test case for OPF using the updated mpc
%   This file should be run after the OperationConditionUpdate.m file. 
%   MATPOWER should have been installed properly to run the test.
% 
%   Inputs:
%       mpc - reduced MATPOWER case
%   Outputs:
%       mpc - updated mpc with Optimal Power Flow results

%   Created by Vivienne Liu, Cornell University
%   Last modified on Sept. 21, 2021

%% Input parameters

if nargin <= 2 || isempty(savefig)
    savefig = true;
end

% Testing timestamp
if isempty(timeStamp)
    year = 2019; month = 12; day = 8; hour = 7;
    timeStamp = datetime(year,month,day,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");    
end

if isempty(mpcreduced)
    mpcreduced = loadcase("Result/mpcreduced.mat");
end

%% Read operation condition for NYS

[fuelMix,interFlow,flowLimit,~,~,zonalPrice] = readOpCond(timeStamp);
busInfo = importBusInfo(fullfile("Data","npcc.csv"));

define_constants;

%% additional constraints for large hydro to avoid dispatch at upper gen limit

%hydro gen constraints
% RMNcf = [0.8072,0.7688,0.815,0.7178,0.8058,0.7785,0.8275,0.8007,0.7931,0.7626,0.7764,0.8540];
% STLcf = [0.9133,0.9483, 1.0112,0.9547,0.9921,1.0984,1.0761,1.0999,1.0976,1.0053,1.0491,1.0456];
% mpcreduced.gen(228,9) = 0.8*(fuelsum.mean_GenMW(string(fuelsum.FuelCategory) == 'Hydro')-910)-STLcf(month)*860;
% mpcreduced.gen(234,9) = STLcf(month)*860;

%% Run OPF
mpopt = mpoption( 'opf.dc.solver','GUROBI','opf.flow_lim','P');
mpcreduced = toggle_iflims(mpcreduced, 'on');
resultOPF = rundcopf(mpcreduced,mpopt);
resultBus = resultOPF.bus;
resultBranch = resultOPF.branch;
resultGen = resultOPF.gen;

fprintf("Finished solving optimal power flow!\n");

timeStampStr = datestr(timeStamp,"yyyymmdd_hh");
outfilename = "Result\"+"resultOPF_"+timeStampStr+".mat";
save(outfilename,"resultOPF");

fprintf("Saved optimal power flow results!\n");

%% Show price results

[priceSim,priceReal,priceError,zoneName] = ...
    price4Plot(resultBus,zonalPrice,busInfo);

% Plot simulated and real price
f = figure();
bar([priceSim priceReal])
xticklabels(zoneName);
legend(["Simulated","Real"],"FontSize",14,"Location","northwest");
xlabel("Zone","FontSize", 12);
ylabel("LMP ($/MW)","FontSize", 12); 
title("OPF: Real and simulated price "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultOPF_LMP_Com_"+timeStampStr+".png";
    saveas(f,figName);
    close(f);
end

% Plot price error
f = figure();
bar(priceError*100);
xticklabels(zoneName);
ytickformat('percentage');
ylabel("Price Error %","FontSize",16);
xlabel("Zone","FontSize",16);
title("OPF: Price error "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultOPF_LMP_Err_"+timeStampStr+".png";
    saveas(f,figName);
    close(f);
end

%% Show interface flow results

[flowSim,flowReal,flowError,flowName] = ...
    flow4Plot(resultBranch,interFlow,flowLimit);

% Plot simulated and real interface flow
f = figure();
bar([flowSim,flowReal]);
xticklabels(flowName);
legend(["Simulated","Real"],"FontSize",14,"Location","northwest");
xlabel("Interface","FontSize", 14);
ylabel("Interface flow (MW)","FontSize", 14);
title("OPF: Real and simulated interface flow "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultOPF_IF_Com_"+timeStampStr+".png";
    saveas(f,figName);
    close(f);
end

% Plot interface flow error
f = figure();
bar(flowError*100);
xticklabels(flowName);
ytickformat('percentage');
ylabel("Power Flow Error %","FontSize",16);
xlabel("Interface","FontSize",16);
title("OPF: Interface flow error "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultOPF_IF_Err_"+timeStampStr+".png";
    saveas(f,figName);
    close(f);
end

%% Show fuel mix results

[fuelSim,fuelReal,fuelError,fuelName] = fuel4Plot(resultOPF,resultGen,fuelMix,interFlow);

% Plot simulated and real interface flow
f = figure();
bar([fuelSim,fuelReal]);
xticklabels(fuelName);
legend(["Simulated","Real"],"FontSize",14,"Location","northwest");
xlabel("Fuel","FontSize", 14);
ylabel("Fuel mix (MW)","FontSize", 14);
title("OPF: Real and simulated fuel mix "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultOPF_FM_Com_"+timeStampStr+".png";
    saveas(f,figName);
    close(f);
end

% Plot interface flow error
f = figure();
bar(fuelError*100);
xticklabels(fuelName);
ytickformat('percentage');
ylabel("Fuel mix Error %","FontSize",16);
xlabel("Fuel","FontSize",16);
title("OPF: Fuel mix error "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultOPF_FM_Err_"+timeStampStr+".png";
    saveas(f,figName);
    close(f);
end

end


       
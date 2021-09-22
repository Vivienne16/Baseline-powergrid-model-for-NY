function resultPF = PFtestcase(mpcreduced,timeStamp,savefig)
%PFTESTCASE
%   
%   This file run a test case for PF using the updatedmpc
%   This file should be run after the OperationConditionUpdate.m file. 
%   MATPOWER should have been installed properly to run the test.
% 
%   Inputs:
%       mpc - reduced MATPOWER case
%   Outputs:
%       mpc - updated MATPOWER case with Power Flow results
% 
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

[fuelMix,interFlow,flowLimit,~,~,~] = readOpCond(timeStamp);

define_constants;

%% Run reduced MATPOWER case

resultPF = rundcpf(mpcreduced);
resultBranch = resultPF.branch;
resultGen = resultPF.gen;

fprintf("Finished solving power flow!\n");

timeStampStr = datestr(timeStamp,"yyyymmdd_hh");
outfilename = "Result\"+"resultPF_"+timeStampStr+".mat";
save(outfilename,"resultPF");

fprintf("Saved power flow results!\n");

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
title("PF: Real and simulated interface flow "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultPF_IF_Com_"+timeStampStr+".png";
    saveas(f,figName);
    close(f);
end

% Plot interface flow error
f = figure();
bar(flowError*100);
xticklabels(flowName);
ytickformat('percentage');
ylabel("Power flow Error %","FontSize",16);
xlabel("Interface","FontSize",16);
title("PF: Interface flow error "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultPF_IF_Err_"+timeStampStr+".png";
    saveas(f,figName);
    close(f);
end

%% Show fuel mix results

[fuelSim,fuelReal,fuelError,fuelName] = fuel4Plot(resultPF,resultGen,fuelMix,interFlow);

% Plot simulated and real interface flow
f = figure();
bar([fuelSim,fuelReal]);
xticklabels(fuelName);
legend(["Simulated","Real"],"FontSize",14,"Location","northwest");
xlabel("Fuel","FontSize", 14);
ylabel("Fuel mix (MW)","FontSize", 14);
title("PF: Real and simulated fuel mix "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultPF_FM_Com_"+timeStampStr+".png";
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
title("PF: Fuel mix error "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultPF_FM_Err_"+timeStampStr+".png";
    saveas(f,figName);
    close(f);
end

end
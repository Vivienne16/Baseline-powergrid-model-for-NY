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

% Read operation condition for NYS
[~,interFlow,flowLimit,~,~,~] = readOpCond(timeStamp);

define_constants;

if isempty(mpcreduced)
    mpcreduced = loadcase("Result/mpcreduced.mat");
end

fprintf("Finished reading MATPOWER case!\n");

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
flow4plot = [flowSim,flowReal];
bar(flow4plot);
xticklabels(flowName);
legend(["Simulated","Real"],"FontSize",14,"Location","northwest");
xlabel("Interface name","FontSize", 14);
ylabel("Interface flow (MW)","FontSize", 14);
title("PF: Real and simulated interface flow "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultPF_IF_Com_"+timeStampStr+".png";
    saveas(f,figName);
end

% Plot interface flow error
f = figure();
bar(flowError*100);
xticklabels(flowName);
ytickformat('percentage');
ylabel("Power Flow Error %","FontSize",16);
xlabel("Interface","FontSize",16);
title("PF: Interface flow error "+datestr(timeStamp,"yyyy-mm-dd hh:00"),"FontSize",16);
set(gca,"FontSize",16);
set(f,"Position",[100,100,800,600]);
if savefig
    figName = "Result\Figure\"+"resultPF_IF_Err_"+timeStampStr+".png";
    saveas(f,figName);
end

end
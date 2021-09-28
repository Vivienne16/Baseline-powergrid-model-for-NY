function resultOPF = OPFtestcase(mpcreduced,timeStamp,savefig,savedata)
%OPFTESTCASE Run optimal power flow at a specified timestamp and show results.
% 
%   Inputs:
%       mpcreduced - struct, reduced MATPOWER case
%       timeStamp - datetime, in "MM/dd/uuuu HH:mm:ss"
%       savefig - boolean, default to be true
%       savedata - boolean, default to be true
%   Outputs:
%       resultOPF - struct, optimal power flow results

%   Created by Vivienne Liu, Cornell University
%   Last modified on Sept. 24, 2021

%% Input parameters

% Read reduced MATPOWER case
if isempty(mpcreduced)
    mpcreduced = loadcase(fullfile('Result','mpcreduced.mat'));
end

% Save figure or not (default to save)
if isempty(savefig)
    savefig = true;
end

% Save OPF results or not (default to save)
if isempty(savedata)
    savedata = true;
end

% Create directory for store OPF results and plots
resultDir = fullfile('Result',string(year(timeStamp)),'OPF');
createDir(resultDir);
figDir = fullfile('Result',string(year(timeStamp)),'Figure','OPF');
createDir(figDir);

%% Read operation condition for NYS

[fuelMix,interFlow,flowLimit,~,~,zonalPrice] = readOpCond(timeStamp);
busInfo = importBusInfo(fullfile("Data","npcc.csv"));

define_constants;

%% Run OPF
mpopt = mpoption( 'opf.dc.solver','GUROBI','opf.flow_lim','P');
mpcreduced = toggle_iflims(mpcreduced, 'on');
resultOPF = rundcopf(mpcreduced,mpopt);
resultBus = resultOPF.bus;
resultBranch = resultOPF.branch;
resultGen = resultOPF.gen;

fprintf("Finished solving optimal power flow!\n");

if savedata
    timeStampStr = datestr(timeStamp,"yyyymmdd_hh");
    outfilename = fullfile(resultDir,"resultPF_"+timeStampStr+".mat");
    save(outfilename,"resultOPF");
    fprintf("Saved optimal power flow results!\n");
end

%% Create plots

type = "OPF";

% Plot interface flow data and error
plotFlow(timeStamp,resultOPF,interFlow,flowLimit,type,savefig,figDir);

% Plot fuel mix data and error
plotFuel(timeStamp,resultOPF,fuelMix,interFlow,type,savefig,figDir);

% Plot price data and error
plotPrice(timeStamp,resultOPF,zonalPrice,busInfo,type,savefig,figDir)


end


       
function resultOPF = OPFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew)
%OPFTESTCASE Run optimal power flow at a specified timestamp and show results.
% 
%   Inputs:
%       mpcreduced - struct, reduced MATPOWER case
%       timeStamp - datetime, in "MM/dd/uuuu HH:mm:ss"
%       savefig - boolean, default to be true
%       savedata - boolean, default to be true
%       addrenew - boolean, default to false
%   Outputs:
%       resultOPF - struct, optimal power flow results

%   Created by Vivienne Liu, Cornell University
%   Last modified on Feb. 7, 2022

%% Input parameters

% Read reduced MATPOWER case
if isempty(mpcreduced)
    mpcfilename = fullfile('Result',string(year(timeStamp)),'mpcreduced',...
        "mpcreduced_"+datestr(timeStamp,"yyyymmdd_hh")+".mat");
    load(mpcfilename,"mpcreduced");
end

% Save figure or not (default to save)
if isempty(savefig)
    savefig = true;
end

% Save OPF results or not (default to save)
if isempty(savedata)
    savedata = true;
end

% Add additional renewable or not (default to not)
if isempty(addrenew)
    addrenew = false;
end

%% Read operation condition for NYS

[fuelMix,interFlow,flowLimit,~,~,zonalPrice] = readOpCond(timeStamp);
busInfo = importBusInfo(fullfile("Data","npcc.csv"));

define_constants;

%% Create directory for store OPF results and plots

if addrenew
    resultDir = fullfile('Result_Renewable',string(year(timeStamp)),'OPF');
    figDir = fullfile('Result_Renewable',string(year(timeStamp)),'Figure','OPF');
else
    resultDir = fullfile('Result',string(year(timeStamp)),'OPF');
    figDir = fullfile('Result',string(year(timeStamp)),'Figure','OPF');
end

createDir(resultDir);
createDir(figDir);

%% Run OPF

mpopt = mpoption('opf.flow_lim','P');
mpcreduced = toggle_iflims(mpcreduced, 'on');
resultOPF = rundcopf(mpcreduced,mpopt);

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
plotFuel(timeStamp,resultOPF,fuelMix,interFlow,type,savefig,figDir,addrenew);

% Plot price data and error
plotPrice(timeStamp,resultOPF,zonalPrice,busInfo,type,savefig,figDir)


end


       
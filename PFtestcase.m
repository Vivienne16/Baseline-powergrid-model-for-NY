function resultPF = PFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew)
%PFTESTCASE Run power flow at a specified timestamp and show results.
%
%   Inputs:
%       mpcreduced - struct, reduced MATPOWER case
%       timeStamp - datetime, in "MM/dd/uuuu HH:mm:ss"
%       savefig - boolean, default to be true
%       savedata - boolean, default to be true
%       addrenew - boolean, default to false
%   Outputs:
%       resultPF - struct, power flow results

%   Created by Vivienne Liu, Cornell University
%   Last modified on Feb. 8, 2022

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

[fuelMix,interFlow,flowLimit,~,~,~] = readOpCond(timeStamp);

define_constants;

%% Create directory for store PF results and plots

if addrenew
    resultDir = fullfile('Result_Renewable',string(year(timeStamp)),'PF');
    figDir = fullfile('Result_Renewable',string(year(timeStamp)),'Figure','PF');
else
    resultDir = fullfile('Result',string(year(timeStamp)),'PF');
    figDir = fullfile('Result',string(year(timeStamp)),'Figure','PF');  
end

createDir(resultDir);
createDir(figDir);

%% Run reduced MATPOWER case

resultPF = rundcpf(mpcreduced);

fprintf("Finished solving power flow!\n");

if savedata
    timeStampStr = datestr(timeStamp,"yyyymmdd_hh");
    outfilename = fullfile(resultDir,"resultPF_"+timeStampStr+".mat");
    save(outfilename,"resultPF");
    fprintf("Saved power flow results!\n");
end

%% Create plots

type = "PF";

% Plot interface flow and error
plotFlow(timeStamp,resultPF,interFlow,flowLimit,type,savefig,figDir);

% Plot fuel mix and error
plotFuel(timeStamp,resultPF,fuelMix,interFlow,type,savefig,figDir,addrenew);

end
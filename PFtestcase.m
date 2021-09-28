function resultPF = PFtestcase(mpcreduced,timeStamp,savefig,savedata)
%PFTESTCASE Run power flow at a specified timestamp and show results.
% 
%   Inputs:
%       mpcreduced - struct, reduced MATPOWER case
%       timeStamp - datetime, in "MM/dd/uuuu HH:mm:ss"
%       savefig - boolean, default to be true
%       savedata - boolean, default to be true
%   Outputs:
%       resultPF - struct, power flow results

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
resultDir = fullfile('Result',string(year(timeStamp)),'PF');
createDir(resultDir);
figDir = fullfile('Result',string(year(timeStamp)),'Figure','PF');
createDir(figDir);

%% Read operation condition for NYS

[fuelMix,interFlow,flowLimit,~,~,~] = readOpCond(timeStamp);

define_constants;

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
plotFuel(timeStamp,resultPF,fuelMix,interFlow,type,savefig,figDir);


end
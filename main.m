%% Main file
% Description of the main file
%
%

%% Parameter settings

clear;
clc;
close all;

savefig = true; % Save figure or not
savedata = true; % Save PF and OPF results
verbose = false; % Verbose printing or not
runloop = false; % Loop through the whole year or not
addrenew = true; % Add additional renewable or not

%% Data preparation

% Specify a year, and download and format the data in that year. Downlaoded
% data are stored in the "Prep" directory. Formatted data are stored in the
% "Data" directory.
% Data sources include:
%   1. NYISO: (1) hourly fuel mix
%             (2) hourly interface flow
%             (3) hourly real time price
%   2. RGGI: (1) hourly generation for thermal generators larger than 25 MW
%   3. NRC: (1) Daily nuclear capacity factor
%   4. EIA: (1) Monthly hydro generation data for Niagara and St. Lawrence

testyear = 2020;
writeFuelmix(testyear);
writeHydroGen(testyear);
writeNuclearGen(testyear);
writePrice(testyear);
writeInterflow(testyear);
writeFuelPrice(testyear);

%% Modify MPC

% Read original NPCC 140 MATPOWER case and make modifications.

mpc = modifyMPC();

%% Test case

% Specify a timestamp with year, month, day and hour, update operation
% condition for that timestamp, and then run power flow (PF) and optimal
% power flow (OPF). Produce figures for comparing simulation results with
% historical data, including interface flow, fuel mix and locational
% marginal price (LMP).

testyear = 2020;
testmonth = 7;
testday = 7;
testhour = 12;

timeStamp = datetime(testyear,testmonth,testday,testhour,0,0,"Format","MM/dd/uuuu HH:mm:ss");

% Operation condition update
mpcreduced = updateOpCond(mpc,timeStamp,savedata,verbose);

% PF test
resultPF = PFtestcase(mpcreduced,timeStamp,savefig,savedata);

% OPF test
resultOPF = OPFtestcase(mpcreduced,timeStamp,savefig,savedata);


%% Loop through the whole year 2019

% Specify the range of year, month, day, and hour that you want to loop
% though, update operation condition for the specified timestamps, and then
% run PF and OPF.

testyear = 2020;

for testmonth = 7
    for testday = 1:7
        parfor testhour = 1:24
            
            timeStamp = datetime(testyear,testmonth,testday,testhour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
            fprintf("Start running %s ...\n",datestr(timeStamp));
            
            % Operation condition update
            mpcreduced = updateOpCond(mpc,timeStamp,savedata,verbose);
            
            % PF test
            resultPF = PFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew);
            
            % OPF test
            resultOPF = OPFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew);
            
            fprintf("Success!\n");
            
        end
    end
end


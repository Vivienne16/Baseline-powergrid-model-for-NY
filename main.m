%% Main file
% Description of the main file
%
%

%% Parameter settings

clear;
clc;
close all;
tic;

savefig = true; % Save figure or not
savedata = true; % Save PF and OPF results
verbose = false; % Verbose printing or not
runloop = true; % Loop through the whole year or not
addrenew = false; % Add additional renewable or not
usemat = true; % Read mat files

% Add project to MATLAB path
addpath(genpath("."))

%% Data preparation

% Specify a year, and download and format the data in that year. Downlaoded
% data are stored in the "Prep" directory. Formatted data are stored in the
% "Data" directory.
% Data sources include:
%   1. NYISO: (1) hourly fuel mix
%             (2) hourly interface flow
%             (3) hourly real time price
%             (4) hourly real time load
%             (5) fuel price (from CARIS report)
%   2. RGGI: (1) hourly generation for thermal generators larger than 25 MW
%   3. NRC: (1) Daily nuclear capacity factor
%   4. EIA: (1) Monthly hydro generation data for Niagara and St. Lawrence

testyear = 2019;
writeFuelmix(testyear);
writeInterflow(testyear);
writePrice(testyear);
writeLoad(testyear);
writeFuelPrice(testyear);
writeThermalGen(testyear);
writeGenParam(testyear);
writeHydroGen(testyear);
writeNuclearGen(testyear);

%% Modify MPC

% Read original NPCC 140 MATPOWER case and make modifications.

mpc = modifyMPC();

%% Test case for one hour

% Specify a timestamp with year, month, day and hour, update operation
% condition for that timestamp, and then run power flow (PF) and optimal
% power flow (OPF). Produce figures for comparing simulation results with
% historical data, including interface flow, fuel mix and locational
% marginal price (LMP).

if runloop == false

    testyear = 2019;
    testmonth = 12;
    testday = 12;
    testhour = 12;
    
    timeStamp = datetime(testyear,testmonth,testday,testhour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
    fprintf("Start running %s ...\n",datestr(timeStamp));
 
    % Update operation conditions
    mpcreduced = updateOpCond(mpc,timeStamp,savedata,verbose,usemat);
    
    % Run power flow
    resultPF = PFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew);
    
    % Run optimal power flow
    resultOPF = OPFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew);
end

%% Loop through the whole year 2019

% Specify the range of year, month, day, and hour that you want to loop
% though, update operation condition for the specified timestamps, and then
% run PF and OPF.

if runloop == true
    testyear = 2019;
    for testmonth = 3
        for testday = 10
            parfor testhour = 1:3
                
                timeStamp = datetime(testyear,testmonth,testday,testhour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
                fprintf("Start running %s ...\n",datestr(timeStamp));
                
                % Update operation conditions
                mpcreduced = updateOpCond(mpc,timeStamp,savedata,verbose,usemat);
                
                % Run power flow
                resultPF = PFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew);
                
                % Run optimal power flow
                resultOPF = OPFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew);
                
                fprintf("Success!\n");
                
            end
        end
    end
end

toc;
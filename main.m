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
addrenew = true; % Add additional renewable or not
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

testyear = 2016;
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

    testyear = 2016;
    testmonth = 8;
    testday = 6;
    testhour = 12;
    
    timeStamp = datetime(testyear,testmonth,testday,testhour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
    fprintf("Start running %s ...\n",datestr(timeStamp));
    
    if timeStamp == datetime(2019,3,10,2,0,0)
        fprintf("Skip the timestep due to daylight saving time!\n");
    elseif timeStamp == datetime(2019,12,12,12,0,0)
        fprintf("Skip the timestep due to data unavailability!");
    else
        % Operation condition update
        mpcreduced = updateOpCond(mpc,timeStamp,savedata,verbose,usemat);
    
        % PF test
        resultPF = PFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew);
    
        % OPF test
        resultOPF = OPFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew);
    end
end

%% Loop through the whole year 2019

% Specify the range of year, month, day, and hour that you want to loop
% though, update operation condition for the specified timestamps, and then
% run PF and OPF.

if runloop == true
    testyear = 2016;
    for testmonth = 8
        for testday = 6:15
            parfor testhour = 0:23
                
                timeStamp = datetime(testyear,testmonth,testday,testhour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
                fprintf("Start running %s ...\n",datestr(timeStamp));
                
                if timeStamp == datetime(2019,3,10,2,0,0)
                    fprintf("Skip the timestep due to daylight saving time!");
                    continue;
                end

                if timeStamp == datetime(2019,12,12,12,0,0)
                    fprintf("Skip the timestep due to data unavailability!");
                    continue;
                end
                
                % Operation condition update
                mpcreduced = updateOpCond(mpc,timeStamp,savedata,verbose,usemat);
                
                % PF test
                resultPF = PFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew);
                
                % OPF test
                resultOPF = OPFtestcase(mpcreduced,timeStamp,savefig,savedata,addrenew);
                
                fprintf("Success!\n");
                
            end
        end
    end
end

toc;
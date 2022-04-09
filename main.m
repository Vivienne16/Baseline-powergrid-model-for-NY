%% Main file
%   Baseline power grid model for NYS
%   Specify timestep(s) and runtime options and run the simulation.

%   Created by Vivienne Liu
%   Last modified on Feb. 8, 2022

clear; clc; close all;
tic;

%% Input parameters

% Simulation timestep(s) for the model. 
% Set it as an array if you want to run multiple timesteps in a loop.

testyear = 2019;
testmonth = 1:12;
testday = 1;
testhour = 0;

%% Runtime options

% Save figure or not
savefig = true;
% Save PF and OPF results or not
savedata = true; 
% Verbose printing or not
verbose = false; 
% Add additional renewable or not
addrenew = false; 
% Read mat files, otherwise read csv files
usemat = true;
% Add project to MATLAB path
addpath(genpath("."))

%% Data preparation

% Download and format the data in the specified year. Downlaoded
% data are stored in the "Prep" directory. Formatted data are stored in the
% "Data" directory. If the data has already been prepared, it will
% automatically skip the process.
%
% Data sources include:
%   1. NYISO: (1) hourly fuel mix
%             (2) hourly interface flow
%             (3) hourly real time price
%             (4) hourly real time load
%             (5) fuel price (from CARIS report)
%   2. RGGI: (1) hourly generation for thermal generators larger than 25 MW
%   3. NRC: (1) Daily nuclear capacity factor
%   4. EIA: (1) Monthly hydro generation data for Niagara and St. Lawrence

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

%% Run the model

% Run the model at the specified timestamp(s). Firstly, update operation
% condition for that timestamp, and then run power flow (PF) and optimal
% power flow (OPF). Produce figures for comparing simulation results with
% historical data, including interface flow, fuel mix and locational
% marginal price (LMP). The loop can run in parallel if a parallel pool is
% provided on the machine.

for y = testyear
    for m = testmonth
        for d = testday
            parfor h = testhour
                timeStamp = datetime(y,m,d,h,0,0,"Format","MM/dd/uuuu HH:mm:ss");
                fprintf("Start running %s ...\n",datestr(timeStamp));
                % Update operation conditions
                mpcreduced = updateOpCond(mpc,timeStamp,savedata,verbose,usemat);
                % Add additional renewables if provided
                if addrenew == true
                    mpcreduced = addRenewable(mpcreduced, timeStamp);
                end
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
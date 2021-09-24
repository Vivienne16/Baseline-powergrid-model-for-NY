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

year = 2020;
writeFuelmix(year);
writeHydroGen(year);
writeNuclearGen(year);
writePrice(year);
writeInterflow(year);

%% Modify MPC

% Read

mpc = modifyMPC();

%% Test case

% Specify a timestamp with year, month, day and hour, update operation
% condition for that timestamp, and then run power flow (PF) and optimal
% power flow (OPF). Produce figures for comparing simulation results with
% historical data, including interface flow, fuel mix and locational
% marginal price (LMP).

year = 2019;
month = 1;
day = 1;
hour = 1;

timeStamp = datetime(year,month,day,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");

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

if runloop
    for month = 7
        for day = 1:eomday(year,month)
            for hour = 1:3:24
                
                % Operation condition update
                timeStamp = datetime(year,month,day,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
                mpcreduced = updateOpCond(timeStamp);
                
                % PF test
                resultPF = PFtestcase(mpcreduced,timeStamp,savefig,savedata);
                
                % OPF test
                resultOPF = OPFtestcase(mpcreduced,timeStamp,savefig,savedata);
            end
        end
    end
end

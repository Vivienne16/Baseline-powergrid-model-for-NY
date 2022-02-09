function mpc = addRenewable(mpc,timeStamp)
%ADDRENEWABLE Add additional renewable generators to the network
%   Inputs:
%       mpc - MATPOWER case struct.
%       timeStamp - datetime.
%   Outputs:
%       mpc - updated MATPOWER case.

%   Created by Bo Yuan, Cornell University
%   Last modified on Sept. 28, 2021

define_constants;

%% Add solar generation

fprintf("Start allocating additional renewables ...\n");

% Read solar generation data
filename = fullfile("Testing","solar_20160805_20160816.csv");
% A matrix of two columns: (1) busID, (2) generation
solarGen = readSolarGen(filename, timeStamp);
numSolar = size(solarGen, 1);

% Solar generator matrix
genSolar = zeros(numSolar, 21);
for i=1:numSolar
    genSolar(i, GEN_BUS) = solarGen(i,1);
    genSolar(i, PG) = solarGen(i,2);
    genSolar(i, QMAX) = 9999;
    genSolar(i, QMIN) = -9999;
    genSolar(i, VG) = 1;
    genSolar(i, MBASE) = 100;
    genSolar(i, GEN_STATUS) = 1;
    genSolar(i, PMAX) = solarGen(i,2);
    genSolar(i, PMIN) = solarGen(i,2);       
    genSolar(i, RAMP_AGC) = 0;
    genSolar(i, RAMP_10) = 0;
    genSolar(i, RAMP_30) = 0;     
end

% Solar gen cost matrix
gencostSolar = zeros(numSolar, 6);
gencostSolar(:, MODEL) = 2;
gencostSolar(:, NCOST) = 2;

mpc = addgen2mpc(mpc, genSolar, gencostSolar, 'Solar');

%% Add wind

% Read wind generation data
filename = fullfile("Testing","wind_20160805_20160816.csv");
% A matrix of two columns: (1) busID, (2) generation
windGen = readWindGen(filename, timeStamp);
numWind = size(windGen, 1);

% Solar generator matrix
genWind = zeros(numWind, 21);
for i=1:numWind
    genWind(i, GEN_BUS) = windGen(i,1);
    genWind(i, PG) = windGen(i,2);
    genWind(i, QMAX) = 9999;
    genWind(i, QMIN) = -9999;
    genWind(i, VG) = 1;
    genWind(i, MBASE) = 100;
    genWind(i, GEN_STATUS) = 1;
    genWind(i, PMAX) = windGen(i,2);
    genWind(i, PMIN) = windGen(i,2);       
    genWind(i, RAMP_AGC) = 0;
    genWind(i, RAMP_10) = 0;
    genWind(i, RAMP_30) = 0;     
end

% Solar gen cost matrix
gencostWind = zeros(numWind, 6);
gencostWind(:, MODEL) = 2;
gencostWind(:, NCOST) = 2;

mpc = addgen2mpc(mpc, genWind, gencostWind, 'Wind');

fprintf("Finished allocating additional renewables in NYS!\n"); 

end

function solarGen = readSolarGen(filename,timeStamp)
%READSOLARGEN Read solar generation data at a specific timestamp

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 19);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TimeStamp", "Bus37", "Bus39", "Bus40", "Bus42", "Bus45", "Bus49", "Bus51", "Bus52", "Bus55", "Bus57", "Bus73", "Bus74", "Bus75", "Bus76", "Bus77", "Bus78", "Bus79", "Bus82"];
opts.VariableTypes = ["datetime", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm");

% Import the data
solarDataAll = readtable(filename, opts);

%% Subset to a specific timestamp

solarData = solarDataAll(solarDataAll.TimeStamp == timeStamp, :);

%% Allocate to bus

busName = string(solarData.Properties.VariableNames(2:end));
busName = str2double(erase(busName,'Bus'));
solarGen = [busName;table2array(solarData(1,2:end))]';
solarGen = rmmissing(solarGen);

end

function windGen = readWindGen(filename,timeStamp)
%READWINDGEN Read wind generation for a specific timestamp

%% Set up the Import Options and import the data

opts = delimitedTextImportOptions("NumVariables", 3);

% Specify range and delimiter
opts.DataLines = [2, inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TimeStamp", "Bus81", "Bus79"];
opts.VariableTypes = ["datetime", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "TimeStamp", "InputFormat", "yyyy-MM-dd HH:mm:ss");

% Import the data
windDataAll = readtable(filename, opts);

%% Subset to a specific timestamp

windData = windDataAll(windDataAll.TimeStamp == timeStamp, :);

%% Allocate to bus

busName = string(windData.Properties.VariableNames(2:end));
busName = str2double(erase(busName,'Bus'));
windGen = [busName;table2array(windData(1,2:end))]';
windGen = rmmissing(windGen);

end
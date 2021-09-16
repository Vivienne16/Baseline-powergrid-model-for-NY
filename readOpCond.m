function [loadData,genData,fuelMix,interFlow,nuclearCf,hydroCf] = readOpCond(timeStamp)


% Read hourly fuelmix data, hourly interface flow data, hourly zonal price
% data, daily nuclear generation capacity factor data, monthly hydro
% generation capacity factor data
fuelMixAll = importFuelMix(fullfile('Data','fuelmixHourly.csv'));
interFlowAll = importInterFlow(fullfile('Data','interflowHourly.csv'));
priceAll = importPrice(fullfile('Data','priceHourly.csv'));
nuclearCfAll = importNuclearGen(fullfile('Data','nuclearGenDaily.csv'));
hydroCfAll = importHydroGen(fullfile('Data','hydroGenMonthly.csv'));

% Read renewable generation capacity allocation table
renewableGen = importRenewableGen(fullfile('Data','RenewableGen.csv'));
businfo = readtable(fullfile('Data','npcc.xlsx'),'Sheet','Bus');

% Read updated mpc case
mpc = loadcase(fullfile('Result','mpcupdated.mat'));

% Get time-specific data
loadData = allocateLoadHourly(year,month,day,hour);
genData = allocateGenHourly(year,month,day,hour);
fuelMix = fuelMixAll(fuelMixAll.TimeStamp == timeStamp,:);
interFlow = interFlowAll(interFlowAll.TimeStamp == timeStamp,["InterfaceName","FlowMWH"]);
flowLimit = interFlowAll(interFlowAll.TimeStamp == timeStamp,["InterfaceName","PositiveLimitMWH","NegativeLimitMWH"]);
nuclearCf = nuclearCfAll(nuclearCfAll.TimeStamp == dateshift(timeStamp,'start','day'),:);
hydroCf = hydroCfAll(hydroCfAll.TimeStamp == dateshift(timeStamp,'start','month'),:);

end

function fuelMix = importFuelMix(filename, dataLines)
% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 3);
% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";
% Specify column names and types
opts.VariableNames = ["TimeStamp", "FuelCategory", "GenMW"];
opts.VariableTypes = ["datetime", "categorical", "double"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Specify variable properties
opts = setvaropts(opts, "FuelCategory", "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");
% Import the data
fuelMix = readtable(filename, opts);
end

function interFlow = importInterFlow(filename, dataLines)
% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 5);
% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";
% Specify column names and types
opts.VariableNames = ["TimeStamp", "InterfaceName", "FlowMWH", "PositiveLimitMWH", "NegativeLimitMWH"];
opts.VariableTypes = ["datetime", "categorical", "double", "double", "double"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Specify variable properties
opts = setvaropts(opts, "InterfaceName", "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm");
% Import the data
interFlow = readtable(filename, opts);
end

function price = importPrice(filename, dataLines)
% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 5);
% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";
% Specify column names and types
opts.VariableNames = ["TimeStamp", "ZoneName", "LBMP", "MarginalCostLosses", "MarginalCostCongestion"];
opts.VariableTypes = ["datetime", "categorical", "double", "double", "double"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Specify variable properties
opts = setvaropts(opts, "ZoneName", "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");
% Import the data
price = readtable(filename, opts);
end

function nuclearGen = importNuclearGen(filename, dataLines)
% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 13);
% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";
% Specify column names and types
opts.VariableNames = ["TimeStamp", "FitzPatrickCF", "FitzPatrickGen", "GinnaCF", "GinnaGen", "IndianPoint2CF", "IndianPoint2Gen", "IndianPoint3CF", "IndianPoint3Gen", "NineMilePoint1CF", "NineMilePoint1Gen", "NineMilePoint2CF", "NineMilePoint2Gen"];
opts.VariableTypes = ["datetime", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Specify variable properties
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy");
% Import the data
nuclearGen = readtable(filename, opts);
end

function hydroGen = importHydroGen(filename, dataLines)
% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 5);
% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";
% Specify column names and types
opts.VariableNames = ["TimeStamp", "rmnGen", "rmnCF", "stlGen", "stlCF"];
opts.VariableTypes = ["datetime", "double", "double", "double", "double"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Specify variable properties
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy");
% Import the data
hydroGen = readtable(filename, opts);
end
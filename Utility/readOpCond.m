function [fuelMix,interFlow,flowLimit,nuclearCf,hydroCf,zonalPrice] = readOpCond(timeStamp,usemat)
%READOPCOND Read operation condition at specified timestamp
%   Read hourly fuelmix data, hourly interface flow data, hourly
%   zonal price data, daily nuclear generation capacity factor data, monthly
%   hydro generation capacity factor data.
%   Inputs:
%       timeStamp - datetime in "MM/dd/uuuu HH:mm:ss"
%       usemat - boolean, if 1, use mat files, if 0, use csv files
%   Outputs:
%       fuelMix - hourly fuel mix data from NYISO
%       interFlow - hourly interface flow data from NYISO
%       flowLimit - hourly interface flow limit data from NYISO
%                   (both positive limit and negative limit)
%       nuclearCf - daily nuclear generation and capacity factor data
%       hydroCf - monthly hydro generation and capacity factor data
%       zonalPrice - hourly zonal price data from NYISO

%   Created by Bo Yuan, Cornell University
%   Last modified on Sept. 24, 2021

%% Input handling

if nargin < 2 || isempty(usemat)
    usemat = 1;
end

%% Read operation condition data

if usemat % Read mat files
    
    load(fullfile('Data','fuelmixHourly_'+string(year(timeStamp))+'.mat'),'fuelmixHourly');
    load(fullfile('Data','interflowHourly_'+string(year(timeStamp))+'.mat'),'interflowHourly');
    load(fullfile('Data','priceHourly_'+string(year(timeStamp))+'.mat'),'priceHourly');
    load(fullfile('Data','nuclearGenDaily_'+string(year(timeStamp))+'.mat'),'nuclearGenDaily');
    load(fullfile('Data','hydroGenMonthly_'+string(year(timeStamp))+'.mat'),'hydroGenMonthly');
    
else % Read csv files
    
    fuelmixHourly = importFuelMix(fullfile('Data','fuelmixHourly_'+string(year(timeStamp))+'.csv'));
    interflowHourly = importInterFlow(fullfile('Data','interflowHourly_'+string(year(timeStamp))+'.csv'));
    priceHourly = importZonalPrice(fullfile('Data','priceHourly_'+string(year(timeStamp))+'.csv'));
    nuclearGenDaily = importNuclearGen(fullfile('Data','nuclearGenDaily_'+string(year(timeStamp))+'.csv'));
    hydroGenMonthly = importHydroGen(fullfile('Data','hydroGenMonthly_'+string(year(timeStamp))+'.csv'));
    
end

%%  Get time-specific data

fuelMix = fuelmixHourly(fuelmixHourly.TimeStamp == timeStamp,:);
interFlow = interflowHourly(interflowHourly.TimeStamp == timeStamp,["InterfaceName","FlowMWH"]);
flowLimit = interflowHourly(interflowHourly.TimeStamp == timeStamp,["InterfaceName","PositiveLimitMWH","NegativeLimitMWH"]);
nuclearCf = nuclearGenDaily(nuclearGenDaily.TimeStamp == dateshift(timeStamp,'start','day'),:);
hydroCf = hydroGenMonthly(hydroGenMonthly.TimeStamp == dateshift(timeStamp,'start','month'),:);
zonalPrice = priceHourly(priceHourly.TimeStamp == timeStamp, :);
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

function zonalPrice = importZonalPrice(filename, dataLines)
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
zonalPrice = readtable(filename, opts);
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
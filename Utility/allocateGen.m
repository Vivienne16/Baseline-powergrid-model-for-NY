function sampleHourGen = allocateGen(timeStamp,costtype,usemat)
%ALLOCATEGENHOURLY Allocate hourly generation to buses in NYS
%   
%   Use the ALLOCATEGENHOURLY function to produces a table of generation
%   parameters, including generation cost curve, for constructing MATPOWER
%   case file.
%   
%   Inputs:
%       timeStamp- includes year, month, day, hour
%       costType - "lm": use linear cost function for all generators, default
%              "qm": mix of linear and quadratic function (if available)
%   Outputs:
%       sampleHourGen - generator parameter and cost table
%
%   Created by Bo Yuan, Cornell University
%   Last modified on July 28, 2021

%% Default function inputs

% Use linear cost function by default
if nargin < 2 || isempty(costtype)
    costtype = "lm";
end

if nargin < 3 || isempty(usemat)
    usemat = 1;
end

%% Generator allocation

% Read generator allocation table
genAllocation = importNearestBus(fullfile("Data","gen_bus_assignment.csv"));

% Read generator parameter table
if usemat
    load(fullfile("Data","genParamAll_newramp.mat"),'genParamAll_newramp');
else
    genParamAll_newramp = importGenParam(fullfile("Data","genParamAll_newramp.csv"));
end

% Allocate generator to the nearest PV bus
genParamWBus = innerjoin(genParamAll_newramp,genAllocation,"Keys",["NYISOName","PTID"], ...
    "RightVariables","BusName");

%% Sample hour generation

% Read hourly generation and heat input data for large generators
if usemat
    load(fullfile('Data','thermalGenHourly_'+string(year(timeStamp))+'.mat'),'hourlyGenLarge');
else
    hourlyGenLarge = importThermalGen(fullfile('Data','thermalGenHourly_'+string(year(timeStamp))+'.csv'));
end

% Hour specific value
sampleHourlyGen = hourlyGenLarge(hourlyGenLarge.TimeStamp == timeStamp, :);

% Combine it with generator allocation table
sampleHourlyGenLarge = outerjoin(genParamWBus,sampleHourlyGen,"Keys",["NYISOName","PTID"],...
    "MergeKeys",true,"Type","left","RightVariables",["hourlyGen","hourlyHeatInput"]);

%% Sample hour generation cost curve

% Read weekly fuel price table in NYISO 2019
fuelPriceTable = importFuelPrice(fullfile('Data','fuelPriceWeekly_'+string(year(timeStamp))+'.csv'));

% Get fuel price for the sampled hour
sampleFuelPrice = fuelPriceTable(fuelPriceTable.TimeStamp <= timeStamp, :);
sampleFuelPrice = sampleFuelPrice(end, :);

% Calculate generation cost curve using heat rate curve and fuel price
sampleCostCurve = createGenCost(genParamAll_newramp,sampleFuelPrice,costtype);

% combine the results with generation parameters table
sampleHourGen = outerjoin(sampleHourlyGenLarge,sampleCostCurve,"Keys",["NYISOName","PTID"],"MergeKeys",true);
sampleHourGen = removevars(sampleHourGen, ["HeatRateLM_1", "HeatRateLM_0",...
    "HeatRateQM_2","HeatRateQM_1","HeatRateQM_0","useQM"]);

end

function costTable = createGenCost(genParam, priceTable, costType)
numGen = height(genParam);
NCOST = zeros(numGen, 1);
cost_2 = zeros(numGen, 1);
cost_1 = zeros(numGen, 1);
cost_0 = zeros(numGen, 1);
for i=1:numGen
    fuelfactor = 1;
    gasfactor = 1;
    zone = genParam(i, :).Zone;
    fuel = genParam(i, :).FuelType;
   
    % Read zonal fuel cost data
    if fuel == "Coal"
        fuelPrice = priceTable.coal_NY;
    elseif fuel == "Natural Gas"
        fuelPrice = priceTable.NG_A2E*gasfactor;
        if zone == "K"
             fuelPrice = priceTable.NG_K*gasfactor;
        end
        if zone == "J"
             fuelPrice = priceTable.NG_J*gasfactor;
        end
    elseif fuel == "Fuel Oil 2" || fuel == "Kerosene"

          fuelPrice = priceTable.FO2_UPNY*fuelfactor;
    elseif fuel == "Fuel Oil 6"

        fuelPrice = priceTable.FO6_UPNY*fuelfactor;
    else
        error("Error: Undefined fuel type!");
    end
    
    % Calculate cost curve
    if costType == "lm"
        NCOST(i) = 1;
        cost_1(i) = fuelPrice * genParam(i, :).HeatRateLM_1;
        cost_0(i) = fuelPrice * genParam(i, :).HeatRateLM_0;
    elseif costType == "qm"
        if genParam.useQM(i) == "1"
            NCOST(i) = 2;
            cost_2(i) = fuelPrice * genParam(i, :).HeatRateQM_2;
            cost_1(i) = fuelPrice * genParam(i, :).HeatRateQM_1;
            cost_0(i) = fuelPrice * genParam(i, :).HeatRateQM_0;
        else
            NCOST(i) = 1;
            cost_1(i) = fuelPrice * genParam(i, :).HeatRateLM_1;
            cost_0(i) = fuelPrice * genParam(i, :).HeatRateLM_0;
        end
    else
        error("Error: Undefined cost type");
    end
end

% Return cost table
if costType == "lm"
    costTable = table(genParam.NYISOName,genParam.PTID,NCOST,cost_1,cost_0);
    costTable.Properties.VariableNames = ["NYISOName","PTID","NCOST","cost_1","cost_0"];
elseif costType == "qm"
    costTable = table(genParam.NYISOName,genParam.PTID,NCOST,cost_2,cost_1,cost_0);
    costTable.Properties.VariableNames = ["NYISOName","PTID","NCOST","cost_2","cost_1","cost_0"];
else
    error("Error: Undefined cost type");
end
end

function fuelPriceTable = importFuelPrice(filename, dataLines)
%IMPORTFILE Import fuel price

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 10);
% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";
% Specify column names and types
opts.VariableNames = ["TimeStamp", "NG_A2E", "NG_F2I", "NG_J", "NG_K", ...
    "FO2_UPNY", "FO2_DSNY", "FO6_UPNY", "FO6_DSNY", "coal_NY"];
opts.VariableTypes = ["datetime", "double", "double", "double", "double", ...
    "double", "double", "double", "double", "double"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Specify variable properties
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy");
% Import the data
fuelPriceTable = readtable(filename, opts);

end

function thermalGenHourly = importThermalGen(filename, dataLines)
%IMPORTTHERMALGEN Import hourly thermal generation

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
opts.VariableNames = ["TimeStamp", "NYISOName", "PTID", "hourlyGen", "hourlyHeatInput"];
opts.VariableTypes = ["datetime", "categorical", "categorical", "double", "double"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Specify variable properties
opts = setvaropts(opts, ["NYISOName", "PTID"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");
% Import the data
thermalGenHourly = readtable(filename, opts);

end
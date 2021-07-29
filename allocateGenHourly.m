function sampleHourGen = allocateGenHourly(year,month,date,hour,costType)
% AllocateGenHourly Allocate hourly generation to buses in NYS, produces a
% table of generation parameters, including generation cost curve, for
% constructing matpower case file
% Inputs:
%   year,month,date,hour - Timestamp information
%   costType - "lm": use linear cost function for all generators, default
%              "qm": mix of linear and quadratic function (if available)
% Outputs:
%   sampleHourGen - generator parameter and cost table

% Author: Bo Yuan
% Last modified: July 28, 2021

% Use linear cost function by default
if nargin <= 4
    costType = "lm";
end

%% Generator allocation
% Read generator allocation table
genAllocation = importNearestBus("Data/gen_bus_assignment.csv");
% Read generator parameter table
genParamAll = importGenParam("Data/genParamAll.csv");
% Allocate generator to the nearest PV bus
genParamWBus = innerjoin(genParamAll,genAllocation,"Keys",["NYISOName","PTID"], ...
    "RightVariables","BusName");

%% Sample hour generation
TimeStamp = datetime(year,month,date,hour,0,0,"Format","MM/dd/uuuu HH:mm:ss");
% Read hourly generation and heat input data for large generators
load("Data/hourlyGenLarge.mat","hourlyGenLarge","-mat");
% Time stamp range checking (only support 2019 hourly data)
startTimeStamp = hourlyGenLarge.TimeStamp(1);
endTimeStamp = hourlyGenLarge.TimeStamp(end);
if TimeStamp < startTimeStamp || TimeStamp > endTimeStamp
    error("Time stamp not supported!");
else
    sampleHourlyGen = hourlyGenLarge(hourlyGenLarge.TimeStamp == TimeStamp, :);
    % Combine it with generator allocation table
    sampleHourlyGenLarge = outerjoin(genParamWBus,sampleHourlyGen,"Keys",["NYISOName","PTID"],...
        "MergeKeys",true,"Type","left","RightVariables",["hourlyGen","hourlyHeatInput"]);
end
%% Sample hour generation cost curve
% Read weekly fuel price table in NYISO 2019
load("Data/fuelPriceTable.mat","fuelPriceTable");
% Get fuel price for the sampled hour
sampleFuelPrice = fuelPriceTable(fuelPriceTable.TimeStamp <= TimeStamp, :);
sampleFuelPrice = sampleFuelPrice(end, :);
% Calculate generation cost curve using heat rate curve and fuel price
sampleCostCurve = createGenCost(genParamAll,sampleFuelPrice,costType);
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

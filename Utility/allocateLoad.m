function sampleHourLoad = allocateLoad(timeStamp,method,usemat)
%ALLOCATELOADHOURLY Allocate hourly load to the buses in NYS.
%   
%   Use the ALLOCATELOADHOURLY function to produces a table of power demand
%   at each bus in NYS for constructing MATPOWER case file.
%   
%   Inputs:
%       timeStamp- datatime, in "MM/dd/uuuu HH:mm:ss"
%       method - string, "evenly" or "weighted"
%   Outputs:
%       sampleHourLoad - load parameter table
%
%   Created by Bo Yuan, Cornell University
%   Last modified on Sept. 27, 2021

%% Default function inputs

if nargin < 2 || isempty(method)
    method = "weighted";
end

if nargin < 3 || isempty(usemat)
    usemat = 1;
end

%% Read NYS bus table

% NYSBus = readtable("Data/bus_ny_type_zone_new.csv");
busInfo = importBusInfo(fullfile("Data","npcc.csv"));
NYSBus = busInfo(busInfo.zone ~= 'NA', :);
% Subset bus with load connected, could be all types of bus
NYSBusWLoad = NYSBus(NYSBus.sumLoadP0 > 0, :);

%% Load bus and ratio calculation
% zoneIDs = {'A','B','C','D','E','F','G','H','I','J','K'};
zoneIDs = unique(busInfo.zone);
loadBusZone = cell(11, 1);
loadRatioZone = cell(11, 1);
numLoadBusZone = zeros(11, 1);
for i=1:11
    % If the zone has bus with load, then distribute the load according to
    % the original load ratio
    % Including zone A, B, C, D, E, F, H, I, K
    loadBusTable = NYSBusWLoad(NYSBusWLoad.zone == zoneIDs(i), :);
    loadBusZone{i} = loadBusTable.idx;
    loadRatioZone{i} = loadBusTable.sumLoadP0/sum(loadBusTable.sumLoadP0);
    
    % If the zone doesn't have bus with load, then evenly distribute the
    % load among all buses in that zone
    % Including zone G, J
    if isempty(loadBusZone{i})
        loadBusZone{i} = NYSBus.idx(NYSBus.zone == zoneIDs(i));
        loadRatioZone{i} = 1/length(loadBusZone{i});
    end
    numLoadBusZone(i) = length(loadBusZone{i});
end
numLoadBusTot = sum(numLoadBusZone);

%% Read load data

if usemat
    load(fullfile('Data','loadHourly_'+string(year(timeStamp))+'.mat'),'loadHourly');
else
    loadHourly = importLoad(fullfile('Data','loadHourly_'+string(year(timeStamp))+'.csv'));
end

sampleLoadZonal = loadHourly(loadHourly.TimeStamp == timeStamp, :);

%% Distribute load to buses

if method == "evenly"
    sampleHourLoad = addLoadEvenly(sampleLoadZonal,NYSBus,zoneIDs);
elseif method == "weighted"
    sampleHourLoad = addLoadWeighted(sampleLoadZonal,loadRatioZone,loadBusZone,numLoadBusTot,NYSBus,zoneIDs,numLoadBusZone);
else
    Error("Error: Undefined load allocation method");
end

end

%% Method 1: Evenly distribte load
function NYSBusLoadEven = addLoadEvenly(hourlyLoadZonal,NYSBus,zoneIDs)
    NYSBusLoadEven = [];
    for i=1:11
        NYSBusZone = NYSBus(NYSBus.zone == zoneIDs(i), :);
        zoneLoadTot = hourlyLoadZonal.Load(hourlyLoadZonal.ZoneID == categorical(zoneIDs(i)));
        NYSBusZone.PD = zoneLoadTot/height(NYSBusZone)*ones(height(NYSBusZone), 1);
        NYSBusLoadEven = [NYSBusLoadEven; NYSBusZone];
    end
    
    powerFactor = 0.98;
    NYSBusLoadEven.QD = NYSBusLoadEven.PD * tan(acos(powerFactor));
    NYSBusLoadEven = NYSBusLoadEven(:, ["idx","name","area","zone","PD","QD"]);
    NYSBusLoadEven = sortrows(NYSBusLoadEven, "idx");
end

%% Method 2: Weighted distribte load
function NYSBusNew = addLoadWeighted(hourlyLoadZonal,loadRatioZone,loadBusZone,numLoadBusTot,NYSBusOld,zoneIDs,numLoadBusZone)
    zoneLoadBus = cell(11, 1);
    loadBusIdx = zeros(numLoadBusTot, 1);
    loadBusLoad = zeros(numLoadBusTot, 1);
    n = 1;
    for i=1:11
        zoneLoadTot = hourlyLoadZonal.Load(hourlyLoadZonal.ZoneID == categorical(zoneIDs(i)));
        zoneLoadBus{i} = loadRatioZone{i}*zoneLoadTot;
        loadBusIdx(n:n+numLoadBusZone(i)-1) = loadBusZone{i};
        loadBusLoad(n:n+numLoadBusZone(i)-1) = zoneLoadBus{i};
        n = n+numLoadBusZone(i);
    end
    busWLoad = array2table([loadBusIdx, loadBusLoad], "VariableNames", ["idx", "PD"]);
    busWLoadCleaned = groupsummary(busWLoad, "idx", "sum", "PD");
    busWLoadCleaned.Properties.VariableNames(3) = "PD";
    
    % Join table
    NYSBusNew = outerjoin(NYSBusOld,busWLoadCleaned,"Type","left","Keys","idx","MergeKeys",true, ...
        "LeftVariables",["idx","name","area","zone"],"RightVariables","PD");
    NYSBusNew.PD = fillmissing(NYSBusNew.PD, "constant", 0);
    powerFactor = 0.98;
    NYSBusNew.QD = NYSBusNew.PD * tan(acos(powerFactor));
end

function load = importLoad(filename, dataLines)
%IMPORTLOAD Import hourly load data in a year

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
opts.VariableNames = ["TimeStamp", "ZoneName", "Load", "ZoneID"];
opts.VariableTypes = ["datetime", "categorical", "double", "categorical"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "ZoneName", "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeStamp", "InputFormat", "MM/dd/yyyy HH:mm:ss");

% Import the data
load = readtable(filename, opts);

end